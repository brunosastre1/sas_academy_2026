/* ============================================================
   PROGRAMA DE COMPARAÇÃO: SEM ÍNDICE x COM ÍNDICE
   ============================================================
   Objetivo: medir o tempo de execução da query N vezes sem
   índice, depois criar os índices e medir N vezes novamente,
   e ao final comparar as médias.
   ============================================================ */


options sastrace=',,,ds' SASTRACELOC=SASLOG NOSTSUFFIX SQL_IP_TRACE=(note, source) msglevel=i dsaccel=any;

%let user=STUDENT;
%let password=Metadata0;

/* ---------- CONFIGURAÇÃO ---------- */
%let N_EXEC = 50;   /* quantidade de execuções por cenário */

/* Tabela para guardar os tempos de cada execução */
proc sql;
    create table work.tempos_teste
        (cenario char(20), execucao num, segundos num);
quit;


/* ============================================================
   ETAPA 0 - GARANTIR QUE NÃO EXISTEM ÍNDICES (estado inicial)
   ============================================================ */
proc sql;
    connect to oracle (
        path='//server.demo.sas.com:1521/ORCL'
        user=&user.
        password=&password. readbuff=32000
    );

    /* Tenta remover, ignora erro caso não existam ainda */
    execute (drop index idx_population_cc_year) by oracle;
    execute (drop index idx_popgrowth_cc_year) by oracle;
    disconnect from oracle;
quit;


/* ============================================================
   ETAPA 1 - CENÁRIO "SEM ÍNDICE"
   ============================================================ */
%macro roda_query(cenario=);
    %local i t0 t1 dif;

    %do i = 1 %to &N_EXEC;

        %let t0 = %sysfunc(datetime());

proc sql;
    connect to oracle (
        path='//server.demo.sas.com:1521/ORCL'
        user=&user.
        password=&password. readbuff=32000
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
            values ("&cenario", &i, &dif);
        quit;

        %put ### &cenario - Execucao &i: &dif segundos ###;

    %end;
%mend roda_query;

%roda_query(cenario=SEM_INDICE);


/* ============================================================
   ETAPA 2 - CRIAR OS ÍNDICES
   ============================================================ */
proc sql;
    connect to oracle (
        path='//server.demo.sas.com:1521/ORCL'
        user=&user.
        password=&password. readbuff=32000
    );


    execute (
        create index idx_population_cc_year
        on population (country_code, year)
    ) by oracle;

    execute (
        create index idx_popgrowth_cc_year
        on pop_growth (country_code, year)
    ) by oracle;

    disconnect from oracle;
quit;


/* ============================================================
   ETAPA 3 - CENÁRIO "COM ÍNDICE"
   ============================================================ */
%roda_query(cenario=COM_INDICE);


/* ============================================================
   ETAPA 4 - COMPARATIVO FINAL
   ============================================================ */
proc sql;
    create table work.resumo_comparativo as
    select
        cenario,
        count(*)          as qtd_execucoes,
        mean(segundos)     as tempo_medio format=8.3,
        min(segundos)      as tempo_min   format=8.3,
        max(segundos)      as tempo_max   format=8.3
    from work.tempos_teste
    group by cenario;
quit;

title "Tempos individuais de cada execução";
proc print data=work.tempos_teste noobs;
run;

title "Resumo comparativo: SEM ÍNDICE x COM ÍNDICE";
proc print data=work.resumo_comparativo noobs;
run;
title;

/* Cálculo do ganho percentual */
proc sql noprint;
    select tempo_medio into :media_sem
        from work.resumo_comparativo where cenario = "SEM_INDICE";
    select tempo_medio into :media_com
        from work.resumo_comparativo where cenario = "COM_INDICE";
quit;

%let ganho = %sysevalf((&media_sem - &media_com) / &media_sem * 100);

%put ============================================================;
%put RESUMO FINAL;
%put Tempo medio SEM indice: &media_sem segundos;
%put Tempo medio COM indice: &media_com segundos;
%put Ganho percentual: &ganho %;
%put ============================================================;


/* Indice não foi utilizado na query (TABLE ACCESS FULL) */

/*
PLAN_TABLE_OUTPUT
Plan hash value: 2609533303
 
------------------------------------------------------------------------------------
| Id | Operation | Name | Rows | Bytes | Cost (%CPU)| Time |
------------------------------------------------------------------------------------
| 0 | SELECT STATEMENT | | 3706 | 629K| 137 (1)| 00:00:01 |
| 1 | VIEW | VW_FOJ_0 | 3706 | 629K| 137 (1)| 00:00:01 |
|* 2 | HASH JOIN FULL OUTER| | 3706 | 629K| 137 (1)| 00:00:01 |
| 3 | VIEW | | 3308 | 109K| 68 (0)| 00:00:01 |
|* 4 | TABLE ACCESS FULL | POP_GROWTH | 3308 | 109K| 68 (0)| 00:00:01 |
| 5 | VIEW | | 3706 | 506K| 68 (0)| 00:00:01 |
|* 6 | TABLE ACCESS FULL | POPULATION | 3706 | 756K| 68 (0)| 00:00:01 |
------------------------------------------------------------------------------------
 
Predicate Information (identified by operation id):
---------------------------------------------------
 
2 - access("P"."COUNTRY_CODE"="G"."COUNTRY_CODE" AND
"P"."YEAR_NUM"="G"."YEAR")
4 - filter("YEAR"=2000 OR "YEAR"=2002 OR "YEAR"=2004 OR "YEAR"=2006 OR
"YEAR"=2008 OR "YEAR"=2010 OR "YEAR"=2012 OR "YEAR"=2014 OR "YEAR"=2016 OR
"YEAR"=2018 OR "YEAR"=2021 OR "YEAR"=2022)
6 - filter("YEAR"='2000' OR "YEAR"='2002' OR "YEAR"='2004' OR
"YEAR"='2006' OR "YEAR"='2008' OR "YEAR"='2010' OR "YEAR"='2012' OR
"YEAR"='2014' OR "YEAR"='2016' OR "YEAR"='2018' OR "YEAR"='2021' OR
"YEAR"='2022')
 
Note
-----
- dynamic statistics used: dynamic sampling (level=2)


Não utilizaremos indice mais, por conta da quantidade de linhas*/