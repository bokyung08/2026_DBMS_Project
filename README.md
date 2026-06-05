# Chonnam University Student Grade Management DB

전남대학교의 학생 정보, 수강신청, 강의, 성적을 관리하는 MySQL 기반 학사행정 데이터베이스 프로젝트입니다. 공식 공개 학과 정보와 개인정보가 없는 대용량 더미 CSV를 함께 사용해 스키마 설계, 무결성, 고급 SQL 기능, 인덱스 최적화를 검증합니다.

## 핵심 기능

| 구분 | 내용 |
| --- | --- |
| 데이터 모델 | `Dept`, `Professor`, `Student`, `Lecture`, `Enrollment`, `Grade` |
| 공식 공개 데이터 | 전남대학교 공개 학과명, 단과대학명, 전화번호 114건 |
| 대용량 데이터 | 학생 10,000행, 강의 1,000행, 수강 50,000행, 성적 50,000행 |
| 고급 SQL | View, Stored Procedure, Transaction, Index, EXPLAIN |
| 실행 패키지 | `submission/` 폴더에서 한 번에 실행 가능 |

## 폴더 구조

```text
dbms/
  README.md
  docs/
    01_요구사항지시서.md
    02_스키마정의서.md
    03_개발완료보고서.md
    erd_description.md
  sql/
  tools/
  data/
  diagrams/
  submission/
    README.md
    sql/
    tools/
    data/
```

`submission/`은 실행 확인용 패키지입니다. 보고서 파일은 별도로 관리하고, 이 폴더에는 코드·데이터·README만 둡니다.

## 빠른 실행

프로젝트 루트에서 실행합니다.

```powershell
cd submission
mysql --local-infile=1 -u root -p < sql/run_all_for_grading.sql
```

이미 `submission` 폴더 안에 있다면 아래 명령만 실행합니다.

```powershell
mysql --local-infile=1 -u root -p < sql/run_all_for_grading.sql
```

실행이 끝나면 `bokyung` 데이터베이스가 생성되고, 기본 테이블·샘플 데이터·공식 학과 데이터·CSV 더미 데이터·고급 SQL 객체가 모두 반영됩니다.

## 주요 SQL

| 파일 | 목적 |
| --- | --- |
| `sql/schema.sql` | DB, 테이블, 기본 샘플 데이터 생성 |
| `sql/jnu_public_seed.sql` | 공식 공개 학과 데이터와 관련 View/Procedure/Index 생성 |
| `sql/optimization.sql` | SQL 내부 대용량 데이터와 인덱스 성능 실험 |
| `sql/load_large_dummy_csv.sql` | CSV 대용량 데이터 적재 |
| `sql/run_all_for_grading.sql` | 전체 실행 통합 스크립트 |

## 도구

| 파일 | 목적 |
| --- | --- |
| `tools/generate_large_dummy_csv.py` | 대용량 더미 CSV 재생성 |
| `tools/crawl_jnu_public_academic_data.py` | 전남대학교 공개 학과 데이터 재수집 |
| `tools/draw_schema_diagrams.py` | ERD와 관계 스키마 이미지 생성 |

## 검증값

`run_all_for_grading.sql` 마지막 검증 쿼리의 기대값입니다.

| 항목 | 기대값 |
| --- | --- |
| Database | `bokyung` |
| Base tables | `6` |
| Official public departments | `114` |
| CSV students | `10000` |
| CSV lectures | `1000` |
| CSV enrollments | `50000` |
| CSV grades | `50000` |
| Views | `4` |
| Procedures | `2` |

## 실행 조건

- MySQL 8.0 이상 권장
- `LOAD DATA LOCAL INFILE` 사용 가능해야 함
- CSV 경로는 실행 위치 기준 상대경로이므로 `submission` 폴더에서 실행

권한 오류가 나면 MySQL에서 아래를 한 번 실행합니다.

```sql
SET GLOBAL local_infile = 1;
```
