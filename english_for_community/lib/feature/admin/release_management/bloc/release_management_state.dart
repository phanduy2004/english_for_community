import 'package:english_for_community/core/entity/admin/app_release_admin_entity.dart';
import 'package:english_for_community/feature/admin/release_management/bloc/release_management_event.dart';
import 'package:equatable/equatable.dart';

enum ReleaseManagementStatus {
  initial,
  loading,
  success,
  error,
  actionRunning,
  actionSuccess
}

class ReleaseManagementState extends Equatable {
  final ReleaseManagementStatus status;
  final String selectedStatus;
  final String searchQuery;
  final ReleaseSortBy sortBy;
  final bool sortDescending;
  final String? errorMessage;
  final List<AppReleaseAdminEntity> allReleases;
  final List<AppReleaseAdminEntity> visibleReleases;
  final Map<String, int> statusCounts;

  const ReleaseManagementState({
    required this.status,
    required this.selectedStatus,
    required this.searchQuery,
    required this.sortBy,
    required this.sortDescending,
    required this.errorMessage,
    required this.allReleases,
    required this.visibleReleases,
    required this.statusCounts,
  });

  factory ReleaseManagementState.initial() {
    return const ReleaseManagementState(
      status: ReleaseManagementStatus.initial,
      selectedStatus: 'pending_approval',
      searchQuery: '',
      sortBy: ReleaseSortBy.createdAt,
      sortDescending: true,
      errorMessage: null,
      allReleases: [],
      visibleReleases: [],
      statusCounts: {},
    );
  }

  ReleaseManagementState copyWith({
    ReleaseManagementStatus? status,
    String? selectedStatus,
    String? searchQuery,
    ReleaseSortBy? sortBy,
    bool? sortDescending,
    String? errorMessage,
    bool clearError = false,
    List<AppReleaseAdminEntity>? allReleases,
    List<AppReleaseAdminEntity>? visibleReleases,
    Map<String, int>? statusCounts,
  }) {
    return ReleaseManagementState(
      status: status ?? this.status,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      allReleases: allReleases ?? this.allReleases,
      visibleReleases: visibleReleases ?? this.visibleReleases,
      statusCounts: statusCounts ?? this.statusCounts,
    );
  }

  @override
  List<Object?> get props => [
        status,
        selectedStatus,
        searchQuery,
        sortBy,
        sortDescending,
        errorMessage,
        allReleases,
        visibleReleases,
        statusCounts,
      ];
}
