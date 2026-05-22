import ExcelJS from 'exceljs';
import { examAttemptService } from './examAttemptService.js';
import { percentFromScore, scoreOfAttempt } from '../lib/examAttemptScoreUtils.js';

function sanitizeFilename(name) {
  return String(name || 'assignment')
    .trim()
    .replace(/[^\w\-]+/g, '_')
    .slice(0, 80);
}

function studentFromAttempt(attempt) {
  const user = attempt.userId;
  if (user && typeof user === 'object') {
    const fullName = (user.fullName || '').trim();
    const email = (user.email || '').trim();
    const username = (user.username || '').trim();
    return {
      name: fullName || email || username || '—',
      email: email || '',
    };
  }
  return { name: '—', email: '' };
}

function formatIso(raw) {
  if (!raw) return '';
  const d = new Date(raw);
  if (Number.isNaN(d.getTime())) return '';
  return d.toISOString();
}

function statusLabel(status) {
  switch (status) {
    case 'in_progress':
      return 'In progress';
    case 'submitted':
      return 'Submitted';
    case 'expired':
      return 'Expired';
    case 'void':
      return 'Void';
    default:
      return status || '';
  }
}

function gradingLabel(state, pendingGrading) {
  if (pendingGrading) return 'Needs grading';
  switch (state) {
    case 'pending_auto':
      return 'Pending auto';
    case 'pending_ai':
      return 'Pending AI';
    case 'pending_manual':
      return 'Pending manual';
    case 'finalized':
      return 'Graded';
    default:
      return state || '';
  }
}

function rowFromAttempt(attempt, index) {
  const { name, email } = studentFromAttempt(attempt);
  const score = scoreOfAttempt(attempt);
  const status = attempt.status || '';
  const gs = attempt.gradingState || '';
  const pendingGrading =
    status === 'submitted' &&
    (gs === 'pending_manual' ||
      gs === 'pending_ai' ||
      gs === 'pending_auto' ||
      (gs === 'finalized' && !attempt.resultsReleased));

  const hasScore =
    score != null && score.awarded != null && Number.isFinite(score.awarded) && score.max > 0;
  const pct = hasScore ? percentFromScore(score) : null;

  return {
    index,
    name,
    email,
    status: statusLabel(status),
    grading: gradingLabel(gs, pendingGrading),
    score: hasScore ? score.awarded : '',
    max: hasScore ? score.max : '',
    percent: pct != null ? pct : '',
    released: attempt.resultsReleased ? 'Yes' : 'No',
    startedAt: formatIso(attempt.startedAt),
    submittedAt: formatIso(attempt.submittedAt),
  };
}

export const teacherAssignmentScoresExportService = {
  async buildXlsx(teacherId, assignmentId) {
    const hub = await examAttemptService.getAssignmentGradingHub(teacherId, assignmentId);
    const assignment = hub.assignment || {};
    const attempts = [...(hub.attempts || [])].sort((a, b) =>
      studentFromAttempt(a).name.localeCompare(studentFromAttempt(b).name, 'vi')
    );

    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'English for Community';
    workbook.created = new Date();

    const sheet = workbook.addWorksheet('Scores', {
      views: [{ state: 'frozen', ySplit: 5 }],
    });

    const title = assignment.examTitle || 'Assignment';
    const classroom = assignment.classroomName || '';
    const mode = assignment.mode || '';

    sheet.mergeCells('A1:J1');
    sheet.getCell('A1').value = title;
    sheet.getCell('A1').font = { bold: true, size: 14 };

    sheet.mergeCells('A2:J2');
    sheet.getCell('A2').value = [classroom, mode, assignment.examFormat].filter(Boolean).join(' · ');

    sheet.mergeCells('A3:J3');
    const stats = hub.stats || {};
    sheet.getCell('A3').value = `Submitted: ${stats.submitted ?? 0} · In progress: ${stats.inProgress ?? 0} · Needs grading: ${stats.pendingManual ?? 0}`;

    sheet.addRow([]);

    const headerRow = sheet.addRow([
      '#',
      'Student',
      'Email',
      'Status',
      'Grading',
      'Score',
      'Max',
      'Percent %',
      'Results released',
      'Started at (UTC)',
      'Submitted at (UTC)',
    ]);
    headerRow.font = { bold: true };
    headerRow.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FFE8F5F1' },
    };

    let i = 1;
    for (const att of attempts) {
      const r = rowFromAttempt(att, i);
      sheet.addRow([
        r.index,
        r.name,
        r.email,
        r.status,
        r.grading,
        r.score,
        r.max,
        r.percent,
        r.released,
        r.startedAt,
        r.submittedAt,
      ]);
      i += 1;
    }

    sheet.columns = [
      { width: 5 },
      { width: 28 },
      { width: 32 },
      { width: 14 },
      { width: 16 },
      { width: 10 },
      { width: 8 },
      { width: 12 },
      { width: 16 },
      { width: 22 },
      { width: 22 },
    ];

    const buffer = await workbook.xlsx.writeBuffer();
    const filename = `${sanitizeFilename(title)}-scores.xlsx`;

    return { buffer, filename, assignment };
  },
};
