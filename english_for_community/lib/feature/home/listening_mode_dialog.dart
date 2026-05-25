import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/feature/listening/list_listening/listening_list_page.dart';
import 'package:english_for_community/feature/listening_comp/listening_comp_list_page.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum ListeningMode {
  dictation,
  comprehension,
}

Future<void> showListeningModeDialog(BuildContext context) {
  final t = context.l10n;
  return showDialog(
    context: context,
    builder: (ctx) => StudentDialogShell(
      title: t.listeningPracticeTitle,
      subtitle: t.listeningChooseSubtitle,
      maxWidth: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: ListeningMode.values
            .map((mode) => _ModeTile(mode: mode, l10n: t))
            .toList(),
      ),
    ),
  );
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({required this.mode, required this.l10n});

  final ListeningMode mode;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
      child: StudentMobileUi.skillAccentCard(
        skill: SkillType.listening,
        onTap: () => _handlePress(context),
        child: Row(
          children: [
            StudentMobileUi.skillIconBox(_getModeIcon(mode), skill: SkillType.listening),
            const SizedBox(width: AppSpacing.s5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_modeTitle(l10n, mode), style: StudentMobileUi.cardTitle(context)),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    _modeDescription(l10n, mode),
                    style: StudentMobileUi.body(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppSkillColors.listening.color,
            ),
          ],
        ),
      ),
    );
  }

  void _handlePress(BuildContext context) {
    Navigator.pop(context);
    if (mode == ListeningMode.dictation) {
      context.pushNamed(ListeningListPage.routeName);
    } else if (mode == ListeningMode.comprehension) {
      context.pushNamed(ListeningCompListPage.routeName);
    }
  }

  String _modeTitle(AppLocalizations t, ListeningMode mode) {
    switch (mode) {
      case ListeningMode.dictation:
        return t.listeningDictation;
      case ListeningMode.comprehension:
        return t.listeningModeComprehensionTitle;
    }
  }

  String _modeDescription(AppLocalizations t, ListeningMode mode) {
    switch (mode) {
      case ListeningMode.dictation:
        return t.listeningModeDictationTileDesc;
      case ListeningMode.comprehension:
        return t.listeningModeComprehensionDesc;
    }
  }

  IconData _getModeIcon(ListeningMode mode) {
    switch (mode) {
      case ListeningMode.dictation:
        return Icons.edit_note_rounded;
      case ListeningMode.comprehension:
        return Icons.quiz_outlined;
    }
  }
}
