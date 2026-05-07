abstract class AppUpdateEvent {}

class AppUpdateCheckRequested extends AppUpdateEvent {
  final bool forceRefresh;

  AppUpdateCheckRequested({this.forceRefresh = false});
}
