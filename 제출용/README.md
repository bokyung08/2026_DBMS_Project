# 🎓 Chonnam University Course & Grade DB

University course registration and grade management database designed from requirements analysis to BCNF normalization, SQL implementation, integrity validation, and index-based query optimization.

MySQL Database Design SQL BCNF InnoDB Portfolio

## 📌 Overview

This repository contains a database systems project for modeling and implementing a university course registration and grade management system.

The project covers the full relational database design workflow: requirement definition, conceptual modeling, logical schema design, functional dependency analysis, normalization, SQL DDL/DML implementation, integrity constraints, views, stored procedures, transactions, and performance optimization with indexes.

The domain is based on Chonnam University course administration. Students register for lectures, professors manage lectures, departments own students and professors, and grades are assigned to completed enrollments.

## 🛠️ Tech Stack

| Category | Tools / Concepts |
| --- | --- |
| DBMS | MySQL 8.0 |
| Storage Engine | InnoDB |
| SQL | DDL, DML, JOIN, VIEW, STORED PROCEDURE, TRANSACTION |
| Data Modeling | ERD, Crow's Foot notation, relational schema mapping |
| Normalization | 1NF, 2NF, 3NF, BCNF |
| Integrity | PK, FK, UNIQUE, CHECK, ENUM, ON DELETE / ON UPDATE |
| Optimization | Index design, EXPLAIN, EXPLAIN ANALYZE |
| Documentation | Markdown project reports, schema definition, validation notes |

## 📂 Repository Layout

```text
제출용/
  README.md
  sql/
    schema.sql
    optimization.sql
  docs/
    01_요구사항지시서.md
    02_스키마정의서.md
    03_개발완료보고서.md
    erd_description.md
```

## 🧩 Database Model

| Entity | Type | Primary Key | Description |
| --- | --- | --- | --- |
| Student | Strong entity | `stuid` | Student profile and department affiliation |
| Dept | Strong entity | `deptid` | Department master data |
| Professor | Strong entity | `pid` | Professor profile and department affiliation |
| Lecture | Strong entity | `lid` | Lecture opened by a professor |
| Enrollment | Weak entity | `enrollid` | Course registration between student and lecture |
| Grade | Weak entity | `gradeid` | Grade assigned to an enrollment |

## 🚀 Quick Start

Run the schema script first.

```bash
mysql -u root -p < sql/schema.sql
```

Then run the optimization and advanced-feature script.

```bash
mysql -u root -p < sql/optimization.sql
```

## 🔬 Advanced Features

| Feature | Implementation |
| --- | --- |
| View | `StudentGradeView`, `LectureStatView` |
| Stored Procedure | `GetStudentGrade(p_stuid)` |
| Transaction | course registration and grade insertion with `COMMIT`, `ROLLBACK`, `SAVEPOINT` |
| Index Optimization | name-search indexes with `EXPLAIN` and `EXPLAIN ANALYZE` comparison |

## 📝 Notes

- Run `schema.sql` before `optimization.sql`.
- MySQL 8.0.18 or later is recommended for `EXPLAIN ANALYZE`.
- The database name used in the scripts is `bokyung`.

