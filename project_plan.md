# PROJECT_PLAN.md

# Project

Chonnam University Database Design

Course

Database Systems Final Project

Goal

Achieve full score (20/20).

---

# Entities

Strong Entities

1. Student
2. Dept
3. Professor
4. Lecture

Weak Entities

5. Enrollment
6. Grade

---

# Student

stuid (PK)

sname

year

phone

email

---

# Dept

deptid (PK)

dname

college

office

tel

---

# Professor

pid (PK)

pname

rank

email

office

---

# Lecture

lid (PK)

lname

lnum

credit

semester

---

# Enrollment

enrollid (PK)

enroll_date

status

semester

enroll_type

---

# Grade

gradeid (PK)

score

grade_letter

evaluation_date

remark

---

# Relationships

Student N:1 Dept

Student M:N Lecture

Professor 1:N Student

Professor 1:N Lecture

Professor N:1 Dept

Enrollment 1:1 Grade

---

# Required Outputs

1. Requirements Specification
2. Schema Definition
3. Development Report
4. SQL Scripts
5. README
6. Optimization Report

---

# Additional Features

1. View
2. Stored Procedure
3. Transaction
4. Index
5. Query Optimization

---

# Optimization Experiment

Dataset Size

Student: 10000

Lecture: 1000

Enrollment: 50000

Grade: 50000

---

# Compare

Before Index

After Index

Using:

EXPLAIN

Execution Time

Rows Examined

Query Cost

---

# Final Goal

Demonstrate that the optimized database performs significantly better than the non-optimized database.
