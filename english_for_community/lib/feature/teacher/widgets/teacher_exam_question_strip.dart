import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/e4c_scroll_behavior.dart';
import 'package:english_for_community/core/ui/exam_system_ui.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_widgets.dart';
import 'package:flutter/material.dart';

/// Numbered boxes per skill: green = correct, red = wrong, gray = unanswered.
class TeacherExamQuestionStripSection extends StatelessWidget {
  const TeacherExamQuestionStripSection({
    super.key,
    required this.title,
    required this.questions,
    this.currentQuestionIndex,
    this.compact = false,
  });

  final String title;
  final List<Map<String, dynamic>> questions;
  /// 0-based index of the question the student is on (optional).
  final int? currentQuestionIndex;
  final bool compact;

  static List<Map<String, dynamic>> parseStrips(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static String stripTitle(BuildContext context, Map<String, dynamic> strip) {
    final skill = strip['skill']?.toString() ?? '';
    final t = context.l10n;
    switch (skill) {
      case 'grammar':
        return t.integratedExamGrammarSectionTitle;
      case 'listening':
        final lt = strip['listeningType']?.toString() ?? '';
        if (lt == 'comprehension') {
          return '${t.teacherExamIntegratedSkillListening} · ${t.teacherExamListeningTypeComprehension}';
        }
        if (lt == 'dictation') {
          return '${t.teacherExamIntegratedSkillListening} · ${t.teacherExamListeningTypeDictation}';
        }
        return t.teacherExamIntegratedSkillListening;
      case 'reading':
        return t.teacherExamIntegratedSkillReading;
      case 'speaking':
        return t.teacherExamIntegratedSkillSpeaking;
      case 'writing':
        return t.teacherExamIntegratedSkillWriting;
      default:
        return skill;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) return const SizedBox.shrink();
    final boxSize = compact ? 28.0 : 32.0;
    final fontSize = compact ? 11.0 : 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: ExamSystemUi.captionSecondary.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: compact ? 11 : 12,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: boxSize + 4,
          child: e4cHorizontalScroll(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: questions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 5),
              itemBuilder: (context, i) {
                final q = questions[i];
                final answered = q['answered'] == true;
                final isCorrect = q['isCorrect'];
                final selected = currentQuestionIndex != null && currentQuestionIndex == i;
                return _QuestionBox(
                  number: (q['number'] as num?)?.toInt() ?? (i + 1),
                  answered: answered,
                  isCorrect: isCorrect is bool ? isCorrect : null,
                  selected: selected,
                  size: boxSize,
                  fontSize: fontSize,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class TeacherExamSkillStripsPanel extends StatelessWidget {
  const TeacherExamSkillStripsPanel({
    super.key,
    required this.skillStrips,
    this.compact = false,
    this.showLegend = true,
  });

  final List<Map<String, dynamic>> skillStrips;
  final bool compact;
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    if (skillStrips.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;

    // Merge multiple listening strips into one section with sub-labels.
    final listeningStrips = skillStrips.where((s) => s['skill'] == 'listening').toList();
    final otherStrips = skillStrips.where((s) => s['skill'] != 'listening').toList();

    final merged = <Map<String, dynamic>>[];
    bool listeningInserted = false;
    for (final strip in skillStrips) {
      if (strip['skill'] == 'listening') {
        if (!listeningInserted) {
          listeningInserted = true;
          merged.add({'__merged_listening__': true, 'strips': listeningStrips});
        }
      } else {
        merged.add(strip);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLegend)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TeacherQuestionStatusLegend(
              correctLabel: l10n.teacherLiveMonitorGrammarCorrect,
              wrongLabel: l10n.teacherLiveMonitorGrammarWrong,
              unansweredLabel: l10n.teacherLiveMonitorGrammarNotAnswered,
            ),
          ),
        ...merged.map((entry) {
          if (entry['__merged_listening__'] == true) {
            return _buildMergedListeningStrip(context, entry['strips'] as List);
          }
          final strip = entry;
          final rawQ = strip['questions'];
          final questions = rawQ is List
              ? rawQ.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              : <Map<String, dynamic>>[];
          final current = (strip['currentQuestionIndex'] as num?)?.toInt();
          return Padding(
            padding: EdgeInsets.only(bottom: compact ? 8 : 12),
            child: TeacherExamQuestionStripSection(
              title: TeacherExamQuestionStripSection.stripTitle(context, strip),
              questions: questions,
              currentQuestionIndex: current,
              compact: compact,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMergedListeningStrip(BuildContext context, List<dynamic> strips) {
    final l10n = context.l10n;
    final title = l10n.teacherExamIntegratedSkillListening;
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: ExamSystemUi.captionSecondary.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11 : 12,
            ),
          ),
          const SizedBox(height: 6),
          for (final strip in strips) ...[
            _buildListeningSubStrip(context, Map<String, dynamic>.from(strip as Map)),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  Widget _buildListeningSubStrip(BuildContext context, Map<String, dynamic> strip) {
    final lt = strip['listeningType']?.toString() ?? 'dictation';
    final subLabel = lt == 'comprehension'
        ? context.l10n.teacherExamListeningTypeComprehension
        : context.l10n.teacherExamListeningTypeDictation;
    final rawQ = strip['questions'];
    final questions = rawQ is List
        ? rawQ.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
    final current = (strip['currentQuestionIndex'] as num?)?.toInt();
    final boxSize = compact ? 28.0 : 32.0;
    final fontSize = compact ? 11.0 : 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          subLabel,
          style: ExamSystemUi.captionMuted.copyWith(fontSize: compact ? 10 : 11),
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: boxSize + 4,
          child: e4cHorizontalScroll(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: questions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 5),
              itemBuilder: (context, i) {
                final q = questions[i];
                final answered = q['answered'] == true;
                final isCorrect = q['isCorrect'];
                final selected = current != null && current == i;
                return _QuestionBox(
                  number: (q['number'] as num?)?.toInt() ?? (i + 1),
                  answered: answered,
                  isCorrect: isCorrect is bool ? isCorrect : null,
                  selected: selected,
                  size: boxSize,
                  fontSize: fontSize,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionBox extends StatelessWidget {
  const _QuestionBox({
    required this.number,
    required this.answered,
    required this.isCorrect,
    required this.selected,
    required this.size,
    required this.fontSize,
  });

  final int number;
  final bool answered;
  final bool? isCorrect;
  final bool selected;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.surfaceCard;
    Color border = AppColors.outlineMuted;
    Color fg = AppColors.textSecondary;
    double borderWidth = 0.75;

    if (answered) {
      if (isCorrect == true) {
        bg = const Color(0xFFE8F5E9);
        border = const Color(0xFF43A047);
        fg = const Color(0xFF2E7D32);
      } else if (isCorrect == false) {
        bg = AppColors.chartTrend.withValues(alpha: 0.12);
        border = AppColors.chartTrend;
        fg = AppColors.chartTrend;
      }
    }

    if (selected) {
      border = AppColors.textPrimary;
      borderWidth = 1.75;
      if (!answered) {
        bg = AppColors.primary.withValues(alpha: 0.06);
      }
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: borderWidth),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: selected || answered ? FontWeight.w600 : FontWeight.w400,
          color: fg,
        ),
      ),
    );
  }
}
