
* root path;
%let project_root=/home/student/github_bruno/student/brunosastre/countries_project;


/* Program paths */
%let ORIGINAL=&project_root./original/Process_Country_Data.sas;
%let OPTIMIZED=&project_root./optimized/Process_Country_Data_Optimized.sas;

%let benchmark_log_original=&project_root./logs/benchmark_original.log;
%let benchmark_log_original=&project_root./logs/benchmark_optimized.log;

/* Centralized connection parameters */
%let path_orcl='//server.demo.sas.com:1521/ORCL';
%let years_num=2000,2002,2004,2006,2008,2010,2012,2014,2016,2018,2021,2022;
%let perf_parameters=readbuff=32000;
%let auth="OracleAuth"; /* used authentication domain just for fun */
