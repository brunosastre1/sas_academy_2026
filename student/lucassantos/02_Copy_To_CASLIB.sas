/*************************************************************************
Project 2 - Natural Disasters

Requirement 3.3.2
Copy the Source Tables to a Caslib

Purpose:
Create the NatDis caslib and copy the source tables into CAS.
*************************************************************************/

/* Source library */

libname natsrc "/casestudy/natdis/data/disasters_thru_2022";

/* Start CAS session */

cas;

/* Create caslib */

caslib NatDis
    path="/casestudy/natdis/caslib"
    datasource=(srctype="path");

/* Load source tables into CAS */

proc casutil;
    load data=natsrc.earthquake outcaslib="NatDis" casout="EARTHQUAKE" replace;
    load data=natsrc.tsunami    outcaslib="NatDis" casout="TSUNAMI" replace;
    load data=natsrc.volcano    outcaslib="NatDis" casout="VOLCANO" replace;
    load data=natsrc.location   outcaslib="NatDis" casout="LOCATION" replace;

    load data=natsrc.eqdetails  outcaslib="NatDis" casout="EQDETAILS" replace;
    load data=natsrc.tsudetails outcaslib="NatDis" casout="TSUDETAILS" replace;
    load data=natsrc.voldetails outcaslib="NatDis" casout="VOLDETAILS" replace;

    list tables incaslib="NatDis";
quit;