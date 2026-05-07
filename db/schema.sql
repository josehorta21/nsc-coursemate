-- ============================================================
-- NSC CourseMate - Initial Database Schema
-- ============================================================
-- Author: Jose Antonio Horta Herrera
-- Course: AD350 Database Technology - Spring 2026
-- Week: 05
--
-- This schema covers the core entities for the MVP:
-- programs, courses, prerequisites, students, quarters, and enrollments.
-- Designed for PostgreSQL 14+ and Supabase deployment.
-- ============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. PROGRAMS
-- ============================================================
-- Represents an academic program offered by NSC.
-- Examples: AS in Computer Science, Certificate in Web Development.
CREATE TABLE programs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(150) NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    total_credits_required INT NOT NULL CHECK (total_credits_required > 0),
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 2. COURSES
-- ============================================================
-- Represents a single course in the NSC catalog.
-- Examples: CS&141, MATH&151, ENGL&101.
CREATE TABLE courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_code VARCHAR(20) NOT NULL UNIQUE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    credits INT NOT NULL CHECK (credits > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for searching courses by code (very common query).
CREATE INDEX idx_courses_course_code ON courses(course_code);

-- ============================================================
-- 3. PREREQUISITES
-- ============================================================
-- Self-referential many-to-many: a course can require many other courses.
-- Junction table connecting courses to their prerequisite courses.
CREATE TABLE prerequisites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    prerequisite_course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Prevent a course from being its own prerequisite.
    CONSTRAINT no_self_prerequisite CHECK (course_id <> prerequisite_course_id),
    -- Prevent duplicate prerequisite entries for the same pair.
    CONSTRAINT unique_prerequisite_pair UNIQUE (course_id, prerequisite_course_id)
);

-- Index for fast lookup of a course's prerequisites.
CREATE INDEX idx_prerequisites_course_id ON prerequisites(course_id);

-- ============================================================
-- 4. STUDENTS
-- ============================================================
-- Represents a student enrolled in NSC.
-- Linked to a single program (their declared major).
CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    program_id UUID REFERENCES programs(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for email lookups during authentication.
CREATE INDEX idx_students_email ON students(email);

-- ============================================================
-- 5. QUARTERS
-- ============================================================
-- Represents an academic quarter (Fall 2025, Winter 2026, etc.).
CREATE TABLE quarters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL UNIQUE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    CONSTRAINT valid_quarter_dates CHECK (end_date > start_date)
);

-- ============================================================
-- 6. ENROLLMENTS
-- ============================================================
-- Tracks which student took which course in which quarter.
-- Includes the grade earned and enrollment status.
CREATE TABLE enrollments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE RESTRICT,
    quarter_id UUID NOT NULL REFERENCES quarters(id) ON DELETE RESTRICT,
    grade VARCHAR(2) CHECK (grade IN ('A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F', 'W', 'I', 'P', 'NP')),
    status VARCHAR(20) NOT NULL DEFAULT 'enrolled' CHECK (status IN ('enrolled', 'completed', 'dropped', 'withdrawn')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- A student can only enroll in the same course once per quarter.
    CONSTRAINT unique_student_course_quarter UNIQUE (student_id, course_id, quarter_id)
);

-- Index to quickly fetch all enrollments for a given student.
CREATE INDEX idx_enrollments_student_id ON enrollments(student_id);

-- Index to quickly fetch all students enrolled in a course.
CREATE INDEX idx_enrollments_course_id ON enrollments(course_id);

-- ============================================================
-- VIEW: student_progress
-- ============================================================
-- Aggregates total credits earned by each student across all completed
-- courses with passing grades. Useful for the degree progress tracker.
CREATE OR REPLACE VIEW student_progress AS
SELECT
    s.id AS student_id,
    s.first_name,
    s.last_name,
    s.email,
    p.name AS program_name,
    p.total_credits_required,
    COALESCE(SUM(c.credits), 0) AS credits_earned,
    p.total_credits_required - COALESCE(SUM(c.credits), 0) AS credits_remaining
FROM students s
LEFT JOIN programs p ON s.program_id = p.id
LEFT JOIN enrollments e ON s.id = e.student_id
    AND e.status = 'completed'
    AND e.grade NOT IN ('F', 'W', 'NP')
LEFT JOIN courses c ON e.course_id = c.id
GROUP BY s.id, s.first_name, s.last_name, s.email, p.name, p.total_credits_required;

-- ============================================================
-- END OF SCHEMA
-- ============================================================
