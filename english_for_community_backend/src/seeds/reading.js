import mongoose from 'mongoose';
import Reading from '../models/Reading.js';

const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/english_community';

const readingsData = [
  {
    title: "The Future of Renewable Energy",
    summary: "A look at solar, wind, and geothermal power, their benefits, and challenges like intermittency.",
    minutesToRead: 2,
    content: "Renewable energy is derived from natural sources that are replenished at a higher rate than they are consumed. Sunlight and wind, for example, are such sources that are constantly being replenished. Renewable energy sources are abundant and all around us.\n\nSolar power is one of the most popular forms. It involves converting sunlight into electricity, either directly using photovoltaics (PV), or indirectly using concentrated solar power. Wind power is another major player, harnessing the power of wind to turn turbines and generate electricity. The main challenge for solar and wind is their intermittency—they don't produce power when the sun isn't shining or the wind isn't blowing. This necessitates efficient battery storage technologies.\n\nGeothermal energy, on the other hand, taps into the Earth's internal heat. Unlike solar and wind, it is a stable and consistent source of energy, available 24/7. Developing these technologies is crucial for reducing our reliance on fossil fuels and combating climate change.",
    // 💡 DỊCH
    translation: {
      title: "Tương lai của Năng lượng Tái tạo",
      content: "Năng lượng tái tạo có nguồn gốc từ các nguồn tự nhiên được bổ sung với tốc độ nhanh hơn mức chúng được tiêu thụ. Ví dụ, ánh sáng mặt trời và gió là những nguồn liên tục được bổ sung. Các nguồn năng lượng tái tạo rất dồi dào và ở xung quanh chúng ta.\n\nNăng lượng mặt trời là một trong những dạng phổ biến nhất. Nó bao gồm việc chuyển đổi ánh sáng mặt trời thành điện năng, trực tiếp bằng quang điện (PV) hoặc gián tiếp bằng năng lượng mặt trời tập trung. Năng lượng gió là một nhân tố chính khác, khai thác sức mạnh của gió để quay tuabin và tạo ra điện. Thách thức chính đối vớI năng lượng mặt trời và gió là tính không liên tục—chúng không tạo ra điện khi mặt trời không chiếu sáng hoặc gió không thổi. Điều này đòi hỏi các công nghệ lưu trữ pin hiệu quả.\n\nMặt khác, năng lượng địa nhiệt khai thác nhiệt bên trong Trái đất. Không giống như năng lượng mặt trời và gió, nó là một nguồn năng lượng ổn định và nhất quán, có sẵn 24/7. Phát triển các công nghệ này là rất quan trọng để giảm sự phụ thuộc của chúng ta vào nhiên liệu hóa thạch và chống biến đổi khí hậu."
    },
    difficulty: "medium",
    imageUrl: "https://example.com/images/solar_panels.png",
    questions: [
      {
        questionText: "What is the primary challenge mentioned for solar and wind power?",
        options: [ "They are too expensive.", "They are not powerful enough.", "Their intermittency (not always available).", "They are difficult to install."],
        correctAnswerIndex: 2,
        feedback: {
          reasoning: "The text explicitly points out the main difficulty for solar and wind is their dependency on environmental conditions.",
          paragraphIndex: 1,
          keySentence: "The main challenge for solar and wind is their intermittency..."
        },
        translation: {
          questionText: "Thách thức chính được đề cập cho năng lượng mặt trời và gió là gì?",
          options: ["Chúng quá đắt.", "Chúng không đủ mạnh.", "Tính không liên tục (không phải lúc nào cũng có sẵn).", "Chúng khó lắp đặt."]
        }
      },
      {
        questionText: "Which renewable source is described as stable and consistent (not intermittent)?",
        options: [ "Solar Power", "Wind Power", "Geothermal Energy", "Fossil Fuels" ],
        correctAnswerIndex: 2,
        feedback: {
          reasoning: "The text contrasts geothermal energy with solar and wind, highlighting its stability.",
          paragraphIndex: 2,
          keySentence: "Geothermal energy... Unlike solar and wind, it is a stable and consistent source of energy..."
        },
        translation: {
          questionText: "Nguồn năng lượng tái tạo nào được mô tả là ổn định và nhất quán (không gián đoạn)?",
          options: ["Năng lượng mặt trời", "Năng lượng gió", "Năng lượng địa nhiệt", "Nhiên liệu hóa thạch"]
        }
      }
    ]
  },
  {
    title: "The Wonders of the Great Barrier Reef",
    summary: "Discover the world's largest coral reef, its biodiversity, and the severe threat of coral bleaching.",
    minutesToRead: 1,
    content: "The Great Barrier Reef, located off the coast of Queensland, Australia, is the world's largest coral reef system. Composed of over 2,900 individual reefs and 900 islands stretching for over 2,300 kilometers, it is one of the seven wonders of the natural world.\n\nThis vast ecosystem is a hotspot of biodiversity, providing a home to countless species of fish, corals, mollusks, and sea turtles. It is so large that it can be seen from outer space. The reef is not just a natural treasure; it also contributes significantly to the local economy through tourism, generating billions of dollars annually.\n\nHowever, the reef is under severe threat. The primary danger is coral bleaching, caused by rising sea temperatures due to global warming. When the water is too warm, corals expel the algae living in their tissues, causing them to turn completely white. This does not kill the coral immediately, but prolonged bleaching can lead to its death, destroying the habitat for many species.",
    // 💡 DỊCH
    translation: {
      title: "Những kỳ quan của Rạn san hô Great Barrier",
      content: "Rạn san hô Great Barrier, nằm ngoài khơi bờ biển Queensland, Úc, là hệ thống rạn san hô lớn nhất thế giới. Bao gồm hơn 2.900 rạn san hô riêng lẻ và 900 hòn đảo trải dài hơn 2.300 km, đây là một trong bảy kỳ quan của thế giới tự nhiên.\n\nHệ sinh thái rộng lớn này là một điểm nóng về đa dạng sinh học, cung cấp nơi ở cho vô số loài cá, san hô, động vật thân mềm và rùa biển. Nó lớn đến mức có thể nhìn thấy từ ngoài không gian. Rạn san hô không chỉ là một kho báu tự nhiên; nó cũng đóng góp đáng kể cho nền kinh tế địa phương thông qua du lịch, tạo ra hàng tỷ đô la mỗi năm.\n\nTuy nhiên, rạn san hô đang bị đe dọa nghiêm trọng. Nguy cơ chính là hiện tượng tẩy trắng san hô, gây ra bởi nhiệt độ nước biển tăng do hiện tượng nóng lên toàn cầu. Khi nước quá ấm, san hô sẽ trục xuất các loài tảo sống trong mô của chúng, khiến chúng chuyển sang màu trắng hoàn toàn. Điều này không giết chết san hô ngay lập tức, nhưng việc tẩy trắng kéo dài có thể dẫn đến cái chết của nó, phá hủy môi trường sống của nhiều loài."
    },
    difficulty: "easy",
    imageUrl: "https://example.com/images/reef.png",
    questions: [
      {
        questionText: "Where is the Great Barrier Reef located?",
        options: [ "Off the coast of California", "Off the coast of Queensland, Australia", "In the Caribbean Sea", "Near Japan" ],
        correctAnswerIndex: 1,
        feedback: {
          reasoning: "The location is clearly identified in the very first sentence of the article.",
          paragraphIndex: 0,
          keySentence: "The Great Barrier Reef, located off the coast of Queensland, Australia..."
        },
        translation: {
          questionText: "Rạn san hô Great Barrier nằm ở đâu?",
          options: ["Ngoài khơi California", "Ngoài khơi Queensland, Úc", "Ở Biển Caribbean", "Gần Nhật Bản"]
        }
      },
      {
        questionText: "What is the primary threat to the reef mentioned in the text?",
        options: [ "Overfishing", "Boat accidents", "Coral bleaching from warm water", "Pollution from rivers" ],
        correctAnswerIndex: 2,
        feedback: {
          reasoning: "The third paragraph introduces the dangers, specifying 'The primary danger' as coral bleaching.",
          paragraphIndex: 2,
          keySentence: "The primary danger is coral bleaching, caused by rising sea temperatures..."
        },
        translation: {
          questionText: "Mối đe dọa chính đối với rạn san hô được đề cập trong văn bản là gì?",
          options: ["Đánh bắt cá quá mức", "Tai nạn tàu thuyền", "Tẩy trắng san hô do nước ấm", "Ô nhiễm từ sông ngòi"]
        }
      }
    ]
  },
  {
    title: "The Psychology of Sleep",
    summary: "An overview of REM and NREM sleep, memory consolidation, and the risks of sleep deprivation.",
    minutesToRead: 2,
    content: "Sleep is an essential function that allows your body and mind to recharge, leaving you refreshed and alert when you wake up. Healthy sleep also helps the body remain healthy and stave off diseases. Without enough sleep, the brain cannot function properly, which can impair concentration, thinking, and memory processing.\n\nSleep is divided into two main types: rapid eye movement (REM) sleep and non-rapid eye movement (NREM) sleep. You cycle through these stages multiple times during the night. NREM sleep is composed of three stages, the last of which is 'deep sleep,' a stage that helps you feel refreshed in the morning. REM sleep, which occurs about 90 minutes after falling asleep, is when most dreaming occurs. It is also crucial for 'memory consolidation'—the process of converting recent memories into long-term ones.\n\nChronic sleep deprivation can have severe consequences, including an increased risk of high blood pressure, diabetes, obesity, and depression. It's not just about the *quantity* of sleep, but also the *quality*.",
    // 💡 DỊCH
    translation: {
      title: "Tâm lý học về Giấc ngủ",
      content: "Ngủ là một chức năng thiết yếu cho phép cơ thể và tâm trí của bạn nạp lại năng lượng, giúp bạn sảng khoái và tỉnh táo khi thức dậy. Giấc ngủ lành mạnh cũng giúp cơ thể khỏe mạnh và ngăn ngừa bệnh tật. Nếu không ngủ đủ, não không thể hoạt động bình thường, điều này có thể làm suy giảm khả năng tập trung, suy nghĩ và xử lý trí nhớ.\n\nGiấc ngủ được chia thành hai loại chính: giấc ngủ chuyển động mắt nhanh (REM) và giấc ngủ không chuyển động mắt nhanh (NREM). Bạn luân phiên qua các giai đoạn này nhiều lần trong đêm. Giấc ngủ NREM bao gồm ba giai đoạn, giai đoạn cuối cùng là 'giấc ngủ sâu', một giai đoạn giúp bạn cảm thấy sảng khoái vào buổi sáng. Giấc ngủ REM, xảy ra khoảng 90 phút sau khi chìm vào giấc ngủ, là lúc hầu hết các giấc mơ xảy ra. Nó cũng rất quan trọng cho việc 'củng cố trí nhớ'—quá trình chuyển đổi ký ức gần đây thành ký ức dài hạn.\n\nThiếu ngủ mãn tính có thể gây ra hậu quả nghiêm trọng, bao gồm tăng nguy cơ cao huyết áp, tiểu đường, béo phì và trầm cảm. Vấn đề không chỉ là *số lượng* giấc ngủ, mà còn là *chất lượng*."
    },
    difficulty: "hard",
    imageUrl: "https://example.com/images/sleep.png",
    questions: [
      {
        questionText: "What are the two main types of sleep?",
        options: [ "Light Sleep and Deep Sleep", "REM and NREM", "Active Sleep and Passive Sleep", "Dreaming and Non-Dreaming" ],
        correctAnswerIndex: 1,
        feedback: {
          reasoning: "The text introduces this classification at the beginning of the second paragraph.",
          paragraphIndex: 1,
          keySentence: "Sleep is divided into two main types: rapid eye movement (REM) sleep and non-rapid eye movement (NREM) sleep."
        },
        translation: {
          questionText: "Hai loại giấc ngủ chính là gì?",
          options: ["Ngủ nông và Ngủ sâu", "REM và NREM", "Ngủ chủ động và Ngủ bị động", "Ngủ mơ và Không mơ"]
        }
      },
      {
        questionText: "What critical process occurs during REM sleep?",
        options: [ "Physical restoration", "Feeling refreshed", "Memory consolidation", "Falling into deep sleep" ],
        correctAnswerIndex: 2,
        feedback: {
          reasoning: "While dreaming also occurs, the text highlights memory consolidation as a 'crucial' function of REM sleep.",
          paragraphIndex: 1,
          keySentence: "It is also crucial for 'memory consolidation'..."
        },
        translation: {
          questionText: "Quá trình quan trọng nào xảy ra trong giấc ngủ REM?",
          options: ["Phục hồi thể chất", "Cảm thấy sảng khoái", "Củng cố trí nhớ", "Rơi vào giấc ngủ sâu"]
        }
      },
      {
        questionText: "Which stage is also known as 'deep sleep'?",
        options: [ "REM sleep", "The first stage of NREM", "The last stage of NREM", "The dreaming stage" ],
        correctAnswerIndex: 2,
        feedback: {
          reasoning: "The text explains that NREM sleep has multiple stages, and 'deep sleep' is the last one.",
          paragraphIndex: 1,
          keySentence: "NREM sleep is composed of three stages, the last of which is 'deep sleep'..."
        },
        translation: {
          questionText: "Giai đoạn nào còn được gọi là 'giấc ngủ sâu'?",
          options: ["Giấc ngủ REM", "Giai đoạn đầu của NREM", "Giai đoạn cuối của NREM", "Giai đoạn mơ"]
        }
      }
    ]
  },
  {
    title: "The Rise of Artificial Intelligence",
    summary: "Explains AI, Machine Learning (ML), and common applications like virtual assistants and recommendation engines.",
    minutesToRead: 2,
    content: "Artificial Intelligence (AI) refers to the simulation of human intelligence in machines that are programmed to think like humans and mimic their actions. The term may also be applied to any machine that exhibits traits associated with a human mind, such as learning and problem-solving.\n\nA key subset of AI is Machine Learning (ML), which is based on the idea that machines can learn from data, identify patterns, and make decisions with minimal human intervention. Neural Networks are a key component of ML, inspired by the structure of the human brain.\n\nWe interact with AI every day, often without realizing it. Virtual assistants like Siri and Alexa, content recommendation engines on Netflix and Spotify, and spam filters in our email are all powered by AI. While the potential benefits in fields like medicine and scientific research are immense, AI also raises significant ethical questions regarding job displacement, algorithmic bias, and privacy.",
    // 💡 DỊCH
    translation: {
      title: "Sự trỗi dậy của Trí tuệ Nhân tạo",
      content: "Trí tuệ nhân tạo (AI) đề cập đến việc mô phỏng trí thông minh của con người trong các cỗ máy được lập trình để suy nghĩ giống con người và bắt chước hành động của họ. Thuật ngữ này cũng có thể được áp dụng cho bất kỳ cỗ máy nào thể hiện các đặc điểm liên quan đến trí óc con người, chẳng hạn như học hỏi và giải quyết vấn đề.\n\Một tập hợp con quan trọng của AI là Học máy (ML), dựa trên ý tưởng rằng máy móc có thể học từ dữ liệu, xác định các mẫu và đưa ra quyết định với sự can thiệp tối thiểu của con người. Mạng nơ-ron là một thành phần quan trọng của ML, được lấy cảm hứng từ cấu trúc của bộ não con người.\n\nChúng ta tương tác với AI mỗi ngày, thường mà không nhận ra. Các trợ lý ảo như Siri và Alexa, các công cụ đề xuất nội dung trên Netflix và Spotify, và các bộ lọc thư rác trong email của chúng ta đều được hỗ trợ bởi AI. Mặc dù những lợi ích tiềm năng trong các lĩnh vực như y học và nghiên cứu khoa học là vô cùng lớn, AI cũng đặt ra những câu hỏi đạo đức đáng kể liên quan đến việc thay thế việc làm, thiên vị thuật toán và quyền riêng tư."
    },
    difficulty: "medium",
    imageUrl: "https://example.com/images/ai_brain.png",
    questions: [
      {
        questionText: "What is Machine Learning (ML)?",
        options: [ "A machine that mimics human actions.", "The structure of the human brain.", "An AI that must be controlled by humans.", "A subset of AI that learns from data to identify patterns." ],
        correctAnswerIndex: 3,
        feedback: {
          reasoning: "The second paragraph provides a clear definition of Machine Learning (ML) as a subset of AI.",
          paragraphIndex: 1,
          keySentence: "...Machine Learning (ML), which is based on the idea that machines can learn from data, identify patterns..."
        },
        translation: {
          questionText: "Học máy (ML) là gì?",
          options: ["Một cỗ máy bắt chước hành động của con người.", "Cấu trúc của bộ não con người.", "Một AI phải được con người điều khiển.", "Một nhánh của AI học từ dữ liệu để xác định các mẫu."]
        }
      },
      {
        questionText: "Which of these is NOT an example of AI mentioned in the text?",
        options: [ "Email spam filters", "Netflix recommendations", "The human brain", "Virtual assistants" ],
        correctAnswerIndex: 2,
        feedback: {
          reasoning: "This question asks what is NOT an example. The text lists virtual assistants, recommendations, and spam filters as things 'powered by AI'. The human brain is mentioned as the *inspiration* for Neural Networks ('inspired by the structure of the human brain'), not an *example* of AI itself."
        },
        translation: {
          questionText: "Điều nào sau đây KHÔNG phải là ví dụ về AI được đề cập trong văn bản?",
          options: ["Bộ lọc thư rác email", "Đề xuất của Netflix", "Bộ não con người", "Trợ lý ảo"]
        }
      }
    ]
  },
  {
    title: "The Lost Kite",
    summary: "A short story about a boy who loses his kite and gets it back from a kind neighbor.",
    minutesToRead: 1,
    content: "It was a windy afternoon in the park. A young boy named Leo was flying his favorite kite, a beautiful red diamond with a long, colorful tail. He loved watching it dance in the sky, higher and higher, until it was just a small speck.\n\nSuddenly, a strong gust of wind snapped the string. Leo watched in horror as his kite drifted away, over the trees and out of sight. He ran after it, searching every corner of the park, but it was gone. Feeling sad, he sat on a bench, holding the empty string spool.\n\nJust as he was about to go home, his neighbor, Mrs. Gable, walked up to him. She was holding his red kite. 'I found this in my backyard,' she said with a smile. 'It landed right in my tomato plants!' Leo was overjoyed. He thanked her again and again. He learned that day that his neighborhood was full of kind people.",
    // 💡 DỊCH
    translation: {
      title: "Chiếc diều bị lạc",
      content: "Đó là một buổi chiều lộng gió ở công viên. Một cậu bé tên Leo đang thả chiếc diều yêu thích của mình, một chiếc diều hình thoi màu đỏ tuyệt đẹp với chiếc đuôi dài sặc sỡ. Cậu thích ngắm nó nhảy múa trên bầu trời, ngày càng cao, cho đến khi nó chỉ còn là một chấm nhỏ.\n\nĐột nhiên, một cơn gió mạnh làm đứt dây. Leo kinh hoàng nhìn chiếc diều của mình trôi đi, bay qua những rặng cây và khuất tầm mắt. Cậu chạy theo nó, tìm kiếm mọi ngóc ngách trong công viên, nhưng nó đã biến mất. Cảm thấy buồn bã, cậu ngồi trên ghế dài, tay cầm lõi dây diều trống rỗng.\n\nNgay khi cậu chuẩn bị về nhà, người hàng xóm của cậu, bà Gable, bước đến chỗ cậu. Bà đang cầm chiếc diều đỏ của cậu. 'Bác tìm thấy cái này ở sân sau nhà,' bà mỉm cười nói. 'Nó đáp ngay vào mấy cây cà chua của bác!' Leo vui mừng khôn xiết. Cậu cảm ơn bà hết lần này đến lần khác. Ngày hôm đó, cậu biết được rằng khu phố của mình có rất nhiều người tốt bụng."
    },
    difficulty: "easy",
    imageUrl: "https://example.com/images/kite.png",
    questions: [
      {
        questionText: "What happened to Leo's kite?",
        options: [ "It got stuck in a tree.", "The string snapped in a strong wind.", "He gave it to his neighbor.", "He put it away because he was tired." ],
        correctAnswerIndex: 1,
        feedback: {
          reasoning: "The second paragraph describes the moment the kite was lost.",
          paragraphIndex: 1,
          keySentence: "Suddenly, a strong gust of wind snapped the string."
        },
        translation: {
          questionText: "Chuyện gì đã xảy ra với chiếc diều của Leo?",
          options: ["Nó bị kẹt trên cây.", "Sợi dây bị đứt trong một cơn gió mạnh.", "Cậu ấy đưa nó cho người hàng xóm.", "Cậu ấy cất nó đi vì đã mệt."]
        }
      },
      {
        questionText: "Who found the kite?",
        options: [ "Leo", "A park ranger", "His mother", "His neighbor, Mrs. Gable" ],
        correctAnswerIndex: 3,
        feedback: {
          reasoning: "The final paragraph shows how Leo got his kite back.",
          paragraphIndex: 2,
          keySentence: "...his neighbor, Mrs. Gable, walked up to him. She was holding his red kite."
        },
        translation: {
          questionText: "Ai đã tìm thấy chiếc diều?",
          options: ["Leo", "Một nhân viên kiểm lâm", "Mẹ của cậu ấy", "Hàng xóm của cậu, bà Gable"]
        }
      }
    ]
  }
];

// Hàm chính
const seedDatabase = async () => {
  try {
    await mongoose.connect(MONGO_URI);
    console.log('MongoDB Connected.');
    await Reading.deleteMany({});
    console.log('Cleared existing Readings.');
    await Reading.insertMany(readingsData);
    console.log('Successfully seeded 5 Reading documents with structured feedback and translations.');
  } catch (err) {
    console.error('Error seeding database:', err);
  } finally {
    await mongoose.disconnect();
    console.log('MongoDB Disconnected.');
  }
};

seedDatabase();