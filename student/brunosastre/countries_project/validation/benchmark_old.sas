/* ============================================================
BENCHMARK - PROCESS_COUNTRY_DATA
Original vs Optimized
 
This program:
1. Runs the original program
2. Runs the optimized program
3. Captures execution time
4. Reads SAS logs generated with FULLSTIMER
5. Extracts Block Input and Block Output operations
6. Calculates Block I/O percent savings
============================================================ */

%include "/home/student/github_bruno/student/brunosastre/countries_project/optimized/parameters.sas";

options sastrace=off;
/* ============================================================
   BENCHMARK - PROCESS_COUNTRY_DATA
   Original vs Optimized
   ============================================================ */

   /*
proc printto log='/home/student/github_bruno/student/brunosastre/countries_project/logs/benchmark_case1.log';
run;
*/


/* ============================================================
   Table to store results
   ============================================================ */
proc sql;
    create table work.execution_times
    (
        scenario char(20),
        seconds  num
    );
quit;


/* ============================================================
   Timing macro
   ============================================================ */
%macro measure_execution(scenario=, program=);

    %local t0 t1 duration;

    %put ============================================================;
    %put STARTING &scenario;
    %put ============================================================;

    %let t0=%sysfunc(datetime());

    %include "&program.";

    %let t1=%sysfunc(datetime());
    %let duration=%sysevalf(&t1-&t0);

    proc sql;
        insert into work.execution_times
        values("&scenario.", &duration.);
    quit;

    %put ============================================================;
    %put &scenario COMPLETED IN &duration SECONDS;
    %put ============================================================;

%mend;


/* ============================================================
   Execute ORIGINAL
   ============================================================ */
%measure_execution(
    scenario=ORIGINAL,
    program=&ORIGINAL.
);


/* ============================================================
   Execute OPTIMIZED
   ============================================================ */
%measure_execution(
    scenario=OPTIMIZED,
    program=&OPTIMIZED.
);


/* ============================================================
   Results
   ============================================================ */
title "Program Execution Time";

proc print data=work.execution_times noobs;
run;


/* ============================================================
   Create comparison table
   ============================================================ */
proc transpose
    data=work.execution_times
    out=work.execution_compare(drop=_NAME_);
    id scenario;
    var seconds;
run;


/* ============================================================
   Calculate improvement
   ============================================================ */
data work.final_results;
    set work.execution_compare;

    performance_gain =
        ((ORIGINAL - OPTIMIZED) / ORIGINAL) * 100;

    format
        ORIGINAL         8.3
        OPTIMIZED        8.3
        performance_gain 8.3;
run;


title "Final Comparison";

proc report data=work.final_results;
run;

/* was going to add ods but I ran out of time */
/*

ods html
    path="/home/student/github_bruno/student/brunosastre/countries_project/validation"
    file="benchmark_results.html"
    style=htmlblue;

title "Execution Time Comparison";

proc report data=work.final_results nowd;
run;

title "Individual Execution Times";

proc report data=work.execution_times nowd;
run;

ods html close;
*/