import 'dart:io';

import 'package:english_for_community/core/entity/app_update_info_entity.dart';
import 'package:english_for_community/core/ui/feedback/app_feedback.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/utils/global_keys.dart';
import 'package:english_for_community/feature/app_update/app_apk_updater.dart';
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
  AppUpdateInfoEntity? _pendingUpdate;
  int? _handledVersionCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Version-check là API public: phải chạy cả khi chưa đăng nhập để soft/force
      // update vẫn hiện trên splasdh/login.
      context
          .read<AppUpdateBloc>()
          .add(AppUpdateCheckRequested(forceRefresh: true));
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
      if (!mounted) return;
      context
          .read<AppUpdateBloc>()
          .add(AppUpdateCheckRequested(forceRefresh: true));
      _tryShowPending();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<UserBloc, UserState>(
          listenWhen: (prev, next) =>
              prev.status != next.status &&
              (next.status == UserStatus.success ||
                  next.status == UserStatus.unauthenticated),
          listener: (context, state) {
            context
                .read<AppUpdateBloc>()
                .add(AppUpdateCheckRequested(forceRefresh: true));
            _tryShowPending();
          },
        ),
        BlocListener<AppUpdateBloc, AppUpdateState>(
          listenWhen: (prev, next) => prev.info != next.info,
          listener: (context, state) {
            final info = state.info;
            if (info == null || !info.hasUpdate) {
              _pendingUpdate = null;
              return;
            }
            _pendingUpdate = info;
            _tryShowPending();
          },
        ),
      ],
      child: widget.child,
    );
  }

  void _tryShowPending() {
    if (!mounted) return;
    final info = _pendingUpdate;
    if (info == null || _dialogShowing) return;

    final authStatus = context.read<UserBloc>().state.status;
    if (authStatus == UserStatus.initial || authStatus == UserStatus.loading) {
      return;
    }

    if (_handledVersionCode == info.latestVersionCode &&
        info.status != AppUpdateStatus.forceUpdate) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _dialogShowing || _pendingUpdate == null) return;
      _dialogShowing = true;
      final result = await _showUpdateDialog(info);
      if (!mounted) return;
      _dialogShowing = false;
      if (result == true) {
        _handledVersionCode = info.latestVersionCode;
        _pendingUpdate = null;
      }
    });
  }

  Future<bool?> _showUpdateDialog(AppUpdateInfoEntity info) async {
    final host = rootNavigatorKey.currentContext;
    if (host == null) return null;

    return showDialog<bool>(
      context: host,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        return _UpdateDialogContent(info: info);
      },
    );
  }
}

/// Dialog responsive: nút full-width trên màn nhỏ, nội dung cuộn được.
class _UpdateDialogContent extends StatefulWidget {
  const _UpdateDialogContent({required this.info});

  final AppUpdateInfoEntity info;

  @override
  State<_UpdateDialogContent> createState() => _UpdateDialogContentState();
}

class _UpdateDialogContentState extends State<_UpdateDialogContent> {
  final AppApkUpdater _updater = AppApkUpdater();
  ApkUpdateProgress _progress = const ApkUpdateProgress(ApkUpdateStage.idle);
  bool _cancelRequested = false;

  bool get _isBusy =>
      _progress.stage == ApkUpdateStage.checkingPermission ||
      _progress.stage == ApkUpdateStage.downloading ||
      _progress.stage == ApkUpdateStage.opening;

  bool get _hasError => _progress.stage == ApkUpdateStage.error;

  @override
  void dispose() {
    _updater.dispose();
    super.dispose();
  }

  void _setProgress(ApkUpdateProgress progress) {
    if (!mounted || _cancelRequested) return;
    setState(() => _progress = progress);
  }

