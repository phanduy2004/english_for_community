import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  trendPct,
  fillSubmissionDays,
  dedupeLatestAttempts,
  shortStem,
  walkItemsWithSection,
  classifyStudentRisk,
  classifyOnTime,
  aggregateHardestItems,
  buildScoreDistribution,
  aggregateSkillAvg,
} from './teacherAnalyticsChartsService.js';
import { resolveWindow } from './teacherAnalyticsScope.js';

const DAY_MS = 24 * 60 * 60 * 1000;

describe('trendPct', () => {
  it('is 0 when both periods are 0 (no activity, no false alarm)', () => {
    assert.equal(trendPct(0, 0), 0);
  });
  it('is +100 when previous was 0 but current has activity', () => {
    assert.equal(trendPct(7, 0), 100);
  });
  it('computes a positive percentage growth', () => {
    assert.equal(trendPct(10, 5), 100);
  });
  it('computes a negative percentage drop', () => {
    assert.equal(trendPct(5, 10), -50);
  });
  it('rounds to one decimal place', () => {
    assert.equal(trendPct(1, 3), -66.7);
  });
});

describe('fillSubmissionDays', () => {
  const since = new Date('2026-07-01T00:00:00.000Z');

  it('produces exactly nDays consecutive entries', () => {
    const days = fillSubmissionDays(7, since, {});
    assert.equal(days.length, 7);
    assert.equal(days[0].date, '2026-07-01');
    assert.equal(days[6].date, '2026-07-07');
  });
  it('fills days with no submissions as 0', () => {
    const days = fillSubmissionDays(3, since, {});
    assert.deepEqual(days.map((d) => d.count), [0, 0, 0]);
  });
  it('maps counts onto the matching date and 0 elsewhere', () => {
    const days = fillSubmissionDays(3, since, { '2026-07-02': 5 });
    assert.deepEqual(days, [
      { date: '2026-07-01', count: 0 },
      { date: '2026-07-02', count: 5 },
      { date: '2026-07-03', count: 0 },
    ]);
  });
  it('sum of counts equals the total submissions in window', () => {
    const days = fillSubmissionDays(4, since, { '2026-07-01': 2, '2026-07-03': 3 });
    assert.equal(days.reduce((s, d) => s + d.count, 0), 5);
  });
});

describe('shortStem', () => {
  it('collapses whitespace and trims', () => {
    assert.equal(shortStem('  hello   world \n'), 'hello world');
  });
  it('returns empty string for nullish/blank input', () => {
    assert.equal(shortStem(null), '');
    assert.equal(shortStem('   '), '');
  });
  it('keeps text at or under the max length unchanged', () => {
    assert.equal(shortStem('short', 10), 'short');
  });
  it('truncates with an ellipsis past the max length', () => {
    const out = shortStem('abcdefghij', 5);
    assert.equal(out, 'abcd…');
    assert.equal(out.length, 5);
  });
});

describe('walkItemsWithSection', () => {
  it('returns [] for non-array input', () => {
    assert.deepEqual(walkItemsWithSection(null), []);
    assert.deepEqual(walkItemsWithSection(undefined), []);
  });
  it('flattens items and tags them with the section label (skill > title > kind)', () => {
    const out = walkItemsWithSection([
      { skill: 'grammar', items: [{ itemId: 'q1', kind: 'mcq_single' }] },
      { title: 'Part B', items: [{ itemId: 'q2', kind: 'fill_blank' }] },
    ]);
    assert.equal(out.length, 2);
    assert.equal(out[0]._section, 'grammar');
    assert.equal(out[1]._section, 'Part B');
  });
  it('includes nested items under reading/listening containers', () => {
    const out = walkItemsWithSection([
      {
        title: 'Reading 1',
        items: [
          {
            itemId: 'passage',
            kind: 'reading',
            nestedItems: [{ itemId: 'q1' }, { itemId: 'q2' }],
          },
        ],
      },
    ]);
    // container + 2 nested = 3
    assert.deepEqual(out.map((i) => i.itemId), ['passage', 'q1', 'q2']);
    assert.equal(out[1]._section, 'Reading 1');
  });
});

