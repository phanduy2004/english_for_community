// speaking.js
import mongoose from 'mongoose';
import SpeakingSet from '../models/SpeakingSet.js';

// --- Dữ liệu Speaking Sets ---
const speakingData = [
  // --- EXISTING SETS (COMPLETED) ---
  {
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
    "title": "Shopping for Clothes",
    "mode": "readAloud",
    "description": "Basic phrases for when you are at a clothing store looking for items.",
    "level": "Beginner",
    "sentences": [
      {
        "id": "sent_sc_01",
        "order": 1,
        "speaker": "You",
        "script": "Excuse me, could you help me? I'm looking for a jacket.",
        "phonetic_script": "ɪkˈskjuːs miː, kʊd juː hɛlp miː? aɪm ˈlʊkɪŋ fɔːr ə ˈdʒækɪt."
      },
      {
        "id": "sent_sc_02",
        "order": 2,
        "speaker": "Assistant",
        "script": "Of course. What size are you looking for?",
        "phonetic_script": "əv kɔːrs. wʌt saɪz ɑːr juː ˈlʊkɪŋ fɔːr?"
      },
      {
        "id": "sent_sc_03",
        "order": 3,
        "speaker": "You",
        "script": "I usually wear a medium. Do you have this one in blue?",
        "phonetic_script": "aɪ ˈjuːʒuəli wɛr ə ˈmiːdiəm. duː juː hæv ðɪs wʌn ɪn bluː?"
      },
      {
        "id": "sent_sc_04",
        "order": 4,
        "speaker": "Assistant",
        "script": "Yes, we do. The fitting rooms are over there if you want to try it on.",
        "phonetic_script": "jɛs, wiː duː. ðə ˈfɪtɪŋ ruːmz ɑːr ˈoʊvər ðɛr ɪf juː wɑːnt tuː traɪ ɪt ɑːn."
      },
      {
        "id": "sent_sc_05",
        "order": 5,
        "speaker": "You",
        "script": "Great, thank you. I will take it.",
        "phonetic_script": "ɡreɪt, θæŋk juː. aɪ wɪl teɪk ɪt."
      }
    ]
  },
  {
    "title": "Job Interview Basics",
    "mode": "readAloud",
    "description": "Practice answering common questions in a job interview confidently.",
    "level": "Intermediate",
    "sentences": [
      {
        "id": "sent_ji_01",
        "order": 1,
        "speaker": "Interviewer",
        "script": "Welcome. Can you start by telling me a little about yourself?",
        "phonetic_script": "ˈwɛlkəm. kæn juː stɑːrt baɪ ˈtɛlɪŋ miː ə ˈlɪtəl əˈbaʊt jɔːrˈsɛlf?"
      },
      {
        "id": "sent_ji_02",
        "order": 2,
        "speaker": "You",
        "script": "Sure. I have three years of experience in digital marketing.",
        "phonetic_script": "ʃʊr. aɪ hæv θriː jɪrz əv ɪkˈspɪriəns ɪn ˈdɪdʒɪtəl ˈmɑːrkɪtɪŋ."
      },
      {
        "id": "sent_ji_03",
        "order": 3,
        "speaker": "Interviewer",
        "script": "That is impressive. Why do you want to work for our company?",
        "phonetic_script": "ðæt ɪz ɪmˈprɛsɪv. waɪ duː juː wɑːnt tuː wɜːrk fɔːr ˈaʊər ˈkʌmpəni?"
      },
      {
        "id": "sent_ji_04",
        "order": 4,
        "speaker": "You",
        "script": "I admire your innovative approach and your company culture.",
        "phonetic_script": "aɪ ədˈmaɪər jɔːr ˈɪnəveɪtɪv əˈproʊtʃ ænd jɔːr ˈkʌmpəni ˈkʌltʃər."
      }
    ]
  },
  {
    "title": "Airport Check-in",
    "mode": "readAloud",
    "description": "Handle the check-in process and security questions at an airport.",
    "level": "Intermediate",
    "sentences": [
      {
        "id": "sent_ac_01",
        "order": 1,
        "speaker": "Agent",
        "script": "Good morning. May I see your passport and ticket, please?",
        "phonetic_script": "ɡʊd ˈmɔːrnɪŋ. meɪ aɪ siː jɔːr ˈpæspɔːrt ænd ˈtɪkɪt, pliːz?"
      },
      {
        "id": "sent_ac_02",
        "order": 2,
        "speaker": "You",
        "script": "Here you go. I have one bag to check in.",
        "phonetic_script": "hɪr juː ɡoʊ. aɪ hæv wʌn bæɡ tuː tʃɛk ɪn."
      },
      {
        "id": "sent_ac_03",
        "order": 3,
        "speaker": "Agent",
        "script": "Please place it on the scale. Would you prefer a window or an aisle seat?",
        "phonetic_script": "pliːz pleɪs ɪt ɑːn ðə skeɪl. wʊd juː prɪˈfɜːr ə ˈwɪndoʊ ɔːr ən aɪl siːt?"
      },
      {
        "id": "sent_ac_04",
        "order": 4,
        "speaker": "You",
        "script": "An aisle seat, please. I like to have some extra legroom.",
        "phonetic_script": "ən aɪl siːt, pliːz. aɪ laɪk tuː hæv sʌm ˈɛkstrə ˈlɛɡruːm."
      }
    ]
  },
  {
    "title": "Opening a Presentation",
    "mode": "readAloud",
    "description": "Learn powerful phrases to start a business presentation effectively.",
    "level": "Advanced",
    "sentences": [
      {
        "id": "sent_op_01",
        "order": 1,
        "speaker": "You",
        "script": "Good morning everyone, and thank you for joining me today.",
        "phonetic_script": "ɡʊd ˈmɔːrnɪŋ ˈɛvriwʌn, ænd θæŋk juː fɔːr ˈdʒɔɪnɪŋ miː təˈdeɪ."
      },
      {
        "id": "sent_op_02",
        "order": 2,
        "speaker": "You",
        "script": "Today, I would like to discuss the future of renewable energy.",
        "phonetic_script": "təˈdeɪ, aɪ wʊd laɪk tuː dɪˈskʌs ðə ˈfjuːtʃər əv rɪˈnuːəbəl ˈɛnərdʒi."
      },
      {
        "id": "sent_op_03",
        "order": 3,
        "speaker": "You",
        "script": "Let's start by looking at some surprising statistics from last year.",
        "phonetic_script": "lɛts stɑːrt baɪ ˈlʊkɪŋ æt sʌm sərˈpraɪzɪŋ stəˈtɪstɪks frʌm læst jɪr."
      },
      {
        "id": "sent_op_04",
        "order": 4,
        "speaker": "You",
        "script": "By the end of this talk, you will understand our new strategy.",
        "phonetic_script": "baɪ ði ɛnd əv ðɪs tɔːk, juː wɪl ˌʌndərˈstænd ˈaʊər nuː ˈstrætədʒi."
      }
    ]
  },
  {
    "title": "Negotiating a Deal",
    "mode": "readAloud",
    "description": "Key phrases for business negotiations and reaching an agreement.",
    "level": "Advanced",
    "sentences": [
      {
        "id": "sent_nd_01",
        "order": 1,
        "speaker": "You",
        "script": "We really like your proposal, but the price is a bit higher than our budget.",
        "phonetic_script": "wiː ˈrɪəli laɪk jɔːr prəˈpoʊzəl, bʌt ðə praɪs ɪz ə bɪt ˈhaɪər ðæn ˈaʊər ˈbʌdʒɪt."
      },
      {
        "id": "sent_nd_02",
        "order": 2,
        "speaker": "Partner",
        "script": "I understand. What price range were you thinking of?",
        "phonetic_script": "aɪ ˌʌndərˈstænd. wʌt praɪs reɪndʒ wɜːr juː ˈθɪŋkɪŋ ʌv?"
      },
      {
        "id": "sent_nd_03",
        "order": 3,
        "speaker": "You",
        "script": "If you can lower the cost by ten percent, we can sign the contract today.",
        "phonetic_script": "ɪf juː kæn ˈloʊər ðə kɔːst baɪ tɛn pərˈsɛnt, wiː kæn saɪn ðə ˈkɑːntrækt təˈdeɪ."
      },
      {
        "id": "sent_nd_04",
        "order": 4,
        "speaker": "Partner",
        "script": "That is a tough request, but I think we can find a compromise.",
        "phonetic_script": "ðæt ɪz ə tʌf rɪˈkwɛst, bʌt aɪ θɪŋk wiː kæn faɪnd ə ˈkɑːmprəmaɪz."
      }
    ]
  },

  // --- 5 NEW SETS ---
  {
    "title": "Checking into a Hotel",
    "mode": "readAloud",
    "description": "Essential conversation for checking into a hotel and asking about amenities.",
    "level": "Beginner",
    "sentences": [
      {
        "id": "sent_ht_01",
        "order": 1,
        "speaker": "You",
        "script": "Hello, I have a reservation under the name Smith.",
        "phonetic_script": "həˈloʊ, aɪ hæv ə ˌrɛzərˈveɪʃən ˈʌndər ðə neɪm smɪθ."
      },
      {
        "id": "sent_ht_02",
        "order": 2,
        "speaker": "Receptionist",
        "script": "Yes, I see it here. A double room for two nights.",
        "phonetic_script": "jɛs, aɪ siː ɪt hɪr. ə ˈdʌbəl ruːm fɔːr tuː naɪts."
      },
      {
        "id": "sent_ht_03",
        "order": 3,
        "speaker": "You",
        "script": "That is correct. Is breakfast included in the price?",
        "phonetic_script": "ðæt ɪz kəˈrɛkt. ɪz ˈbrɛkfəst ɪnˈkluːdɪd ɪn ðə praɪs?"
      },
      {
        "id": "sent_ht_04",
        "order": 4,
        "speaker": "Receptionist",
        "script": "Yes, it is served from six to ten in the morning.",
        "phonetic_script": "jɛs, ɪt ɪz sɜːrvd frʌm sɪks tuː tɛn ɪn ðə ˈmɔːrnɪŋ."
      }
    ]
  },
  {
    "title": "Asking for Directions",
    "mode": "readAloud",
    "description": "How to ask for help when you are lost in a new city.",
    "level": "Beginner",
    "sentences": [
      {
        "id": "sent_ad_01",
        "order": 1,
        "speaker": "You",
        "script": "Excuse me, do you know where the nearest subway station is?",
        "phonetic_script": "ɪkˈskjuːs miː, duː juː noʊ wɛr ðə ˈnɪrɪst ˈsʌbweɪ ˈsteɪʃən ɪz?"
      },
      {
        "id": "sent_ad_02",
        "order": 2,
        "speaker": "Stranger",
        "script": "Yes, go straight down this street and turn left at the bank.",
        "phonetic_script": "jɛs, ɡoʊ streɪt daʊn ðɪs striːt ænd tɜːrn lɛft æt ðə bæŋk."
      },
      {
        "id": "sent_ad_03",
        "order": 3,
        "speaker": "You",
        "script": "Is it far from here? Should I take a taxi?",
        "phonetic_script": "ɪz ɪt fɑːr frʌm hɪr? ʃʊd aɪ teɪk ə ˈtæksi?"
      },
      {
        "id": "sent_ad_04",
        "order": 4,
        "speaker": "Stranger",
        "script": "No, it is only a five-minute walk.",
        "phonetic_script": "noʊ, ɪt ɪz ˈoʊnli ə faɪv ˈmɪnɪt wɔːk."
      }
    ]
  },
  {
    "title": "Discussing Weekend Plans",
    "mode": "readAloud",
    "description": "Casual social conversation about hobbies and free time.",
    "level": "Intermediate",
    "sentences": [
      {
        "id": "sent_wp_01",
        "order": 1,
        "speaker": "Friend",
        "script": "So, do you have any exciting plans for the weekend?",
        "phonetic_script": "soʊ, duː juː hæv ˈɛni ɪkˈsaɪtɪŋ plænz fɔːr ðə ˈwiːkˌɛnd?"
      },
      {
        "id": "sent_wp_02",
        "order": 2,
        "speaker": "You",
        "script": "Not really. I was thinking of just catching up on some reading.",
        "phonetic_script": "nɑːt ˈrɪəli. aɪ wʌz ˈθɪŋkɪŋ əv dʒʌst ˈkætʃɪŋ ʌp ɑːn sʌm ˈriːdɪŋ."
      },
      {
        "id": "sent_wp_03",
        "order": 3,
        "speaker": "Friend",
        "script": "That sounds relaxing. I am going hiking on Saturday.",
        "phonetic_script": "ðæt saʊndz rɪˈlæksɪŋ. aɪ æm ˈɡoʊɪŋ ˈhaɪkɪŋ ɑːn ˈsætərdeɪ."
      },
      {
        "id": "sent_wp_04",
        "order": 4,
        "speaker": "You",
        "script": "Oh, I love hiking. I hope the weather stays nice for you.",
        "phonetic_script": "oʊ, aɪ lʌv ˈhaɪkɪŋ. aɪ hoʊp ðə ˈwɛðər steɪz naɪs fɔːr juː."
      }
    ]
  },
  {
    "title": "Expressing Opinions on Technology",
    "mode": "readAloud",
    "description": "Discussing the impact of AI and technology on daily life.",
    "level": "Advanced",
    "sentences": [
      {
        "id": "sent_et_01",
        "order": 1,
        "speaker": "Colleague",
        "script": "What do you think about the rapid development of artificial intelligence?",
        "phonetic_script": "wʌt duː juː θɪŋk əˈbaʊt ðə ˈræpɪd dɪˈvɛləpmənt əv ˌɑːrtɪˈfɪʃəl ɪnˈtɛlɪdʒəns?"
      },
      {
        "id": "sent_et_02",
        "order": 2,
        "speaker": "You",
        "script": "I believe it brings immense benefits, but we must be cautious.",
        "phonetic_script": "aɪ bɪˈliːv ɪt brɪŋz ɪˈmɛns ˈbɛnəfɪts, bʌt wiː mʌst biː ˈkɔːʃəs."
      },
      {
        "id": "sent_et_03",
        "order": 3,
        "speaker": "Colleague",
        "script": "True. Automation might replace many jobs in the near future.",
        "phonetic_script": "truː. ˌɔːtəˈmeɪʃən maɪt rɪˈpleɪs ˈmɛni dʒɑːbz ɪn ðə nɪr ˈfjuːtʃər."
      },
      {
        "id": "sent_et_04",
        "order": 4,
        "speaker": "You",
        "script": "Exactly. Therefore, adapting and learning new skills is essential.",
        "phonetic_script": "ɪɡˈzæktli. ðɛrˈfɔːr, əˈdæptɪŋ ænd ˈlɜːrnɪŋ nuː skɪlz ɪz ɪˈsɛnʃəl."
      }
    ]
  },
  {
    "title": "Apologizing for a Mistake",
    "mode": "readAloud",
    "description": "How to handle a professional mistake and offer a solution.",
    "level": "Intermediate",
    "sentences": [
      {
        "id": "sent_am_01",
        "order": 1,
        "speaker": "You",
        "script": "I realized I made an error in the report I sent yesterday.",
        "phonetic_script": "aɪ ˈriːəlaɪzd aɪ meɪd ən ˈɛrər ɪn ðə rɪˈpɔːrt aɪ sɛnt ˈjɛstərdeɪ."
      },
      {
        "id": "sent_am_02",
        "order": 2,
        "speaker": "Manager",
        "script": "Is it a major issue? How will it affect our presentation?",
        "phonetic_script": "ɪz ɪt ə ˈmeɪdʒər ˈɪʃuː? haʊ wɪl ɪt əˈfɛkt ˈaʊər ˌprɛzənˈteɪʃən?"
      },
      {
        "id": "sent_am_03",
        "order": 3,
        "speaker": "You",
        "script": "It was a calculation error. I have already corrected it and updated the file.",
        "phonetic_script": "ɪt wʌz ə ˌkælkjəˈleɪʃən ˈɛrər. aɪ hæv ɔːlˈrɛdi kəˈrɛktɪd ɪt ænd ʌpˈdeɪtɪd ðə faɪl."
      },
      {
        "id": "sent_am_04",
        "order": 4,
        "speaker": "Manager",
        "script": "Thank you for fixing it so quickly. Please be more careful next time.",
        "phonetic_script": "θæŋk juː fɔːr ˈfɪksɪŋ ɪt soʊ ˈkwɪkli. pliːz biː mɔːr ˈkɛrfəl nɛkst taɪm."
      }
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