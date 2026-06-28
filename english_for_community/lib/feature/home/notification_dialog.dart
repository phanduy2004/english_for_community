import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/utils/global_keys.dart';
import 'package:english_for_community/feature/home/bloc_noti/notification_bloc.dart';
import 'package:english_for_community/feature/home/bloc_noti/notification_event.dart';
import 'package:english_for_community/feature/home/notification_inbox_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

bool _notificationDialogOpen = false;

/// True while the shared notification inbox dialog is on screen.
bool get isNotificationDialogVisible => _notificationDialogOpen;

void showAppNotificationsDialog(BuildContext context) {
  if (_notificationDialogOpen) return;

  final bloc = getIt<NotificationBloc>();
  bloc.add(const NotificationLoadStarted(isRefresh: true));

  _notificationDialogOpen = true;
  showDialog<void>(
    context: rootNavigatorKey.currentContext ?? context,
    builder: (ctx) => BlocProvider.value(
      value: bloc,
      child: const NotificationDialog(),
    ),
  ).whenComplete(() {
    _notificationDialogOpen = false;
  });
}

/// Shared notification inbox dialog — student mobile, teacher web, and admin.
class NotificationDialog extends StatelessWidget {
  const NotificationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 600;

    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      elevation: 0,
      insetPadding: EdgeInsets.all(isCompact ? AppSpacing.s5 : AppSpacing.s6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sheet + 2),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isCompact ? double.infinity : 400,
          maxHeight: isCompact ? size.height * 0.75 : 560,
        ),
        child: SizedBox(
          width: isCompact ? double.infinity : null,
          height: isCompact ? size.height * 0.75 : null,
          child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s6, AppSpacing.s5, AppSpacing.s4, AppSpacing.s4),
              child: Row(
                children: [
                  Expanded(child: Text(t.notificationsTitle, style: StudentMobileUi.sectionTitle(context))),
                  TextButton(
                    onPressed: () {
                      context.read<NotificationBloc>().add(NotificationMarkAllRead());
                    },
                    child: Text(t.markAllRead),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.outline),
            const Expanded(
              child: NotificationInboxBody(closeBeforeNavigate: true),
            ),
            const Divider(height: 1, color: AppColors.outline),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s3),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t.close),
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
