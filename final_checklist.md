# SELF_REVIEW.md

# Chonnam University DB Final Audit Checklist

목표

교수님 채점 기준으로 프로젝트를 스스로 검증하여 20점 만점 수준인지 확인한다.

---

# Section 1

요구사항 지시서 (10점)

## 요소 1

프로젝트 목적 작성

점검

* [ ] 프로젝트 목적 존재
* [ ] 데이터베이스 목적 설명
* [ ] 관리 목적 설명

배점

2점

---

## 요소 2

개체와 속성 작성

점검

* [ ] Student 작성
* [ ] Dept 작성
* [ ] Professor 작성
* [ ] Lecture 작성
* [ ] Enrollment 작성
* [ ] Grade 작성

배점

2점

---

## 요소 3

강한 개체 / 약한 개체

점검

* [ ] 강한 개체 설명
* [ ] 약한 개체 설명
* [ ] 약한 개체 의존성 설명

배점

2점

---

## 요소 4

관계 설계

점검

* [ ] 관계명 존재
* [ ] 관계대응수 존재
* [ ] 최소참여 존재
* [ ] ERD 반영 완료

배점

2점

---

## 요소 5

속성 개수 제한

점검

* [ ] 개체 수 6개 이하
* [ ] 각 개체 5개 이하 속성
* [ ] 각 개체 3개 이상 속성

배점

2점

---

# Section 2

개념적 모델링 (1점)

점검

* [ ] 모든 PK 설명
* [ ] 중복 가능 여부 설명
* [ ] 속성 설명 존재

배점

1점

---

# Section 3

논리적 모델링 (1점)

점검

* [ ] FK 설명
* [ ] 관계 매핑 설명
* [ ] 참조 무결성 설명

배점

1점

---

# Section 4

함수 종속성 및 정규화 (1점)

점검

* [ ] Student FD 작성

* [ ] Dept FD 작성

* [ ] Professor FD 작성

* [ ] Lecture FD 작성

* [ ] Enrollment FD 작성

* [ ] Grade FD 작성

* [ ] 1NF 설명

* [ ] 2NF 설명

* [ ] 3NF 설명

배점

1점

---

# Section 5

SQL 구현 (2점)

## CREATE

점검

* [ ] CREATE DATABASE 정상 실행
* [ ] CREATE TABLE 정상 실행

배점

1점

---

## INSERT

점검

* [ ] INSERT 정상 실행
* [ ] FK 오류 없음

배점

1점

---

# Section 6

검증 (1점)

점검

* [ ] SHOW TABLES 실행
* [ ] SELECT * 실행
* [ ] 모든 테이블 데이터 확인

배점

1점

---

# Section 7

ERD

점검

* [ ] PK 표시
* [ ] 관계명 표시
* [ ] Crow's Foot 사용
* [ ] 최소참여 표시

배점

필수

---

# Section 8

README

점검

* [ ] 설치 방법
* [ ] 실행 순서
* [ ] 프로젝트 구조

배점

필수

---

# Section 9

추가 점수

## View

점검

* [ ] StudentGradeView 생성
* [ ] 실행 결과 캡처

점수

+1

---

## Stored Procedure

점검

* [ ] GetStudentGrade 생성
* [ ] CALL 테스트 완료

점수

+1

---

## Transaction

점검

* [ ] START TRANSACTION
* [ ] COMMIT
* [ ] ROLLBACK
* [ ] 캡처 완료

점수

+1

---

## Index

점검

* [ ] idx_student_name 생성
* [ ] idx_lecture_name 생성

점수

+1

---

# Section 10

최적화 실험

교수님 차별화 요소

---

## 대량 데이터

점검

* [ ] Student 10000건
* [ ] Enrollment 50000건
* [ ] Grade 50000건

---

## 성능 측정

점검

* [ ] 인덱스 전 실행시간 측정
* [ ] 인덱스 후 실행시간 측정

---

## EXPLAIN

점검

* [ ] EXPLAIN 실행
* [ ] 실행 계획 저장

---

## 분석

점검

* [ ] Query Cost 비교
* [ ] Rows Examined 비교
* [ ] Full Table Scan 여부 분석

---

# Section 11

스크린샷 검증

필수

* [ ] create_database.png
* [ ] create_table.png
* [ ] insert_data.png
* [ ] select_result.png

---

추가

* [ ] view_result.png
* [ ] procedure_result.png
* [ ] transaction_result.png
* [ ] index_result.png

---

최적화

* [ ] performance_before.png
* [ ] performance_after.png
* [ ] explain_before.png
* [ ] explain_after.png

---

# Final Evaluation

## 기본 점수

요구사항 지시서

__/10

개념적 모델링

__/1

논리적 모델링

__/1

정규화

__/1

CREATE

__/1

INSERT

__/1

SELECT

__/1

소계

__/16

---

## 추가 점수

View

__/1

Procedure

__/1

Transaction

__/1

Index

__/1

소계

__/4

---

## 총점

__/20

---

# Claude Audit Prompt

프로젝트 전체를 검토하라.

SELF_REVIEW.md를 기준으로 누락 항목을 찾고 수정하라.

SQL 실행 오류 가능성을 검토하라.

ERD와 논리 모델링의 일관성을 검토하라.

정규화가 3NF를 만족하는지 검토하라.

예상 점수를 산출하라.

20점 미만이라면 부족한 부분을 자동 수정하라.
