USE bokyung;

CREATE OR REPLACE VIEW StudentGradeView AS
SELECT s.stuid,
       s.sname,
       d.dname        AS dept_name,
       l.lname        AS lecture_name,
       l.credit,
       e.semester,
       e.status,
       g.score,
       g.grade_letter
FROM Student s
JOIN Dept d        ON s.deptid = d.deptid
JOIN Enrollment e  ON e.stuid  = s.stuid
JOIN Lecture l     ON e.lid    = l.lid
LEFT JOIN Grade g  ON g.enrollid = e.enrollid;

CREATE OR REPLACE VIEW LectureStatView AS
SELECT l.lid,
       l.lname,
       p.pname             AS professor,
       COUNT(e.enrollid)   AS enroll_count,
       ROUND(AVG(g.score), 2) AS avg_score
FROM Lecture l
JOIN Professor p   ON l.pid = p.pid
LEFT JOIN Enrollment e ON e.lid = l.lid AND e.status <> '취소'
LEFT JOIN Grade g  ON g.enrollid = e.enrollid
GROUP BY l.lid, l.lname, p.pname;

SELECT * FROM StudentGradeView WHERE stuid <= 5 ORDER BY stuid, lecture_name;
SELECT * FROM LectureStatView ORDER BY enroll_count DESC LIMIT 10;

DROP PROCEDURE IF EXISTS GetStudentGrade;
DELIMITER $$
CREATE PROCEDURE GetStudentGrade(IN p_stuid INT)
BEGIN
  SELECT s.stuid,
         s.sname,
         l.lname        AS lecture_name,
         l.credit,
         g.score,
         g.grade_letter
  FROM Student s
  JOIN Enrollment e ON e.stuid = s.stuid
  JOIN Lecture l    ON l.lid   = e.lid
  JOIN Grade g      ON g.enrollid = e.enrollid
  WHERE s.stuid = p_stuid
  ORDER BY l.lname;

  SELECT s.sname                              AS student_name,
         COUNT(g.gradeid)                     AS subject_count,
         ROUND(AVG(g.score), 2)               AS avg_score,
         SUM(l.credit)                        AS total_credit,
         ROUND(
           SUM(
             CASE g.grade_letter
               WHEN 'A+' THEN 4.5 WHEN 'A0' THEN 4.0
               WHEN 'B+' THEN 3.5 WHEN 'B0' THEN 3.0
               WHEN 'C+' THEN 2.5 WHEN 'C0' THEN 2.0
               WHEN 'D+' THEN 1.5 WHEN 'D0' THEN 1.0
               ELSE 0
             END * l.credit
           ) / NULLIF(SUM(l.credit), 0), 2)   AS gpa
  FROM Student s
  JOIN Enrollment e ON e.stuid = s.stuid
  JOIN Lecture l    ON l.lid   = e.lid
  JOIN Grade g      ON g.enrollid = e.enrollid
  WHERE s.stuid = p_stuid
  GROUP BY s.stuid, s.sname;
END$$
DELIMITER ;

CALL GetStudentGrade(1);

DELETE FROM Enrollment WHERE semester = '2026-2';

START TRANSACTION;
  INSERT INTO Enrollment (stuid, lid, enroll_date, status, semester, enroll_type)
  VALUES (5, 1, '2026-09-01', '완료', '2026-2', '정규');

  SET @new_enroll = LAST_INSERT_ID();

  INSERT INTO Grade (enrollid, score, grade_letter, evaluation_date)
  VALUES (@new_enroll, 92.00, 'A0', '2026-12-20');
COMMIT;
SELECT * FROM Enrollment WHERE enrollid = @new_enroll;

START TRANSACTION;
  UPDATE Grade SET score = 10.00 WHERE enrollid = @new_enroll;
  SELECT score AS score_in_tx FROM Grade WHERE enrollid = @new_enroll;
ROLLBACK;
SELECT score AS score_after_rollback FROM Grade WHERE enrollid = @new_enroll;

START TRANSACTION;
  UPDATE Grade SET remark = '1차 검토' WHERE enrollid = @new_enroll;
  SAVEPOINT sp1;
  UPDATE Grade SET remark = '2차 검토(취소대상)' WHERE enrollid = @new_enroll;
  ROLLBACK TO sp1;
COMMIT;
SELECT remark AS remark_after_savepoint FROM Grade WHERE enrollid = @new_enroll;

DELETE FROM Student WHERE sname LIKE '학생%';
DELETE FROM Lecture WHERE lname LIKE '강의%';

