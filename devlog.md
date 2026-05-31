# DEVLOG.md — 개발 로그

프로젝트: 전남대학교 데이터베이스 설계 (수강신청·성적관리 시스템)

각 Phase 완료 시점마다 작업 내용을 시간순으로 기록한다.

---

## 2026-05-31

### Phase 1 — 프로젝트 구조 생성 (완료)
- `/sql`, `/docs`, `/screenshots` 폴더 생성.
- `screenshots/README.md`에 권장 캡처 목록 정리.
- 산출물 배치 규칙 확정: 루트에는 `README.md`, 문서(`.md`)는 `/docs`, 스크립트(`.sql`)는 `/sql`에 배치.

### Phase 2 — 요구사항지시서 작성 (완료)
- `docs/01_요구사항지시서.md` 작성: 프로젝트 목적, 강/약 개체 식별(6개), 속성 정의,
  관계 카디널리티(R1~R6), 참여 제약(total/partial), 업무 규칙(BR1~BR10) 정리.
- 설계 이슈 발견 및 해결: MySQL 예약어 충돌 → `year`→`stu_year`, `rank`→`prof_rank`로 컬럼명 변경.
- M:N 관계(Student–Lecture)는 교차 개체 Enrollment로 해소, Enrollment–Grade는 1:1(UNIQUE)로 확정.
- decisions.md에 Decision 6~8 추가(예약어 개명, 약 개체 대리키, 지도교수 NULL 허용).

### Phase 3 — 스키마정의서 + ERD 설명 작성 (완료)
- `docs/erd_description.md`: 텍스트 ERD, Crow's Foot 표기 해석, ER→관계 변환 규칙 정리.
- `docs/02_스키마정의서.md`: DB명 `chonnam_univ_db`, 6개 테이블 컬럼/타입/제약 상세,
  FK 매핑 7개(ON DELETE 규칙: RESTRICT/SET NULL/CASCADE), 관계 매핑, 인덱스/무결성 요약.
- 삭제 규칙 설계: 마스터(Dept/Professor) RESTRICT, 지도교수 SET NULL, 약 개체 CASCADE.

### Phase 4 — 개발완료보고서 작성 (완료)
- `docs/03_개발완료보고서.md`: 개념/논리 모델링, 6개 릴레이션 FD 분석, BCNF 정규화 검증,
  비정규 평면 테이블의 이행 종속·이상 현상 → 분해 사례, 무손실/종속성 보존 논증.
- 고급 기능 설계 요약(View/Procedure/Transaction/Index)과 성능 최적화 실험 설계
  (10k/1k/50k/50k 데이터, Q1~Q3, EXPLAIN type ALL→ref, 실행시간 대표값), 검증 표 포함.

### Phase 5 — schema.sql 작성 (완료)
- `sql/schema.sql`: DROP/CREATE DATABASE `chonnam_univ_db`(utf8mb4), 6개 테이블 DDL,
  FK 7개(RESTRICT/SET NULL/CASCADE), CHECK(학년·학점·점수)·ENUM·UNIQUE 제약.
- 샘플 데이터: 학과6·교수8·학생12·강의8·수강18·성적12건. 조회 테스트 6종(조인·집계·서브쿼리).
- 오타 수정: 학생8 email ':isj@'→'isj@'.
- 검증 메모: 로컬 MySQL 8.0.45 서버는 가동 중이나 root 비밀번호 미보유로 실서버 실행 검증은
  보류. Phase 8에서 문법 수기 검증으로 대체.

### Phase 6 — optimization.sql 작성 (완료)
- `sql/optimization.sql`: 뷰 2종(StudentGradeView, LectureStatView), 프로시저 GetStudentGrade
  (성적 상세 + 평균/학점/GPA 요약), 트랜잭션 3종(COMMIT/ROLLBACK/SAVEPOINT).
- 대용량 생성: digits 교차결합 시퀀스로 학생 1만·강의 1천·수강 5만·성적 5만 set-based 삽입.
  재실행 안전(상단 cleanup), FK CASCADE로 연쇄 정리. base 변수로 ID 매핑하여 재실행 견고화.
- 인덱스 실험: FK 자동 인덱스를 피해 sname/lname 대상 선정. idx_student_name/idx_lecture_name
  생성 전후 EXPLAIN + EXPLAIN ANALYZE. 보고서 8장 질의를 SQL과 일치하도록 수정.

### Phase 7 — README.md 작성 (완료)
- 루트 `README.md`: 개요, 폴더 구조, 실행환경, 설치·실행순서(Workbench/CLI),
  SQL 단계별 동작, 검증 포인트, 문서 링크.

### Phase 8 — 전체 검토/검증 (완료)
- schema.sql 정독: FK 생성순서·CHECK·ENUM·DEFAULT(CURRENT_DATE)·샘플 FK 참조 모두 정상.
- optimization.sql 정독 후 수정: (1) PART3 트랜잭션 예제 재실행 시 '2026-2' UNIQUE 충돌 →
  상단 DELETE 정리 추가, (2) 대용량 생성 base 변수·DIV 매핑 유일성 확인.
