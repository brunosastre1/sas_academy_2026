# Developer's Guide

# 1. Countries Data Project

## 1.1 Project Overview

The objective of the Countries Data Project was to modernize and optimize an existing SAS implementation responsible for processing World Bank Indicators data and standardized country reference information.

The original solution generated the following output tables:

- COUNTRIES_POP_GDP
- COUNTRY_LOOKUP

The optimization goals were:

- Reduce the number of processing passes through the data
- Increase Oracle pushdown execution
- Minimize data movement between Oracle and SAS
- Maintain functional equivalence with the original implementation
- Provide measurable performance improvements

---

## 1.2 Architecture Assessment

Before implementing the optimized solution, several exploratory analyses were performed to understand the existing architecture and identify optimization opportunities.

The exploration phase included:

- Existing process analysis
- Oracle index evaluation
- Oracle execution plan investigation
- Data type validation
- Oracle parallel processing evaluation
- Pushdown validation testing

Exploration artifacts were maintained in:

```text
countries_project/exploration/

├── Exploration_Process_Country_Data_Exploration.sas
├── Exploration_Process_Country_Data_Explain_Index.sas
├── Exploration_Process_Country_Performance_Exploration_Index.sas
├── Exploration_Process_Country_Performance_Exploration_Parallel_Oracle.sas
├── Exploraration_Process_Country_Performance_Exploration_DataType.sas
└── LucasSantos_Process_Country_Data.sas
```

These exploratory activities helped identify areas where the original processing flow could be simplified and moved into Oracle.

---

## 1.3 Original Solution Assessment

The original implementation relied heavily on SAS Compute Server processing.

The original architecture generated:

- Multiple processing passes through the data
- Significant Oracle-to-SAS data movement
- Increased Block I/O activity
- Additional temporary datasets

---

## 1.4 Optimization Goals

The optimization effort focused on the following objectives:

### Reduce Data Movement

The original implementation repeatedly copied data between Oracle and SAS.

The optimized implementation was designed to keep processing as close as possible to the Oracle database.

### Reduce Processing Passes

Multiple sorts, merges and intermediate tables were consolidated into fewer processing stages.

### Increase Oracle Processing

The optimized implementation was redesigned to maximize database-side execution through Oracle pass-through processing.

### Preserve Business Logic

All optimization activities were required to maintain functional equivalence with the original implementation.

---

## 1.5 Configuration and Parameterization

A dedicated parameter file was introduced to centralize configuration.

File:

```text
optimized/parameters.sas
```

This file centralizes:

- Project paths
- Program locations
- Oracle connection parameters
- Processing years so I could reuse the years information in Process_Country_Data_Optimized.sas
- Performance settings
- Authentication settings

Benefits:

- Improved maintainability
- Reduced hardcoded values
- Simplified future modifications
- Improved portability

---

## 1.6 Authentication Design

Oracle authentication was implemented using a SAS Authentication Domain.

```sas
authdomain="OracleAuth"
```

Instead of storing credentials directly in source code, authentication details were abstracted through the SAS metadata layer.

Benefits:

- Improved security
- Reduced credential exposure
- Easier credential maintenance
- Enterprise-aligned implementation

Although not required by the case study, this design more closely represents production-grade implementations.

---

## 1.7 Oracle Pushdown Strategy

A primary optimization objective was maximizing Oracle-side execution.

Two complementary approaches were used.

### Implicit Pass-Through

Oracle tables were exposed through an Oracle LIBNAME engine.

```sas
libname oralib oracle ...
```

This allowed SAS procedures to automatically generate SQL executed directly by Oracle whenever supported.

### Explicit Pass-Through

More complex transformations were implemented using Oracle SQL executed through:

```sas
proc sql;
connect to oracle (...);
```

Explicit pass-through was selected for the most computationally intensive operations because it provided complete control over SQL execution and processing location.

---

## 1.8 Pushdown Validation

Oracle pushdown behavior was validated using tracing options.

```sas
options
    sastrace=',,,ds'
    sastraceloc=saslog
    sql_ip_trace=(note, source)
    msglevel=i;
```

These settings provided visibility into:

- Generated SQL statements
- Pushdown behavior
- Oracle-side execution
- SQL processing location

Validation activities ensured that critical transformations remained within Oracle instead of being executed by the SAS Compute Server.

---

