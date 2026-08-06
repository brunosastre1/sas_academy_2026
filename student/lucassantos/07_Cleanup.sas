/*************************************************************************
Project 2 - Natural Disasters

Requirement 3.3.8
Delete Tables that are No Longer Needed

Purpose:
Remove temporary tables after validating the
NATURAL_DISASTERS reporting table.
*************************************************************************/

cas;
caslib _all_ assign;

/*----------------------------------------------------------
Drop Intermediate Tables
----------------------------------------------------------*/

proc casutil;

    droptable casdata="EARTHQUAKE_TR"
              incaslib="NATDIS"
              quiet;

    droptable casdata="TSUNAMI_TR"
              incaslib="NATDIS"
              quiet;

    droptable casdata="VOLCANO_TR"
              incaslib="NATDIS"
              quiet;

    droptable casdata="LOCATION_TR"
              incaslib="NATDIS"
              quiet;

quit;

/*----------------------------------------------------------
Verify Remaining Tables
----------------------------------------------------------*/

proc contents data=natdis._all_;
run;

/*----------------------------------------------------------
Verify NATURAL_DISASTERS Exists
----------------------------------------------------------*/

proc sql;

    select
        count(*) as Total_Rows

    from natdis.natural_disasters;

quit;