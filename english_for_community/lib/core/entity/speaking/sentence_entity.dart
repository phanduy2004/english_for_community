// lib/core/entity/speaking/sentence_entity.dart (hoặc file của bạn)

import 'package:equatable/equatable.dart';
import 'speaking_attempt_entity.dart'; // ⬅️ 1. Đảm bảo bạn import file này

class SentenceEntity extends Equatable {
  final String id;
  final int order;
  final String speaker;
  final String script;
  final String phoneticScript;

  // ⬇️ 2. THÊM TRƯỜNG MỚI
  final List<SpeakingAttemptEntity> history;

  const SentenceEntity({
    required this.id,
    required this.order,
    required this.speaker,
    required this.script,
    required this.phoneticScript,
    this.history = const [], // ⬅️ 3. Thêm vào constructor (với giá trị mặc định)
  });

  // ⬇️ 4. CẬP NHẬT factory .fromJson
  factory SentenceEntity.fromJson(Map<String, dynamic> json) {
    // Lấy mảng 'history' thô từ JSON
    final historyList = (json['history'] as List<dynamic>? ?? []);

    // Chuyển đổi (map) mảng thô đó thành List<SpeakingAttemptEntity>
    final historyEntities = historyList
        .map((item) => SpeakingAttemptEntity.fromJson(item as Map<String, dynamic>))
        .toList();

    return SentenceEntity(
      id: (json['id'] ?? json['_id'])?.toString() ?? 'temp_${DateTime.now().microsecondsSinceEpoch}',
      order: (json['order'] as num?)?.toInt() ?? 0,
      speaker: (json['speaker'] as String?) ?? '',
      script: (json['script'] as String?) ?? '',
      phoneticScript: (json['phonetic_script'] as String?) ?? '',
      history: historyEntities, // ⬅️ 5. Gán mảng đã parse vào đây
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'speaker': speaker,
      'script': script,
      'phonetic_script': phoneticScript,
      'history': history.map((e) => e.toJson()).toList(), // This calls the method from Step 2
    };
  }
  // ⬇️ 6. CẬP NHẬT props (cho Equatable)
  @override
  List<Object?> get props => [
    id,
    order,
    speaker,
    script,
    phoneticScript,
    history, // ⬅️ Thêm 'history' vào đây
  ];
}