## 1.9 GDP Processing Redesign

GDP processing represented one of the largest redesign efforts.

### Original Approach

The original implementation relied on:

- PROC TRANSPOSE
- DATA Step processing
- SAS-side lag calculations

Processing flow:

```text
GDP_WIDE
   ↓
PROC TRANSPOSE
   ↓
DATA STEP
   ↓
GDP Dataset
```

### Optimized Approach

The optimized implementation replaced PROC TRANSPOSE with Oracle UNPIVOT.

Processing flow:

```text
GDP_WIDE
   ↓
Oracle UNPIVOT
   ↓
GDP_LONG
```

Benefits:

- Elimination of PROC TRANSPOSE
- Oracle-side processing
- Reduced intermediate datasets
- Improved scalability

---

## 1.10 Common Table Expressions (CTEs)

The optimized implementation was designed around multiple Common Table Expressions (temporary result sets)

Major CTE stages include:

- population_indicators
- countries_pop_indicators
- gdp_long_all_years
- gdp_with_lag
- gdp_filtered
- countries_pop_gdp_partial

CTEs were selected because they:

- Improve readability
- Improve maintainability
- Reduce temporary table creation
- Simplify troubleshooting
- Clearly represent business logic stages

The final SQL implementation closely follows the intended ETL pipeline while remaining inside Oracle.

---

## 1.11 Oracle Analytic Functions

Several Oracle analytic functions were introduced to replace SAS-side calculations.

### GDP Lag Calculation

```sql
lag(gdp) over
(
    partition by country_code
    order by year
)
```

This replaced DATA Step lag processing used in the original implementation.

### World GDP Calculation

```sql
sum(gdp) over
(
    partition by year
)
```

This replaced an aggregation stage previously executed in SAS.

Benefits:

- Reduced processing complexity
- Improved readability
- Reduced data movement
- Oracle-side execution

---

## 1.12 COUNTRY_LOOKUP Construction

The original implementation generated COUNTRY_LOOKUP through multiple SAS processing stages:

- SAME_CODES
- SAME_NAMES
- COUNTRY_WITH_DUPS
- PROC SORT NODUPKEY

The optimized implementation consolidated this logic into Oracle using:

- Two joins
- A UNION operation

Benefits:

- Fewer processing stages
- Elimination of duplicate-removal workflows
- Reduced temporary datasets
- Native Oracle execution

---

## 1.13 Validation Strategy

Output validation was considered mandatory to ensure functional equivalence.

Validation was performed using:

```sas
proc compare
```

The validation process compared:

- Original outputs
- Optimized outputs

Validation criteria included:

- Row count comparison
- Variable comparison
- Numeric comparison
- Functional equivalence

Special consideration was given to floating-point precision differences between SAS and Oracle.

### COUNTRIES_POP_GDP

Validation results:

- 3192 rows
- 16 variables
- No unequal values using CRITERION=1E-12

### COUNTRY_LOOKUP

Validation results:

- 214 rows
- 4 variables
- Exact match

The optimized implementation produced equivalent business results.

---

## 1.14 Benchmark Framework Design

A custom benchmarking framework was developed for this project.

File:

```text
validation/benchmark_v1.sas
```

The framework automates:

- Original implementation execution
- Optimized implementation execution
- Log collection
- Execution time measurement
- Block I/O extraction
- Comparative reporting

This approach ensures repeatable and consistent benchmark execution.

---

## 1.15 Performance Measurement Methodology

The case study required performance comparison using Block I/O metrics.

To ensure fair measurements, validation activities were excluded from performance calculations.

A dedicated marker was introduced:

```sas
%put NOTE: ===PIPELINE_END===;
```

All processing executed after this marker is excluded from benchmark calculations.

Excluded activities include:

- PROC COMPARE
- Validation queries
- Metadata inspection
- Oracle result retrieval used exclusively for validation

This approach guarantees that only operational ETL processing contributes to performance measurements.

---

## 5.16 Log Parsing Design

The benchmark framework automatically parses execution logs and extracts relevant metrics.

Metrics collected:

- Execution Time
- Block Input Operations
- Block Output Operations
- Total Block I/O
- Runtime Savings
- I/O Savings Percentage

Separate log files are generated for both implementations:

```text
benchmark_original.log
benchmark_optimized.log
```

