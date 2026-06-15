import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/feature/home/bloc_noti/notification_bloc.dart';
import 'package:english_for_community/feature/home/bloc_noti/notification_event.dart';
import 'package:english_for_community/feature/home/notification_inbox_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Full-screen notification inbox for student mobile (native Android/iOS).
class NotificationsPage extends StatelessWidget {
  static const String routeName = 'NotificationsPage';
  static const String routePath = '/notifications';

  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final bloc = getIt<NotificationBloc>();

    return BlocProvider.value(
      value: bloc,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: StudentMobileUi.appBar(
          context,
          title: t.notificationsTitle,
          actions: [
            TextButton(
              onPressed: () {
                context.read<NotificationBloc>().add(NotificationMarkAllRead());
              },
              child: Text(t.markAllRead),
            ),
          ],
        ),
        body: const SafeArea(
          top: false,
          child: NotificationInboxBody(closeBeforeNavigate: false),
        ),
      ),
    );
  }
}
