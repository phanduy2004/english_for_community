import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:flutter/material.dart';

/// When true, child skill UIs use compact exam typography (aligned with teacher dashboard).
class ExamEmbeddedSkillScope extends InheritedWidget {
  const ExamEmbeddedSkillScope({
    super.key,
    required this.compact,
    required super.child,
  });

  final bool compact;

  static bool compactOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ExamEmbeddedSkillScope>()?.compact ?? false;
  }

  @override
  bool updateShouldNotify(ExamEmbeddedSkillScope oldWidget) => compact != oldWidget.compact;
}

/// Wraps embedded skill exercise trees with lighter [Theme] + [ExamEmbeddedSkillScope].
class ExamEmbeddedSkillTheme extends StatelessWidget {
  const ExamEmbeddedSkillTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final textTheme = base.textTheme.apply(
      bodyColor: AppColors.textSecondary,
      displayColor: AppColors.textPrimary,
    );

    return ExamEmbeddedSkillScope(
      compact: true,
      child: Theme(
        data: base.copyWith(
          textTheme: textTheme.copyWith(
            titleLarge: ExamSystemUi.embeddedCardTitleStyle,
            titleMedium: ExamSystemUi.embeddedCardTitleStyle,
            titleSmall: ExamSystemUi.embeddedSectionLabelStyle,
            bodyLarge: ExamSystemUi.embeddedBodyStyle,
            bodyMedium: ExamSystemUi.embeddedBodyStyle,
            bodySmall: ExamSystemUi.embeddedCaptionStyle,
            labelLarge: ExamSystemUi.embeddedButtonLabelStyle,
            labelMedium: ExamSystemUi.embeddedCaptionStyle,
          ),
          inputDecorationTheme: base.inputDecorationTheme.copyWith(
            hintStyle: ExamSystemUi.embeddedCaptionStyle,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              textStyle: ExamSystemUi.embeddedButtonLabelStyle,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              textStyle: ExamSystemUi.embeddedButtonLabelStyle,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              textStyle: ExamSystemUi.embeddedButtonLabelStyle,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(textStyle: ExamSystemUi.embeddedButtonLabelStyle),
          ),
          tabBarTheme: base.tabBarTheme.copyWith(
            labelStyle: ExamSystemUi.embeddedTabLabelStyle,
            unselectedLabelStyle: ExamSystemUi.embeddedTabLabelStyle.copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted,
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}
