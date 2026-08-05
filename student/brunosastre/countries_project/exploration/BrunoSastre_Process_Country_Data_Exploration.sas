options fullstimer sastrace=',,,ds' SASTRACELOC=SASLOG NOSTSUFFIX SQL_IP_TRACE=(note, source) msglevel=i dsaccel=any;

libname oralib oracle path='//server.demo.sas.com:1521/ORCL' user=STUDENT 
	password=Metadata0 DB_LENGTH_SEMANTICS_BYTE=NO DBCLIENT_MAX_BYTES=1;

/* not worth using CAS due to the low ammount of observations */

proc sql;

    select count(*) from oralib.population; /* 16k */
    select count(*) from oralib.countries; /* 263 */
    select count(*) from oralib.pop_growth; /* 16k */
    select count(*) from oralib.gdp_wide; /* 266 */
    select count(*) from oralib.regions; /* 247 */

quit;

/* versao lucas */
proc sql;
    connect to oracle (
        path='//server.demo.sas.com:1521/ORCL'
        user=STUDENT
        password=Metadata0
    );
    execute (drop table population_indicators_ora) by oracle;
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


proc sql;
    connect to oracle (
        path='//server.demo.sas.com:1521/ORCL'
        user=STUDENT
        password=Metadata0 readbuff=32000
    );

/* versao bs */
/* de fato a ordem não muda aqui por conta da quantidade de linhas, o que ajudou foi o readbuff*/
 execute (drop table population_indicators_ora) by oracle;
execute (
    create table population_indicators_ora as
    select
        coalesce(p.country_code, g.country_code) as country_code,
        p.country_name                             as country_name,
        coalesce(p.year_num, g.year)                as year,
        p.population                                as population,
        (g.pop_pct_growth / 100)                    as pop_growth
    from
        ( select country_code, country_name,
                 to_number(year) as year_num,
                 population
          from population
          where year in ('2000','2002','2004','2006','2008',
                          '2010','2012','2014','2016','2018','2021','2022')
        ) p
    full outer join
        ( select country_code, year, pop_pct_growth
          from pop_growth
          where year in (2000,2002,2004,2006,2008,2010,2012,2014,2016,2018,2021,2022)
        ) g
        on p.country_code = g.country_code
       and p.year_num = g.year
) by oracle;

    disconnect from oracle;
quit;

/* resultados dos testes */

/*
Sendo: primeira execução código do lucas e o segundo a minha versão

Teste 1:

Summary Statistics for ORACLE are:
Total SQL execution seconds were:                   0.054465
Total seconds used by the ORACLE ACCESS engine were     0.055089

Summary Statistics for ORACLE are:
Total SQL execution seconds were:                   0.036738
Total seconds used by the ORACLE ACCESS engine were     0.037270

Teste 2:

Summary Statistics for ORACLE are:
Total SQL execution seconds were:                   0.173414
Total seconds used by the ORACLE ACCESS engine were     0.173983


Summary Statistics for ORACLE are:
Total SQL execution seconds were:                   0.041086
Total seconds used by the ORACLE ACCESS engine were     0.041712

Teste 3:

Summary Statistics for ORACLE are:
Total SQL execution seconds were:                   0.123639
Total seconds used by the ORACLE ACCESS engine were     0.124166

Summary Statistics for ORACLE are:
Total SQL execution seconds were:                   0.035208
Total seconds used by the ORACLE ACCESS engine were     0.035689

Teste 4:


Summary Statistics for ORACLE are:
Total SQL execution seconds were:                   0.045096
Total seconds used by the ORACLE ACCESS engine were     0.045577

Summary Statistics for ORACLE are:
Total SQL execution seconds were:                   0.033293
Total seconds used by the ORACLE ACCESS engine were     0.033684

Teste 5:

Summary Statistics for ORACLE are:
Total SQL execution seconds were:                   0.100175
Total seconds used by the ORACLE ACCESS engine were     0.100605

Summary Statistics for ORACLE are:
Total SQL execution seconds were:                   0.034594
Total seconds used by the ORACLE ACCESS engine were     0.035128
*/


/****nova query após mudança na base de dados - population data - campo year */
proc sql;
    connect to oracle (
        path='//server.demo.sas.com:1521/ORCL'
        user=STUDENT
        password=Metadata0 readbuff=32000
    );
 execute (drop table population_indicators_ora) by oracle;
execute (
    create table population_indicators_ora as
    select
        coalesce(p.country_code, g.country_code) as country_code,
        p.country_name                             as country_name,
        coalesce(p.year, g.year)                    as year,
        p.population                                as population,
        (g.pop_pct_growth / 100)                    as pop_growth
    from
        ( select country_code, country_name, year, population
          from population
          where year in (2000,2002,2004,2006,2008,2010,2012,2014,2016,2018,2021,2022)
        ) p
    full outer join
        ( select country_code, year, pop_pct_growth
          from pop_growth
          where year in (2000,2002,2004,2006,2008,2010,2012,2014,2016,2018,2021,2022)
        ) g
        on p.country_code = g.country_code
       and p.year = g.year
) by oracle;


    disconnect from oracle;
quit;