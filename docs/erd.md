# NSC CourseMate — Entity Relationship Diagram

This diagram shows the core entities of the NSC CourseMate database and their relationships.

## ER Diagram

```mermaid
erDiagram
    PROGRAMS ||--o{ STUDENTS : "enrolls"
    STUDENTS ||--o{ ENROLLMENTS : "has"
    COURSES ||--o{ ENROLLMENTS : "is_taken_in"
    QUARTERS ||--o{ ENROLLMENTS : "occurs_during"
    COURSES ||--o{ PREREQUISITES : "requires"
    COURSES ||--o{ PREREQUISITES : "is_required_by"

    PROGRAMS {
        uuid id PK
        varchar name
        varchar code UK
        int total_credits_required
        text description
        timestamptz created_at
    }

    COURSES {
        uuid id PK
        varchar course_code UK
        varchar title
        text description
        int credits
        timestamptz created_at
    }

    PREREQUISITES {
        uuid id PK
        uuid course_id FK
        uuid prerequisite_course_id FK
        timestamptz created_at
    }

    STUDENTS {
        uuid id PK
        varchar email UK
        varchar first_name
        varchar last_name
        uuid program_id FK
        timestamptz created_at
    }

    QUARTERS {
        uuid id PK
        varchar name UK
        date start_date
        date end_date
    }

    ENROLLMENTS {
        uuid id PK
        uuid student_id FK
        uuid course_id FK
        uuid quarter_id FK
        varchar grade
        varchar status
        timestamptz created_at
    }
```

## Relationships Explained

- **Programs to Students:** A program can have many students; each student belongs to one program (or none).
- **Students to Enrollments:** A student can have many enrollments across different quarters.
- **Courses to Enrollments:** A course can be taken by many students across different quarters.
- **Quarters to Enrollments:** Each enrollment occurs in exactly one quarter.
- **Courses to Prerequisites:** A course can have many prerequisites; a single course can also be a prerequisite for many other courses (self-referential many-to-many through the prerequisites junction table).

## Key Design Decisions

- **UUIDs as primary keys** for all tables to ensure global uniqueness and enable safe horizontal scaling.
- **Self-referential prerequisites** modeled through a junction table to support recursive CTE queries for traversing prerequisite chains.
- **`student_progress` view** abstracts the credit calculation logic away from the application layer, ensuring consistency across all clients.
- **CHECK constraints** validate domain rules at the database layer (e.g., grade values, credits > 0, valid quarter dates).
- **Indexes** added on frequently queried columns: `email`, `course_code`, foreign keys in junction tables.

## Future Schema Additions

- `course_offerings` table to model which courses are offered in which quarters with section, instructor, and capacity data.
- `degree_requirements` table to formalize what courses each program needs.
- `student_plans` and `plan_courses` to support the planner feature for future quarters.
