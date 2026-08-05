
options sastrace=',,,ds'
        sastraceloc=saslog
        nostsuffix
        sql_ip_trace=(note, source)
        msglevel=i
        dsaccel=any
        fullstimer;
        
/**************************************************************
Process World Bank Indicators 

Note:  The documentation and comments for this code are
intentionally sparse.   You should add more comments as you
work with and understand the code.

Change this code to be more efficient and to do as much
processing as possible in the Oracle environment

***************************************************************/

%let path_orcl='//server.demo.sas.com:1521/ORCL';
%let user=STUDENT;
%let pwd=Metadata0;
%let years_num = 2000, 2002, 2004, 2006, 2008, 2010, 2012, 2014, 2016, 2018, 2021, 2022;

proc sql noerrorstop noprint ;
    connect to oracle (path=&path_orcl. user=&user. password=&pwd.);

    /* Verifica existencia antes de cada DROP para evitar ORA-00942 */
    select table_count into :tbl1_exists trimmed
    from connection to oracle
    (select count(*) as table_count from user_tables where table_name = 'COUNTRIES_POP_GDP');

    select table_count into :tbl2_exists trimmed
    from connection to oracle
    (select count(*) as table_count from user_tables where table_name = 'COUNTRY_LOOKUP');

    select table_count into :tbl3_exists trimmed
    from connection to oracle
    (select count(*) as table_count from user_tables where table_name = 'POPULATION_INDICATORS_ORA');

    select table_count into :tbl4_exists trimmed
    from connection to oracle
    (select count(*) as table_count from user_tables where table_name = 'POPULATION_CHAR_BACKUP');

    %if &tbl1_exists. > 0 %then %do;
        execute (drop table countries_pop_gdp) by oracle;
    %end;
    %if &tbl2_exists. > 0 %then %do;
        execute (drop table country_lookup) by oracle;
    %end;
    %if &tbl3_exists. > 0 %then %do;
            execute (drop table POPULATION_INDICATORS_ORA) by oracle;
    %end;
    %if &tbl4_exists. > 0 %then %do;
                execute (drop table POPULATION_CHAR_BACKUP) by oracle;
     %end;

    execute (
        create table population_char_backup as
        select country_code, country_name,
               to_char(year) as year,
               population
        from population
    ) by oracle;

    disconnect from oracle;
quit;



/* copy data files from Oracle library */
libname oralib oracle path='//server.demo.sas.com:1521/ORCL' user=STUDENT 
	password=Metadata0 DB_LENGTH_SEMANTICS_BYTE=NO DBCLIENT_MAX_BYTES=1;

/*
proc copy in=oralib out=work memtype=data;
	select countries population pop_growth gdp_wide regions;
run;*/

proc copy in=oralib out=work memtype=data;
select countries population_char_backup pop_growth gdp_wide regions;
run;

/* Renomeia work.population_char_backup para work.population, 
   para nao precisar alterar o resto do programa original */
proc datasets lib=work nolist;
    delete population;  /* remove qualquer population antiga do WORK, se existir */
    change population_char_backup=population;
quit;

libname oralib clear;

/* Merge Population and Population Growth data.*/
/* Keep only data for specified years */

%let years=2000, 2002, 2004, 2006, 2008, 2010, 2012, 2014, 2016, 2018, 2021, 2022;

proc sort data=work.population out=work.population_sorted;
	by country_code year;
	where input(year, 4.) in (&years);
run;

proc sort data=work.pop_growth out=work.pop_growth_sorted;
	by country_code year;
	where year in (&years);
run;

proc sql;
	create table work.population_indicators as 
	select p.country_code, 
		p.country_name, g.year, p.population, (g.pop_pct_growth/100) as POP_GROWTH 
		format=percent5.2 label="Population % Growth" 
	from work.population_sorted as p 
	full join work.pop_growth_sorted as g 
	on (p.country_code=g.country_code and input(p.year, 4.)=g.year) 
	order by 1, 3;
quit;

/* Merge the Countries and Population Indicators data */
proc sort data=work.countries out=work.countries_sorted nodupkey;
	by country_code;
run;

