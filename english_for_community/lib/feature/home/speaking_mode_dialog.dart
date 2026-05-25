import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/feature/speaking/free_speaking_page.dart';
import 'package:english_for_community/feature/speaking/speaking_hub_page.dart';
import 'package:english_for_community/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Future<void> showSpeakingModeDialog(BuildContext context) {
  final t = context.l10n;
  final availableModes = SpeakingMode.values.where((mode) {
    return mode == SpeakingMode.readAloud || mode == SpeakingMode.freeSpeaking;
  }).toList();

  return showDialog(
    context: context,
    builder: (ctx) => StudentDialogShell(
      title: t.speakingSelectModeTitle,
      subtitle: t.speakingSelectModeSubtitle,
      maxWidth: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: availableModes.map((mode) => _ModeTile(mode: mode, l10n: t)).toList(),
      ),
    ),
  );
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({required this.mode, required this.l10n});

  final SpeakingMode mode;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
      child: StudentMobileUi.skillAccentCard(
        skill: SkillType.speaking,
        onTap: () => _handlePress(context),
        child: Row(
          children: [
            StudentMobileUi.skillIconBox(_getModeIcon(mode), skill: SkillType.speaking),
            const SizedBox(width: AppSpacing.s5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mode.titleLocalized(l10n), style: StudentMobileUi.cardTitle(context)),
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
              color: AppSkillColors.speaking.color,
            ),
          ],
        ),
      ),
    );
  }

  void _handlePress(BuildContext context) {
    Navigator.pop(context);
    if (mode == SpeakingMode.freeSpeaking) {
      context.pushNamed(FreeSpeakingPage.routeName);
    } else {
      context.pushNamed(
        SpeakingHubPage.routeName,
        pathParameters: {'modeName': mode.name},
      );
    }
  }

  String _modeDescription(AppLocalizations t, SpeakingMode mode) {
    switch (mode) {
      case SpeakingMode.readAloud:
        return t.speakingDescReadAloud;
      case SpeakingMode.freeSpeaking:
        return t.speakingDescFreeSpeaking;
      case SpeakingMode.shadowing:
        return t.speakingDescShadowing;
      case SpeakingMode.pronunciation:
        return t.speakingDescPronunciation;
    }
  }

  IconData _getModeIcon(SpeakingMode mode) {
    switch (mode) {
      case SpeakingMode.readAloud:
        return Icons.chrome_reader_mode_outlined;
      case SpeakingMode.freeSpeaking:
        return Icons.forum_outlined;
      case SpeakingMode.shadowing:
        return Icons.headphones_outlined;
      case SpeakingMode.pronunciation:
        return Icons.mic_none_outlined;
    }
  }
}
