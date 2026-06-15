import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/dtos/speaking_response_dto.dart';
import '../../core/locale/l10n_context.dart';
import '../../core/theme/app_color.dart';
import '../../core/theme/app_skill_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/ui/student_mobile_ui.dart';
import '../../l10n/generated/app_localizations.dart';
import '../speaking/speaking_skills_page.dart';
import 'bloc/speaking_bloc.dart';
import 'bloc/speaking_event.dart';
import 'bloc/speaking_state.dart';

enum SpeakingMode {
  readAloud,
  shadowing,
  pronunciation,
  freeSpeaking,
}

extension SpeakingModeL10n on SpeakingMode {
  String titleLocalized(AppLocalizations t) {
    switch (this) {
      case SpeakingMode.readAloud:
        return t.speakingModeReadAloud;
      case SpeakingMode.shadowing:
        return t.speakingModeShadowing;
      case SpeakingMode.pronunciation:
        return t.speakingModePronunciation;
      case SpeakingMode.freeSpeaking:
        return t.speakingModeFreeSpeaking;
    }
  }
}

class SpeakingHubPage extends StatelessWidget {
  final SpeakingMode mode;

  const SpeakingHubPage({
    super.key,
    required this.mode,
  });

  static const routeName = 'SpeakingHubPage';
  static const routePath = '/speaking-hub/:modeName';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SpeakingBloc>()
        ..add(FetchSpeakingSetsEvent(
          mode: mode,
          level: 'Beginner',
        )),
      child: _SpeakingHubView(mode: mode),
    );
  }
}

class _SpeakingHubView extends StatefulWidget {
  final SpeakingMode mode;
  const _SpeakingHubView({required this.mode});

  @override
  State<_SpeakingHubView> createState() => _SpeakingHubViewState();
}

