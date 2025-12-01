import '../entity/user_entity.dart';

class ReportEntity {
  final String id;
  final UserEntity? user; // Backend populate user
  final String type;
  final String title;
  final String description;
  final String status;
  final String? adminResponse;
  final DateTime createdAt;

  ReportEntity({
    required this.id,
    this.user,
    required this.type,
    required this.title,
    required this.description,
    required this.status,
    this.adminResponse,
    required this.createdAt,
  });

  factory ReportEntity.fromJson(Map<String, dynamic> json) {
    return ReportEntity(
      id: json['_id'],
      // Nếu populate trả về object thì parse UserEntity, nếu chỉ ID string thì để null hoặc xử lý khác
      user: json['userId'] is Map<String, dynamic> ? UserEntity.fromJson(json['userId']) : null,
      type: json['type'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      adminResponse: json['adminResponse'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}