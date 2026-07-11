import 'dart:convert';

ProgressSummaryEntity progressSummaryEntityFromJson(String str) =>
    ProgressSummaryEntity.fromJson(json.decode(str));

// Lớp chính
class ProgressSummaryEntity {
  final StudyTimeEntity studyTime;
  final StatsGridEntity statsGrid;
  final WeeklyChartEntity weeklyChart;
  final CalloutEntity callout;

  ProgressSummaryEntity({
    required this.studyTime,
    required this.statsGrid,
    required this.weeklyChart,
    required this.callout,
  });

  factory ProgressSummaryEntity.fromJson(Map<String, dynamic> json) =>
      ProgressSummaryEntity(
        studyTime: StudyTimeEntity.fromJson(json["studyTime"]),
        statsGrid: StatsGridEntity.fromJson(json["statsGrid"]),
        weeklyChart: WeeklyChartEntity.fromJson(json["weeklyChart"]),
        callout: CalloutEntity.fromJson(json["callout"]),
      );
}

// Lớp con cho "studyTime" (Đã chính xác, giữ nguyên)
class StudyTimeEntity {
  final int todayMinutes;
  final int goalMinutes;
  final double progressPercent;
  final int totalMinutesInRange;
  StudyTimeEntity({
    required this.totalMinutesInRange,
    required this.todayMinutes,
    required this.goalMinutes,
    required this.progressPercent,
  });

  factory StudyTimeEntity.fromJson(Map<String, dynamic> json) =>
      StudyTimeEntity(
        todayMinutes: (json["todayMinutes"] as num?)?.toInt() ?? 0,
        goalMinutes: (json["goalMinutes"] as num?)?.toInt() ?? 0,
        totalMinutesInRange: (json["totalMinutesInRange"] as num?)?.toInt() ?? 0,
        // Chuyển đổi linh hoạt từ int hoặc double (null-safe)
        progressPercent: (json["progressPercent"] as num?)?.toDouble() ?? 0,
      );
}

// ⭐️ SỬA LẠI LỚP NÀY ĐỂ KHỚP VỚI CONTROLLER ⭐️
// Lớp con cho "statsGrid"
class StatsGridEntity {
  final int vocabLearned;
  final double avgWritingScore;
  final int readingAccuracy;
  final int dictationAccuracy;
  final int speakingAccuracy;
  final int speakingFluency;
  final int lessonsCompleted; // ✍️ THÊM TRƯỜNG MỚI
  final int readingWpm;

  StatsGridEntity({
    required this.vocabLearned,
    required this.avgWritingScore,
    required this.readingAccuracy,
    required this.dictationAccuracy,
    required this.speakingAccuracy,
    required this.speakingFluency,
    required this.lessonsCompleted, // ✍️ THÊM VÀO CONSTRUCTOR
    required this.readingWpm,
  });

  factory StatsGridEntity.fromJson(Map<String, dynamic> json) =>
      StatsGridEntity(
        vocabLearned: (json["vocabLearned"] as num?)?.toInt() ?? 0,
        avgWritingScore: (json["avgWritingScore"] as num?)?.toDouble() ?? 0,
        readingAccuracy: (json["readingAccuracy"] as num?)?.toInt() ?? 0,
        dictationAccuracy: (json["dictationAccuracy"] as num?)?.toInt() ?? 0,
        speakingAccuracy: (json["speakingAccuracy"] as num?)?.toInt() ?? 0,
        speakingFluency: (json["speakingFluency"] as num?)?.toInt() ?? 0,
        lessonsCompleted: (json["lessonsCompleted"] as num?)?.toInt() ?? 0,
        readingWpm: (json["readingWpm"] as num?)?.toInt() ?? 0,
      );
}

// Lớp con cho "weeklyChart" (Giữ nguyên)
class WeeklyChartEntity {
  final List<String> labels;
  final List<int> minutes;

  WeeklyChartEntity({
    required this.labels,
    required this.minutes,
  });

  factory WeeklyChartEntity.fromJson(Map<String, dynamic> json) =>
      WeeklyChartEntity(
        labels: List<String>.from(json["labels"].map((x) => x)),
        minutes: List<int>.from(json["minutes"].map((x) => x)),
      );
}

// Lớp con cho "callout" (Giữ nguyên)
class CalloutEntity {
  final String title;
  final String message;

  CalloutEntity({
    required this.title,
    required this.message,
  });

  factory CalloutEntity.fromJson(Map<String, dynamic> json) => CalloutEntity(
        title: json["title"],
        message: json["message"],
      );
}

class ProgressDetailEntity {
  final String id;
  final String title;
  final double score; // Điểm số (85% hoặc band Viết 6.5 — giữ thập phân, format ở UI)
  final int duration; // Thời gian (phút)
  final String date; // ISO Date String
  final String type;
  const ProgressDetailEntity({
    required this.id,
    required this.title,
    required this.score,
    required this.duration,
    required this.date,
    required this.type,
  });

  factory ProgressDetailEntity.fromJson(Map<String, dynamic> json) {
    // Lấy các giá trị có thể là null an toàn
    final titleFromJson = json['title'] as String?;
    final dateFromJson = json['date'] as String?;
    final idFromJson = json['_id'] ?? json['id'] as String?;
    final typeFromJson = json['type'] as String?; // Chỉ có trong lessons

    return ProgressDetailEntity(
      // 🔥 1. SỬA CHO STRING: Đảm bảo luôn trả về chuỗi, không bao giờ là null
      id: idFromJson ?? '',
      title: titleFromJson ?? 'N/A',
      date: dateFromJson ?? 'N/A',

      // Sửa lỗi cho số (như đã thảo luận trước):
      score: (json['score'] as num? ?? 0).toDouble(),
      duration: (json['duration'] as num? ?? 0).toInt(),

      // Trường bổ sung
      type: typeFromJson ?? '',
    );
  }
}
