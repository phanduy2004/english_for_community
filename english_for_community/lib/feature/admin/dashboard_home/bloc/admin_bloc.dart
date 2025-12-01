import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../../../core/entity/admin/paginated_response.dart';
import '../../../../core/entity/report_entity.dart';
import '../../../../core/entity/user_entity.dart'; // Import UserEntity
import '../../../../core/repository/admin_repository.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository adminRepository;

  AdminBloc({required this.adminRepository}) : super(AdminState.initial()) {
    on<GetDashboardStatsEvent>(_onGetDashboardStats);
    on<GetAllUsersEvent>(_onGetAllUsers);
    on<GetReportsEvent>(_onGetReports);
    on<UpdateReportStatusEvent>(_onUpdateReportStatus);

    // --- Đăng ký Event mới ---
    on<BanUserEvent>(_onBanUser);
    on<DeleteUserEvent>(_onDeleteUser);
  }

  // ... (Các hàm cũ _onGetDashboardStats, _onGetAllUsers, _onGetReports, _onUpdateReportStatus GIỮ NGUYÊN) ...

  Future<void> _onGetDashboardStats(
      GetDashboardStatsEvent event, Emitter<AdminState> emit) async {
    emit(state.copyWith(status: AdminStatus.loading));
    final result = await adminRepository.getDashboardStats(range: event.range);
    result.fold(
          (failure) => emit(state.copyWith(status: AdminStatus.error, errorMessage: failure.message)),
          (data) => emit(state.copyWith(status: AdminStatus.success, stats: data)),
    );
  }

  Future<void> _onGetAllUsers(
      GetAllUsersEvent event, Emitter<AdminState> emit) async {
    emit(state.copyWith(status: AdminStatus.loading));
    final result = await adminRepository.getAllUsers(
        page: event.page, limit: event.limit, filter: event.filter, search: event.search
    );
    result.fold(
          (failure) => emit(state.copyWith(status: AdminStatus.error, errorMessage: failure.message)),
          (data) => emit(state.copyWith(status: AdminStatus.success, users: data)),
    );
  }

  Future<void> _onGetReports(
      GetReportsEvent event, Emitter<AdminState> emit) async {
    emit(state.copyWith(status: AdminStatus.loading));
    final result = await adminRepository.getReports(
      page: event.page, limit: event.limit, status: event.status,
    );
    result.fold(
          (failure) => emit(state.copyWith(status: AdminStatus.error, errorMessage: failure.message)),
          (data) => emit(state.copyWith(status: AdminStatus.success, reports: data)),
    );
  }

  Future<void> _onUpdateReportStatus(
      UpdateReportStatusEvent event, Emitter<AdminState> emit) async {
    emit(state.copyWith(status: AdminStatus.loading));
    final result = await adminRepository.updateReportStatus(
      reportId: event.reportId, status: event.status, adminResponse: event.adminResponse,
    );
    result.fold(
          (failure) => emit(state.copyWith(status: AdminStatus.error, errorMessage: failure.message)),
          (updatedReport) {
        PaginatedResponse<ReportEntity>? currentReports = state.reports;
        if (currentReports != null) {
          final updatedList = currentReports.data.map((r) => r.id == updatedReport.id ? updatedReport : r).toList();
          currentReports = PaginatedResponse(data: updatedList, pagination: currentReports.pagination);
        }
        emit(state.copyWith(status: AdminStatus.actionSuccess, reports: currentReports));
        emit(state.copyWith(status: AdminStatus.success));
      },
    );
  }

  // --- 🆕 LOGIC XỬ LÝ BAN USER ---
  Future<void> _onBanUser(
      BanUserEvent event, Emitter<AdminState> emit) async {
    // Bật loading
    emit(state.copyWith(status: AdminStatus.loading));

    final result = await adminRepository.banUser(
      userId: event.userId,
      banType: event.banType,
      durationInHours: event.durationInHours,
      reason: event.reason,
    );

    result.fold(
          (failure) {
        emit(state.copyWith(status: AdminStatus.error, errorMessage: failure.message));
      },
          (updatedUser) {
        // Cập nhật trực tiếp user đã thay đổi vào danh sách (Optimistic update)
        PaginatedResponse<UserEntity>? currentUsers = state.users;

        if (currentUsers != null) {
          final updatedList = currentUsers.data.map((u) {
            // Tìm đúng user đó và thay thế bằng user mới (đã có isBanned=true/false)
            return u.id == updatedUser.id ? updatedUser : u;
          }).toList();

          currentUsers = PaginatedResponse(
              data: updatedList,
              pagination: currentUsers.pagination
          );
        }

        emit(state.copyWith(
            status: AdminStatus.actionSuccess, // Để UI hiện thông báo
            users: currentUsers
        ));

        // Reset status về success
        emit(state.copyWith(status: AdminStatus.success));
      },
    );
  }

  // --- 🆕 LOGIC XỬ LÝ DELETE USER ---
  Future<void> _onDeleteUser(
      DeleteUserEvent event, Emitter<AdminState> emit) async {
    emit(state.copyWith(status: AdminStatus.loading));

    final result = await adminRepository.deleteUser(event.userId);

    result.fold(
          (failure) {
        emit(state.copyWith(status: AdminStatus.error, errorMessage: failure.message));
      },
          (_) {
        // Xóa user khỏi danh sách hiện tại
        PaginatedResponse<UserEntity>? currentUsers = state.users;

        if (currentUsers != null) {
          // Lọc bỏ user có id trùng với id đã xóa
          final updatedList = currentUsers.data.where((u) => u.id != event.userId).toList();

          currentUsers = PaginatedResponse(
              data: updatedList,
              pagination: currentUsers.pagination // Có thể giảm total nếu cần
          );
        }

        emit(state.copyWith(
            status: AdminStatus.actionSuccess,
            users: currentUsers
        ));
        emit(state.copyWith(status: AdminStatus.success));
      },
    );
  }
}