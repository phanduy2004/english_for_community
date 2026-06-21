/**
 * Chụp JSON "golden" ~10 endpoint nóng để diff sau mỗi giai đoạn migration (T2 audit).
 *
 * Usage:
 *   node scripts/goldenCapture.js
 *   node scripts/goldenCapture.js --out migrations/golden/baseline.json
 *
 * Env (optional overrides):
 *   GOLDEN_BASE_URL=http://localhost:3000
 *   GOLDEN_TEACHER_EMAIL=hoangdong.teacher@e4c.dev
 *   GOLDEN_TEACHER_PASSWORD=Teacher@123456
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { loadEnv } from '../src/lib/loadEnv.js';

loadEnv();

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const BASE = (process.env.GOLDEN_BASE_URL || 'http://localhost:3000').replace(/\/$/, '');
const EMAIL = process.env.GOLDEN_TEACHER_EMAIL || 'hoangdong.teacher@e4c.dev';
const PASSWORD = process.env.GOLDEN_TEACHER_PASSWORD || 'Teacher@123456';

async function api(method, urlPath, token, body) {
  const res = await fetch(`${BASE}${urlPath}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body != null ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    json = { _raw: text, _status: res.status };
  }
  if (!res.ok) {
    return { _error: true, status: res.status, body: json };
  }
  return json;
}

function pickFirstId(list, keys = ['id', '_id']) {
  if (!Array.isArray(list) || list.length === 0) return null;
  const item = list[0];
  for (const k of keys) {
    const v = item?.[k];
    if (v != null) return String(v);
  }
  return null;
}

async function capture() {
  const outArg = process.argv.indexOf('--out');
  const outPath =
    outArg >= 0
      ? path.resolve(process.argv[outArg + 1])
      : path.join(__dirname, '..', 'migrations', 'golden', 'baseline.json');

  const login = await api('POST', '/api/auth/login', null, { email: EMAIL, password: PASSWORD });
  const token = login?.accessToken;
  if (!token) {
    throw new Error(`Login failed: ${JSON.stringify(login)}`);
  }

  const classrooms = await api('GET', '/api/classrooms/mine', token);
  const classroomId = pickFirstId(classrooms);

  const assignments = await api('GET', '/api/teacher/exams/assignments', token);
  const assignmentId = pickFirstId(assignments);

  const exams = await api('GET', '/api/teacher/exams', token);
  const examId = pickFirstId(exams);

  let attemptId = null;
  let gradingHub = null;
  if (assignmentId) {
    gradingHub = await api('GET', `/api/teacher/exams/assignments/${assignmentId}/attempts`, token);
    attemptId = pickFirstId(gradingHub?.attempts);
  }

  const snapshot = {
    capturedAt: new Date().toISOString(),
    baseUrl: BASE,
    teacherEmail: EMAIL,
    endpoints: {
      login: { accessTokenPresent: !!token, user: login?.user ?? login },
      teacherDashboardActionItems: await api('GET', '/api/teacher/dashboard/action-items', token),
      teacherExams: exams,
      teacherAssignments: assignments,
      classroomDetail: classroomId
        ? await api('GET', `/api/classrooms/${classroomId}`, token)
        : { _skipped: 'no classroom' },
      gradebook: classroomId
        ? await api('GET', `/api/teacher/exams/classrooms/${classroomId}/gradebook`, token)
        : { _skipped: 'no classroom' },
      assignmentAttempts: gradingHub,
      gradingAttempt: attemptId
        ? await api('GET', `/api/teacher/exams/grading-attempts/${attemptId}`, token)
        : { _skipped: 'no attempt' },
      liveScreen: attemptId
        ? await api('GET', `/api/teacher/exams/attempts/${attemptId}/live-screen`, token)
        : { _skipped: 'no attempt' },
      chatInbox: await api('GET', '/api/classroom-chat/inbox', token),
      notifications: await api('GET', '/api/notifications?page=1', token),
      examDetail: examId
        ? await api('GET', `/api/teacher/exams/${examId}`, token)
        : { _skipped: 'no exam' },
    },
    ids: { classroomId, assignmentId, attemptId, examId },
  };

  fs.mkdirSync(path.dirname(outPath), { recursive: true });
  fs.writeFileSync(outPath, JSON.stringify(snapshot, null, 2));
  console.log(`[golden] wrote ${outPath}`);
  return outPath;
}

capture().catch((err) => {
  console.error('[golden] failed', err);
  process.exit(1);
});
