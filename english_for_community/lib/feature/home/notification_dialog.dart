import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/feature/home/bloc_noti/notification_bloc.dart';
import 'package:english_for_community/feature/home/bloc_noti/notification_event.dart';
import 'package:english_for_community/feature/home/notification_inbox_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Desktop/web dialog inbox — teacher & admin on wide screens.
class NotificationDialog extends StatelessWidget {
  const NotificationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sheet + 2),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
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
    );
  }
}
