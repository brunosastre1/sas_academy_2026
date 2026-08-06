%include "/home/student/github_bruno/student/brunosastre/natdis_project/01_setup_load/1_1_parameters.sas";
options fullstimer msglevel=i symbolgen;

*checking the values in the country field;
proc MDSUMMARY data=&lib_cas..location;
groupby country / out=&lib_cas..location_country_md;
run;

proc freq data=&lib_cas..location;
    tables Country / out=&lib_cas..location_country_freq;
run;

*same thing but it does not generate a table as output;
proc cas;
   casTbl = {name = "location", caslib = "&lib_cas."};
   simple.freq / table= casTbl, inputs = 'country';
quit;

* time to adjust a few countries;
proc fedsql sessref=&sess_nm.;
    create table &lib_cas..location_v3 {options replace=true} as
    select
        *,
        case
            when Country = 'INDE' then 'INDIA'
            when Country = 'ITALIE' then 'ITALY'
            when Country = 'JAPON' then 'JAPAN'
            when Country = 'MEXIQUE' then 'MEXICO'
            when Country = 'COLUMBIA' then 'COLOMBIA'
            when Country = 'TAJIKSTAN' then 'TAJIKISTAN'
            when Country = 'HOLLAND' then 'NETHERLANDS'
            when Country = 'THE NETHERLANDS' then 'NETHERLANDS'
            when Country = 'FIJI ISLANDS' then 'FIJI'
            when Country = 'TRINIDAD' then 'TRINIDAD AND TOBAGO'
            when Country = 'TOBAGO' then 'TRINIDAD AND TOBAGO'
            when Country = 'ALABAMA' then 'UNITED STATES'
            when Country = 'TEXAS' then 'UNITED STATES'
            else Country
        end as Country_Clean
    from &lib_cas..location;
quit;

/*only heard of QKBm but let's try it*/

data &lib_cas..location_dq;
    set &lib_cas..location;
    Country_DQ = UPCASE(
        dqStandardize(
            Country,
            'Country'
        ));
run;

proc cas;
   casTbl = {name = "location_dq", caslib = "&lib_cas."};
   simple.freq / table= casTbl, inputs = 'Country_DQ';
quit;




data countries_test;
    length Country $50;
    input Country & $50.;
    datalines;
INDE
ITALIE
JAPON
MEXIQUE
COLUMBIA
TAJIKSTAN
HOLLAND
THE NETHERLANDS
FIJI ISLANDS
TRINIDAD
TOBAGO
BRAZIL
INDIA
JAPAN
;
run;

data dq_result;
    set countries_test;

    Country_DQ =
        dqStandardize(
            Country,
            'Country'
        );
run;

data dq_result2;
    set countries_test;

    Country_DQ =
        dqStandardize(
            Country,
            'Country'
        );
run;

proc fedsql sessref=&sess_nm.;

select distinct

Country,
Country_DQ
from &lib_cas..location_dq
where Country <> Country_DQ;
quit;