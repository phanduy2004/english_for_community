import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/admin/dashboard_home/admin_dashboard.dart';
import 'package:english_for_community/feature/admin/layout/admin_page_scaffold.dart';
import 'package:english_for_community/feature/admin/layout/admin_skill_palette.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:english_for_community/feature/admin/layout/admin_widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/datasource/admin_remote_datasource.dart';
import '../../../../core/get_it/get_it.dart';

class ContentDashboardPage extends StatelessWidget {
  static const String routeName = 'ContentDashboardPage';
  static const String routePath = '/admin/content';

  const ContentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AdminPageScaffold(
      title: l10n.contentManagerTile,
      subtitle: l10n.contentManagerSub,
      scrollable: false,
      breadcrumbs: [
        AdminBreadcrumb(
          label: l10n.adminOverviewTitle,
          location: AdminDashboardPage.routePath,
        ),
        AdminBreadcrumb(label: l10n.contentManagerTile),
      ],
      body: FutureBuilder<Map<String, int>>(
        future: getIt<AdminRemoteDatasource>().getContentSummary(),
        builder: (context, snapshot) {
          final counts = snapshot.data ??
              const {
                'writing': 0,
                'speaking': 0,
                'reading': 0,
                'listening': 0,
              };
          return AdminCardGrid(
            children: [
              AdminSkillCard(
                title: l10n.writingTitle,
                count: counts['writing'] ?? 0,
                countLabel: l10n.adminContentItemCount,
                color: AdminSkillPalette.writing,
                icon: Icons.edit_note,
                onTap: () => _navToList(context, 'writing'),
              ),
              AdminSkillCard(
                title: l10n.speakingPracticeTitle,
                count: counts['speaking'] ?? 0,
                countLabel: l10n.adminContentItemCount,
                color: AdminSkillPalette.speaking,
                icon: Icons.mic_none,
                onTap: () => _navToList(context, 'speaking'),
              ),
              AdminSkillCard(
                title: l10n.readingPracticeTitle,
                count: counts['reading'] ?? 0,
                countLabel: l10n.adminContentItemCount,
                color: AdminSkillPalette.reading,
                icon: Icons.menu_book,
                onTap: () => _navToList(context, 'reading'),
              ),
              AdminSkillCard(
                title: l10n.listeningTitle,
                count: counts['listening'] ?? 0,
                countLabel: l10n.adminContentItemCount,
                color: AdminSkillPalette.listening,
                icon: Icons.headphones,
                onTap: () => _showListeningTypeDialog(context),
              ),
            ],
          );
        },
      ),
    );
  }

  void _navToList(BuildContext context, String skillType) {
    context.pushNamed('ContentListViewRoute', pathParameters: {'type': skillType});
  }

  void _showListeningTypeDialog(BuildContext context) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
          title: Row(
            children: [
              const Icon(Icons.headphones_outlined, size: 20, color: AdminSkillPalette.listening),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.listeningTitle, style: AdminWebUi.webH2(ctx))),
              IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogOption(
                ctx,
                title: l10n.adminListeningDictation,
                subtitle: l10n.adminListeningDictationSub,
                icon: Icons.edit_document,
                onTap: () {
                  Navigator.pop(ctx);
                  _navToList(context, 'listening');
                },
              ),
              const SizedBox(height: AppSpacing.s4),
              _buildDialogOption(
                ctx,
                title: l10n.adminListeningComprehension,
                subtitle: l10n.adminListeningComprehensionSub,
                icon: Icons.quiz_outlined,
                onTap: () {
                  Navigator.pop(ctx);
                  context.pushNamed('ContentListViewRoute', pathParameters: {'type': 'listening-comp'});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDialogOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s5),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AdminSkillPalette.listening.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
              child: Icon(icon, color: AdminSkillPalette.listening, size: 24),
            ),
            const SizedBox(width: AppSpacing.s5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AdminWebUi.webBody(context).copyWith(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: AdminWebUi.webCaption(context)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

