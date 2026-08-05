/* ******************************************
Prepare Student Data sets for Data Engineering Case Study
Source data is in /casestudy/util/setup/countries/WBI.xlsx
Output data will be stored in Oracle 
Intermediate files are created in WORK

Updated: RCM Jan 2024
**************************************** */

options VALIDVARNAME=v7; 

%let source=/casestudy/util/setup/countries/;


/** Country Name and Code data **/
options VALIDVARNAME=v7;   /* option needs to be run with each submission */
                           /* SAS Studio resets it otherwise */

proc import 
datafile="&source/WBI.xlsx"  
out=work.countries  
dbms=xlsx replace;  
getnames=yes;  
sheet="Countries";  
run; 


proc contents data=work.countries; 
run; 


/** Population Data **/
options VALIDVARNAME=v7;
/*******************************************REPLACED THE CODE BELOW************************/
/*REASON: transform year to numeric so I don't need to make transformations while performing joins*/
/*************************************************************************************** */
/*
proc import  
datafile="&source/WBI.xlsx"  
out=work.population_wide  
dbms=xlsx replace;  
getnames=yes;  
sheet="Population";  
run; 

proc contents data=work.population_wide; 
run; 

    /* reshape data to one row per country per year */
/*proc transpose data=work.population_wide 
out=work.population(rename=(col1=Population) drop=_NAME_) 
label=Year; 
var _1960-_2022;  
by Country_Code Country_Name Indicator_Code Indicator_Name notsorted; 
run; */


   /* Add labels so that Year and Population vars are capitalized correctly */
/*proc datasets library=work; 
modify population; 
label Year='Year'; 
label Population='Population'; 
run; 


proc contents data=work.population; 
run; 
*/


/******************************** NEW CODE FOR POPULATION**************************** */

/** Population Data **/

proc import  
datafile="&source/WBI.xlsx"  
out=work.population_wide  
dbms=xlsx replace;  
getnames=yes;  
sheet="Population";  
run; 

proc contents data=work.population_wide; 
run; 

    /* reshape data to one row per country per year */
proc transpose data=work.population_wide 
out=work.population_char(rename=(col1=Population) drop=_NAME_) 
label=Year_char; 
var _1960-_2022;   /* all years of data */
by Country_Code Country_Name Indicator_Code Indicator_Name notsorted; 
run; 

   /* Convert Year from character (label) to numeric */
data work.population; 
set work.population_char; 
Year=input(Year_char, 4.); 
label Year='Year' 
      Population='Population'; 
drop Year_char; 
run; 

proc contents data=work.population; 
run;

/** Population Growth data **/
options VALIDVARNAME=v7; 

proc import  
datafile="&source/WBI.xlsx"   
out=work.pop_growth_wide  
dbms=xlsx replace;  
getnames=yes;  
sheet="Pop_growth";  
run; 

proc contents data=work.pop_growth_wide; 
run; 

proc transpose data=work.pop_growth_wide 
out=work.pop_growth_char(rename=(col1=Pop_pct_growth) drop=_Name_) 
label=Year_char; 
var _1961-_2022; 
by Country_Code Country_Name Indicator_Code Indicator_Name notsorted; 
run; 

data work.pop_growth; 
set work.pop_growth_char; 
Year=input(Year_char, 4.); 
label Year="Year" 
Pop_pct_growth="Population % Growth"; 
drop Year_char; 
run; 

proc contents data=work.pop_growth; 
run; 

/** GDP Data **/
options VALIDVARNAME=v7; 

proc import  
datafile="&source/WBI.xlsx" 
out=work.gdp_wide  
dbms=xlsx replace;  
getnames=yes;  
sheet="GDP";  
run;

proc contents data=work.gdp_wide; 
run;

/** NOC Region data **/
options VALIDVARNAME=v7; 

proc import  
datafile="&source/WBI.xlsx" 
out=work.Regions  
dbms=xlsx replace;  
getnames=yes;  
sheet="Regions";  
run;

proc contents data=work.Regions; 
run;

/** Copy data sets to Oracle **/
libname oralib oracle path='//server.demo.sas.com:1521/ORCL' 
user=STUDENT password=Metadata0 DB_LENGTH_SEMANTICS_BYTE=NO DBCLIENT_MAX_BYTES=1; 

/* delete dataset if they exist */ 
proc datasets lib=oralib nowarn; 
delete countries population  pop_growth gdp_wide NOC_regions Regions; 
run;

proc copy in=work out=oralib memtype=data; 
select countries population  pop_growth gdp_wide Regions; 
run;

proc contents data=oralib._all_; 
run;

libname oralib clear;
