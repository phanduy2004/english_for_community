import 'package:equatable/equatable.dart';
import 'package:english_for_community/core/entity/track_entity.dart';

class UnitEntity extends Equatable {
  final String id;              // id/_id
  final TrackEntity track;      // <-- object
  final String name;
  final String? description;
  final int? order;
  final String? imageUrl;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UnitEntity({
    required this.id,
    required this.track,
    required this.name,
    this.description,
    this.order,
    this.imageUrl,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory UnitEntity.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'])?.toString();
    if (id == null) {
      throw ArgumentError('UnitEntity.fromJson: missing id/_id');
    }

    // Accept "track" or "trackId" as OBJECT. Reject string id to keep contract strict.
    final rawTrack = json['track'] ?? json['trackId'];
    if (rawTrack is! Map<String, dynamic>) {
      throw ArgumentError(
          'UnitEntity.fromJson: expected track/trackId to be an OBJECT, got: ${rawTrack.runtimeType}. '
              'Please make backend return populated object for track.'
      );
    }

    return UnitEntity(
      id: id,
      track: TrackEntity.fromJson(rawTrack as Map<String, dynamic>),
      name: (json['name'] ?? '') as String,
      description: json['description'] as String?,
      order: (json['order'] as num?)?.toInt(),
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool?,
      createdAt: _tryParseDate(json['createdAt']),
      updatedAt: _tryParseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'track': track.toJson(), // gửi cả object
    'name': name,
    'description': description,
    'order': order,
    'imageUrl': imageUrl,
    'isActive': isActive,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  static DateTime? _tryParseDate(Object? v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  @override
  List<Object?> get props => [
    id, track, name, description, order, imageUrl, isActive, createdAt, updatedAt,
  ];

  UnitEntity copyWith({
    String? id,
    TrackEntity? track,
    String? name,
    String? description,
    int? order,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UnitEntity(
      id: id ?? this.id,
      track: track ?? this.track,
      name: name ?? this.name,
      description: description ?? this.description,
      order: order ?? this.order,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
