import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { aggregateProgressRecords } from './progressService.js';

// Dựng 1 bản ghi UserDailyProgress tối giản. `over` ghi đè field cần test.
const rec = (date, over = {}) => ({
  date,
  studySeconds: 0,
  vocabLearned: 0,
  lessonsCompleted: {},
  stats: {},
  ...over,
});

// stat = { total, count } — total là TỔNG điểm cộng dồn, count là số lần.
const stat = (total, count) => ({ total, count });

const TODAY = '2026-07-11';
const bounds = (startDateString, todayString = TODAY) => ({ startDateString, todayString });

describe('aggregateProgressRecords — trung bình có trọng số (không phải avg-of-avgs)', () => {
  it('gộp total/count qua nhiều ngày rồi mới chia', () => {
    // Ngày 1: 1 lần điểm 0.8 → total 0.8, count 1
    // Ngày 2: 2 lần tổng 1.2 (tb 0.6) → total 1.2, count 2
    // Weighted = (0.8+1.2)/(1+2) = 0.6667 → *100 → round → 67
    // (avg-of-avgs sai sẽ ra (0.8+0.6)/2 = 0.70 → 70)
    const records = [
      rec('2026-07-10', { stats: { readingAccuracy: stat(0.8, 1) } }),
      rec('2026-07-11', { stats: { readingAccuracy: stat(1.2, 2) } }),
    ];
    const { statsGrid } = aggregateProgressRecords(records, bounds('2026-07-01'));
    assert.equal(statsGrid.readingAccuracy, 67);
  });
});

describe('aggregateProgressRecords — đơn vị từng card', () => {
  it('reading/dictation/speaking: 0..1 → phần trăm (*100)', () => {
    const records = [
      rec(TODAY, {
        stats: {
          readingAccuracy: stat(0.9, 1), // 90%
          dictationAccuracy: stat(0.75, 1), // 75%
          speakingScore: stat(0.42, 1), // 42%
        },
      }),
    ];
    const { statsGrid } = aggregateProgressRecords(records, bounds('2026-07-01'));
    assert.equal(statsGrid.readingAccuracy, 90);
    assert.equal(statsGrid.dictationAccuracy, 75);
    assert.equal(statsGrid.speakingAccuracy, 42);
  });

  it('writing: giữ nguyên band 0..9, làm tròn 1 chữ số (KHÔNG *100)', () => {
    // 2 bài band 6 và 7 → tb 6.5
    const records = [
      rec(TODAY, { stats: { writingScore: stat(13, 2) } }),
    ];
    const { statsGrid } = aggregateProgressRecords(records, bounds('2026-07-01'));
    assert.equal(statsGrid.avgWritingScore, 6.5);
    // Không bao giờ vượt thang 9 kiểu bị *100
    assert.ok(statsGrid.avgWritingScore <= 9);
  });

  it('readingWpm: trung bình thô, làm tròn số nguyên', () => {
    const records = [
      rec(TODAY, { stats: { readingWpm: stat(250, 2) } }), // tb 125
    ];
    const { statsGrid } = aggregateProgressRecords(records, bounds('2026-07-01'));
    assert.equal(statsGrid.readingWpm, 125);
  });
});

describe('aggregateProgressRecords — không có dữ liệu / count = 0', () => {
  it('records rỗng → mọi card = 0, không NaN', () => {
    const { statsGrid } = aggregateProgressRecords([], bounds('2026-07-01'));
    assert.deepEqual(statsGrid, {
      vocabLearned: 0,
      lessonsCompleted: 0,
      readingAccuracy: 0,
      dictationAccuracy: 0,
      speakingAccuracy: 0,
      speakingFluency: 0,
      avgWritingScore: 0,
      readingWpm: 0,
    });
    for (const v of Object.values(statsGrid)) {
      assert.ok(!Number.isNaN(v), 'không được NaN');
    }
  });

  it('stat có total nhưng count = 0 → bị bỏ qua (guard ?.count)', () => {
    const records = [
      rec(TODAY, { stats: { readingAccuracy: { total: 5, count: 0 } } }),
    ];
    const { statsGrid } = aggregateProgressRecords(records, bounds('2026-07-01'));
    assert.equal(statsGrid.readingAccuracy, 0);
  });
});

