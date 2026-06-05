"""
Crawl public Chonnam National University academic-unit pages and generate SQL.

Only public department/college names from the official representative site are
used. Student names, student IDs, enrollment records, and grades are never
crawled because they are personal or non-public academic records.
"""

from __future__ import annotations

import csv
import re
import sys
from pathlib import Path
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup


BASE_URL = "https://www.jnu.ac.kr"
INDEX_URL = "https://www.jnu.ac.kr/MainUniversity/University/Uni_Total"
OUT_DIR = Path(__file__).resolve().parents[1] / "data"
SQL_OUT = Path(__file__).resolve().parents[1] / "sql" / "jnu_public_seed.sql"
CSV_OUT = OUT_DIR / "jnu_public_departments.csv"


def clean(value: str) -> str:
    return " ".join(value.split()).strip()


def sql_quote(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "''") + "'"


def extract_department_links() -> list[tuple[str, str]]:
    response = requests.get(INDEX_URL, timeout=20)
    response.raise_for_status()
    response.encoding = response.apparent_encoding
    soup = BeautifulSoup(response.text, "html.parser")

    links: list[tuple[str, str]] = []
    seen: set[str] = set()
    for anchor in soup.find_all("a", href=True):
        href = anchor["href"]
        name = clean(anchor.get_text(" ", strip=True))
        if not name or "/MainUniversity/University/Uni_" not in href:
            continue
        url = urljoin(BASE_URL, href)
        if url in seen:
            continue
        seen.add(url)
        links.append((name, url))
    return links


def parse_department_page(url: str) -> dict[str, str] | None:
    response = requests.get(url, timeout=20)
    response.raise_for_status()
    response.encoding = response.apparent_encoding
    soup = BeautifulSoup(response.text, "html.parser")
    if not soup.title:
        return None

    title = clean(soup.title.get_text(" ", strip=True))
    parts = [clean(part) for part in title.split("<")]
    # Department pages have the shape:
    # "컴퓨터정보통신공학과 < 공과대학 < 대학·학부 < ..."
    if len(parts) < 3 or parts[2] != "대학·학부":
        return None

    department = parts[0]
    college = parts[1]
    if not department or not college or department == college:
        return None

    page_text = clean(soup.get_text(" ", strip=True))
    tel_match = re.search(r"(0\d{1,2}-\d{3,4}-\d{4})", page_text)
    tel = tel_match.group(1) if tel_match else None

    return {
        "department": department,
        "college": college,
        "office": "",
        "tel": tel or "",
        "source_url": url,
    }


def crawl() -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    seen_departments: set[str] = set()
    for _, url in extract_department_links():
        try:
            parsed = parse_department_page(url)
        except requests.RequestException as exc:
            print(f"skip_timeout_or_request_error={url} ({exc})", file=sys.stderr)
            continue
        if not parsed:
            continue
        if parsed["department"] in seen_departments:
            continue
        seen_departments.add(parsed["department"])
        rows.append(parsed)
    rows.sort(key=lambda row: (row["college"], row["department"]))
    for index, row in enumerate(rows, start=101):
        row["office"] = f"{index}호"
    return rows


def write_csv(rows: list[dict[str, str]]) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    with CSV_OUT.open("w", encoding="utf-8-sig", newline="") as file:
        writer = csv.DictWriter(
            file,
            fieldnames=["department", "college", "office", "tel", "source_url"],
        )
        writer.writeheader()
        writer.writerows(rows)


