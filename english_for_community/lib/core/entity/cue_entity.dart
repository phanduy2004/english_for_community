import 'package:equatable/equatable.dart';

class CueEntity extends Equatable {
  final String id;          // Map từ _id của sub-document
  final int startMs;
  final int endMs;
  final String? spk;        // speaker
  final String? text;       // ground truth (nội dung gốc)
  final String? textNorm;   // normalized (để chấm điểm)

  const CueEntity({
    required this.id,
    required this.startMs,
    required this.endMs,
    this.spk,
    this.text,
    this.textNorm,
  });

  factory CueEntity.fromJson(Map<String, dynamic> json) {
    // Backend trả về _id, nhưng ta map vào id cho chuẩn Dart
    final _id = (json['_id'] ?? json['id']) as String?;

    // Nếu tạo mới chưa có ID thì gán tạm rỗng hoặc throw tuỳ logic app bạn
    // Ở đây tôi để throw để đảm bảo data chặt chẽ
    if (_id == null) {
      throw ArgumentError('CueEntity.fromJson: missing id/_id');
    }

    return CueEntity(
      id: _id,
      startMs: (json['startMs'] as num?)?.toInt() ?? 0,
      endMs: (json['endMs'] as num?)?.toInt() ?? 0,
      spk: json['spk'] as String?,
      text: json['text'] as String?,
      textNorm: json['textNorm'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    // Khi gửi lên server tạo/sửa, có thể không cần gửi id nếu là tạo mới
    // Nhưng nếu edit thì cần id để backend biết
    return {
      if (id.isNotEmpty) 'id': id, // hoặc _id tuỳ convention
      'startMs': startMs,
      'endMs': endMs,
      'spk': spk,
      'text': text,
      'textNorm': textNorm,
    };
  }

  // Helper để hiển thị thời gian debug (tuỳ chọn)
  @override
  String toString() => 'Cue($startMs - $endMs: $text)';

  @override
  List<Object?> get props => [id, startMs, endMs, spk, text, textNorm];
}
