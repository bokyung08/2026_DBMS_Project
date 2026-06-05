USE bokyung;

DELETE FROM Student WHERE stuid BETWEEN 100001 AND 110000;
DELETE FROM Lecture WHERE lid BETWEEN 200001 AND 201000;

LOAD DATA LOCAL INFILE 'data/large_csv/dummy_students_10000.csv'
INTO TABLE Student
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(stuid, sname, stu_year, phone, email, deptid, advisor_pid);

LOAD DATA LOCAL INFILE 'data/large_csv/dummy_lectures_1000.csv'
INTO TABLE Lecture
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(lid, lname, lnum, credit, semester, pid);

LOAD DATA LOCAL INFILE 'data/large_csv/dummy_enrollments_50000.csv'
INTO TABLE Enrollment
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(enrollid, stuid, lid, enroll_date, status, semester, enroll_type);

LOAD DATA LOCAL INFILE 'data/large_csv/dummy_grades_50000.csv'
INTO TABLE Grade
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(gradeid, enrollid, score, grade_letter, evaluation_date, remark);

SELECT 'Student CSV dummy' AS dataset, COUNT(*) AS rows_cnt
FROM Student
WHERE stuid BETWEEN 100001 AND 110000
UNION ALL
SELECT 'Lecture CSV dummy', COUNT(*)
FROM Lecture
WHERE lid BETWEEN 200001 AND 201000
UNION ALL
SELECT 'Enrollment CSV dummy', COUNT(*)
FROM Enrollment
WHERE enrollid BETWEEN 300001 AND 350000
UNION ALL
SELECT 'Grade CSV dummy', COUNT(*)
FROM Grade
WHERE gradeid BETWEEN 400001 AND 450000;

SET @drop_base_student_idx_sql := (
  SELECT IF(
    COUNT(*) > 0,
    'DROP INDEX idx_student_name ON Student',
    'SELECT ''idx_student_name does not exist'' AS info'
  )
  FROM information_schema.statistics
  WHERE table_schema = DATABASE()
    AND table_name = 'Student'
    AND index_name = 'idx_student_name'
);
PREPARE stmt FROM @drop_base_student_idx_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @drop_csv_idx_sql := (
  SELECT IF(
    COUNT(*) > 0,
    'DROP INDEX idx_csv_student_name ON Student',
    'SELECT ''idx_csv_student_name does not exist'' AS info'
  )
  FROM information_schema.statistics
  WHERE table_schema = DATABASE()
    AND table_name = 'Student'
    AND index_name = 'idx_csv_student_name'
);
PREPARE stmt FROM @drop_csv_idx_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

EXPLAIN SELECT * FROM Student WHERE sname = '더미학생05000';

CREATE INDEX idx_csv_student_name ON Student(sname);
EXPLAIN SELECT * FROM Student WHERE sname = '더미학생05000';

EXPLAIN ANALYZE SELECT * FROM Student WHERE sname = '더미학생05000';