Results are automatically consolidated into the results page in SAS Studio:
    - Execution Times
    - Block I/O Summary (validation steps excluded)
    - Final Benchmark Results (validation steps excluded)

---

## 1.17 Design Outcomes

The final solution significantly reduced SAS-side processing by moving the majority of transformations into Oracle.

Major design improvements include:

- Database-first processing
- Oracle pushdown execution
- Replacement of PROC TRANSPOSE with Oracle UNPIVOT
- Use of Common Table Expressions
- Use of Oracle analytic functions
- Reduced temporary datasets
- Centralized parameter management
- Automated benchmark framework
- Automated validation framework

The resulting architecture is simpler, more maintainable, and more scalable while preserving functional equivalence.

---

## 1.18 Lessons Learned

Key lessons learned during this project include:

- Oracle pushdown can significantly reduce SAS Compute Server workload.
- Explicit pass-through provides greater control over execution behavior.
- Oracle analytic functions can replace multiple SAS processing stages.
- Common Table Expressions improve readability and maintainability.
- Validation and benchmarking should be automated whenever possible.
- Performance measurements should exclude validation activities.
- Centralized configuration improves maintainability and code reuse.
- Database-side processing can dramatically reduce data movement and I/O consumption.


# 2. Natural Disasters Project

## 2.1 Project Overview

The objective of the Natural Disasters Project was to design and implement a complete ETL pipeline using CAS as the primary processing engine.

The solution integrates multiple natural disaster datasets, enriches the data through additional detail tables, standardizes location information, and generates a consolidated reporting table named `NATURAL_DISASTERS`. The project also includes parameterized reporting capabilities and a reusable framework for loading future disaster data from additional years.
The main goals of the solution were:

- Perform data processing in CAS whenever possible
- Demonstrate CAS-based ETL techniques
- Apply Data Quality standardization
- Build a consolidated reporting layer
- Design a reusable loading process for future years
- Organize the pipeline through both modular SAS programs and SAS Studio Flows

---

## 2.2 Overall Architecture

The project was designed as a modular ETL pipeline.

```text
Source Files
      |
      v
Setup and Loading
      |
      v
Data Transformation
      |
      v
Data Quality Processing
      |
      v
Join Discovery and Validation
      |
      v
Reporting Table Creation
      |
      v
Cleanup
      |
      v
Reports
      |
      v
Incremental Loads (2023+)
```

Each stage was implemented in an independent SAS program to improve readability, maintainability and troubleshooting.

---

## 2.3 Configuration and Parameterization

The project uses a centralized configuration model.

File:

```text
01_setup_load/1_1_parameters.sas
```

This file centralizes:

- Project paths
- SAS source library name
- CAS library name
- CAS session name
- Report parameters
- Incremental load parameters

Example:

```sas
%let lib_sas=natdis;
%let lib_cas=natCas;
%let sess_nm=disasterSession;

%let report_country='JAPAN';
%let report_year=2022;

%let years_to_load=2023 2024;
```

Centralizing these values reduced hardcoded configuration and simplified future maintenance and testing activities. 

---

## 2.4 CAS Session and Caslib Design

The project was intentionally designed around CAS.

The setup phase creates:

- A SAS library pointing to the source files
- A CAS session
- A path-based caslib
- A CAS library reference

Source data is initially accessed through the SAS Compute Server and then loaded into CAS memory.

The following source tables are loaded into CAS:

- EARTHQUAKE
- TSUNAMI
- VOLCANO
- LOCATION
- EQDETAILS
- TSUDETAILS
- VOLDETAILS

Loading operations are performed through PROC CASUTIL.

The setup phase also creates independent libraries for future disaster datasets:

```sas
libname dis2023 "/casestudy/natdis/data/disasters_2023";
libname dis2024 "/casestudy/natdis/data/disasters_2024";
```

This separation simplifies incremental loading operations while keeping the historical reporting process unchanged. 

---

## 2.5 Data Transformation Strategy

The transformation phase prepares source tables for integration and reporting.

File:

```text
02_transform_dataquality/2_1_transform.sas
```

The transformation stage performs:

- Numeric conversion of date components
- URL generation
- Extraction of Latitude and Longitude values
- Standardization of structures used in downstream joins

For disaster source tables, Year, Month and Day are converted from character variables into numeric values.

Example:

