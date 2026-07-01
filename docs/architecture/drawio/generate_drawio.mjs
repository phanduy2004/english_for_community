#!/usr/bin/env node
/** Generate editable draw.io database: E4C database diagrams */

import { writeFileSync, mkdirSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";
import { randomBytes } from "crypto";

const OUT_DIR = dirname(fileURLToPath(import.meta.url));

const ENTITY_STYLE =
  "rounded=0;whiteSpace=wrap;html=1;fillColor=#ffffff;strokeColor=#333333;fontSize=11;align=center;verticalAlign=middle;";
const HUB_STYLE =
  "rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;fontStyle=1;fontSize=12;align=center;verticalAlign=middle;";
const GROUP_STYLE =
  "rounded=0;whiteSpace=wrap;html=1;fillColor=#f5f5f5;strokeColor=#999999;dashed=1;dashPattern=8 8;fontStyle=2;fontSize=12;align=left;verticalAlign=top;spacingLeft=8;spacingTop=6;";
const EDGE_STYLE =
  "edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;strokeColor=#333333;fontSize=10;endArrow=block;endFill=1;";
const EDGE_DASHED =
  EDGE_STYLE + "dashed=1;dashPattern=6 6;endArrow=open;endFill=0;";

function esc(text) {
  return String(text)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

class DrawioBuilder {
  constructor(pageW = 2000, pageH = 1400) {
    this.pageW = pageW;
    this.pageH = pageH;
    this.cells = [];
    this.nameToId = {};
    this._id = 2;
  }

  nextId() {
    return String(this._id++);
  }

  addGroup(label, x, y, w, h) {
    const cid = this.nextId();
    this.cells.push(
      `        <mxCell id="${cid}" value="${esc(label)}" style="${GROUP_STYLE}" vertex="1" parent="1">\n` +
        `          <mxGeometry x="${x}" y="${y}" width="${w}" height="${h}" as="geometry"/>\n` +
        `        </mxCell>`
    );
    return cid;
  }

  addEntity(name, x, y, w = 150, h = 44, { hub = false, subtitle = null } = {}) {
    const cid = this.nextId();
    const value = subtitle
      ? `&lt;b&gt;${esc(name)}&lt;/b&gt;&lt;br&gt;&lt;font style=&quot;font-size:9px&quot;&gt;${esc(subtitle)}&lt;/font&gt;`
      : esc(name);
    const style = hub ? HUB_STYLE : ENTITY_STYLE;
    this.cells.push(
      `        <mxCell id="${cid}" value="${value}" style="${style}" vertex="1" parent="1">\n` +
        `          <mxGeometry x="${x}" y="${y}" width="${w}" height="${h}" as="geometry"/>\n` +
        `        </mxCell>`
    );
    this.nameToId[name] = cid;
    return cid;
  }

  addEdge(source, target, srcCard = "1", tgtCard = "0..*", dashed = false) {
    const sid = this.nameToId[source];
    const tid = this.nameToId[target];
    if (!sid || !tid) throw new Error(`Missing entity for edge ${source} -> ${target}`);
    const eid = this.nextId();
    const style = dashed ? EDGE_DASHED : EDGE_STYLE;
    const label = `${srcCard} → ${tgtCard}`;
    this.cells.push(
      `        <mxCell id="${eid}" value="${esc(label)}" style="${style}" edge="1" parent="1" source="${sid}" target="${tid}">\n` +
        `          <mxGeometry relative="1" as="geometry"/>\n` +
        `        </mxCell>`
    );
  }

  build(diagramName, title) {
    const diagramId = "d-" + randomBytes(4).toString("hex");
    return `<mxfile host="app.diagrams.net" modified="2026-06-28T00:00:00.000Z" agent="E4C" version="24.0.0">
  <diagram id="${diagramId}" name="${esc(diagramName)}">
    <mxGraphModel dx="1200" dy="800" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="${this.pageW}" pageHeight="${this.pageH}" math="0" shadow="0">
      <root>
        <mxCell id="0"/>
        <mxCell id="1" parent="0"/>
        <mxCell id="title" value="${esc(title)}" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontStyle=1;fontSize=16;" vertex="1" parent="1">
          <mxGeometry x="40" y="10" width="${this.pageW - 80}" height="30" as="geometry"/>
        </mxCell>
${this.cells.join("\n")}
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
`;
  }
}

function buildOverview() {
  const b = new DrawioBuilder(2200, 1500);
  b.addGroup("Core", 480, 50, 1240, 110);
  b.addGroup("Lớp học", 40, 200, 340, 420);
  b.addGroup("Đề thi", 480, 1180, 920, 120);
  b.addGroup("4 kỹ năng (Nghe · Đọc · Viết · Nói)", 1380, 200, 780, 920);

  b.addEntity("User", 960, 620, 180, 56, { hub: true, subtitle: "user | teacher | admin" });

  const coreX = [520, 720, 920, 1120, 1320, 1520];
  const coreNames = ["Notification", "Report", "Word", "UserDailyProgress", "AdminAuditLog", "AppRelease"];
  coreNames.forEach((name, i) => {
    const w = name === "UserDailyProgress" ? 170 : 150;
    b.addEntity(name, coreX[i], 90, w, 44);
  });

  ["Classroom", "ClassroomMember", "ClassroomMessage", "ClassroomActivityLog", "ClassroomChatReadState"].forEach(
    (name, i) => {
      const w = name === "ClassroomActivityLog" ? 200 : 170;
      b.addEntity(name, 80, 240 + i * 72, w, 44);
    }
  );

  ["Exam", "ExamAssignment", "ExamSession", "ExamAttempt", "TeacherAssignmentPreset"].forEach((name, i) => {
    const w = name === "TeacherAssignmentPreset" ? 200 : 150;
    b.addEntity(name, 520 + i * 170, 1230, w, 44);
  });

  const cols = [
    ["Listening", "Enrollment", "DictationAttempt", "CueComment"],
    ["ListeningComprehension", "ListeningCompAttempt"],
    ["Reading", "ReadingProgress", "ReadingAttempt"],
    ["WritingTopic", "WritingSubmission", "WritingTopicVersion"],
    ["SpeakingSet", "SpeakingEnrollment", "SpeakingAttempt"],
  ];
  const colX = [1400, 1560, 1720, 1880, 2040];
  cols.forEach((names, ci) => {
    names.forEach((name, j) => {
      const w = name.length > 18 ? 190 : 150;
      b.addEntity(name, colX[ci] - (w === 190 ? 20 : 0), 240 + j * 72, w, 44);
    });
  });

  coreNames.slice(0, -1).forEach((name) => {
    if (name === "Notification") {
      b.addEdge("User", name, "1", "0..*");
      b.addEdge("User", name, "0..1", "0..*");
    } else {
      b.addEdge("User", name);
    }
  });

  b.addEdge("User", "Classroom");
  b.addEdge("User", "ClassroomMember");
  b.addEdge("User", "ClassroomMessage");
  b.addEdge("User", "ClassroomActivityLog", "0..1", "0..*");
  b.addEdge("User", "ClassroomChatReadState");
  b.addEdge("Classroom", "ClassroomMember");
  b.addEdge("Classroom", "ClassroomMessage");
  b.addEdge("Classroom", "ClassroomActivityLog");
  b.addEdge("Classroom", "ClassroomChatReadState");
  b.addEdge("Classroom", "ClassroomMessage", "0..1", "0..1");

  ["Exam", "ExamAssignment", "ExamSession", "ExamAttempt", "TeacherAssignmentPreset"].forEach((n) =>
    b.addEdge("User", n)
  );
  b.addEdge("Exam", "ExamAssignment");
  b.addEdge("Classroom", "ExamAssignment", "0..1", "0..*");
  b.addEdge("ExamAssignment", "ExamSession");
  b.addEdge("ExamAssignment", "ExamAttempt");
  b.addEdge("ExamSession", "ExamAttempt", "0..1", "0..*");
  b.addEdge("TeacherAssignmentPreset", "ExamAssignment", "1", "0..*", true);

  [
    "Enrollment",
    "DictationAttempt",
    "CueComment",
    "ListeningCompAttempt",
    "ReadingProgress",
    "ReadingAttempt",
    "WritingSubmission",
    "SpeakingEnrollment",
    "SpeakingAttempt",
  ].forEach((n) => b.addEdge("User", n));
  b.addEdge("User", "WritingTopicVersion", "0..1", "0..*");

  b.addEdge("Listening", "Enrollment");
  b.addEdge("Listening", "DictationAttempt");
  b.addEdge("Listening", "CueComment");
  b.addEdge("ListeningComprehension", "ListeningCompAttempt");
  b.addEdge("CueComment", "CueComment", "0..1", "0..*");
  b.addEdge("Reading", "ReadingProgress");
  b.addEdge("Reading", "ReadingAttempt");
  b.addEdge("WritingTopic", "WritingSubmission");
  b.addEdge("WritingTopic", "WritingTopicVersion");
  b.addEdge("SpeakingSet", "SpeakingEnrollment");
  b.addEdge("SpeakingSet", "SpeakingAttempt");

  return b.build("Overview", "E4C — Sơ đồ tổng quan CSDL (32 collection)");
}

function buildCore() {
  const b = new DrawioBuilder(1200, 800);
  b.addGroup("Core & Hệ thống", 40, 60, 1120, 680);
  b.addEntity("User", 480, 120, 200, 56, { hub: true, subtitle: "user | teacher | admin" });
  [
    ["Notification", 120, 280],
    ["Report", 320, 280],
    ["Word", 520, 280],
    ["UserDailyProgress", 720, 280],
    ["AdminAuditLog", 920, 280],
    ["AppRelease", 520, 520],
  ].forEach(([name, x, y]) => {
    const w = name === "UserDailyProgress" ? 190 : 160;
    b.addEntity(name, x, y, w, 44);
  });
  b.addEdge("User", "Notification", "1", "0..*");
  b.addEdge("User", "Notification", "0..1", "0..*");
  ["Report", "Word", "UserDailyProgress", "AdminAuditLog"].forEach((n) => b.addEdge("User", n));
  return b.build("Core", "E4C — Core & Hệ thống (7 collection)");
}

function buildClassroomExam() {
  const b = new DrawioBuilder(1400, 900);
  b.addEntity("User", 600, 40, 180, 56, { hub: true });
  b.addGroup("Lớp học", 40, 140, 520, 380);
  ["Classroom", "ClassroomMember", "ClassroomMessage", "ClassroomActivityLog", "ClassroomChatReadState"].forEach(
    (n, i) => b.addEntity(n, 80, 200 + i * 58, 200, 44)
  );
  b.addGroup("Đề thi", 40, 560, 1320, 300);
  ["Exam", "ExamAssignment", "ExamSession", "ExamAttempt", "TeacherAssignmentPreset"].forEach((n, i) =>
    b.addEntity(n, 80 + i * 240, 640, 200, 44)
  );

  ["Classroom", "ClassroomMember", "ClassroomMessage", "ClassroomChatReadState"].forEach((n) => b.addEdge("User", n));
  b.addEdge("User", "ClassroomActivityLog", "0..1", "0..*");
  b.addEdge("Classroom", "ClassroomMember");
  b.addEdge("Classroom", "ClassroomMessage");
  b.addEdge("Classroom", "ClassroomActivityLog");
  b.addEdge("Classroom", "ClassroomChatReadState");
  b.addEdge("Classroom", "ClassroomMessage", "0..1", "0..1");

  ["Exam", "ExamAssignment", "ExamSession", "ExamAttempt", "TeacherAssignmentPreset"].forEach((n) => b.addEdge("User", n));
  b.addEdge("Exam", "ExamAssignment");
  b.addEdge("Classroom", "ExamAssignment", "0..1", "0..*");
  b.addEdge("ExamAssignment", "ExamSession");
  b.addEdge("ExamAssignment", "ExamAttempt");
  b.addEdge("ExamSession", "ExamAttempt", "0..1", "0..*");
  b.addEdge("TeacherAssignmentPreset", "ExamAssignment", "1", "0..*", true);

  return b.build("ClassroomExam", "E4C — Lớp học & Đề thi (10 collection)");
}

function buildLearning() {
  const b = new DrawioBuilder(1800, 1000);
  b.addEntity("User", 780, 40, 180, 56, { hub: true });

  const groups = [
    ["Nghe — Dictation", ["Listening", "Enrollment", "DictationAttempt", "CueComment"], 40, 120],
    ["Nghe — MCQ", ["ListeningComprehension", "ListeningCompAttempt"], 40, 420],
    ["Đọc", ["Reading", "ReadingProgress", "ReadingAttempt"], 420, 120],
    ["Viết", ["WritingTopic", "WritingSubmission", "WritingTopicVersion"], 780, 120],
    ["Nói", ["SpeakingSet", "SpeakingEnrollment", "SpeakingAttempt"], 1140, 120],
  ];

  groups.forEach(([label, names, gx, gy]) => {
    const gh = 40 + names.length * 58 + 20;
    b.addGroup(label, gx, gy, 320, gh);
    names.forEach((n, i) => b.addEntity(n, gx + 20, gy + 50 + i * 58, 280, 44));
  });

  b.addEdge("Listening", "Enrollment");
  b.addEdge("Listening", "DictationAttempt");
  b.addEdge("Listening", "CueComment");
  b.addEdge("ListeningComprehension", "ListeningCompAttempt");
  b.addEdge("CueComment", "CueComment", "0..1", "0..*");
  b.addEdge("Reading", "ReadingProgress");
  b.addEdge("Reading", "ReadingAttempt");
  b.addEdge("WritingTopic", "WritingSubmission");
  b.addEdge("WritingTopic", "WritingTopicVersion");
  b.addEdge("SpeakingSet", "SpeakingEnrollment");
  b.addEdge("SpeakingSet", "SpeakingAttempt");

  [
    "Enrollment",
    "DictationAttempt",
    "CueComment",
    "ListeningCompAttempt",
    "ReadingProgress",
    "ReadingAttempt",
    "WritingSubmission",
    "SpeakingEnrollment",
    "SpeakingAttempt",
  ].forEach((n) => b.addEdge("User", n));
  b.addEdge("User", "WritingTopicVersion", "0..1", "0..*");

  return b.build("Learning", "E4C — 4 kỹ năng (16 collection)");
}

mkdirSync(OUT_DIR, { recursive: true });

const files = {
  "database-overview.drawio": buildOverview(),
  "database-domain-core.drawio": buildCore(),
  "database-domain-classroom-exam.drawio": buildClassroomExam(),
  "database-domain-learning.drawio": buildLearning(),
};

for (const [name, content] of Object.entries(files)) {
  const path = join(OUT_DIR, name);
  writeFileSync(path, content, "utf8");
  console.log("Wrote", path);
}