def write_sql(rows: list[dict[str, str]]) -> None:
    values = []
    for row in rows:
        values.append(
            "  ({}, {}, {}, {})".format(
                sql_quote(row["department"]),
                sql_quote(row["college"]),
                sql_quote(row["office"]),
                sql_quote(row["tel"] or None if False else row["tel"]),
            )
        )

    SQL_OUT.parent.mkdir(parents=True, exist_ok=True)
    SQL_OUT.write_text(
        """-- =====================================================================
-- jnu_public_seed.sql
-- 전남대학교 공식 대표 홈페이지 공개 학과 정보를 Dept에 반영한다.
-- 출처: https://www.jnu.ac.kr/MainUniversity/University/Uni_Total
--
-- 주의:
--   - 학과명/단과대학명 같은 공개 정보만 사용한다.
--   - 학생 개인정보, 실제 학번, 실제 성적, 포털 로그인 정보는 사용하지 않는다.
--   - schema.sql 실행 후 선택적으로 실행한다.
-- =====================================================================

USE bokyung;

INSERT INTO Dept (dname, college, office, tel) VALUES
{}
ON DUPLICATE KEY UPDATE
  college = VALUES(college),
  office = VALUES(office),
  tel = VALUES(tel);

-- 공식 공개 학과 데이터 반영 확인
SELECT college AS 단과대학, COUNT(*) AS 학과수
FROM Dept
WHERE office REGEXP '^[0-9]{{3}}호$'
GROUP BY college
ORDER BY 학과수 DESC, college;

-- =====================================================================
-- 공식 공개 학과 데이터 기반 고급 기능 구현
-- =====================================================================

-- 1) View: 전남대학교 공식 공개 학과 목록 조회
CREATE OR REPLACE VIEW JnuPublicDeptView AS
SELECT deptid,
       dname   AS department_name,
       college AS college_name,
       tel
FROM Dept
WHERE office REGEXP '^[0-9]{{3}}호$';

-- 2) View: 단과대학별 공식 공개 학과 수 집계
CREATE OR REPLACE VIEW JnuCollegeDeptStatView AS
SELECT college AS college_name,
       COUNT(*) AS department_count
FROM Dept
WHERE office REGEXP '^[0-9]{{3}}호$'
GROUP BY college;

SELECT * FROM JnuPublicDeptView
WHERE college_name = '공과대학'
ORDER BY department_name;

SELECT * FROM JnuCollegeDeptStatView
ORDER BY department_count DESC, college_name;

-- 3) Stored Procedure: 단과대학명을 입력하면 해당 전남대 공식 학과 목록 반환
DROP PROCEDURE IF EXISTS GetJnuCollegeDepartments;
DELIMITER $$
CREATE PROCEDURE GetJnuCollegeDepartments(IN p_college VARCHAR(50))
BEGIN
  SELECT deptid,
         dname AS department_name,
         college AS college_name,
         tel
  FROM Dept
  WHERE college = p_college
    AND office REGEXP '^[0-9]{{3}}호$'
  ORDER BY dname;

  SELECT p_college AS college_name,
         COUNT(*) AS department_count
  FROM Dept
  WHERE college = p_college
    AND office REGEXP '^[0-9]{{3}}호$';
END$$
DELIMITER ;

CALL GetJnuCollegeDepartments('공과대학');

-- 4) Transaction: 공식 공개 학과 전화번호 갱신 작업의 원자성 검증
--    실제 제출 데이터는 ROLLBACK으로 원복한다.
SELECT tel AS official_tel_before
FROM Dept
WHERE dname = '컴퓨터정보통신공학과';

START TRANSACTION;
  UPDATE Dept
  SET tel = '062-000-0000'
  WHERE dname = '컴퓨터정보통신공학과';

  SELECT tel AS tel_in_transaction
  FROM Dept
  WHERE dname = '컴퓨터정보통신공학과';
ROLLBACK;

SELECT tel AS official_tel_after_rollback
FROM Dept
WHERE dname = '컴퓨터정보통신공학과';

-- 5) Index: 공식 공개 학과 데이터의 단과대학별 검색 최적화
SET @drop_idx_sql := (
  SELECT IF(
    COUNT(*) > 0,
    'DROP INDEX idx_dept_college ON Dept',
    'SELECT ''idx_dept_college does not exist'' AS info'
  )
  FROM information_schema.statistics
  WHERE table_schema = DATABASE()
    AND table_name = 'Dept'
    AND index_name = 'idx_dept_college'
);
PREPARE stmt FROM @drop_idx_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

EXPLAIN SELECT * FROM Dept WHERE college = '공과대학';
CREATE INDEX idx_dept_college ON Dept(college);
EXPLAIN SELECT * FROM Dept WHERE college = '공과대학';
SHOW INDEX FROM Dept;
""".format(
            ",\n".join(values)
        ),
        encoding="utf-8",
    )


def main() -> None:
    rows = crawl()
    if not rows:
        raise SystemExit("No public department rows were crawled.")
    write_csv(rows)
    write_sql(rows)
    print(f"crawled_departments={len(rows)}")
    print(f"csv={CSV_OUT}")
    print(f"sql={SQL_OUT}")


if __name__ == "__main__":
    main()
