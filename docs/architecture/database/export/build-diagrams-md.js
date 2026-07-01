const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname);
const out = path.join(dir, '..', 'database-diagrams-uml.md');

function bodyFromMmd(name) {
  const raw = fs.readFileSync(path.join(dir, `${name}.mmd`), 'utf8');
  return raw.replace(/^---[\s\S]*?---\n?/, '').trim();
}

const sections = [
  {
    id: '2.x.2.1',
    title: 'User, hệ thống, lớp học (Hình 1/3)',
    count: 12,
    file: 'erd-hinh-1a-user-lop',
    img: 'Hình 2.x.2.1 — User, hệ thống, lớp học',
  },
  {
    id: '2.x.2.2',
    title: 'Đề thi (Hình 2/3)',
    count: 7,
    file: 'erd-hinh-1b-de-thi',
    img: 'Hình 2.x.2.2 — Đề thi',
  },
  {
    id: '2.x.2.3',
    title: 'Học tập — Nghe, đọc, viết, nói (Hình 3/3)',
    count: 15,
    file: 'erd-hinh-2-hoc-tap',
    img: 'Hình 2.x.2.3 — Học tập',
  },
];

let md = `# Lược đồ thực thể kết hợp (ERD) — English for Community

> **32 collection** · MongoDB \`english_community\`  
> Kiểu **luận văn**: mỗi thực thể dạng **class UML** (\`+ObjectId _id\`, một cột); quan hệ có **cardinality** (\`1\`, \`0..*\`, \`0..1\`); **không ghi tên FK** trên mũi tên.  
> **Trắng đen** (không tô màu miền). Ký hiệu field: \`+\` public · \`-\` private · \`#\` protected.

**Hướng dẫn Word:** [database-diagrams-for-word.md](../database-diagrams-for-word.md)  
**PlantUML (7 trang):** [plantuml/database-full.puml](../plantuml/database-full.puml)

### Cách xem & sửa

| Việc | Làm gì |
|------|--------|
| **Xem sơ đồ** | Preview file này (Ctrl+Shift+V) hoặc xem PNG bên dưới |
| **Sửa schema** | Sửa [\`export/*.mmd\`](export/) → chạy [\`export/export-erd.ps1\`](export/export-erd.ps1) |
| **Chèn Word** | PNG/SVG trong [\`export/\`](export/) |
| **Copy Mermaid** | Dán khối \`\`\`mermaid\`\`\` bên dưới vào [mermaid.live](https://mermaid.live) (kèm frontmatter [\`erd-frontmatter.yaml\`](export/erd-frontmatter.yaml)) |

---

`;

for (const s of sections) {
  const code = bodyFromMmd(s.file);
  md += `## ${s.id} ${s.title}

${s.count} thực thể · Source: [\`export/${s.file}.mmd\`](export/${s.file}.mmd)

\`\`\`mermaid
${code}
\`\`\`

![${s.img}](export/${s.file}.png)

---

`;
}

md += `## Ghi chú

| Mục | Giải thích |
|-----|------------|
| **Đủ 32/32** | User + 31 collection còn lại — bảng đối chiếu bên dưới |
| **Hình 1** | User (đủ field) + hệ thống + lớp — 12 thực thể |
| **Hình 2** | Đề thi — 7 thực thể; User rút gọn (tham chiếu) |
| **Hình 3** | Nghe, đọc, viết, nói — 15 thực thể; User rút gọn |
| **Không vẽ** | \`RolePermission\`, \`TeacherApplication\` — model cũ |
| **AppRelease** | Không FK tới User |
| Kiểu \`objectId\` | Tham chiếu MongoDB ObjectId (FK ngầm) |
| Kiểu \`object\` / \`object_array\` | Subdocument nhúng (Mongoose embed) |
| Quan hệ \`"1" --> "0..*"\` | Một–nhiều bắt buộc |
| Quan hệ \`"0..1" ..> "0..*"\` | Một–nhiều tùy chọn |
| Quan hệ \`"0..1" ..> "0..1"\` | Một–một tùy chọn |
| **Giới hạn Mermaid** | Không vẽ **chân quạ ER** và **bảng class** trong cùng một diagram |

### Bảng đối chiếu 32 collection

| STT | Collection | Hình ERD |
|:---:|------------|:--------:|
| 1 | User | 1 + 2 + 3 |
| 2 | Notification | 1 |
| 3 | Report | 1 |
| 4 | Word | 1 |
| 5 | UserDailyProgress | 1 |
| 6 | AdminAuditLog | 1 |
| 7 | AppRelease | 1 |
| 8 | Classroom | 1 |
| 9 | ClassroomMember | 1 |
| 10 | ClassroomMessage | 1 |
| 11 | ClassroomActivityLog | 1 |
| 12 | ClassroomChatReadState | 1 |
| 13 | Exam | 2 |
| 14 | ExamAssignment | 2 |
| 15 | ExamSession | 2 |
| 16 | ExamAttempt | 2 |
| 17 | TeacherAssignmentPreset | 2 |
| 18 | Listening | 3 |
| 19 | Enrollment | 3 |
| 20 | DictationAttempt | 3 |
| 21 | CueComment | 3 |
| 22 | ListeningComprehension | 3 |
| 23 | ListeningCompAttempt | 3 |
| 24 | Reading | 3 |
| 25 | ReadingProgress | 3 |
| 26 | ReadingAttempt | 3 |
| 27 | WritingTopic | 3 |
| 28 | WritingSubmission | 3 |
| 29 | WritingTopicVersion | 3 |
| 30 | SpeakingSet | 3 |
| 31 | SpeakingEnrollment | 3 |
| 32 | SpeakingAttempt | 3 |
`;

fs.writeFileSync(out, md, 'utf8');
console.log('Wrote', out);
