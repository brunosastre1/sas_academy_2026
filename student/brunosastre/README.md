# Execution Guide

This section describes the recommended execution methods for both projects included in this repository.

---

# Project 1 - Countries Data Project

## Recommended Execution Method

The complete Countries Data Project can be executed through a single SAS program:

```text
countries_project/validation/benchmark_v1.sas
```

### Purpose

This program automates the execution of both implementations:

- Original implementation
- Optimized implementation

In addition, it performs benchmarking activities and generates comparative results that can be used to validate correctness and evaluate performance improvements.

### Output

The execution produces:

- Original process results
- Optimized process results
- Benchmark information
- Performance comparison metrics

### Project Location

```text
student/
└── brunosastre/
    └── countries_project/
        ├── original/
        ├── optimized/
        ├── validation/
        │   └── benchmark_v1.sas
        ├── logs/
        └── exploration/
```

---

# Project 2 - Natural Disasters Project

The Natural Disasters Project can be executed using two different methods.

## Method 1 - Execute the Main Driver Program

Recommended for automated execution.

Program:

```text
natdis_project/main_tester.sas
```

This program orchestrates the complete ETL pipeline and executes all project stages in sequence.

Execution order:

```text
01_setup_load
↓
02_transform_dataquality
↓
03_join_and_report
↓
04_cleanup
↓
05_reports
↓
06_increment_2023_2024
```

### Project Location

```text
student/
└── brunosastre/
    └── natdis_project/
        ├── main_tester.sas
        ├── 01_setup_load/
        ├── 02_transform_dataquality/
        ├── 03_join_and_report/
        ├── 04_cleanup/
        ├── 05_reports/
        └── 06_increment_2023_2024/
```

---

## Method 2 - Execute the SAS Studio Flow

Recommended for visual execution and demonstration purposes.

Flow:

```text
natdis_project/natdis_project_flow.flw
```

The flow provides a graphical representation of the ETL pipeline and allows the complete project to be executed through a single action in SAS Studio.

The flow was organized into logical ETL stages to improve readability, maintainability and troubleshooting.

### SAS Studio Flow Location

```text
student/
└── brunosastre/
    └── natdis_project/
        └── natdis_project_flow.flw
```

### Flow Structure

- Setup and Load
- Transformations
- Data Quality
- Join and Reporting
- Cleanup
- Reports
- Incremental Loads

### Example Repository Structure

The repository is organized as shown below:

```text
student/
└── brunosastre
    ├── countries_project
    ├── documentation
    ├── natdis_project
    │   ├── main_tester.sas
    │   └── natdis_project_flow.flw
    ├── presentation
    └── research_topic
```

---

# Source Control

As an additional learning activity beyond the case study requirements, GitHub source control and SAS Studio Git integration were used throughout the project lifecycle.

Repository:

[Bruno Sastre - SAS Academy 2026](https://github.com/brunosastre1/sas_academy_2026)

Git integration was used to maintain source code versioning, project history and development traceability.

## SAS Studio Git Limitation

During implementation, it was observed that SAS Studio Git integration supports synchronization only for files located on the SAS Server filesystem.

As a result:

- ✅ SAS Server directories can be synchronized with Git repositories.
- ❌ SAS Content objects cannot be directly synchronized through the native Git integration.

Because of this limitation, all source code was maintained in Git-controlled directories on the SAS Server filesystem.
