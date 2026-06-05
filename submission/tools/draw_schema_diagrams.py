from pathlib import Path
import math

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT_DIRS = [ROOT / "diagrams"]


def load_font(size, bold=False):
    candidates = []
    if bold:
        candidates.extend(
            [
                r"C:\Windows\Fonts\timesbd.ttf",
                r"C:\Windows\Fonts\arialbd.ttf",
                r"C:\Windows\Fonts\malgunbd.ttf",
            ]
        )
    candidates.extend(
        [
            r"C:\Windows\Fonts\times.ttf",
            r"C:\Windows\Fonts\arial.ttf",
            r"C:\Windows\Fonts\malgun.ttf",
        ]
    )
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


FONT_TITLE = load_font(46, bold=True)
FONT_HEAD = load_font(34, bold=True)
FONT = load_font(30)
FONT_SMALL = load_font(24)
FONT_TINY = load_font(20)


def text_size(draw, text, font):
    box = draw.textbbox((0, 0), text, font=font)
    return box[2] - box[0], box[3] - box[1]


def centered_text(draw, box, text, font=FONT, underline=False, fill="black"):
    x1, y1, x2, y2 = box
    w, h = text_size(draw, text, font)
    x = (x1 + x2 - w) / 2
    y = (y1 + y2 - h) / 2 - 1
    draw.text((x, y), text, font=font, fill=fill)
    if underline:
        draw.line((x, y + h + 2, x + w, y + h + 2), fill=fill, width=2)


def line(draw, p1, p2, width=2):
    draw.line((p1[0], p1[1], p2[0], p2[1]), fill="black", width=width)


def polyline(draw, points, width=2):
    for a, b in zip(points, points[1:]):
        line(draw, a, b, width)


def arrow(draw, points, width=2):
    polyline(draw, points, width)
    p1 = points[-2]
    p2 = points[-1]
    angle = math.atan2(p2[1] - p1[1], p2[0] - p1[0])
    length = 16
    spread = math.radians(24)
    left = (
        p2[0] - length * math.cos(angle - spread),
        p2[1] - length * math.sin(angle - spread),
    )
    right = (
        p2[0] - length * math.cos(angle + spread),
        p2[1] - length * math.sin(angle + spread),
    )
    draw.polygon([p2, left, right], outline="black", fill="black")


def rect(draw, box, text, font=FONT, double=False):
    draw.rectangle(box, outline="black", width=2)
    if double:
        x1, y1, x2, y2 = box
        draw.rectangle((x1 + 6, y1 + 6, x2 - 6, y2 - 6), outline="black", width=2)
    centered_text(draw, box, text, font)


def ellipse(draw, center, text, rx=100, ry=36, underline=False):
    x, y = center
    box = (x - rx, y - ry, x + rx, y + ry)
    draw.ellipse(box, outline="black", width=2)
    centered_text(draw, box, text, FONT_SMALL, underline=underline)
    return box


def diamond(draw, center, text, rx=95, ry=58):
    x, y = center
    pts = [(x, y - ry), (x + rx, y), (x, y + ry), (x - rx, y)]
    draw.polygon(pts, outline="black", fill="white")
    centered_text(draw, (x - rx, y - ry, x + rx, y + ry), text, FONT_SMALL)
    return pts


def label(draw, point, text, font=FONT_SMALL):
    draw.text(point, text, font=font, fill="black")


def label_bg(draw, point, text, font=FONT_TINY, padding=4):
    x, y = point
    w, h = text_size(draw, text, font)
    draw.rectangle((x - padding, y - padding, x + w + padding, y + h + padding), fill="white")
    draw.text((x, y), text, font=font, fill="black")


def entity_attr(draw, entity_box, attr_center, text, key=False, rx=96):
    x1, y1, x2, y2 = entity_box
    cx, cy = attr_center
    ex = min(max(cx, x1), x2)
    ey = min(max(cy, y1), y2)
    line(draw, (ex, ey), (cx, cy), 1)
    ellipse(draw, attr_center, text, rx=rx, underline=key)