describe('classifyStudentRisk', () => {
  it('flags a student who was assigned work but submitted nothing', () => {
    const r = classifyStudentRisk({ assignedCount: 5, submittedCount: 0, avgPercent: null });
    assert.equal(r.reason, 'not_submitting');
    assert.equal(r.severity, 300);
  });
  it('does NOT flag a student with no assigned work as not-submitting', () => {
    const r = classifyStudentRisk({ assignedCount: 0, submittedCount: 0, avgPercent: null });
    assert.equal(r.reason, null);
  });
  it('flags a low average (< 50%)', () => {
    const r = classifyStudentRisk({ assignedCount: 5, submittedCount: 3, avgPercent: 40 });
    assert.equal(r.reason, 'low_score');
    assert.equal(r.severity, 210); // 200 + (50 - 40)
  });
  it('treats exactly 50% as NOT low (strict less-than boundary)', () => {
    const r = classifyStudentRisk({ assignedCount: 5, submittedCount: 3, avgPercent: 50 });
    assert.equal(r.reason, null);
  });
  it('flags frequently-late (>= 2 late) when average is fine', () => {
    const r = classifyStudentRisk({ assignedCount: 5, submittedCount: 5, avgPercent: 80, lateCount: 2 });
    assert.equal(r.reason, 'late');
    assert.equal(r.severity, 102);
  });
  it('does not flag a single late submission', () => {
    const r = classifyStudentRisk({ assignedCount: 5, submittedCount: 5, avgPercent: 80, lateCount: 1 });
    assert.equal(r.reason, null);
  });
  it('prioritises not-submitting over low-score and late', () => {
    const r = classifyStudentRisk({ assignedCount: 5, submittedCount: 0, avgPercent: 10, lateCount: 5 });
    assert.equal(r.reason, 'not_submitting');
  });
  it('low-score severity always outranks late severity', () => {
    const low = classifyStudentRisk({ assignedCount: 5, submittedCount: 2, avgPercent: 49, lateCount: 0 });
    const late = classifyStudentRisk({ assignedCount: 5, submittedCount: 5, avgPercent: 90, lateCount: 9 });
    assert.ok(low.severity > late.severity);
  });
});

describe('classifyOnTime', () => {
  const due = new Date('2026-07-10T00:00:00.000Z');
  it('is on-time when there is no due date', () => {
    assert.equal(classifyOnTime(new Date('2026-07-20'), null), 'onTime');
  });
  it('is on-time when there is no submission timestamp', () => {
    assert.equal(classifyOnTime(null, due), 'onTime');
  });
  it('is on-time when submitted before the due date', () => {
    assert.equal(classifyOnTime(new Date('2026-07-09T23:59:00Z'), due), 'onTime');
  });
  it('is on-time when submitted exactly at the due date', () => {
    assert.equal(classifyOnTime(new Date('2026-07-10T00:00:00Z'), due), 'onTime');
  });
  it('is late when submitted after the due date', () => {
    assert.equal(classifyOnTime(new Date('2026-07-10T00:01:00Z'), due), 'late');
  });
});

