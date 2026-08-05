# SAS Data Engineering Track

## Project 1 - Countries Data Project

This repository contains my solution for the first project of the SAS Data Engineering Case Study: **Countries Data Project**.

The objective was to analyze an existing SAS program, execute it successfully in SAS Viya, investigate optimization opportunities, implement an optimized version using Oracle pushdown techniques, validate the results, and benchmark the performance improvements achieved.

---

## Project Overview

The original program processes country information and World Bank indicator data to create analytical datasets.

The optimization effort focused on reducing SAS-side processing, increasing Oracle pushdown utilization, simplifying data flows, and maintaining equivalent business results.

The project was executed in four phases:

1. Analysis of the original implementation
2. Performance and Oracle optimization research
3. Development of the optimized solution
4. Validation and benchmarking

---

## Repository Structure

### exploration/

Contains the analysis, research, and performance experiments performed during the investigation phase.


#### BrunoSastre_Process_Country_Data_Exploration.sas

Analysis of the original workflow, transformations, joins, and output generation process.

#### BrunoSastre_Process_Country_Data_Explain_Index.sas

Investigation of Oracle execution plans and index utilization to identify optimization opportunities.

#### BrunoSastre_Process_Country_Performance_Exploration_DataType.sas

Performance analysis focused on data types, conversions, and their impact on Oracle pushdown and execution efficiency.

#### BrunoSastre_Process_Country_Performance_Exploration_Index.sas

Performance testing of indexing strategies and their effect on Oracle query execution paths.

#### BrunoSastre_Process_Country_Performance_Exploration_Parallel_Oracle.sas

Exploration of Oracle parallel execution capabilities and potential performance gains.

---

### original/

Contains the original case study implementation.

#### Process_Country_Data.sas

Baseline program used to:

- Understand the original process
- Generate reference results
- Establish baseline performance metrics
- Serve as the comparison point for the optimized implementation

---

### optimized/

Contains the final optimized solution.

#### Process_Country_Data_Optimized.sas

Main project deliverable.

Optimization techniques applied include:

- Explicit Pass-Through SQL
- Implicit Pass-Through SQL
- Oracle-side processing
- Common Table Expressions (CTEs)
- Window Functions
- Reduced intermediate datasets
- Reduced sorting operations
- Reduced data movement between Oracle and SAS

#### Load_Countries_to_SAS_population_data.sas

Supporting program used to load and prepare source data required during development and testing.

#### parameters.sas

Centralized configuration file containing reusable project parameters and macro variables.

---

### validation/

Contains the benchmarking and validation artifacts.

#### benchmark.sas

Benchmark framework used to compare the original and optimized implementations.

---

## Optimization Techniques Demonstrated

The final solution applies several SAS Data Engineering best practices:

- SAS/ACCESS Interface to Oracle
- Explicit Pass-Through Processing
- Implicit Pass-Through Processing
- Oracle Pushdown Optimization
- SQL Refactoring
- Common Table Expressions (CTEs)
- Oracle Window Functions
- In-Database Processing
- Reduced Intermediate Tables
- Reduced Data Movement
- Performance Benchmarking

---

## Technologies Used

- SAS Viya
- SAS Studio
- PROC SQL
- SAS/ACCESS Interface to Oracle
- Oracle Database
- Oracle SQL
- Explicit Pass-Through
- Implicit Pass-Through

---

## Project Goals

- Execute the original program successfully in SAS Viya
- Understand the existing business logic
- Identify optimization opportunities
- Increase Oracle pushdown utilization
- Reduce SAS-side processing
- Improve execution efficiency
- Validate output consistency
- Measure performance improvements

