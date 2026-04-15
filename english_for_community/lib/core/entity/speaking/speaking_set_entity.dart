import 'package:equatable/equatable.dart';
import 'sentence_entity.dart';

class SpeakingSetEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String level;
  final String mode; // 👇 THÊM TRƯỜNG NÀY (Backend yêu cầu)
  final List<SentenceEntity> sentences;
  final int totalSentences; // Helper để hiện UI
  final int attemptsCount;
  final String adminStatus;

  const SpeakingSetEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.mode,
    required this.sentences,
    this.totalSentences = 0,
    this.attemptsCount = 0,
    this.adminStatus = 'published',
  });

  factory SpeakingSetEntity.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id']) as String?;
    if (id == null) {
      // Handle trường hợp tạo mới chưa có ID
      return SpeakingSetEntity.empty();
    }

    final sentencesList = (json['sentences'] as List? ?? [])
        .map((e) => SentenceEntity.fromJson(e as Map<String, dynamic>))
        .toList();

    return SpeakingSetEntity(
      id: id,
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      level: (json['level'] as String?) ?? 'Beginner',
      mode: (json['mode'] as String?) ?? 'readAloud', // Default mode
      sentences: sentencesList,
      totalSentences: (json['totalSentences'] as num?)?.toInt() ?? sentencesList.length,
      attemptsCount: (json['attemptsCount'] as num?)?.toInt() ?? 0,
      adminStatus: (json['adminStatus'] ?? 'published').toString(),
    );
  }

  // Factory rỗng để tránh lỗi null
  factory SpeakingSetEntity.empty() {
    return const SpeakingSetEntity(
        id: '', title: '', description: '',
        level: 'Beginner', mode: 'readAloud', sentences: [],
        attemptsCount: 0, adminStatus: 'published'
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'title': title,
      'description': description,
      'level': level,
      'mode': mode,
      'attemptsCount': attemptsCount,
      'adminStatus': adminStatus,
      // Map key đúng với backend (phonetic_script) trong SentenceEntity.toJson
      'sentences': sentences.map((e) => e.toJson()).toList(),
    };
    // Chỉ gửi id nếu không rỗng (để update)
    if (id.isNotEmpty) map['id'] = id;
    return map;
  }

  // CopyWith để update state trong Bloc
  SpeakingSetEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? level,
    String? mode,
    List<SentenceEntity>? sentences,
    int? attemptsCount,
    String? adminStatus,
  }) {
    return SpeakingSetEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      level: level ?? this.level,
      mode: mode ?? this.mode,
      sentences: sentences ?? this.sentences,
      totalSentences: sentences?.length ?? this.totalSentences,
      attemptsCount: attemptsCount ?? this.attemptsCount,
      adminStatus: adminStatus ?? this.adminStatus,
    );
  }

  @override
  List<Object?> get props => [id, title, description, level, mode, sentences, attemptsCount, adminStatus];
}