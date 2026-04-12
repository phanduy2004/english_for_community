import 'package:english_for_community/feature/progress/report_dialog.dart';
import 'package:english_for_community/feature/progress/widgets/weekly_activity_bars_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:english_for_community/feature/progress/bloc/progress_bloc.dart';
import 'package:english_for_community/feature/progress/bloc/progress_event.dart';
import 'package:english_for_community/feature/progress/bloc/progress_state.dart';
import 'package:english_for_community/feature/progress/stat_detail_dialog.dart';
import 'package:english_for_community/feature/progress/user_profile_dialog.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/repository/user_repository.dart';

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
      case _Range.day: return 'day';
      case _Range.week: return 'week';
      case _Range.month: return 'month';
    }
  }

  String _rangeToLabel(_Range range, AppLocalizations t) {
    switch (range) {
      case _Range.day: return t.progressFilterDay;
      case _Range.week: return t.progressFilterWeek;
      case _Range.month: return t.progressFilterMonth;
    }
  }

  String _periodHeading(_Range range, AppLocalizations t) {
    switch (range) {
      case _Range.day: return t.progressPeriodToday;
      case _Range.week: return t.progressPeriodThisWeek;
      case _Range.month: return t.progressPeriodThisMonth;
    }
  }

  StatDetailRange _rangeToDialogEnum(_Range range) {
    switch (range) {
      case _Range.day: return StatDetailRange.day;
      case _Range.week: return StatDetailRange.week;
      case _Range.month: return StatDetailRange.month;
    }
  }

  // 🔥 Hàm mới: Tính số ngày chính xác trong tháng hiện tại
  int _daysInMonth(DateTime date) {
    // Lấy ngày đầu tiên của tháng tiếp theo (tháng hiện tại + 1)
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    // Trừ đi 1 ngày sẽ ra ngày cuối cùng của tháng hiện tại
    final lastDay = nextMonth.subtract(const Duration(days: 1));
    return lastDay.day;
  }

  // 🔥 Sửa đổi hàm tính toán mục tiêu tổng
  int _calculateTotalGoalMinutes(_Range range, int dailyGoal) {
    switch (range) {
      case _Range.day:
        return dailyGoal;
      case _Range.week:
        return dailyGoal * 7;
      case _Range.month:
      // ✅ Lấy số ngày chính xác của tháng hiện tại
        final today = DateTime.now();
        final days = _daysInMonth(today);
        return dailyGoal * days;
    }
  }


  void _onRangeSelected(BuildContext blocContext, _Range newRange) {
    if (_range == newRange) return;
    setState(() { _range = newRange; });
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
        }
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
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (snapshot.hasError) {
              return AlertDialog(
                title: Text(t.errorTitle),
                content: Text(t.failedToLoadProfile),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(t.close),
                  ),
                ],
              );
            }

            if (snapshot.hasData) {
              return snapshot.data!.fold(
                    (failure) => AlertDialog(
                  title: Text(t.errorTitle),
                  content: Text(failure.message),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(t.close),
                    )
                  ],
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
    const bgPage = Color(0xFFF9FAFB);
    const borderCol = Color(0xFFE4E4E7);
    const textMain = Color(0xFF09090B);

    return BlocProvider(
      create: (context) => getIt<ProgressBloc>()
        ..add(FetchProgressData(range: _rangeToString(_range)))
        ..add(FetchLeaderboard()),
      child: Scaffold(
        backgroundColor: bgPage,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: borderCol, height: 1),
          ),
          title: Text(
            t.learningProgressTitle,
            style: const TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 16),
          ),
          actions: [
            IconButton(
              tooltip: t.reportIssueTooltip,
              icon: const Icon(Icons.flag_outlined, color: textMain),
              onPressed: _openReportDialog,
            ),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<ProgressBloc, ProgressState>(
            builder: (context, state) {
              if (state.status == ProgressStatus.loading || state.status == ProgressStatus.initial) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(t.failedToLoadData, style: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(message ?? t.pleaseTryAgainLater, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => _onRefresh(context),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.black, side: const BorderSide(color: Colors.grey)),
            child: Text(t.retry),
          )
        ],
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

    // 1. Tính tổng số phút đã học trong phạm vi hiện tại
    final totalMinutesInActualRange = _range == _Range.day
        ? studyTime.todayMinutes
        : studyTime.totalMinutesInRange;

    // 2. Tính tổng Mục tiêu cho phạm vi hiện tại (Sử dụng số ngày chính xác)
    final totalGoalMinutes = _calculateTotalGoalMinutes(_range, studyTime.goalMinutes);

    // 3. Tính lại progress (tiến trình) chính xác
    final progress = (totalGoalMinutes > 0 ? (totalMinutesInActualRange / totalGoalMinutes) : 0.0).clamp(0.0, 1.0);


    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);
    const borderColor = Color(0xFFE4E4E7);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return RefreshIndicator(
      onRefresh: () => _onRefresh(context),
      color: primaryColor,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.progressOverview, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textMain, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text(t.progressPerformanceMetrics, style: const TextStyle(fontSize: 14, color: textMuted)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _FilterTab(label: t.progressFilterDay, selected: _range == _Range.day, onTap: () => _onRangeSelected(context, _Range.day)),
                      _FilterTab(label: t.progressFilterWeek, selected: _range == _Range.week, onTap: () => _onRangeSelected(context, _Range.week)),
                      _FilterTab(label: t.progressFilterMonth, selected: _range == _Range.month, onTap: () => _onRangeSelected(context, _Range.month)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _ShadcnCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _periodHeading(_range, t),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textMain),
                          ),
                          const SizedBox(height: 4),
                          // Hiển thị tổng số phút đã học
                          Text(
                            _fmtHhMm(totalMinutesInActualRange, t),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textMain),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.timer_outlined, color: Theme.of(context).colorScheme.primary, size: 24),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: progress, // Sử dụng progress đã tính lại
                      color: primaryColor,
                      backgroundColor: const Color(0xFFF4F4F5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Hiển thị mục tiêu tổng đã tính lại
                      Text(t.progressGoalLine(_fmtHhMm(totalGoalMinutes, t)), style: const TextStyle(fontSize: 12, color: textMuted)),
                      Text(t.progressPercentCompleted((progress * 100).round()), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMain)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(t.progressDetailedStats, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textMain)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: [
                _StatBox(
                  icon: Icons.psychology, iconColor: const Color(0xFF8B5CF6),
                  value: '${stats.vocabLearned}', label: t.progressStatVocabulary,
                  onTap: () => _showStatDetailDialog(progressBloc, 'vocab', _range),
                ),
                _StatBox(
                  icon: Icons.menu_book, iconColor: const Color(0xFF3B82F6),
                  value: '${stats.readingAccuracy}%', label: t.progressStatReading,
                  onTap: () => _showStatDetailDialog(progressBloc, 'reading', _range),
                ),
                _StatBox(
                  icon: Icons.headphones, iconColor: const Color(0xFF22C55E),
                  value: '${stats.dictationAccuracy}%', label: t.progressStatListening,
                  onTap: () => _showStatDetailDialog(progressBloc, 'dictation', _range),
                ),
                _StatBox(
                  icon: Icons.task_alt, iconColor: const Color(0xFFF97316),
                  value: '${stats.lessonsCompleted}', label: t.progressStatLessons,
                  onTap: () => _showStatDetailDialog(progressBloc, 'lessons', _range),
                ),
                _StatBox(
                  icon: Icons.edit, iconColor: const Color(0xFFEC4899),
                  value: stats.avgWritingScore.toStringAsFixed(1), label: t.progressStatWriting,
                  onTap: () => _showStatDetailDialog(progressBloc, 'writing', _range),
                ),
                _StatBox(
                  icon: Icons.mic, iconColor: const Color(0xFF14B8A6),
                  value: '${stats.speakingAccuracy}%', label: t.progressStatSpeaking,
                  onTap: () => _showStatDetailDialog(progressBloc, 'speaking', _range),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.progressLeaderboard, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textMain)),

              ],
            ),
            const SizedBox(height: 12),

            _ShadcnCard(
              padding: EdgeInsets.zero,
              child: _buildLeaderboardContent(state, borderColor, t),
            ),

            const SizedBox(height: 24),

            _ShadcnCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.progressActivity, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textMain)),
                      const Icon(Icons.bar_chart, color: Color(0xFF71717A), size: 20),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 160,
                    child: WeeklyActivityBarsChart(
                      values: chart.minutes,
                      labels: chart.labels,
                      barColor: primaryColor,
                      highlightIndex: chart.labels.length - 1,
                      highlightColor: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                border: Border.all(color: const Color(0xFFBBF7D0)),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.celebration_rounded, color: Color(0xFF16A34A), size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(callout.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF15803D))),
                        const SizedBox(height: 4),
                        Text(callout.message, style: const TextStyle(fontSize: 13, color: Color(0xFF166534))),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFF15803D)),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardContent(ProgressState state, Color dividerColor, AppLocalizations t) {
    if (state.leaderboardStatus == LeaderboardStatus.loading) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.leaderboardStatus == LeaderboardStatus.error) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: Text(state.errorMessage ?? t.leaderboardLoadFailed, style: const TextStyle(fontSize: 12))),
      );
    }

    final users = state.leaderboardUsers;
    if (users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(child: Text(t.leaderboardEmpty, style: const TextStyle(color: Colors.grey))),
      );
    }

    return Column(
      children: List.generate(users.length, (index) {
        final user = users[index];

        if (user.isSeparator) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.white,
            child: const Center(
              child: Text('...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
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
            if (index < users.length - 1)
              Divider(height: 1, color: dividerColor),
          ],
        );
      }),
    );
  }
}

// ==============================================================================
// 🏞️ WIDGET COMPONENTS (Giữ nguyên)
// ==============================================================================

class _ShadcnCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _ShadcnCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
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

  @override
  Widget build(BuildContext context) {
    Color rankColor;
    if (rank == 1) rankColor = const Color(0xFFEAB308);
    else if (rank == 2) rankColor = const Color(0xFF94A3B8);
    else if (rank == 3) rankColor = const Color(0xFFB45309);
    else rankColor = const Color(0xFF71717A);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: isMe ? const Color(0xFFF0F9FF) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: rankColor,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                  image: (avatarUrl != null && avatarUrl!.isNotEmpty)
                      ? DecorationImage(image: NetworkImage(avatarUrl!), fit: BoxFit.cover)
                      : null,
                  color: const Color(0xFFF4F4F5),
                ),
                child: (avatarUrl == null || avatarUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 20, color: Color(0xFF71717A))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                    color: const Color(0xFF09090B),
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                xp,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF09090B),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: selected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFF09090B) : const Color(0xFF71717A),
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _StatBox({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E4E7)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF09090B))),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF71717A)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}