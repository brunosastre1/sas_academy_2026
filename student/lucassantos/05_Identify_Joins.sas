/*************************************************************************
Project 2 - Natural Disasters

Requirement 3.3.5
Identify the Columns Needed to Join the Tables

Purpose:
Identify and document join relationships between source tables.
*************************************************************************/

cas;
caslib _all_ assign;

/*----------------------------------------------------------
Table Information
----------------------------------------------------------*/

proc contents data=natdis.earthquake_tr;
run;

proc contents data=natdis.eqdetails;
run;

proc contents data=natdis.tsunami_tr;
run;

proc contents data=natdis.tsudetails;
run;

proc contents data=natdis.volcano_tr;
run;

proc contents data=natdis.voldetails;
run;

proc contents data=natdis.location_tr;
run;

/*----------------------------------------------------------
Join Relationship Analysis

EARTHQUAKE_TR
    ↔ EQDETAILS
    using EQ

TSUNAMI_TR
    ↔ TSUDETAILS
    using TSU

VOLCANO_TR
    ↔ VOLDETAILS
    using VOL

LOCATION_TR
    ↔ Disaster Tables
    using LATITUDE + LONGITUDE

Analysis:

- Earthquakes can have related tsunami events
- Earthquakes can have related volcano events
- Relationships are optional

Join Strategy:

LEFT JOIN should be used to preserve all
source disaster records and add detail
information only when a match exists.
----------------------------------------------------------*/

data _null_;

    put "==============================================";
    put "JOIN RELATIONSHIPS";
    put "==============================================";

    put "EARTHQUAKE_TR <-> EQDETAILS : EQ";
    put "TSUNAMI_TR    <-> TSUDETAILS: TSU";
    put "VOLCANO_TR    <-> VOLDETAILS: VOL";

    put "LOCATION_TR joined using:";
    put "LATITUDE + LONGITUDE";

    put " ";

    put "Recommended Join Type:";
    put "LEFT JOIN";

    put " ";

    put "Reason:";
    put "Not all disasters have related";
    put "tsunami or volcano information.";

    put "LEFT JOIN preserves all events.";

run;