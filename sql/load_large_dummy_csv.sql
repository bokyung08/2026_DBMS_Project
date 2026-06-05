-- =====================================================================
-- load_large_dummy_csv.sql
-- CSV 파일 기반 대용량 더미 데이터 적재 실험
--
-- 실행 전:
--   1) python tools/generate_large_dummy_csv.py
--   2) MySQL Workbench에서 schema.sql 실행
--   3) 필요하면 jnu_public_seed.sql 실행
--
-- 주의:
--   - 아래 데이터는 모두 임의 생성 더미 데이터이다.
--   - 실제 학생 개인정보, 실제 학번, 실제 수강신청, 실제 성적은 포함하지 않는다.
--   - LOAD DATA LOCAL INFILE이 막혀 있으면 Workbench 연결 설정에서
--     OPT_LOCAL_INFILE=1 또는 local_infile 옵션을 허용해야 한다.
-- =====================================================================

USE bokyung;

-- 환경에 따라 LOAD DATA LOCAL INFILE 허용 설정이 필요할 수 있다.
-- 권한 오류를 피하기 위해 본 스크립트에서는 전역 설정을 직접 변경하지 않는다.
-- 필요 시 MySQL Workbench 연결 옵션에서 OPT_LOCAL_INFILE=1을 설정하거나,
-- 관리자 권한으로 다음 명령을 별도 실행한다.
-- SET GLOBAL local_infile = 1;

-- 재실행 안전: CSV 더미 데이터만 삭제한다.
DELETE FROM Student WHERE stuid BETWEEN 100001 AND 110000;
DELETE FROM Lecture WHERE lid BETWEEN 200001 AND 201000;

-- 저장소 루트 또는 submission 폴더에서 실행하면 CSV 상대경로가 맞는다.
-- 1) 학생 10,000행 CSV 적재
LOAD DATA LOCAL INFILE 'data/large_csv/dummy_students_10000.csv'
INTO TABLE Student
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(stuid, sname, stu_year, phone, email, deptid, advisor_pid);

-- 2) 강의 1,000행 CSV 적재
LOAD DATA LOCAL INFILE 'data/large_csv/dummy_lectures_1000.csv'
INTO TABLE Lecture
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(lid, lname, lnum, credit, semester, pid);

-- 3) 수강신청 50,000행 CSV 적재
LOAD DATA LOCAL INFILE 'data/large_csv/dummy_enrollments_50000.csv'
INTO TABLE Enrollment
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(enrollid, stuid, lid, enroll_date, status, semester, enroll_type);

-- 4) 성적 50,000행 CSV 적재
LOAD DATA LOCAL INFILE 'data/large_csv/dummy_grades_50000.csv'
INTO TABLE Grade
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(gradeid, enrollid, score, grade_letter, evaluation_date, remark);

-- 적재 결과 확인
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

-- CSV 대용량 데이터 기반 인덱스 전후 비교 예시
-- 같은 컬럼(sname)에 앞 단계 실험 인덱스가 남아 있으면 before 결과가 왜곡되므로 제거한다.
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