describe('aggregateHardestItems', () => {
  const meta = {
    a1: { q1: { stem: 'Present perfect vs past simple', tag: 'grammar' } },
    a2: { q1: { stem: 'Reading inference', tag: 'reading' } },
  };
  const getMeta = (aid, itemId) => meta[aid]?.[itemId];

  const attempt = (aid, items) => ({ assignmentId: aid, scores: { items } });

  it('computes % of points earned and sorts ascending (hardest first)', () => {
    const rows = aggregateHardestItems(
      [
        attempt('a1', { q1: { maxPoints: 1, awardedPoints: 0, status: 'finalized' } }),
        attempt('a1', { q1: { maxPoints: 1, awardedPoints: 1, status: 'finalized' } }),
        attempt('a1', { q1: { maxPoints: 1, awardedPoints: 0, status: 'finalized' } }),
        attempt('a2', { q1: { maxPoints: 1, awardedPoints: 1, status: 'finalized' } }),
        attempt('a2', { q1: { maxPoints: 1, awardedPoints: 1, status: 'finalized' } }),
        attempt('a2', { q1: { maxPoints: 1, awardedPoints: 1, status: 'finalized' } }),
      ],
      getMeta
    );
    assert.equal(rows.length, 2);
    assert.equal(rows[0].label, 'Present perfect vs past simple'); // 1/3 = 33.3% hardest
    assert.equal(rows[0].pctCorrect, 33.3);
    assert.equal(rows[0].attempts, 3);
    assert.equal(rows[0].tag, 'grammar');
    assert.equal(rows[1].pctCorrect, 100); // a2 easy
  });

  it('excludes ungraded manual questions (pending_manual / pending_ai)', () => {
    const rows = aggregateHardestItems(
      [
        attempt('a1', { q1: { maxPoints: 5, awardedPoints: 0, status: 'pending_manual' } }),
        attempt('a1', { q1: { maxPoints: 5, awardedPoints: 0, status: 'pending_ai' } }),
        attempt('a1', { q1: { maxPoints: 5, awardedPoints: 0, status: 'pending_manual' } }),
      ],
      getMeta
    );
    assert.deepEqual(rows, []); // nothing graded → no false "0% hardest"
  });

  it('requires a minimum number of responses to be meaningful', () => {
    const rows = aggregateHardestItems(
      [
        attempt('a1', { q1: { maxPoints: 1, awardedPoints: 0, status: 'finalized' } }),
        attempt('a1', { q1: { maxPoints: 1, awardedPoints: 0, status: 'finalized' } }),
      ],
      getMeta,
      { minResponses: 3 }
    );
    assert.deepEqual(rows, []); // only 2 responses < 3
  });

  it('ignores items with non-positive max points', () => {
    const rows = aggregateHardestItems(
      [
        attempt('a1', { q1: { maxPoints: 0, awardedPoints: 0, status: 'finalized' } }),
        attempt('a1', { q1: { maxPoints: 0, awardedPoints: 0, status: 'finalized' } }),
        attempt('a1', { q1: { maxPoints: 0, awardedPoints: 0, status: 'finalized' } }),
      ],
      getMeta
    );
    assert.deepEqual(rows, []);
  });

  it('clamps awarded points into [0, max] before averaging', () => {
    const rows = aggregateHardestItems(
      [
        attempt('a1', { q1: { maxPoints: 2, awardedPoints: 5, status: 'finalized' } }), // clamp→2
        attempt('a1', { q1: { maxPoints: 2, awardedPoints: -3, status: 'finalized' } }), // clamp→0
        attempt('a1', { q1: { maxPoints: 2, awardedPoints: 1, status: 'finalized' } }),
      ],
      getMeta
    );
    // (2 + 0 + 1) / (2*3) = 3/6 = 50%
    assert.equal(rows[0].pctCorrect, 50);
  });

  it('keeps the same itemId in different assignments as separate questions', () => {
    const rows = aggregateHardestItems(
      [
        attempt('a1', { q1: { maxPoints: 1, awardedPoints: 0, status: 'finalized' } }),
        attempt('a1', { q1: { maxPoints: 1, awardedPoints: 0, status: 'finalized' } }),
        attempt('a1', { q1: { maxPoints: 1, awardedPoints: 0, status: 'finalized' } }),
        attempt('a2', { q1: { maxPoints: 1, awardedPoints: 1, status: 'finalized' } }),
        attempt('a2', { q1: { maxPoints: 1, awardedPoints: 1, status: 'finalized' } }),
        attempt('a2', { q1: { maxPoints: 1, awardedPoints: 1, status: 'finalized' } }),
      ],
      getMeta
    );
    assert.equal(rows.length, 2);
  });

  it('falls back to a #id label when the question stem is unknown', () => {
    const rows = aggregateHardestItems(
      [
        attempt('a9', { longid1234: { maxPoints: 1, awardedPoints: 0, status: 'finalized' } }),
        attempt('a9', { longid1234: { maxPoints: 1, awardedPoints: 0, status: 'finalized' } }),
        attempt('a9', { longid1234: { maxPoints: 1, awardedPoints: 0, status: 'finalized' } }),
      ],
      () => undefined
    );
    assert.equal(rows[0].label, '#1234');
  });

  it('caps the result to the requested limit', () => {
    const attempts = [];
    for (let q = 0; q < 10; q++) {
      for (let n = 0; n < 3; n++) {
        attempts.push(attempt('a1', { [`q${q}`]: { maxPoints: 1, awardedPoints: 0, status: 'finalized' } }));
      }
    }
    const rows = aggregateHardestItems(attempts, () => undefined, { limit: 6 });
    assert.equal(rows.length, 6);
  });
});

