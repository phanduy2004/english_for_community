export const geminiTools = [
  {
    functionDeclarations: [
      // 1. Lịch sử học tập tổng quan (Progress)
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

      // 2. Chi tiết Speaking (Luyện nói)
      {
        name: "get_speaking_details",
        description: "Lấy danh sách các bài tập Nói (Speaking) người dùng đã làm, kèm điểm số, độ chính xác và transcript.",
        parameters: {
          type: "OBJECT",
          properties: {
            limit: { type: "NUMBER", description: "Số lượng bài gần nhất muốn lấy (mặc định 5)" }
          },
        },
      },

      // 3. Chi tiết Reading (Luyện đọc)
      {
        name: "get_reading_details",
        description: "Lấy danh sách các bài Đọc (Reading) người dùng đã làm, kèm điểm số và tốc độ đọc (WPM).",
        parameters: {
          type: "OBJECT",
          properties: {
            limit: { type: "NUMBER", description: "Số lượng bài gần nhất muốn lấy (mặc định 5)" }
          },
        },
      },

      // 4. Chi tiết Writing (Luyện viết)
      {
        name: "get_writing_details",
        description: "Lấy danh sách các bài Viết (Writing) người dùng đã nộp, kèm điểm số và nhận xét.",
        parameters: {
          type: "OBJECT",
          properties: {
            limit: { type: "NUMBER", description: "Số lượng bài gần nhất muốn lấy (mặc định 5)" }
          },
        },
      },

      // 5. Chi tiết Listening/Dictation (Nghe chép chính tả)
      {
        name: "get_listening_details",
        description: "Lấy danh sách các bài Nghe chép chính tả (Dictation) người dùng đã làm, kèm điểm số (WER).",
        parameters: {
          type: "OBJECT",
          properties: {
            limit: { type: "NUMBER", description: "Số lượng bài gần nhất muốn lấy (mặc định 5)" }
          },
        },
      },

      // 6. Từ vựng (Vocabulary)
      {
        name: "get_vocab_list",
        description: "Lấy danh sách từ vựng người dùng đang học hoặc đã lưu.",
        parameters: {
          type: "OBJECT",
          properties: {
            status: {
              type: "STRING",
              enum: ["learning", "saved", "recent"],
              description: "Trạng thái từ vựng (learning: đang học, saved: đã lưu, recent: mới tra)"
            },
            limit: { type: "NUMBER", description: "Số lượng từ (mặc định 10)" }
          },
        },
      }
    ]
  }
];