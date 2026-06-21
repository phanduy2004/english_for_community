import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/get_it/get_it.dart';
import '../../core/repository/user_vocab_repository.dart';
import '../../core/sqflite/dict_db.dart';
import '../../core/locale/l10n_context.dart';
import '../../core/ui/feedback/app_feedback.dart';
import '../../core/theme/app_color.dart';
import '../../core/theme/app_skill_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/ui/student_mobile_ui.dart';
import '../../core/ui/widget/app_card.dart';

class DictDetailPage extends StatefulWidget {
  final Entry entry;
  final bool isGuest;

  const DictDetailPage({
    super.key,
    required this.entry,
    this.isGuest = false,
  });

  @override
  State<DictDetailPage> createState() => _DictDetailPageState();
}

class _DictDetailPageState extends State<DictDetailPage> {
  UserVocabRepository? _userVocabRepository;
  late FlutterTts flutterTts;

  @override
  void initState() {
    super.initState();
    _initTts();
    if (!widget.isGuest) {
      _userVocabRepository = getIt<UserVocabRepository>();
    }
  }

  void _initTts() {
    flutterTts = FlutterTts();
    flutterTts.setLanguage('en-US');
    flutterTts.setSpeechRate(0.5);
    flutterTts.setVolume(1.0);
    flutterTts.setPitch(1.0);
  }

  Future<void> _speak() async {
    await flutterTts.stop();
    await flutterTts.speak(widget.entry.headword);
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: StudentMobileUi.skillAppBar(
        context,
        title: widget.entry.headword,
        skill: SkillType.vocabulary,
        actions: widget.isGuest
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.school_rounded, size: 20),
                  color: AppColors.primary,
                  tooltip: t.dictTooltipStartLearning,
                  onPressed: () => _startLearning(context),
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark_border_rounded, size: 20),
                  color: AppColors.accent,
                  tooltip: t.dictTooltipSaveWord,
                  onPressed: () => _saveWord(context),
                ),
              ],
      ),
      body: SingleChildScrollView(
        padding: StudentMobileUi.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              variant: AppCardVariant.filled,
              padding: const EdgeInsets.all(AppSpacing.s5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.entry.headword,
                    style: StudentMobileUi.greeting(context).copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Row(
                    children: [
                      Material(
                        color: AppColors.primaryTint,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _speak,
                          child: const Padding(
                            padding: EdgeInsets.all(AppSpacing.s3),
                            child: Icon(
                              Icons.volume_up_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s4),
                      if (widget.entry.ipa != null && widget.entry.ipa!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s3,
                            vertical: AppSpacing.s2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: Text(
                            '/${widget.entry.ipa}/',
                            style: StudentMobileUi.body(context).copyWith(
                              fontFamily: 'NotoSans',
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (widget.entry.pos != null || widget.entry.tags.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s4),
                    Wrap(
                      spacing: AppSpacing.s3,
                      runSpacing: AppSpacing.s3,
                      children: [
                        if (widget.entry.pos != null) _buildTag(widget.entry.pos!),
                        ...widget.entry.tags.map(_buildTag),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: StudentMobileUi.sectionGap),
            Text(t.dictDefinitions, style: StudentMobileUi.sectionTitle(context)),
            const SizedBox(height: AppSpacing.s4),
            ...widget.entry.senses.asMap().entries.map(
                  (e) => _buildSenseItem(context, e.key + 1, e.value),
                ),
            if (widget.entry.seeAlso.isNotEmpty) ...[
              const SizedBox(height: StudentMobileUi.sectionGap),
              const Divider(color: AppColors.outline),
              const SizedBox(height: AppSpacing.s4),
              Text(t.dictSeeAlso, style: StudentMobileUi.cardTitle(context)),
              const SizedBox(height: AppSpacing.s3),
              Wrap(
                spacing: AppSpacing.s3,
                children: widget.entry.seeAlso
                    .map(
                      (s) => Chip(
                        label: Text(s, style: StudentMobileUi.caption(context)),
                        backgroundColor: AppColors.surfaceSubtle,
                        side: const BorderSide(color: AppColors.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.outline),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.label(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildSenseItem(BuildContext context, int index, Sense sense) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.surfaceSubtle,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: StudentMobileUi.caption(context).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sense.def, style: StudentMobileUi.body(context)),
                if (sense.examples.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s3),
                  Container(
                    padding: const EdgeInsets.only(left: AppSpacing.s4),
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: AppColors.outline, width: 2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sense.examples
                          .map(
                            (ex) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                              child: Text(
                                ex,
                                style: StudentMobileUi.body(context).copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveWord(BuildContext context) async {
    if (_userVocabRepository == null) return;
    final result = await _userVocabRepository!.saveWord(widget.entry);
    if (context.mounted) {
      result.fold(
        (l) => AppFeedback.error(context, l.message),
        (r) => AppFeedback.success(context, context.l10n.wordSavedSnackbar(widget.entry.headword)),
      );
    }
  }

  Future<void> _startLearning(BuildContext context) async {
    if (_userVocabRepository == null) return;
    final result = await _userVocabRepository!.startLearningWord(widget.entry);
    if (context.mounted) {
      result.fold(
        (l) => AppFeedback.error(context, l.message),
        (r) => AppFeedback.success(context, context.l10n.wordAddedToLearningQueue(widget.entry.headword)),
      );
    }
  }
}
