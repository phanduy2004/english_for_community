import 'package:english_for_community/core/repository/admin_repository.dart';
import 'package:english_for_community/feature/admin/analytics/bloc/admin_analytics_event.dart';
import 'package:english_for_community/feature/admin/analytics/bloc/admin_analytics_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminAnalyticsBloc extends Bloc<AdminAnalyticsEvent, AdminAnalyticsState> {
  AdminAnalyticsBloc({required this.repository}) : super(AdminAnalyticsState.initial()) {
    on<AdminAnalyticsLoadRequested>(_onLoad);
    on<AdminAnalyticsRangeChanged>(_onRangeChanged);
  }

  final AdminRepository repository;

  Future<void> _onLoad(
    AdminAnalyticsLoadRequested event,
    Emitter<AdminAnalyticsState> emit,
  ) async {
    emit(state.copyWith(
        status: AdminAnalyticsStatus.loading, range: event.range, clearError: true));
    final r = await repository.getUserAnalytics(range: event.range);
    r.fold(
      (f) => emit(state.copyWith(
        status: AdminAnalyticsStatus.error,
        errorMessage: f.message,
      )),
      (d) => emit(state.copyWith(
        status: AdminAnalyticsStatus.success,
        range: event.range,
        data: Map<String, dynamic>.from(d),
      )),
    );
  }

  Future<void> _onRangeChanged(
    AdminAnalyticsRangeChanged event,
    Emitter<AdminAnalyticsState> emit,
  ) async {
    add(AdminAnalyticsLoadRequested(range: event.range));
  }
}
