import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/repository/user_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/progress/bloc/progress_bloc.dart';
import 'package:english_for_community/feature/progress/bloc/progress_event.dart';
import 'package:english_for_community/feature/progress/bloc/progress_state.dart';
import 'package:english_for_community/feature/progress/report_dialog.dart';
import 'package:english_for_community/feature/progress/stat_detail_dialog.dart';
import 'package:english_for_community/feature/progress/user_profile_dialog.dart';
import 'package:english_for_community/feature/progress/widgets/weekly_activity_bars_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/locale/l10n_context.dart';
import '../../l10n/generated/app_localizations.dart';

class ProgressReportPage extends StatefulWidget {
  const ProgressReportPage({super.key});
  static String routeName = 'ProgressReportPage';
  static String routePath = '/progress';

  @override
  State<ProgressReportPage> createState() => _ProgressReportPageState();
}

enum _Range { day, week, month }

class _ProgressReportPageState extends State<ProgressReportPage> {
  _Range _range = _Range.week;

  void _openReportDialog() {
    showDialog(
      context: context,
      builder: (_) => const ReportDialog(),
    );
  }

  String _fmtHhMm(int totalMinutes, AppLocalizations t) {
    if (totalMinutes < 0) return t.progressDurationHm(0, 0);
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return t.progressDurationHm(h, m);
  }

  String _rangeToString(_Range range) {
    switch (range) {
      case _Range.day:
        return 'day';
      case _Range.week:
        return 'week';
      case _Range.month:
        return 'month';
    }
  }

  String _rangeToLabel(_Range range, AppLocalizations t) {
    switch (range) {
      case _Range.day:
        return t.progressFilterDay;
      case _Range.week:
        return t.progressFilterWeek;
      case _Range.month:
        return t.progressFilterMonth;
    }
  }

  String _periodHeading(_Range range, AppLocalizations t) {
    switch (range) {
      case _Range.day:
        return t.progressPeriodToday;
      case _Range.week:
        return t.progressPeriodThisWeek;
      case _Range.month:
        return t.progressPeriodThisMonth;
    }
  }

  StatDetailRange _rangeToDialogEnum(_Range range) {
    switch (range) {
      case _Range.day:
        return StatDetailRange.day;
      case _Range.week:
        return StatDetailRange.week;
      case _Range.month:
        return StatDetailRange.month;
    }
  }

  int _daysInMonth(DateTime date) {
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    final lastDay = nextMonth.subtract(const Duration(days: 1));
    return lastDay.day;
  }

  int _calculateTotalGoalMinutes(_Range range, int dailyGoal) {
    switch (range) {
      case _Range.day:
        return dailyGoal;
      case _Range.week:
        return dailyGoal * 7;
      case _Range.month:
        final today = DateTime.now();
        final days = _daysInMonth(today);
        return dailyGoal * days;
    }
  }

  void _onRangeSelected(BuildContext blocContext, int index) {
    final newRange = _Range.values[index];
    if (_range == newRange) return;
    setState(() => _range = newRange);
    blocContext.read<ProgressBloc>().add(FetchProgressData(range: _rangeToString(newRange)));
  }

