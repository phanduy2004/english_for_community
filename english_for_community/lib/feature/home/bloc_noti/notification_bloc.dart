import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:english_for_community/core/entity/notification_entity.dart';
import 'package:english_for_community/core/repository/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository repository;

  /// Tránh hai [NotificationLoadMore] chạy song song (trùng trang).
  bool _isLoadingMore = false;

  NotificationBloc({required this.repository}) : super(const NotificationState()) {
    on<NotificationLoadStarted>(_onLoadStarted);
    on<NotificationLoadMore>(_onLoadMore);
    on<NotificationMarkRead>(_onMarkRead);
    on<NotificationMarkAllRead>(_onMarkAllRead);
    on<NotificationIncomingReceived>(_onIncomingReceived);
  }

  /// 1. Load lần đầu hoặc Refresh
  Future<void> _onLoadStarted(
      NotificationLoadStarted event,
      Emitter<NotificationState> emit,
      ) async {
    if (!event.isRefresh) {
      emit(state.copyWith(status: NotificationStatus.loading));
    }

    // Reset về trang 1
    final result = await repository.getNotifications(1);

    result.fold(
          (failure) => emit(state.copyWith(
        status: NotificationStatus.failure,
        errorMessage: failure.message,
      )),
          (data) {
        final List<NotificationEntity> items = data['items'];
        final int count = data['unreadCount'];
        final bool hasMore = data['hasMore'];

        emit(state.copyWith(
          status: NotificationStatus.success,
          notifications: items,
          unreadCount: count,
          hasReachedMax: !hasMore,
          page: 1,
        ));
      },
    );
  }

  /// 2. Load More (Phân trang)
  Future<void> _onLoadMore(
      NotificationLoadMore event,
      Emitter<NotificationState> emit,
      ) async {
    if (state.hasReachedMax ||
        state.status == NotificationStatus.loading ||
        _isLoadingMore) {
      return;
    }

    _isLoadingMore = true;
    final nextPage = state.page + 1;
    try {
      final result = await repository.getNotifications(nextPage);

      result.fold(
        (failure) => null,
        (data) {
          final List<NotificationEntity> newItems = data['items'];
          final bool hasMore = data['hasMore'];

          emit(state.copyWith(
            notifications: List.of(state.notifications)..addAll(newItems),
            hasReachedMax: !hasMore,
            page: nextPage,
          ));
        },
      );
    } finally {
      _isLoadingMore = false;
    }
  }

  /// 3. Đánh dấu 1 tin đã đọc
  Future<void> _onMarkRead(
      NotificationMarkRead event,
      Emitter<NotificationState> emit,
      ) async {
    // --- OPTIMISTIC UPDATE: Cập nhật UI ngay lập tức ---
    final index = state.notifications.indexWhere((e) => e.id == event.id);
    if (index == -1) return;

    final item = state.notifications[index];
    if (item.isRead) return; // Nếu đã đọc rồi thì thôi

    final updatedList = List<NotificationEntity>.from(state.notifications);
    updatedList[index] = item.copyWith(isRead: true);

    // Giảm số lượng chưa đọc đi 1 (nếu > 0)
    final newCount = (state.unreadCount - 1).clamp(0, 999);

    emit(state.copyWith(
      notifications: updatedList,
      unreadCount: newCount,
    ));

    // --- GỌI API (Không cần chờ kết quả để UI mượt hơn) ---
    await repository.markAsRead(event.id);
  }

  /// 4. Đánh dấu tất cả đã đọc
  Future<void> _onMarkAllRead(
      NotificationMarkAllRead event,
      Emitter<NotificationState> emit,
      ) async {
    // --- OPTIMISTIC UPDATE ---
    final updatedList = state.notifications.map((e) => e.copyWith(isRead: true)).toList();

    emit(state.copyWith(
      notifications: updatedList,
      unreadCount: 0,
    ));

    // --- GỌI API ---
    await repository.markAllAsRead();
  }

  /// 5. Nhận Socket Realtime
  void _onIncomingReceived(
      NotificationIncomingReceived event,
      Emitter<NotificationState> emit,
      ) {
    final updatedList = List<NotificationEntity>.from(state.notifications)
      ..insert(0, event.notification);
    emit(state.copyWith(
      notifications: updatedList,
      unreadCount: state.unreadCount + 1,
    ));
  }
}