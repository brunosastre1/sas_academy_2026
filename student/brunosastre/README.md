# Source Control and Development Practices

## Git Repository

As an additional learning activity beyond the mandatory case study requirements, Git source control was implemented and used throughout the project lifecycle.

The complete project repository is available at:

**GitHub Repository:**  
[Bruno Sastre - SAS Academy 2026](https://github.com/brunosastre1/sas_academy_2026)

The repository was used to manage:

- Source code versioning
- Incremental development
- Backup of project artifacts
- Change tracking
- Documentation updates
- Project organization and traceability

Using Git provided a structured development workflow and allowed all project components to be maintained under version control.

## SAS Studio Git Integration

Although Git integration was not a requirement of the case study, it was explored and implemented as part of the project in order to gain additional experience with modern development practices in SAS Viya.

The following capabilities were evaluated and used:

- Repository cloning from GitHub
- Commit and synchronization workflows
- Version tracking of SAS programs
- Project organization using a Git-based structure
- Integration between SAS Studio and GitHub

This additional work helped improve project maintainability and provided hands-on experience using source control within the SAS Viya ecosystem.

## SAS Studio Git Integration Limitation

During implementation, an important limitation of the current SAS Studio Git integration was identified.

Git synchronization is supported only for files stored within directories that are accessible through the SAS Server filesystem.

As a result:

-  Git repositories can be synchronized with directories stored on the SAS Server filesystem.
-  SAS Content objects cannot be directly synchronized with Git repositories using the native SAS Studio Git integration.

Because of this limitation, the project source code was organized and maintained within the Linux filesystem on the SAS Server, allowing direct integration with GitHub while using SAS Content only when required by the case study.

## Repository Structure

The repository was organized to separate project components, benchmarks, documentation, and deliverables.

```text
student/
└── brunosastre
    ├── countries_project
    │   ├── exploration
    │   ├── logs
    │   ├── optimized
    │   ├── original
    │   └── validation
    │
    ├── natdis_project
    │   ├── 01_setup_load
    │   ├── 02_transform_dataquality
    │   ├── 03_join_and_report
    │   ├── 04_cleanup
    │   ├── 05_reports
    │   ├── 06_increment_2023_2024
    │   ├── 07_data_exploration
    │   ├── main_tester.sas
    │   └── natdis_project_flow.flw
    │
    ├── documentation
    ├── presentation
    └── research_topic
```

## Additional Value

The use of GitHub and SAS Studio Git integration was not required to complete the case study. However, it provided additional experience with:

- Source control best practices
- Change management
- Project traceability
- Code organization
- Reproducible development workflows

These practices are commonly used in enterprise software and data engineering projects and helped maintain a structured and maintainable solution throughout the case study.

## Lessons Learned

Working with Git inside SAS Studio provided valuable insight into how modern software development practices can be combined with SAS development. While the current integration has limitations regarding SAS Content synchronization, it is highly effective for managing SAS programs, documentation, and project artifacts stored on the SAS Server filesystem.

The experience reinforced the importance of version control, reproducibility, and repository organization as part of a professional data engineering workflow.
