options symbolgen;

/* ============================================================
   Setup Config
   ============================================================ */

%let lib_sas =natdis;
%let lib_cas =natCas;
%let sess_nm =disasterSession;

%let project_root=/home/student/github_bruno/student/brunosastre/natdis_project;


%let path_orcl='//server.demo.sas.com:1521/ORCL';
%let years_num=2000,2002,2004,2006,2008,2010,2012,2014,2016,2018,2021,2022;
%let perf_parameters=readbuff=32000 DB_LENGTH_SEMANTICS_BYTE=NO  DBCLIENT_MAX_BYTES=1;
%let auth="OracleAuth"; /* used authentication domain just for fun */
