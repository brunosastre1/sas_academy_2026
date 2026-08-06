%include "/home/student/github_bruno/student/brunosastre/natdis_project/01_setup_load/1_1_parameters.sas";
options fullstimer msglevel=i symbolgen;

*checking the values in the country field - some countries written in another language, errors etc;
proc cas;
   casTbl = {name = "location", caslib = "&lib_cas."};
   simple.freq / table= casTbl, inputs = 'country';
quit;

/*only heard of QKB but let's try it*/

data &lib_cas..location;
    set &lib_cas..location;
    Country_DQ = UPCASE(dqStandardize(Country,'Country')); /* pattern definition set to country */
run;

/* checking if it worked as expected */
proc cas;
   casTbl = {name = "location", caslib = "&lib_cas."};
   simple.freq / table= casTbl, inputs = 'Country_DQ';
quit;


/* checking if it worked in another way by checking 
what's different from the dq results and the original value */

proc fedsql sessref=&sess_nm.;
select distinct Country, Country_DQ
from &lib_cas..location
where Country <> Country_DQ;
quit;

/* OBS: some countries separated by ; were merged

For example, note on the "PERU EQUADOR" label: NOAA names locations based on tectonic 
macro-regions and impacted areas. The label reflects the general fault zone 
rather than a precise point on the map. */

*Dropping country column after confirming dq is working as expected;

proc casutil;
      altertable casdata="location" incaslib="&lib_cas." drop={"country"};
quit;

