import 'package:equatable/equatable.dart';
import 'package:english_for_community/core/entity/unit_entity.dart';

enum LessonType { vocabulary, grammar, reading, listening, speaking, writing }

String? _lessonTypeToJson(LessonType? v) {
  switch (v) {
    case LessonType.vocabulary: return 'vocabulary';
    case LessonType.grammar:   return 'grammar';
    case LessonType.reading:   return 'reading';
    case LessonType.listening: return 'listening';
    case LessonType.speaking:  return 'speaking';
    case LessonType.writing:   return 'writing';
    default: return null;
  }
}

LessonType? _lessonTypeFromJson(Object? v) {
  switch (v) {
    case 'vocabulary': return LessonType.vocabulary;
    case 'grammar':   return LessonType.grammar;
    case 'reading':   return LessonType.reading;
    case 'listening': return LessonType.listening;
    case 'speaking':  return LessonType.speaking;
    case 'writing':   return LessonType.writing;
    default: return null;
  }
}

class LessonEntity extends Equatable {
  final String id;                 // id/_id
  final UnitEntity unit;           // <-- object
  final String name;
  final String? description;
  final int? order;
  final LessonType? type;
  final Map<String, dynamic>? content;
  final String? imageUrl;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LessonEntity({
    required this.id,
    required this.unit,
    required this.name,
    this.description,
    this.order,
    this.type,
    this.content,
    this.imageUrl,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory LessonEntity.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'])?.toString();
    if (id == null) {
      throw ArgumentError('LessonEntity.fromJson: missing id/_id');
    }

    // Accept "unit" or "unitId" as OBJECT. Reject string id to keep contract strict.
    final rawUnit = json['unit'] ?? json['unitId'];
    if (rawUnit is! Map<String, dynamic>) {
      throw ArgumentError(
          'LessonEntity.fromJson: expected unit/unitId to be an OBJECT, got: ${rawUnit.runtimeType}. '
              'Please make backend return populated object for unit.'
      );
    }

    return LessonEntity(
      id: id,
      unit: UnitEntity.fromJson(rawUnit as Map<String, dynamic>),
      name: (json['name'] ?? '') as String,
      description: json['description'] as String?,
      order: (json['order'] as num?)?.toInt(),
      type: _lessonTypeFromJson(json['type']),
      content: (json['content'] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(json['content'] as Map)
          : null,
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'unit': unit.toJson(), // gửi cả object (giữ đúng contract)
    'name': name,
    'description': description,
    'order': order,
    'type': _lessonTypeToJson(type),
    'content': content,
    'imageUrl': imageUrl,
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
    id, unit, name, description, order, type, content, imageUrl, isActive, createdAt, updatedAt,
  ];
}
