

options fullstimer sastrace=',,,ds' SASTRACELOC=SASLOG NOSTSUFFIX SQL_IP_TRACE=(note, source) msglevel=i dsaccel=any;

/**************************************************************
Program: Process World Bank Indicators - Optimized Version

Purpose:
This optimized version processes World Bank indicator data and
creates two final output tables:

1. COUNTRIES_POP_GDP
2. COUNTRY_LOOKUP

Source Tables:
- ORALIB.COUNTRIES
- ORALIB.POPULATION
- ORALIB.POP_GROWTH
- ORALIB.GDP_WIDE
- ORALIB.REGIONS

Output Tables:
- ORALIB.COUNTRIES_POP_GDP
- ORALIB.COUNTRY_LOOKUP

Optimization Goals:
- Reduce unnecessary DATA and PROC steps
- Reduce intermediate WORK tables
- Move more processing to Oracle
- Use explicit pass-through
- Use implicit pass-through
- Preserve the same final output structure and row counts

Expected final results based on the original program:
- COUNTRIES_POP_GDP: 3192 rows and 16 columns
- COUNTRY_LOOKUP: 214 rows and 4 columns

Case Study:
SAS Data Engineering Track

Author:
Lucas Santos
***************************************************************/


/**************************************************************
Step 1: Define reporting years

These are the selected years used throughout the Countries Data
Project.
***************************************************************/

%let years_num = 2000, 2002, 2004, 2006, 2008, 2010, 2012, 2014, 2016, 2018, 2021, 2022;


/**************************************************************
Step 2: Connect to Oracle

The Oracle libref is used for implicit pass-through processing
and for copying final tables back to Oracle.
***************************************************************/

libname oralib oracle
    path='//server.demo.sas.com:1521/ORCL'
    user=STUDENT
    password=Metadata0
    DB_LENGTH_SEMANTICS_BYTE=NO
    DBCLIENT_MAX_BYTES=1;


/**************************************************************
Step 3: Clean previous WORK tables

This prevents old output tables from a previous failed run from
being reused accidentally.
***************************************************************/

proc datasets lib=work nolist nowarn;
    delete countries_pop_indicators
           gdp_transpose
           gdp
           countries_pop_gdp_partial
           countries_pop_gdp
           country_lookup;
quit;


/**************************************************************
Step 4: Remove previous Oracle output and temporary tables

This keeps the program rerunnable. NOWARN prevents warnings if
the tables do not already exist.
***************************************************************/

proc datasets lib=oralib nowarn;
    delete countries_pop_gdp
           country_lookup
           population_indicators_ora;
quit;


/**************************************************************
Step 5: Explicit pass-through to Oracle

This step creates POPULATION_INDICATORS_ORA directly in Oracle.

Original approach:
- Copy POPULATION and POP_GROWTH from Oracle to WORK
- Sort POPULATION
- Sort POP_GROWTH
- Join them in SAS

Optimized approach:
- Join POPULATION and POP_GROWTH directly in Oracle
- Filter selected years in Oracle
- Store the resulting intermediate table in Oracle

This removes two PROC SORT steps and moves the join/filter work
to Oracle.
***************************************************************/

proc sql;
    connect to oracle (
        path='//server.demo.sas.com:1521/ORCL'
        user=STUDENT
        password=Metadata0
    );

    execute (
        create table population_indicators_ora as
        select
            coalesce(p.country_code, g.country_code) as country_code,
            p.country_name as country_name,
            coalesce(to_number(p.year), g.year) as year,
            p.population as population,
            (g.pop_pct_growth / 100) as pop_growth
        from population p
        full outer join pop_growth g
            on p.country_code = g.country_code
           and to_number(p.year) = g.year
        where to_number(p.year) in
              (2000, 2002, 2004, 2006, 2008, 2010, 2012, 2014, 2016, 2018, 2021, 2022)
           or g.year in
              (2000, 2002, 2004, 2006, 2008, 2010, 2012, 2014, 2016, 2018, 2021, 2022)
    ) by oracle;

    disconnect from oracle;
quit;


/**************************************************************
Step 6: Implicit pass-through using ORALIB

SASTRACE is enabled so the SAS log shows which SQL is passed to
Oracle.

Important correction:
The original SAS DATA step MERGE preserved all rows from the
population indicator data. Therefore, this step uses the Oracle
population indicator table as the driving table and LEFT JOINs
country metadata onto it.

This preserves the expected 3192 rows.

This replaces:
- PROC SORT of COUNTRIES
- DATA step merge of COUNTRIES and POPULATION_INDICATORS
***************************************************************/


proc sql;
    create table work.countries_pop_indicators as
    select
        c.table_name as SORTABLE_NAME,
        p.country_code,
        c.short_name,
        c.long_name,
        c.alpha_2_code,
        c.region,
        c.income_group,
        c.wb_2_code,
        p.country_name,
        p.year,
        p.population,
        p.pop_growth format=percent5.2 label="Population % Growth"
    from oralib.population_indicators_ora as p
    left join oralib.countries as c
        on p.country_code = c.country_code
    order by p.country_code, p.year;
quit;


