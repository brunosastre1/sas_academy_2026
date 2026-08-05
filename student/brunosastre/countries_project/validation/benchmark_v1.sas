%include "/home/student/github_bruno/student/brunosastre/countries_project/optimized/parameters.sas";

/* ============================================================
 Some parts done with copilot - didn't have time to learn how to parse a log in sas.

COUNTRIES PROJECT BENCHMARK
   Original vs Optimized

   Measures:
   - Execution time
   - Block Input Operations
   - Block Output Operations
   - Total Block I/O
   - I/O savings percentage

   Case Study formula:
   ((Original Total Block I/O - Optimized Total Block I/O)
    / Original Total Block I/O) * 100

   IMPORTANT:
   Both the ORIGINAL and OPTIMIZED programs must contain the marker line

       %put NOTE: ===PIPELINE_END===;

   placed immediately before the validation/comparison section
   (PROC COMPARE, fetching Oracle tables back to WORK, PROC CONTENTS
   used only for validation, etc). Everything logged AFTER that
   marker is excluded from the Block I/O totals below, per the
   case study instruction: "Do not include the steps for verifying
   the output of your program in the efficiency improvement
   calculations."
   ============================================================ */

options fullstimer msglevel=i sastrace=off;

/* ============================================================
   Log files
   ============================================================ */

%let LOG_ORIGINAL=&project_root./logs/benchmark_original.log;
%let LOG_OPTIMIZED=&project_root./logs/benchmark_optimized.log;

/* ============================================================
   Clean previous benchmark outputs
   ============================================================ */

proc datasets lib=work nolist nowarn;
    delete
        execution_times
        block_lines_original
        block_lines_optimized
        block_lines
        io_values
        io_results
        io_savings
        time_compare
        final_results;
quit;

/* ============================================================
   Table to store execution time
   ============================================================ */

proc sql;
    create table work.execution_times
    (
        scenario char(20),
        seconds num
    );
quit;

/* ============================================================
   Macro to execute a program and capture its log
   ============================================================ */

%macro measure_execution(scenario=, program=, logfile=);

    %local t0 t1 duration;

    %put ============================================================;
    %put STARTING &scenario.;
    %put PROGRAM: &program.;
    %put LOGFILE: &logfile.;
    %put ============================================================;

    proc printto log="&logfile." new;
    run;

    %let t0=%sysfunc(datetime());

    %include "&program.";

    %let t1=%sysfunc(datetime());
    %let duration=%sysevalf(&t1. - &t0.);

    proc printto;
    run;

    proc sql;
        insert into work.execution_times
        values ("&scenario.", &duration.);
    quit;

    %put ============================================================;
    %put &scenario. COMPLETED IN &duration. SECONDS;
    %put ============================================================;

%mend;

/* ============================================================
   Run original program
   ============================================================ */

%measure_execution(
    scenario=ORIGINAL,
    program=&ORIGINAL.,
    logfile=&LOG_ORIGINAL.
);

/* ============================================================
   Run optimized program
   ============================================================ */

%measure_execution(
    scenario=OPTIMIZED,
    program=&OPTIMIZED.,
    logfile=&LOG_OPTIMIZED.
);

/* ============================================================
   Read Block I/O lines from original log

   Stops counting once the ===PIPELINE_END=== marker is found,
   so validation/comparison steps (PROC COMPARE, fetching Oracle
   tables back to WORK for comparison, validation-only PROC
   CONTENTS, etc.) are excluded from the totals.
   ============================================================ */

data work.block_lines_original;
    length scenario $20 line $32767;
    retain capture_flag 1;

    infile "&LOG_ORIGINAL." truncover;
    input line $char32767.;

    /* Once the marker is found stop capturing further lines */
    if index(line, '===PIPELINE_END===') then capture_flag = 0;

    if capture_flag then do;
        if index(upcase(line), "BLOCK INPUT OPERATIONS")
        or index(upcase(line), "BLOCK OUTPUT OPERATIONS") then do;
            scenario = "ORIGINAL";
            output;
        end;
    end;

    keep scenario line;
run;

/* ============================================================
   Read Block I/O lines from optimized log

   Same marker-based cutoff logic as above.
   ============================================================ */

