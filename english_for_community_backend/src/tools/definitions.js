export const geminiTools = [
  {
    functionDeclarations: [
      // ========================================
      // 1. LỊCH SỬ HỌC TẬP TỔNG QUAN
      // ========================================
      {
        name: "get_learning_history",
        description: "Lấy thống kê tổng quan (số phút học, số từ vựng mới, điểm trung bình) trong một khoảng thời gian.",
        parameters: {
          type: "OBJECT",
          properties: {
            startDate: { type: "STRING", description: "Ngày bắt đầu (YYYY-MM-DD)" },
            endDate: { type: "STRING", description: "Ngày kết thúc (YYYY-MM-DD)" }
          },
          required: ["startDate", "endDate"],
        },
      },

      // ========================================
      // 2. CHI TIẾT SPEAKING (Mở rộng)
      // ========================================
      {
        name: "get_speaking_details",
        description: "Lấy danh sách các bài tập Nói (Speaking) đã làm, kèm điểm số WER, transcript và thời lượng audio.",
        parameters: {
          type: "OBJECT",
          properties: {
            limit: { type: "NUMBER", description: "Số lượng bài gần nhất (mặc định 5)" },
            mode: {
              type: "STRING",
              enum: ["Read-aloud", "Shadowing", "all"],
              description: "Lọc theo chế độ Speaking (không bắt buộc)"
            }
          },
        },
      },

      // ========================================
      // 3. CHI TIẾT READING (Mở rộng)
      // ========================================
      {
        name: "get_reading_details",
        description: "Lấy danh sách các bài Đọc đã làm, kèm điểm số, số lần thử và tốc độ đọc (WPM).",
        parameters: {
          type: "OBJECT",
          properties: {
            limit: { type: "NUMBER", description: "Số lượng bài gần nhất (mặc định 5)" },
            difficulty: {
              type: "STRING",
              enum: ["easy", "medium", "hard", "all"],
              description: "Lọc theo độ khó (không bắt buộc)"
            }
          },
        },
      },

      // ========================================
      // 4. CHI TIẾT WRITING (Mở rộng)
      // ========================================
      {
        name: "get_writing_details",
        description: "Lấy danh sách các bài Viết đã nộp, kèm điểm số, nhận xét chi tiết từ AI và thời gian làm bài.",
        parameters: {
          type: "OBJECT",
          properties: {
            limit: { type: "NUMBER", description: "Số lượng bài gần nhất (mặc định 5)" },
            topicId: {
              type: "STRING",
              description: "Lọc theo Topic cụ thể (không bắt buộc)"
            }
          },
        },
      },

      // ========================================
      // 5. CHI TIẾT LISTENING/DICTATION
      // ========================================
      {
        name: "get_listening_details",
        description: "Lấy danh sách các bài Nghe chép chính tả (Dictation) đã làm, kèm điểm số độ chính xác.",
        parameters: {
          type: "OBJECT",
          properties: {
            limit: { type: "NUMBER", description: "Số lượng bài gần nhất (mặc định 5)" }
          },
        },
      },

      // ========================================
      // 6. TỪ VỰNG (Mở rộng)
      // ========================================
      {
        name: "get_vocab_list",
        description: "Lấy danh sách từ vựng theo trạng thái (đang học, đã lưu, gần đây).",
        parameters: {
          type: "OBJECT",
          properties: {
            status: {
              type: "STRING",
              enum: ["learning", "saved", "recent"],
              description: "Trạng thái từ vựng"
            },
            limit: { type: "NUMBER", description: "Số lượng từ (mặc định 10)" }
          },
        },
      },

      // ========================================
      // 7. TỪ VỰNG CẦN ÔN TẬP (Mới)
      // ========================================
      {
        name: "get_vocab_review",
        description: "Lấy danh sách từ vựng cần ôn tập hôm nay (theo thuật toán Ebbinghaus).",
        parameters: {
          type: "OBJECT",
          properties: {
            limit: { type: "NUMBER", description: "Số lượng từ (mặc định 20)" }
          },
        },
      },

      // ========================================
      // 8. THỐNG KÊ THEO KỸ NĂNG (Mới)
      // ========================================
      {
        name: "get_skill_statistics",
        description: "Lấy thống kê chi tiết cho một kỹ năng cụ thể trong khoảng thời gian.",
        parameters: {
          type: "OBJECT",
          properties: {
            skill: {
              type: "STRING",
              enum: ["reading", "writing", "speaking", "listening", "vocab"],
              description: "Kỹ năng cần xem thống kê"
            },
            range: {
              type: "STRING",
              enum: ["day", "week", "month"],
              description: "Phạm vi thời gian (mặc định: week)"
            }
          },
          required: ["skill"]
        },
      },

      // ========================================
      // 9. BẢNG XẾP HẠNG (Mới)
      // ========================================
      {
        name: "get_leaderboard",
        description: "Lấy bảng xếp hạng người dùng theo điểm tích lũy (XP).",
        parameters: {
          type: "OBJECT",
          properties: {},
        },
      },

      // ========================================
      // 10. TÌM BÀI TẬP THEO ĐỘ KHÓ (Mới)
      // ========================================
      {
        name: "get_exercises_by_difficulty",
        description: "Tìm các bài tập phù hợp với trình độ người dùng (chưa làm hoặc điểm thấp).",
        parameters: {
          type: "OBJECT",
          properties: {
            skill: {
              type: "STRING",
              enum: ["reading", "speaking", "listening"],
              description: "Loại bài tập"
            },
            difficulty: {
              type: "STRING",
              enum: ["easy", "medium", "hard", "Beginner", "Intermediate", "Advanced"],
              description: "Độ khó"
            },
            limit: { type: "NUMBER", description: "Số lượng bài (mặc định 5)" }
          },
          required: ["skill", "difficulty"]
        },
      },

      // ========================================
      // 11. PHÂN TÍCH ĐIỂM YẾU (Mới)
      // ========================================
      {
        name: "analyze_weaknesses",
        description: "Phân tích điểm yếu của người dùng dựa trên lịch sử học tập (kỹ năng nào điểm thấp, ít luyện tập).",
        parameters: {
          type: "OBJECT",
          properties: {
            range: {
              type: "STRING",
              enum: ["week", "month"],
              description: "Phạm vi phân tích (mặc định: week)"
            }
          }
        },
      },

      // ========================================
      // 12. CHI TIẾT MỘT BÀI HỌC CỤ THỂ (Mới)
      // ========================================
      {
        name: "get_lesson_detail",
        description: "Lấy chi tiết một bài học cụ thể (Reading/Listening/Speaking) kèm lịch sử làm bài.",
        parameters: {
          type: "OBJECT",
          properties: {
            lessonType: {
              type: "STRING",
              enum: ["reading", "listening", "speaking"],
              description: "Loại bài học"
            },
            lessonId: {
              type: "STRING",
              description: "ID của bài học"
            }
          },
          required: ["lessonType", "lessonId"]
        },
      }
    ]
  }
];