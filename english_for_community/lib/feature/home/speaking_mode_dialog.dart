import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/locale/l10n_context.dart';
import '../../l10n/generated/app_localizations.dart';
import '../speaking/free_speaking_page.dart';
import '../speaking/speaking_hub_page.dart';

Future<void> showSpeakingModeDialog(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withOpacity(0.5), // Slightly darker overlay
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: const _SpeakingModeDialogContent(),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, -0.05), end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
}

class _SpeakingModeDialogContent extends StatelessWidget {
  const _SpeakingModeDialogContent();

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    const bgCard = Colors.white;
    const borderCol = Color(0xFFE4E4E7); // Zinc-200
    const textMain = Color(0xFF09090B); // Zinc-950
    const textMuted = Color(0xFF71717A); // Zinc-500

    // Filter available modes (Removed Shadowing and Pronunciation)
    final availableModes = SpeakingMode.values.where((mode) {
      return mode == SpeakingMode.readAloud || mode == SpeakingMode.freeSpeaking;
    }).toList();

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderCol),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.speakingSelectModeTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textMain,
                    letterSpacing: -0.5,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.close, size: 20, color: textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              t.speakingSelectModeSubtitle,
              style: const TextStyle(fontSize: 14, color: textMuted, height: 1.4),
            ),
            const SizedBox(height: 24),

            // --- MODE LIST ---
            Column(
              children: availableModes.map((mode) => _ModeTile(mode: mode, l10n: t)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final SpeakingMode mode;
  final AppLocalizations l10n;

  const _ModeTile({required this.mode, required this.l10n});

  @override
  Widget build(BuildContext context) {
    const borderCol = Color(0xFFE4E4E7); // Zinc-200
    const textMain = Color(0xFF09090B); // Zinc-950
    const textMuted = Color(0xFF71717A); // Zinc-500

    final themeColor = _getModeColor(mode);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handlePress(context),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 1. Icon Box
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: themeColor.withOpacity(0.2)),
                  ),
                  child: Icon(_getModeIcon(mode), size: 22, color: themeColor),
                ),
                const SizedBox(width: 16),

                // 2. Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.titleLocalized(l10n),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _modeDescription(l10n, mode),
                        style: const TextStyle(fontSize: 13, color: textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 3. Arrow
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[300]),
              ],
            ),
          ),
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
      case SpeakingMode.readAloud: return Icons.chrome_reader_mode_outlined;
      case SpeakingMode.freeSpeaking: return Icons.forum_outlined;
    // Temporarily disabled
      case SpeakingMode.shadowing: return Icons.headphones_outlined;
      case SpeakingMode.pronunciation: return Icons.mic_none_outlined;
    }
  }

  Color _getModeColor(SpeakingMode mode) {
    switch (mode) {
      case SpeakingMode.readAloud: return const Color(0xFF3B82F6); // Blue
      case SpeakingMode.freeSpeaking: return const Color(0xFF10B981); // Emerald
    // Temporarily disabled
      case SpeakingMode.shadowing: return const Color(0xFFA855F7); // Purple
      case SpeakingMode.pronunciation: return const Color(0xFFF97316); // Orange
    }
  }
}