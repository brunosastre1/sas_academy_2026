%include "/home/student/github_bruno/student/brunosastre/natdis_project/01_setup_load/1_1_parameters.sas";
options symbolgen;

* report 1 - all events for a country;

title "Natural Disasters for &report_country. ";

proc fedsql sessref=&sess_nm.;

    select  year,
        month,
        day,
        event_type,
        country,
        deaths,
        injuries,
        total_deaths,
        earthquake_magnitude,
        tsunami_magnitude,
        volcano_name from &lib_cas..natural_disasters 
        where country = &report_country. order by year;

title;

* report 2- event count by country for selectd year;
 
title "Natural Disaster Event Counts by Country - &report_year";


    select
        country,
        sum(case
                when event_type='EARTHQUAKE'
                then 1
                else 0
            end) as earthquake_Count,
        sum(case
                when event_type='TSUNAMI'
                then 1
                else 0
            end) as tsunami_count,
        sum(case
                when event_type='VOLCANO'
                then 1
                else 0
            end) as volcano_count,
        count(*) as total_events

    from &lib_cas..natural_disasters
    where Year=&report_year.
    group by country
    order by total_events desc;

quit;

title;


