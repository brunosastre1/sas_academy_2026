# SAS Data Engineering Track

## Project 1 - Countries Data Project

This repository contains the files created for the first project of the SAS Data Engineering Case Study: **Countries Data Project**.

The goal of this project was to take the original SAS program provided in the case study, run it successfully in SAS Viya, optimize it using SAS/ACCESS to Oracle techniques, validate that the optimized version produces equivalent results, and calculate the efficiency improvement.

---

## Project Objective

The Countries Data Project focuses on improving an existing SAS program that processes World Bank indicator data and standardized country/region information.

The optimized program was created to:

- Reduce unnecessary processing steps
- Reduce intermediate WORK tables
- Reduce PROC SORT operations
- Move more processing into Oracle
- Use both Explicit Pass-Through and Implicit Pass-Through
- Produce the same final output as the original program

---

## Files Included

### Process_Country_Data.sas

This is the original program provided by the case study.

It was used to:

- Understand the original process
- Generate the baseline output tables
- Compare the optimized version against the original output

The original program creates the following final tables:

- `COUNTRIES_POP_GDP`
- `COUNTRY_LOOKUP`

---

### Process_Country_Data_Optimized.sas

This is the optimized version of the original program.

Main improvements included:

- Explicit Pass-Through processing in Oracle
- Implicit Pass-Through processing using the Oracle libref
- Use of `SASTRACE` to verify SQL being passed to Oracle
- Reduction of PROC SORT steps
- Replacement of DATA step merges with SQL joins where appropriate
- Reduction of intermediate WORK tables
- Reduced data movement between Oracle and SAS

This is the main deliverable for the optimized Countries Project solution.

---

### Countries_Backup.sas

This program creates backup copies of the original output tables before running the optimized version.

It creates:

- `ORIG_COUNTRIES_POP_GDP`
- `ORIG_COUNTRY_LOOKUP`

These backup tables were used as the baseline for PROC COMPARE validation.

---

### Countries_real_Validation.sas

This program validates the optimized output against the original output using `PROC COMPARE`.

It compares:

- `ORIG_COUNTRIES_POP_GDP` vs. `COUNTRIES_POP_GDP`
- `ORIG_COUNTRY_LOOKUP` vs. `COUNTRY_LOOKUP`

Validation results:

- `COUNTRY_LOOKUP` matched exactly.
- `COUNTRIES_POP_GDP` matched with only a negligible floating-point precision difference in `POP_GROWTH`.

The small difference in `POP_GROWTH` was caused by numeric precision differences between Oracle and SAS and does not impact the business result.

---

### Countries_Efficiency.sas

This file documents the efficiency calculation required for section 2.3.6 of the case study.

Efficiency results:

- Original Program Block Output Operations: `31,324`
- Optimized Program Block Output Operations: `18,048`

Efficiency improvement calculation:

```text
((31324 - 18048) / 31324) * 100 = 42.39%
