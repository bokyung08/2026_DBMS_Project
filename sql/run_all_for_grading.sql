-- =====================================================================
-- run_all_for_grading.sql
--
-- 실행 위치: 저장소 루트(dbms 또는 submission)에서 실행
--
-- 포함 내용:
--   1) schema.sql: DB/테이블/기본 데이터
--   2) jnu_public_seed.sql: 전남대 공식 공개 학과 데이터 + 고급 기능
--   3) optimization.sql: SQL 내부 대용량 데이터 + 인덱스 실험
--   4) load_large_dummy_csv.sql: CSV 대용량 더미 데이터 적재 + 인덱스 실험
-- =====================================================================


-- =====================================================================
-- BEGIN sql\schema.sql
-- =====================================================================

-- =====================================================================
-- schema.sql
-- 전남대학교 학생 정보·성적관리 데이터베이스 — 스키마 및 샘플 데이터
-- 실행 도구: MySQL Workbench
--
-- [실행 순서]
--   1) 본 파일을 먼저 실행하여 DB/테이블/샘플데이터를 생성한다.
--   2) 이후 optimization.sql 을 실행하여 뷰/프로시저/인덱스/성능실험을 수행한다.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. 데이터베이스 생성
-- ---------------------------------------------------------------------
DROP DATABASE IF EXISTS bokyung;
CREATE DATABASE bokyung
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;
USE bokyung;

-- 외래키 의존성 때문에 자식 → 부모 순으로 미리 삭제(재실행 안전성)
DROP TABLE IF EXISTS Grade;
DROP TABLE IF EXISTS Enrollment;
DROP TABLE IF EXISTS Lecture;
DROP TABLE IF EXISTS Student;
DROP TABLE IF EXISTS Professor;
DROP TABLE IF EXISTS Dept;

-- ---------------------------------------------------------------------
-- 1. 테이블 생성 (부모 → 자식 순)
-- ---------------------------------------------------------------------

-- 1.1 학과(Dept) : 강 개체
CREATE TABLE Dept (
  deptid   INT AUTO_INCREMENT PRIMARY KEY,
  dname    VARCHAR(50) NOT NULL,
  college  VARCHAR(50) NOT NULL,
  office   VARCHAR(50),
  tel      VARCHAR(20),
  CONSTRAINT uq_dept_name UNIQUE (dname)
) ENGINE=InnoDB;

