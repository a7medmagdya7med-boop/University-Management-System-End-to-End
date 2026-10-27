
# Phase 2 — ERD Design & Validation

## Project
University Management System — End-to-End

## Objective
Transform the approved conceptual data model into
a validated Entity Relationship Diagram (ERD),
ensuring accurate representation of university
entities, relationships, cardinalities, and
participation constraints.

## ERD Modeling Approaches

### 1. Chen Notation
- Represent entities and their attributes.
- Define relationships between entities.
- Identify relationship cardinalities.
- Document participation constraints.
- Represent the quaternary ResearchCollaboration
  relationship.

### 2. Crow's Foot Notation
- Translate the conceptual relationships into
  a more implementation-oriented representation.
- Validate one-to-many relationships.
- Resolve many-to-many relationships through
  associative structures where appropriate.
- Review mandatory and optional participation.
- Maintain consistency with approved business rules.

## Key Design Decisions

### GraduationProject
- Modeled as a strong entity.
- Supports individual and group projects.
- Each student participates in at most one
  graduation project.
- Each graduation project requires at least
  one participating student.

### ResearchProject
- Each research project has one lead department.
- Collaboration with other departments is allowed.

### ResearchCollaboration
- Represents a quaternary relationship involving:
  Student, Professor, ResearchProject, Department.
- Duplicate combinations are not permitted.
- Multiple collaborating departments are allowed
  for the same Student-Professor-ResearchProject
  combination.

### Course Responsibility
- Professor participation: (0, N).
- Course participation: (1, N).

## Validation Activities
- Entity and relationship consistency review.
- Cardinality verification.
- Participation constraint verification.
- Business-rule alignment.
- Chen and Crow's Foot comparison.
- Final ERD review and approval.

## Validation Status
ERD design and validation approved.

## Open Business Decision
D-18 remains open for business-level clarification
regarding the timing of mandatory research
collaboration.

## Deliverables
- Chen ERD
- Crow's Foot ERD
- Detailed ERD views
- Integrated ERD
- Final validation documentation

Note: Diagram files should be uploaded separately
from the approved local project artifacts.

## Next Phase
Phase 3 — Relational Mapping & Normalization
