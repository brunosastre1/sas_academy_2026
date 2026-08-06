%include "/home/student/github_bruno/student/brunosastre/natdis_project/01_setup_load/1_1_parameters.sas";

options fullstimer msglevel=i symbolgen;


* ============================================================
   Setup Config
   ============================================================ */

* main source of data;
libname &lib_sas. '/casestudy/natdis/data/disasters_thru_2022';


* validate if data can be accessed - it doesn't need to be on all the time;
/*
proc contents data=natdis._ALL_;
run;
*/


* create session;
cas &sess_nm.;

* create path based caslib;
* research difference caslib pvcas path="<insertpath>" libref=pvcas;
caslib &lib_cas. datasource=(srctype="path") path="/casestudy/natdis/caslib" sessref=&sess_nm.;

* point the caslib to a library;
libname &lib_cas. cas caslib=&lib_cas.;

* push natdis data to a caslib - now it's in memory;
proc casutil incaslib="&lib_sas." outcaslib="&lib_cas";
    load data=&lib_sas..earthquake  casout="earthquake"  replace;
    load data=&lib_sas..tsunami     casout="tsunami"     replace;
    load data=&lib_sas..volcano     casout="volcano"     replace;
    load data=&lib_sas..location    casout="location"    replace;
    load data=&lib_sas..eqdetails   casout="eqdetails"   replace;
    load data=&lib_sas..tsudetails  casout="tsudetails"  replace;
    load data=&lib_sas..voldetails  casout="voldetails"  replace;
run;

/* verify if all the tables were successfully copied
 FEDSQL - Running on CAS due to "sessref" */

/*proc fedsql iptrace sessref=disasterSession ;
    select count(*) from &lib_cas..earthquake;
    select count(*) from &lib_cas..tsunami;
    select count(*) from &lib_cas..volcano;
    select count(*) from &lib_cas..location;
    select count(*) from &lib_cas..eqdetails;
    select count(*) from &lib_cas..tsudetails;
    select count(*) from &lib_cas..voldetails;
quit;

proc contents data=&lib_cas.._ALL_;run;

*contents from casutil does not work with ALL;
proc casutil;
    contents casdata=_ALL_ incaslib="&lib_cas.";
run;    
    */



libname dis2023 "/casestudy/natdis/data/disasters_2023";

libname dis2024 "/casestudy/natdis/data/disasters_2024";