/**************************************************************
Step 7: Transpose GDP data

GDP_WIDE stores years as columns, for example Y_1960 through
Y_2022.

PROC TRANSPOSE converts the table from wide format to long
format so GDP can be joined by COUNTRY_CODE and YEAR.

This step is kept in SAS for this optimized version because the
original calculation depends on SAS transpose and lag behavior.
***************************************************************/

proc transpose data=oralib.gdp_wide
    out=work.gdp_transpose
        (rename=(col1=GDP) drop=_Name_)
    label=Year_char;
    var Y_1960-Y_2022;
    by Country_Code Country_Name Indicator_Code Indicator_Name notsorted;
run;


/**************************************************************
Step 8: Calculate GDP percentage change

This step calculates year-over-year GDP percentage change by
country.

The LAG1 function stores the previous GDP value. This variable
is intentionally kept because the original program includes it
in the final output structure.

Only selected reporting years are kept.
***************************************************************/

data work.gdp(drop=Indicator_Code Indicator_Name Year_char);
    set work.gdp_transpose;
    by country_code notsorted;

    format GDP_Pct_Change percent6.2;
    label GDP_Pct_Change="GDP % Change"
          GDP="GDP (current US$)";

    lagged_GDP = lag1(GDP);

    if first.country_code then
        GDP_pct_change=.;
    else if GDP=. or lagged_GDP=. or lagged_GDP=0 then
        GDP_pct_change=.;
    else
        GDP_pct_change=(GDP-lagged_GDP)/lagged_GDP;

    Year=input(scan(Year_char, -1, '_ '), 4.);

    if Year in (&years_num);
run;


/**************************************************************
Step 9: Join GDP with country and population indicators

Original approach:
- Sort COUNTRIES_POP_INDICATORS
- Sort GDP
- DATA step merge

Optimized approach:
- Use PROC SQL join directly
- Avoid two PROC SORT steps
- Avoid one DATA step merge

Important correction:
LAGGED_GDP is kept in the output to preserve the original final
table structure.
***************************************************************/

proc sql;
    create table work.countries_pop_gdp_partial as
    select
        c.*,
        g.GDP,
        g.lagged_GDP,
        g.GDP_Pct_Change
    from work.countries_pop_indicators as c
    left join work.gdp as g
        on c.country_code = g.country_code
       and c.year = g.year
    order by c.country_code, c.year;
quit;


/**************************************************************
Step 10: Calculate World GDP by year

This creates the final COUNTRIES_POP_GDP table and adds WORLD_GDP
to each row.

WORLD_GDP is the sum of GDP for each selected year.
***************************************************************/

proc sql;
    create table work.countries_pop_gdp as
    select
        *,
        sum(GDP) as World_GDP label="World GDP for Year"
    from work.countries_pop_gdp_partial
    group by Year;
quit;


/**************************************************************
Step 11: Create COUNTRY_LOOKUP with fewer intermediate tables

Original approach:
- Create SAME_CODES
- Create SAME_NAMES
- Stack them with DATA step
- Remove duplicates with PROC SORT NODUPKEY

Optimized approach:
- Use UNION to combine both match strategies
- UNION removes duplicate rows automatically
- Avoids two intermediate tables, one DATA step, and one PROC SORT
***************************************************************/

proc sql;
    create table work.Country_Lookup as

    select
        o.isoalpha3,
        w.country_code,
        o.idname,
        w.country_name
    from oralib.regions as o
    inner join work.countries_pop_gdp_partial as w
        on o.isoalpha3 = w.country_code

    union

    select
        o.isoalpha3,
        w.country_code,
        o.idname,
        w.country_name
    from oralib.regions as o
    inner join work.countries_pop_gdp_partial as w
        on o.idname = w.country_name

    order by 1, 2, 3, 4;
quit;


/**************************************************************
Step 12: Remove sorted-by metadata

Oracle does not support SAS sorted-by attributes, so the metadata
is cleared before copying the tables back to Oracle.
***************************************************************/

proc datasets lib=work nowarn;
    modify countries_pop_gdp (sortedby=_NULL_);
    modify Country_Lookup (sortedby=_NULL_);
quit;


/**************************************************************
Step 13: Delete old final output tables from Oracle

This prepares Oracle for the new optimized output tables.
***************************************************************/

proc datasets lib=oralib nowarn;
    delete countries_pop_gdp Country_Lookup;
quit;


/**************************************************************
Step 14: Copy final output tables to Oracle

The final output tables are copied to Oracle as required by the
case study.
***************************************************************/

proc copy in=work out=oralib memtype=data;
    select countries_pop_gdp Country_Lookup;
run;


/**************************************************************
Step 15: Validate exported table structures

PROC CONTENTS confirms that the final output tables exist in
Oracle and shows their metadata.
***************************************************************/

proc contents data=oralib.countries_pop_gdp;
run;

proc contents data=oralib.Country_Lookup;
run;


/**************************************************************
Step 16: Clean up temporary Oracle intermediate table

The case study states that intermediate tables should not be
saved permanently, so the Oracle temporary table created for
optimization is removed.
***************************************************************/

proc datasets lib=oralib nowarn;
    delete population_indicators_ora;
quit;


/**************************************************************
Step 17: Clear Oracle libref
***************************************************************/

libname oralib clear;