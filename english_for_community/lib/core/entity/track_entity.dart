import 'package:equatable/equatable.dart';

enum TrackLevel { beginner, intermediate, advanced }

String? _trackLevelToJson(TrackLevel? v) {
  switch (v) {
    case TrackLevel.beginner: return 'beginner';
    case TrackLevel.intermediate: return 'intermediate';
    case TrackLevel.advanced: return 'advanced';
    default: return null;
  }
}

TrackLevel? _trackLevelFromJson(Object? v) {
  switch (v) {
    case 'beginner': return TrackLevel.beginner;
    case 'intermediate': return TrackLevel.intermediate;
    case 'advanced': return TrackLevel.advanced;
    default: return null;
  }
}

class TrackEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final TrackLevel? level;
  final String? imageUrl;
  final int? order;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TrackEntity({
    required this.id,
    required this.name,
    this.description,
    this.level,
    this.imageUrl,
    this.order,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory TrackEntity.fromJson(Map<String, dynamic> json) {
    final _id = (json['id'] ?? json['_id']) as String?;
    if (_id == null) {
      throw ArgumentError('TrackEntity.fromJson: missing id/_id');
    }
    return TrackEntity(
      id: _id,
      name: (json['name'] ?? '') as String,
      description: json['description'] as String?,
      level: _trackLevelFromJson(json['level']),
      imageUrl: json['imageUrl'] as String?,
      order: (json['order'] as num?)?.toInt(),
      isActive: json['isActive'] as bool?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'level': _trackLevelToJson(level),
    'imageUrl': imageUrl,
    'order': order,
    'isActive': isActive,
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
    name,
    description,
    level,
    imageUrl,
    order,
    isActive,
    createdAt,
    updatedAt,
  ];
}
