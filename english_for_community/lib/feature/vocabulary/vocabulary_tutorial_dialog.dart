import 'package:flutter/material.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/theme/app_motion.dart';

import '../../core/locale/l10n_context.dart';
import '../../core/theme/app_color.dart';
import '../../l10n/generated/app_localizations.dart';

class _TutorialStep {
  const _TutorialStep({
    required this.title,
    required this.icon,
    required this.color,
    required this.spans,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<InlineSpan> spans;
}

class VocabularyTutorialDialog extends StatefulWidget {
  const VocabularyTutorialDialog({super.key});

  @override
  State<VocabularyTutorialDialog> createState() => _VocabularyTutorialDialogState();
}

class _VocabularyTutorialDialogState extends State<VocabularyTutorialDialog> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  List<_TutorialStep> _steps(AppLocalizations t) {
    const textMuted = AppColors.textSecondary;
    const green = AppColors.success;
    const amber700 = AppColors.warning;
    const reviewRed = AppColors.danger;

    final bodyStyle = const TextStyle(fontSize: AppTypography.mobileBodyLg, color: textMuted, height: 1.6);

    return [
      _TutorialStep(
        title: t.vocabTutorialSlide1Title,
        icon: Icons.auto_stories_rounded,
        color: AppColors.info,
        spans: [
          TextSpan(style: bodyStyle, children: [
            TextSpan(text: t.vocabTutorialSlide1a),
            TextSpan(text: t.vocabTutorialSlide1b, style: bodyStyle.copyWith(fontWeight: FontWeight.bold)),
            TextSpan(text: t.vocabTutorialSlide1c),
          ]),
        ],
      ),
      _TutorialStep(
        title: t.vocabTutorialSlide2Title,
        icon: Icons.search_rounded,
        color: AppColors.accent,
        spans: [
          TextSpan(style: bodyStyle, children: [
            TextSpan(text: t.vocabTutorialSlide2a),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(Icons.bookmark, size: 16, color: Colors.amber[700]),
            ),
            TextSpan(
              text: ' ${t.vocabTutorialSlide2SaveLabel}',
              style: bodyStyle.copyWith(fontWeight: FontWeight.bold, color: amber700),
            ),
            TextSpan(text: t.vocabTutorialSlide2b),
            const WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(Icons.school, size: 16, color: green),
            ),
            TextSpan(
              text: ' ${t.vocabTutorialSlide2LearnLabel}',
              style: bodyStyle.copyWith(fontWeight: FontWeight.bold, color: green),
            ),
            TextSpan(text: t.vocabTutorialSlide2c),
          ]),
        ],
      ),
      _TutorialStep(
        title: t.vocabTutorialSlide3Title,
        icon: Icons.psychology_rounded,
        color: green,
        spans: [
          TextSpan(style: bodyStyle, children: [
            TextSpan(text: t.vocabTutorialSlide3a),
            TextSpan(
              text: t.vocabTutorialSlide3b,
              style: bodyStyle.copyWith(fontWeight: FontWeight.bold, color: green),
            ),
            TextSpan(text: t.vocabTutorialSlide3c),
            TextSpan(text: t.vocabTutorialSlide3d, style: bodyStyle.copyWith(fontWeight: FontWeight.bold)),
            TextSpan(text: t.vocabTutorialSlide3e),
          ]),
        ],
      ),
      _TutorialStep(
        title: t.vocabTutorialSlide4Title,
        icon: Icons.history_edu_rounded,
        color: AppColors.tertiary,
        spans: [
          TextSpan(style: bodyStyle, children: [
            TextSpan(text: t.vocabTutorialSlide4a),
            TextSpan(
              text: t.vocabReviewNowFab,
              style: bodyStyle.copyWith(fontWeight: FontWeight.bold, color: reviewRed),
            ),
            TextSpan(text: t.vocabTutorialSlide4c),
          ]),
        ],
      ),
    ];
  }

  void _nextPage(int stepCount) {
    if (_currentIndex < stepCount - 1) {
      _pageController.nextPage(
        duration: AppMotion.tooltipWait,
        curve: Curves.fastOutSlowIn,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final steps = _steps(t);
    const textMain = AppColors.textPrimary;
    const textMuted = AppColors.textSecondary;

    final currentColor = steps[_currentIndex].color;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 480),
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: AppMotion.tooltipWait,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          currentColor.withValues(alpha: 0.15),
                          currentColor.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: AppMotion.base,
                    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                    child: Container(
                      key: ValueKey<int>(_currentIndex),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: currentColor.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        steps[_currentIndex].icon,
                        size: 64,
                        color: currentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          step.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: AppTypography.mobileDisplay,
                            fontWeight: FontWeight.w800,
                            color: textMain,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: AppTypography.mobileBodyLg,
                              color: textMuted,
                              height: 1.6,
                            ),
                            children: step.spans,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(steps.length, (index) {
                      return AnimatedContainer(
                        duration: AppMotion.base,
                        margin: const EdgeInsets.only(right: 6),
                        height: 6,
                        width: _currentIndex == index ? 24 : 6,
                        decoration: BoxDecoration(
                          color: _currentIndex == index ? currentColor : AppColors.outline,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                      );
                    }),
                  ),
                  AnimatedContainer(
                    duration: AppMotion.base,
                    child: ElevatedButton(
                      onPressed: () => _nextPage(steps.length),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: textMain,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _currentIndex == steps.length - 1 ? t.vocabTutorialLetsGo : t.next,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (_currentIndex != steps.length - 1) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 16),
                          ]
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
