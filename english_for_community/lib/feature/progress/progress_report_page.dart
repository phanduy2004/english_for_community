import 'dart:math' as math;
import 'dart:ui';

import 'package:english_for_community/feature/progress/report_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:english_for_community/core/entity/progress_summary_entity.dart';
import 'package:english_for_community/feature/progress/bloc/progress_bloc.dart';
import 'package:english_for_community/feature/progress/bloc/progress_event.dart';
import 'package:english_for_community/feature/progress/bloc/progress_state.dart';
import 'package:english_for_community/feature/progress/stat_detail_dialog.dart';
import 'package:english_for_community/feature/progress/user_profile_dialog.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/entity/leaderboard_entity.dart';
import 'package:english_for_community/core/repository/user_repository.dart';

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

  String _fmtHhMm(int totalMinutes) {
    if (totalMinutes < 0) return '0h 0m';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h}h ${m}m';
  }

  String _rangeToString(_Range range) {
    switch (range) {
      case _Range.day: return 'day';
      case _Range.week: return 'week';
      case _Range.month: return 'month';
    }
  }

  String _rangeToLabel(_Range range) {
    switch (range) {
      case _Range.day: return 'Daily';
      case _Range.week: return 'Weekly';
      case _Range.month: return 'Monthly';
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
    showDialog(
        context: context,
        builder: (ctx) {
          return BlocProvider.value(
            value: bloc,
            child: StatDetailDialog(
              statKey: statKey,
              range: _rangeToDialogEnum(range),
              rangeLabel: _rangeToLabel(range),
            ),
          );
        }
    );
  }

  void _showUserProfile(BuildContext context, String userId) {
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
                title: const Text('Error'),
                content: const Text('Failed to load user profile.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              );
            }

            if (snapshot.hasData) {
              return snapshot.data!.fold(
                    (failure) => AlertDialog(
                  title: const Text('Error'),
                  content: Text(failure.message),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
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
          title: const Text(
            'Learning Progress',
            style: TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 16),
          ),
          actions: [
            IconButton(
              tooltip: 'Report Issue',
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
                return _buildErrorUI(context, state.errorMessage);
              }
              if (state.summary != null) {
                return _buildSuccessUI(context, state);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorUI(BuildContext context, String? message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text('Failed to load data', style: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(message ?? 'Please try again later', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => _onRefresh(context),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.black, side: const BorderSide(color: Colors.grey)),
            child: const Text('Retry'),
          )
        ],
      ),
    );
  }

  Widget _buildSuccessUI(BuildContext context, ProgressState state) {
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
                    const Text('Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textMain, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    const Text('Performance metrics', style: TextStyle(fontSize: 14, color: textMuted)),
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
                      _FilterTab(label: 'Day', selected: _range == _Range.day, onTap: () => _onRangeSelected(context, _Range.day)),
                      _FilterTab(label: 'Week', selected: _range == _Range.week, onTap: () => _onRangeSelected(context, _Range.week)),
                      _FilterTab(label: 'Month', selected: _range == _Range.month, onTap: () => _onRangeSelected(context, _Range.month)),
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
                            _range == _Range.day ? 'Today' : (_range == _Range.week ? 'This Week' : 'This Month'),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textMain),
                          ),
                          const SizedBox(height: 4),
                          // Hiển thị tổng số phút đã học
                          Text(
                            _fmtHhMm(totalMinutesInActualRange),
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
                      Text('Goal: ${_fmtHhMm(totalGoalMinutes)}', style: const TextStyle(fontSize: 12, color: textMuted)),
                      Text('${(progress * 100).round()}% completed', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMain)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Detailed Stats', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textMain)),
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
                  value: '${stats.vocabLearned}', label: 'Vocabulary',
                  onTap: () => _showStatDetailDialog(progressBloc, 'vocab', _range),
                ),
                _StatBox(
                  icon: Icons.menu_book, iconColor: const Color(0xFF3B82F6),
                  value: '${stats.readingAccuracy}%', label: 'Reading',
                  onTap: () => _showStatDetailDialog(progressBloc, 'reading', _range),
                ),
                _StatBox(
                  icon: Icons.headphones, iconColor: const Color(0xFF22C55E),
                  value: '${stats.dictationAccuracy}%', label: 'Listening',
                  onTap: () => _showStatDetailDialog(progressBloc, 'dictation', _range),
                ),
                _StatBox(
                  icon: Icons.task_alt, iconColor: const Color(0xFFF97316),
                  value: '${stats.lessonsCompleted}', label: 'Lessons',
                  onTap: () => _showStatDetailDialog(progressBloc, 'lessons', _range),
                ),
                _StatBox(
                  icon: Icons.edit, iconColor: const Color(0xFFEC4899),
                  value: stats.avgWritingScore.toStringAsFixed(1), label: 'Writing',
                  onTap: () => _showStatDetailDialog(progressBloc, 'writing', _range),
                ),
                _StatBox(
                  icon: Icons.mic, iconColor: const Color(0xFF14B8A6),
                  value: '${stats.speakingAccuracy}%', label: 'Speaking',
                  onTap: () => _showStatDetailDialog(progressBloc, 'speaking', _range),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Leaderboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textMain)),

              ],
            ),
            const SizedBox(height: 12),

            _ShadcnCard(
              padding: EdgeInsets.zero,
              child: _buildLeaderboardContent(state, borderColor),
            ),

            const SizedBox(height: 24),

            _ShadcnCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textMain)),
                      const Icon(Icons.bar_chart, color: Color(0xFF71717A), size: 20),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 160,
                    child: _Bars(
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

  Widget _buildLeaderboardContent(ProgressState state, Color dividerColor) {
    if (state.leaderboardStatus == LeaderboardStatus.loading) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.leaderboardStatus == LeaderboardStatus.error) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: Text(state.errorMessage ?? 'Cannot load leaderboard', style: const TextStyle(fontSize: 12))),
      );
    }

    final users = state.leaderboardUsers;
    if (users.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: Text('No leaderboard data available', style: TextStyle(color: Colors.grey))),
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
class _Bars extends StatefulWidget {
  const _Bars({
    required this.values,
    required this.labels,
    this.barColor,
    this.highlightIndex,
    this.highlightColor,
  });

