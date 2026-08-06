/*************************************************************************
Project 2 - Natural Disasters

Requirement 3.3.4
Perform Data Quality Processing on the Country Field

Purpose:
Analyze and standardize COUNTRY values.
*************************************************************************/

cas;
caslib _all_ assign;

/*----------------------------------------------------------
Review Country Values
----------------------------------------------------------*/

proc cas;

   casTbl = {
      name = "LOCATION_TR",
      caslib = "NATDIS"
   };

   simple.freq /
      table = casTbl,
      inputs = {"Country"};

quit;

/*----------------------------------------------------------
Apply Data Quality Standardization
----------------------------------------------------------*/

data natdis.location_tr;

    set natdis.location_tr;

    Country =
        upcase(
            dqStandardize(
                Country,
                'Country'
            )
        );

run;

/*----------------------------------------------------------
Validate Standardized Values
----------------------------------------------------------*/

proc cas;

   casTbl = {
      name = "LOCATION_TR",
      caslib = "NATDIS"
   };

   simple.freq /
      table = casTbl,
      inputs = {"Country"};

quit;