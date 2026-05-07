import 'package:english_for_community/core/entity/app_update_info_entity.dart';
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
        context.read<AppUpdateBloc>().add(AppUpdateCheckRequested());
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
      BuildContext context, AppUpdateInfoEntity info) async {
    final l10n = AppLocalizations.of(context)!;
    final mustUpdate = info.status == AppUpdateStatus.forceUpdate;
    final bodyText =
        (info.changelog.isNotEmpty ? info.changelog : l10n.updateAvailableBody);

    await showDialog<void>(
      context: context,
      barrierDismissible: !mustUpdate,
      builder: (dialogContext) {
        return PopScope(
          canPop: !mustUpdate,
          child: AlertDialog(
            title: Text(
                mustUpdate ? l10n.forceUpdateTitle : l10n.updateAvailableTitle),
            content: Text(bodyText),
            actions: [
              if (!mustUpdate)
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.updateLaterButton),
                ),
              FilledButton(
                onPressed: () async {
                  final url = info.updateUrl;
                  if (url == null || url.isEmpty) return;
                  final uri = Uri.parse(url);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                child: Text(l10n.updateNowButton),
              ),
            ],
          ),
        );
      },
    );
  }
}