class _SpeakingHubViewState extends State<_SpeakingHubView> {
  int _selectedFilterIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const _apiLevels = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchData() {
    context.read<SpeakingBloc>().add(
          FetchSpeakingSetsEvent(
            mode: widget.mode,
            level: _apiLevels[_selectedFilterIndex],
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final levels = [
      t.difficultyBeginner,
      t.difficultyIntermediate,
      t.difficultyAdvanced,
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: StudentMobileUi.skillAppBar(
        context,
        title: widget.mode.titleLocalized(t),
        skill: SkillType.speaking,
      ),
      body: SafeArea(
        child: ListView(
          padding: StudentMobileUi.pagePadding,
          clipBehavior: Clip.none,
          children: [
            StudentMobileUi.skillHubBanner(
              context: context,
              title: t.speakingMasteryTitle,
              subtitle: t.speakingMasterySubtitle,
              badge: t.aiPoweredBadge,
              icon: Icons.mic_none_rounded,
              skill: SkillType.speaking,
            ),
            const SizedBox(height: StudentMobileUi.sectionGap),
            StudentMobileUi.searchField(
              controller: _searchController,
              hintText: t.searchTopicHint,
              showClear: _searchQuery.trim().isNotEmpty,
              onClear: () {
                _searchController.clear();
                FocusScope.of(context).unfocus();
              },
            ),
            const SizedBox(height: StudentMobileUi.cardGap),
            StudentMobileUi.filterRow(
              labels: levels,
              selectedIndex: _selectedFilterIndex,
              skill: SkillType.speaking,
              onSelected: (i) {
                setState(() => _selectedFilterIndex = i);
                _fetchData();
              },
            ),
            const SizedBox(height: StudentMobileUi.sectionGap),
            BlocBuilder<SpeakingBloc, SpeakingState>(
              builder: (context, state) {
                if (state.status == SpeakingStatus.loading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.s10),
                    child: Center(child: AppLoadingIndicator.center()),
                  );
                }
                if (state.status == SpeakingStatus.error) {
                  return StudentMobileUi.errorBanner(
                    message: state.errorMessage ?? t.loadDataFailed,
                    onRetry: _fetchData,
                    retryLabel: t.commonRetry,
                  );
                }
                if (state.status == SpeakingStatus.success) {
                  final sets = state.sets
                      .where((set) => _matchesPrefix(set.title, _searchQuery))
                      .toList();
                  if (sets.isEmpty) {
                    return StudentMobileUi.emptyState(
                      context,
                      icon: Icons.mic_off_outlined,
                      title: t.noSpeakingLessonsFound,
                      body: t.searchTopicHint,
                      skill: SkillType.speaking,
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sets.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: StudentMobileUi.cardGap),
                    itemBuilder: (context, index) {
                      return _LessonCard(
                        set: sets[index],
                        levelApi: _apiLevels[_selectedFilterIndex],
                        levelLabel: levels[_selectedFilterIndex],
                        onReturn: _fetchData,
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesPrefix(String source, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;
    return source.trimLeft().toLowerCase().startsWith(normalizedQuery);
  }
}

class _LessonCard extends StatelessWidget {
  final SpeakingSetProgressEntity set;
  final String levelApi;
  final String levelLabel;
  final VoidCallback onReturn;

  const _LessonCard({
    required this.set,
    required this.levelApi,
    required this.levelLabel,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final levelColor = StudentMobileUi.difficultyColor(levelApi);
    final isResumed = set.isResumed;
    final hasScore = set.bestScore != null && set.bestScore! > 0;
    final scoreText = hasScore ? '${set.bestScore}%' : t.noAttemptsYet;
    final isCompleted = set.progress >= 0.99;

    return StudentMobileUi.skillAccentCard(
      skill: SkillType.speaking,
      onTap: () => _navigateToDetail(context, isRetake: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Badge(label: levelLabel, color: levelColor),
              StudentMobileUi.skillIconBox(
                Icons.mic_rounded,
                skill: SkillType.speaking,
                size: 36,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            set.title,
            style: StudentMobileUi.cardTitle(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            t.lessonMetaLine(set.totalSentences, t.topicDailyLife),
            style: StudentMobileUi.body(context),
          ),
          const SizedBox(height: AppSpacing.s5),
          Row(
            children: [
              Expanded(
                child: StudentMobileUi.skillProgressBar(
                  value: set.progress,
                  skill: SkillType.speaking,
                  height: 6,
                ),
              ),
              const SizedBox(width: AppSpacing.s4),
              Text(
                t.percentDone((set.progress * 100).toInt()),
                style: AppTypography.label(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s5),
          const Divider(height: 1, color: AppColors.outlineMuted),
          const SizedBox(height: AppSpacing.s4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s3,
                  vertical: AppSpacing.s2,
                ),
                decoration: BoxDecoration(
                  color: hasScore ? AppColors.accentTint : AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 16,
                      color: hasScore ? AppColors.accent : AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.bestScoreLabel,
                          style: AppTypography.label(color: AppColors.textSecondary),
                        ),
                        Text(
                          scoreText,
                          style: AppTypography.label(
                            color: hasScore ? AppColors.accentDark : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StudentMobileUi.skillCardReviewButton(
                      onPressed: () => _navigateToDetail(context, isRetake: false),
                      label: t.reviewAction,
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    StudentMobileUi.skillCardRetakeButton(
                      onPressed: () => _navigateToDetail(context, isRetake: true),
                      label: t.retakeAction,
                    ),
                  ],
                )
              else
                SizedBox(
                  height: 36,
                  child: FilledButton(
                    onPressed: () => _navigateToDetail(context, isRetake: false),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
                    ),
                    child: Text(
                      isResumed ? t.resumeAction : t.startAction,
                      style: AppTypography.label(color: AppColors.onPrimary),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToDetail(BuildContext context, {bool isRetake = false}) async {
    await context.pushNamed(
      SpeakingSkillsPage.routeName,
      pathParameters: {'setId': set.id},
      queryParameters: {'isRetake': isRetake.toString()},
    );
    onReturn();
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label, style: AppTypography.label(color: color)),
    );
  }
}
