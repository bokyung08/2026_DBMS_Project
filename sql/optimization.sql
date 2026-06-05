-- =====================================================================
-- optimization.sql
-- 전남대학교 학생 정보·성적관리 데이터베이스
--   - 뷰(View) / 저장 프로시저(Stored Procedure) / 트랜잭션(Transaction)
--   - 대용량 테스트 데이터 생성(학생 1만, 강의 1천, 수강 5만, 성적 5만)
--   - 인덱스(Index) 생성 및 EXPLAIN 기반 성능 비교 실험
-- DBMS: MySQL 8.0
--
-- [선행 조건] 반드시 schema.sql 을 먼저 실행한 뒤 본 파일을 실행한다.
-- [재실행]   본 파일은 상단의 정리(cleanup) 구문 덕분에 반복 실행이 안전하다.
-- =====================================================================

USE bokyung;

-- =====================================================================
-- PART 1. 뷰 (View)
-- =====================================================================

-- 1.1 학생 성적표 뷰 : 학생-학과-수강-강의-성적을 한눈에 조회
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
LEFT JOIN Grade g  ON g.enrollid = e.enrollid;   -- 성적 미입력도 표시(LEFT JOIN)

-- 1.2 (보너스) 강의별 수강 통계 뷰
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

-- 뷰 조회 테스트
SELECT * FROM StudentGradeView WHERE stuid <= 5 ORDER BY stuid, lecture_name;
SELECT * FROM LectureStatView ORDER BY enroll_count DESC LIMIT 10;


-- =====================================================================
-- PART 2. 저장 프로시저 (Stored Procedure)
-- =====================================================================
DROP PROCEDURE IF EXISTS GetStudentGrade;
DELIMITER $$
-- 특정 학생의 성적 상세와 요약(평균점수·신청학점·GPA)을 반환한다.
CREATE PROCEDURE GetStudentGrade(IN p_stuid INT)
BEGIN
  -- (결과셋 1) 성적 상세
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

  -- (결과셋 2) 요약 : 과목수, 평균점수, 신청학점, GPA(4.5 만점)
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

-- 프로시저 호출 테스트 (1번 학생 홍길동)
CALL GetStudentGrade(1);


-- =====================================================================
-- PART 3. 트랜잭션 (Transaction)
-- =====================================================================

-- 3.0 재실행 안전 : 이전 실행에서 만든 트랜잭션 예제 데이터('2026-2' 학기) 정리
--     (Enrollment 삭제 시 FK CASCADE 로 연결된 Grade도 함께 삭제됨)
DELETE FROM Enrollment WHERE semester = '2026-2';

-- 3.1 정상 트랜잭션 : 수강신청 + 성적 입력을 원자적으로 처리 → COMMIT
--     (UNIQUE 충돌을 피하기 위해 '2026-2' 학기로 신규 신청)
START TRANSACTION;
  INSERT INTO Enrollment (stuid, lid, enroll_date, status, semester, enroll_type)
  VALUES (5, 1, '2026-09-01', '완료', '2026-2', '정규');

  SET @new_enroll = LAST_INSERT_ID();

  INSERT INTO Grade (enrollid, score, grade_letter, evaluation_date)
  VALUES (@new_enroll, 92.00, 'A0', '2026-12-20');
COMMIT;
-- 결과 확인
SELECT * FROM Enrollment WHERE enrollid = @new_enroll;

-- 3.2 롤백 예제 : 잘못된 갱신을 되돌린다 → ROLLBACK
--     (CHECK(0~100) 범위 내의 '잘못 입력된' 값으로 바꾼 뒤 되돌린다)
START TRANSACTION;
  UPDATE Grade SET score = 10.00 WHERE enrollid = @new_enroll;  -- 실수로 잘못 입력
  SELECT score AS score_in_tx FROM Grade WHERE enrollid = @new_enroll; -- 트랜잭션 내부 값(10.00)
ROLLBACK;
-- 롤백 후: 원래 값(92.00)으로 복구되었는지 확인
SELECT score AS score_after_rollback FROM Grade WHERE enrollid = @new_enroll;