- 문서 정합화: 02 인덱스 표를 실제/자동 인덱스 구분으로 정정, 01에 개체별 속성 5개 표 추가,
  screenshots/README를 채점 체크리스트 파일명과 일치.
- 채점 루브릭(final_checklist.md) 기반 `docs/04_자체검토보고서.md` 작성 → 예상 20/20
  (단, 결과 스크린샷은 사용자 실행 필요).
- 일관성 검증: SQL 내 `rank`/`year`는 주석에만 존재, 실제 컬럼은 prof_rank/stu_year로 통일 확인.
- 미해결: 로컬 MySQL root 비밀번호 미보유로 실서버 실행 검증은 사용자 몫(문법은 수기 검증 완료).

## 프로젝트 완료 (2026-05-31)
전 산출물(README, 01~04 문서, erd_description, schema.sql, optimization.sql) 생성 및 검증 완료.

## 2026-06-01 — 실서버 실행 검증 (MySQL 8.0.45)

사용자가 root 비밀번호(0828)를 제공하여 실제 MySQL 서버에서 end-to-end 실행 검증 수행.

### 실행 중 발견·수정한 실제 버그 2건
1. **CHECK 위반 (PART 3.2 롤백 예제)**: `score = score + 50` → 92+50=142가 CHECK(0~100)
   위반으로 ROLLBACK 시연 전에 statement가 실패. → `score = 10.00`(범위 내 잘못된 값)으로 수정.
2. **TEMPORARY 테이블 재참조 오류 (ERROR 1137, PART 4.1)**: digits 임시테이블을 5중 self-join →
   "Can't reopen table". MySQL은 TEMP 테이블 1쿼리 다중참조 불가. → `gen_digits`를 일반 테이블로
   변경(끝에서 DROP)하여 해결.

### 최종 실행 결과 (둘 다 EXIT=0, 오류 없음)
- 데이터 규모: Student 10,012 / Lecture 1,008 / Enrollment 50,019 / Grade 50,014.
- 트랜잭션: ROLLBACK 후 score 92.00 복구, SAVEPOINT 부분롤백('1차 검토' 유지) 정상.
- 인덱스 실험(EXPLAIN ANALYZE 실측): Q1 sname 검색 type ALL→ref,
  실행시간 2.72ms→0.011ms(약 247배), cost 994→0.35. Q2/Q3도 ALL→ref 확인.
- 보고서 §8.5/§8.7을 대표값 → **실측값**으로 갱신.

## 2026-06-01 — 재검토 및 이해 가이드 추가
- 라이브 DB로 무결성(고아행·1:1·범위 0건)·제약 거부(FK1452/CHECK3819/UNIQUE1062) 실증.
- FK 7개·삭제규칙이 docs 02 §4와 완전 일치 확인. 정규화 BCNF(⊃3NF) 재확인. 예상 20/20.
- `screenshots/실행결과_텍스트증거.md` 추가(실측 출력 텍스트 증거).
- `docs/05_프로젝트_이해가이드.md` 추가: 쉬운 해설 + 예상 질문 12개 모범답변 + 시연 순서 +
  핵심 숫자 요약(발표·구두평가 대비용). README 문서 목록에 링크 추가.

## 2026-06-01 — 교수님 실제 채점 양식 대조 및 보완
사용자가 교수님 요구사항지시서·개발완료보고서 실제 템플릿/채점표 제공 → 정밀 대조.
- (보완1) 01 문서 관계표에 **관계명**(belong/study/tutor/manage/work_dept/evaluate) 컬럼 추가.
- (보완2) 03 문서 §2.4에 **속성별 기본키·중복가능여부 표**(6개 개체) 추가 → 개발보고서 요소1 충족.
- (보완3) 03 문서 §3에 **관계별 FK 삽입 설명** 추가 → 요소2 충족.
- (확인) 속성 수: 각 개체 FK 삽입 이전 5개로 '최소3~최대5' 충족. 개체 6개(최대) 충족.
- (사용자 과제로 식별) ⚠️ DB 이름을 `chonnam_univ_db` → **본인 실명**으로 변경 필요(요구사항 명시),
  문서 표지 학번/이름 기입, 실행화면 캡처. → `최종_제출전_체크리스트.md`로 저장.

### DB 이름 변경 완료 (사용자 이름: bokyung)
- `chonnam_univ_db` → 잠시 `보경`(한글, 백틱) → 최종 **`bokyung`(영문)** 으로 변경 확정.
  영문 식별자라 백틱 불필요(`CREATE DATABASE bokyung`). schema.sql, optimization.sql + 관련 문서 전체 반영.
  MySQL 8.0.45 재실행 EXIT=0, 데이터 정상 적재(Student 10,012 / Enrollment 50,019).
  기존 chonnam_univ_db / 보경 DB는 정리.
