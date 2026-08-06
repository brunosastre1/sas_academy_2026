/*************************************************************************
Project 2 - Natural Disasters

Requirement 3.3.6
Join the Source Tables

Requirement 3.3.7
Create the NATURAL_DISASTERS Table

Purpose:
Join source tables and create the final reporting table.
*************************************************************************/

cas;
caslib _all_ assign;

/*----------------------------------------------------------
Create NATURAL_DISASTERS
----------------------------------------------------------*/

proc fedsql sessref=casauto;

create table natdis.natural_disasters {options replace=true} as

/*==========================================================
EARTHQUAKE EVENTS
==========================================================*/
select

    e.year,
    e.month,
    e.day,

    'EARTHQUAKE' as Event_Type,

    l.country as Country,

    e.latitude,
    e.longitude,

    e.eq,
    e.tsu,
    e.vol,

    e.url,

    e.deaths,
    e.injuries,
    e.injuries_description,
    e.damage,
    e.houses_destroyed,
    e.houses_destroyed_description,
    e.total_deaths,
    e.total_death_description,
    e.total_injuries,
    e.total_injuries_description,
    e.total_damage,
    e.total_damage_description,

    d.earthquake_magnitude,
    d.focal_depth,
    d.earthquake_mmi_intensity,

    cast(null as double) as tsunami_event_validity,
    cast(null as double) as tsunami_cause_code,
    cast(null as double) as deposits,
    cast(null as double) as maximum_water_height,
    cast(null as double) as number_of_runups,
    cast(null as double) as tsunami_magnitude,
    cast(null as double) as tsunami_intensity,

    cast(null as double) as elevation,
    cast(null as varchar(50)) as volcano_type,
    cast(null as double) as vei,
    cast(null as varchar(50)) as volcanic_agent,
    cast(null as varchar(100)) as volcano_name,

    datetime() as Upload_Date

from natdis.earthquake_tr e

left join natdis.eqdetails d
    on e.eq = d.eq

left join natdis.location_tr l
    on e.latitude = l.latitude
   and e.longitude = l.longitude

union all

/*==========================================================
TSUNAMI EVENTS
==========================================================*/
select

    t.year,
    t.month,
    t.day,

    'TSUNAMI' as Event_Type,

    l.country as Country,

    t.latitude,
    t.longitude,

    t.eq,
    t.tsu,
    t.vol,

    t.url,

    t.deaths,
    t.injuries,
    t.injuries_description,
    t.damage,
    t.houses_destroyed,
    t.houses_destroyed_description,
    t.total_deaths,
    t.total_death_description,
    t.total_injuries,
    t.total_injuries_description,
    t.total_damage,
    t.total_damage_description,

    cast(null as double) as earthquake_magnitude,
    cast(null as double) as focal_depth,
    cast(null as double) as earthquake_mmi_intensity,

    d.tsunami_event_validity,
    d.tsunami_cause_code,
    d.deposits,
    d.maximum_water_height,
    d.number_of_runups,
    d.tsunami_magnitude,
    d.tsunami_intensity,

    cast(null as double) as elevation,
    cast(null as varchar(50)) as volcano_type,
    cast(null as double) as vei,
    cast(null as varchar(50)) as volcanic_agent,
    cast(null as varchar(100)) as volcano_name,

    datetime() as Upload_Date

from natdis.tsunami_tr t

left join natdis.tsudetails d
    on t.tsu = d.tsu

left join natdis.location_tr l
    on t.latitude = l.latitude
   and t.longitude = l.longitude

union all

/*==========================================================
VOLCANO EVENTS
==========================================================*/
select

    v.year,
    v.month,
    v.day,

    'VOLCANO' as Event_Type,

    l.country as Country,

    v.latitude,
    v.longitude,

    v.eq,
    v.tsu,
    v.vol,

    v.url,

    v.deaths,
    v.injuries,
    v.injuries_description,
    v.damage,
    v.houses_destroyed,
    v.houses_destroyed_description,
    v.total_deaths,
    v.total_death_description,
    v.total_injuries,
    v.total_injuries_description,
    v.total_damage,
    v.total_damage_description,

    cast(null as double) as earthquake_magnitude,
    cast(null as double) as focal_depth,
    cast(null as double) as earthquake_mmi_intensity,

    cast(null as double) as tsunami_event_validity,
    cast(null as double) as tsunami_cause_code,
    cast(null as double) as deposits,
    cast(null as double) as maximum_water_height,
    cast(null as double) as number_of_runups,
    cast(null as double) as tsunami_magnitude,
    cast(null as double) as tsunami_intensity,

    d.elevation,
    d.volcano_type,
    d.vei,
    d.volcanic_agent,
    d.volcano_name,

    datetime() as Upload_Date

from natdis.volcano_tr v

left join natdis.voldetails d
    on v.vol = d.vol

left join natdis.location_tr l
    on v.latitude = l.latitude
   and v.longitude = l.longitude

;

quit;

/*----------------------------------------------------------
Validation
----------------------------------------------------------*/

proc contents data=natdis.natural_disasters;
run;

proc sql;

    select
        count(*) as Total_Rows

    from natdis.natural_disasters;

quit;

proc freq data=natdis.natural_disasters;

    tables Event_Type / missing;

run;

proc sql;

    select
        count(*) as Total_Rows,
        sum(missing(Country)) as Missing_Country,
        sum(missing(URL)) as Missing_URL,
        sum(missing(Year)) as Missing_Year

    from natdis.natural_disasters;

quit;

proc print
    data=natdis.natural_disasters(obs=20);
run;

proc freq data=natdis.natural_disasters;
    tables Event_Type;
run;