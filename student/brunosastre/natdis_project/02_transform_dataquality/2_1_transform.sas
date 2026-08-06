%include "/home/student/github_bruno/student/brunosastre/natdis_project/01_setup_load/1_1_parameters.sas";
options fullstimer msglevel=i symbolgen;

* converting year, month, day columns to numeric for earthquake, tsunami and volcano - there's no way to alter table using proc cas utils;
data &lib_cas..earthquake;
    set &lib_cas..earthquake;

    year_num  = input(Year, 8.);
    month_num = input(Month, 8.);
    day_num   = input(Day, 8.);

    length URL $200;
    URL = catt("https://www.ngdc.noaa.gov/hazel/view/hazards/earthquake/event-moreinfo/",eq);

    drop year month day;
    rename year_num=year month_num=month day_num=day;
run;

*tsunami;
data &lib_cas..tsunami;
    set &lib_cas..tsunami;

    year_num  = input(Year, 8.);
    month_num = input(Month, 8.);
    day_num   = input(Day, 8.);

    length URL $200;
     URL = catt("https://www.ngdc.noaa.gov/hazel/view/hazards/tsunami/event-more-info/",tsu);

    drop year month day;
    rename year_num=year month_num=month day_num=day;
run;

*volcano;
data &lib_cas..volcano;
    set &lib_cas..volcano;

    year_num  = input(Year, 8.);
    month_num = input(Month, 8.);
    day_num   = input(Day, 8.);

    length URL $200;
     URL = catt("https://www.ngdc.noaa.gov/hazel/view/hazards/volcano/event-more-info/",vol);

    drop year month day;
    rename year_num=year month_num=month day_num=day;
    /*put "Processed on " _threadid_= _nthreads_=; - checking if threads were used*/
run;

*location - using proc fedsql;
proc fedsql sessref=&sess_nm. iptrace;
    create table &lib_cas..location {options replace=true} as 
        select *, cast(compress(scan(geo_coordinates, 1, ','),'() ') as double) as latitude, 
        cast(compress(scan(geo_coordinates, 2, ','), '() ') as double) as longitude 
        from &lib_cas..location;

quit;

/*** same result as above and apparently the same iptrace warning messages

WARNING: General error IPTRACE: Partial (SELECT) pushdown to  FAILURE!
WARNING: General error IPTRACE: Retextualized child query unavailable
WARNING: General error IPTRACE: Partial Query Tree pushdown to  SUCCESS!
WARNING: General error IPTRACE: Retextualized child query unavailable
WARNING: General error IPTRACE: Partial (for DDL emulation) pushdown to  SUCCESS WITH INFO!
WARNING: General error IPTRACE: Retextualized child query unavailable
WARNING: General error IPTRACE: Partial (for DDL emulation) pushdown to  SUCCESS!
WARNING: General error IPTRACE: Retextualized child query unavailable
NOTE: Table LOCATION_V2 was created in caslib NATCAS with 5735 rows returned.
WARNING: CAS action completed [OKAY]
FEDSQL: The fedsql.execDirect action returned rc=0x00000000

I need to do some research on how to avoid this warnings (if possible)


proc fedsql sessref=&sess_nm. iptrace;
    create table &lib_cas..location_v2 {options replace=true} as
    select *, 
        cast(compress(substring(Geo_Coordinates, 1, index(Geo_Coordinates, ',') - 1),'() ') as double) as Latitude,
        cast(compress(substring(Geo_Coordinates, index(Geo_Coordinates, ',') + 1), '() ' ) as double) as Longitude
    from &lib_cas..location;
quit;
*/

*dropping tables and changing the name of the new tables - moved to cleanup;
/*
proc casutil;
    droptable casdata="earthquake" incaslib="&lib_cas." quiet;
    droptable casdata="tsunami"    incaslib="&lib_cas." quiet;
    droptable casdata="volcano"    incaslib="&lib_cas." quiet;
    droptable casdata="location"    incaslib="&lib_cas." quiet;
    altertable casdata="earthquake_v2" incaslib="&lib_cas." rename="earthquake";
    altertable casdata="tsunami_v2" incaslib="&lib_cas." rename="tsunami";
    altertable casdata="volcano_v2" incaslib="&lib_cas." rename="volcano";
    altertable casdata="location_v2" incaslib="&lib_cas." rename="location";
quit;

*/