-- 3.3 SAVEPOINT 부분 롤백 예제
START TRANSACTION;
  UPDATE Grade SET remark = '1차 검토' WHERE enrollid = @new_enroll;
  SAVEPOINT sp1;
  UPDATE Grade SET remark = '2차 검토(취소대상)' WHERE enrollid = @new_enroll;
  ROLLBACK TO sp1;        -- 2차 변경만 취소, 1차 변경은 유지
COMMIT;
SELECT remark AS remark_after_savepoint FROM Grade WHERE enrollid = @new_enroll;


-- =====================================================================
-- PART 4. 대용량 테스트 데이터 생성
--   학생 +10,000 / 강의 +1,000 / 수강 +50,000 / 성적 +50,000
-- =====================================================================

-- 4.0 재실행 안전을 위한 기존 생성 데이터 정리
--     (학생/강의 삭제 시 FK CASCADE 로 수강·성적이 함께 삭제됨)
DELETE FROM Student WHERE sname LIKE '학생%';
DELETE FROM Lecture WHERE lname LIKE '강의%';

-- 4.1 숫자 생성용 테이블 (0~9 → 교차결합으로 1~100000 시퀀스)
--     주의) MySQL은 TEMPORARY 테이블을 한 쿼리에서 2번 이상 참조할 수 없으므로
--           5중 self-join 대상인 gen_digits는 '일반 테이블'로 만든다(끝에서 DROP).
DROP TABLE IF EXISTS gen_digits;
CREATE TABLE gen_digits (d INT);
INSERT INTO gen_digits VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

DROP TEMPORARY TABLE IF EXISTS tmp_seq;
CREATE TEMPORARY TABLE tmp_seq (seq INT PRIMARY KEY);
INSERT INTO tmp_seq (seq)
SELECT a.d + b.d*10 + c.d*100 + dd.d*1000 + e.d*10000 + 1 AS seq
FROM gen_digits a, gen_digits b, gen_digits c, gen_digits dd, gen_digits e;
-- 이제 tmp_seq.seq 는 1 ~ 100000

-- 4.2 학생 10,000명 (deptid 1~6, advisor_pid 1~8 순환)
INSERT INTO Student (sname, stu_year, deptid, advisor_pid)
SELECT CONCAT('학생', LPAD(seq, 5, '0')),
       1 + (seq % 4),          -- 학년 1~4
       1 + (seq % 6),          -- 학과 1~6
       1 + (seq % 8)           -- 지도교수 1~8
FROM tmp_seq
WHERE seq BETWEEN 1 AND 10000;

-- 4.3 강의 1,000개 (pid 1~8 순환)
INSERT INTO Lecture (lname, lnum, credit, semester, pid)
SELECT CONCAT('강의', LPAD(seq, 4, '0')),
       CONCAT('GEN', LPAD(seq, 4, '0')),
       1 + (seq % 3),          -- 학점 1~3
       '2026-1',
       1 + (seq % 8)           -- 담당교수 1~8
FROM tmp_seq
WHERE seq BETWEEN 1 AND 1000;

-- 4.4 수강신청 50,000건
--     생성된 학생/강의의 실제 시작 ID(base)를 읽어 안전하게 매핑한다.
--     (stuid, lid) = (base+0..9999, base+0..4) → 5만 쌍이 모두 유일 → UNIQUE 만족
SET @stu_base := (SELECT MIN(stuid) FROM Student WHERE sname LIKE '학생%');
SET @lec_base := (SELECT MIN(lid)   FROM Lecture WHERE lname LIKE '강의%');

INSERT INTO Enrollment (stuid, lid, enroll_date, status, semester, enroll_type)
SELECT @stu_base + ((seq - 1) % 10000),     -- 학생 10,000명 순환
       @lec_base + ((seq - 1) DIV 10000),   -- 강의 5개 사용(seq 1~50000 → 0~4)
       '2026-03-02',
       '완료',
       '2026-1',
       '정규'
