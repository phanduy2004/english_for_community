import 'package:bloc/bloc.dart';
import 'package:english_for_community/core/entity/admin/app_release_admin_entity.dart';
import 'package:english_for_community/core/repository/app_release_repository.dart';
import 'package:english_for_community/feature/admin/release_management/bloc/release_management_event.dart';
import 'package:english_for_community/feature/admin/release_management/bloc/release_management_state.dart';

class ReleaseManagementBloc
    extends Bloc<ReleaseManagementEvent, ReleaseManagementState> {
  final AppReleaseRepository repository;

  ReleaseManagementBloc({required this.repository})
      : super(ReleaseManagementState.initial()) {
    on<ReleaseLoadRequested>(_onLoadRequested);
    on<ReleaseSearchChanged>(_onSearchChanged);
    on<ReleaseSortChanged>(_onSortChanged);
    on<ReleaseActionRequested>(_onActionRequested);
  }

  Future<void> _onLoadRequested(
    ReleaseLoadRequested event,
    Emitter<ReleaseManagementState> emit,
  ) async {
    emit(state.copyWith(
      status: ReleaseManagementStatus.loading,
      selectedStatus: event.status,
      clearError: true,
    ));

    final result = await repository.getReleases(status: event.status);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ReleaseManagementStatus.error,
        errorMessage: failure.message,
      )),
      (data) {
        final visible = _applyView(
          source: data,
          query: state.searchQuery,
          sortBy: state.sortBy,
          desc: state.sortDescending,
        );
        emit(state.copyWith(
          status: ReleaseManagementStatus.success,
          allReleases: data,
          visibleReleases: visible,
          statusCounts: _buildStatusCounts(data),
          clearError: true,
        ));
      },
    );
  }

  void _onSearchChanged(
    ReleaseSearchChanged event,
    Emitter<ReleaseManagementState> emit,
  ) {
    final visible = _applyView(
      source: state.allReleases,
      query: event.query,
      sortBy: state.sortBy,
      desc: state.sortDescending,
    );
    emit(state.copyWith(
      searchQuery: event.query,
      visibleReleases: visible,
    ));
  }

  void _onSortChanged(
    ReleaseSortChanged event,
    Emitter<ReleaseManagementState> emit,
  ) {
    final visible = _applyView(
      source: state.allReleases,
      query: state.searchQuery,
      sortBy: event.sortBy,
      desc: event.descending,
    );
    emit(state.copyWith(
      sortBy: event.sortBy,
      sortDescending: event.descending,
      visibleReleases: visible,
    ));
  }

  Future<void> _onActionRequested(
    ReleaseActionRequested event,
    Emitter<ReleaseManagementState> emit,
  ) async {
    emit(state.copyWith(
        status: ReleaseManagementStatus.actionRunning, clearError: true));
    final result = await repository.runAction(
      action: event.action,
      releaseId: event.releaseId,
      payload: event.payload,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        status: ReleaseManagementStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(status: ReleaseManagementStatus.actionSuccess));
        add(ReleaseLoadRequested(status: state.selectedStatus));
      },
    );
  }

  Map<String, int> _buildStatusCounts(List<AppReleaseAdminEntity> rows) {
    final map = <String, int>{};
    for (final row in rows) {
      map[row.status] = (map[row.status] ?? 0) + 1;
    }
    return map;
  }

  List<AppReleaseAdminEntity> _applyView({
    required List<AppReleaseAdminEntity> source,
    required String query,
    required ReleaseSortBy sortBy,
    required bool desc,
  }) {
    final q = query.trim().toLowerCase();
    final filtered = source.where((e) {
      if (q.isEmpty) return true;
      final text =
          '${e.platform} ${e.environment} ${e.versionName} ${e.versionCode} ${e.status} ${e.gitSha ?? ''}'
              .toLowerCase();
      return text.contains(q);
    }).toList();

    filtered.sort((a, b) {
      int cmp;
      switch (sortBy) {
        case ReleaseSortBy.versionCode:
          cmp = a.versionCode.compareTo(b.versionCode);
          break;
        case ReleaseSortBy.status:
          cmp = a.status.compareTo(b.status);
          break;
        case ReleaseSortBy.createdAt:
          final ad = a.createdAt?.millisecondsSinceEpoch ?? 0;
          final bd = b.createdAt?.millisecondsSinceEpoch ?? 0;
          cmp = ad.compareTo(bd);
          break;
      }
      return desc ? -cmp : cmp;
    });
    return filtered;
  }
}
