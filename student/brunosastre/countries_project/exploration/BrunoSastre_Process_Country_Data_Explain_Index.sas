

options sastrace=',,,ds' SASTRACELOC=SASLOG NOSTSUFFIX SQL_IP_TRACE=(note, source) msglevel=i dsaccel=any;


%let user=STUDENT;
%let password=Metadata0;

proc sql;
    connect to oracle (
        path='//server.demo.sas.com:1521/ORCL'
        user=&user
        password=&password.
    );

    execute (
        explain plan for
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

    select * from connection to oracle
    (select * from table(dbms_xplan.display));

    disconnect from oracle;
quit;