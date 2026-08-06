# SAS Data Engineering Case Study

This repository contains my work for the SAS Data Engineering Case Study, focused on three key areas of SAS Viya data engineering:

1. Countries Data Project
2. Natural Disasters Data Project
3. CAS Research Topic

The objective of the case study was to demonstrate practical SAS Viya skills involving Oracle integration, data engineering, CAS processing, performance optimization, ETL development, and technical knowledge sharing. 
---

```text
student/brunosastre/

├── countries_project
├── natdis_project
├── documentation
├── presentation
└── research_topic
```

## Documentation

For additional implementation details, refer to:

documentation/developers_guide.md

## Additional Learning Activities

As an additional learning exercise beyond the case study requirements, Git source control was implemented using GitHub and the native SAS Studio Git integration.

This repository was developed and maintained under version control throughout the project lifecycle.
---

# Project 1 - Countries Data Project

The Countries Data Project focused on improving an existing SAS program that processes World Bank indicator data and standardized country information.

The project objectives were:

- Execute the original SAS program in SAS Viya
- Reduce processing passes through the data
- Move processing from SAS Compute to Oracle
- Use both Explicit and Implicit Pass-Through techniques
- Validate that optimized results match the original output
- Measure efficiency improvements using Block I/O operations 【1-4fb255】

### Key Techniques

- SAS/ACCESS Interface to Oracle
- Explicit Pass-Through SQL
- Implicit Pass-Through SQL
- Oracle pushdown optimization
- Common Table Expressions (CTEs)
- Oracle Window Functions
- PROC COMPARE validation
- Performance benchmarking using FULLSTIMER

### Outputs

- COUNTRIES_POP_GDP
- COUNTRY_LOOKUP 【1-4fb255】


---
# Project 2 - Natural Disasters Data Project

The Natural Disasters project focused on creating an end-to-end ETL pipeline using CAS and SAS Studio Flows.

The project objectives were:

- Load source disaster data into CAS
- Perform transformations and data quality processing
- Build a maintainable ETL pipeline
- Process as much data as possible inside CAS
- Create reusable flows and reporting tables
- Support incremental data loads for future years 【1-4fb255】

### Key Techniques

- CAS Data Processing
- PROC FEDSQL
- PROC CASUTIL
- SAS Data Step in CAS
- SAS Studio Flows
- Data Quality Processing
- CASLIB Management
- ETL Pipeline Development

### Main Output

- NATURAL_DISASTERS reporting table containing earthquake, tsunami, volcano, location, and impact information. 【1-4fb255】

---

# Project 3 - CAS Research Topic

The research project focused on investigating and presenting a CAS-related topic to increase customer knowledge of SAS Viya capabilities.

The work included:

- Researching CAS concepts and best practices
- Creating technical examples and demonstrations
- Explaining real-world use cases
- Preparing knowledge-sharing materials and presentations 【1-4fb255】

Examples of research topics included:

- CAS Data Manipulation Techniques
- Parquet and Columnar Storage
- SAS Studio Custom Steps
- CAS Data Storage Features
- Data Quality Programming in CAS 【1-4fb255】

---

# Technologies Used

- SAS Viya
- SAS Studio
- SAS Studio Flows
- CAS Server
- PROC SQL
- PROC FEDSQL
- PROC CASUTIL
- SAS/ACCESS Interface to Oracle
- Oracle Database
- Explicit Pass-Through
- Implicit Pass-Through
- CASL
- Performance Benchmarking
- Data Quality Processing

---

# Skills Demonstrated

- SAS Data Engineering
- SAS Viya Development
- Oracle Integration
- ETL Design
- Data Pipeline Development
- CAS Processing
- SQL Optimization
- Query Tuning
- Oracle Pushdown Validation
- Data Quality
- Performance Benchmarking
- Technical Documentation
- Knowledge Sharing
