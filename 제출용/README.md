# 전남대학교 수강신청·성적관리 데이터베이스

> 데이터베이스 시스템(Database Systems) 기말 프로젝트
> 대학의 **수강신청·성적관리** 업무를 대상으로 개념 모델링부터 SQL 구현,
> 인덱스 기반 질의 최적화 실험까지 데이터베이스 설계 전 과정을 수행한 프로젝트입니다.

---

## 1. 프로젝트 개요

| 항목 | 내용 |
| --- | --- |
| 주제 | 수강신청·성적관리 데이터베이스 설계 및 구현 |
| 개체 수 | 6개 (강 개체 4 + 약 개체 2) |
| 정규화 수준 | **BCNF** |
| DBMS | MySQL 8.0 (InnoDB, utf8mb4) |
| 핵심 기능 | View · Stored Procedure · Transaction · Index · 성능 최적화 실험 |

**데이터 모델 요약**
- 강 개체: `Student`(학생), `Dept`(학과), `Professor`(교수), `Lecture`(강의)
- 약 개체: `Enrollment`(수강신청), `Grade`(성적)
- 관계: 학생–학과(N:1), 교수–학과(N:1), 교수–학생 지도(1:N), 교수–강의(1:N),
  학생–강의(M:N → Enrollment로 해소), 수강–성적(1:1)

---

## 2. 폴더 구조

```
dbms/
├── README.md                  ← (현재 파일) 프로젝트 안내·실행 방법
├── docs/                      ← 설계 문서
│   ├── 01_요구사항지시서.md      ← 요구분석, 개체/관계/제약
│   ├── 02_스키마정의서.md        ← 논리 스키마, 테이블/FK 정의
│   ├── 03_개발완료보고서.md      ← 모델링·FD·정규화·성능실험·검증
│   └── erd_description.md       ← ERD(텍스트) 및 변환 규칙
├── sql/                       ← 실행 스크립트
│   ├── schema.sql               ← DB/테이블/제약/샘플데이터/조회테스트
│   └── optimization.sql         ← 뷰/프로시저/트랜잭션/대용량데이터/인덱스실험
└── screenshots/               ← 실행 결과 캡처 보관
```

---

## 3. 실행 환경 (Environment)

| 구분 | 사양 |
| --- | --- |
| DBMS | MySQL 8.0 이상 (Community Server) |
| 클라이언트 | MySQL Workbench 8.0 (또는 mysql CLI) |
| 문자셋 | utf8mb4 (한글 데이터 저장) |
| 엔진 | InnoDB (트랜잭션·외래키 지원) |

> 주의: 한글 식별자/데이터를 사용하므로 접속 문자셋이 `utf8mb4`인지 확인하세요.
> MySQL 8.0.18 이상에서 `EXPLAIN ANALYZE`(실측 실행시간)를 지원합니다.

---

## 4. 설치 및 실행 (Installation & Execution)

### 4.1 MySQL Workbench로 실행하는 경우 (권장)
1. MySQL Workbench를 실행하고 로컬 인스턴스에 접속한다.
2. **File ▸ Open SQL Script**로 `sql/schema.sql`을 연다.
3. 번개(⚡) 버튼으로 **전체 실행**한다. → DB·테이블·샘플데이터 생성 및 조회 테스트 완료.
4. 이어서 `sql/optimization.sql`을 열고 **전체 실행**한다.
   → 뷰·프로시저·트랜잭션 생성, 대용량 데이터(5만 건) 생성, 인덱스 전/후 EXPLAIN 비교.

### 4.2 명령줄(CLI)로 실행하는 경우
```bash
# (Windows PowerShell / cmd 기준, 경로는 환경에 맞게 조정)
mysql -u root -p < sql\schema.sql
mysql -u root -p < sql\optimization.sql
```

### 4.3 실행 순서 (Execution Order)
```
[1] sql/schema.sql        (필수, 먼저 실행)
        ↓
[2] sql/optimization.sql  (schema.sql 실행 후)
```
> `optimization.sql`은 `schema.sql`이 만든 DB(`bokyung`)와 샘플 데이터를 전제로 합니다.
> `optimization.sql`은 상단 정리(cleanup) 구문이 있어 **반복 실행해도 안전**합니다.

---

## 5. SQL 실행 단계별 동작 (SQL Execution Steps)

### 5.1 schema.sql
| 단계 | 동작 |
| --- | --- |
| ① CREATE DATABASE | `bokyung` 생성(utf8mb4) |
| ② CREATE TABLE | Dept→Professor→Student→Lecture→Enrollment→Grade (부모→자식 순) |
| ③ 제약 | PK, FK 7개, CHECK(학년·학점·점수), ENUM, UNIQUE |
| ④ INSERT | 학과6·교수8·학생12·강의8·수강18·성적12 샘플 |
| ⑤ SELECT 테스트 | 학과별 인원, 교수별 강의, 성적표, 강의별 인원, 평균점수 등 6종 |

### 5.2 optimization.sql
| 단계 | 동작 |
| --- | --- |
| PART 1 View | `StudentGradeView`, `LectureStatView` 생성 및 조회 |
| PART 2 Procedure | `GetStudentGrade(p_stuid)` 생성 → `CALL GetStudentGrade(1);` |
| PART 3 Transaction | COMMIT / ROLLBACK / SAVEPOINT 예제 |
| PART 4 대용량 데이터 | 학생 +1만, 강의 +1천, 수강 +5만, 성적 +5만 생성 |
| PART 5 Index 실험 | 인덱스 **생성 전 EXPLAIN** → 인덱스 생성 → **생성 후 EXPLAIN** 비교 |

---

## 6. 주요 검증 포인트

| 기능 | 확인 방법 |
| --- | --- |
| 참조 무결성 | 존재하지 않는 `deptid`로 학생 INSERT 시 FK 오류 발생 |
| 도메인 무결성 | `score=150` INSERT 시 CHECK 위반 발생 |
| 중복 신청 방지 | 동일 `(stuid, lid, semester)` 재신청 시 UNIQUE 위반 |
| 뷰 | `SELECT * FROM StudentGradeView;` |
| 프로시저 | `CALL GetStudentGrade(1);` |
| 인덱스 효과 | PART 5의 EXPLAIN `type` 값이 `ALL → ref`로 변하는지 확인 |

---

## 7. 산출물 문서 안내

- 설계의 배경과 근거: [docs/01_요구사항지시서.md](docs/01_요구사항지시서.md)
- 테이블·FK 정의: [docs/02_스키마정의서.md](docs/02_스키마정의서.md)
- 정규화·성능 실험·검증: [docs/03_개발완료보고서.md](docs/03_개발완료보고서.md)
- ERD: [docs/erd_description.md](docs/erd_description.md)

---

## 8. 참고
- 모든 SQL은 MySQL 8.0 / MySQL Workbench에서 실행 가능하도록 작성되었습니다.
- 예약어 충돌을 피하기 위해 컬럼명은 `stu_year`(학년), `prof_rank`(직급)을 사용합니다.
- 성능 실험의 실제 측정 화면은 `screenshots/` 폴더에 캡처하여 보관합니다.
