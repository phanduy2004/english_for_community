import 'package:english_for_community/core/entity/notification_entity.dart';

/// Parsed on a background isolate so the loading spinner stays smooth.
({List<NotificationEntity> items, int unreadCount, bool hasMore}) parseNotificationPage(
  Map<String, dynamic> res,
) {
  final data = res['data'];
  final List<dynamic> rawList = data is List ? data : const [];
  final items = rawList
      .map(
        (e) => NotificationEntity.fromJson(
          Map<String, dynamic>.from(e as Map),
        ),
      )
      .toList();
  final pagination = res['pagination'];
  final hasMore = pagination is Map ? (pagination['hasMore'] == true) : false;
  return (
    items: items,
    unreadCount: (res['unreadCount'] as num?)?.toInt() ?? 0,
    hasMore: hasMore,
  );
}