  Future<void> _openUpdateUrl(BuildContext context) async {
    final url = widget.info.updateUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      AppFeedback.error(context, l10n.updateLinkOpenFailed);
    }
  }

  Future<void> _startUpdate(BuildContext context) async {
    if (_isBusy) return;

    final downloadUrl = widget.info.downloadUrl?.trim();
    if (!Platform.isAndroid || downloadUrl == null || downloadUrl.isEmpty) {
      await _openUpdateUrl(context);
      return;
    }

    _cancelRequested = false;
    setState(() {
      _progress = const ApkUpdateProgress(ApkUpdateStage.checkingPermission);
    });

    final openedInstaller = await _updater.downloadAndInstall(
      url: downloadUrl,
      versionCode: widget.info.latestVersionCode,
      onProgress: _setProgress,
    );
    if (!mounted || _cancelRequested) return;

    if (!openedInstaller && _progress.stage != ApkUpdateStage.error) {
      if (!context.mounted) return;
      await _openUpdateUrl(context);
      if (!mounted) return;
      setState(() {
        _progress = const ApkUpdateProgress(ApkUpdateStage.idle);
      });
    }
  }

  void _cancelDownload() {
    _cancelRequested = true;
    _updater.cancel();
    setState(() {
      _progress = const ApkUpdateProgress(ApkUpdateStage.idle);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mustUpdate = widget.info.status == AppUpdateStatus.forceUpdate;

    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final screenH = mq.size.height;
    final insetH = screenW < 360 ? 12.0 : 20.0;
    final insetV = mq.padding.bottom > 0 ? 20.0 : 24.0;
    final stackActionsVertically = screenW < 480;

    final versionName = widget.info.latestVersionName?.trim().isNotEmpty == true
        ? widget.info.latestVersionName!.trim()
        : '—';

    final defaultBody = widget.info.changelog.isNotEmpty
        ? widget.info.changelog
        : l10n.updateAvailableBody;

    return PopScope(
      canPop: !mustUpdate && !_isBusy,
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
                    widget.info.latestVersionCode,
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
                      if (widget.info.changelog.isNotEmpty) ...[
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
                child: _buildActions(
                  context: context,
                  l10n: l10n,
                  theme: theme,
                  mustUpdate: mustUpdate,
                  stackActionsVertically: stackActionsVertically,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions({
    required BuildContext context,
    required AppLocalizations l10n,
    required ThemeData theme,
    required bool mustUpdate,
    required bool stackActionsVertically,
  }) {
    if (_progress.stage == ApkUpdateStage.downloading) {
      return _buildDownloadProgress(
        l10n: l10n,
        theme: theme,
        mustUpdate: mustUpdate,
      );
    }

    if (_progress.stage == ApkUpdateStage.checkingPermission ||
        _progress.stage == ApkUpdateStage.opening) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: _progress.stage == ApkUpdateStage.opening ? 1 : null,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.updatePreparingInstall,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (_hasError) {
      return _buildErrorActions(
        context: context,
        l10n: l10n,
        theme: theme,
        stackActionsVertically: stackActionsVertically,
      );
    }

    return _buildIdleActions(
      context: context,
      l10n: l10n,
      mustUpdate: mustUpdate,
      stackActionsVertically: stackActionsVertically,
    );
  }

  Widget _buildDownloadProgress({
    required AppLocalizations l10n,
    required ThemeData theme,
    required bool mustUpdate,
  }) {
    final progress = _progress.progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(value: progress > 0 ? progress : null),
        const SizedBox(height: 10),
        Text(
          l10n.updateDownloading((progress * 100).round()),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (!mustUpdate) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _cancelDownload,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(l10n.updateCancel),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorActions({
    required BuildContext context,
    required AppLocalizations l10n,
    required ThemeData theme,
    required bool stackActionsVertically,
  }) {
    final error = _progress.error?.trim();
    final errorText = error == null || error.isEmpty
        ? l10n.updateDownloadFailed
        : '${l10n.updateDownloadFailed}\n$error';

    final retryButton = FilledButton(
      onPressed: () => _startUpdate(context),
      style: FilledButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: stackActionsVertically ? 12 : 20,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(l10n.updateRetry),
    );

    final browserButton = TextButton(
      onPressed: () => _openUpdateUrl(context),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: stackActionsVertically ? 12 : 16,
          vertical: 12,
        ),
      ),
      child: Text(l10n.updateOpenInBrowser),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          errorText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFFDC2626),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        if (stackActionsVertically)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              retryButton,
              const SizedBox(height: 8),
              browserButton,
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              browserButton,
              const SizedBox(width: 8),
              retryButton,
            ],
          ),
      ],
    );
  }

  Widget _buildIdleActions({
    required BuildContext context,
    required AppLocalizations l10n,
    required bool mustUpdate,
    required bool stackActionsVertically,
  }) {
    if (stackActionsVertically) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: () => _startUpdate(context),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(l10n.updateNowButton),
          ),
          if (!mustUpdate) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(l10n.updateLaterButton),
            ),
          ],
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!mustUpdate)
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.updateLaterButton),
          ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => _startUpdate(context),
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
    );
  }
}
