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
- Processing years so I could reuse the years information
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

The optimized implementation was designed around multiple Common Table Expressions.

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

Results are automatically consolidated into a final benchmark report.

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
