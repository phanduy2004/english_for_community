// feature/admin/dashboard_home/bloc/admin_bloc.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../../../core/entity/admin/paginated_response.dart';
import '../../../../core/entity/report_entity.dart';
import '../../../../core/entity/user_entity.dart';
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
    on<BanUserEvent>(_onBanUser);
    on<DeleteUserEvent>(_onDeleteUser);
  }

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

// 🔥 SỬA: Xử lý GetReports trả về PaginatedResponse
  Future<void> _onGetReports(
      GetReportsEvent event, Emitter<AdminState> emit) async {
    emit(state.copyWith(status: AdminStatus.loading));

    // Gọi Repository (Repository trả về Either<Failure, PaginatedResponse<ReportEntity>>)
    final result = await adminRepository.getReports(
      page: event.page, limit: event.limit, status: event.status,
    );

    result.fold(
          (failure) => emit(state.copyWith(status: AdminStatus.error, errorMessage: failure.message)),
          (paginatedData) => emit(state.copyWith(status: AdminStatus.success, reports: paginatedData)),
    );
  }

  // 🔥 SỬA: Logic cập nhật 1 item trong PaginatedResponse
  Future<void> _onUpdateReportStatus(
      UpdateReportStatusEvent event, Emitter<AdminState> emit) async {
    // Không emit loading toàn màn hình ở đây để UX mượt hơn (hoặc tùy bạn)
    // emit(state.copyWith(status: AdminStatus.loading));

    final result = await adminRepository.updateReportStatus(
      id: event.reportId, status: event.status, adminResponse: event.adminResponse,
    );

    result.fold(
          (failure) => emit(state.copyWith(status: AdminStatus.error, errorMessage: failure.message)),
          (updatedReport) {
        // Lấy danh sách hiện tại
        PaginatedResponse<ReportEntity>? currentReports = state.reports;

        if (currentReports != null) {
          // Tạo list mới đã cập nhật item
          final updatedList = currentReports.data.map((r) => r.id == updatedReport.id ? updatedReport : r).toList();

          // Gán lại vào object PaginatedResponse mới
          currentReports = PaginatedResponse(
              data: updatedList,
              pagination: currentReports.pagination
          );
        }

        // Emit state mới
        emit(state.copyWith(
            status: AdminStatus.actionSuccess, // Để UI hiện snackbar "Thành công"
            reports: currentReports
        ));

        // Reset về success để không hiện snackbar liên tục
        emit(state.copyWith(status: AdminStatus.success));
      },
    );
  }
  Future<void> _onBanUser(
      BanUserEvent event, Emitter<AdminState> emit) async {
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
        PaginatedResponse<UserEntity>? currentUsers = state.users;

        if (currentUsers != null) {
          final updatedList = currentUsers.data.map((u) {
            return u.id == updatedUser.id ? updatedUser : u;
          }).toList();

          currentUsers = PaginatedResponse(
              data: updatedList,
              pagination: currentUsers.pagination
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

  Future<void> _onDeleteUser(
      DeleteUserEvent event, Emitter<AdminState> emit) async {
    emit(state.copyWith(status: AdminStatus.loading));

    final result = await adminRepository.deleteUser(event.userId);

    result.fold(
          (failure) {
        emit(state.copyWith(status: AdminStatus.error, errorMessage: failure.message));
      },
          (_) {
        PaginatedResponse<UserEntity>? currentUsers = state.users;

        if (currentUsers != null) {
          final updatedList = currentUsers.data.where((u) => u.id != event.userId).toList();

          currentUsers = PaginatedResponse(
              data: updatedList,
              pagination: currentUsers.pagination
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