FROM tmp_seq
WHERE seq BETWEEN 1 AND 50000;

-- 4.5 성적 50,000건 : 아직 성적이 없는 '완료' 수강건에 점수 부여
--     점수는 결정적 의사난수(40~100), 등급은 점수 구간에 따라 부여
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

-- 4.6 통계 갱신(옵티마이저 정확도 향상)
ANALYZE TABLE Student, Lecture, Enrollment, Grade;

-- 4.7 생성 결과 행 수 확인
SELECT 'Student' AS tbl, COUNT(*) AS rows_cnt FROM Student
UNION ALL SELECT 'Lecture',    COUNT(*) FROM Lecture
UNION ALL SELECT 'Enrollment', COUNT(*) FROM Enrollment
UNION ALL SELECT 'Grade',      COUNT(*) FROM Grade;


-- =====================================================================
-- PART 5. 인덱스 성능 비교 실험 (EXPLAIN: 인덱스 적용 전 → 후)
-- =====================================================================
--
-- 실험 대상 질의
--   Q1) 학생 이름으로 검색            : Student.sname
--   Q2) 강의명으로 검색               : Lecture.lname
--   Q3) 이름으로 학생 → 수강내역 조인 : Student.sname (구동 테이블) + 조인
--
-- 주의) InnoDB는 FK 컬럼(Enrollment.stuid, Enrollment.lid)에 자동 인덱스를 생성한다.
--       따라서 본 실험은 자동 인덱스가 없는 sname/lname 컬럼을 대상으로 한다.
-- ---------------------------------------------------------------------

-- ----- 5.1 [BEFORE] 인덱스 없는 상태에서 EXPLAIN (type=ALL 풀스캔 예상) -----
EXPLAIN SELECT * FROM Student WHERE sname = '학생05000';
EXPLAIN SELECT * FROM Lecture WHERE lname = '강의0777';
EXPLAIN
SELECT COUNT(*)
FROM Student s
JOIN Enrollment e ON e.stuid = s.stuid
WHERE s.sname = '학생05000';

-- 실제 실행시간까지 보려면(MySQL 8.0.18+):
EXPLAIN ANALYZE SELECT * FROM Student WHERE sname = '학생05000';

-- ----- 5.2 인덱스 생성 -----
CREATE INDEX idx_student_name ON Student(sname);
CREATE INDEX idx_lecture_name ON Lecture(lname);
-- 추가 보조 인덱스(성적 점수 범위 검색용)
CREATE INDEX idx_grade_score   ON Grade(score);

-- 통계 갱신
ANALYZE TABLE Student, Lecture, Grade;

-- ----- 5.3 [AFTER] 인덱스 적용 후 동일 질의 EXPLAIN (type=ref 예상) -----
EXPLAIN SELECT * FROM Student WHERE sname = '학생05000';
EXPLAIN SELECT * FROM Lecture WHERE lname = '강의0777';
EXPLAIN
SELECT COUNT(*)
FROM Student s
JOIN Enrollment e ON e.stuid = s.stuid
WHERE s.sname = '학생05000';

EXPLAIN ANALYZE SELECT * FROM Student WHERE sname = '학생05000';

-- ----- 5.4 인덱스 목록 확인 -----
SHOW INDEX FROM Student;
SHOW INDEX FROM Lecture;

-- ----- 5.5 데이터 생성용 보조 테이블 정리 -----
DROP TABLE IF EXISTS gen_digits;
DROP TEMPORARY TABLE IF EXISTS tmp_seq;

-- =====================================================================
-- [기대 결과 요약]
--   BEFORE : type = ALL,  rows ≈ 테이블 전체(1만~5만),  풀 테이블 스캔
--   AFTER  : type = ref,  rows ≈ 1~수개,                인덱스 탐색
--   → 핵심 조회 질의에서 수십 배 수준의 응답시간 개선 확인
--     (상세 수치/캡처는 docs/03_개발완료보고서.md 8장 및 screenshots/ 참조)
-- =====================================================================
-- optimization.sql 끝
-- =====================================================================