  void _showStatDetailDialog(ProgressBloc bloc, String statKey, _Range range) {
    final t = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) {
        return BlocProvider.value(
          value: bloc,
          child: StatDetailDialog(
            statKey: statKey,
            range: _rangeToDialogEnum(range),
            rangeLabel: _rangeToLabel(range, t),
          ),
        );
      },
    );
  }

  void _showUserProfile(BuildContext context, String userId) {
    final t = context.l10n;
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder(
          future: getIt<UserRepository>().getPublicProfile(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Dialog(
                backgroundColor: AppColors.surfaceCard,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s7),
                  child: const Center(
                    child: AppLoadingIndicator.center(color: AppColors.primary),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return StudentDialogShell(
                title: t.errorTitle,
                subtitle: t.failedToLoadProfile,
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(t.close),
                  ),
                ],
                child: const SizedBox.shrink(),
              );
            }

            if (snapshot.hasData) {
              return snapshot.data!.fold(
                (failure) => StudentDialogShell(
                  title: t.errorTitle,
                  subtitle: failure.message,
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(t.close),
                    ),
                  ],
                  child: const SizedBox.shrink(),
                ),
                (user) => UserProfileDialog(
                  fullName: user.fullName,
                  username: user.username,
                  avatarUrl: user.avatarUrl,
                  dateOfBirth: user.dateOfBirth,
                  bio: user.bio,
                  gender: user.gender,
                  totalPoints: user.totalPoints ?? 0,
                  level: user.level ?? 1,
                  currentStreak: user.currentStreak ?? 0,
                  isOnline: user.isOnline,
                ),
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Future<void> _onRefresh(BuildContext context) async {
    final bloc = context.read<ProgressBloc>();
    bloc.add(FetchProgressData(range: _rangeToString(_range)));
    bloc.add(FetchLeaderboard());
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    return BlocProvider(
      create: (context) => getIt<ProgressBloc>()
        ..add(FetchProgressData(range: _rangeToString(_range)))
        ..add(FetchLeaderboard()),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: StudentMobileUi.appBar(
          context,
          title: t.learningProgressTitle,
          actions: [
            IconButton(
              tooltip: t.reportIssueTooltip,
              icon: const Icon(Icons.flag_outlined, size: 20),
              onPressed: _openReportDialog,
            ),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<ProgressBloc, ProgressState>(
            builder: (context, state) {
              if (state.status == ProgressStatus.loading || state.status == ProgressStatus.initial) {
                return StudentMobileUi.pageLoading(color: AppColors.primary);
              }
              if (state.status == ProgressStatus.error) {
                return _buildErrorUI(context, state.errorMessage, t);
              }
              if (state.summary != null) {
                return _buildSuccessUI(context, state, t);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorUI(BuildContext context, String? message, AppLocalizations t) {
    return Center(
      child: Padding(
        padding: StudentMobileUi.pagePadding,
        child: StudentMobileUi.errorBanner(
          message: message ?? t.pleaseTryAgainLater,
          onRetry: () => _onRefresh(context),
          retryLabel: t.retry,
        ),
      ),
    );
  }

  Widget _buildSuccessUI(BuildContext context, ProgressState state, AppLocalizations t) {
    final progressBloc = context.read<ProgressBloc>();
    final summary = state.summary!;

    final studyTime = summary.studyTime;
    final stats = summary.statsGrid;
    final chart = summary.weeklyChart;
    final callout = summary.callout;

    final totalMinutesInActualRange = _range == _Range.day
        ? studyTime.todayMinutes
        : studyTime.totalMinutesInRange;

    final totalGoalMinutes = _calculateTotalGoalMinutes(_range, studyTime.goalMinutes);

    final progress = (totalGoalMinutes > 0 ? (totalMinutesInActualRange / totalGoalMinutes) : 0.0).clamp(0.0, 1.0);

    final rangeLabels = [
      t.progressFilterDay,
      t.progressFilterWeek,
      t.progressFilterMonth,
    ];

    return RefreshIndicator(
      onRefresh: () => _onRefresh(context),
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceCard,
      child: SingleChildScrollView(
        primary: false,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: StudentMobileUi.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StudentMobileUi.sectionHeader(context, title: t.progressOverview),
            const SizedBox(height: AppSpacing.s1),
            Text(t.progressPerformanceMetrics, style: StudentMobileUi.body(context)),
            const SizedBox(height: AppSpacing.s3),
            StudentMobileUi.filterRow(
              labels: rangeLabels,
              selectedIndex: _range.index,
              onSelected: (i) => _onRangeSelected(context, i),
            ),
            const SizedBox(height: AppSpacing.s4),

            AppCard(
              variant: AppCardVariant.outline,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _periodHeading(_range, t),
                              style: StudentMobileUi.cardTitle(context),
                            ),
                            const SizedBox(height: AppSpacing.s1),
                            Text(
                              _fmtHhMm(totalMinutesInActualRange, t),
                              style: StudentMobileUi.kpi(context),
                            ),
                          ],
                        ),
                      ),
                      StudentMobileUi.skillIconBox(Icons.timer_outlined, size: 36),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    child: StudentMobileUi.skillProgressBar(
                      value: progress,
                      color: AppColors.accent,
                      height: 6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.progressGoalLine(_fmtHhMm(totalGoalMinutes, t)),
                        style: StudentMobileUi.caption(context),
                      ),
                      Text(
                        t.progressPercentCompleted((progress * 100).round()),
                        style: StudentMobileUi.caption(context).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s4),

            Text(t.progressDetailedStats, style: StudentMobileUi.sectionTitle(context)),
            const SizedBox(height: AppSpacing.s3),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: StudentMobileUi.cardGap,
              mainAxisSpacing: StudentMobileUi.cardGap,
              childAspectRatio: 1.12,
              children: [
                _StatBox(
                  icon: Icons.style_rounded,
                  value: '${stats.vocabLearned}',
                  label: t.progressStatVocabulary,
                  skill: SkillType.vocabulary,
                  onTap: () => _showStatDetailDialog(progressBloc, 'vocab', _range),
                ),
                _StatBox(
                  icon: Icons.menu_book_rounded,
                  value: '${stats.readingAccuracy}%',
                  label: t.progressStatReading,
                  skill: SkillType.reading,
                  onTap: () => _showStatDetailDialog(progressBloc, 'reading', _range),
                ),
                _StatBox(
                  icon: Icons.headphones_rounded,
                  value: '${stats.dictationAccuracy}%',
                  label: t.progressStatListening,
                  skill: SkillType.listening,
                  onTap: () => _showStatDetailDialog(progressBloc, 'dictation', _range),
                ),
                _StatBox(
                  icon: Icons.task_alt_rounded,
                  value: '${stats.lessonsCompleted}',
                  label: t.progressStatLessons,
                  onTap: () => _showStatDetailDialog(progressBloc, 'lessons', _range),
                ),
                _StatBox(
                  icon: Icons.edit_note_rounded,
                  value: stats.avgWritingScore.toStringAsFixed(1),
                  label: t.progressStatWriting,
                  skill: SkillType.writing,
                  onTap: () => _showStatDetailDialog(progressBloc, 'writing', _range),
                ),
                _StatBox(
                  icon: Icons.record_voice_over_rounded,
                  value: '${stats.speakingAccuracy}%',
                  label: t.progressStatSpeaking,
                  skill: SkillType.speaking,
                  onTap: () => _showStatDetailDialog(progressBloc, 'speaking', _range),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),

            StudentMobileUi.sectionHeader(context, title: t.progressLeaderboard),
            const SizedBox(height: AppSpacing.s3),
            AppCard(
              variant: AppCardVariant.outline,
              padding: EdgeInsets.zero,
              child: _buildLeaderboardContent(state, t),
            ),
            const SizedBox(height: AppSpacing.s4),

            AppCard(
              variant: AppCardVariant.outline,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.progressActivity, style: StudentMobileUi.sectionTitle(context)),
                      const Icon(Icons.bar_chart, color: AppColors.textSecondary, size: 18),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  SizedBox(
                    height: 120,
                    child: WeeklyActivityBarsChart(
                      values: chart.minutes,
                      labels: chart.labels,
                      barColor: AppColors.chartBar,
                      highlightIndex: chart.labels.length - 1,
                      highlightColor: AppColors.chartHighlight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            AppCard(
              variant: AppCardVariant.outline,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
              child: Row(
                children: [
                  const Icon(Icons.celebration_rounded, color: AppColors.success, size: 24),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          callout.title,
                          style: StudentMobileUi.cardTitle(context).copyWith(color: AppColors.success),
                        ),
                        const SizedBox(height: AppSpacing.s1),
                        Text(callout.message, style: StudentMobileUi.body(context)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.success, size: 18),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s5),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardContent(ProgressState state, AppLocalizations t) {
    if (state.leaderboardStatus == LeaderboardStatus.loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.s6),
        child: Center(child: AppLoadingIndicator.center(color: AppColors.primary)),
      );
    }

    if (state.leaderboardStatus == LeaderboardStatus.error) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.s5),
        child: Center(
          child: Text(
            state.errorMessage ?? t.leaderboardLoadFailed,
            style: StudentMobileUi.caption(context),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final users = state.leaderboardUsers;
    if (users.isEmpty) {
      return StudentMobileUi.emptyState(
        context,
        icon: Icons.leaderboard_outlined,
        title: t.leaderboardEmpty,
        body: '',
      );
    }

    return Column(
      children: List.generate(users.length, (index) {
        final user = users[index];

        if (user.isSeparator) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
            color: AppColors.surfaceCard,
            child: const Center(
              child: Text(
                '...',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMuted),
              ),
            ),
          );
        }

        return Column(
          children: [
            _LeaderRow(
              rank: user.rank,
              name: user.name,
              xp: user.xp,
              isMe: user.isMe,
              avatarUrl: user.avatarUrl,
              onTap: () => _showUserProfile(context, user.id),
            ),
            if (index < users.length - 1) const Divider(height: 1, color: AppColors.outline),
          ],
        );
      }),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  final int rank;
  final String name;
  final String xp;
  final bool isMe;
  final String? avatarUrl;
  final VoidCallback? onTap;

  const _LeaderRow({
    required this.rank,
    required this.name,
    required this.xp,
    this.isMe = false,
    this.avatarUrl,
    this.onTap,
  });

  Color get _rankColor {
    if (rank == 1) return AppColors.accent;
    if (rank == 2) return AppColors.textSecondary;
    if (rank == 3) return AppColors.warning;
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isMe ? AppColors.primaryTint : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '#$rank',
                  style: StudentMobileUi.caption(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: _rankColor,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.outline),
                  image: (avatarUrl != null && avatarUrl!.isNotEmpty)
                      ? DecorationImage(image: NetworkImage(avatarUrl!), fit: BoxFit.cover)
                      : null,
                  color: AppColors.surfaceSubtle,
                ),
                child: (avatarUrl == null || avatarUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 16, color: AppColors.textSecondary)
                    : null,
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StudentMobileUi.cardTitle(context).copyWith(
                    fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Text(xp, style: StudentMobileUi.cardTitle(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;
  final SkillType? skill;

  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
    this.skill,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.outline,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2, vertical: AppSpacing.s2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StudentMobileUi.skillIconBox(icon, size: 28, skill: skill),
          const SizedBox(height: AppSpacing.s1),
          Text(value, style: StudentMobileUi.kpi(context)),
          const SizedBox(height: AppSpacing.s1),
          Text(
            label,
            style: StudentMobileUi.caption(context),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