def draw_chen_er():
    img = Image.new("RGB", (3600, 2600), "white")
    d = ImageDraw.Draw(img)

    centered_text(
        d,
        (0, 28, 3600, 90),
        "1. ER Diagram - Chonnam University Student Grade Management DB",
        FONT_HEAD,
    )
    label(d, (70, 95), "Chen notation: rectangle=entity, diamond=relationship, oval=attribute, underlined=PK, endpoint=(min,max)", FONT_SMALL)

    dept = (1550, 240, 1850, 340)
    student = (270, 910, 570, 1010)
    professor = (2870, 910, 3170, 1010)
    lecture = (2870, 1660, 3170, 1760)
    enrollment = (1550, 1580, 1900, 1680)
    grade = (1180, 2180, 1480, 2280)

    rect(d, dept, "Dept")
    rect(d, student, "Student")
    rect(d, professor, "Professor")
    rect(d, lecture, "Lecture")
    rect(d, enrollment, "Enrollment", double=True)
    rect(d, grade, "Grade", double=True)

    entity_attr(d, dept, (1390, 150), "deptid", True)
    entity_attr(d, dept, (1620, 120), "dname")
    entity_attr(d, dept, (1860, 130), "college")
    entity_attr(d, dept, (2100, 220), "office")
    entity_attr(d, dept, (1730, 480), "tel")

    entity_attr(d, student, (150, 740), "stuid", True)
    entity_attr(d, student, (390, 725), "sname")
    entity_attr(d, student, (650, 775), "stu_year", rx=110)
    entity_attr(d, student, (160, 1180), "phone")
    entity_attr(d, student, (435, 1200), "email")

    entity_attr(d, professor, (2740, 740), "pid", True)
    entity_attr(d, professor, (3000, 725), "pname")
    entity_attr(d, professor, (3310, 780), "prof_rank", rx=118)
    entity_attr(d, professor, (2720, 1200), "email")
    entity_attr(d, professor, (3050, 1220), "office")

    entity_attr(d, lecture, (2740, 1530), "lid", True)
    entity_attr(d, lecture, (3020, 1485), "lname")
    entity_attr(d, lecture, (3380, 1690), "lnum")
    entity_attr(d, lecture, (2740, 1910), "credit")
    entity_attr(d, lecture, (3080, 1970), "semester", rx=110)

    entity_attr(d, enrollment, (1440, 1425), "enrollid", True, rx=115)
    entity_attr(d, enrollment, (1745, 1425), "enroll_date", rx=130)
    entity_attr(d, enrollment, (1330, 1765), "status")
    entity_attr(d, enrollment, (1690, 1880), "semester", rx=110)
    entity_attr(d, enrollment, (2030, 1785), "enroll_type", rx=125)

    entity_attr(d, grade, (1010, 2075), "gradeid", True)
    entity_attr(d, grade, (1220, 2470), "score")
    entity_attr(d, grade, (1540, 2470), "grade_letter", rx=130)
    entity_attr(d, grade, (780, 2255), "evaluation_date", rx=150)
    entity_attr(d, grade, (1660, 2225), "remark")

    diamond(d, (950, 620), "belong")
    line(d, (475, 910), (870, 665), 2)
    line(d, (1030, 575), (1550, 290), 2)
    label_bg(d, (535, 830), "(1,1)")
    label_bg(d, (1420, 315), "(0,N)")

    diamond(d, (2400, 620), "work_dept", rx=120)
    line(d, (2870, 910), (2495, 665), 2)
    line(d, (2295, 580), (1850, 290), 2)
    label_bg(d, (2765, 840), "(1,1)")
    label_bg(d, (1895, 315), "(0,N)")

    diamond(d, (1720, 960), "tutor")
    line(d, (570, 960), (1625, 960), 2)
    line(d, (1815, 960), (2870, 960), 2)
    label_bg(d, (610, 915), "(0,1)")
    label_bg(d, (2770, 915), "(0,N)")

    diamond(d, (3320, 1345), "manage")
    line(d, (3170, 1010), (3300, 1288), 2)
    line(d, (3300, 1402), (3170, 1660), 2)
    label_bg(d, (3190, 1085), "(0,N)")
    label_bg(d, (3190, 1590), "(1,1)")

    diamond(d, (930, 1350), "study")
    line(d, (490, 1010), (850, 1310), 2)
    line(d, (1015, 1370), (1550, 1630), 2)
    label_bg(d, (560, 1080), "(0,N)")
    label_bg(d, (1450, 1570), "(1,1)")

    diamond(d, (2370, 1630), "for_lecture", rx=125)
    line(d, (1900, 1630), (2245, 1630), 2)
    line(d, (2495, 1630), (2870, 1710), 2)
    label_bg(d, (1930, 1588), "(1,1)")
    label_bg(d, (2785, 1660), "(1,N)")

    diamond(d, (1370, 1950), "evaluate", rx=105)
    line(d, (1600, 1680), (1430, 1905), 2)
    line(d, (1335, 2005), (1330, 2180), 2)
    label_bg(d, (1515, 1745), "(0,1)")
    label_bg(d, (1350, 2115), "(1,1)")

    label(d, (1560, 1715), "Enrollment resolves Student M:N Lecture", FONT_TINY)
    label(d, (1540, 2325), "Weak/associative entities are drawn with double rectangles.", FONT_TINY)

    save_all(img, "chen_er_diagram")


