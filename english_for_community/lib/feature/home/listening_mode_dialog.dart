import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../listening/list_listening/listening_list_page.dart';
import '../listening_comp/listening_comp_list_page.dart';

enum ListeningMode {
  dictation,
  comprehension;

  String get title {
    switch (this) {
      case ListeningMode.dictation:
        return 'Dictation';
      case ListeningMode.comprehension:
        return 'Multiple Choice';
    }
  }
}

Future<void> showListeningModeDialog(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: const _ListeningModeDialogContent(),
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

class _ListeningModeDialogContent extends StatelessWidget {
  const _ListeningModeDialogContent();

  @override
  Widget build(BuildContext context) {
    const bgCard = Colors.white;
    const borderCol = Color(0xFFE4E4E7); // Zinc-200
    const textMain = Color(0xFF09090B); // Zinc-950
    const textMuted = Color(0xFF71717A); // Zinc-500

    final availableModes = ListeningMode.values.toList();

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
                const Text(
                  'Listening Practice',
                  style: TextStyle(
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
            const Text(
              'Choose how you want to train your ear today.',
              style: TextStyle(fontSize: 14, color: textMuted, height: 1.4),
            ),
            const SizedBox(height: 24),

            // --- MODE LIST ---
            Column(
              children: availableModes.map((mode) => _ModeTile(mode: mode)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final ListeningMode mode;

  const _ModeTile({required this.mode});

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
                        _getModeTitle(mode),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getModeDescription(mode),
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

    if (mode == ListeningMode.dictation) {
      context.pushNamed(ListeningListPage.routeName); // Tới trang Dictation cũ
    } else if (mode == ListeningMode.comprehension) {
      context.pushNamed(ListeningCompListPage.routeName); // Tới trang mới này
    }
  }

  // --- DATA HELPERS ---

  String _getModeTitle(ListeningMode mode) {
    switch (mode) {
      case ListeningMode.dictation: return 'Dictation';
      case ListeningMode.comprehension: return 'Comprehension';
    }
  }

  String _getModeDescription(ListeningMode mode) {
    switch (mode) {
      case ListeningMode.dictation: return 'Listen and type exactly what you hear.';
      case ListeningMode.comprehension: return 'Listen to audio and answer multiple choice questions.';
    }
  }

  IconData _getModeIcon(ListeningMode mode) {
    switch (mode) {
      case ListeningMode.dictation: return Icons.edit_note_rounded;
      case ListeningMode.comprehension: return Icons.quiz_outlined;
    }
  }

  Color _getModeColor(ListeningMode mode) {
    switch (mode) {
      case ListeningMode.dictation: return const Color(0xFF3B82F6); // Blue
      case ListeningMode.comprehension: return const Color(0xFF10B981); // Emerald
    }
  }
}