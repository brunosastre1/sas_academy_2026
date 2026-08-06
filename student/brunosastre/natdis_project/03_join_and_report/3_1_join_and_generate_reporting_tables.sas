%include "/home/student/github_bruno/student/brunosastre/natdis_project/01_setup_load/1_1_parameters.sas";

options fullstimer msglevel=i symbolgen;

*Capture one upload timestamp for all rows created by this run;
%let upload_dt = %sysfunc(datetime());


/* ============================================================
   Step: Join source tables and create reporting table

   design decision:
   - The finl NATURAL_DISASTERS table stores one row per event.
   - EARTHQUAKE, TSUNAMI, and VOLCANO rows are stacked with UNION ALL.
   - Event_Type identifies the origin of each row.
   - Detail tables are optional enrichments, so LEFT JOIN is used.
   - LOCATION is joined by calculated Latitude and Longitude.
     This satisfies the requirement that some joins need more than
     a single column in the join condition.

   why not inner?
   - it could remove events that do not have matching detail
     or location records.
   - left preserves the base disaster records and adds available
     enrichment data only when a match exists.

    A draft can be found in the same folder with my first attempt.
   ============================================================ */


/* ============================================================
   1. Review CAS table structures
   ============================================================ */

   proc contents data=&lib_cas.._ALL_;
run;



/* ============================================================
   2. Validate expected base row counts
   ============================================================ */

proc fedsql sessref=&sess_nm.;
    select 'EARTHQUAKE' as table_name,
           count(*) as row_count
    from &lib_cas..earthquake

    union all

    select 'TSUNAMI' as table_name,
           count(*) as row_count
    from &lib_cas..tsunami

    union all

    select 'VOLCANO' as table_name,
           count(*) as row_count
    from &lib_cas..volcano;



/* ============================================================
   3. Validate detail table relationships

   These checks confirm whether the detail tables can be used
   as enrichment tables without changing the expected number of
  rows
   ============================================================ */


    select
        'EARTHQUAKE_TO_EQDETAILS' as relationship,
        count(*) as base_rows,
        sum(case when d.eq is not null then 1 else 0 end) as matched_rows,
        sum(case when d.eq is null then 1 else 0 end) as unmatched_rows
    from &lib_cas..earthquake e
        left join &lib_cas..eqdetails d
            on e.eq = d.eq

    union all

    select
        'TSUNAMI_TO_TSUDETAILS' as relationship,
        count(*) as base_rows,
        sum(case when d.tsu is not null then 1 else 0 end) as matched_rows,
        sum(case when d.tsu is null then 1 else 0 end) as unmatched_rows
    from &lib_cas..tsunami t
        left join &lib_cas..tsudetails d
            on t.tsu = d.tsu

    union all

    select
        'VOLCANO_TO_VOLDETAILS' as relationship,
        count(*) as base_rows,
        sum(case when d.vol is not null then 1 else 0 end) as matched_rows,
        sum(case when d.vol is null then 1 else 0 end) as unmatched_rows
    from &lib_cas..volcano v
        left join &lib_cas..voldetails d
            on v.vol = d.vol;



/* ============================================================
 
  Can earthquakes, tsunamis, and volcanos be related events?
  Answer: Yes. The tests performed show that some earthquakes have a volcano id (vol) associated with earthquakes, 
  allowing to create relationships between earthquake and volcano

  It's safe to suppose that the tsu identifier suggests a relationship between earthquakes and tsunamis.

   ============================================================ */


    select count(*) as total_earthquakes, sum(case when tsu is null then 1 else 0
            end) as without_tsunami,

        sum(case when tsu is not null then 1
                else 0 end) as with_tsunami,

        round(100.0 * sum(case when tsu is null then 1 else 0 end) / count(*)
        ,0.01) as pct_without_tsunami,

        round(100.0 * sum(case when tsu is not null then 1 else 0 end)/ count(*)
        ,0.01) as pct_with_tsunami

    from &lib_cas..earthquake;


/* notes - if we use inner join, it could exclude most earthquake observations. 
only 30% of earthquake records have a related tsunami event*/




