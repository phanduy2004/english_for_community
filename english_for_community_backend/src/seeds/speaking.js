// (File seed.js của bạn)
import mongoose from 'mongoose';
import SpeakingSet from '../models/SpeakingSet.js'; // Import model đã sửa ở trên

// --- Dữ liệu Speaking Sets ---
const speakingData = [
  {
    // "id": "set_restaurant_order", // ⬅️ ĐÃ XÓA
    "title": "Ordering at a Restaurant",
    "mode": "readAloud",
    "description": "Practice a typical conversation when ordering food at a restaurant.",
    "level": "Beginner",
    "sentences": [
      {
        "id": "sent_ro_01",
        "order": 1,
        "speaker": "Waiter",
        "script": "Hello, are you ready to order, or do you need a few more minutes?",
        "phonetic_script": "həˈloʊ, ɑːr juː ˈrɛdi tuː ˈɔːrdər, ɔːr duː juː niːd ə fjuː mɔːr ˈmɪnɪts?"
      },
      {
        "id": "sent_ro_02",
        "order": 2,
        "speaker": "You",
        "script": "I'm ready. I would like to have the grilled chicken salad, please.",
        "phonetic_script": "aɪm ˈrɛdi. aɪ wʊd laɪk tuː hæv ðə ɡrɪld ˈtʃɪkən ˈsæləd, pliːz."
      },
      {
        "id": "sent_ro_03",
        "order": 3,
        "speaker": "Waiter",
        "script": "Excellent choice. And what would you like to drink?",
        "phonetic_script": "ˈɛksələnt tʃɔɪs. ænd wʌt wʊd juː laɪk tuː drɪŋk?"
      },
      {
        "id": "sent_ro_04",
        "order": 4,
        "speaker": "You",
        "script": "Just a glass of water for me, thank you.",
        "phonetic_script": "dʒʌst ə ɡlæs əv ˈwɔːtər fɔːr miː, θæŋk juː."
      },
      {
        "id": "sent_ro_05",
        "order": 5,
        "speaker": "Waiter",
        "script": "Certainly. I'll get that for you right away.",
        "phonetic_script": "ˈsɜːrtənli. aɪl ɡɛt ðæt fɔːr juː raɪt əˈweɪ."
      }
    ]
  },
  {
    // "id": "set_shopping_clothes", // ⬅️ ĐÃ XÓA
    "title": "Shopping for Clothes",
    "mode": "readAloud",
    "description": "Basic phrases for when you are at a clothing store.",
    "level": "Beginner",
    "sentences": [
      {
        "id": "sent_sc_01",
        "order": 1,
        "speaker": "You",
        "script": "Excuse me, could you help me? I'm looking for a jacket.",
        "phonetic_script": "ɪkˈskjuːs miː, kʊd juː hɛlp miː? aɪm ˈlʊkɪŋ fɔːr ə ˈdʒækɪt."
      },
      // ... (các sentences khác)
    ]
  },
  {
    // "id": "set_job_interview", // ⬅️ ĐÃ XÓA
    "title": "Job Interview Basics",
    "mode": "readAloud",
    "description": "Practice answering common questions in a job interview.",
    "level": "Intermediate",
    "sentences": [
      // ...
    ]
  },
  {
    // "id": "set_airport_checkin", // ⬅️ ĐÃ XÓA
    "title": "Airport Check-in",
    "mode": "readAloud",
    "description": "Handle the check-in process and security questions at an airport.",
    "level": "Intermediate",
    "sentences": [
      // ...
    ]
  },
  {
    // "id": "set_presentation_opening", // ⬅️ ĐÃ XÓA
    "title": "Opening a Presentation",
    "mode": "readAloud",
    "description": "Learn powerful phrases to start a business presentation effectively.",
    "level": "Advanced",
    "sentences": [
      // ...
    ]
  },
  {
    // "id": "set_negotiating_deal", // ⬅️ ĐÃ XÓA
    "title": "Negotiating a Deal",
    "mode": "readAloud",
    "description": "Key phrases for business negotiations and reaching an agreement.",
    "level": "Advanced",
    "sentences": [
      // ...
    ]
  }
];

// --- Cấu hình kết nối ---
const MONGO_URI =  process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/english_community';

// --- Hàm Seed Database ---
const seedDatabase = async () => {
  const speakingSets = speakingData;
  if (!speakingSets || speakingSets.length === 0) {
    console.log('Không tìm thấy dữ liệu để seed.');
    return;
  }
  try {
    console.log(`Đang kết nối tới ${MONGO_URI}...`);
    await mongoose.connect(MONGO_URI);
    console.log('Kết nối MongoDB thành công.');

    // 1. Xóa dữ liệu cũ
    console.log('Đang xóa dữ liệu cũ (SpeakingSet)...');
    await SpeakingSet.deleteMany({});
    console.log('Đã xóa dữ liệu cũ.');

    // 2. Chèn dữ liệu mới
    console.log(`Đang chèn ${speakingSets.length} speaking sets...`);
    await SpeakingSet.insertMany(speakingSets);
    console.log('Đã seed dữ liệu thành công!');

  } catch (error) {
    console.error('Lỗi trong quá trình seed database:', error);
  } finally {
    // 3. Đóng kết nối
    console.log('Đang đóng kết nối...');
    await mongoose.connection.close();
    console.log('Đã đóng kết nối MongoDB.');
  }
};

// --- Chạy hàm seed ---
seedDatabase();