DROP TABLE IF EXISTS gen_digits;
CREATE TABLE gen_digits (d INT);
INSERT INTO gen_digits VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

DROP TEMPORARY TABLE IF EXISTS tmp_seq;
CREATE TEMPORARY TABLE tmp_seq (seq INT PRIMARY KEY);
INSERT INTO tmp_seq (seq)
SELECT a.d + b.d*10 + c.d*100 + dd.d*1000 + e.d*10000 + 1 AS seq
FROM gen_digits a, gen_digits b, gen_digits c, gen_digits dd, gen_digits e;

INSERT INTO Student (sname, stu_year, deptid, advisor_pid)
SELECT CONCAT('학생', LPAD(seq, 5, '0')),
       1 + (seq % 4),
       1 + (seq % 6),
       1 + (seq % 8)
FROM tmp_seq
WHERE seq BETWEEN 1 AND 10000;

INSERT INTO Lecture (lname, lnum, credit, semester, pid)
SELECT CONCAT('강의', LPAD(seq, 4, '0')),
       CONCAT('GEN', LPAD(seq, 4, '0')),
       1 + (seq % 3),
       '2026-1',
       1 + (seq % 8)
FROM tmp_seq
WHERE seq BETWEEN 1 AND 1000;

SET @stu_base := (SELECT MIN(stuid) FROM Student WHERE sname LIKE '학생%');
SET @lec_base := (SELECT MIN(lid)   FROM Lecture WHERE lname LIKE '강의%');

INSERT INTO Enrollment (stuid, lid, enroll_date, status, semester, enroll_type)
SELECT @stu_base + ((seq - 1) % 10000),
       @lec_base + ((seq - 1) DIV 10000),
       '2026-03-02',
       '완료',
       '2026-1',
       '정규'
FROM tmp_seq
WHERE seq BETWEEN 1 AND 50000;

INSERT INTO Grade (enrollid, score, grade_letter, evaluation_date)
SELECT e.enrollid,
       sc.score,
       CASE
         WHEN sc.score >= 95 THEN 'A+'  WHEN sc.score >= 90 THEN 'A0'
         WHEN sc.score >= 85 THEN 'B+'  WHEN sc.score >= 80 THEN 'B0'
         WHEN sc.score >= 75 THEN 'C+'  WHEN sc.score >= 70 THEN 'C0'
         WHEN sc.score >= 65 THEN 'D+'  WHEN sc.score >= 60 THEN 'D0'
         ELSE 'F'
       END,
       '2026-06-20'
FROM Enrollment e
JOIN ( SELECT enrollid, ROUND(40 + ((enrollid * 17) % 61), 2) AS score
       FROM Enrollment ) sc ON sc.enrollid = e.enrollid
LEFT JOIN Grade g ON g.enrollid = e.enrollid
WHERE g.gradeid IS NULL
  AND e.status = '완료';

ANALYZE TABLE Student, Lecture, Enrollment, Grade;

SELECT 'Student' AS tbl, COUNT(*) AS rows_cnt FROM Student
UNION ALL SELECT 'Lecture',    COUNT(*) FROM Lecture
UNION ALL SELECT 'Enrollment', COUNT(*) FROM Enrollment
UNION ALL SELECT 'Grade',      COUNT(*) FROM Grade;

EXPLAIN SELECT * FROM Student WHERE sname = '학생05000';
EXPLAIN SELECT * FROM Lecture WHERE lname = '강의0777';
EXPLAIN
SELECT COUNT(*)
FROM Student s
JOIN Enrollment e ON e.stuid = s.stuid
WHERE s.sname = '학생05000';

EXPLAIN ANALYZE SELECT * FROM Student WHERE sname = '학생05000';

CREATE INDEX idx_student_name ON Student(sname);
CREATE INDEX idx_lecture_name ON Lecture(lname);
CREATE INDEX idx_grade_score   ON Grade(score);

ANALYZE TABLE Student, Lecture, Grade;

EXPLAIN SELECT * FROM Student WHERE sname = '학생05000';
EXPLAIN SELECT * FROM Lecture WHERE lname = '강의0777';
EXPLAIN
SELECT COUNT(*)
FROM Student s
JOIN Enrollment e ON e.stuid = s.stuid
WHERE s.sname = '학생05000';

EXPLAIN ANALYZE SELECT * FROM Student WHERE sname = '학생05000';

SHOW INDEX FROM Student;
SHOW INDEX FROM Lecture;

DROP TABLE IF EXISTS gen_digits;
DROP TEMPORARY TABLE IF EXISTS tmp_seq;