-- 1.2 교수(Professor) : 강 개체, Dept N:1
CREATE TABLE Professor (
  pid        INT AUTO_INCREMENT PRIMARY KEY,
  pname      VARCHAR(30) NOT NULL,
  prof_rank  VARCHAR(20) NOT NULL,          
  email      VARCHAR(100),
  office     VARCHAR(50),
  deptid     INT NOT NULL,
  CONSTRAINT uq_prof_email UNIQUE (email),
  CONSTRAINT fk_prof_dept FOREIGN KEY (deptid) REFERENCES Dept(deptid)
      ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 1.3 학생(Student) : 강 개체, Dept N:1, Professor(지도) N:1
CREATE TABLE Student (
  stuid        INT AUTO_INCREMENT PRIMARY KEY,
  sname        VARCHAR(30) NOT NULL,
  stu_year     TINYINT NOT NULL,            
  phone        VARCHAR(20),
  email        VARCHAR(100),
  deptid       INT NOT NULL,
  advisor_pid  INT,                         -- 지도교수 미배정 허용(NULL)
  CONSTRAINT uq_stu_email UNIQUE (email),
  CONSTRAINT chk_stu_year CHECK (stu_year BETWEEN 1 AND 4),
  CONSTRAINT fk_stu_dept FOREIGN KEY (deptid) REFERENCES Dept(deptid)
      ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_stu_advisor FOREIGN KEY (advisor_pid) REFERENCES Professor(pid)
      ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 1.4 강의(Lecture) : 강 개체, Professor 1:N
CREATE TABLE Lecture (
  lid       INT AUTO_INCREMENT PRIMARY KEY,
  lname     VARCHAR(60) NOT NULL,
  lnum      VARCHAR(20) NOT NULL,
  credit    TINYINT NOT NULL,
  semester  VARCHAR(10) NOT NULL,
  pid       INT NOT NULL,
  CONSTRAINT chk_lec_credit CHECK (credit BETWEEN 1 AND 3),
  CONSTRAINT fk_lec_prof FOREIGN KEY (pid) REFERENCES Professor(pid)
      ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 1.5 수강신청(Enrollment) : 약 개체, Student M:N Lecture 해소
CREATE TABLE Enrollment (
  enrollid     INT AUTO_INCREMENT PRIMARY KEY,
  stuid        INT NOT NULL,
  lid          INT NOT NULL,
  enroll_date  DATE NOT NULL,
  status       ENUM('수강중','취소','완료') NOT NULL DEFAULT '수강중',
  semester     VARCHAR(10) NOT NULL,
  enroll_type  ENUM('정규','재수강') NOT NULL DEFAULT '정규',
  CONSTRAINT fk_enr_stu FOREIGN KEY (stuid) REFERENCES Student(stuid)
      ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_enr_lec FOREIGN KEY (lid) REFERENCES Lecture(lid)
      ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT uq_enroll UNIQUE (stuid, lid, semester)   -- 동일 학기 중복신청 방지
) ENGINE=InnoDB;

-- 1.6 성적(Grade) : 약 개체, Enrollment 1:1
CREATE TABLE Grade (
  gradeid          INT AUTO_INCREMENT PRIMARY KEY,
  enrollid         INT NOT NULL,
  score            DECIMAL(5,2) NOT NULL,
  grade_letter     VARCHAR(2),
  evaluation_date  DATE,
  remark           VARCHAR(100),
  CONSTRAINT uq_grade_enroll UNIQUE (enrollid),         -- 1:1 보장
  CONSTRAINT chk_grade_score CHECK (score >= 0 AND score <= 100),
  CONSTRAINT fk_grade_enr FOREIGN KEY (enrollid) REFERENCES Enrollment(enrollid)
      ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. 샘플 데이터 삽입
-- ---------------------------------------------------------------------

-- 2.1 학과
INSERT INTO Dept (deptid, dname, college, office, tel) VALUES
 (1, '컴퓨터공학과',   '공과대학',     '공대1호관 301', '062-530-1111'),
 (2, '전자공학과',     '공과대학',     '공대2호관 210', '062-530-2222'),
 (3, '경영학과',       '경영대학',     '경영관 105',    '062-530-3333'),
 (4, '수학과',         '자연과학대학', '자연관 402',    '062-530-4444'),
 (5, '화학공학과',     '공과대학',     '공대3호관 115', '062-530-5555'),
 (6, '영어영문학과',   '인문대학',     '인문관 220',    '062-530-6666');

-- 2.2 교수 (prof_rank: 전임강사/조교수/부교수/정교수)
INSERT INTO Professor (pid, pname, prof_rank, email, office, deptid) VALUES
 (1, '김민준', '정교수',   'kmj@jnu.ac.kr', '공대1호관 501', 1),
 (2, '이서연', '부교수',   'lsy@jnu.ac.kr', '공대1호관 502', 1),
 (3, '박지호', '조교수',   'pjh@jnu.ac.kr', '공대2호관 305', 2),
 (4, '최유진', '정교수',   'cyj@jnu.ac.kr', '경영관 210',    3),
 (5, '정우성', '부교수',   'jws@jnu.ac.kr', '자연관 410',    4),
 (6, '강하늘', '조교수',   'khn@jnu.ac.kr', '공대3호관 220', 5),
 (7, '조정석', '전임강사', 'jjs@jnu.ac.kr', '인문관 305',    6),
 (8, '윤아름', '정교수',   'yar@jnu.ac.kr', '공대1호관 503', 1);

-- 2.3 학생 (advisor_pid 12번은 미배정=NULL)
INSERT INTO Student (stuid, sname, stu_year, phone, email, deptid, advisor_pid) VALUES
 (1,  '홍길동', 3, '010-1000-0001', 'hgd@jnu.ac.kr', 1, 1),
 (2,  '김철수', 2, '010-1000-0002', 'kcs@jnu.ac.kr', 1, 2),
 (3,  '이영희', 4, '010-1000-0003', 'lyh@jnu.ac.kr', 1, 8),
 (4,  '박민수', 1, '010-1000-0004', 'pms@jnu.ac.kr', 2, 3),
 (5,  '정수빈', 3, '010-1000-0005', 'jsb@jnu.ac.kr', 2, 3),
 (6,  '강지원', 2, '010-1000-0006', 'kjw@jnu.ac.kr', 3, 4),
 (7,  '윤도현', 4, '010-1000-0007', 'ydh@jnu.ac.kr', 3, 4),
 (8,  '임세진', 1, '010-1000-0008', 'isj@jnu.ac.kr', 4, 5),
 (9,  '한지민', 3, '010-1000-0009', 'hjm@jnu.ac.kr', 4, 5),
 (10, '오현우', 2, '010-1000-0010', 'ohw@jnu.ac.kr', 5, 6),
 (11, '신유나', 4, '010-1000-0011', 'syn@jnu.ac.kr', 6, 7),
 (12, '배수지', 1, '010-1000-0012', 'bsj@jnu.ac.kr', 6, NULL);

-- 2.4 강의 (semester 2026-1)
INSERT INTO Lecture (lid, lname, lnum, credit, semester, pid) VALUES
 (1, '데이터베이스',     'CSE301', 3, '2026-1', 1),
 (2, '운영체제',         'CSE302', 3, '2026-1', 2),
 (3, '자료구조',         'CSE201', 3, '2026-1', 1),
 (4, '디지털논리회로',   'EEE201', 3, '2026-1', 3),
 (5, '경영학원론',       'BUS101', 3, '2026-1', 4),
 (6, '선형대수',         'MAT201', 3, '2026-1', 5),
 (7, '화학공학개론',     'CHE101', 3, '2026-1', 6),
 (8, '영미문학',         'ENG201', 3, '2026-1', 7);

-- 2.5 수강신청
INSERT INTO Enrollment (enrollid, stuid, lid, enroll_date, status, semester, enroll_type) VALUES
 (1,  1,  1, '2026-03-02', '완료',   '2026-1', '정규'),
 (2,  1,  3, '2026-03-02', '완료',   '2026-1', '정규'),
 (3,  2,  1, '2026-03-02', '완료',   '2026-1', '정규'),
 (4,  2,  2, '2026-03-02', '수강중', '2026-1', '정규'),
 (5,  3,  1, '2026-03-02', '완료',   '2026-1', '정규'),
 (6,  3,  3, '2026-03-02', '완료',   '2026-1', '정규'),
 (7,  4,  4, '2026-03-02', '완료',   '2026-1', '정규'),
 (8,  5,  4, '2026-03-02', '수강중', '2026-1', '정규'),
 (9,  6,  5, '2026-03-02', '완료',   '2026-1', '정규'),
 (10, 7,  5, '2026-03-02', '완료',   '2026-1', '정규'),
 (11, 8,  6, '2026-03-02', '완료',   '2026-1', '정규'),
 (12, 9,  6, '2026-03-02', '수강중', '2026-1', '정규'),
 (13, 10, 7, '2026-03-02', '완료',   '2026-1', '정규'),
 (14, 11, 8, '2026-03-02', '완료',   '2026-1', '정규'),
 (15, 12, 8, '2026-03-02', '수강중', '2026-1', '정규'),
 (16, 1,  2, '2026-03-02', '취소',   '2026-1', '정규'),
 (17, 4,  1, '2026-03-02', '완료',   '2026-1', '재수강'),
 (18, 2,  3, '2026-03-02', '완료',   '2026-1', '정규');

-- 2.6 성적 (status='완료' 인 수강신청에 대해서만 부여)
INSERT INTO Grade (gradeid, enrollid, score, grade_letter, evaluation_date, remark) VALUES
 (1,  1,  95.00, 'A+', '2026-06-20', NULL),
 (2,  2,  88.00, 'B+', '2026-06-20', NULL),
 (3,  3,  91.00, 'A0', '2026-06-20', NULL),
 (4,  5,  78.00, 'C+', '2026-06-20', NULL),
 (5,  6,  83.00, 'B0', '2026-06-20', NULL),
 (6,  7,  99.00, 'A+', '2026-06-20', NULL),
 (7,  9,  72.00, 'C0', '2026-06-20', NULL),
 (8,  10, 85.00, 'B+', '2026-06-20', NULL),
 (9,  11, 67.00, 'D+', '2026-06-20', NULL),
 (10, 13, 90.00, 'A0', '2026-06-20', NULL),
 (11, 14, 100.00,'A+', '2026-06-20', NULL),
 (12, 17, 81.00, 'B0', '2026-06-20', '재수강 학점');

-- ---------------------------------------------------------------------
-- 3. 조회(SELECT) 테스트
-- ---------------------------------------------------------------------

-- 3.1 학과별 소속 학생 수
SELECT d.dname AS 학과, COUNT(s.stuid) AS 학생수
FROM Dept d
LEFT JOIN Student s ON s.deptid = d.deptid
GROUP BY d.deptid, d.dname
ORDER BY 학생수 DESC;

-- 3.2 교수별 담당 강의 목록
SELECT p.pname AS 교수, p.prof_rank AS 직급, l.lname AS 강의명, l.credit AS 학점
FROM Professor p
JOIN Lecture l ON l.pid = p.pid
ORDER BY p.pname;

-- 3.3 학생 성적표 (학생-강의-성적 조인)
SELECT s.sname AS 학생, l.lname AS 강의, g.score AS 점수, g.grade_letter AS 등급
FROM Student s
JOIN Enrollment e ON e.stuid = s.stuid
JOIN Lecture l    ON l.lid = e.lid
JOIN Grade g      ON g.enrollid = e.enrollid
ORDER BY s.sname, l.lname;

-- 3.4 강의별 수강 인원(취소 제외)
SELECT l.lname AS 강의, COUNT(*) AS 수강인원
FROM Lecture l
JOIN Enrollment e ON e.lid = l.lid AND e.status <> '취소'
GROUP BY l.lid, l.lname
ORDER BY 수강인원 DESC;

-- 3.5 학생별 평균 점수(성적이 있는 학생만) — 서브쿼리 활용
SELECT sub.sname AS 학생, ROUND(AVG(sub.score), 2) AS 평균점수
FROM (
  SELECT s.stuid, s.sname, g.score
  FROM Student s
  JOIN Enrollment e ON e.stuid = s.stuid
  JOIN Grade g      ON g.enrollid = e.enrollid
) AS sub
GROUP BY sub.stuid, sub.sname
ORDER BY 평균점수 DESC;

-- 3.6 지도교수가 미배정된 학생
SELECT stuid, sname FROM Student WHERE advisor_pid IS NULL;

-- =====================================================================
-- schema.sql 끝
-- =====================================================================


-- =====================================================================
-- END sql\schema.sql
-- =====================================================================


-- =====================================================================
-- BEGIN sql\jnu_public_seed.sql
-- =====================================================================

-- =====================================================================
-- jnu_public_seed.sql
-- 전남대학교 공식 대표 홈페이지 공개 학과 정보를 Dept에 반영한다.
-- 출처: https://www.jnu.ac.kr/MainUniversity/University/Uni_Total
--
-- 주의:
--   - 학과명/단과대학명 같은 공개 정보만 사용한다.
--   - 학생 개인정보, 실제 학번, 실제 성적, 포털 로그인 정보는 사용하지 않는다.
--   - schema.sql 실행 후 선택적으로 실행한다.
-- =====================================================================

USE bokyung;

INSERT INTO Dept (dname, college, office, tel) VALUES
  ('미래모빌리티학과', 'AI융합대학', '101호', '062-530-5114'),
  ('빅데이터융합학과', 'AI융합대학', '102호', '062-530-5114'),
  ('융합전공', 'AI융합대학', '103호', '062-530-5114'),
  ('인공지능학부', 'AI융합대학', '104호', '062-530-5114'),
  ('간호학과', '간호대학', '105호', '062-530-4937'),
  ('경영학부', '경영대학', '106호', '062-530-1430'),
  ('경제학부', '경영대학', '107호', '062-530-1540'),
  ('건축학부', '공과대학', '108호', '062-530-1630'),
  ('고분자융합소재공학부', '공과대학', '109호', '062-530-1870'),
  ('기계공학부', '공과대학', '110호', '062-530-1660'),
  ('산업공학과', '공과대학', '111호', '062-530-1780'),
  ('생물공학과', '공과대학', '112호', '062-530-1048'),
  ('소프트웨어공학과', '공과대학', '113호', '062-530-1750'),
  ('신소재공학부', '공과대학', '114호', '062-530-1711'),
  ('에너지자원공학과', '공과대학', '115호', '062-530-1720'),
  ('전기공학과', '공과대학', '116호', '062-530-1740'),
  ('전자공학과', '공과대학', '117호', '062-530-1800'),
  ('전자컴퓨터공학부', '공과대학', '118호', '062-530-1800'),
  ('컴퓨터정보통신공학과', '공과대학', '119호', '062-530-1751'),
  ('토목공학과', '공과대학', '120호', '062-530-1650'),
  ('화학공학부', '공과대학', '121호', '062-530-5114'),
  ('환경에너지공학과', '공과대학', '122호', '062-530-1860'),
  ('건축디자인학과', '공학대학(여수)', '123호', '061-659-7330'),
  ('기계설계공학과', '공학대학(여수)', '124호', '061-659-7280'),
  ('기계시스템공학과', '공학대학(여수)', '125호', '061-659-7220'),
  ('냉동공조공학과', '공학대학(여수)', '126호', '061-659-7270'),
  ('메카트로닉스공학과', '공학대학(여수)', '127호', '061-659-7710'),
  ('산업기술융합공학과', '공학대학(여수)', '128호', '061-659-7750'),
  ('석유화학소재공학과', '공학대학(여수)', '129호', '061-659-7760'),
  ('융합생명공학과', '공학대학(여수)', '130호', '061-659-7300'),
  ('의공학과', '공학대학(여수)', '131호', '061-659-7360'),
  ('의공학부', '공학대학(여수)', '132호', '061-659-7360'),
  ('전자통신공학과', '공학대학(여수)', '133호', '061-659-7230'),
  ('조기취업형 계약학과', '공학대학(여수)', '134호', '061-659-6894'),
  ('해양토목공학과', '공학대학(여수)', '135호', '061-659-7240'),
  ('화공생명공학과', '공학대학(여수)', '136호', '061-659-7290'),
  ('환경시스템공학과', '공학대학(여수)', '137호', '061-659-7260'),
  ('농생명화학과', '농업생명과학대학', '138호', '062-530-2130'),
  ('농업경제학과', '농업생명과학대학', '139호', '062-530-2170'),
  ('동물자원학부', '농업생명과학대학', '140호', '062-530-2120'),
  ('바이오에너지공학과', '농업생명과학대학', '141호', '062-530-2043'),
  ('분자생명공학과', '농업생명과학대학', '142호', '062-530-5114'),
  ('산림자원학과', '농업생명과학대학', '143호', '062-530-2080'),
  ('식물생명공학부', '농업생명과학대학', '144호', '062-530-2050'),
  ('식품공학과', '농업생명과학대학', '145호', '062-530-5114'),
  ('융합바이오시스템기계공학과', '농업생명과학대학', '146호', '062-530-0850'),
  ('임산공학과', '농업생명과학대학', '147호', '062-530-2090'),
  ('조경학과', '농업생명과학대학', '148호', '062-530-2100'),
  ('지역 바이오시스템공학과', '농업생명과학대학', '149호', '062-530-2150'),
  ('국제학부', '문화사회과학대학(여수)', '150호', '061-659-7510'),
  ('글로벌비즈니스학부', '문화사회과학대학(여수)', '151호', '061-659-7530'),
  ('문화관광경영학과', '문화사회과학대학(여수)', '152호', '061-659-7640'),
  ('문화콘텐츠학부', '문화사회과학대학(여수)', '153호', '061-659-7440'),
  ('물류교통학과', '문화사회과학대학(여수)', '154호', '061-659-7340'),
  ('가정교육과', '사범대학', '155호', '062-530-2520'),
  ('교육학과', '사범대학', '156호', '062-530-2340'),
  ('국어교육과', '사범대학', '157호', '062-530-2410'),
  ('물리교육과', '사범대학', '158호', '062-530-2480'),
  ('생물교육과', '사범대학', '159호', '062-530-2500'),
  ('수학교육과', '사범대학', '160호', '062-530-2470'),
  ('역사교육과', '사범대학', '161호', '062-530-2370'),
  ('영어교육과', '사범대학', '162호', '062-530-2430'),
  ('유아교육과', '사범대학', '163호', '062-530-2360'),
  ('윤리교육과', '사범대학', '164호', '062-530-2400'),
  ('음악교육과', '사범대학', '165호', '062-530-2530'),
  ('지구과학교육과', '사범대학', '166호', '062-530-2510'),
  ('지리교육과', '사범대학', '167호', '062-530-2380'),
  ('체육교육과', '사범대학', '168호', '062-530-2550'),
  ('특수교육학부', '사범대학', '169호', '062-530-5410'),
  ('화학교육과', '사범대학', '170호', '062-530-2490'),
  ('문헌정보학과', '사회과학대학', '171호', '062-530-2660'),
  ('문화인류고고학과', '사회과학대학', '172호', '062-530-2690'),
  ('미디어커뮤니케이션학과', '사회과학대학', '173호', '062-530-2670'),
  ('사회학과', '사회과학대학', '174호', '062-530-2640'),
  ('심리학과', '사회과학대학', '175호', '062-530-2650'),
  ('정치외교학과', '사회과학대학', '176호', '062-530-2620'),
  ('지리학과', '사회과학대학', '177호', '062-530-2680'),
  ('행정학과', '사회과학대학', '178호', '062-530-2250'),
  ('생활복지학과', '생활과학대학', '179호', '062-530-1320'),
  ('식품영양과학부', '생활과학대학', '180호', '062-530-1330'),
  ('의류학과', '생활과학대학', '181호', '062-530-1340'),
  ('기관시스템공학과', '수산해양대학(여수)', '182호', '061-659-7130'),
  ('수산생명의학과', '수산해양대학(여수)', '183호', '061-659-7170'),
  ('수산해양산업관광레저융합학과', '수산해양대학(여수)', '184호', '061-659-7190'),
  ('스마트수산자원관리학과', '수산해양대학(여수)', '185호', '061-659-7410'),
  ('양식생물학과', '수산해양대학(여수)', '186호', '061-659-7160'),
  ('조선해양공학과', '수산해양대학(여수)', '187호', '061-659-7150'),
  ('해양경찰학과', '수산해양대학(여수)', '188호', '061-659-7180'),
  ('해양바이오식품학과', '수산해양대학(여수)', '189호', '061-659-7210'),
  ('해양생산관리학과', '수산해양대학(여수)', '190호', '061-659-7120'),
  ('해양융합과학과', '수산해양대학(여수)', '191호', '061-659-7140'),
  ('수의예과', '수의과대학', '192호', '062-530-2805'),
  ('수의학과', '수의과대학', '193호', '062-530-2805'),
  ('약학부', '약학대학', '194호', '062-530-2920'),
  ('국악학과', '예술대학', '195호', '062-530-3050'),
  ('디자인학과', '예술대학', '196호', '062-530-3070'),
  ('미술학과', '예술대학', '197호', '062-530-2540'),
  ('음악학과', '예술대학', '198호', '062-530-3030'),
  ('의예과', '의과대학', '199호', '062-530-4191'),
  ('의학과', '의과대학', '200호', '062-220-4000'),
  ('국어국문학과', '인문대학', '201호', '062-530-3130'),
  ('독일언어문학과', '인문대학', '202호', '062-530-3170'),
  ('불어불문학과', '인문대학', '203호', '062-530-3190'),
  ('사학과', '인문대학', '204호', '062-530-3240'),
  ('영어영문학과', '인문대학', '205호', '062-530-3150'),
  ('일어일문학과', '인문대학', '206호', '062-530-3210'),
  ('중어중문학과', '인문대학', '207호', '062-530-3200'),
  ('철학과', '인문대학', '208호', '062-530-3220'),
  ('물리학과', '자연과학대학', '209호', '062-530-3350'),
  ('생물학과', '자연과학대학', '210호', '062-530-3390'),
  ('수학과', '자연과학대학', '211호', '062-530-3330'),
  ('지구환경과학부', '자연과학대학', '212호', '062-530-5114'),
  ('통계학과', '자연과학대학', '213호', '062-530-3440'),
  ('화학과', '자연과학대학', '214호', '062-530-3370')
ON DUPLICATE KEY UPDATE
  college = VALUES(college),
  office = VALUES(office),
  tel = VALUES(tel);

-- 공식 공개 학과 데이터 반영 확인
SELECT college AS 단과대학, COUNT(*) AS 학과수
FROM Dept
WHERE office REGEXP '^[0-9]{3}호$'
GROUP BY college
ORDER BY 학과수 DESC, college;

-- =====================================================================
-- 공식 공개 학과 데이터 기반 고급 기능 구현
-- =====================================================================

-- 1) View: 전남대학교 공식 공개 학과 목록 조회
CREATE OR REPLACE VIEW JnuPublicDeptView AS
SELECT deptid,
       dname   AS department_name,
       college AS college_name,
       tel
FROM Dept
WHERE office REGEXP '^[0-9]{3}호$';

-- 2) View: 단과대학별 공식 공개 학과 수 집계
CREATE OR REPLACE VIEW JnuCollegeDeptStatView AS
SELECT college AS college_name,
       COUNT(*) AS department_count
FROM Dept
WHERE office REGEXP '^[0-9]{3}호$'
GROUP BY college;

SELECT * FROM JnuPublicDeptView
WHERE college_name = '공과대학'
ORDER BY department_name;

SELECT * FROM JnuCollegeDeptStatView
ORDER BY department_count DESC, college_name;

-- 3) Stored Procedure: 단과대학명을 입력하면 해당 전남대 공식 학과 목록 반환
DROP PROCEDURE IF EXISTS GetJnuCollegeDepartments;
DELIMITER $$
CREATE PROCEDURE GetJnuCollegeDepartments(IN p_college VARCHAR(50))
BEGIN
  SELECT deptid,
         dname AS department_name,
         college AS college_name,
         tel
  FROM Dept
  WHERE college = p_college
    AND office REGEXP '^[0-9]{3}호$'
  ORDER BY dname;

  SELECT p_college AS college_name,
         COUNT(*) AS department_count
  FROM Dept
  WHERE college = p_college
    AND office REGEXP '^[0-9]{3}호$';
END$$
DELIMITER ;

CALL GetJnuCollegeDepartments('공과대학');

-- 4) Transaction: 공식 공개 학과 전화번호 갱신 작업의 원자성 검증
--    실제 제출 데이터는 ROLLBACK으로 원복한다.
SELECT tel AS official_tel_before
FROM Dept
WHERE dname = '컴퓨터정보통신공학과';

