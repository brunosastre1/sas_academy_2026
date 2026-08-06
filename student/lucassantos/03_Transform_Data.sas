/*************************************************************************
Project 2 - Natural Disasters

Requirement 3.3.3
Transform and Create Columns

Purpose:
Transform source tables and create required columns.
*************************************************************************/

cas;
caslib _all_ assign;

/*----------------------------------------------------------
EARTHQUAKE
----------------------------------------------------------*/

data natdis.earthquake_tr;
    set natdis.earthquake;

    Year_Num  = input(Year,best12.);
    Month_Num = input(Month,best12.);
    Day_Num   = input(Day,best12.);

    length URL $200;

    URL = cats(
        'https://www.ngdc.noaa.gov/hazel/view/hazards/earthquake/event-moreinfo/',
        strip(put(eq,best32.))
    );

    drop Year Month Day;

    rename
        Year_Num  = Year
        Month_Num = Month
        Day_Num   = Day;
run;

/*----------------------------------------------------------
TSUNAMI
----------------------------------------------------------*/

data natdis.tsunami_tr;
    set natdis.tsunami;

    Year_Num  = input(Year,best12.);
    Month_Num = input(Month,best12.);
    Day_Num   = input(Day,best12.);

    length URL $200;

    URL = cats(
        'https://www.ngdc.noaa.gov/hazel/view/hazards/tsunami/event-moreinfo/',
        strip(put(tsu,best32.))
    );

    drop Year Month Day;

    rename
        Year_Num  = Year
        Month_Num = Month
        Day_Num   = Day;
run;

/*----------------------------------------------------------
VOLCANO
----------------------------------------------------------*/

data natdis.volcano_tr;
    set natdis.volcano;

    Year_Num  = input(Year,best12.);
    Month_Num = input(Month,best12.);
    Day_Num   = input(Day,best12.);

    length URL $200;

    URL = cats(
        'https://www.ngdc.noaa.gov/hazel/view/hazards/volcano/event-moreinfo/',
        strip(put(vol,best32.))
    );

    drop Year Month Day;

    rename
        Year_Num  = Year
        Month_Num = Month
        Day_Num   = Day;
run;

/*----------------------------------------------------------
LOCATION
----------------------------------------------------------*/

data natdis.location_tr;
    set natdis.location;

    geo_clean = compress(Geo_Coordinates,'()');

    Latitude  = input(scan(geo_clean,1,','),best32.);
    Longitude = input(scan(geo_clean,2,','),best32.);

    drop geo_clean;
run;

/*----------------------------------------------------------
Validation
----------------------------------------------------------*/

proc contents data=natdis.earthquake_tr;
run;

proc contents data=natdis.tsunami_tr;
run;

proc contents data=natdis.volcano_tr;
run;

proc contents data=natdis.location_tr;
run;