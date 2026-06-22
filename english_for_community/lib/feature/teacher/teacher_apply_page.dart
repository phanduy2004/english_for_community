import 'package:english_for_community/feature/teacher/layout/teacher_skeleton.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_theme.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:english_for_community/core/ui/workspace_layout_scope.dart';
import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:english_for_community/feature/auth/bloc/user_event.dart';
import 'package:english_for_community/feature/teacher/bloc/apply/teacher_apply_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/apply/teacher_apply_event.dart';
import 'package:english_for_community/feature/teacher/bloc/apply/teacher_apply_state.dart';
import 'package:english_for_community/feature/teacher/teacher_dashboard_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class TeacherApplyPage extends StatefulWidget {
  const TeacherApplyPage({super.key});

  static const String routePath = '/teacher/apply';
  static const String routeName = 'TeacherApplyPage';

  @override
  State<TeacherApplyPage> createState() => _TeacherApplyPageState();
}

class _TeacherApplyPageState extends State<TeacherApplyPage> {
  final _bio = TextEditingController();
  final _org = TextEditingController();

  @override
  void dispose() {
    _bio.dispose();
    _org.dispose();
    super.dispose();
  }

  Future<void> _withdraw(BuildContext context) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.teacherApplyWithdraw),
        content: Text(l10n.teacherApplyWithdrawConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.teacherApplyWithdraw)),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<TeacherApplyBloc>().add(const TeacherApplyWithdrawRequested());
    }
  }

  Widget _statusCard(BuildContext context, dynamic l10n, Map<String, dynamic>? application, bool submitting) {
    if (application == null) {
      return Text(l10n.teacherApplyStatusNone, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary));
    }
    final st = application['status'] as String? ?? '';
    final review = application['review'];
    String? reason;
    if (review is Map && (review['reason'] as String?)?.trim().isNotEmpty == true) {
      reason = review['reason'] as String;
    }
    String message;
    switch (st) {
      case 'pending':
        message = l10n.teacherApplyStatusPending;
        break;
      case 'approved':
        message = l10n.teacherApplyStatusApproved;
        break;
      case 'rejected':
        message = l10n.teacherApplyStatusRejected;
        break;
      case 'withdrawn':
        message = l10n.teacherApplyStatusWithdrawn;
        break;
      default:
        message = st;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        if (reason != null) ...[
          const SizedBox(height: 8),
          Text('${l10n.teacherApplyRejectReason}: $reason', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
        ],
        if (st == 'pending') ...[
          const SizedBox(height: 16),
          TeacherInlineActions(
            children: [
              TeacherOutlinedButton(
                label: l10n.teacherApplyWithdraw,
                onPressed: submitting ? null : () => _withdraw(context),
              ),
            ],
          ),
        ],
        if (st == 'approved') ...[
          const SizedBox(height: 16),
          TeacherInlineActions(
            children: [
              TeacherFilledButton(
                label: l10n.teacherApplyGoToHub,
                onPressed: () => context.go(TeacherDashboardPage.routePath),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (_) => getIt<TeacherApplyBloc>()..add(const TeacherApplyLoadRequested()),
      child: BlocConsumer<TeacherApplyBloc, TeacherApplyState>(
        listenWhen: (p, c) =>
            p.status != c.status && c.status == TeacherApplyStatus.submitted ||
            (c.errorMessage != null && p.errorMessage != c.errorMessage),
        listener: (context, state) {
          if (state.status == TeacherApplyStatus.submitted) {
            AppCornerToast.show(context, l10n.teacherApplySubmitted);
            context.read<UserBloc>().add(GetProfileEvent());
          } else if (state.errorMessage != null) {
            AppCornerToast.show(context, state.errorMessage!, error: true);
          }
        },
        builder: (context, state) {
          final application = state.existingApplication;
          final status = application?['status'] as String?;
          final showForm = application == null || status == 'rejected' || status == 'withdrawn';
          final loading = state.status == TeacherApplyStatus.loading;

          return WorkspaceLayoutScope(
            useWebDensity: kIsWeb,
            child: Theme(
              data: kIsWeb ? AppTheme.mergeWorkspaceWeb(context) : Theme.of(context),
              child: Scaffold(
                backgroundColor: AppColors.surface,
                appBar: AppBar(
                  title: Text(l10n.teacherApplyTitle),
                  backgroundColor: AppColors.surfaceCard,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  actions: [
                    IconButton(
                      onPressed: loading
                          ? null
                          : () => context.read<TeacherApplyBloc>().add(const TeacherApplyLoadRequested()),
                      icon: const Icon(Icons.refresh_outlined),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxW = constraints.maxWidth >= 720 ? 560.0 : constraints.maxWidth;
                    return Center(
                      child: SingleChildScrollView(
                        padding: TeacherWebUi.pagePaddingFor(context),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxW),
                          child: loading
                              ? TeacherSkeleton.page(TeacherSkeleton.cardList(n: 1, height: 160))
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    AppCard(
                                      variant: AppCardVariant.outline,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: _statusCard(context, l10n, application, state.submitting),
                                      ),
                                    ),
                                    if (showForm) ...[
                                      const SizedBox(height: 20),
                                      AppCard(
                                        variant: AppCardVariant.outline,
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              TextField(
                                                controller: _bio,
                                                maxLines: 4,
                                                decoration: InputDecoration(
                                                  labelText: l10n.teacherApplyBioLabel,
                                                  border: const OutlineInputBorder(),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              TextField(
                                                controller: _org,
                                                decoration: InputDecoration(
                                                  labelText: l10n.teacherApplyOrgLabel,
                                                  border: const OutlineInputBorder(),
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              TeacherInlineActions(
                                                alignment: Alignment.centerRight,
                                                children: [
                                                  FilledButton(
                                                    style: TeacherWebUi.compactFilledStyle(context),
                                                    onPressed: (state.submitting || status == 'pending')
                                                        ? null
                                                        : () {
                                                            context.read<TeacherApplyBloc>().add(
                                                                  TeacherApplySubmitRequested(
                                                                    bio: _bio.text.trim(),
                                                                    organization: _org.text.trim(),
                                                                  ),
                                                                );
                                                          },
                                                    child: state.submitting
                                                        ? const SizedBox(
                                                            height: 18,
                                                            width: 18,
                                                            child: AppLoadingIndicator(strokeWidth: 2),
                                                          )
                                                        : Text(l10n.teacherApplySubmit),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
