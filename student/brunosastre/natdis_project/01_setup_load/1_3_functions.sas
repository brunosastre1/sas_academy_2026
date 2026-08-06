%include "/home/student/github_bruno/student/brunosastre/natdis_project/01_setup_load/1_1_parameters.sas";

options symbolgen;

*functions;

/* used in 06_increment_2023_2024 

not my best work and I ran out of time to find a better way to perform an append*/


%macro load_natdis(years=&years_to_load);

    %local i year;

    /* starts with the base table */
    data &lib_cas..natural_disasters_new;
        set &lib_cas..natural_disasters;
    run;

    %let i=1;
    %let year=%scan(&years,&i);

    %do %while(%length(&year));

        data &lib_cas..natdis_append;

            if 0 then set natcas.natural_disasters;

            set dis&year..natdis&year
                (rename=(
                    month                       = month_src
                    day                         = day_src
                    country                     = country_src
                    event_type                  = event_type_src
                    volcano_type                = volcano_type_src
                    volcanic_agent              = volcanic_agent_src
                    volcano_name                = volcano_name_src
                    modified_mercalli_intensity = earthquake_mmi_intensity
                    volcanic_explosivity_index  = vei
                    total_death_desc            = total_death_description
                    total_injuries_desc         = total_injuries_description
                    total_damage_desc           = total_damage_description
                ));

            year = &year;

            /* converting month */
            month = input(month_src,best.);
            day   = input(day_src,best.);

            /* varchar variables from CAS */
            country        = country_src;
            event_type     = event_type_src;
            volcano_type   = volcano_type_src;
            volcanic_agent = volcanic_agent_src;
            volcano_name   = volcano_name_src;

            /* inexistent variables in the source table */
            damage                       = .;
            deaths                       = .;
            injuries                     = .;
            injuries_description         = .;
            houses_destroyed             = .;
            houses_destroyed_description = .;

            url         = "";
            upload_date = datetime();

            keep
                year month day
                country event_type
                latitude longitude
                eq tsu vol
                url
                deaths injuries injuries_description
                damage
                houses_destroyed houses_destroyed_description
                total_deaths total_death_description
                total_injuries total_injuries_description
                total_damage total_damage_description
                earthquake_magnitude
                earthquake_mmi_intensity
                focal_depth
                tsunami_event_validity
                tsunami_cause_code
                deposits
                maximum_water_height
                number_of_runups
                tsunami_magnitude
                tsunami_intensity
                elevation
                volcano_type
                vei
                volcanic_agent
                volcano_name
                upload_date
            ;
        run;

        /* Append */

        data &lib_cas..natural_disasters_new;
            set &lib_cas..natural_disasters_new
                &lib_cas..natdis_append;
        run;

        %let i=%eval(&i+1);
        %let year=%scan(&years,&i);

    %end;

%mend load_natdis;


