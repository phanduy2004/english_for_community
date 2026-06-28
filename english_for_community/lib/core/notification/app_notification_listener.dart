import 'dart:convert';

import 'package:english_for_community/core/entity/notification_entity.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/notification/local_notification_service.dart';
import 'package:english_for_community/core/notification/notification_navigation.dart';
import 'package:english_for_community/core/notification/notification_payload.dart';
import 'package:english_for_community/core/socket/socket_service.dart';
import 'package:english_for_community/core/ui/feedback/app_in_app_banner.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/core/ui/workspace_layout_scope.dart';
import 'package:english_for_community/core/utils/global_keys.dart';
import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:english_for_community/feature/auth/bloc/user_state.dart';
import 'package:english_for_community/feature/home/bloc_noti/notification_bloc.dart';
import 'package:english_for_community/feature/home/bloc_noti/notification_event.dart';
import 'package:english_for_community/feature/home/notification_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Student learner app — not teacher/admin web workspace.
bool isStudentLearnerApp([BuildContext? context]) {
  final ctx = context ?? rootNavigatorKey.currentContext;
  if (ctx != null) {
    return !WorkspaceLayoutScope.isWebWorkspace(ctx);
  }
  final role = getIt<UserBloc>().state.userEntity?.role ?? 'user';
  return role == 'user';
}

bool _appInForeground() {
  final state = WidgetsBinding.instance.lifecycleState;
  return state == null || state == AppLifecycleState.resumed;
}

bool _notificationTargetsCurrentRoute(GoRouter router, Map<String, dynamic> payload) {
  final location = router.state.uri.toString();
  final classroomId = payload['classroomId']?.toString();
  if (classroomId != null && classroomId.isNotEmpty && location.contains(classroomId)) {
    return true;
  }
  final attemptId = payload['attemptId']?.toString();
  if (attemptId != null && attemptId.isNotEmpty && location.contains(attemptId)) {
    return true;
  }
  final sessionId = payload['sessionId']?.toString();
  if (sessionId != null && sessionId.isNotEmpty && location.contains(sessionId)) {
    return true;
  }
  if (isNotificationDialogVisible) {
    return true;
  }
  return false;
}

/// Subscribes to socket `new_notification` for authenticated users.
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

  void _presentStudentNotification(
    Map<String, dynamic> map,
    NotificationEntity noti,
    String title,
    String displayBody,
  ) {
    final payload = buildNotificationPayload(map);
    final payloadMap = payload != null
        ? Map<String, dynamic>.from(jsonDecode(payload) as Map)
        : <String, dynamic>{'type': noti.type};

    final ctx = rootNavigatorKey.currentContext;
    final router = ctx != null ? GoRouter.maybeOf(ctx) : null;
    final onTargetScreen = router != null && _notificationTargetsCurrentRoute(router, payloadMap);

    if (_appInForeground()) {
      if (onTargetScreen) {
        // Inbox/list already updated via bloc — no banner or push.
        return;
      }
      AppInAppBanner.show(
        title: title,
        body: displayBody,
        dedupKey: noti.id,
        onTap: () {
          if (router == null) return;
          final ctx = rootNavigatorKey.currentContext;
          if (!navigateFromNotification(router, item: noti, data: payloadMap) && ctx != null) {
            showAppNotificationsDialog(ctx);
          }
        },
      );
      return;
    }

    LocalNotificationService().showInstantNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: displayBody.isEmpty ? title : displayBody,
      payload: payload,
    );
  }

  void _presentTeacherWebBanner(String title, String body) {
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

        final ctx = rootNavigatorKey.currentContext;
        if (isStudentLearnerApp(ctx)) {
          _presentStudentNotification(map, noti, title, displayBody);
        } else if (ctx != null && WorkspaceLayoutScope.isWebWorkspace(ctx)) {
          _presentTeacherWebBanner(title, displayBody.isEmpty ? serverMessage : displayBody);
        } else {
          // Teacher on native mobile — system tray when background.
          final payload = buildNotificationPayload(map);
          if (_appInForeground()) {
            _presentTeacherWebBanner(title, displayBody.isEmpty ? serverMessage : displayBody);
          } else {
            LocalNotificationService().showInstantNotification(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: title,
              body: displayBody.isEmpty ? serverMessage : displayBody,
              payload: payload,
            );
          }
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
