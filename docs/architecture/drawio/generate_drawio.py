#!/usr/bin/env python3
"""Generate editable draw.io database diagrams from relationship definitions."""

from __future__ import annotations

import html
import uuid
from pathlib import Path

OUT_DIR = Path(__file__).resolve().parent

ENTITY_STYLE = (
    "rounded=0;whiteSpace=wrap;html=1;fillColor=#ffffff;strokeColor=#333333;"
    "fontSize=11;align=center;verticalAlign=middle;"
)
HUB_STYLE = (
    "rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;"
    "fontStyle=1;fontSize=12;align=center;verticalAlign=middle;"
)
GROUP_STYLE = (
    "rounded=0;whiteSpace=wrap;html=1;fillColor=#f5f5f5;strokeColor=#999999;"
    "dashed=1;dashPattern=8 8;fontStyle=2;fontSize=12;align=left;verticalAlign=top;"
    "spacingLeft=8;spacingTop=6;"
)
EDGE_STYLE = (
    "edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;"
    "html=1;strokeColor=#333333;fontSize=10;endArrow=block;endFill=1;"
)
EDGE_DASHED = EDGE_STYLE + "dashed=1;dashPattern=6 6;endArrow=open;endFill=0;"


def esc(text: str) -> str:
    return html.escape(text, quote=True)


def make_id(prefix: str) -> str:
    return f"{prefix}-{uuid.uuid4().hex[:8]}"


class DrawioBuilder:
    def __init__(self, page_w: int = 2000, page_h: int = 1400) -> None:
        self.page_w = page_w
        self.page_h = page_h
        self.cells: list[str] = []
        self._id = 2

    def next_id(self) -> str:
        cid = str(self._id)
        self._id += 1
        return cid

    def add_group(self, label: str, x: int, y: int, w: int, h: int) -> str:
        cid = self.next_id()
        self.cells.append(
            f'        <mxCell id="{cid}" value="{esc(label)}" style="{GROUP_STYLE}" '
            f'vertex="1" parent="1">\n'
            f'          <mxGeometry x="{x}" y="{y}" width="{w}" height="{h}" as="geometry"/>\n'
            f"        </mxCell>"
        )
        return cid

    def add_entity(
        self,
        name: str,
        x: int,
        y: int,
        w: int = 150,
        h: int = 44,
        hub: bool = False,
        subtitle: str | None = None,
    ) -> str:
        cid = self.next_id()
        if subtitle:
            value = f"<b>{esc(name)}</b><br><font style=\"font-size:9px\">{esc(subtitle)}</font>"
        else:
            value = esc(name)
        style = HUB_STYLE if hub else ENTITY_STYLE
        self.cells.append(
            f'        <mxCell id="{cid}" value="{value}" style="{style}" '
            f'vertex="1" parent="1">\n'
            f'          <mxGeometry x="{x}" y="{y}" width="{w}" height="{h}" as="geometry"/>\n'
            f"        </mxCell>"
        )
        self.name_to_id = getattr(self, "name_to_id", {})
        self.name_to_id[name] = cid
        return cid

    def add_edge(
        self,
        source: str,
        target: str,
        src_card: str = "1",
        tgt_card: str = "0..*",
        dashed: bool = False,
    ) -> None:
        sid = self.name_to_id[source]
        tid = self.name_to_id[target]
        eid = self.next_id()
        style = EDGE_DASHED if dashed else EDGE_STYLE
        label = f"{src_card} → {tgt_card}"
        self.cells.append(
            f'        <mxCell id="{eid}" value="{esc(label)}" style="{style}" '
            f'edge="1" parent="1" source="{sid}" target="{tid}">\n'
            f'          <mxGeometry relative="1" as="geometry"/>\n'
            f"        </mxCell>"
        )

    def build(self, diagram_name: str, title: str) -> str:
        diagram_id = make_id("d")
        body = "\n".join(self.cells)
        return f"""<mxfile host="app.diagrams.net" modified="2026-06-28T00:00:00.000Z" agent="E4C" version="24.0.0">
  <diagram id="{diagram_id}" name="{esc(diagram_name)}">
    <mxGraphModel dx="1200" dy="800" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="{self.page_w}" pageHeight="{self.page_h}" math="0" shadow="0">
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
        <mxCell id="title" value="{esc(title)}" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontStyle=1;fontSize=16;" vertex="1" parent="1">
          <mxGeometry x="40" y="10" width="{self.page_w - 80}" height="30" as="geometry"/>
        </mxCell>
{body}
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
"""


