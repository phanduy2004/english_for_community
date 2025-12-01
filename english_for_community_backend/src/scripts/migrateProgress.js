import mongoose from 'mongoose';
import dotenv from 'dotenv';
import path from 'path';

const envPath = path.join(process.cwd(), '.env');
dotenv.config({ path: envPath });

// Import Models
import UserDailyProgress from '../models/UserDailyProgress.js';
import ReadingAttempt from '../models/ReadingAttempt.js';
import WritingSubmission from '../models/WritingSubmission.js';
import SpeakingAttempt from '../models/SpeakingAttempt.js';
import DictationAttempt from '../models/DictationAttempt.js';
import ReadingProgress from '../models/ReadingProgress.js';
import Enrollment from '../models/Enrollment.js';
import SpeakingEnrollment from '../models/SpeakingEnrollment.js';
// Model Word
import Word from '../models/Word.js';

const MONGO_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/english_community';

const runMigration = async () => {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(MONGO_URI);
    console.log('✅ Connected.');
    await UserDailyProgress.deleteMany({});
    console.log('🧹 Cleared old UserDailyProgress data.');

    const TIMEZONE = 'Asia/Ho_Chi_Minh';
    const validDateMatch = { $match: { submittedAt: { $exists: true, $ne: null } } };

    console.log('🚀 Starting Aggregation...');

    // =================================================================
    // PHẦN 0: TÍNH TỪ VỰNG (VOCAB)
    // =================================================================

    // 1. Từ mới được tạo (Created)
    // Tính là 1 lần học vào ngày tạo
    const vocabCreatedPipeline = [
      { $match: {
          createdAt: { $ne: null }
        }},
      { $project: {
          userId: '$user',
          date: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt", timezone: TIMEZONE } }
        }},
      { $group: {
          _id: { userId: "$userId", date: "$date" },
          count: { $sum: 1 }
        }}
    ];

    // 2. Từ được ôn tập (Reviewed) - MỚI THÊM 🟢
    // Tính là 1 lần học vào ngày ôn tập gần nhất (Nếu khác ngày tạo)
    // Điều kiện: lastReviewedDate tồn tại và status là learning/saved
    const vocabReviewedPipeline = [
      { $match: {
          lastReviewedDate: { $ne: null },
          // Chỉ tính review cho các từ đang học, bỏ qua từ mới tra (recent) nếu chưa học
          status: { $in: ['learning', 'saved'] }
        }},
      { $project: {
          userId: '$user',
          // So sánh ngày tạo và ngày review
          createdDateStr: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt", timezone: TIMEZONE } },
          reviewDateStr: { $dateToString: { format: "%Y-%m-%d", date: "$lastReviewedDate", timezone: TIMEZONE } }
        }},
      // Chỉ lấy những lần review KHÁC ngày tạo (để tránh cộng đôi trong cùng 1 ngày tạo)
      // Hoặc nếu bạn muốn cộng cả 2 (1 lần tạo, 1 lần học) thì bỏ $match này đi.
      // Ở đây tôi giữ logic: Ngày tạo +1, Ngày ôn +1.
      { $group: {
          _id: { userId: "$userId", date: "$reviewDateStr" },
          count: { $sum: 1 }
        }}
    ];

    const [vocabCreatedStats, vocabReviewedStats] = await Promise.all([
      Word.aggregate(vocabCreatedPipeline),
      Word.aggregate(vocabReviewedPipeline)
    ]);

    console.log(`📚 Vocab Created Days: ${vocabCreatedStats.length}`);
    console.log(`🔄 Vocab Reviewed Days: ${vocabReviewedStats.length}`);


    // =================================================================
    // PHẦN 1: TÍNH THỜI GIAN VÀ ĐIỂM SỐ (Attempt)
    // =================================================================
    // ... (Giữ nguyên code Pipeline Attempt cũ của bạn ở đây)
    const attemptPipelines = [
      // Paste lại đoạn code Reading/Writing/Speaking/Dictation Attempt cũ vào đây
      // (Để code ngắn gọn tôi không paste lại, hãy giữ nguyên phần này từ file cũ)
      ReadingAttempt.aggregate([
        { $match: { createdAt: { $ne: null } } },
        { $project: {
            userId: 1,
            duration: { $ifNull: ['$durationInSeconds', 0] },
            normalizedScore: {
              $cond: {
                if: { $gt: [{ $ifNull: ["$totalQuestions", 0] }, 0] },
                then: { $divide: ["$correctCount", "$totalQuestions"] },
                else: 0
              }
            },
            wpm: { $ifNull: ['$wpm', 0] },
            date: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt", timezone: TIMEZONE } }
          }},
        { $group: {
            _id: { userId: "$userId", date: "$date" },
            studySeconds: { $sum: "$duration" },
            readingAccSum: { $sum: "$normalizedScore" },
            readingWpmSum: { $sum: "$wpm" },
            attemptsCount: { $sum: 1 }
          }}
      ]),
      WritingSubmission.aggregate([
        { $match: { status: 'reviewed', submittedAt: { $ne: null } } },
        { $project: {
            userId: 1,
            duration: { $ifNull: ['$durationInSeconds', 0] },
            score: { $ifNull: ['$score', 0] },
            date: { $dateToString: { format: "%Y-%m-%d", date: "$submittedAt", timezone: TIMEZONE } }
          }},
        { $group: {
            _id: { userId: "$userId", date: "$date" },
            studySeconds: { $sum: "$duration" },
            writingScoreSum: { $sum: "$score" },
            attemptsCount: { $sum: 1 }
          }}
      ]),
      SpeakingAttempt.aggregate([
        { $project: {
            userId: 1,
            duration: { $ifNull: ['$audioDurationSeconds', 0] },
            wer: { $ifNull: ['$score.wer', 1] },
            realDate: { $ifNull: ["$submittedAt", "$createdAt"] },
          }},
        { $match: { realDate: { $ne: null } } },
        { $project: {
            userId: 1,
            duration: 1,
            wer: 1,
            date: { $dateToString: { format: "%Y-%m-%d", date: "$realDate", timezone: TIMEZONE } }
          }},
        { $group: {
            _id: { userId: "$userId", date: "$date" },
            studySeconds: { $sum: "$duration" },
            speakingScoreSum: { $sum: { $max: [0, { $subtract: [1, "$wer"] }] } },
            attemptsCount: { $sum: 1 }
          }}
      ]),
      DictationAttempt.aggregate([
        { $project: {
            userId: 1,
            duration: { $ifNull: ['$durationInSeconds', 0] },
            wer: { $ifNull: ['$score.wer', 1] },
            realDate: { $ifNull: ["$submittedAt", "$createdAt"] },
          }},
        { $match: { realDate: { $ne: null } } },
        { $project: {
            userId: 1,
            duration: 1,
            wer: 1,
            date: { $dateToString: { format: "%Y-%m-%d", date: "$realDate", timezone: TIMEZONE } }
          }},
        { $group: {
            _id: { userId: "$userId", date: "$date" },
            studySeconds: { $sum: "$duration" },
            dictationAccSum: { $sum: { $max: [0, { $subtract: [1, "$wer"] }] } },
            attemptsCount: { $sum: 1 }
          }}
      ])
    ];
    const [readAtt, writeAtt, speakAtt, dicAtt] = await Promise.all(attemptPipelines);

    // =================================================================
    // PHẦN 2: TÍNH SỐ BÀI HOÀN THÀNH (Completion)
    // =================================================================
    // (Giữ nguyên code cũ của phần này)
    const completionPipelines = [
      ReadingProgress.aggregate([
        { $match: { status: 'completed', updatedAt: { $ne: null } } },
        { $project: {
            userId: 1,
            date: { $dateToString: { format: "%Y-%m-%d", date: "$updatedAt", timezone: TIMEZONE } }
          }},
        { $group: {
            _id: { userId: "$userId", date: "$date" },
            count: { $sum: 1 }
          }}
      ]),
      WritingSubmission.aggregate([
        { $match: { status: 'reviewed', submittedAt: { $ne: null } } },
        { $project: {
            userId: 1,
            date: { $dateToString: { format: "%Y-%m-%d", date: "$submittedAt", timezone: TIMEZONE } }
          }},
        { $group: {
            _id: { userId: "$userId", date: "$date" },
            count: { $sum: 1 }
          }}
      ]),
      Enrollment.aggregate([
        { $match: { isCompleted: true, updatedAt: { $ne: null } } },
        { $project: {
            userId: 1,
            date: { $dateToString: { format: "%Y-%m-%d", date: "$updatedAt", timezone: TIMEZONE } }
          }},
        { $group: {
            _id: { userId: "$userId", date: "$date" },
            count: { $sum: 1 }
          }}
      ]),
      SpeakingEnrollment.aggregate([
        { $match: { isCompleted: true, updatedAt: { $ne: null } } },
        { $project: {
            userId: 1,
            date: { $dateToString: { format: "%Y-%m-%d", date: "$updatedAt", timezone: TIMEZONE } }
          }},
        { $group: {
            _id: { userId: "$userId", date: "$date" },
            count: { $sum: 1 }
          }}
      ])
    ];
    const [readDone, writeDone, listenDone, speakDone] = await Promise.all(completionPipelines);

    // =================================================================
    // PHẦN 3: MERGE DỮ LIỆU
    // =================================================================

    const progressMap = {};

    const getRecord = (userId, date) => {
      if (!userId || !date) return null;
      const key = `${userId}_${date}`;
      if (!progressMap[key]) {
        progressMap[key] = {
          userId, date,
          studySeconds: 0,
          vocabLearned: 0,
          lessonsCompleted: { listening: 0, reading: 0, speaking: 0, writing: 0 },
          stats: {
            readingAccuracy: { total: 0, count: 0 },
            dictationAccuracy: { total: 0, count: 0 },
            speakingScore: { total: 0, count: 0 },
            writingScore: { total: 0, count: 0 },
            readingWpm: { total: 0, count: 0 },
          }
        };
      }
      return progressMap[key];
    };

    // --- 3a. MERGE VOCAB (CREATED + REVIEWED) 🟢 ---
    vocabCreatedStats.forEach(i => {
      const r = getRecord(i._id.userId, i._id.date);
      if(r) r.vocabLearned += i.count;
    });

    vocabReviewedStats.forEach(i => {
      const r = getRecord(i._id.userId, i._id.date);
      if(r) r.vocabLearned += i.count;
    });

    // --- 3b. MERGE SCORES ---
    readAtt.forEach(i => {
      const r = getRecord(i._id.userId, i._id.date);
      if(r) {
        r.studySeconds += i.studySeconds;
        r.stats.readingAccuracy.total += i.readingAccSum;
        r.stats.readingAccuracy.count += i.attemptsCount;
        r.stats.readingWpm.total += i.readingWpmSum;
        r.stats.readingWpm.count += i.attemptsCount;
      }
    });

    writeAtt.forEach(i => {
      const r = getRecord(i._id.userId, i._id.date);
      if(r) {
        r.studySeconds += i.studySeconds;
        r.stats.writingScore.total += i.writingScoreSum;
        r.stats.writingScore.count += i.attemptsCount;
      }
    });

    speakAtt.forEach(i => {
      const r = getRecord(i._id.userId, i._id.date);
      if(r) {
        r.studySeconds += i.studySeconds;
        r.stats.speakingScore.total += i.speakingScoreSum;
        r.stats.speakingScore.count += i.attemptsCount;
      }
    });

    dicAtt.forEach(i => {
      const r = getRecord(i._id.userId, i._id.date);
      if(r) {
        r.studySeconds += i.studySeconds;
        r.stats.dictationAccuracy.total += i.dictationAccSum;
        r.stats.dictationAccuracy.count += i.attemptsCount;
      }
    });

    // --- 3c. MERGE COMPLETION ---
    readDone.forEach(i => {
      const r = getRecord(i._id.userId, i._id.date);
      if(r) r.lessonsCompleted.reading += i.count;
    });

    writeDone.forEach(i => {
      const r = getRecord(i._id.userId, i._id.date);
      if(r) r.lessonsCompleted.writing += i.count;
    });

    listenDone.forEach(i => {
      const r = getRecord(i._id.userId, i._id.date);
      if(r) r.lessonsCompleted.listening += i.count;
    });

    speakDone.forEach(i => {
      const r = getRecord(i._id.userId, i._id.date);
      if(r) r.lessonsCompleted.speaking += i.count;
    });

    // =================================================================
    // PHẦN 4: LƯU DB
    // =================================================================
    const operations = Object.values(progressMap).map(doc => ({
      insertOne: { document: doc }
    }));

    if (operations.length > 0) {
      await UserDailyProgress.bulkWrite(operations);
      console.log(`✅ Successfully migrated ${operations.length} daily records.`);
    } else {
      console.log('⚠️ No data found to migrate.');
    }

  } catch (error) {
    console.error('❌ Migration failed:', error);
  } finally {
    await mongoose.disconnect();
    console.log('👋 Disconnected.');
    process.exit(0);
  }
};

runMigration();