describe('buildScoreDistribution', () => {
  it('prefers integrated 0–10 buckets when present, filling gaps with 0', () => {
    const dist = buildScoreDistribution(
      [
        { _id: 0, count: 3 },
        { _id: 4, count: 87 },
      ],
      [{ _id: 0, count: 999 }]
    );
    assert.deepEqual(dist, [
      { range: '0–2', count: 3 },
      { range: '2–4', count: 0 },
      { range: '4–6', count: 0 },
      { range: '6–8', count: 0 },
      { range: '8–10', count: 87 },
    ]);
  });
  it('falls back to legacy percentage buckets when no integrated data', () => {
    const dist = buildScoreDistribution(
      [],
      [
        { _id: 0, count: 2 },
        { _id: 50, count: 5 },
        { _id: 85, count: 10 },
      ]
    );
    assert.deepEqual(dist, [
      { range: '<50%', count: 2 },
      { range: '50–70%', count: 5 },
      { range: '≥85%', count: 10 },
    ]);
  });
  it('handles empty inputs without throwing', () => {
    assert.deepEqual(buildScoreDistribution([], []), []);
    assert.deepEqual(buildScoreDistribution(null, null), []);
  });
});

describe('aggregateSkillAvg', () => {
  const withSkills = (skillScores) => ({ scores: { skillScores } });

  it('averages only finalized, non-null skill scores and rounds to 1 dp', () => {
    const avg = aggregateSkillAvg([
      withSkills({ listening: { score: 8, status: 'finalized' } }),
      withSkills({ listening: { score: 7, status: 'finalized' } }),
    ]);
    assert.equal(avg.listening, 7.5);
  });
  it('ignores pending / no_content / null skill entries', () => {
    const avg = aggregateSkillAvg([
      withSkills({ writing: { score: null, status: 'pending_ai' } }),
      withSkills({ writing: { score: 5, status: 'no_content' } }),
      withSkills({ writing: { score: 6, status: 'finalized' } }),
    ]);
    assert.equal(avg.writing, 6); // only the finalized 6 counts
  });
  it('omits skills that have no finalized data at all', () => {
    const avg = aggregateSkillAvg([withSkills({ reading: { score: 7, status: 'finalized' } })]);
    assert.equal(avg.reading, 7);
    assert.ok(!('speaking' in avg));
  });
  it('counts finalized zeros toward the average', () => {
    const avg = aggregateSkillAvg([
      withSkills({ grammar: { score: 0, status: 'finalized' } }),
      withSkills({ grammar: { score: 10, status: 'finalized' } }),
    ]);
    assert.equal(avg.grammar, 5);
  });
  it('returns an empty object when there is no skill data', () => {
    assert.deepEqual(aggregateSkillAvg([]), {});
    assert.deepEqual(aggregateSkillAvg(null), {});
  });
});

