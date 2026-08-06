%include "/home/student/github_bruno/student/brunosastre/natdis_project/01_setup_load/1_1_parameters.sas";
options fullstimer msglevel=i symbolgen;

/* ============================================================
   Start of Analisys
   ============================================================ */
proc contents data=&lib_cas.._ALL_;run;

/* notes

all tables (earthquake, tsunami and volcano) contains the following variables/columns:
latitude, longitude, year, month, day, eq, tsu, vol

regarding the detail tables (eqdetails, tsudetails and voldetails):

- each table has a key: eq, tsu and vol

so...

- it's possible to join earthquake + eqdetails by the eq variable
- both tables have 5225 observations

- the same applies to the other tables:
-> tsunami + tsudetails by the tsu variable
-> volcano + voldetails by the vol variable

the thing is that all the source tables have the eq, tsu and vol variables.

I'm going to check if all the ids can be joined and are matches
*/

/*1544 and 5225*/
/*proc fedsql sessref=&sess_nm.;
    select count(*) as matches_eq_tsu 
    from &lib_cas..earthquake d1 
    inner join &lib_cas..tsunami d2
    on d1.tsu = d2.tsu;

    select count(*) as matches_eq_vol
    from &lib_cas..earthquake d1
    inner join &lib_cas..volcano d2
    on d1.vol=d2.vol;
quit;*/

/* notes

5225 is the same amount of rows earthquake table has...
*/

* didn't help much;
/*
proc freq data=&lib_cas..earthquake;
    tables vol / missing;
run;

proc freq data=&lib_cas..volcano;
    tables vol / missing;
run;*/
/*
proc sql;
    select
        min(vol) as min_vol,
        max(vol) as max_vol,
        count(distinct vol) as distinct_vol
    from &lib_cas..earthquake;

    select
        min(vol) as min_vol,
        max(vol) as max_vol,
        count(distinct vol) as distinct_vol
    from &lib_cas..volcano;
quit;
*/

/* notes 

5225 = earthquake

5166 without volcano

59 with volcano

5225 - 5166 = 59*/

/*MATCHES_EQ_VOL 59*/
/*proc fedsql sessref=&sess_nm.;
    select count(*) as matches_eq_vol
    from &lib_cas..earthquake e
    inner join &lib_cas..volcano v
    on e.vol=v.vol
    where e.vol is not null;
quit;*/

/* it confirms that vol is a valid relationship between earthquake and volcanoes

-only 59 earthquakes have a volcano associated with it
*/

/* Can earthquakes, volcanos, and tsunamis be related events?

Answer: Yes. The tests performed that some earthquakes has a volcano id (vol) associated with earthquakes, 
allowing to create relationships between earthquake and volcano

It's safe to suppose that the tsu identifier suggests a relationship between earthquakes and tsunamis.


What type of join should be used?

left join because all the relationships are optional. a natural disaster can occur without any dependencies of the other events.
using a inner join, for example, could result in data los. The left join preserves all the registered disasters, adding tsu or vol information only when there's a match.

*/

/* final test */

proc fedsql sessref=&sess_nm.;
    select count(*) as total_earthquakes, sum(case when tsu is null then 1 else 0
            end) as without_tsunami,

        sum(case when tsu is not null then 1
                else 0 end) as with_tsunami,

        round(100.0 * sum(case when tsu is null then 1 else 0 end) / count(*)
        ,0.01) as pct_without_tsunami,

        round(100.0 * sum(case when tsu is not null then 1 else 0 end)/ count(*)
        ,0.01) as pct_with_tsunami

    from &lib_cas..earthquake;
quit;

/* notes - if we use inner join, it could exclude most earthquake observations. 
only 30% of earthquake records have a related tsunami event

*/

/* ============================================================
   End of Anaisys
   ============================================================ */


/* ============================================================
   First Join - Eq and eqdetails
   ============================================================ */

proc fedsql sessref=&sess_nm.;
    create table &lib_cas..earthquake_full {options replace=true} as
    select e.*, ed.earthquake_magnitude,ed.earthquake_mmi_intensity,ed.focal_depth
    from &lib_cas..earthquake e
    left join &lib_cas..eqdetails ed
        on e.eq = ed.eq
;


/* ============================================================
   Second Join - Tsu and tsudetails
   ============================================================ */


    create table &lib_cas..tsunami_full {options replace=true} as
    select  t.*, td.tsunami_event_validity,td.tsunami_cause_code,
        td.maximum_water_height, td.tsunami_magnitude,td.tsunami_intensity
    from &lib_cas..tsunami t
    left join &lib_cas..tsudetails td
        on t.tsu = td.tsu;


/* ============================================================
   Third Join - Vol and voldetails
   ============================================================ */

     create table &lib_cas..volcano_full {options replace=true} as
    select  v.*, vd.volcano_name,vd.volcano_type,
        vd.volcanic_agent, vd.elevation,vd.vei
    from &lib_cas..volcano v
    left join &lib_cas..voldetails vd
        on v.vol = vd.vol;

