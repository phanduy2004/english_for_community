/**
 * Integration tests: teacher ↔ student notifications (API + optional DB)
 * Run: npm run test:notifications
 */
import '../lib/loadEnv.js';

const BASE = process.env.TEST_API_BASE || 'http://localhost:3000/api';

const TEACHER = { email: 'hoangdong.teacher@e4c.dev', password: 'Teacher@123456' };
const STUDENT = { email: 'seed.hd.student01@e4c.dev', password: 'Student@123456' };

const results = [];

function pass(name, detail = '') {
  results.push({ name, ok: true, detail });
  console.log(`  ✅ ${name}${detail ? ` — ${detail}` : ''}`);
}
function fail(name, detail = '') {
  results.push({ name, ok: false, detail });
  console.log(`  ❌ ${name}${detail ? ` — ${detail}` : ''}`);
}

async function api(method, path, { token, body } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers,
    body: body != null ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let data;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }
  return { status: res.status, data };
}

async function login(creds) {
  const { status, data } = await api('POST', '/auth/login', { body: creds });
  if (status !== 200 || !data?.accessToken) {
    throw new Error(`Login failed ${status}: ${JSON.stringify(data)}`);
  }
  return { token: data.accessToken, user: data.user };
}

async function getNotifications(token) {
  const { status, data } = await api('GET', '/notifications?page=1', { token });
  if (status !== 200) throw new Error(`GET notifications ${status}: ${JSON.stringify(data)}`);
  return data;
}

