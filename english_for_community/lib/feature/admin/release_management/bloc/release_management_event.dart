enum ReleaseSortBy { createdAt, versionCode, status }

abstract class ReleaseManagementEvent {}

class ReleaseLoadRequested extends ReleaseManagementEvent {
  final String status;

  ReleaseLoadRequested({required this.status});
}

class ReleaseSearchChanged extends ReleaseManagementEvent {
  final String query;

  ReleaseSearchChanged(this.query);
}

class ReleaseSortChanged extends ReleaseManagementEvent {
  final ReleaseSortBy sortBy;
  final bool descending;

  ReleaseSortChanged({required this.sortBy, required this.descending});
}

class ReleaseActionRequested extends ReleaseManagementEvent {
  final String action;
  final String releaseId;
  final Map<String, dynamic>? payload;

  ReleaseActionRequested({
    required this.action,
    required this.releaseId,
    this.payload,
  });
}
