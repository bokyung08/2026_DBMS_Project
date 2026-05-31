# PROJECT_STATE.md

# 현재 프로젝트 상태

## 프로젝트
전남대학교 데이터베이스 설계 — 수강신청·성적관리 시스템 (Database Systems Final Project)

기준일: 2026-05-31

---

## 전체 진행률

* [x] Phase 1 — 프로젝트 폴더 구조 생성
* [x] Phase 2 — 요구사항지시서 (01)
* [x] Phase 3 — 스키마정의서 (02) + ERD 설명
* [x] Phase 4 — 개발완료보고서 (03)
* [x] Phase 5 — schema.sql
* [x] Phase 6 — optimization.sql
* [x] Phase 7 — README.md
* [x] Phase 8 — 전체 검토/검증 (완료)

---

## 산출물 배치 규칙
* 루트: `README.md`
* `/docs`: `01_요구사항지시서.md`, `02_스키마정의서.md`, `03_개발완료보고서.md`, `erd_description.md`
* `/sql`: `schema.sql`, `optimization.sql`
* `/screenshots`: 실행 결과 캡처

---

## 현재 작업
전체 완료 + 실서버 실행 검증 완료(MySQL 8.0.45). 남은 작업은 사용자가 MySQL Workbench에서
결과 화면을 screenshots/ 폴더에 캡처하는 것뿐이다(DB bokyung는 이미 생성·적재됨).

## 직전 완료 작업
실서버 end-to-end 실행 검증. 실제 버그 2건(CHECK 위반, TEMP 테이블 재참조) 수정,
보고서 성능수치를 실측값(2.72ms→0.011ms, 약 247배)으로 갱신.

## 다음 작업
(개발 완료) — 채점용 스크린샷 캡처는 사용자 환경에서 진행.

---

## 이슈
없음

---

## 비고
주요 설계 결정은 `decisions.md`에 누적 기록한다.