describe('aggregateProgressRecords — lọc theo range (rec.date >= startDateString)', () => {
  it('bỏ qua bản ghi trước mốc range dù nằm trong mảng', () => {
    const records = [
      // Trước range: điểm cao, KHÔNG được tính
      rec('2026-06-30', { vocabLearned: 999, stats: { readingAccuracy: stat(1, 5) } }),
      // Trong range
      rec('2026-07-05', { vocabLearned: 3, stats: { readingAccuracy: stat(0.5, 1) } }),
    ];
    const { statsGrid } = aggregateProgressRecords(records, bounds('2026-07-01'));
    assert.equal(statsGrid.vocabLearned, 3); // 999 bị loại
    assert.equal(statsGrid.readingAccuracy, 50); // chỉ 0.5
  });

  it("range 'day' (startDateString = today) chỉ tính hôm nay cho stats", () => {
    const records = [
      rec('2026-07-10', { studySeconds: 600, stats: { readingAccuracy: stat(1, 1) } }),
      rec(TODAY, { studySeconds: 300, stats: { readingAccuracy: stat(0.4, 1) } }),
    ];
    const { statsGrid, todayMinutes } = aggregateProgressRecords(records, bounds(TODAY, TODAY));
    assert.equal(statsGrid.readingAccuracy, 40); // hôm qua (100%) bị loại
    assert.equal(todayMinutes, 5); // 300s → 5 phút
  });
});

describe('aggregateProgressRecords — vocab & lessons cộng dồn', () => {
  it('vocabLearned cộng dồn qua các ngày', () => {
    const records = [
      rec('2026-07-09', { vocabLearned: 4 }),
      rec('2026-07-10', { vocabLearned: 6 }),
    ];
    const { statsGrid } = aggregateProgressRecords(records, bounds('2026-07-01'));
    assert.equal(statsGrid.vocabLearned, 10);
  });

  it('lessonsCompleted = tổng 4 kỹ năng con', () => {
    const records = [
      rec('2026-07-10', {
        lessonsCompleted: { listening: 1, reading: 2, speaking: 0, writing: 3 },
      }),
      rec('2026-07-11', { lessonsCompleted: { reading: 1 } }),
    ];
    const { statsGrid } = aggregateProgressRecords(records, bounds('2026-07-01'));
    assert.equal(statsGrid.lessonsCompleted, 7); // 1+2+0+3 + 1
  });
});

describe('aggregateProgressRecords — thời gian học', () => {
  it('totalSecondsInRange cộng dồn trong range; todayMinutes theo todayString', () => {
    const records = [
      rec('2026-07-10', { studySeconds: 1200 }),
      rec(TODAY, { studySeconds: 900 }),
    ];
    const { totalSecondsInRange, todayMinutes } = aggregateProgressRecords(
      records,
      bounds('2026-07-01'),
    );
    assert.equal(totalSecondsInRange, 2100);
    assert.equal(todayMinutes, 15); // 900s
  });
});

describe('aggregateProgressRecords — speaking: card gộp cả 2 bucket (F1)', () => {
  // Sau F1: speakingAccuracy = trung bình có trọng số của (speakingScore ∪ speakingFluency).
  it('gộp speaking-set (1-WER) + free-speaking (overall/9) vào 1 %', () => {
    const records = [
      rec(TODAY, {
        stats: {
          speakingScore: stat(0.6, 1), // speaking-set
          speakingFluency: stat(0.8, 1), // free-speaking
        },
      }),
    ];
    const { statsGrid } = aggregateProgressRecords(records, bounds('2026-07-01'));
    // (0.6 + 0.8) / (1 + 1) = 0.7 → 70
    assert.equal(statsGrid.speakingAccuracy, 70);
    assert.equal(statsGrid.speakingFluency, 80); // bucket vẫn được trả (backward-compat)
  });

  it('chỉ free-speaking cũng tính vào Speaking % (KHÔNG còn 0%)', () => {
    const records = [
      rec(TODAY, { stats: { speakingFluency: stat(0.85, 1) } }),
    ];
    const { statsGrid } = aggregateProgressRecords(records, bounds('2026-07-01'));
    assert.equal(statsGrid.speakingAccuracy, 85); // trước F1 là 0
    assert.equal(statsGrid.speakingFluency, 85);
  });
});
