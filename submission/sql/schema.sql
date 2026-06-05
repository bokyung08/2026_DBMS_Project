DROP DATABASE IF EXISTS bokyung;
CREATE DATABASE bokyung
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;
USE bokyung;

DROP TABLE IF EXISTS Grade;
DROP TABLE IF EXISTS Enrollment;
DROP TABLE IF EXISTS Lecture;
DROP TABLE IF EXISTS Student;
DROP TABLE IF EXISTS Professor;
DROP TABLE IF EXISTS Dept;

CREATE TABLE Dept (
  deptid   INT AUTO_INCREMENT PRIMARY KEY,
  dname    VARCHAR(50) NOT NULL,
  college  VARCHAR(50) NOT NULL,
  office   VARCHAR(50),
  tel      VARCHAR(20),
  CONSTRAINT uq_dept_name UNIQUE (dname)
) ENGINE=InnoDB;

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

CREATE TABLE Student (
  stuid        INT AUTO_INCREMENT PRIMARY KEY,
  sname        VARCHAR(30) NOT NULL,
  stu_year     TINYINT NOT NULL,
  phone        VARCHAR(20),
  email        VARCHAR(100),
  deptid       INT NOT NULL,
  advisor_pid  INT,
  CONSTRAINT uq_stu_email UNIQUE (email),
  CONSTRAINT chk_stu_year CHECK (stu_year BETWEEN 1 AND 4),
  CONSTRAINT fk_stu_dept FOREIGN KEY (deptid) REFERENCES Dept(deptid)
      ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_stu_advisor FOREIGN KEY (advisor_pid) REFERENCES Professor(pid)
      ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

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
  CONSTRAINT uq_enroll UNIQUE (stuid, lid, semester)
) ENGINE=InnoDB;

CREATE TABLE Grade (
  gradeid          INT AUTO_INCREMENT PRIMARY KEY,
  enrollid         INT NOT NULL,
  score            DECIMAL(5,2) NOT NULL,
  grade_letter     VARCHAR(2),
  evaluation_date  DATE,
  remark           VARCHAR(100),
  CONSTRAINT uq_grade_enroll UNIQUE (enrollid),
  CONSTRAINT chk_grade_score CHECK (score >= 0 AND score <= 100),
  CONSTRAINT fk_grade_enr FOREIGN KEY (enrollid) REFERENCES Enrollment(enrollid)
      ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

INSERT INTO Dept (deptid, dname, college, office, tel) VALUES
 (1, '컴퓨터공학과',   '공과대학',     '공대1호관 301', '062-530-1111'),
 (2, '전자공학과',     '공과대학',     '공대2호관 210', '062-530-2222'),
 (3, '경영학과',       '경영대학',     '경영관 105',    '062-530-3333'),
 (4, '수학과',         '자연과학대학', '자연관 402',    '062-530-4444'),
 (5, '화학공학과',     '공과대학',     '공대3호관 115', '062-530-5555'),
 (6, '영어영문학과',   '인문대학',     '인문관 220',    '062-530-6666');

INSERT INTO Professor (pid, pname, prof_rank, email, office, deptid) VALUES
 (1, '김민준', '정교수',   'kmj@jnu.ac.kr', '공대1호관 501', 1),
 (2, '이서연', '부교수',   'lsy@jnu.ac.kr', '공대1호관 502', 1),
 (3, '박지호', '조교수',   'pjh@jnu.ac.kr', '공대2호관 305', 2),
 (4, '최유진', '정교수',   'cyj@jnu.ac.kr', '경영관 210',    3),
 (5, '정우성', '부교수',   'jws@jnu.ac.kr', '자연관 410',    4),
 (6, '강하늘', '조교수',   'khn@jnu.ac.kr', '공대3호관 220', 5),
 (7, '조정석', '전임강사', 'jjs@jnu.ac.kr', '인문관 305',    6),
 (8, '윤아름', '정교수',   'yar@jnu.ac.kr', '공대1호관 503', 1);

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

INSERT INTO Lecture (lid, lname, lnum, credit, semester, pid) VALUES
 (1, '데이터베이스',     'CSE301', 3, '2026-1', 1),
 (2, '운영체제',         'CSE302', 3, '2026-1', 2),
 (3, '자료구조',         'CSE201', 3, '2026-1', 1),
 (4, '디지털논리회로',   'EEE201', 3, '2026-1', 3),
 (5, '경영학원론',       'BUS101', 3, '2026-1', 4),
 (6, '선형대수',         'MAT201', 3, '2026-1', 5),
 (7, '화학공학개론',     'CHE101', 3, '2026-1', 6),
 (8, '영미문학',         'ENG201', 3, '2026-1', 7);

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

SELECT d.dname AS 학과, COUNT(s.stuid) AS 학생수
FROM Dept d
LEFT JOIN Student s ON s.deptid = d.deptid
GROUP BY d.deptid, d.dname
ORDER BY 학생수 DESC;

SELECT p.pname AS 교수, p.prof_rank AS 직급, l.lname AS 강의명, l.credit AS 학점
FROM Professor p
JOIN Lecture l ON l.pid = p.pid
ORDER BY p.pname;

SELECT s.sname AS 학생, l.lname AS 강의, g.score AS 점수, g.grade_letter AS 등급
FROM Student s
JOIN Enrollment e ON e.stuid = s.stuid
JOIN Lecture l    ON l.lid = e.lid
JOIN Grade g      ON g.enrollid = e.enrollid
ORDER BY s.sname, l.lname;

SELECT l.lname AS 강의, COUNT(*) AS 수강인원
FROM Lecture l
JOIN Enrollment e ON e.lid = l.lid AND e.status <> '취소'
GROUP BY l.lid, l.lname
ORDER BY 수강인원 DESC;

SELECT sub.sname AS 학생, ROUND(AVG(sub.score), 2) AS 평균점수
FROM (
  SELECT s.stuid, s.sname, g.score
  FROM Student s
  JOIN Enrollment e ON e.stuid = s.stuid
  JOIN Grade g      ON g.enrollid = e.enrollid
) AS sub
GROUP BY sub.stuid, sub.sname
ORDER BY 평균점수 DESC;

SELECT stuid, sname FROM Student WHERE advisor_pid IS NULL;
