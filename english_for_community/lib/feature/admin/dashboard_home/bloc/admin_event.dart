// feature/admin/dashboard_home/bloc/admin_event.dart

abstract class AdminEvent {}

class GetDashboardStatsEvent extends AdminEvent {
  final String range;
  GetDashboardStatsEvent({this.range = 'week'});
}

class GetAllUsersEvent extends AdminEvent {
  final int page;
  final int limit;
  final String filter;
  final String? search;

  GetAllUsersEvent({
    this.page = 1,
    this.limit = 20,
    this.filter = 'all',
    this.search,
  });
}

class GetReportsEvent extends AdminEvent {
  final int page;
  final int limit;
  final String? status;

  GetReportsEvent({this.page = 1, this.limit = 20, this.status});
}

class UpdateReportStatusEvent extends AdminEvent {
  final String reportId;
  final String status;
  final String? adminResponse;

  UpdateReportStatusEvent({
    required this.reportId,
    required this.status,
    this.adminResponse,
  });
}

// --- 🆕 SỰ KIỆN MỚI CHO USER ACTIONS ---

class BanUserEvent extends AdminEvent {
  final String userId;
  final String banType; // 'permanent', 'temporary', 'unban'
  final int? durationInHours;
  final String? reason;

  BanUserEvent({
    required this.userId,
    required this.banType,
    this.durationInHours,
    this.reason
  });
}

class DeleteUserEvent extends AdminEvent {
  final String userId;
  DeleteUserEvent({required this.userId});
}