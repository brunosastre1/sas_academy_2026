/*************************************************************************
Project 2 - Natural Disasters

Requirement 3.3.10
Create Reports

Purpose:
Create reports using the NATURAL_DISASTERS table.
*************************************************************************/

cas;
caslib _all_ assign;

/*----------------------------------------------------------
Report 1
Events for a Selected Country
----------------------------------------------------------*/

%let report_country = JAPAN;

title "Natural Disaster Events for &report_country";

proc print data=natdis.natural_disasters;

    where upcase(Country)=upcase("&report_country");

    var
        Year
        Month
        Day
        Event_Type
        Country
        Latitude
        Longitude
        URL;

run;

title;

/*----------------------------------------------------------
Report 2
Event Counts by Country for Selected Year
----------------------------------------------------------*/

%let report_year = 2022;

title "Event Counts by Country - &report_year";

proc freq data=natdis.natural_disasters;

    where Year=&report_year;

    tables Country*Event_Type / nocol norow;

run;

title;

/*----------------------------------------------------------
Summary Table
----------------------------------------------------------*/

proc fedsql sessref=casauto;

    create table natdis.report_summary
    {options replace=true} as

    select
        Country,
        Event_Type,
        count(*) as Event_Count

    from natdis.natural_disasters

    where Year=&report_year

    group by
        Country,
        Event_Type
    ;

quit;

/*----------------------------------------------------------
Display Summary
----------------------------------------------------------*/

title "Summary of Events by Country - &report_year";

proc print
    data=natdis.report_summary(obs=50);

run;

title;

/*----------------------------------------------------------
Validation
----------------------------------------------------------*/

proc contents
    data=natdis.report_summary;
run;

proc sql;

    select
        count(*) as Summary_Rows

    from natdis.report_summary;

quit;