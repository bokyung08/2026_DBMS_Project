# DECISIONS.md

# Architecture Decisions

## Decision 1

Use 6 entities.

Reason:

Maximum score coverage.

---

## Decision 2

Use Enrollment as weak entity.

Reason:

Resolve M:N relationship.

---

## Decision 3

Use Grade as weak entity.

Reason:

Represent evaluation separately.

---

## Decision 4

Use surrogate keys.

Reason:

Simpler SQL implementation.

---

## Decision 5

Implement optimization experiment.

Reason:

Professor values database tuning.

---

## Decision 6 (2026-05-31, Phase 2)

MySQL 예약어와 충돌하는 컬럼명을 변경한다: `year` → `stu_year`(학년), `rank` → `prof_rank`(직급).

Reason:

MySQL 8.0에서 `RANK`는 윈도우 함수 예약어, `YEAR`는 데이터 타입/함수명이라 식별자로
사용하면 백틱이 강제되거나 오류 위험이 있다. 백틱 없이도 실행 가능한 깔끔한 스키마를 위해 명시적으로 개명한다.

---

## Decision 7 (2026-05-31, Phase 2)

약 개체(Enrollment, Grade)에 대리키를 부여하되 약 개체의 본질은 제약으로 보존한다.

Reason:

대리키(enrollid, gradeid)로 JOIN/FK 작성을 단순화하면서도,
존재 의존성은 FK NOT NULL로, 부분 키 유일성은 UNIQUE(stuid, lid, semester) /
UNIQUE(enrollid)로 강제하여 식별 관계의 의미를 유지한다.

---

## Decision 8 (2026-05-31, Phase 2)

지도교수(advisor) 관계 R3은 Student.advisor_pid를 NULL 허용으로 둔다.

Reason:

미배정 학생을 허용해야 하므로 부분 참여. 소속 학과(deptid)는 NOT NULL(전체 참여)과 대비된다.

---

## Decision 9 (2026-06-01, 실서버 검증)

대용량 데이터 생성용 숫자 시퀀스는 TEMPORARY 테이블이 아닌 **일반 테이블 `gen_digits`** 로 만든다.

Reason:

MySQL은 하나의 쿼리에서 TEMPORARY 테이블을 2회 이상 참조할 수 없다(ERROR 1137
"Can't reopen table"). 숫자 0~9 테이블을 5중 self-join하여 10만 시퀀스를 만들려면
다중 참조가 필요하므로 일반 테이블로 생성하고 사용 후 DROP한다.

---

## Decision 10 (2026-06-01, 실서버 검증)

롤백 예제는 CHECK(0~100) 범위를 벗어나지 않는 값으로 갱신한 뒤 ROLLBACK한다.

Reason:

`score+50`은 92→142로 CHECK 제약을 위반하여 statement 자체가 실패한다(롤백 시연 불가).
범위 내 '잘못 입력된 값'(10.00)으로 바꾼 뒤 되돌려야 트랜잭션 롤백 효과를 올바로 보인다.

---

# Rule

Whenever a major design decision changes,
append a new decision record.