def relation_widths(draw, attrs):
    widths = []
    for text, _ in attrs:
        w, _ = text_size(draw, text, FONT_TINY)
        widths.append(max(110, w + 28))
    return widths


def draw_relation(draw, name, x, y, attrs):
    widths = relation_widths(draw, attrs)
    h = 66
    label(draw, (x, y - 38), f"<{name}>", FONT_SMALL)
    cells = {}
    cur = x
    for (text, key), w in zip(attrs, widths):
        box = (cur, y, cur + w, y + h)
        draw.rectangle(box, outline="black", width=2)
        centered_text(draw, box, text, FONT_TINY, underline=key)
        cells[text] = box
        cur += w
    return cells, (x, y, cur, y + h)


def center_top(box):
    x1, y1, x2, _ = box
    return ((x1 + x2) / 2, y1)


def center_bottom(box):
    x1, _, x2, y2 = box
    return ((x1 + x2) / 2, y2)


def center_left(box):
    x1, y1, _, y2 = box
    return (x1, (y1 + y2) / 2)


def center_right(box):
    _, y1, x2, y2 = box
    return (x2, (y1 + y2) / 2)


def draw_schema():
    img = Image.new("RGB", (2100, 1500), "white")
    d = ImageDraw.Draw(img)
    centered_text(d, (0, 35, 2100, 95), "2. Relational Database Schema", FONT_HEAD)
    label(d, (120, 120), "Underlined attributes are primary keys. FK attributes point to referenced primary keys.", FONT_SMALL)

    dept_attrs = [("deptid", True), ("dname", False), ("college", False), ("office", False), ("tel", False)]
    professor_attrs = [
        ("pid", True),
        ("pname", False),
        ("prof_rank", False),
        ("email", False),
        ("office", False),
        ("deptid(FK)", False),
    ]
    student_attrs = [
        ("stuid", True),
        ("sname", False),
        ("stu_year", False),
        ("phone", False),
        ("email", False),
        ("deptid(FK)", False),
        ("advisor_pid(FK)", False),
    ]
    lecture_attrs = [
        ("lid", True),
        ("lname", False),
        ("lnum", False),
        ("credit", False),
        ("semester", False),
        ("pid(FK)", False),
    ]
    enrollment_attrs = [
        ("enrollid", True),
        ("stuid(FK)", False),
        ("lid(FK)", False),
        ("enroll_date", False),
        ("status", False),
        ("semester", False),
        ("enroll_type", False),
    ]
    grade_attrs = [
        ("gradeid", True),
        ("enrollid(FK)", False),
        ("score", False),
        ("grade_letter", False),
        ("evaluation_date", False),
        ("remark", False),
    ]

    cells = {}
    boxes = {}
    cells["Dept"], boxes["Dept"] = draw_relation(d, "Dept", 760, 190, dept_attrs)
    cells["Student"], boxes["Student"] = draw_relation(d, "Student", 90, 430, student_attrs)
    cells["Professor"], boxes["Professor"] = draw_relation(d, "Professor", 1220, 430, professor_attrs)
    cells["Lecture"], boxes["Lecture"] = draw_relation(d, "Lecture", 1220, 700, lecture_attrs)
    cells["Enrollment"], boxes["Enrollment"] = draw_relation(d, "Enrollment", 490, 980, enrollment_attrs)
    cells["Grade"], boxes["Grade"] = draw_relation(d, "Grade", 610, 1250, grade_attrs)

    arrow(
        d,
        [
            center_top(cells["Student"]["deptid(FK)"]),
            (820, 380),
            (820, 256),
            center_bottom(cells["Dept"]["deptid"]),
        ],
    )
    arrow(
        d,
        [
            center_top(cells["Professor"]["deptid(FK)"]),
            (990, 380),
            (990, 256),
            center_bottom(cells["Dept"]["deptid"]),
        ],
    )
    arrow(
        d,
        [
            center_top(cells["Student"]["advisor_pid(FK)"]),
            (1070, 360),
            (1260, 430),
            center_left(cells["Professor"]["pid"]),
        ],
    )
    arrow(
        d,
        [
            center_top(cells["Lecture"]["pid(FK)"]),
            (1295, 625),
            center_bottom(cells["Professor"]["pid"]),
        ],
    )
    arrow(
        d,
        [
            center_top(cells["Enrollment"]["stuid(FK)"]),
            (250, 860),
            (250, 496),
            center_bottom(cells["Student"]["stuid"]),
        ],
    )
    arrow(
        d,
        [
            center_top(cells["Enrollment"]["lid(FK)"]),
            (1320, 900),
            (1320, 766),
            center_bottom(cells["Lecture"]["lid"]),
        ],
    )
    arrow(
        d,
        [
            center_top(cells["Grade"]["enrollid(FK)"]),
            (750, 1190),
            center_bottom(cells["Enrollment"]["enrollid"]),
        ],
    )

    notes = [
        "UNIQUE Dept(dname)",
        "UNIQUE Enrollment(stuid, lid, semester) prevents duplicate course registration",
        "UNIQUE Grade(enrollid) enforces Enrollment-Grade 1:1",
        "Student-Lecture M:N is mapped through Enrollment",
    ]
    y = 1360
    for note in notes:
        label(d, (120, y), f"- {note}", FONT_SMALL)
        y += 34

    save_all(img, "relational_schema_diagram")