/* ============================================================
   Reporting Table
   ============================================================ */

    /*
    create table &lib_cas..natural_disasters {options replace=true} as
    select

        e.*,

     
        t.Tsunami_Event_Validity,
        t.Tsunami_Cause_Code,
        t.Maximum_Water_Height,
        t.Tsunami_Magnitude,
        t.Tsunami_Intensity,

      
        v.Volcano_Name,
        v.Volcano_Type,
        v.Volcanic_Agent,
        v.Elevation,
        v.VEI,

   
        l.Country

    from &lib_cas..earthquake_full e

        left join &lib_cas..tsunami_full t
            on e.tsu = t.tsu

        left join &lib_cas..volcano_full v
            on e.vol = v.vol

        left join &lib_cas..location l
            on e.latitude  = l.latitude
           and e.longitude = l.longitude
;

*/

/*------------------------------------------------------------*
 | Create NATURAL_DISASTERS table in the NATDIS caslib
 | Source tables are read from &lib_cas
 | Target table will be stored in NATDIS.NATURAL_DISASTERS
 *------------------------------------------------------------*/

/* capture the upload timestamp once */

%let upload_dt = %sysfunc(datetime());


/*
The final table contains one record per natural disaster
event, with Event_Type identifying whether the row came from
eq,tsu, or vol */


create table natdis.natural_disasters_raw {options replace=true} as

/*========================================================*
    | EARTHQUAKE records
    *========================================================*/
select
    e.year                                           as Year,
    e.month                                          as Month,
    e.day                                            as Day,

    'EARTHQUAKE'                                     as Event_Type,

    l.Country_DQ                                     as Country,

    coalesce(e.Latitude, d.Latitude)                 as Latitude,
    coalesce(e.Longitude, d.Longitude)               as Longitude,

    e.eq                                             as Eq,
    e.tsu                                            as Tsu,
    e.vol                                            as Vol,

    e.URL                                            as URL,

    e.Deaths                                         as Deaths,
    e.Injuries                                       as Injuries,
    e.Injuries_Description                           as Injuries_Description,
    e.Damage                                         as Damage,
    e.Houses_Destroyed                               as Houses_Destroyed,
    e.Houses_Destroyed_Description                   as Houses_Destroyed_Description,
    e.Total_Deaths                                   as Total_Deaths,
    e.Total_Death_Description                        as Total_Death_Description,
    e.Total_Injuries                                 as Total_Injuries,
    e.Total_Injuries_Description                     as Total_Injuries_Description,
    e.Total_Damage                                   as Total_Damage,
    e.Total_Damage_Description                       as Total_Damage_Description,

    d.Earthquake_Magnitude                           as Earthquake_Magnitude,
    d.Focal_Depth                                    as Focal_Depth,
    d.Earthquake_MMI_Intensity                       as Earthquake_MMI_Intensity,

    cast(null as double)                             as Tsunami_Event_Validity,
    cast(null as double)                             as Tsunami_Cause_Code,
    cast(null as double)                             as Deposits,
    cast(null as double)                             as Maximum_Water_Height,
    cast(null as double)                             as Number_of_Runups,
    cast(null as double)                             as Tsunami_Magnitude,
    cast(null as double)                             as Tsunami_Intensity,

    cast(null as double)                             as Elevation,
    cast(null as varchar(21))                        as Volcano_Type,
    cast(null as double)                             as VEI,
    cast(null as varchar(9))                         as Volcanic_Agent,
    cast(null as varchar(27))                        as Volcano_Name,

    &upload_dt.                                      as Upload_Date

from &lib_cas..earthquake e

    left join &lib_cas..eqdetails d
        on e.eq = d.eq

    left join &lib_cas..location_dq l
        on coalesce(e.Latitude, d.Latitude) = l.Latitude
        and coalesce(e.Longitude, d.Longitude) = l.Longitude


union all


/*========================================================*
    | TSUNAMI records
    *========================================================*/
