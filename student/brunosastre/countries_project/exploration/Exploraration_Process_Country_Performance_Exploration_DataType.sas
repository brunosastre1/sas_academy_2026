/* ============================================================
   COMPARACAO: QUERY ANTIGA (TO_NUMBER) x QUERY NOVA (YEAR NUMERICO)
   ============================================================
   Objetivo: medir o tempo de execucao de cada versao da query
   N vezes, intercalando as execucoes, e comparar as medias.
   ============================================================ */

options fullstimer sastrace=',,,ds' SASTRACELOC=SASLOG NOSTSUFFIX SQL_IP_TRACE=(note, source) msglevel=i dsaccel=any;


/* ---------- CONFIGURACAO ---------- */
%let N_EXEC = 5;   /* quantidade de execucoes por cenario */

proc sql;
    create table work.tempos_teste
        (cenario char(20), execucao num, segundos num);
quit;


/* ============================================================
   MACRO - UMA EXECUCAO DA VERSAO ANTIGA (com TO_NUMBER)
   ============================================================ */
%macro roda_antiga_uma(i);
    %local t0 t1 dif;
    %let t0 = %sysfunc(datetime());

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

    %let t1 = %sysfunc(datetime());
    %let dif = %sysevalf(&t1 - &t0);

    proc sql;
        insert into work.tempos_teste
        values ("ANTIGA_TONUMBER", &i, &dif);
    quit;

    %put ### ANTIGA - Execucao &i: &dif segundos ###;
%mend roda_antiga_uma;


/* ============================================================
   MACRO - UMA EXECUCAO DA VERSAO NOVA (year ja numerico)
   ============================================================ */
%macro roda_nova_uma(i);
    %local t0 t1 dif;
    %let t0 = %sysfunc(datetime());

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

    %let t1 = %sysfunc(datetime());
    %let dif = %sysevalf(&t1 - &t0);

    proc sql;
        insert into work.tempos_teste
        values ("NOVA_NUMERICO", &i, &dif);
    quit;

    %put ### NOVA - Execucao &i: &dif segundos ###;
%mend roda_nova_uma;


/* ============================================================
   EXECUCAO INTERCALADA (antiga, nova, antiga, nova, ...)
   ============================================================
   Intercalar evita que uma das versoes seja beneficiada ou
   prejudicada s6 por rodar num momento de servidor mais
   ocioso/ocupado que a outra.
   ============================================================ */
%macro roda_intercalado;
    %local i;
    %do i = 1 %to &N_EXEC;
        %roda_antiga_uma(&i);
        %roda_nova_uma(&i);
    %end;
%mend roda_intercalado;

%roda_intercalado;


/* ============================================================
   COMPARATIVO FINAL
   ============================================================ */
proc sql;
    create table work.resumo_comparativo as
    select
        cenario,
        count(*)           as qtd_execucoes,
        mean(segundos)      as tempo_medio   format=8.4,
        std(segundos)       as desvio_padrao format=8.4,
        min(segundos)       as tempo_min     format=8.4,
        max(segundos)       as tempo_max     format=8.4
    from work.tempos_teste
    group by cenario;
quit;

title "Tempos individuais de cada execucao";
proc print data=work.tempos_teste noobs;
run;

title "Resumo comparativo: ANTIGA (TO_NUMBER) x NOVA (year numerico)";
proc print data=work.resumo_comparativo noobs;
run;
title;

/* Calculo do ganho percentual */
proc sql noprint;
    select tempo_medio into :media_antiga
        from work.resumo_comparativo where cenario = "ANTIGA_TONUMBER";
    select tempo_medio into :media_nova
        from work.resumo_comparativo where cenario = "NOVA_NUMERICO";
quit;

%let ganho = %sysevalf((&media_antiga - &media_nova) / &media_antiga * 100);

%put ============================================================;
%put RESUMO FINAL;
%put Tempo medio ANTIGA (TO_NUMBER): &media_antiga segundos;
%put Tempo medio NOVA (numerico):    &media_nova segundos;
%put Ganho percentual:               &ganho pct;
%put ============================================================;
