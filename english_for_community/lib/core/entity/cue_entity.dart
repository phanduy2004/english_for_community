import 'package:equatable/equatable.dart';

class CueEntity extends Equatable {
  final String id;          // đổi thành '_id' nếu server trả _id
  final String listeningId; // ref CueSchema.listeningId
  final int idx;            // 0..N-1 (unique trong 1 listening)
  final int startMs;
  final int endMs;
  final String? spk;        // speaker
  final String? text;       // ground truth
  final String? textNorm;   // normalized
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CueEntity({
    required this.id,
    required this.listeningId,
    required this.idx,
    required this.startMs,
    required this.endMs,
    this.spk,
    this.text,
    this.textNorm,
    this.createdAt,
    this.updatedAt,
  });

  factory CueEntity.fromJson(Map<String, dynamic> json) {
    final _id = (json['id'] ?? json['_id']) as String?;
    if (_id == null) {
      throw ArgumentError('CueEntity.fromJson: missing id/_id');
    }
    return CueEntity(
      id: _id,
      listeningId: (json['listeningId'] ?? '') as String,
      idx: (json['idx'] as num?)?.toInt() ?? 0,
      startMs: (json['startMs'] as num?)?.toInt() ?? 0,
      endMs: (json['endMs'] as num?)?.toInt() ?? 0,
      spk: json['spk'] as String?,
      text: json['text'] as String?,
      textNorm: json['textNorm'] as String?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'listeningId': listeningId,
    'idx': idx,
    'startMs': startMs,
    'endMs': endMs,
    'spk': spk,
    'text': text,
    'textNorm': textNorm,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  static DateTime? _parseDate(Object? v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    listeningId,
    idx,
    startMs,
    endMs,
    spk,
    text,
    textNorm,
    createdAt,
    updatedAt,
  ];
}