def draw_min_cardinality():
    img = Image.new("RGB", (2400, 1700), "white")
    d = ImageDraw.Draw(img)
    centered_text(d, (0, 35, 2400, 95), "3. Minimum Relationship Cardinality Diagram", FONT_HEAD)
    label(d, (120, 120), "(min, max) shows how many times each entity must/can participate in the relationship.", FONT_SMALL)
    label(d, (120, 155), "min=1 means mandatory participation, min=0 means optional participation.", FONT_SMALL)

    def entity_box(x, y, text):
        box = (x, y, x + 270, y + 82)
        rect(d, box, text, FONT_SMALL)
        return box

    def relation_diamond(x, y, text):
        diamond(d, (x, y + 41), text, rx=130, ry=62)
        return (x - 130, y - 21, x + 130, y + 103)

    def minmax_label(box, text, above=True):
        x1, y1, x2, y2 = box
        w, h = text_size(d, text, FONT_SMALL)
        y = y1 - 42 if above else y2 + 12
        d.text(((x1 + x2 - w) / 2, y), text, font=FONT_SMALL, fill="black")

    def row(y, rid, left_entity, left_mm, rel, right_entity, right_mm, note=""):
        label(d, (130, y + 22), rid, FONT_SMALL)
        left = entity_box(300, y, left_entity)
        rel_box = relation_diamond(1035, y, rel)
        right = entity_box(1500, y, right_entity)
        line(d, (570, y + 41), (905, y + 41), 2)
        line(d, (1165, y + 41), (1500, y + 41), 2)
        minmax_label(left, left_mm, above=True)
        minmax_label(right, right_mm, above=True)
        if note:
            label(d, (1815, y + 22), note, FONT_TINY)

    rows = [
        ("R1", "Student", "(1,1)", "belong", "Dept", "(0,N)", "Student.deptid NOT NULL"),
        ("R2", "Professor", "(1,1)", "work_dept", "Dept", "(0,N)", "Professor.deptid NOT NULL"),
        ("R3", "Professor", "(0,N)", "tutor", "Student", "(0,1)", "Student.advisor_pid NULL"),
        ("R4", "Professor", "(0,N)", "manage", "Lecture", "(1,1)", "Lecture.pid NOT NULL"),
        ("R5", "Student", "(0,N)", "study", "Lecture", "(1,N)", "M:N, implemented by Enrollment"),
        ("R6", "Enrollment", "(0,1)", "evaluate", "Grade", "(1,1)", "Grade.enrollid NOT NULL + UNIQUE"),
    ]
    y = 285
    for item in rows:
        row(y, *item)
        y += 200

    summary = (300, 1490, 2050, 1605)
    d.rectangle(summary, outline="black", width=2)
    label(d, (330, 1512), "Reading example: Student (1,1) -- belong -- Dept (0,N)", FONT_SMALL)
    label(d, (330, 1547), "Every student must belong to exactly one department, but a department may have zero or many students.", FONT_TINY)
    label(d, (330, 1578), "These constraints match the FK NULL/NOT NULL and UNIQUE rules in schema.sql.", FONT_TINY)

    save_all(img, "minimum_cardinality_diagram")


def save_all(img, stem):
    for out_dir in OUT_DIRS:
        out_dir.mkdir(parents=True, exist_ok=True)
        img.save(out_dir / f"{stem}.png", quality=95)


if __name__ == "__main__":
    draw_chen_er()
    draw_schema()
    draw_min_cardinality()
    print("Generated:")
    for out_dir in OUT_DIRS:
        print(out_dir / "chen_er_diagram.png")
        print(out_dir / "relational_schema_diagram.png")
        print(out_dir / "minimum_cardinality_diagram.png")