def build_overview() -> str:
    b = DrawioBuilder(page_w=2200, page_h=1500)

    b.add_group("Core", 480, 50, 1240, 120)
    b.add_group("Lớp học", 40, 200, 320, 420)
    b.add_group("Đề thi", 480, 1180, 900, 120)
    b.add_group("4 kỹ năng (Nghe · Đọc · Viết · Nói)", 1380, 200, 780, 920)

    # Hub
    b.add_entity("User", 960, 620, 180, 56, hub=True, subtitle="user | teacher | admin")

    # Core — top
    core_x = [520, 720, 920, 1120, 1320, 1520]
    core_names = [
        "Notification",
        "Report",
        "Word",
        "UserDailyProgress",
        "AdminAuditLog",
        "AppRelease",
    ]
    for x, name in zip(core_x, core_names):
        w = 170 if name == "UserDailyProgress" else 150
        b.add_entity(name, x, 90, w, 44)

    # Classroom — left
    cls_names = [
        "Classroom",
        "ClassroomMember",
        "ClassroomMessage",
        "ClassroomActivityLog",
        "ClassroomChatReadState",
    ]
    for i, name in enumerate(cls_names):
        w = 200 if name == "ClassroomActivityLog" else 170
        b.add_entity(name, 80, 240 + i * 72, w, 44)

    # Exam — bottom
    exam_names = [
        "Exam",
        "ExamAssignment",
        "ExamSession",
        "ExamAttempt",
        "TeacherAssignmentPreset",
    ]
    for i, name in enumerate(exam_names):
        w = 200 if name == "TeacherAssignmentPreset" else 150
        b.add_entity(name, 520 + i * 170, 1230, w, 44)

    # Learning — 5 columns
    cols: list[list[str]] = [
        ["Listening", "Enrollment", "DictationAttempt", "CueComment"],
        ["ListeningComprehension", "ListeningCompAttempt"],
        ["Reading", "ReadingProgress", "ReadingAttempt"],
        ["WritingTopic", "WritingSubmission", "WritingTopicVersion"],
        ["SpeakingSet", "SpeakingEnrollment", "SpeakingAttempt"],
    ]
    col_x = [1400, 1560, 1720, 1880, 2040]
    for x, names in zip(col_x, cols):
        for j, name in enumerate(names):
            w = 190 if len(name) > 18 else 150
            b.add_entity(name, x - (20 if w == 190 else 0), 240 + j * 72, w, 44)

    # User → Core
    for name in core_names[:-1]:  # AppRelease standalone
        if name == "Notification":
            b.add_edge("User", name, "1", "0..*")
            b.add_edge("User", name, "0..1", "0..*")
        else:
            b.add_edge("User", name)

    # User → Classroom
    b.add_edge("User", "Classroom")
    b.add_edge("User", "ClassroomMember")
    b.add_edge("User", "ClassroomMessage")
    b.add_edge("User", "ClassroomActivityLog", "0..1", "0..*")
    b.add_edge("User", "ClassroomChatReadState")

    # Classroom internal
    b.add_edge("Classroom", "ClassroomMember")
    b.add_edge("Classroom", "ClassroomMessage")
    b.add_edge("Classroom", "ClassroomActivityLog")
    b.add_edge("Classroom", "ClassroomChatReadState")
    b.add_edge("Classroom", "ClassroomMessage", "0..1", "0..1")

    # User → Exam
    for name in exam_names:
        b.add_edge("User", name)

    # Exam chain
    b.add_edge("Exam", "ExamAssignment")
    b.add_edge("Classroom", "ExamAssignment", "0..1", "0..*")
    b.add_edge("ExamAssignment", "ExamSession")
    b.add_edge("ExamAssignment", "ExamAttempt")
    b.add_edge("ExamSession", "ExamAttempt", "0..1", "0..*")
    b.add_edge("TeacherAssignmentPreset", "ExamAssignment", dashed=True)

    # User → Learning attempts/progress
    for name in [
        "Enrollment",
        "DictationAttempt",
        "CueComment",
        "ListeningCompAttempt",
        "ReadingProgress",
        "ReadingAttempt",
        "WritingSubmission",
        "WritingTopicVersion",
        "SpeakingEnrollment",
        "SpeakingAttempt",
    ]:
        card = "0..1" if name == "WritingTopicVersion" else "1"
        b.add_edge("User", name, card, "0..*")

    # Content → child
    b.add_edge("Listening", "Enrollment")
    b.add_edge("Listening", "DictationAttempt")
    b.add_edge("Listening", "CueComment")
    b.add_edge("ListeningComprehension", "ListeningCompAttempt")
    b.add_edge("CueComment", "CueComment", "0..1", "0..*")
    b.add_edge("Reading", "ReadingProgress")
    b.add_edge("Reading", "ReadingAttempt")
    b.add_edge("WritingTopic", "WritingSubmission")
    b.add_edge("WritingTopic", "WritingTopicVersion")
    b.add_edge("SpeakingSet", "SpeakingEnrollment")
    b.add_edge("SpeakingSet", "SpeakingAttempt")

    return b.build("Overview", "E4C — Sơ đồ tổng quan CSDL (32 collection)")


