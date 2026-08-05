%include "/home/student/github_bruno/student/brunosastre/countries_project/optimized/parameters.sas";

/* 
   enable tracing to verify what is being pushed to Oracle
 */
options sastrace=',,,ds'
        sastraceloc=saslog
        nostsuffix
        sql_ip_trace=(note, source)
        msglevel=i
        dsaccel=any
        fullstimer;


proc sql;
    connect to oracle
    (
        path=&path_orcl.
        authdomain=&auth.
        &perf_parameters.
    );

/* 
   Build the GDP column list for Oracle UNPIVOT.
   The original program transposes Y_1960 through Y_2022 before filtering years
   To preserve the same lag logic all years need to be unpivoted first
*/

%macro build_gdp_unpivot_list(start_year=1960, end_year=2022);

    %global gdp_unpivot_list;
    %let gdp_unpivot_list=;

    %do y=&start_year %to &end_year;

        %if &y > &start_year %then
            %let gdp_unpivot_list=&gdp_unpivot_list.,;

        %let gdp_unpivot_list=&gdp_unpivot_list. Y_&y;

    %end;

%mend;

%build_gdp_unpivot_list(start_year=1960, end_year=2022);

%put NOTE: GDP UNPIVOT LIST = &gdp_unpivot_list.;


/* 
   Oracle libref for implicit passthrough.
   This is also used to remove existing final output tables before recreating them.
*/

/* have not found any other options for libname oracle that are useful at this moment */

libname oralib oracle
    path=&path_orcl.
    authdomain=&auth.
    DB_LENGTH_SEMANTICS_BYTE=NO
    DBCLIENT_MAX_BYTES=1 &perf_parameters.;


/* 
   Remove final output tables if they already exist.
*/
proc datasets lib=oralib nowarn nolist;
    delete countries_pop_gdp;
    delete country_lookup;
quit;


/* 
   Main processing using explicit passthrough.
   The final output tables are created directly in Oracle.
*/

proc sql;
    connect to oracle
    (
        path=&path_orcl.
        authdomain=&auth.
        &perf_parameters.
    );


    /* 
       Create COUNTRIES_POP_GDP directly in Oracle.

       This replaces several SAS-side steps from the original program:
       - sorting population
       - sorting pop_growth
       - joining population and pop_growth
       - sorting countries
       - merging countries with population indicators
       - transposing GDP in SAS
       - calculating lagged GDP in SAS
       - merging GDP with population/country data
       - calculating world GDP in SAS

       used WITH - creates temporary tables in Oracle - so I don't need to drop them everytime this code is executed
    
       unpivot - took some time to get the idea:

       from: country --- Y_2020 --- Y_2021 --- Y_2022
       to:   country --- year --- gdp
    
       */

    execute
    (
        create table countries_pop_gdp as

        with population_indicators as
        (
            select
                coalesce(p.country_code, g.country_code) as country_code,
                p.country_name as country_name,
                coalesce(p.year, g.year) as year,
                p.population as population,
                (g.pop_pct_growth / 100)  as pop_growth
            from
            (
                select
                    country_code,
                    country_name,
                    year,
                    population
                from population
                where year in (&years_num.)
            ) p
            full outer join
            (
                select
                    country_code,
                    year,
                    pop_pct_growth
                from pop_growth
                where year in (&years_num.)
            ) g
                on p.country_code = g.country_code
               and p.year = g.year
        ),

        countries_pop_indicators as
        (
            select
                p.country_code                         as country_code,
                c.short_name                           as short_name,
                c.table_name                           as sortable_name,
                c.long_name                            as long_name,
                c.alpha_2_code                         as alpha_2_code,
                c.region                               as region,
                c.income_group                         as income_group,
                c.wb_2_code                            as wb_2_code,
                p.country_name                         as country_name,
                p.year                                 as year,
                p.population                           as population,
                p.pop_growth                           as pop_growth
            from population_indicators p
            left join countries c
                on p.country_code = c.country_code
        ),

        gdp_long_all_years as
        (
            select
                country_code,
                country_name,
                indicator_code,
                indicator_name,
                to_number(substr(year_char, 3)) as year,
                gdp
            from gdp_wide
            unpivot include nulls
            (
                gdp for year_char in
                (
                    &gdp_unpivot_list.
                )
            )
        ),

        gdp_with_lag as
        (
            select
                country_code,
                country_name,
                indicator_code,
                indicator_name,
                year,
                gdp,
                lag(gdp) over /*retrieve the GDP value from the previous year for each country*/
                (
                    partition by country_code
                    order by year
                ) as lagged_gdp
            from gdp_long_all_years
        ),

        gdp_filtered as
        (
            select
                country_code,
                country_name,
                year,
                gdp,
                case
                    when gdp is null then null
                    when lagged_gdp is null then null
                    when lagged_gdp = 0 then null
                    else (gdp - lagged_gdp) / lagged_gdp
                end as gdp_pct_change,
                lagged_gdp
            from gdp_with_lag
            where year in (&years_num.)
        ),

        countries_pop_gdp_partial as
        (
            select
                c.country_code,
                c.short_name,
                c.sortable_name,
                c.long_name,
                c.alpha_2_code,
                c.region,
                c.income_group,
                c.wb_2_code,
                c.country_name,
                c.year,
                c.population,
                c.pop_growth,
                g.gdp,
                g.gdp_pct_change,
                g.lagged_gdp
            from countries_pop_indicators c
            left join gdp_filtered g
                on c.country_code = g.country_code
               and c.year = g.year
        )

        select
            country_code,
            short_name,
            sortable_name,
            long_name,
            alpha_2_code,
            region,
            income_group,
            wb_2_code,
            country_name,
            year,
            population,
            pop_growth,
            gdp,
            gdp_pct_change,
            lagged_gdp,
            sum(gdp) over
            (
                partition by year
            ) as world_gdp
        from countries_pop_gdp_partial

    ) by oracle;


    /* 
       create COUNTRY_LOOKUP directly in Oracle
       UNION removes duplicates, similar to the original deduplication logic.
    */

    execute
    (
        create table country_lookup as

        select
            r.isoalpha3,
            w.country_code,
            r.idname,
            w.country_name
        from regions r
        inner join countries_pop_gdp w
            on r.isoalpha3 = w.country_code

        union

        select
            r.isoalpha3,
            w.country_code,
            r.idname,
            w.country_name
        from regions r
        inner join countries_pop_gdp w
            on r.idname = w.country_name

    ) by oracle;


    /* Validate final row counts directly from Oracle */
    select *
    from connection to oracle
    (
        select
            'COUNTRIES_POP_GDP' as table_name,
            count(*) as row_count
        from countries_pop_gdp

        union all

        select
            'COUNTRY_LOOKUP' as table_name,
            count(*)  as row_count
        from country_lookup
    );

    disconnect from oracle;