select
    t.year                                           as Year,
    t.month                                          as Month,
    t.day                                            as Day,

    'TSUNAMI'                                        as Event_Type,

    l.Country_DQ                                     as Country,

    coalesce(t.Latitude, d.Latitude)                 as Latitude,
    coalesce(t.Longitude, d.Longitude)               as Longitude,

    t.eq                                             as Eq,
    t.tsu                                            as Tsu,
    t.vol                                            as Vol,

    t.URL                                            as URL,

    t.Deaths                                         as Deaths,
    t.Injuries                                       as Injuries,
    t.Injuries_Description                           as Injuries_Description,
    t.Damage                                         as Damage,
    t.Houses_Destroyed                               as Houses_Destroyed,
    t.Houses_Destroyed_Description                   as Houses_Destroyed_Description,
    t.Total_Deaths                                   as Total_Deaths,
    t.Total_Death_Description                        as Total_Death_Description,
    t.Total_Injuries                                 as Total_Injuries,
    t.Total_Injuries_Description                     as Total_Injuries_Description,
    t.Total_Damage                                   as Total_Damage,
    t.Total_Damage_Description                       as Total_Damage_Description,

    cast(null as double)                             as Earthquake_Magnitude,
    cast(null as double)                             as Focal_Depth,
    cast(null as double)                             as Earthquake_MMI_Intensity,

    d.Tsunami_Event_Validity                         as Tsunami_Event_Validity,
    d.Tsunami_Cause_Code                             as Tsunami_Cause_Code,
    d.Deposits                                       as Deposits,
    d.Maximum_Water_Height                           as Maximum_Water_Height,
    d.Number_of_Runups                               as Number_of_Runups,
    d.Tsunami_Magnitude                              as Tsunami_Magnitude,
    d.Tsunami_Intensity                              as Tsunami_Intensity,

    cast(null as double)                             as Elevation,
    cast(null as varchar(21))                        as Volcano_Type,
    cast(null as double)                             as VEI,
    cast(null as varchar(9))                         as Volcanic_Agent,
    cast(null as varchar(27))                        as Volcano_Name,

    &upload_dt.                                      as Upload_Date

from &lib_cas..tsunami t

    left join &lib_cas..tsudetails d
        on t.tsu = d.tsu

    left join &lib_cas..location_dq l
        on coalesce(t.Latitude, d.Latitude) = l.Latitude
        and coalesce(t.Longitude, d.Longitude) = l.Longitude


union all


/*========================================================*
    | VOLCANO records
    *========================================================*/
select
    v.year                                           as Year,
    v.month                                          as Month,
    v.day                                            as Day,

    'VOLCANO'                                        as Event_Type,

    l.Country_DQ                                     as Country,

    coalesce(v.Latitude, d.Latitude)                 as Latitude,
    coalesce(v.Longitude, d.Longitude)               as Longitude,

    v.eq                                             as Eq,
    v.tsu                                            as Tsu,
    v.vol                                            as Vol,

    v.URL                                            as URL,

    v.Deaths                                         as Deaths,
    v.Injuries                                       as Injuries,
    v.Injuries_Description                           as Injuries_Description,
    v.Damage                                         as Damage,
    v.Houses_Destroyed                               as Houses_Destroyed,
    v.Houses_Destroyed_Description                   as Houses_Destroyed_Description,
    v.Total_Deaths                                   as Total_Deaths,
    v.Total_Death_Description                        as Total_Death_Description,
    v.Total_Injuries                                 as Total_Injuries,
    v.Total_Injuries_Description                     as Total_Injuries_Description,
    v.Total_Damage                                   as Total_Damage,
    v.Total_Damage_Description                       as Total_Damage_Description,

    cast(null as double)                             as Earthquake_Magnitude,
    cast(null as double)                             as Focal_Depth,
    cast(null as double)                             as Earthquake_MMI_Intensity,

    cast(null as double)                             as Tsunami_Event_Validity,
    cast(null as double)                             as Tsunami_Cause_Code,
    cast(null as double)                             as Deposits,
    cast(null as double)                             as Maximum_Water_Height,
    cast(null as double)                             as Number_of_Runups,
    cast(null as double)                             as Tsunami_Magnitude,
    cast(null as double)                             as Tsunami_Intensity,

    d.Elevation                                      as Elevation,
    d.Volcano_Type                                   as Volcano_Type,
    d.VEI                                            as VEI,
    d.Volcanic_Agent                                 as Volcanic_Agent,
    d.Volcano_Name                                   as Volcano_Name,

    &upload_dt.                                      as Upload_Date

from &lib_cas..volcano v

    left join &lib_cas..voldetails d
        on v.vol = d.vol

    left join &lib_cas..location_dq l
        on coalesce(v.Latitude, d.Latitude) = l.Latitude
        and coalesce(v.Longitude, d.Longitude) = l.Longitude
;
quit;


/*------------------------------------------------------------*
 | Step 2 - Apply label and datetime format to Upload_Date
 |
 | PROC FEDSQL creates the column, but this DATA step applies
 | the required label and a readable datetime format.
 *------------------------------------------------------------*/

data natdis.natural_disasters;
    set natdis.natural_disasters_raw;

    label Upload_Date = "Date Uploaded";
    format Upload_Date datetime20.;
run;


/*------------------------------------------------------------*
 | Step 3 - Optional cleanup
 |
 | Remove the intermediate raw table if you do not need it.
 *------------------------------------------------------------*/

proc casutil;
    droptable casdata="natural_disasters_raw"
              incaslib="natdis"
              quiet;
  
quit;