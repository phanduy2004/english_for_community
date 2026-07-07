import 'package:english_for_community/core/entity/progress_summary_entity.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/feature/progress/bloc/progress_bloc.dart';
import 'package:english_for_community/feature/progress/bloc/progress_event.dart';
import 'package:english_for_community/feature/progress/bloc/progress_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/locale/l10n_context.dart';
import '../../l10n/generated/app_localizations.dart';

enum StatDetailRange { day, week, month }

class StatDetailDialog extends StatefulWidget {
  final String statKey;
  final StatDetailRange range;
  final String rangeLabel;

  const StatDetailDialog({
    super.key,
    required this.statKey,
    required this.range,
    required this.rangeLabel,
  });

  @override
  State<StatDetailDialog> createState() => _StatDetailDialogState();
}

class _StatDetailDialogState extends State<StatDetailDialog> {
  String _rangeToString(StatDetailRange range) {
    switch (range) {
      case StatDetailRange.day:
        return 'day';
      case StatDetailRange.week:
        return 'week';
      case StatDetailRange.month:
        return 'month';
    }
  }

  String _getTitle(AppLocalizations t) {
    switch (widget.statKey) {
      case 'vocab':
        return t.statDetailVocab;
      case 'reading':
        return t.statDetailReading;
      case 'dictation':
        return t.statDetailDictation;
      case 'speaking':
        return t.statDetailSpeaking;
      case 'writing':
        return t.statDetailWriting;
      case 'lessons':
        return t.statDetailLessons;
      default:
        return t.statDetailGeneric;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressBloc>().add(
            FetchStatDetail(
              statKey: widget.statKey,
              range: _rangeToString(widget.range),
            ),
          );
    });
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final dtUtc = DateTime.parse(isoDate);
      final dtLocal = dtUtc.toLocal();
      return '${dtLocal.day.toString().padLeft(2, '0')}/${dtLocal.month.toString().padLeft(2, '0')}/${dtLocal.year} ${dtLocal.hour.toString().padLeft(2, '0')}:${dtLocal.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildDetailItem(ProgressDetailEntity item, String statKey, AppLocalizations t) {
    final dateDisplay = _formatDate(item.date);

    String subtitle;
    String valueDisplay;
    String unit;
    IconData icon;

    if (statKey == 'lessons') {
      icon = Icons.check_circle_outline_rounded;
      subtitle = dateDisplay.isEmpty ? '' : t.statDetailDateOnly(dateDisplay);
      valueDisplay = '';
      unit = '';

      return _DetailRow(
        icon: icon,
        title: item.title,
        subtitle: subtitle,
        value: valueDisplay,
        unit: unit,
        isCompact: true,
      );
    }

    if (statKey == 'reading') {
      final scoreDisplay = item.score.round().toString();
      subtitle = t.statDetailReadingSubtitle(scoreDisplay, dateDisplay);
      valueDisplay = scoreDisplay;
      unit = '%';
      icon = Icons.menu_book_rounded;
    } else if (statKey == 'speaking') {
      final scoreDisplay = item.score.round().toString();
      subtitle = t.statDetailScoreDateSubtitle(scoreDisplay, dateDisplay);
      valueDisplay = scoreDisplay;
      unit = '%';
      icon = Icons.mic_external_on_rounded;
    } else if (statKey == 'writing') {
      // Band Viết có bước 0.5 → giữ 1 chữ số thập phân, không làm tròn xuống.
      final scoreDisplay = item.score.toStringAsFixed(1);
      subtitle = t.statDetailWritingSubtitle(scoreDisplay, dateDisplay);
      valueDisplay = scoreDisplay;
      unit = '';
      icon = Icons.edit_note_rounded;
    } else if (statKey == 'dictation' || statKey == 'listening') {
      final scoreDisplay = item.score.round().toString();
      subtitle = t.statDetailScoreDateSubtitle(scoreDisplay, dateDisplay);
      valueDisplay = scoreDisplay;
      unit = '%';
      icon = Icons.headphones_rounded;
    } else {
      subtitle = dateDisplay.isEmpty ? '' : t.statDetailDateLine(dateDisplay);
      valueDisplay = '';
      unit = '';
      icon = Icons.info_outline;
    }

    return _DetailRow(
      icon: icon,
      title: item.title,
      subtitle: subtitle,
      value: valueDisplay,
      unit: unit,
    );
  }

  Widget _buildGroupedLessonsList(List<ProgressDetailEntity> data, AppLocalizations t) {
    final groupedData = <String, List<ProgressDetailEntity>>{};
    for (var item in data) {
      final key = (item.type.isEmpty) ? t.statDetailLessonsGroupOther : item.type;
      groupedData.putIfAbsent(key, () => []).add(item);
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: groupedData.entries.map((entry) {
        final groupTitle = entry.key;
        final groupItems = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4, horizontal: AppSpacing.s2),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.outlineMuted, width: 1)),
              ),
              child: Text(
                groupTitle.toUpperCase(),
                style: StudentMobileUi.caption(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...groupItems.map((item) => _buildDetailItem(item, 'lessons', t)),
            const SizedBox(height: AppSpacing.s3),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDetailList(BuildContext context, ProgressState state) {
    final t = context.l10n;

    if (state.detailStatus == ProgressDetailStatus.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.s8),
          child: AppLoadingIndicator(color: AppColors.primary),
        ),
      );
    }

    if (state.detailStatus == ProgressDetailStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s5),
          child: Text(
            state.errorMessage ?? t.genericLoadError,
            style: StudentMobileUi.body(context),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (state.detailStatus == ProgressDetailStatus.success) {
      final List<ProgressDetailEntity> data = state.detailData.cast<ProgressDetailEntity>();

      if (data.isEmpty) {
        return StudentMobileUi.emptyState(
          context,
          icon: Icons.inbox_outlined,
          title: t.statDetailNoData,
          body: '',
        );
      }

      if (widget.statKey == 'lessons') {
        return _buildGroupedLessonsList(data, t);
      }

      return Column(
        children: data.map((item) => _buildDetailItem(item, widget.statKey, t)).toList(),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet + 2)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s7, AppSpacing.s6, AppSpacing.s4, AppSpacing.s3),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getTitle(t), style: StudentMobileUi.sectionTitle(context)),
                        const SizedBox(height: AppSpacing.s2),
                        Text(
                          t.statDetailPeriodLog(widget.rangeLabel),
                          style: StudentMobileUi.body(context),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.outline),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6, vertical: AppSpacing.s3),
                child: BlocBuilder<ProgressBloc, ProgressState>(
                  builder: (context, state) => _buildDetailList(context, state),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.outline),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s5),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(t.close),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String unit;
  final bool isCompact;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isCompact ? AppSpacing.s4 : AppSpacing.s5),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outlineMuted, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          StudentMobileUi.skillIconBox(icon, size: isCompact ? 36 : 40),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: StudentMobileUi.cardTitle(context)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s2),
                  Text(subtitle, style: StudentMobileUi.caption(context)),
                ],
              ],
            ),
          ),
          if (value.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: StudentMobileUi.kpi(context)),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.s2),
                  Text(unit, style: StudentMobileUi.caption(context)),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