data work.block_lines_optimized;
    length scenario $20 line $32767;
    retain capture_flag 1;

    infile "&LOG_OPTIMIZED." truncover;
    input line $char32767.;

    if index(line, '===PIPELINE_END===') then capture_flag = 0;

    if capture_flag then do;
        if index(upcase(line), "BLOCK INPUT OPERATIONS")
        or index(upcase(line), "BLOCK OUTPUT OPERATIONS") then do;
            scenario = "OPTIMIZED";
            output;
        end;
    end;

    keep scenario line;
run;

/* ============================================================
   Combine Block I/O log lines
   ============================================================ */

data work.block_lines;
    set
        work.block_lines_original
        work.block_lines_optimized;
run;

/* ============================================================
   Extract numeric values from Block I/O lines
   ============================================================ */

data work.io_values;
    length scenario $20 metric $10 line $32767;

    set work.block_lines;

    if index(upcase(line), "BLOCK INPUT OPERATIONS") then do;
        metric = "INPUT";

        value = input(
                    compress(scan(strip(line), -1, ' '), ','),
                    best32.
                );

        output;
    end;

    else if index(upcase(line), "BLOCK OUTPUT OPERATIONS") then do;
        metric = "OUTPUT";

        value = input(
                    compress(scan(strip(line), -1, ' '), ','),
                    best32.
                );

        output;
    end;

    keep scenario metric line value;
run;

/* ============================================================
   Aggregate Block Input, Block Output and Total Block I/O
   ============================================================ */

proc sql;
    create table work.io_results as
    select
        scenario,

        sum(
            case
                when metric = "INPUT"
                then value
                else 0
            end
        ) as block_input_operations format=comma15.,

        sum(
            case
                when metric = "OUTPUT"
                then value
                else 0
            end
        ) as block_output_operations format=comma15.,

        calculated block_input_operations
        +
        calculated block_output_operations
            as total_block_io format=comma15.

    from work.io_values
    group by scenario;
quit;

/* ============================================================
   Calculate Block I/O savings
   ============================================================ */

proc sql;
    create table work.io_savings as
    select
        o.block_input_operations
            as original_block_input format=comma15.,

        o.block_output_operations
            as original_block_output format=comma15.,

        o.total_block_io
            as original_total_io format=comma15.,

        p.block_input_operations
            as optimized_block_input format=comma15.,

        p.block_output_operations
            as optimized_block_output format=comma15.,

        p.total_block_io
            as optimized_total_io format=comma15.,

        o.total_block_io - p.total_block_io
            as block_io_saved format=comma15.,

        case
            when o.total_block_io > 0 then
                ((o.total_block_io - p.total_block_io)
                 / o.total_block_io) * 100
            else .
        end
            as io_savings_pct format=8.2

    from
        work.io_results as o,
        work.io_results as p

    where
        o.scenario = "ORIGINAL"
        and p.scenario = "OPTIMIZED";
quit;

/* ============================================================
   Prepare execution time comparison
   ============================================================ */

proc transpose
    data=work.execution_times
    out=work.time_compare(drop=_name_);
    id scenario;
    var seconds;
run;

/* ============================================================
   Final benchmark results
   ============================================================ */

proc sql;
    create table work.final_results as
    select
        t.ORIGINAL
            as original_seconds format=8.3,

        t.OPTIMIZED
            as optimized_seconds format=8.3,

        t.ORIGINAL - t.OPTIMIZED
            as runtime_seconds_saved format=8.3,

        case
            when t.ORIGINAL > 0 then
                ((t.ORIGINAL - t.OPTIMIZED) / t.ORIGINAL) * 100
            else .
        end
            as runtime_savings_pct format=8.2,

        i.original_block_input,
        i.original_block_output,
        i.original_total_io,

        i.optimized_block_input,
        i.optimized_block_output,
        i.optimized_total_io,

        i.block_io_saved,
        i.io_savings_pct

    from
        work.time_compare as t,
        work.io_savings as i;
quit;

/* ============================================================
   Print results in SAS Studio
   ============================================================ */

title "Execution Times";
proc print data=work.execution_times noobs;
run;

/*
title "Block I/O Lines Extracted from Logs (validation steps excluded)";
proc print data=work.io_values noobs;
run;*/

title "Block I/O Summary (validation steps excluded)";
proc print data=work.io_results noobs;
run;

title "Final Benchmark Results (validation steps excluded)";
proc print data=work.final_results noobs;
run;

title;
