import 'package:equatable/equatable.dart';
import '../../../../core/entity/admin/admin_stats_entity.dart';
import '../../../../core/entity/admin/paginated_response.dart';
import '../../../../core/entity/report_entity.dart';
import '../../../../core/entity/user_entity.dart';


enum AdminStatus {
  initial,
  loading,
  success,
  error,
  actionSuccess, // Dùng khi update report thành công (để hiện snackbar)
}

class AdminState extends Equatable {
  final AdminStatus status;
  final String? errorMessage;

  // Dữ liệu Dashboard
  final AdminStatsEntity? stats;

  // Dữ liệu danh sách User
  final PaginatedResponse<UserEntity>? users;

  // Dữ liệu danh sách Report
  final PaginatedResponse<ReportEntity>? reports;

  const AdminState._({
    required this.status,
    this.errorMessage,
    this.stats,
    this.users,
    this.reports,
  });

  factory AdminState.initial() => const AdminState._(status: AdminStatus.initial);

  AdminState copyWith({
    AdminStatus? status,
    String? errorMessage,
    AdminStatsEntity? stats,
    PaginatedResponse<UserEntity>? users,
    PaginatedResponse<ReportEntity>? reports,
  }) {
    return AdminState._(
      status: status ?? this.status,
      errorMessage: errorMessage, // Reset lỗi nếu không truyền vào
      stats: stats ?? this.stats,
      users: users ?? this.users,
      reports: reports ?? this.reports,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, stats, users, reports];
}