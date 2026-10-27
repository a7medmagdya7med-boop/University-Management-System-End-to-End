
# Phase 1 — Conceptual Data Modeling

## Project
University Management System — End-to-End

## Objective
Define the university's core business entities,
relationships, cardinalities, and business rules
before developing the Entity Relationship Diagram (ERD).

## Core Business Entities
- Student
- Professor
- Department
- Course
- Enrollment
- GraduationProject
- ResearchProject
- ResearchCollaboration

Additional entities and relationships are documented
in the complete conceptual model.

## Key Business Rules

### Graduation Projects
- Graduation projects can be individual or group-based.
- Each student may participate in at most one graduation project.
- Each graduation project must have at least one student.

### Research Projects
- Each research project has exactly one lead department.
- Other departments may participate through research collaboration.

### Research Collaboration
- ResearchCollaboration is a quaternary relationship
  connecting Student, Professor, ResearchProject,
  and Department.
- Each combination is recorded only once.
- The same Student-Professor-ResearchProject
  combination may collaborate with multiple departments.
- Research collaboration is distinct from research
  participation and research supervision.

## Design Principles
- Business rules drive database design.
- Entity relationships must reflect university operations.
- Cardinality and participation constraints must be documented.
- Conceptual modeling precedes relational mapping.

## Validation Status
Conceptual model approved for ERD development.

## Open Business Decisions
D-18: Timing of mandatory research collaboration
remains open and requires business-level confirmation.

## Next Phase
Phase 2 — ERD Design and Validation
