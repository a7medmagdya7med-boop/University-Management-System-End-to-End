
# Phase 3 — Relational Mapping & Normalization

## Project
University Management System — End-to-End

## Objective
Convert the approved conceptual ERD into a
relational database schema and evaluate the
resulting tables against normalization rules.

## Relational Mapping

The approved relational schema contains
21 tables.

### Final Relational Tables

1. Book
2. Borrowing
3. ClubMembership
4. Course
5. CourseResponsibility
6. Department
7. DepartmentHead
8. Enrollment
9. GraduationProject
10. GraduationProjectSupervision
11. Library
12. Professor
13. ResearchCollaboration
14. ResearchParticipation
15. ResearchProject
16. ResearchProjectSupervision
17. Semester
18. Student
19. StudentClub
20. StudentPhone
21. UniversityIDCard

## Mapping Principles

- Each strong entity is mapped to a table.
- Primary Keys identify table records.
- Foreign Keys implement relationships.
- Composite Keys are used where appropriate.
- Many-to-many relationships are represented
  through associative tables.
- Relationship constraints must remain
  consistent with the approved business rules.

## Special Design Considerations

### ResearchCollaboration
The quaternary relationship involves:
- Student
- Professor
- ResearchProject
- Department

Its uniqueness rules preserve the complete
collaboration combination.

### Professor Advisor Relationship
AdvisorProfessorID is stored in Professor.

The approved design includes a conditional
functional dependency requiring explicit
documentation and enforcement considerations.

### Graduation Projects
The relational mapping must preserve:
- Individual and group graduation projects.
- At most one graduation project per student.
- At least one student per graduation project.

## Normalization Review

### First Normal Form (1NF)
Review atomic attributes, repeating groups,
and unique row identification.

### Second Normal Form (2NF)
Review partial dependencies, particularly
in tables with composite Primary Keys.

### Third Normal Form (3NF)
Review transitive dependencies and confirm
that non-key attributes follow the approved
functional dependency rules.

## Validation Status

- Relational mapping approved.
- 21-table schema approved.
- Normalization review completed.
- 3NF assessment approved with documented
  design considerations.

## Open Business Decision

D-18:
The timing of mandatory ResearchCollaboration
remains open for business-level confirmation.

This does not automatically invalidate the
approved relational structure.

## Deliverables

- Relational mapping documentation
- Primary Key and Foreign Key definitions
- Normalization analysis
- Functional dependency review
- Approved 21-table relational schema

## Next Phase

Phase 4 — SQL Database Implementation
and Data Integrity Verification