// A light integration-style check that the exported pieces compose the way getCharts uses them.
describe('composition sanity', () => {
  it('fillSubmissionDays total feeds trendPct consistently', () => {
    const since = new Date(Date.now() - 3 * DAY_MS);
    const days = fillSubmissionDays(3, since, {});
    const current = days.reduce((s, d) => s + d.count, 0);
    assert.equal(trendPct(current, 0), 0); // no current, no prev → 0, not 100
  });
});

describe('resolveWindow — cửa sổ N ngày VN, GỒM hôm nay (fix #1/#2)', () => {
  const nowMs = Date.UTC(2026, 6, 12, 3, 0, 0); // 2026-07-12 10:00 giờ VN

  it('window 7 ngày phủ đúng 7 ngày VN, ngày cuối là HÔM NAY', () => {
    const { since } = resolveWindow(nowMs, 7);
    const days = fillSubmissionDays(7, since, {});
    assert.equal(days.length, 7);
    assert.equal(days[0].date, '2026-07-06');
    assert.equal(days[6].date, '2026-07-12'); // hôm nay được tính (trước đây bị rớt)
  });

  it('bài nộp HÔM NAY nằm trong [since, now]', () => {
    const { since } = resolveWindow(nowMs, 7);
    const todaySubmit = Date.UTC(2026, 6, 12, 2, 0, 0); // 09:00 VN hôm nay
    assert.ok(since.getTime() <= todaySubmit && todaySubmit <= nowMs);
  });

  it('bài nộp buổi tối VN gom đúng ngày VN, không lệch sang hôm trước', () => {
    // 2026-07-12 23:30 VN = 2026-07-12T16:30Z. Key VN phải là '2026-07-12'.
    const eveningVn = Date.UTC(2026, 6, 12, 16, 30, 0);
    const { since } = resolveWindow(nowMs, 7);
    const days = fillSubmissionDays(7, since, { '2026-07-12': 1 });
    assert.equal(days[6].date, '2026-07-12');
    assert.equal(days[6].count, 1);
    assert.ok(eveningVn <= Date.UTC(2026, 6, 12, 17, 0, 0)); // vẫn thuộc ngày VN 07-12
  });

  it('kỳ trước cách N ngày, cùng độ dài', () => {
    const { since, prevSince } = resolveWindow(nowMs, 7);
    assert.equal(since.getTime() - prevSince.getTime(), 7 * DAY_MS);
  });

  it('window 30 ngày cũng kết thúc hôm nay', () => {
    const { since } = resolveWindow(nowMs, 30);
    const days = fillSubmissionDays(30, since, {});
    assert.equal(days.length, 30);
    assert.equal(days[29].date, '2026-07-12');
  });
});

describe('dedupeLatestAttempts — chống đếm trùng khi nộp lại (fix #3)', () => {
  it('giữ attempt MỚI NHẤT cho mỗi (student, assignment)', () => {
    const out = dedupeLatestAttempts([
      { userId: 'u1', assignmentId: 'a1', submittedAt: '2026-07-01T00:00:00Z' },
      { userId: 'u1', assignmentId: 'a1', submittedAt: '2026-07-05T00:00:00Z' }, // mới hơn
      { userId: 'u1', assignmentId: 'a2', submittedAt: '2026-07-02T00:00:00Z' },
      { userId: 'u2', assignmentId: 'a1', submittedAt: '2026-07-03T00:00:00Z' },
    ]);
    assert.equal(out.length, 3); // (u1,a1) gộp 1; (u1,a2); (u2,a1)
    const u1a1 = out.find((a) => a.userId === 'u1' && a.assignmentId === 'a1');
    assert.equal(u1a1.submittedAt, '2026-07-05T00:00:00Z');
  });

  it('input rỗng / null trả []', () => {
    assert.deepEqual(dedupeLatestAttempts([]), []);
    assert.deepEqual(dedupeLatestAttempts(null), []);
  });
});
