import 'package:english_for_community/core/entity/app_update_info_entity.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/feature/app_update/bloc/app_update_bloc.dart';
import 'package:english_for_community/feature/app_update/bloc/app_update_event.dart';
import 'package:english_for_community/feature/app_update/bloc/app_update_state.dart';
import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:english_for_community/feature/auth/bloc/user_state.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateGuard extends StatefulWidget {
  final Widget child;

  const AppUpdateGuard({super.key, required this.child});

  @override
  State<AppUpdateGuard> createState() => _AppUpdateGuardState();
}

class _AppUpdateGuardState extends State<AppUpdateGuard>
    with WidgetsBindingObserver {
  bool _dialogShowing = false;
  int? _lastShownVersionCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userState = context.read<UserBloc>().state;
      if (userState.status == UserStatus.success) {
        context
            .read<AppUpdateBloc>()
            .add(AppUpdateCheckRequested(forceRefresh: true));
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final userState = context.read<UserBloc>().state;
      if (userState.status == UserStatus.success) {
        context
            .read<AppUpdateBloc>()
            .add(AppUpdateCheckRequested(forceRefresh: true));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<UserBloc, UserState>(
          listenWhen: (prev, next) => prev.status != next.status,
          listener: (context, state) {
            if (state.status == UserStatus.success) {
              context
                  .read<AppUpdateBloc>()
                  .add(AppUpdateCheckRequested(forceRefresh: true));
            }
          },
        ),
        BlocListener<AppUpdateBloc, AppUpdateState>(
          listenWhen: (prev, next) => prev.info != next.info,
          listener: (context, state) async {
            final info = state.info;
            if (info == null || !info.hasUpdate) return;
            if (_dialogShowing) return;
            if (_lastShownVersionCode == info.latestVersionCode &&
                info.status != AppUpdateStatus.forceUpdate) {
              return;
            }
            _dialogShowing = true;
            _lastShownVersionCode = info.latestVersionCode;
            await _showUpdateDialog(context, info);
            _dialogShowing = false;
          },
        ),
      ],
      child: widget.child,
    );
  }

  Future<void> _showUpdateDialog(
    BuildContext context,
    AppUpdateInfoEntity info,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: info.status != AppUpdateStatus.forceUpdate,
      useRootNavigator: true,
      builder: (dialogContext) {
        return _UpdateDialogContent(info: info);
      },
    );
  }
}

/// Dialog responsive: nút full-width trên màn nhỏ, nội dung cuộn được.
class _UpdateDialogContent extends StatelessWidget {
  const _UpdateDialogContent({required this.info});

  final AppUpdateInfoEntity info;

  Future<void> _openUpdateUrl(BuildContext context) async {
    final url = info.updateUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.updateLinkOpenFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mustUpdate = info.status == AppUpdateStatus.forceUpdate;

    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final screenH = mq.size.height;
    final insetH = screenW < 360 ? 12.0 : 20.0;
    final insetV = mq.padding.bottom > 0 ? 20.0 : 24.0;
    final stackActionsVertically = screenW < 480;

    final versionName =
        info.latestVersionName?.trim().isNotEmpty == true
            ? info.latestVersionName!.trim()
            : '—';

    final defaultBody =
        info.changelog.isNotEmpty ? info.changelog : l10n.updateAvailableBody;

    return PopScope(
      canPop: !mustUpdate,
      child: Dialog(
        insetPadding: EdgeInsets.fromLTRB(insetH, insetV * 1.5, insetH, insetV),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        elevation: 8,
        shadowColor: Colors.black26,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: screenH * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: mustUpdate
                    ? const Color(0xFFFEE2E2)
                    : AppColors.primary.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        mustUpdate
                            ? Icons.warning_amber_rounded
                            : Icons.system_update_rounded,
                        color: mustUpdate
                            ? const Color(0xFFDC2626)
                            : AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          mustUpdate
                              ? l10n.forceUpdateTitle
                              : l10n.updateAvailableTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Text(
                  l10n.updateDialogVersionLine(
                    versionName,
                    info.latestVersionCode,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: screenH * 0.42,
                ),
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (info.changelog.isNotEmpty) ...[
                        Text(
                          l10n.updateDialogWhatsNewTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      SelectableText(
                        defaultBody,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  stackActionsVertically ? 14 : 12,
                  12,
                  stackActionsVertically ? 14 : 12,
                  stackActionsVertically ? 14 : 14,
                ),
                child: stackActionsVertically
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton(
                            onPressed: () => _openUpdateUrl(context),
                            style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(l10n.updateNowButton),
                          ),
                          if (!mustUpdate) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(l10n.updateLaterButton),
                            ),
                          ],
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!mustUpdate)
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(l10n.updateLaterButton),
                            ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () => _openUpdateUrl(context),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(l10n.updateNowButton),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
