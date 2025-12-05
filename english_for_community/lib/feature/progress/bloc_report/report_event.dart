import 'package:equatable/equatable.dart';

abstract class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object> get props => [];
}

// Sự kiện gửi báo cáo
class SendReportEvent extends ReportEvent {
  final String type; // 'bug', 'feature', ...
  final String title;
  final String description;
  final List<String> images;
  final Map<String, dynamic> deviceData;

  const SendReportEvent({
    required this.type,
    required this.title,
    required this.description,
    required this.images,
    required this.deviceData,
  });

  @override
  List<Object> get props => [type, title, description, images, deviceData];
}