quit;


/* 
   Implicit passthrough validation.
   PROC CONTENTS confirms that the final Oracle tables exist and shows metadata. 
   don't need it since we are using proc compare
*/
/*
proc contents data=oralib.countries_pop_gdp;
run;

proc contents data=oralib.country_lookup;
run;
*/

/* 
   Expected based on the original program:
   - countries_pop_gdp: 3192 rows
   - country_lookup: 214 rows
*/

proc sql;
    select count(*) as countries_pop_gdp_rows
    from oralib.countries_pop_gdp;

    select count(*) as country_lookup_rows
    from oralib.country_lookup;
quit;


/* results of the new and optimized program - push from Oracle to SAS */

data work.new_countries_pop_gdp;
    set oralib.countries_pop_gdp;
run;

data work.new_country_lookup;
    set oralib.country_lookup;
run;

/* results of the original program - push from Oracle to SAS */

proc sort data=work.orig_countries_pop_gdp;
    by _all_;
run;

proc sort data=work.new_countries_pop_gdp;
    by _all_;
run;

/* had to use criterion due to some floating-point precision differences*/
proc compare
    base=work.orig_countries_pop_gdp
    compare=work.new_countries_pop_gdp
    criterion=1e-12;
run;

proc compare base=orig_country_lookup compare=new_country_lookup;
run;

/*

The modified program produced the same output as the original program.

PROC COMPARE was executed after copying the Oracle tables back to SAS WORK and sorting the datasets prior to comparison.

COUNTRIES_POP_GDP:
- 3192 rows
- 16 variables
- No unequal values using METHOD=RELATIVE and CRITERION=1E-12

COUNTRY_LOOKUP:
- 214 rows
- 4 variables
- Exact match with no unequal values

Minor floating-point precision differences were observed between Oracle and SAS numeric calculations, but all values were within the specified comparison tolerance and therefore considered equivalent.
*/



libname oralib clear;


/* Turn off detailed Oracle tracing if no longer needed */
options sastrace=off;