```sas
year_num  = input(Year, 8.);
month_num = input(Month, 8.);
day_num   = input(Day, 8.);
```

NOAA event URLs are generated using the event identifiers.

This allows the final reporting table to include direct navigation links to the original NOAA event information. 

---

## 6.6 Geographic Normalization

The LOCATION table contains a character column named `Geo_Coordinates`.

This field stores latitude and longitude values as a single string representation.

The solution creates explicit numeric Latitude and Longitude columns using PROC FEDSQL.

Example:

```sql
cast(compress(scan(geo_coordinates, 1, ','),'() ') as double) as latitude
```

and

```sql
cast(compress(scan(geo_coordinates, 2, ','), '() ') as double) as longitude
```

Creating dedicated numeric coordinate columns simplifies later join operations and enables multi-column matching between event records and location information.

---

## 2.7 Exploratory Data Analysis

Before implementing Data Quality processing, exploratory analysis was performed to understand data characteristics and identify inconsistencies.

File:

```text
07_data_exploration/data_exploration.sas
```

The exploration used:

- PROC MDSUMMARY
- PROC FREQ
- PROC CAS Simple.Freq
- PROC FEDSQL

The primary objective was evaluating the Country field values and identifying non-standardized country names.

Several values were found using non-English spellings or alternative labels, including examples such as:

- INDE
- ITALIE
- JAPON
- MEXIQUE
- HOLLAND
- THE NETHERLANDS

The exploratory phase helped determine whether a manual mapping approach or a Data Quality approach would be more appropriate. 
---

## 2.8 Data Quality Strategy

Data Quality processing was implemented using SAS Data Quality functions.

File:

```text
02_transform_dataquality/2_2_dq.sas
```

The process begins by generating frequency distributions for the Country field.

This allows the identification of:

- Spelling variations
- Alternate country names
- Non-English country labels
- Potential data quality issues

After the assessment phase, country values are standardized using:

```sas
Country_DQ = UPCASE(
    dqStandardize(
        Country,
        'Country'
    )
);
```

The standardized values are stored in a new column named `Country_DQ`. 

---

## 2.9 Use of the Quality Knowledge Base (QKB)

During development, a manual CASE-based standardization strategy was initially evaluated.

However, the final implementation adopted `dqStandardize()` because it leverages the SAS Data Quality framework and country standardization definitions available through the Data Quality environment.

The `Country` standardization definition acts as a reusable ruleset that normalizes country names according to predefined matching and standardization logic.

Benefits of using Data Quality functions instead of hardcoded CASE expressions include:

- Improved maintainability
- Reduced custom mapping rules
- Better scalability
- Reusable standardization logic
- More realistic enterprise implementation

The decision also provided practical exposure to SAS Data Quality capabilities and the Quality Knowledge Base concepts introduced during the case study.

---

## 2.10 Validation of Data Quality Processing

Multiple validation techniques were applied after standardization.

Validation included:

- Country frequency distributions before standardization
- Country frequency distributions after standardization
- Comparison between original and standardized values

Example:

```sql
select distinct
    Country,
    Country_DQ
from location
where Country <> Country_DQ;
```

This allowed direct inspection of modified values and ensured that standardization behaved as expected. 

---

## 2.11 Join Discovery Methodology

The case study intentionally did not provide explicit primary keys for all tables.

For this reason, a dedicated investigative phase was performed before implementing joins.

The analysis focused on:

- Reviewing table structures
- Identifying shared identifiers
- Validating relationship cardinality
- Confirming expected row counts

The following identifiers were identified as key relationship candidates:

| Table | Identifier |
|---------|------------|
| EARTHQUAKE | EQ |
| TSUNAMI | TSU |
| VOLCANO | VOL |
| EQDETAILS | EQ |
| TSUDETAILS | TSU |
| VOLDETAILS | VOL |

These observations supported the final join design used in the reporting layer. 

---

## 2.12 Relationship Analysis

Additional exploration was performed to understand whether earthquakes, tsunamis and volcanoes could be related events.

Validation queries showed:

- Some earthquake records contain a volcano identifier
- Earthquake records may also contain tsunami identifiers
- Not all disasters have related events

Because these relationships are optional rather than mandatory, the final design avoided excluding rows based on missing relationships.

---

## 2.13 Join Strategy

The final reporting table uses a combination of:

- LEFT JOIN
- Multi-column location joins
- UNION ALL

