# 전남대학교 학생 정보·성적관리 DB 제출본

먼저 이것만 실행하면 됩니다.

```powershell
# 프로젝트 루트에서 실행하는 경우
cd submission
mysql --local-infile=1 -u root -p < sql/run_all_for_grading.sql
```

터미널을 이미 `submission` 폴더에서 열었다면 두 번째 줄만 실행하면 됩니다.

`sql/run_all_for_grading.sql` 한 번 실행으로 데이터베이스 생성, 테이블 생성, 기본 데이터 입력, 전남대학교 공식 공개 학과 데이터 반영, View/Procedure/Transaction/Index, 대용량 SQL 데이터 실험, CSV 적재 실험, 최종 검증 조회까지 모두 진행됩니다.

## 1. 실행 전 조건

| 항목 | 내용 |
| --- | --- |
| DBMS | MySQL 8.0 이상 권장 |
| 실행 위치 | `submission` 폴더 안 |
| CSV 옵션 | `mysql --local-infile=1` 옵션 필요 |
| 문자셋 | UTF-8, `utf8mb4` |

`LOAD DATA LOCAL INFILE`이 막히면 MySQL에서 아래를 한 번 실행한 뒤 다시 실행합니다.

```sql
SET GLOBAL local_infile = 1;
```

## 2. 프로젝트 주제

```text
전남대학교의 학생 정보와 성적을 관리하는 학사행정 DB
```

관리 대상은 학생, 학과, 교수, 강의, 수강신청, 성적입니다. 학과 정보는 전남대학교 공식 대표 홈페이지의 공개 학과 정보를 사용했고, 학생·수강·성적 대용량 데이터는 개인정보가 없는 임의 생성 CSV를 사용했습니다.

## 3. 폴더 구조

```text
submission/
  README.md
  sql/
    run_all_for_grading.sql
    schema.sql
    jnu_public_seed.sql
    optimization.sql
    load_large_dummy_csv.sql
  tools/
    generate_large_dummy_csv.py
    crawl_jnu_public_academic_data.py
    draw_schema_diagrams.py
  data/
    jnu_public_departments.csv
    large_csv/
```

## 4. SQL 파일 목적과 실행 방법

| 파일 | 목적 | 실행 방법 |
| --- | --- | --- |
| `sql/run_all_for_grading.sql` | 전체 생성·적재·검증 통합 실행 | `mysql --local-infile=1 -u root -p < sql/run_all_for_grading.sql` |
| `sql/schema.sql` | `bokyung` DB, 6개 테이블, 기본 샘플 데이터 생성 | `mysql -u root -p < sql/schema.sql` |
| `sql/jnu_public_seed.sql` | 전남대학교 공식 공개 학과 데이터 114건 반영, 관련 View/Procedure/Transaction/Index 실행 | `mysql -u root -p bokyung < sql/jnu_public_seed.sql` |
| `sql/optimization.sql` | SQL 내부 생성 대용량 데이터와 인덱스 전후 성능 실험 | `mysql -u root -p bokyung < sql/optimization.sql` |
| `sql/load_large_dummy_csv.sql` | CSV 학생 10,000행, 강의 1,000행, 수강 50,000행, 성적 50,000행 적재 및 검색 성능 실험 | `mysql --local-infile=1 -u root -p bokyung < sql/load_large_dummy_csv.sql` |

개별 파일 실행은 확인용입니다. 제출 확인은 `sql/run_all_for_grading.sql` 하나만 실행하면 됩니다.

## 5. 도구 파일 목적과 실행 방법

| 파일 | 목적 | 실행 방법 |
| --- | --- | --- |
| `tools/generate_large_dummy_csv.py` | `data/large_csv/`의 대용량 더미 CSV 재생성 | `python tools/generate_large_dummy_csv.py` |
| `tools/crawl_jnu_public_academic_data.py` | 전남대학교 공식 공개 학과 목록을 다시 수집하여 CSV와 SQL seed 재생성 | `python tools/crawl_jnu_public_academic_data.py` |
| `tools/draw_schema_diagrams.py` | ERD, 관계 스키마, 최소 관계대응수 다이어그램 재생성 | `python tools/draw_schema_diagrams.py` |

Python 도구는 데이터 또는 다이어그램을 다시 만들 때만 실행합니다. 기본 검증에는 SQL 통합 실행만 필요합니다.

## 6. 실행 후 확인값

`run_all_for_grading.sql` 마지막에 아래 검증 결과가 출력됩니다.

| check_item | 기대값 |
| --- | --- |
| `01_database_created` | `bokyung` |
| `02_base_tables` | `6` |
| `03_official_public_departments` | `114` |
| `04_csv_dummy_students` | `10000` |
| `05_csv_dummy_lectures` | `1000` |
| `06_csv_dummy_enrollments` | `50000` |
| `07_csv_dummy_grades` | `50000` |
| `08_views_created` | `4` |
| `09_procedure_created` | `2` |

## 7. 고급 기능 반영 내용

| 기능 | 구현 내용 |
| --- | --- |
| 공식 공개 데이터 | 전남대학교 공개 학과명, 단과대학명, 전화번호 114건을 `Dept`에 반영 |
| 대용량 CSV 적재 | 개인정보 없는 학생·강의·수강·성적 더미 CSV 적재 |
| View | 학생 성적표, 강의별 통계, 공식 학과 목록, 단과대학별 학과 수 |
| Stored Procedure | 학생별 성적 조회, 단과대학별 공식 학과 조회 |
| Transaction | 공식 학과 전화번호 변경 후 `ROLLBACK`으로 원자성 검증 |
| Index/EXPLAIN | 학과 검색과 학생 이름 검색의 인덱스 전후 실행계획 비교 |

## 8. 오류 대처

| 증상 | 처리 |
| --- | --- |
| CSV 파일을 찾지 못함 | 반드시 `submission` 폴더에서 실행 |
| `LOAD DATA LOCAL INFILE` 차단 | `--local-infile=1` 옵션 사용, 필요 시 `SET GLOBAL local_infile = 1;` 실행 |
| `EXPLAIN ANALYZE` 오류 | MySQL 8.0.18 이상 사용 권장 |
| 이미 같은 DB가 있음 | 통합 SQL이 `DROP DATABASE IF EXISTS bokyung` 후 새로 생성 |
