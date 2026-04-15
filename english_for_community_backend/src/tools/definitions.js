export const geminiTools = [
  {
    functionDeclarations: [
      // ========================================
      // 1. LỊCH SỬ HỌC TẬP TỔNG QUAN
      // ========================================
      {
        name: "get_learning_history",
        description:
          "Thống kê UserDailyProgress (phút học, từ mới, điểm TB) trong khoảng ngày. Chỉ dùng khi đã có chính xác startDate/endDate (YYYY-MM-DD). KHÔNG bịa ngày — với hôm nay/tuần/tháng dùng get_learning_history_period hoặc get_daily_activity.",
        parameters: {
          type: "OBJECT",
          properties: {
            startDate: { type: "STRING", description: "Ngày bắt đầu (YYYY-MM-DD)" },
            endDate: { type: "STRING", description: "Ngày kết thúc (YYYY-MM-DD)" }
          },
          required: ["startDate", "endDate"],
        },
      },
      {
        name: "get_learning_history_period",
        description:
          "Giống get_learning_history nhưng server tự tính ngày theo múi giờ user: today | week (7 ngày gần nhất tính đến hôm nay) | last_week (tuần dương lịch trước: Thứ Hai–Chủ nhật, KHÔNG gồm tuần hiện tại) | month (từ mùng 1 đến hôm nay). Với \"tuần trước / last week\" bắt buộc dùng last_week, không dùng week.",
        parameters: {
          type: "OBJECT",
          properties: {
            range: {
              type: "STRING",
              enum: ["today", "week", "last_week", "month"],
              description:
                "today = hôm nay; week = 7 ngày lùi từ hôm nay (rolling); last_week = tuần dương lịch trước (Thứ Hai–Chủ nhật); month = tháng hiện tại",
            },
          },
        },
      },
      {
        name: "get_daily_activity",
        description:
          "Danh sách bài đã làm trong MỘT ngày (khớp màn Progress/Lịch sử app): đếm số activity và từng tiêu đề. Dùng khi user hỏi hôm nay làm mấy bài / progress hôm nay.",
        parameters: {
          type: "OBJECT",
          properties: {
            date: {
              type: "STRING",
              description: "YYYY-MM-DD (tùy chọn). Bỏ trống = hôm nay theo timezone user.",
            },
          },
        },
      },

      // ========================================
      // 2. CHI TIẾT SPEAKING (Mở rộng)
      // ========================================
      {
        name: "get_speaking_details",
        description:
          "Danh sách bài Speaking đã hoàn thành. Có thể lọc theo khoảng ngày (theo timezone user) để khớp 'hôm nay'.",
        parameters: {
          type: "OBJECT",
          properties: {
            limit: { type: "NUMBER", description: "Số lượng bài gần nhất (mặc định 5)" },
            mode: {
              type: "STRING",
              enum: ["Read-aloud", "Shadowing", "all"],
              description: "Lọc theo chế độ Speaking (không bắt buộc)"
            },
            startDate: { type: "STRING", description: "Lọc lastAccessedAt từ ngày (YYYY-MM-DD), dùng cùng endDate" },
            endDate: { type: "STRING", description: "Lọc đến ngày (YYYY-MM-DD)" },
          },
        },
      },

      // ========================================
      // 3. CHI TIẾT READING (Mở rộng)
      // ========================================
      {
        name: "get_reading_details",
        description:
          "Bài Reading đã hoàn thành. Truyền startDate+endDate (YYYY-MM-DD) để chỉ lấy bài có hoạt động trong khoảng đó (ví dụ hôm nay).",
        parameters: {
          type: "OBJECT",
          properties: {
            limit: { type: "NUMBER", description: "Số lượng bài gần nhất (mặc định 5)" },
            difficulty: {
              type: "STRING",
              enum: ["easy", "medium", "hard", "all"],
              description: "Lọc theo độ khó (không bắt buộc)"
            },
            startDate: { type: "STRING", description: "YYYY-MM-DD (kèm endDate)" },
            endDate: { type: "STRING", description: "YYYY-MM-DD" },
          },
        },
      },

      // ========================================
      // 4. CHI TIẾT WRITING (Mở rộng)
      // ========================================
      {
        name: "get_writing_details",
        description: "Bài Writing đã nộp. Có thể lọc submittedAt theo startDate/endDate (YYYY-MM-DD).",
        parameters: {
          type: "OBJECT",
          properties: {
            limit: { type: "NUMBER", description: "Số lượng bài gần nhất (mặc định 5)" },
            topicId: {
              type: "STRING",
              description: "Lọc theo Topic cụ thể (không bắt buộc)"
            },
            startDate: { type: "STRING", description: "YYYY-MM-DD (kèm endDate)" },
            endDate: { type: "STRING", description: "YYYY-MM-DD" },
          },
        },
      },

      // ========================================
      // 5. CHI TIẾT LISTENING/DICTATION
      // ========================================
      {
        name: "get_listening_details",
        description:
          "Bài Dictation đã hoàn thành. startDate+endDate (YYYY-MM-DD) lọc theo lastAccessedAt trong ngày của user.",
        parameters: {
          type: "OBJECT",
          properties: {
            limit: { type: "NUMBER", description: "Số lượng bài gần nhất (mặc định 5)" },
            startDate: { type: "STRING", description: "YYYY-MM-DD (kèm endDate)" },
            endDate: { type: "STRING", description: "YYYY-MM-DD" },
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
              enum: ["today", "day", "week", "last_week", "month"],
              description: "today/day = hôm nay; week = 7 ngày lùi đến hôm nay; last_week = tuần dương lịch trước; month = từ mùng 1 (timezone user). Mặc định: week"
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
              enum: ["today", "day", "week", "last_week", "month"],
              description: "today/day = hôm nay; week = 7 ngày; last_week = tuần dương lịch trước; month theo timezone user (mặc định: week)"
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