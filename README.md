# 🎓 Chonnam University Course & Grade DB

> University course registration and grade management database designed from requirements analysis to BCNF normalization, SQL implementation, integrity validation, and index-based query optimization.

[![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=flat-square&logo=mysql&logoColor=white)](https://www.mysql.com/)
[![SQL](https://img.shields.io/badge/SQL-DDL%20%7C%20DML-336791?style=flat-square&logo=postgresql&logoColor=white)]()
[![InnoDB](https://img.shields.io/badge/Engine-InnoDB-005C84?style=flat-square&logo=mysql&logoColor=white)]()
[![Normalization](https://img.shields.io/badge/Normalization-BCNF-6A5ACD?style=flat-square)]()
[![Portfolio](https://img.shields.io/badge/Portfolio-Database%20Design-2E8B57?style=flat-square)]()

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
dbms/
  README.md                    Project overview and execution guide
  sql/
    schema.sql                 Database, tables, constraints, sample data, validation queries
    optimization.sql           Views, procedure, transaction examples, bulk data, index tests
  docs/
    01_요구사항지시서.md          Requirements and entity/relationship definition
    02_스키마정의서.md            Logical schema and FK mapping
    03_개발완료보고서.md          Modeling, FD analysis, normalization, SQL validation
    04_자체검토보고서.md          Self-review and requirement checklist
    05_프로젝트_이해가이드.md      Project explanation guide
    erd_description.md         Text ERD and relationship explanation
  한글_제출본문/
    문서1_요구사항지시서.md        Korean submission body, document 1
    문서2_스키마정의서.md          Korean submission body, document 2
    문서3_개발완료보고서.md        Korean submission body, document 3
  screenshots/
    실행결과_텍스트증거.md         Text evidence for SQL execution results
  제출용/                       Submission-ready copy of core docs and SQL files
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

## 🔗 Relationship Mapping

| Relationship | Cardinality | Implementation |
| --- | --- | --- |
| Student - Dept | N:1 | `Student.deptid` FK |
| Professor - Dept | N:1 | `Professor.deptid` FK |
| Professor - Student | 1:N | `Student.advisor_pid` FK, nullable |
| Professor - Lecture | 1:N | `Lecture.pid` FK |
| Student - Lecture | M:N | resolved through `Enrollment` |
| Enrollment - Grade | 1:1 | `Grade.enrollid` FK + UNIQUE |

## ⚙️ Installation

Install MySQL 8.0 or later.

MySQL Workbench is recommended for visual execution and result capture, but the scripts can also be executed with the MySQL CLI.

```bash
mysql --version
```

The scripts use `utf8mb4` for Korean text and InnoDB for foreign key and transaction support.

## 🚀 Quick Start

Run the schema script first.

```bash
mysql -u root -p < sql/schema.sql
```

Then run the optimization and advanced-feature script.

```bash
mysql -u root -p < sql/optimization.sql
```

Execution order:

```text
1. sql/schema.sql
2. sql/optimization.sql
```

`optimization.sql` assumes that `schema.sql` has already created the `bokyung` database and base sample data.

## ✅ Validation

The project validates the following database constraints and behaviors:

| Validation Target | Method |
| --- | --- |
| Entity integrity | every table has a non-null unique primary key |
| Referential integrity | 7 foreign keys with `RESTRICT`, `SET NULL`, and `CASCADE` rules |
| Domain integrity | `CHECK` constraints for score, grade year, and credit range |
| Key integrity | `UNIQUE` constraints for department name, email, enrollment pair, and grade mapping |
| Duplicate prevention | `UNIQUE(stuid, lid, semester)` blocks repeated registration |
| 1:1 grade mapping | `Grade.enrollid` is both FK and UNIQUE |

Example validation queries are included in `sql/schema.sql` and documented in `docs/03_개발완료보고서.md`.

## 🔬 Advanced Features

| Feature | Implementation |
| --- | --- |
| View | `StudentGradeView`, `LectureStatView` |
| Stored Procedure | `GetStudentGrade(p_stuid)` |
| Transaction | course registration and grade insertion with `COMMIT`, `ROLLBACK`, `SAVEPOINT` |
| Bulk Data | generated students, lectures, enrollments, and grades for performance testing |
| Index Optimization | name-search indexes with `EXPLAIN` and `EXPLAIN ANALYZE` comparison |

The index experiment confirms that query access changes from full scan (`ALL`) to indexed lookup (`ref`) after index creation.

## 📝 Documentation

| Document | Purpose |
| --- | --- |
| `docs/01_요구사항지시서.md` | requirement analysis, entities, attributes, relationships |
| `docs/02_스키마정의서.md` | table schema, FK design, integrity constraints |
| `docs/03_개발완료보고서.md` | conceptual/logical modeling, FD analysis, normalization, SQL implementation |
| `docs/erd_description.md` | ERD structure and relationship explanation |
| `screenshots/실행결과_텍스트증거.md` | execution-result evidence in text form |

## 📦 Submission Notes

The `제출용/` directory contains a compact submission copy of the main documentation and SQL scripts.

The `한글_제출본문/` directory contains Markdown-formatted Korean body text intended for transfer into a Hangul document format.

## ⚠️ Notes

- Run `schema.sql` before `optimization.sql`.
- MySQL 8.0.18 or later is recommended for `EXPLAIN ANALYZE`.
- The database name used in the scripts is `bokyung`.
- Generated DB dumps, local archives, editor settings, and runtime artifacts are excluded through `.gitignore`.
