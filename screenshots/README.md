# screenshots 폴더

MySQL Workbench에서 `schema.sql` → `optimization.sql`을 실행한 결과 화면을 이 폴더에 저장합니다.
파일명은 채점 체크리스트(`final_checklist.md` Section 11)와 일치하도록 아래 권장 이름을 사용하세요.

## 필수 캡처 (기본 점수)

| 파일명 | 캡처 대상 |
| --- | --- |
| `create_database.png` | `CREATE DATABASE bokyung` 실행 화면 |
| `create_table.png` | 6개 테이블 CREATE 및 `SHOW TABLES` 결과 |
| `insert_data.png` | 샘플 데이터 INSERT 완료 화면 |
| `select_result.png` | 기본 조회(SELECT) 결과 (예: 성적표 조인) |

## 추가 점수 캡처 (고급 기능)

| 파일명 | 캡처 대상 |
| --- | --- |
| `view_result.png` | `SELECT * FROM StudentGradeView;` 결과 |
| `procedure_result.png` | `CALL GetStudentGrade(1);` 결과 |
| `transaction_result.png` | 트랜잭션 COMMIT/ROLLBACK/SAVEPOINT 동작 |
| `index_result.png` | `SHOW INDEX FROM Student;` 또는 인덱스 생성 결과 |

## 최적화 실험 캡처 (차별화 요소)

| 파일명 | 캡처 대상 |
| --- | --- |
| `explain_before.png` | 인덱스 생성 **전** EXPLAIN 결과 (type=ALL) |
| `explain_after.png` | 인덱스 생성 **후** EXPLAIN 결과 (type=ref) |
| `performance_before.png` | 인덱스 전 `EXPLAIN ANALYZE`(실행시간) |
| `performance_after.png` | 인덱스 후 `EXPLAIN ANALYZE`(실행시간) |

> 캡처 시 쿼리문과 결과(또는 실행시간 Duration)가 함께 보이도록 하면 채점 근거로 활용하기 좋습니다.
