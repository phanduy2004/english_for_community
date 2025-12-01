
class UserWordEntity {
  // (Bạn nên thêm 'extends Equatable' nếu dùng)
  // 🔽 ✍️ SỬA 1: Đổi kiểu 'id' thành String?
  final String? id;
  final String headword;
  final String? ipa;
  final String? shortDefinition;
  final String? pos;
  final String status;
  final int learningLevel;
  final DateTime nextReviewDate;
  final DateTime lastReviewedDate;

  UserWordEntity({
    this.id, // 👈 Đã đổi thành String?
    required this.headword,
    this.ipa,
    this.shortDefinition,
    this.pos,
    required this.status,
    required this.learningLevel,
    required this.nextReviewDate,
    required this.lastReviewedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'headword': headword,
      'ipa': ipa,
      'shortDefinition': shortDefinition,
      'pos': pos,
      'status': status,
      'learningLevel': learningLevel,
      'nextReviewDate': nextReviewDate.toIso8601String(),
      'lastReviewedDate': lastReviewedDate.toIso8601String(),
    };
  }

  factory UserWordEntity.fromMap(Map<String, dynamic> map) {
    return UserWordEntity(
      // 🔽 ✍️ SỬA 2: SỬA LOGIC LẤY ID
      // Logic này: Lấy '_id' (từ server Mongoose) trước,
      // nếu không có, thì lấy 'id' (từ local db, nếu có).
      // Chuyển tất cả về String.
      id: map['_id']?.toString() ?? map['id']?.toString(),
      // 🔼

      headword: map['headword'] as String,
      ipa: map['ipa'] as String?,
      shortDefinition: map['shortDefinition'] as String?,
      pos: map['pos'] as String?,
      status: map['status'] as String,
      learningLevel: map['learningLevel'] as int,
      nextReviewDate: DateTime.parse(map['nextReviewDate'] as String),
      lastReviewedDate: DateTime.parse(map['lastReviewedDate'] as String),
    );
  }
}