data work.countries_pop_indicators;
	merge work.countries_sorted(rename=(table_name=SORTABLE_NAME)) 
		work.population_indicators;
	by country_code;
run;

/* Prepare GDP data for merging including calculating yearly GDP % growth */
proc transpose data=work.GDP_wide out=work.GDP_transpose (rename=(col1=GDP) 
		drop=_Name_) label=Year_char;
	var Y_1960-Y_2022;
	by Country_Code Country_Name Indicator_Code Indicator_Name notsorted;
run;

Data work.GDP(drop=Indicator_Code Indicator_name Year_char);
	set work.gdp_transpose;
	by country_code notsorted;
	format GDP_Pct_Change percent6.2;
	label GDP_Pct_Change="GDP % Change" GDP="GDP (current US$)";

	lagged_GDP = lag1(GDP);

	/* calc change in GDP from one year to the next */
	if first.country_code then
		GDP_pct_change=.;
	else if GDP=. or lagged_GDP=. or lagged_GDP=0 then
		GDP_pct_change=.;
	else
		GDP_pct_change=(GDP-lagged_GDP)/lagged_GDP;

	/* only keep Olympic years */
	Year=input(scan(Year_char, -1, '_ '), 4.);

	if Year in (&years);
run;

/* Merge GDP data with Country and Population Indicators */
proc sort data=work.countries_pop_indicators 
		out=work.countries_pop_indicators_sorted;
	by Country_Code Year;
run;

proc sort data=work.gdp out=work.gdp_sorted;
	by Country_Code Year;
run;

data work.countries_pop_gdp_partial;
	/*more GDP indicators will be added later */
	merge work.countries_pop_indicators_sorted work.gdp_sorted;
	by Country_Code Year;
run;


/* Calculate World GDP by year and add it to each observation */
proc sql;
	create table work.countries_pop_gdp as select *, sum(GDP) as World_GDP 
		label="World GDP for Year" from work.countries_pop_gdp_partial group by Year;
quit;

/* Create look-up table of Country codes */
/* Keep matches of Regions isolapha3 code and World Bank country code */

proc sql;
	create table work.same_codes as select o.isoalpha3, 
		w.COUNTRY_CODE, o.idname, w.COUNTRY_NAME from work.REGIONS as o 
		inner join work.countries_pop_gdp_partial as w on 
		o.isoalpha3=w.COUNTRY_CODE order by 1;
quit;
/* Keep matches of Regions Idname and World Bank country name */

proc sql;
	create table work.same_names as select o.isoalpha3, 
		w.COUNTRY_CODE, o.idname, w.COUNTRY_NAME from work.REGIONS as o 
		inner join work.countries_pop_gdp_partial as w on 
		o.idname=w.COUNTRY_NAME order by 3;
quit;
/* Combine list of name matches and code matches */
data work.Country_with_dups;
	set work.same_codes work.same_names;
run;

/* remove duplicates */
proc sort data=work.Country_with_dups 
		out=work.Country_Lookup nodupkey;
	by _all_;
run;

/* remove sortedby attribute because it is not supported by Oracle */
proc datasets  lib=work nowarn;
	modify countries_pop_gdp (sortedby=_NULL_);
	modify Country_Lookup (sortedby=_NULL_);
quit;


/* copy data files to Oracle library */
libname oralib oracle path='//server.demo.sas.com:1521/ORCL' user=STUDENT 
	password=Metadata0 DB_LENGTH_SEMANTICS_BYTE=NO DBCLIENT_MAX_BYTES=1;
	
/* delete tables in Oracle library if they exist */
proc datasets lib=oralib nowarn;
delete countries_pop_gdp Country_Lookup;  
run;

proc copy in=work out=oralib memtype=data;
	select countries_pop_gdp Country_Lookup ;
run;

proc contents data=oralib.countries_pop_gdp;
run;

proc contents data=oralib.Country_Lookup;
run;



/* Resultado do programa original */

data work.orig_countries_pop_gdp;
    set oralib.countries_pop_gdp;
run;

data work.orig_country_lookup;
    set oralib.country_lookup;
run;

libname oralib clear;