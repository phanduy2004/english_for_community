import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../speaking/free_speaking_page.dart';
import '../speaking/speaking_hub_page.dart';

Future<void> showSpeakingModeDialog(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withOpacity(0.4),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 100, left: 20, right: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: const _SpeakingModeDialogContent(),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, -0.1), end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
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
    const bgCard = Colors.white;
    const borderCol = Color(0xFFE4E4E7);
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderCol),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn chế độ luyện tập',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textMain,
                    letterSpacing: -0.5,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 20, color: textMuted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Lựa chọn phương pháp phù hợp để bắt đầu bài học.',
              style: TextStyle(fontSize: 14, color: textMuted),
            ),
            const SizedBox(height: 24),
            Column(
              children: SpeakingMode.values.map((mode) => _ModeTile(mode: mode)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final SpeakingMode mode;

  const _ModeTile({required this.mode});

  @override
  Widget build(BuildContext context) {
    const borderCol = Color(0xFFE4E4E7);
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getModeIcon(mode), size: 20, color: primaryColor),
          ),
          const SizedBox(width: 14),
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
          const SizedBox(width: 12),
          SizedBox(
            height: 32,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: textMain,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                if (mode == SpeakingMode.freeSpeaking) {
                  // Điều hướng đến trang Chat AI mới tạo
                  context.pushNamed(FreeSpeakingPage.routeName);
                } else {
                  // Các mode khác vẫn dùng SpeakingHubPage
                  context.pushNamed(
                    SpeakingHubPage.routeName,
                    pathParameters: {'modeName': mode.name},
                  );
                }
              },
              child: const Text(
                'Bắt đầu',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getModeTitle(SpeakingMode mode) {
    switch (mode) {
      case SpeakingMode.readAloud: return 'Read Aloud';
      case SpeakingMode.shadowing: return 'Shadowing';
      case SpeakingMode.pronunciation: return 'Pronunciation';
      case SpeakingMode.freeSpeaking: return 'Free Speaking';
    }
  }

  String _getModeDescription(SpeakingMode mode) {
    switch (mode) {
      case SpeakingMode.readAloud: return 'Đọc to đoạn văn bản.';
      case SpeakingMode.shadowing: return 'Nghe và lặp lại ngay lập tức.';
      case SpeakingMode.pronunciation: return 'Luyện phát âm từng âm tiết.';
      case SpeakingMode.freeSpeaking: return 'Nói tự do theo chủ đề.';
    }
  }

  IconData _getModeIcon(SpeakingMode mode) {
    switch (mode) {
      case SpeakingMode.readAloud: return Icons.chrome_reader_mode_outlined;
      case SpeakingMode.shadowing: return Icons.hearing_outlined;
      case SpeakingMode.pronunciation: return Icons.mic_none_outlined;
      case SpeakingMode.freeSpeaking: return Icons.chat_bubble_outline_rounded;
    }
  }
}