  final List<int> values;
  final List<String> labels;
  final Color? barColor;
  final int? highlightIndex;
  final Color? highlightColor;

  @override
  State<_Bars> createState() => _BarsState();
}

class _BarsState extends State<_Bars> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _Bars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labels.length != widget.labels.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const axisColor = Color(0xFFA1A1AA);
    const gridColor = Color(0xFFF4F4F5);

    final maxVal = (widget.values.isEmpty ? 0 : widget.values.reduce((a, b) => a > b ? a : b)).toDouble();
    double chartTopVal;
    if (maxVal <= 10) {
      chartTopVal = 10;
    } else if (maxVal <= 60) {
      chartTopVal = (maxVal / 10).ceil() * 10.0;
    } else {
      chartTopVal = (maxVal / 30).ceil() * 30.0;
    }
    if (chartTopVal == 0) chartTopVal = 10;

    return LayoutBuilder(
      builder: (context, constraints) {
        const double xAxisLabelHeight = 20;
        const double xAxisGap = 8;
        const double yAxisWidth = 30;

        final double barAreaHeight = (constraints.maxHeight - xAxisLabelHeight - xAxisGap).clamp(0.0, constraints.maxHeight);
        final double chartAreaWidth = constraints.maxWidth - yAxisWidth;

        final int itemCount = widget.values.length;
        const double minItemWidth = 46.0;
        final double totalContentWidth = (itemCount * minItemWidth > chartAreaWidth)
            ? itemCount * minItemWidth
            : chartAreaWidth;

        final double itemSlotWidth = itemCount > 0 ? totalContentWidth / itemCount : 0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Lớp 1: Grid Lines
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: barAreaHeight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Divider(height: 1, color: gridColor),
                            const Divider(height: 1, color: gridColor),
                            const Divider(height: 1, color: gridColor),
                          ],
                        ),
                      ),
                      const SizedBox(height: xAxisLabelHeight + xAxisGap),
                    ],
                  ),

                  // Lớp 2: Nội dung
                  SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: totalContentWidth,
                      height: constraints.maxHeight,
                      child: Stack(
                        children: [
                          // A. VẼ CỘT (BARS)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(itemCount, (i) {
                              final value = widget.values[i];
                              final ratio = (value / chartTopVal).clamp(0.0, 1.0);
                              final double barHeight = (value == 0) ? 0.0 : (ratio * barAreaHeight).clamp(4.0, barAreaHeight);
                              final isHi = widget.highlightIndex != null && i == widget.highlightIndex;
                              final c = isHi ? (widget.highlightColor ?? Colors.orange) : (widget.barColor ?? Colors.blue);

                              return SizedBox(
                                width: itemSlotWidth,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: 14,
                                      height: barHeight,
                                      decoration: BoxDecoration(
                                        color: c,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                      ),
                                    ),
                                    const SizedBox(height: xAxisGap),
                                    SizedBox(
                                      height: xAxisLabelHeight,
                                      child: Center(
                                        child: Text(
                                          widget.labels[i],
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isHi ? FontWeight.bold : FontWeight.normal,
                                            color: isHi ? const Color(0xFF09090B) : axisColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),

                          // B. VẼ ĐƯỜNG NÉT ĐỨT + MŨI TÊN
                          IgnorePointer(
                            child: CustomPaint(
                              size: Size(totalContentWidth, barAreaHeight),
                              painter: _DashedTrendLinePainter(
                                values: widget.values,
                                itemWidth: itemSlotWidth,
                                maxValue: chartTopVal,
                                lineColor: const Color(0xFFEF4444), // Màu đỏ
                                lineWidth: 1.5, // 🔥 Nét mỏng hơn (trước là 2.5)
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- TRỤC Y ---
            SizedBox(
              width: yAxisWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: barAreaHeight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("${chartTopVal.round()}", style: const TextStyle(fontSize: 10, color: axisColor)),
                        Text("${(chartTopVal / 2).round()}", style: const TextStyle(fontSize: 10, color: axisColor)),
                        const Text("0", style: const TextStyle(fontSize: 10, color: axisColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: xAxisLabelHeight + xAxisGap),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// 🔥 Class Painter mới: Nét đứt + Mũi tên
class _DashedTrendLinePainter extends CustomPainter {
  final List<int> values;
  final double itemWidth;
  final double maxValue;
  final Color lineColor;
  final double lineWidth;

  _DashedTrendLinePainter({
    required this.values,
    required this.itemWidth,
    required this.maxValue,
    required this.lineColor,
    required this.lineWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    double getX(int index) => (index * itemWidth) + (itemWidth / 2);
    double getY(int index) {
      final val = values[index];
      final ratio = (val / maxValue).clamp(0.0, 1.0);
      return size.height - (ratio * size.height);
    }

    // 1. Tạo đường dẫn gốc (đường cong liền mạch)
    final Path path = Path();
    path.moveTo(getX(0), getY(0));

    for (int i = 0; i < values.length - 1; i++) {
      final double x1 = getX(i);
      final double y1 = getY(i);
      final double x2 = getX(i + 1);
      final double y2 = getY(i + 1);

      final double controlX1 = x1 + (x2 - x1) / 2;
      final double controlY1 = y1;
      final double controlX2 = x1 + (x2 - x1) / 2;
      final double controlY2 = y2;

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, x2, y2);
    }

    // 2. Chuyển đổi thành Nét đứt (Dashed Line)
    final Path dashedPath = Path();
    double dashWidth = 6.0; // Độ dài nét gạch
    double dashSpace = 4.0; // Độ dài khoảng trống
    double distance = 0.0;

    // Sử dụng PathMetrics để đo và cắt đường dẫn
    for (PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        dashedPath.addPath(
          measurePath.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    // 3. Vẽ nét đứt
    final Paint paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(dashedPath, paint);

    // 4. Vẽ các chấm tròn tại đỉnh (Giữ lại để dễ nhìn data)
    final Paint dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final Paint dotBorderPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5; // Viền chấm cũng mỏng lại

    for (int i = 0; i < values.length; i++) {
      final offset = Offset(getX(i), getY(i));
      // Nếu là điểm cuối cùng thì không vẽ chấm tròn, để nhường chỗ cho mũi tên
      if (i != values.length - 1) {
        canvas.drawCircle(offset, 3.0, dotPaint);
        canvas.drawCircle(offset, 3.0, dotBorderPaint);
      }
    }

    // 5. 🔥 Vẽ Mũi tên ở cuối đường (Arrowhead)
    if (values.length > 1) {
      // Lấy thông số của đoạn cuối đường dẫn
      final PathMetric lastMetric = path.computeMetrics().last;
      // Lấy tiếp tuyến (tangent) tại điểm cuối cùng để biết góc xoay
      final Tangent? tangent = lastMetric.getTangentForOffset(lastMetric.length);

      if (tangent != null) {
        final Offset endPoint = tangent.position;
        final double angle = -tangent.angle; // Góc xoay của mũi tên

        canvas.save();
        // Di chuyển canvas đến điểm cuối
        canvas.translate(endPoint.dx, endPoint.dy);
        // Xoay canvas theo hướng đường kẻ (lưu ý: tangent.angle tính theo radian)
        canvas.rotate(-angle);

        // Vẽ hình tam giác mũi tên
        final Path arrowPath = Path();
        arrowPath.moveTo(0, 0); // Đỉnh mũi tên
        arrowPath.lineTo(-6, -4); // Cánh trái
        arrowPath.lineTo(-6, 4);  // Cánh phải
        arrowPath.close();

        final Paint arrowPaint = Paint()
          ..color = lineColor
          ..style = PaintingStyle.fill;

        canvas.drawPath(arrowPath, arrowPaint);
        canvas.restore();
      }
    } else if (values.length == 1) {
      // Nếu chỉ có 1 điểm, vẽ mũi tên hướng lên nhẹ hoặc dấu chấm
      // (Trường hợp hiếm khi mới bắt đầu tuần)
      final offset = Offset(getX(0), getY(0));
      canvas.drawCircle(offset, 3.0, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedTrendLinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.itemWidth != itemWidth ||
        oldDelegate.maxValue != maxValue;
  }
}