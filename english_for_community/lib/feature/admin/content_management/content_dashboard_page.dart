import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/widget/web_data_table.dart';
import 'package:english_for_community/feature/admin/dashboard_home/admin_dashboard.dart';
import 'package:english_for_community/feature/admin/layout/admin_page_scaffold.dart';
import 'package:english_for_community/feature/admin/layout/admin_skill_palette.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
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
          final rows = <_ContentRow>[
            _ContentRow(
              title: l10n.writingTitle,
              icon: Icons.edit_note,
              count: counts['writing'] ?? 0,
              onTap: () => _navToList(context, 'writing'),
            ),
            _ContentRow(
              title: l10n.speakingPracticeTitle,
              icon: Icons.mic_none,
              count: counts['speaking'] ?? 0,
              onTap: () => _navToList(context, 'speaking'),
            ),
            _ContentRow(
              title: l10n.readingPracticeTitle,
              icon: Icons.menu_book,
              count: counts['reading'] ?? 0,
              onTap: () => _navToList(context, 'reading'),
            ),
            _ContentRow(
              title: l10n.listeningTitle,
              icon: Icons.headphones,
              count: counts['listening'] ?? 0,
              onTap: () => _showListeningTypeDialog(context),
            ),
          ];
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s6,
              vertical: AppSpacing.s5,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AdminWebUi.contentMaxTable),
                child: WebDataTable(
                  columns: [
                    WebTableColumn(label: l10n.adminTableContent, flex: 4),
                    WebTableColumn(
                      label: l10n.adminContentItemCount,
                      width: 140,
                      align: Alignment.centerRight,
                      headAlign: Alignment.centerRight,
                    ),
                  ],
                  rowCount: rows.length,
                  decoration: AdminWebUi.panelDecoration(),
                  headStyle: AdminWebUi.webTableHead(context),
                  onRowTap: (row) => rows[row].onTap,
                  cellBuilder: (context, row, col) {
                    final r = rows[row];
                    return switch (col) {
                      0 => Row(
                          children: [
                            Icon(r.icon,
                                size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: AppSpacing.s3),
                            Text(
                              r.title,
                              style: AdminWebUi.webBody(context).copyWith(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      1 => Text(
                          '${r.count}',
                          style: AdminWebUi.webBody(context).copyWith(
                            fontSize: 12,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      _ => const SizedBox.shrink(),
                    };
                  },
                ),
              ),
            ),
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

class _ContentRow {
  const _ContentRow({
    required this.title,
    required this.icon,
    required this.count,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final int count;
  final VoidCallback onTap;
}