START TRANSACTION;
  UPDATE Dept
  SET tel = '062-000-0000'
  WHERE dname = '컴퓨터정보통신공학과';

  SELECT tel AS tel_in_transaction
  FROM Dept
  WHERE dname = '컴퓨터정보통신공학과';
ROLLBACK;

SELECT tel AS official_tel_after_rollback
FROM Dept
WHERE dname = '컴퓨터정보통신공학과';

-- 5) Index: 공식 공개 학과 데이터의 단과대학별 검색 최적화
SET @drop_idx_sql := (
  SELECT IF(
    COUNT(*) > 0,
    'DROP INDEX idx_dept_college ON Dept',
    'SELECT ''idx_dept_college does not exist'' AS info'
  )
  FROM information_schema.statistics
  WHERE table_schema = DATABASE()
    AND table_name = 'Dept'
    AND index_name = 'idx_dept_college'
);
PREPARE stmt FROM @drop_idx_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

EXPLAIN SELECT * FROM Dept WHERE college = '공과대학';
CREATE INDEX idx_dept_college ON Dept(college);
EXPLAIN SELECT * FROM Dept WHERE college = '공과대학';
SHOW INDEX FROM Dept;


-- =====================================================================
-- END sql\jnu_public_seed.sql
-- =====================================================================


