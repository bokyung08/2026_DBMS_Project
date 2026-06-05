# ERD 설명서 (Entity-Relationship Diagram Description)

**프로젝트:** 전남대학교 학생 정보·성적관리 데이터베이스
**작성일:** 2026-05-31
**표기법:** Crow's Foot (까마귀 발) 표기법 기준 설명

---

## 1. 개체 관계 다이어그램 (텍스트 ERD)

아래는 6개 개체와 관계를 텍스트로 표현한 ERD이다.
`PK`=기본키, `FK`=외래키, `U`=UNIQUE 제약.

```
                          ┌────────────────────────┐
                          │         Dept           │
                          │────────────────────────│
                          │ PK deptid               │
                          │    dname                │
                          │    college              │
                          │    office               │
                          │    tel                  │
                          └───────────┬─────────────┘
                       (1)            │           (1)
              ┌──────────────────┐    │    ┌──────────────────┐
              │ R1  N:1          │    │    │ R2  N:1          │
              ▼                  │    │    ▼                  │
   ┌────────────────────┐        │    │   ┌────────────────────┐
   │      Student       │        │    │   │     Professor      │
   │────────────────────│        │    │   │────────────────────│
   │ PK stuid           │        │    │   │ PK pid             │
   │    sname           │        │    │   │    pname           │
   │    stu_year        │        │    │   │    prof_rank       │
   │    phone           │        │    │   │    email           │
   │    email           │        │    │   │    office          │
   │ FK deptid ─────────┼────────┘    └───┼─ FK deptid         │
   │ FK advisor_pid ────┼─────────────────┼─◄ (R3 1:N 지도)    │
   └─────────┬──────────┘   R3            └─────────┬──────────┘
             │ (1)                                  │ (1)
             │                                      │ R4 1:N 담당
             │ R5 M:N (Enrollment으로 해소)          ▼
             │                          ┌────────────────────┐
             │                          │      Lecture       │
             │                          │────────────────────│
             │                          │ PK lid             │
             │                          │    lname           │
             │                          │    lnum            │
             │                          │    credit          │
             │                          │    semester        │
             │                          │ FK pid             │
             │                          └─────────┬──────────┘
             │ (N)                                │ (N)
             ▼                                    ▼
        ┌─────────────────────────────────────────────────┐
        │                  Enrollment                      │  ◄ 약 개체
        │──────────────────────────────────────────────────│
        │ PK enrollid                                      │
        │ FK stuid          (→ Student, NOT NULL)          │
        │ FK lid            (→ Lecture, NOT NULL)          │
        │    enroll_date                                   │
        │    status         (수강중/취소/완료)              │
        │    semester                                      │
        │    enroll_type    (정규/재수강)                   │
        │ U  (stuid, lid, semester)  ← 부분키 유일성        │
        └───────────────────────┬──────────────────────────┘
                                │ (1)
                                │ R6  1:1
                                ▼ (1)
        ┌─────────────────────────────────────────────────┐
        │                     Grade                        │  ◄ 약 개체
        │──────────────────────────────────────────────────│
        │ PK gradeid                                       │
        │ FK enrollid       (→ Enrollment, NOT NULL, U)    │
        │    score          (0~100)                        │
        │    grade_letter   (A+, A0, ... , F)              │
        │    evaluation_date                               │
        │    remark                                        │
        └─────────────────────────────────────────────────┘
```

---

## 2. 개체 요약

| 개체 | 유형 | 기본키 | 외래키 |
| --- | --- | --- | --- |
| Dept | 강 개체 | deptid | — |
| Professor | 강 개체 | pid | deptid → Dept |
| Student | 강 개체 | stuid | deptid → Dept, advisor_pid → Professor |
| Lecture | 강 개체 | lid | pid → Professor |
| Enrollment | 약 개체 | enrollid | stuid → Student, lid → Lecture |
| Grade | 약 개체 | gradeid | enrollid → Enrollment |

---

## 3. 관계 상세 설명

| ID | 관계 | 카디널리티 | 참여 제약(좌:우) | 설명 |
| --- | --- | --- | --- | --- |
| R1 | Student → Dept | N:1 | (전체 : 부분) | 모든 학생은 한 학과에 소속 |
| R2 | Professor → Dept | N:1 | (전체 : 부분) | 모든 교수는 한 학과에 소속 |
| R3 | Professor → Student | 1:N | (부분 : 부분) | 교수는 여러 학생을 지도(미배정 허용) |
| R4 | Professor → Lecture | 1:N | (부분 : 전체) | 모든 강의는 담당 교수 보유 |
| R5 | Student ↔ Lecture | M:N | (전체 : 전체)* | Enrollment 교차 개체로 해소 |
| R6 | Enrollment → Grade | 1:1 | (부분 : 전체) | 수강 1건당 성적 1건(부여 전 NULL 가능) |

\* M:N의 참여 제약은 교차 개체 Enrollment를 기준으로 본 것이며, 양측 FK가 모두 NOT NULL이다.

---

## 4. Crow's Foot 표기 해석

- **N:1 (다대일)** — Student 쪽에 까마귀 발(여러 개), Dept 쪽에 단일 막대(하나).
- **1:N (일대다)** — Professor 쪽 단일, Lecture/Student 쪽 까마귀 발.
- **1:1 (일대일)** — Enrollment와 Grade 양쪽 모두 단일 막대, Grade.enrollid에 UNIQUE.
- **전체 참여(total)** — FK 컬럼이 `NOT NULL` (해당 개체의 모든 행이 관계에 참여).
- **부분 참여(partial)** — FK 컬럼이 `NULL` 허용 (예: Student.advisor_pid).

---

## 5. ERD를 관계 스키마로 변환하는 규칙 요약

1. **강 개체** → 각각 독립 테이블. 키 속성 = PK.
2. **N:1 / 1:N 관계** → '다(N)' 쪽 테이블에 '일(1)' 쪽의 PK를 FK로 추가.
   (Student.deptid, Professor.deptid, Lecture.pid, Student.advisor_pid)
3. **M:N 관계** → 교차 테이블 생성, 양쪽 PK를 FK로 포함(Enrollment).
4. **1:1 관계** → 한쪽 FK + UNIQUE (Grade.enrollid).
5. **약 개체** → 소유 개체의 키를 FK(NOT NULL)로 포함하여 식별 관계 표현.

> 변환 결과의 구체적 테이블 정의(컬럼 타입, 제약)는 `02_스키마정의서.md`와 `sql/schema.sql`을 참조한다.

