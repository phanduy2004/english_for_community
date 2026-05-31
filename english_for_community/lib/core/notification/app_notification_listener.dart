import 'dart:convert';

import 'package:english_for_community/core/entity/notification_entity.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/notification/local_notification_service.dart';
import 'package:english_for_community/core/socket/socket_service.dart';
import 'package:english_for_community/core/utils/global_keys.dart';
import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:english_for_community/feature/auth/bloc/user_state.dart';
import 'package:english_for_community/feature/home/bloc_noti/notification_bloc.dart';
import 'package:english_for_community/feature/home/bloc_noti/notification_event.dart';
import 'package:english_for_community/feature/home/notification_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Subscribes to socket `new_notification` for any authenticated user (student or teacher).
class AppNotificationListener extends StatefulWidget {
  const AppNotificationListener({super.key, required this.child});

  final Widget child;

  @override
  State<AppNotificationListener> createState() => _AppNotificationListenerState();
}

class _AppNotificationListenerState extends State<AppNotificationListener> {
  bool _socketNotiBound = false;

  Map<String, dynamic> _normalizeSocketMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw FormatException('Expected Map, got ${raw.runtimeType}');
  }

  void _showForegroundBanner(String title, String body) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    AppCornerToast.show(
      ctx,
      body.isEmpty ? title : '$title\n$body',
      duration: const Duration(seconds: 5),
    );
  }

  void _bindSocketNotifications(String userId) {
    final socket = getIt<SocketService>();
    socket.userLogin(userId);

    if (_socketNotiBound) return;
    _socketNotiBound = true;

    final bloc = getIt<NotificationBloc>();
    socket.listenToNotifications((data) {
      try {
        final map = _normalizeSocketMap(data);
        final noti = NotificationEntity.fromJson(map);
        bloc.add(NotificationIncomingReceived(noti));

        var senderName = '';
        if (map['senderId'] is Map) {
          senderName = map['senderId']['fullName']?.toString() ?? '';
        }
        final serverMessage = map['message']?.toString() ?? '';
        final displayBody = '$senderName $serverMessage'.trim();
        final title = map['title']?.toString() ?? 'Notification';

        if (kDebugMode) {
          debugPrint('🔔 [Socket] ${noti.type}: $title');
        }

        if (kIsWeb) {
          _showForegroundBanner(title, displayBody.isEmpty ? serverMessage : displayBody);
        } else {
          String? payload;
          if (map['data'] != null) {
            final d = _normalizeSocketMap(map['data']);
            d['type'] ??= map['type']?.toString() ?? noti.type;
            payload = jsonEncode(d);
          } else if (map['type'] != null) {
            payload = jsonEncode({'type': map['type']});
          }
          LocalNotificationService().showInstantNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: title,
            body: displayBody.isEmpty ? serverMessage : displayBody,
            payload: payload,
          );
        }
      } catch (e, st) {
        debugPrint('[AppNotificationListener] parse error: $e\n$st');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status || prev.userEntity?.id != curr.userEntity?.id,
      listener: (context, state) {
        if (state.status == UserStatus.success && state.userEntity != null) {
          _bindSocketNotifications(state.userEntity!.id);
          getIt<NotificationBloc>().add(const NotificationLoadStarted(isRefresh: true));
        } else if (state.status == UserStatus.unauthenticated) {
          _socketNotiBound = false;
        }
      },
      child: widget.child,
    );
  }
}

void showAppNotificationsDialog(BuildContext context) {
  final bloc = getIt<NotificationBloc>();
  bloc.add(const NotificationLoadStarted(isRefresh: true));
  showDialog<void>(
    context: rootNavigatorKey.currentContext ?? context,
    builder: (ctx) => BlocProvider.value(
      value: bloc,
      child: const NotificationDialog(),
    ),
  );
}
