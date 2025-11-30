// writing_topic_entity.dart
import 'package:equatable/equatable.dart';

class WritingTopicEntity extends Equatable {
  final String id;              // _id / id
  final String name;
  final String slug;
  final String? icon;
  final String? color;          // #RRGGBB
  final int order;
  final bool isActive;
  final AiConfig? aiConfig;
  final TopicStats? stats;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WritingTopicEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.color,
    this.order = 0,
    this.isActive = true,
    this.aiConfig,
    this.stats,
    this.createdAt,
    this.updatedAt,
  });

  factory WritingTopicEntity.fromJson(Map<String, dynamic> json) {
    final _id = (json['_id'] ?? json['id']) as String?;
    if (_id == null) {
      throw ArgumentError('WritingTopicEntity.fromJson: missing id/_id');
    }
    return WritingTopicEntity(
      id: _id,
      name: (json['name'] ?? '') as String,
      slug: (json['slug'] ?? '') as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
      isActive: (json['isActive'] as bool?) ?? true,
      aiConfig: json['aiConfig'] != null ? AiConfig.fromJson(json['aiConfig'] as Map<String, dynamic>) : null,
      stats: json['stats'] != null ? TopicStats.fromJson(json['stats'] as Map<String, dynamic>) : null,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'icon': icon,
    'color': color,
    'order': order,
    'isActive': isActive,
    'aiConfig': aiConfig?.toJson(),
    'stats': stats?.toJson(),
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
  List<Object?> get props => [id, name, slug, icon, color, order, isActive, aiConfig, stats, createdAt, updatedAt];
}

class AiConfig extends Equatable {
  final String? language;                 // vi-VN
  final List<String>? taskTypes;          // ['Discussion', ...]
  final String? defaultTaskType;
  final String? level;                    // Beginner/Intermediate/Advanced
  final String? targetWordCount;          // '250–320'
  final String? generationTemplate;

  const AiConfig({
    this.language,
    this.taskTypes,
    this.defaultTaskType,
    this.level,
    this.targetWordCount,
    this.generationTemplate,
  });

  factory AiConfig.fromJson(Map<String, dynamic> json) => AiConfig(
    language: json['language'] as String?,
    taskTypes: (json['taskTypes'] as List?)?.map((e) => e as String).toList(),
    defaultTaskType: json['defaultTaskType'] as String?,
    level: json['level'] as String?,
    targetWordCount: json['targetWordCount'] as String?,
    generationTemplate: json['generationTemplate'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'language': language,
    'taskTypes': taskTypes,
    'defaultTaskType': defaultTaskType,
    'level': level,
    'targetWordCount': targetWordCount,
    'generationTemplate': generationTemplate,
  };

  @override
  List<Object?> get props => [language, taskTypes, defaultTaskType, level, targetWordCount, generationTemplate];
}

class TopicStats extends Equatable {
  final int submissionsCount;
  final double? avgScore;

  const TopicStats({this.submissionsCount = 0, this.avgScore});

  factory TopicStats.fromJson(Map<String, dynamic> json) => TopicStats(
    submissionsCount: (json['submissionsCount'] as num?)?.toInt() ?? 0,
    avgScore: (json['avgScore'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'submissionsCount': submissionsCount,
    'avgScore': avgScore,
  };

  @override
  List<Object?> get props => [submissionsCount, avgScore];
}