-- =====================================================================
-- BEGIN sql\optimization.sql
-- =====================================================================

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


-- =====================================================================
-- END sql\optimization.sql
-- =====================================================================


-- =====================================================================
-- BEGIN sql\load_large_dummy_csv.sql
-- =====================================================================

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


-- =====================================================================
-- END sql\load_large_dummy_csv.sql
-- =====================================================================


-- =====================================================================
-- FINAL GRADING SUMMARY QUERIES
-- 아래 결과만 확인해도 핵심 구현 여부를 빠르게 검증할 수 있다.
-- =====================================================================

USE bokyung;

SELECT '01_database_created' AS check_item, DATABASE() AS result_value;

SELECT '02_base_tables' AS check_item, COUNT(*) AS result_value
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_type = 'BASE TABLE'
  AND table_name IN ('Dept','Professor','Student','Lecture','Enrollment','Grade');

SELECT '03_official_public_departments' AS check_item, COUNT(*) AS result_value
FROM Dept
WHERE office REGEXP '^[0-9]{3}호$';

SELECT '04_csv_dummy_students' AS check_item, COUNT(*) AS result_value
FROM Student
WHERE stuid BETWEEN 100001 AND 110000
UNION ALL
SELECT '05_csv_dummy_lectures', COUNT(*)
FROM Lecture
WHERE lid BETWEEN 200001 AND 201000
UNION ALL
SELECT '06_csv_dummy_enrollments', COUNT(*)
FROM Enrollment
WHERE enrollid BETWEEN 300001 AND 350000
UNION ALL
SELECT '07_csv_dummy_grades', COUNT(*)
FROM Grade
WHERE gradeid BETWEEN 400001 AND 450000;

SELECT '08_views_created' AS check_item, COUNT(*) AS result_value
FROM information_schema.views
WHERE table_schema = DATABASE()
  AND table_name IN ('StudentGradeView','LectureStatView','JnuPublicDeptView','JnuCollegeDeptStatView');

SELECT '09_procedure_created' AS check_item, COUNT(*) AS result_value
FROM information_schema.routines
WHERE routine_schema = DATABASE()
  AND routine_type = 'PROCEDURE'
  AND routine_name IN ('GetStudentGrade','GetJnuCollegeDepartments');

SELECT *
FROM JnuCollegeDeptStatView
ORDER BY department_count DESC, college_name
LIMIT 10;

CALL GetJnuCollegeDepartments('공과대학');

SHOW INDEX FROM Dept;
SHOW INDEX FROM Student;

EXPLAIN SELECT * FROM Dept WHERE college = '공과대학';
EXPLAIN SELECT * FROM Student WHERE sname = '더미학생05000';