/* ============================================================
   5. Create NATURAL_DISASTERS reporting table

   Notes:
   - LEFT JOIN is used for all detail and location enrichments.
   - LOCATION uses a multi-column join:
       event latitude  = location latitude
       event longitude = location longitude
   - UNION ALL keeps the three event populations separated while
     storing them in one reporting table.
   ============================================================ */

    create table &lib_cas..natural_disasters {options replace=true} as

    /*========================================================*
        EARTHQUAKE records
    *========================================================*/
    select
        cast(e.year as integer)                                          as Year,
        cast(e.month as integer)                                         as Month,
        cast(e.day as integer)                                            as Day,
        'EARTHQUAKE'                                     as Event_Type,
        l.Country_DQ                                     as Country,
        e.Latitude                                       as Latitude,
        e.Longitude                                      as Longitude,
        e.eq                                             as Eq,
        e.tsu                                            as Tsu,
        e.vol                                            as Vol,
        e.URL                                            as URL,
        cast( e.Deaths  as integer)                                       as Deaths,
         cast(e.Injuries       as integer)                                as Injuries,
        e.Injuries_Description                           as Injuries_Description,
        e.Damage                                         as Damage,
        e.Houses_Destroyed                               as Houses_Destroyed,
        e.Houses_Destroyed_Description                   as Houses_Destroyed_Description,
        cast( e.Total_Deaths      as integer)                             as Total_Deaths,
        e.Total_Death_Description                        as Total_Death_Description,
        cast( e.Total_Injuries       as integer)                          as Total_Injuries,
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
        cast(null as varchar(30))                        as Volcano_Type,
        cast(null as double)                             as VEI,
        cast(null as varchar(20))                         as Volcanic_Agent,
        cast(null as varchar(50))                        as Volcano_Name,

        &upload_dt.                                      as Upload_Date

    from &lib_cas..earthquake e

        left join &lib_cas..eqdetails d
            on e.eq = d.eq

        left join &lib_cas..location l
            on e.Latitude = l.Latitude
           and e.Longitude = l.Longitude


    union all


    /*========================================================*
        TSUNAMI records
    *========================================================*/
    select
       cast(t.year  as integer)                                        as Year,
       cast(t.month as integer)                                  as Month,
       cast(t.day as integer)                                         as Day,
        'TSUNAMI'                                        as Event_Type,
        l.Country_DQ                                     as Country,
        t.Latitude                                       as Latitude,
        t.Longitude                                      as Longitude,
        t.eq                                             as Eq,
        t.tsu                                            as Tsu,
        t.vol                                            as Vol,
        t.URL                                            as URL,
        cast(t.Deaths as integer)                                        as Deaths,
         cast(t.Injuries    as integer)                                   as Injuries,
        t.Injuries_Description                           as Injuries_Description,
        t.Damage                                         as Damage,
        t.Houses_Destroyed                               as Houses_Destroyed,
        t.Houses_Destroyed_Description                   as Houses_Destroyed_Description,
        cast(t.Total_Deaths         as integer)                          as Total_Deaths,
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
        cast(null as varchar(30))                        as Volcano_Type,
        cast(null as double)                             as VEI,
        cast(null as varchar(20))                         as Volcanic_Agent,
        cast(null as varchar(50))                        as Volcano_Name,
        &upload_dt.                                      as Upload_Date

    from &lib_cas..tsunami t

        left join &lib_cas..tsudetails d
            on t.tsu = d.tsu

        left join &lib_cas..location l
            on t.Latitude = l.Latitude
           and t.Longitude = l.Longitude


    union all


    /*========================================================*
        VOLCANO records
    *========================================================*/
    select
        cast(v.year as integer)                                           as Year,
        cast(v.month as integer)                                         as Month,
        cast(v.day  as integer)                                        as Day,
        'VOLCANO'                                        as Event_Type,
        l.Country_DQ                                     as Country,
        v.Latitude                                       as Latitude,
        v.Longitude                                      as Longitude,
        v.eq                                             as Eq,
        v.tsu                                            as Tsu,
        v.vol                                            as Vol,
        v.URL                                            as URL,
       cast(v.Deaths      as integer)                                 as Deaths,
        cast( v.Injuries     as integer)                                  as Injuries,
        v.Injuries_Description                           as Injuries_Description,
        v.Damage                                         as Damage,
        v.Houses_Destroyed                               as Houses_Destroyed,
        v.Houses_Destroyed_Description                   as Houses_Destroyed_Description,
        cast( v.Total_Deaths  as integer)                                 as Total_Deaths,
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

        left join &lib_cas..location l
            on v.Latitude = l.Latitude
           and v.Longitude = l.Longitude
    ;

quit;


/* ============================================================
   6. Apply label and datetime format to Upload_Date
   ============================================================ */

proc casutil;
    altertable casdata="natural_disasters" incaslib="&lib_cas."
        columns={{  name="Upload_Date", label="Date Uploaded", format="datetime20."}};
quit;


/* ============================================================
   7. Sample visual inspection
   ============================================================ */

title "Sample rows from NATURAL_DISASTERS";

proc print data=&lib_cas..natural_disasters(obs=30);
run;

title;