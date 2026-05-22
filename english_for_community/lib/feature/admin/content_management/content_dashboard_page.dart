import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/admin/layout/admin_page_scaffold.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/datasource/admin_remote_datasource.dart';
import '../../../../core/get_it/get_it.dart';
import 'content_widgets.dart';

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
              _SkillCard(
                title: l10n.writingTitle,
                count: counts['writing'] ?? 0,
                color: const Color(0xFFEF4444),
                icon: Icons.edit_note,
                onTap: () => _navToList(context, 'writing'),
              ),
              _SkillCard(
                title: l10n.speakingPracticeTitle,
                count: counts['speaking'] ?? 0,
                color: const Color(0xFF3B82F6),
                icon: Icons.mic_none,
                onTap: () => _navToList(context, 'speaking'),
              ),
              _SkillCard(
                title: l10n.readingPracticeTitle,
                count: counts['reading'] ?? 0,
                color: AppColors.chartHighlight,
                icon: Icons.menu_book,
                onTap: () => _navToList(context, 'reading'),
              ),
              _SkillCard(
                title: l10n.listeningTitle,
                count: counts['listening'] ?? 0,
                color: const Color(0xFF8B5CF6),
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
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
          title: Row(
            children: [
              const Icon(Icons.headphones_outlined, size: 20, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              Expanded(child: Text('Listening', style: AdminWebUi.webH2(ctx))),
              IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogOption(
                title: 'Dictation',
                subtitle: 'Nghe chép chính tả (Cues)',
                icon: Icons.edit_document,
                onTap: () {
                  Navigator.pop(ctx);
                  _navToList(context, 'listening');
                },
              ),
              const SizedBox(height: AppSpacing.s4),
              _buildDialogOption(
                title: 'Comprehension',
                subtitle: 'Nghe hiểu (Trắc nghiệm)',
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

  Widget _buildDialogOption({
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
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF8B5CF6), size: 24),
            ),
            const SizedBox(width: AppSpacing.s5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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

class _SkillCard extends StatelessWidget {
  const _SkillCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ShadcnCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AdminWebUi.webH2(context)),
              const SizedBox(height: 4),
              Text('$count topics', style: AdminWebUi.webCaption(context)),
            ],
          ),
        ],
      ),
    );
  }
}
