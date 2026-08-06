%include "/home/student/github_bruno/student/brunosastre/natdis_project/01_setup_load/1_1_parameters.sas";

/*------------------------------------------------------------*
 | Cleanup
 |
 | Remove the intermediate tables.
 *------------------------------------------------------------*/

proc casutil;
    droptable casdata="earthquake" incaslib="&lib_cas." quiet;
    droptable casdata="volcano" incaslib="&lib_cas." quiet;
    droptable casdata="tsunami" incaslib="&lib_cas." quiet;
    droptable casdata="location" incaslib="&lib_cas." quiet;
    droptable casdata="eqdetails" incaslib="&lib_cas." quiet;
    droptable casdata="tsudetails" incaslib="&lib_cas." quiet;
    droptable casdata="voldetails" incaslib="&lib_cas." quiet;
quit;