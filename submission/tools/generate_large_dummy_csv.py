from __future__ import annotations

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "data" / "large_csv"

STUDENT_COUNT = 10_000
LECTURE_COUNT = 1_000
ENROLLMENT_COUNT = 50_000

STUDENT_BASE = 100_001
LECTURE_BASE = 200_001
ENROLLMENT_BASE = 300_001
GRADE_BASE = 400_001


def write_csv(name: str, header: list[str], rows) -> Path:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    path = OUT_DIR / name
    with path.open("w", encoding="utf-8-sig", newline="") as file:
        writer = csv.writer(file)
        writer.writerow(header)
        writer.writerows(rows)
    return path


def grade_letter(score: int) -> str:
    if score >= 95:
        return "A+"
    if score >= 90:
        return "A0"
    if score >= 85:
        return "B+"
    if score >= 80:
        return "B0"
    if score >= 75:
        return "C+"
    if score >= 70:
        return "C0"
    if score >= 65:
        return "D+"
    if score >= 60:
        return "D0"
    return "F"


def student_rows():
    for i in range(1, STUDENT_COUNT + 1):
        stuid = STUDENT_BASE + i - 1
        yield [
            stuid,
            f"더미학생{i:05d}",
            1 + (i % 4),
            f"010-9{i // 10000}{(i // 100) % 100:02d}-{i % 10000:04d}",
            f"dummy{i:05d}@jnu.ac.kr",
            1 + (i % 6),
            1 + (i % 8),
        ]


def lecture_rows():
    subjects = [
        "전남대공개학과데이터분석",
        "학사정보시스템",
        "수강신청데이터베이스",
        "성적관리실습",
        "교육데이터마이닝",
        "대학행정정보처리",
        "공개데이터활용",
        "SQL최적화",
    ]
    for i in range(1, LECTURE_COUNT + 1):
        lid = LECTURE_BASE + i - 1
        yield [
            lid,
            f"{subjects[(i - 1) % len(subjects)]}{i:04d}",
            f"JNU{i:04d}",
            1 + (i % 3),
            "2026-1",
            1 + (i % 8),
        ]


def enrollment_rows():
    for i in range(1, ENROLLMENT_COUNT + 1):
        enrollid = ENROLLMENT_BASE + i - 1
        stuid = STUDENT_BASE + ((i - 1) % STUDENT_COUNT)
        lid = LECTURE_BASE + ((i - 1) // STUDENT_COUNT)
        yield [
            enrollid,
            stuid,
            lid,
            "2026-03-02",
            "완료",
            "2026-1",
            "정규",
        ]


def grade_rows():
    for i in range(1, ENROLLMENT_COUNT + 1):
        gradeid = GRADE_BASE + i - 1
        enrollid = ENROLLMENT_BASE + i - 1
        score = 40 + ((enrollid * 17) % 61)
        yield [
            gradeid,
            enrollid,
            f"{score:.2f}",
            grade_letter(score),
            "2026-06-20",
            "CSV 대용량 더미",
        ]


def main() -> None:
    outputs = [
        write_csv(
            "dummy_students_10000.csv",
            ["stuid", "sname", "stu_year", "phone", "email", "deptid", "advisor_pid"],
            student_rows(),
        ),
        write_csv(
            "dummy_lectures_1000.csv",
            ["lid", "lname", "lnum", "credit", "semester", "pid"],
            lecture_rows(),
        ),
        write_csv(
            "dummy_enrollments_50000.csv",
            ["enrollid", "stuid", "lid", "enroll_date", "status", "semester", "enroll_type"],
            enrollment_rows(),
        ),
        write_csv(
            "dummy_grades_50000.csv",
            ["gradeid", "enrollid", "score", "grade_letter", "evaluation_date", "remark"],
            grade_rows(),
        ),
    ]
    for path in outputs:
        print(path)


if __name__ == "__main__":
    main()
