
# Phase 5 — Business Queries & Power BI Analytics

## Project
University Management System — End-to-End

## Objective

Transform the validated relational database into
actionable business insights using SQL Server,
Business Queries, DAX Measures, and Power BI.

The analytics solution evaluates academic operations,
course enrollment, faculty workloads, research
projects, research collaboration, and supervision.

## Technology Stack

- Microsoft SQL Server
- SQL Server Management Studio (SSMS)
- SQL Views and Business Queries
- Power BI Desktop
- DAX Measures
- DirectQuery Connectivity

## Data Architecture

SQL Server Database
    |
    v
Business SQL Queries and Views
    |
    v
Power BI DirectQuery
    |
    v
Semantic Model and DAX Measures
    |
    v
Interactive Analytics Reports

The solution uses DirectQuery to retrieve data
from SQL Server without importing the main
source tables into Power BI.

## Business Analytics Areas

### 1. Academic Performance

- Student enrollment analysis
- Completed enrollments
- Enrollment completion rates
- Academic year comparisons
- Semester performance
- Average completed grades
- Course-level performance

### 2. Faculty and Teaching Analytics

- Teaching workload by professor
- Course responsibility distribution
- Faculty allocation analysis

### 3. Research Analytics

- Research project distribution
- Research project participation
- Research collaboration analysis
- Cross-department collaboration
- Research collaboration network
- Research supervision workload
- Research supervision coverage

## Power BI Reporting

The developed report contains 18 report pages,
covering academic, teaching, and research analytics.

Selected research visuals include:

| Chart | Analytical Focus |
|---|---|
| Chart 14 | Cross-Department Collaboration |
| Chart 15 | Research Collaboration Network |
| Chart 16 | Research Project Participation |
| Chart 17 | Research Supervision Workload by Professor |
| Chart 18 | Research Supervision Coverage by Department |

Other report pages cover enrollment, academic
performance, course responsibilities, and
research distribution.

## Validated SQL Baseline

The following values were verified against the
project database during final SQL reconciliation.

| Indicator | Verified Value |
|---|---:|
| Departments | 8 |
| Students | 64 |
| Professors | 32 |
| Courses | 24 |
| Enrollment Records | 192 |
| Research Projects | 16 |
| Research Collaboration Records | 80 |
| Research Supervision Assignments | 24 |
| Cross-Department Collaboration Records | 32 |

These values represent the validated project
dataset, not live university statistics.

## Research Supervision Analysis

### Chart 17 — Supervision Workload

The verified results include:

- Total professors: 32
- Professors with supervision: 24
- Professors without supervision: 8
- Supervision assignments: 24

The chart distinguishes professors with assigned
research supervision from those without assignments.

### Chart 18 — Research Supervision Coverage

The verified department-level results include:

- Research projects: 16
- Supervised research projects: 16
- Unsupervised research projects: 0
- Research supervision assignments: 24

Each of the eight departments has:

- 2 research projects
- 2 supervised projects
- 0 unsupervised projects
- 3 supervision assignments
- 100% supervision coverage

The coverage percentage is calculated as:

Supervised Projects / Total Research Projects

## DAX Measures

Examples of implemented measures include:

- Completed Enrollments
- Research Supervision Assignments
- Research Supervision Coverage %

Measures are designed to respond to relevant
filter context.

## Data Validation

The analytics workflow includes:

1. SQL-level business metric verification.
2. Reconciliation between SQL and Power BI.
3. DAX measure validation.
4. Relationship and filter-context review.
5. Visual-level quality assurance.
6. DirectQuery configuration verification.
7. Performance Analyzer testing.

## DirectQuery Considerations

DirectQuery was retained during report development.

The Power BI report depends on SQL Server
availability and valid database connectivity.

Publishing to Power BI Service requires separate
connectivity and gateway configuration where
applicable. Local Desktop verification does not
constitute verification of Service connectivity.

## Final Visual QA

The final QA process covered:

- Report visual accuracy
- KPI reconciliation
- Chart 17 zero-assignment verification
- Chart 18 coverage percentage verification
- Tooltip validation
- Filter context review
- Performance Analyzer execution

## Project Artifacts

The following artifacts should be uploaded
separately after review:

- SQL business query scripts
- SQL analytical Views
- DAX measure documentation
- Power BI report file (.pbix)
- Sanitized report screenshots
- SQL-to-Power BI reconciliation evidence

## Business Value

The solution demonstrates how relational data
can support evidence-based university management.

Its analytical capabilities enable structured
evaluation of:

- Academic operations
- Teaching resource allocation
- Research collaboration
- Research supervision
- Performance monitoring

## Status

Development and local verification completed.

Repository artifact publication and verification
are tracked separately.

## Next Phase

Phase 6 — Final Project Audit & Closure