def build_domain(
    title: str,
    diagram_name: str,
    groups: list[tuple[str, list[str], int, int, int, int]],
    edges: list[tuple],
    page_w: int = 1600,
    page_h: int = 1000,
) -> str:
    b = DrawioBuilder(page_w=page_w, page_h=page_h)
    y_offset = 60
    for group_label, names, gx, gy, gw, gh in groups:
        b.add_group(group_label, gx, gy + y_offset, gw, gh)
        inner_y = gy + y_offset + 40
        step = min(56, max(44, (gh - 60) // max(len(names), 1)))
        for i, name in enumerate(names):
            w = min(220, max(150, len(name) * 8 + 40))
            b.add_entity(name, gx + 20, inner_y + i * step, w, 44)

    if "User" not in b.name_to_id:
        # domain-core has User in first group
        pass

    for edge in edges:
        dashed = edge[3] if len(edge) > 3 else False
        src_card = edge[2] if len(edge) > 2 and isinstance(edge[2], str) and ".." in edge[2] else "1"
        tgt_card = "0..*"
        if len(edge) >= 3 and not (isinstance(edge[2], str) and ".." in str(edge[2])):
            b.add_edge(edge[0], edge[1], dashed=dashed)
        elif len(edge) >= 4:
            b.add_edge(edge[0], edge[1], edge[2], edge[3], dashed=dashed)
        else:
            b.add_edge(edge[0], edge[1], src_card, tgt_card, dashed=dashed)

    return b.build(diagram_name, title)


def build_core() -> str:
    b = DrawioBuilder(page_w=1200, page_h=800)
    b.add_group("Core & Hệ thống", 40, 60, 1120, 680)
    b.add_entity("User", 480, 120, 200, 56, hub=True, subtitle="user | teacher | admin")
    others = [
        ("Notification", 120, 280),
        ("Report", 320, 280),
        ("Word", 520, 280),
        ("UserDailyProgress", 720, 280),
        ("AdminAuditLog", 920, 280),
        ("AppRelease", 520, 520),
    ]
    for name, x, y in others:
        w = 190 if name == "UserDailyProgress" else 160
        b.add_entity(name, x, y, w, 44)

    b.add_edge("User", "Notification", "1", "0..*")
    b.add_edge("User", "Notification", "0..1", "0..*")
    for name in ["Report", "Word", "UserDailyProgress", "AdminAuditLog"]:
        b.add_edge("User", name)
    return b.build("Core", "E4C — Core & Hệ thống (7 collection)")


def build_classroom_exam() -> str:
    b = DrawioBuilder(page_w=1400, page_h=900)
    b.add_entity("User", 600, 40, 180, 56, hub=True)

    b.add_group("Lớp học", 40, 140, 520, 380)
    cls = ["Classroom", "ClassroomMember", "ClassroomMessage", "ClassroomActivityLog", "ClassroomChatReadState"]
    for i, n in enumerate(cls):
        b.add_entity(n, 80, 200 + i * 58, 200, 44)

    b.add_group("Đề thi", 40, 560, 1320, 300)
    exam = ["Exam", "ExamAssignment", "ExamSession", "ExamAttempt", "TeacherAssignmentPreset"]
    for i, n in enumerate(exam):
        b.add_entity(n, 80 + i * 240, 640, 200, 44)

    for n in cls:
        card = "0..1" if n == "ClassroomActivityLog" else "1"
        b.add_edge("User", n, card, "0..*")
    b.add_edge("Classroom", "ClassroomMember")
    b.add_edge("Classroom", "ClassroomMessage")
    b.add_edge("Classroom", "ClassroomActivityLog")
    b.add_edge("Classroom", "ClassroomChatReadState")
    b.add_edge("Classroom", "ClassroomMessage", "0..1", "0..1")

    for n in exam:
        b.add_edge("User", n)
    b.add_edge("Exam", "ExamAssignment")
    b.add_edge("Classroom", "ExamAssignment", "0..1", "0..*")
    b.add_edge("ExamAssignment", "ExamSession")
    b.add_edge("ExamAssignment", "ExamAttempt")
    b.add_edge("ExamSession", "ExamAttempt", "0..1", "0..*")
    b.add_edge("TeacherAssignmentPreset", "ExamAssignment", dashed=True)

    return b.build("ClassroomExam", "E4C — Lớp học & Đề thi (10 collection)")


def build_learning() -> str:
    b = DrawioBuilder(page_w=1800, page_h=1000)
    b.add_entity("User", 780, 40, 180, 56, hub=True)

    groups = [
        ("Nghe — Dictation", ["Listening", "Enrollment", "DictationAttempt", "CueComment"], 40, 120),
        ("Nghe — MCQ", ["ListeningComprehension", "ListeningCompAttempt"], 40, 420),
        ("Đọc", ["Reading", "ReadingProgress", "ReadingAttempt"], 420, 120),
        ("Viết", ["WritingTopic", "WritingSubmission", "WritingTopicVersion"], 780, 120),
        ("Nói", ["SpeakingSet", "SpeakingEnrollment", "SpeakingAttempt"], 1140, 120),
    ]
    for label, names, gx, gy in groups:
        gh = 40 + len(names) * 58 + 20
        b.add_group(label, gx, gy, 320, gh)
        for i, n in enumerate(names):
            b.add_entity(n, gx + 20, gy + 50 + i * 58, 280, 44)

    b.add_edge("Listening", "Enrollment")
    b.add_edge("Listening", "DictationAttempt")
    b.add_edge("Listening", "CueComment")
    b.add_edge("ListeningComprehension", "ListeningCompAttempt")
    b.add_edge("CueComment", "CueComment", "0..1", "0..*")
    b.add_edge("Reading", "ReadingProgress")
    b.add_edge("Reading", "ReadingAttempt")
    b.add_edge("WritingTopic", "WritingSubmission")
    b.add_edge("WritingTopic", "WritingTopicVersion")
    b.add_edge("SpeakingSet", "SpeakingEnrollment")
    b.add_edge("SpeakingSet", "SpeakingAttempt")

    for n in [
        "Enrollment", "DictationAttempt", "CueComment", "ListeningCompAttempt",
        "ReadingProgress", "ReadingAttempt", "WritingSubmission",
        "SpeakingEnrollment", "SpeakingAttempt",
    ]:
        b.add_edge("User", n)
    b.add_edge("User", "WritingTopicVersion", "0..1", "0..*")

    return b.build("Learning", "E4C — 4 kỹ năng (16 collection)")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    files = {
        "database-overview.drawio": build_overview(),
        "database-domain-core.drawio": build_core(),
        "database-domain-classroom-exam.drawio": build_classroom_exam(),
        "database-domain-learning.drawio": build_learning(),
    }
    for name, content in files.items():
        path = OUT_DIR / name
        path.write_text(content, encoding="utf-8")
        print(f"Wrote {path}")


if __name__ == "__main__":
    main()