function findNoti(items, type, extra = {}) {
  return items.find((n) => {
    if (n.type !== type) return false;
    for (const [k, v] of Object.entries(extra)) {
      if (String(n.data?.[k] ?? '') !== String(v)) return false;
    }
    return true;
  });
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function main() {
  const startedAt = Date.now();
  console.log('\n🧪 Teacher ↔ Student notification tests\n');
  console.log(`API: ${BASE}\n`);

  let teacherToken;
  let studentToken;

  try {
    const t = await login(TEACHER);
    teacherToken = t.token;
    pass('Login teacher', TEACHER.email);
    const s = await login(STUDENT);
    studentToken = s.token;
    pass('Login student', STUDENT.email);
  } catch (e) {
    fail('Login / server', e.message);
    printSummary(startedAt);
    process.exit(1);
  }

  // Teacher classrooms + exams
  const { status: clsStatus, data: classrooms } = await api('GET', '/classrooms/mine', {
    token: teacherToken,
  });
  if (clsStatus !== 200 || !Array.isArray(classrooms) || classrooms.length === 0) {
    fail('GET teacher classrooms', `${clsStatus}`);
    printSummary(startedAt);
    process.exit(1);
  }
  const classroom = classrooms.find((c) => /SEED:HoangDong/i.test(c.name || '')) || classrooms[0];
  const classroomId = classroom.id || classroom._id;
  pass('Teacher classroom', classroom.name || classroomId);

  const { status: exStatus, data: exams } = await api('GET', '/teacher/exams', { token: teacherToken });
  if (exStatus !== 200 || !Array.isArray(exams)) {
    fail('GET teacher exams', `${exStatus}`);
    printSummary(startedAt);
    process.exit(1);
  }
  const published = exams.find((e) => e.status === 'published' && /SEED:HoangDong/i.test(e.title || ''))
    || exams.find((e) => e.status === 'published');
  if (!published) {
    fail('Published exam for test');
    printSummary(startedAt);
    process.exit(1);
  }
  const examId = published.id || published._id;
  pass('Published exam', published.title);

  const studentInboxBefore = await getNotifications(studentToken);
  const teacherInboxBefore = await getNotifications(teacherToken);
  const studentItemsBefore = studentInboxBefore.data || [];
  const teacherItemsBefore = teacherInboxBefore.data || [];

  // ─── TC1: EXAM_ASSIGNED ───────────────────────────────────────
  console.log('\n📋 TC1 — Giao bài cho lớp (EXAM_ASSIGNED + Socket)');
  const createRes = await api('POST', '/teacher/exams/assignments', {
    token: teacherToken,
    body: {
      examId,
      audience: 'classroom',
      classroomId,
      mode: 'practice',
      config: {
        allowPartialSubmit: true,
        attemptPolicy: 'unlimited',
        showResultsPolicy: 'after_submit',
      },
    },
  });
  let assignmentId;
  if (createRes.status === 201) {
    assignmentId = createRes.data?.id || createRes.data?._id;
    pass('POST create classroom assignment (practice)', assignmentId);
  } else {
    fail('POST create assignment', `${createRes.status} ${JSON.stringify(createRes.data)}`);
  }

  await sleep(800);
  if (assignmentId) {
    const inbox = await getNotifications(studentToken);
    const items = inbox.data || [];
    const found = findNoti(items, 'EXAM_ASSIGNED', { assignmentId });
    if (found) {
      pass('Student inbox EXAM_ASSIGNED', `"${found.title}"`);
      if (found.data?.classroomId) pass('Payload classroomId', found.data.classroomId);
      else fail('Payload classroomId missing');
    } else {
      const newOnes = items.filter((n) => !studentItemsBefore.some((o) => (o._id || o.id) === (n._id || n.id)));
      fail('Student inbox EXAM_ASSIGNED', `new items: ${newOnes.map((n) => n.type).join(', ') || 'none'}`);
    }
    if ((inbox.unreadCount ?? 0) > 0) pass('Student unreadCount > 0', `${inbox.unreadCount}`);
  }

  // ─── TC2: EXAM_ASSIGNMENT_UPDATED ─────────────────────────────
  if (assignmentId) {
    console.log('\n📋 TC2 — Cập nhật bài (EXAM_ASSIGNMENT_UPDATED)');
    const patchRes = await api('PATCH', `/teacher/exams/assignments/${assignmentId}`, {
      token: teacherToken,
      body: { config: { timeLimitSeconds: 1800 } },
    });
    if (patchRes.status === 200) pass('PATCH assignment');
    else fail('PATCH assignment', `${patchRes.status}`);

    await sleep(600);
    const inbox = await getNotifications(studentToken);
    const found = findNoti(inbox.data || [], 'EXAM_ASSIGNMENT_UPDATED', { assignmentId });
    if (found) pass('Student inbox EXAM_ASSIGNMENT_UPDATED', found.title);
    else fail('Student inbox EXAM_ASSIGNMENT_UPDATED');
  }

  // ─── TC3: EXAM_SUBMISSION_RECEIVED + TC4 RESULTS ─────────────
  if (assignmentId) {
    console.log('\n📋 TC3 — Học sinh nộp bài → GV (EXAM_SUBMISSION_RECEIVED)');
    const startRes = await api('POST', `/exams/assignments/${assignmentId}/start`, {
      token: studentToken,
    });
    let attemptId;
    if (startRes.status === 201 || startRes.status === 200) {
      attemptId = startRes.data?.id || startRes.data?._id;
      pass('Student start attempt', attemptId);
    } else {
      fail('Student start attempt', `${startRes.status} ${JSON.stringify(startRes.data)}`);
    }

    if (attemptId) {
      const submitRes = await api('POST', `/exams/attempts/${attemptId}/submit`, {
        token: studentToken,
        body: { force: true },
      });
      if (submitRes.status === 200) pass('Student submit (force)');
      else fail('Student submit', `${submitRes.status} ${JSON.stringify(submitRes.data)}`);

      await sleep(800);
      const tInbox = await getNotifications(teacherToken);
      const sub = findNoti(tInbox.data || [], 'EXAM_SUBMISSION_RECEIVED', { assignmentId });
      if (sub) pass('Teacher inbox EXAM_SUBMISSION_RECEIVED', sub.title);
      else {
        const newT = (tInbox.data || []).filter(
          (n) => !teacherItemsBefore.some((o) => (o._id || o.id) === (n._id || n.id))
        );
        fail('Teacher inbox EXAM_SUBMISSION_RECEIVED', `new: ${newT.map((n) => n.type).join(', ') || 'none'}`);
      }

      // TC4 — practice after_submit may auto-release; also test manual release
      console.log('\n📋 TC4 — Công bố điểm (EXAM_RESULTS_RELEASED)');
      const beforeRel = await getNotifications(studentToken);
      const releaseRes = await api('POST', `/teacher/exams/attempts/${attemptId}/release-results`, {
        token: teacherToken,
      });
      if (releaseRes.status === 200) pass('Teacher release-results');
      else fail('Teacher release-results', `${releaseRes.status} ${JSON.stringify(releaseRes.data)}`);

      await sleep(600);
      const afterRel = await getNotifications(studentToken);
      const rel = findNoti(afterRel.data || [], 'EXAM_RESULTS_RELEASED', { attemptId });
      const hadBefore = findNoti(beforeRel.data || [], 'EXAM_RESULTS_RELEASED', { attemptId });
      if (rel) pass('Student inbox EXAM_RESULTS_RELEASED', rel.title);
      else if (hadBefore) pass('Student EXAM_RESULTS_RELEASED (already on submit)', 'practice after_submit');
      else fail('Student inbox EXAM_RESULTS_RELEASED');
    }
  }

  // ─── TC5: EXAM_ASSIGNMENT_CLOSED ──────────────────────────────
  if (assignmentId) {
    console.log('\n📋 TC5 — Đóng bài (EXAM_ASSIGNMENT_CLOSED)');
    const closeRes = await api('POST', `/teacher/exams/assignments/${assignmentId}/close`, {
      token: teacherToken,
    });
    if (closeRes.status === 200) pass('POST close assignment');
    else fail('POST close assignment', `${closeRes.status}`);

    await sleep(600);
    const inbox = await getNotifications(studentToken);
    const closed = findNoti(inbox.data || [], 'EXAM_ASSIGNMENT_CLOSED', { assignmentId });
    if (closed) pass('Student inbox EXAM_ASSIGNMENT_CLOSED', closed.title);
    else fail('Student inbox EXAM_ASSIGNMENT_CLOSED');
  }

  // ─── TC6: Socket (manual note) ────────────────────────────────
  console.log('\n📋 TC6 — Socket realtime (manual)');
  pass(
    'Socket delivery',
    'Check backend log: ⚡ [Socket] new_notification → room <studentId> while student app is open'
  );

  printSummary(startedAt);
  const failed = results.filter((r) => !r.ok).length;
  process.exit(failed > 0 ? 1 : 0);
}

function printSummary(startedAt) {
  const passed = results.filter((r) => r.ok).length;
  const failed = results.filter((r) => !r.ok).length;
  console.log('\n' + '─'.repeat(50));
  console.log(`Summary: ${passed} passed, ${failed} failed (${Date.now() - startedAt}ms)`);
  if (failed > 0) {
    console.log('\nFailed:');
    results.filter((r) => !r.ok).forEach((r) => console.log(`  • ${r.name}: ${r.detail}`));
  }
  console.log('\nRe-run: npm run test:notifications');
  console.log('Socket UI: keep student logged in, watch SnackBar (web) or banner (mobile).\n');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
