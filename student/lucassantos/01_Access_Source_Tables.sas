/*************************************************************************
Project 2 - Natural Disasters

Requirement 3.3.1
Access the Source Tables

Purpose:
Verify access to the Natural Disasters source tables and inspect
their structure.
*************************************************************************/

libname natsrc "/casestudy/natdis/data/disasters_thru_2022";

proc contents data=natsrc._all_ nods;
run;