Important design decisions include:

### LEFT JOIN for Enrichment Tables

Detail tables are treated as optional enrichments.

LEFT JOIN preserves all disaster events even when matching detail records are unavailable.

### Multi-Column LOCATION Join

Location matching uses:

```text
Latitude
+
Longitude
```

instead of a single identifier.

This satisfies the case study requirement that some joins require more than one join condition.

### UNION ALL

EARTHQUAKE, TSUNAMI and VOLCANO populations are maintained independently and then combined into a single reporting table using UNION ALL. 

---

## 1.14 Reporting Table Design

The final reporting table is:

```text
NATURAL_DISASTERS
```

The table stores one row per natural disaster event.

The source event population is tracked through:

```text
Event_Type
```

Possible values include:

- EARTHQUAKE
- TSUNAMI
- VOLCANO

This design allows multiple event types to coexist in a single reporting structure while preserving event-specific attributes. 

---

## 2.15 Upload Timestamp Design

The solution captures a single upload timestamp at runtime:

```sas
%let upload_dt = %sysfunc(datetime());
```

This timestamp is assigned to every row inserted during the execution.

The final Upload_Date column is configured with:

- Label: Date Uploaded
- Format: DATETIME20.

This provides traceability and allows consumers of the reporting table to identify when records were processed. 

---

## 2.16 Cleanup Design

After validation and reporting table creation, source tables are removed from CAS.

File:

```text
04_cleanup/4_1_cleanup.sas
```

Removed tables include:

- earthquake
- tsunami
- volcano
- location
- eqdetails
- tsudetails
- voldetails

This leaves the reporting table as the primary artifact within CAS.

---

## 2.17 Reporting Design

The reporting layer is parameterized through macro variables.

Examples:

```sas
%let report_country='JAPAN';
%let report_year=2022;
```

Implemented reports include:

- All events for a selected country
- Event counts by country for a selected year

This design allows reports to be reused without code modification.

---

## 2.18 Incremental Load Design

A reusable incremental load framework was implemented to support future datasets.

Files:

```text
01_setup_load/1_3_functions.sas
06_increment_2023_2024/6_increment_data.sas
```

The years to process are controlled through:

```sas
%let years_to_load=2023 2024;
```

The incremental process is executed using:

```sas
%load_natdis();
```

This design allows new years to be added by changing only the macro variable definition.

---

## 2.19 Incremental Load Macro Architecture

The macro dynamically processes:

```text
DIS2023.NATDIS2023
DIS2024.NATDIS2024
```

For each year the process:

1. Loads the yearly dataset
2. Standardizes field names
3. Converts data types
4. Maps source columns to the reporting schema
5. Creates missing columns
6. Assigns Upload_Date
7. Appends results into a consolidated table

This architecture significantly improves maintainability by avoiding duplicated code for each year. 

---

## 2.20 SAS Studio Flow Design

The project includes a SAS Studio Flow implementation.

File:

```text
natdis_project_flow.flw
```

The flow organizes the ETL pipeline into logical stages:

- Setup and Load
- Transformations
- Data Quality
- Reporting Table Generation
- Cleanup
- Reports
- Incremental Loads

This visual representation improves maintainability and provides an easy way to demonstrate the pipeline during project presentations. 

---

## 2.21 Design Outcomes

Major design outcomes include:

- CAS-based in-memory processing
- Modular ETL architecture
- Data Quality standardization using SAS functions
- Multi-stage validation and exploration
- FEDSQL-based reporting table creation
- Reusable incremental load framework
- Parameterized reporting
- Flow-based orchestration
- Maintainable project structure

The resulting architecture emphasizes maintainability, traceability, reusability and alignment with SAS Viya best practices.

---

## 2.22 Lessons Learned

Key lessons learned during the project include:

- CAS enables efficient in-memory ETL processing.
- PROC CASUTIL simplifies CAS table lifecycle management.
- FEDSQL provides a flexible framework for reporting-table creation.
- Data Quality functions can replace extensive manual standardization logic.
- Exploratory analysis is critical when primary keys are not explicitly defined.
- LEFT JOIN strategies help preserve event populations when enrichment relationships are optional.
- Macro-driven incremental processing improves scalability and maintainability.
- SAS Studio Flows provide a useful abstraction layer for ETL orchestration and solution presentation.
