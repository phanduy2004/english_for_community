/* eslint-disable no-console */
import dotenv from 'dotenv';
dotenv.config();
import mongoose from 'mongoose';
import path from 'path';
import { fileURLToPath } from 'url';

import ListeningComprehension from '../models/ListeningComprehension.js';
import { cloudinary } from '../config/cloudinary.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const MONGO = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/english_community';

// ——— DỮ LIỆU BÀI NGHE CHẤT LƯỢNG CAO (CHUẨN TOEIC PART 4) ———
const rawData = {
  title: "TechNova Corporate Orientation",
  summary: "Listen to the HR Director giving a welcome speech and explaining the schedule for new employees' first day.",

  // Transcript dài dặn, dùng đoạn này để copy vào ttsmp3.com tạo file audio nhé!
  transcript: "Good morning, everyone, and welcome to the annual orientation here at TechNova Solutions. My name is Sarah Jenkins, and I'm the Director of Human Resources. We are thrilled to have such a talented group of new hires joining our team today. Before we begin our facility tour at 10:00 AM, I want to go over a few important administrative details. First, please ensure you have picked up your employee ID badges from the front desk. You will need these to access the building, as well as the cafeteria on the second floor. Second, your IT setup sessions are scheduled for this afternoon. Please check the individualized schedules in your welcome packets to find your exact time slot. Finally, I'd like to remind everyone that our company-wide welcome luncheon will take place at 12:30 PM in the main conference room. This will be a great opportunity to meet your department heads and mingle with your new colleagues. If you have any questions during the day, don't hesitate to ask me or any of the HR staff members wearing blue lanyards. Now, if everyone is ready, let's head over to the main lobby to start our tour.",

  difficulty: "medium",
  minutesToComplete: 10,

  questions: [
    {
      questionText: "Who is the speaker?",
      options: [
        "A facility tour guide",
        "A senior software engineer",
        "The Director of Human Resources",
        "The Chief Executive Officer"
      ],
      correctAnswerIndex: 2,
      feedback: {
        reasoning: "The speaker introduces herself by saying: 'My name is Sarah Jenkins, and I'm the Director of Human Resources.'",
        hintTimestampSeconds: 7,
        keySentence: "My name is Sarah Jenkins, and I'm the Director of Human Resources."
      }
    },
    {
      questionText: "What must the listeners do before the tour begins?",
      options: [
        "Set up their computers",
        "Pick up their ID badges",
        "Meet their department heads",
        "Have lunch in the cafeteria"
      ],
      correctAnswerIndex: 1,
      feedback: {
        reasoning: "She explicitly instructs the attendees to pick up their badges before the tour: 'Before we begin our facility tour... please ensure you have picked up your employee ID badges.'",
        hintTimestampSeconds: 20,
        keySentence: "First, please ensure you have picked up your employee ID badges from the front desk."
      }
    },
    {
      questionText: "Where is the cafeteria located?",
      options: [
        "In the main lobby",
        "On the second floor",
        "In the main conference room",
        "At the front desk"
      ],
      correctAnswerIndex: 1,
      feedback: {
        reasoning: "When discussing the ID badges, she mentions they are needed to access 'the cafeteria on the second floor.'",
        hintTimestampSeconds: 28,
        keySentence: "You will need these to access the building, as well as the cafeteria on the second floor."
      }
    },
    {
      questionText: "What will happen at 12:30 PM?",
      options: [
        "A facility tour will begin",
        "An IT setup session will start",
        "A welcome luncheon will take place",
        "A staff meeting will be held"
      ],
      correctAnswerIndex: 2,
      feedback: {
        reasoning: "The speaker reminds everyone about a luncheon happening at that specific time.",
        hintTimestampSeconds: 43,
        keySentence: "Our company-wide welcome luncheon will take place at 12:30 PM in the main conference room."
      }
    },
    {
      questionText: "How can attendees identify the HR staff members?",
      options: [
        "By their blue lanyards",
        "By their ID badges",
        "By their company uniforms",
        "By the welcome packets they carry"
      ],
      correctAnswerIndex: 0,
      feedback: {
        reasoning: "She tells attendees to ask questions to 'any of the HR staff members wearing blue lanyards.'",
        hintTimestampSeconds: 58,
        keySentence: "Don't hesitate to ask me or any of the HR staff members wearing blue lanyards."
      }
    }
  ]
};

async function run() {
  await mongoose.connect(MONGO);
  console.log('🔗 Mongo Connected:', MONGO);

  try {
    // 1. Upload Audio lên Cloudinary
    // Yêu cầu: Bạn đã tạo file mp3 bằng Text-to-Speech và bỏ vào thư mục assets
    const localAudioPath = path.join(__dirname, 'assets', 'corporate_orientation.mp3');
    console.log(`⏳ Đang upload audio từ: ${localAudioPath}...`);

    const uploadResult = await cloudinary.uploader.upload(localAudioPath, {
      folder: 'english_community_audio',
      resource_type: 'video',
    });

    console.log('✅ Upload Audio thành công! URL:', uploadResult.secure_url);

    // 2. Dọn dẹp data cũ (upsert)
    await ListeningComprehension.deleteMany({ title: rawData.title });

    // 3. Insert dữ liệu vào MongoDB
    const newListening = await ListeningComprehension.create({
      ...rawData,
      audioUrl: uploadResult.secure_url,
    });

    console.log('🎉 Đã tạo Listening Comprehension thành công. ID:', newListening._id);
    console.log('👉 Tổng số câu hỏi:', newListening.totalQuestions);

  } catch (error) {
    console.error('❌ Lỗi quá trình Seed:', error);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Đã ngắt kết nối DB.');
  }
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});