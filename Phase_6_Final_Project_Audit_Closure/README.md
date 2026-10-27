
# Phase 6 — Final Project Audit & Closure

## Project
University Management System — End-to-End

## Objective
Conduct the final technical and business-rule audit
of the University Management System, reconcile
SQL Server results with Power BI analytics, and
document project closure and outstanding decisions.

## 1. Database Structure Audit

Database: UniversityManagementDB
Platform: Microsoft SQL Server LocalDB

Verified results:
- Total database tables: 21
- Tables with Primary Keys: 21
- Tables without Primary Keys: 0
- Total Foreign Key constraints: 30
- Enabled Foreign Keys: 30
- Disabled Foreign Keys: 0
- Untrusted Foreign Keys: 0

Result: PASS

## 2. Referential Integrity Verification

Verification activities:
- Foreign Key metadata inspection
- Enabled and trusted constraint validation
- Expected versus actual relationship comparison
- Composite Foreign Key mapping verification
- DBCC CHECKCONSTRAINTS execution

Results:
- Expected relationships: 30
- Matched relationships: 30
- Missing relationships: 0
- Relationships requiring review: 0
- Composite Foreign Keys inspected: 3
- Composite column mappings validated: 6
- Failed composite mappings: 0

Result: PASS

## 3. Business Rule Validation

Nine business-rule checks were executed.

BR-01: Courses without responsible professors
BR-02: Graduation projects without students
BR-03: Departments without assigned heads
BR-04: Research projects without lead departments
BR-05: Research projects without supervisors
BR-06: Duplicate research collaboration tuples
BR-07: Collaborations without research participation
BR-08: Department heads assigned across departments
BR-09: Advisors assigned across departments

Audit results:
- Total checks: 9
- Passed checks: 9
- Checks requiring review: 0
- Recorded violations: 0

Result: PASS

## 4. SQL and Power BI Reconciliation

The following SQL Server totals were verified:

| Metric | Verified Value |
|---|---:|
| Departments | 8 |
| Students | 64 |
| Professors | 32 |
| Courses | 24 |
| Enrollments | 192 |
| Research Projects | 16 |
| Research Collaboration Records | 80 |
| Cross-Department Collaboration Records | 32 |
| Research Supervision Assignments | 24 |

These figures provide reference values for
Power BI reconciliation.

## 5. Power BI Dashboard Quality Assurance

Report:
University_Management_Analytics

Storage Mode:
DirectQuery

Report scope:
18 report pages, including research collaboration,
research participation, supervision workload,
and supervision coverage analysis.

### Chart 17 — Research Supervision Workload

SQL verification identified:
- Total professors: 32
- Professors with supervision assignments: 24
- Professors without supervision assignments: 8
- Total supervision assignments: 24

The dashboard was reviewed against the
professor-level SQL results.

### Chart 18 — Research Supervision Coverage

Verified SQL results:
- Departments: 8
- Research projects: 16
- Supervised projects: 16
- Unsupervised projects: 0
- Supervision assignments: 24
- Supervision coverage: 100%

Each department has:
- 2 research projects
- 2 supervised projects
- 0 unsupervised projects
- 3 supervision assignments

The Power BI chart and coverage measure
were reviewed against these results.

## 6. DirectQuery Verification

DirectQuery was retained during the
Power BI implementation.

Verification activities included:
- Storage Mode inspection
- SQL source connectivity validation
- Visual rendering review
- Performance Analyzer testing

A recorded Performance Analyzer measurement
for Chart 18 was 118 ms.

This is an observed measurement, not a
formal performance SLA or load-test result.

## 7. Final Visual Quality Assurance

Activities covered:
- Chart 17 supervision workload reconciliation
- Professors with zero assignments
- Chart 18 department-level supervision coverage
- Correct category labels and aggregation
- Tooltip and DAX measure inspection
- SQL-to-dashboard numerical reconciliation

The documented checks support technical
acceptance of the reviewed visualizations.

## 8. Outstanding Business Decisions

Decision D-18 remains open.

Subject:
Timing of mandatory ResearchCollaboration.

The technical database audit passed, but
this business-level decision still requires
formal clarification.

Any additional unresolved business decisions
should be recorded in the final decision log.

## 9. Final Audit Summary

| Audit Area | Result |
|---|---|
| Database Table Structure | PASS |
| Primary Key Validation | PASS |
| Foreign Key Validation | PASS |
| Referential Integrity | PASS |
| Composite Key Mapping | PASS |
| Business Rule Checks | PASS |
| SQL Reconciliation | PASS |
| Chart 17 Verification | Reviewed |
| Chart 18 Verification | Reviewed |
| DirectQuery Configuration | Verified |
| Business Decision D-18 | OPEN |
| GitHub Artifact Publication | IN PROGRESS |

## 10. Project Closure Status

Technical database verification:
PASSED

Documented dashboard verification:
REVIEWED

Outstanding business decisions:
OPEN

GitHub publication:
IN PROGRESS

Overall status:
TECHNICAL AUDIT PASSED —
FINAL PUBLICATION AND BUSINESS CLOSURE PENDING

## 11. Remaining Publication Deliverables

Before declaring the GitHub repository complete,
upload or link the approved project artifacts:

- Conceptual modeling documentation
- Chen and Crow's Foot ERD files
- Relational mapping and normalization documentation
- SQL database creation scripts
- Data population scripts or safe sample data
- SQL verification scripts and audit evidence
- Business queries and DAX documentation
- Power BI report file, when appropriate
- Dashboard screenshots
- Final project validation and closure evidence

Remove sensitive information before publication.

## Conclusion

The available SQL verification evidence supports
successful technical validation of the university
database.

The documented Power BI results demonstrate
reconciliation of selected analytical outputs
with SQL Server.

Formal repository publication and outstanding
business decisions must be addressed before
unconditional project closure.
