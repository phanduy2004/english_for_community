import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/feature/admin/layout/admin_page_scaffold.dart';
import 'package:english_for_community/feature/admin/layout/admin_skill_palette.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:english_for_community/feature/admin/layout/admin_widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:english_for_community/feature/admin/layout/admin_skeleton.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/entity/admin/admin_stats_entity.dart';
import '../../../core/get_it/get_it.dart';
import '../content_management/content_dashboard_page.dart';
import '../ops_center/admin_ops_center_page.dart';
import '../release_management/release_management_page.dart';
import '../report_management/report_management_page.dart';
import '../submission_managerment/activity_history_page.dart';
import '../user_management/user_management_page.dart';
import 'bloc/admin_bloc.dart';
import 'bloc/admin_event.dart';
import 'bloc/admin_state.dart';

// Enum nội bộ để quản lý Tab UI
enum _AdminRange { day, week, month }

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  static const String routeName = 'AdminDashboardPage';
  static const String routePath = '/admin-dashboard';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<AdminBloc>()..add(GetDashboardStatsEvent(range: 'week')),
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatefulWidget {
  const _AdminDashboardView();

  @override
  State<_AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<_AdminDashboardView> {
  _AdminRange _selectedRange = _AdminRange.week;
  final ScrollController _scrollController = ScrollController();

  void _onRangeChanged(_AdminRange newRange) {
    if (_selectedRange == newRange) return;
    setState(() {
      _selectedRange = newRange;
    });
    context.read<AdminBloc>().add(GetDashboardStatsEvent(range: newRange.name));
  }

  void _scrollToEnd() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppMotion.savedFade,
          curve: Curves.easeOutQuart,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AdminPageScaffold(
      title: l10n.adminOverviewTitle,
      subtitle: DateFormat('EEEE, d MMMM').format(DateTime.now()),
      scrollable: false,
      actions: [
        AdminSegmentedControl<_AdminRange>(
          segments: _AdminRange.values,
          selected: _selectedRange,
          onSelected: _onRangeChanged,
          labelBuilder: (r) => switch (r) {
            _AdminRange.day => 'Day',
            _AdminRange.week => 'Week',
            _AdminRange.month => 'Month',
          },
        ),
      ],
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state.status == AdminStatus.error && state.errorMessage != null) {
            AppCornerToast.show(context, state.errorMessage!, error: true);
          }
          if (state.status == AdminStatus.success) {
            _scrollToEnd();
          }
        },
        builder: (context, state) {
          if (state.status == AdminStatus.loading && state.stats == null) {
            return AdminSkeleton.page(AdminSkeleton.cardList());
          }

          if (state.stats == null) {
            return Center(
              child: AdminRetryButton(
                label: l10n.adminRetry,
                onPressed: () => context
                    .read<AdminBloc>()
                    .add(GetDashboardStatsEvent(range: _selectedRange.name)),
              ),
            );
          }

          final metrics = state.stats!.metrics;
          final chartData = state.stats!.chart;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AdminBloc>().add(GetDashboardStatsEvent(range: _selectedRange.name));
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: AppSpacing.s9),
                  children: [
                    AdminKpiGrid(
                      children: [
                        AdminKpiCard(
                          label: l10n.submissionsMetric,
                          value: '${metrics.submissions.value}',
                          meta: metrics.submissions.trendLabel ?? metrics.submissions.trend ?? '',
                          icon: Icons.layers_outlined,
                          accent: AdminSkillPalette.speaking,
                          onTap: () => context.pushNamed(ActivityHistoryPage.routeName),
                        ),
                        AdminKpiCard(
                          label: l10n.aiCostMetric,
                          value: '${metrics.aiCost.value}',
                          meta: metrics.aiCost.subLabel ?? '',
                          icon: Icons.token_outlined,
                          accent: AdminSkillPalette.listening,
                        ),
                        AdminKpiCard(
                          label: l10n.reportsMetric,
                          value: '${metrics.reports.value}',
                          meta: metrics.reports.status ?? 'Pending',
                          icon: Icons.flag_outlined,
                          accent: AdminSkillPalette.reports,
                          onTap: () => context.pushNamed(ReportManagementPage.routeName),
                        ),
                        AdminKpiCard(
                          label: l10n.activeUsersMetric,
                          value: '${metrics.activeUsers.value}',
                          meta: 'Today',
                          icon: Icons.group_outlined,
                          accent: AdminSkillPalette.users,
                          onTap: () => context.pushNamed(
                            UserManagementPage.routeName,
                            queryParameters: {'filter': 'today'},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s7),
                    _buildChartSection(chartData, constraints.maxWidth),
                    const SizedBox(height: AppSpacing.s7),
                    Text(l10n.managementSection, style: AdminWebUi.sectionTitle(context)),
                    const SizedBox(height: AppSpacing.s4),
                    _buildManagementSection(),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildChartSection(ChartData chartData, double availableWidth) {
    final l10n = context.l10n;
    return Container(
      decoration: AdminWebUi.cardDecoration(),
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.activityChart, style: AdminWebUi.webH2(context)),
                  const SizedBox(height: 4),
                  Text(_getChartSubtitle(), style: AdminWebUi.webCaption(context)),
                ],
              ),
              if (_selectedRange != _AdminRange.week)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(l10n.swipeToView, style: AdminWebUi.webCaption(context)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s5),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _LegendItem(color: AdminSkillPalette.writing, label: l10n.writingTitle),
                const SizedBox(width: AppSpacing.s5),
                _LegendItem(color: AdminSkillPalette.speaking, label: l10n.speakingPracticeTitle),
                const SizedBox(width: AppSpacing.s5),
                _LegendItem(color: AdminSkillPalette.reading, label: l10n.readingPracticeTitle),
                const SizedBox(width: AppSpacing.s5),
                _LegendItem(color: AdminSkillPalette.listening, label: l10n.listeningTitle),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Chart Layout Logic
          LayoutBuilder(
            builder: (context, boxConstraints) {
              final int dataCount = chartData.labels.length;

              // Nếu ở Web, cố gắng fit chart vào màn hình nếu ít cột
              double itemWidth = 60.0;
              if (_selectedRange == _AdminRange.week) {
                // Chia đều chiều rộng cho 7 ngày
                itemWidth = boxConstraints.maxWidth / 7;
              }

              // Tính chiều rộng tổng của chart
              final double chartWidth = (dataCount * itemWidth)
                  .clamp(boxConstraints.maxWidth, 5000.0);

              return SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartWidth,
                  height: 240,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: _buildBarChart(chartData),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildManagementSection() {
    final l10n = context.l10n;
    return AdminCardGrid(
      children: [
        AdminNavTile(
          icon: Icons.library_books_outlined,
          title: l10n.contentManagerTile,
          subtitle: l10n.contentManagerSub,
          onTap: () => context.pushNamed(ContentDashboardPage.routeName),
        ),
        AdminNavTile(
          icon: Icons.flag_outlined,
          title: l10n.reportsMenuTitle,
          subtitle: l10n.reportsMenuSub,
          accent: AppColors.chartHighlight,
          onTap: () => context.pushNamed(ReportManagementPage.routeName),
        ),
        AdminNavTile(
          icon: Icons.people_alt_outlined,
          title: l10n.usersMenuTitle,
          subtitle: l10n.usersMenuSub,
          accent: AppColors.success,
          onTap: () => context.pushNamed(UserManagementPage.routeName),
        ),
        AdminNavTile(
          icon: Icons.tune_outlined,
          title: l10n.adminNavOps,
          subtitle: 'Moderation, export, permissions',
          accent: AppColors.info,
          onTap: () => context.pushNamed(AdminOpsCenterPage.routeName),
        ),
        AdminNavTile(
          icon: Icons.system_update_alt_outlined,
          title: l10n.adminNavReleases,
          subtitle: 'Approve / schedule / publish',
          accent: AppColors.info,
          onTap: () => context.pushNamed(ReleaseManagementPage.routeName),
        ),
      ],
    );
  }

  String _getChartSubtitle() {
    switch (_selectedRange) {
      case _AdminRange.day:
        return 'Today (Hourly: 0h - 23h)';
      case _AdminRange.week:
        return 'This Week (Starts Mon)';
      case _AdminRange.month:
        return 'Last 30 Days';
    }
  }

  Widget _buildBarChart(ChartData chartData) {
    final int dataLength = chartData.labels.length;
    final double maxY = _calculateMaxY(chartData);

    // Bọc trong _GrowingBarChart để các cột "mọc" từ 0 lên khi hiện lần đầu và
    // mỗi khi đổi Day/Week/Month (fl_chart tween 0 → giá trị thật, easeOutCubic).
    return _GrowingBarChart(
      dataKey: _chartKey(chartData),
      builder: (grown) {
        final List<BarChartGroupData> barGroups = [];
        for (int i = 0; i < dataLength; i++) {
          final double w =
              (i < chartData.writing.length) ? chartData.writing[i].toDouble() : 0;
          final double s = (i < chartData.speaking.length)
              ? chartData.speaking[i].toDouble()
              : 0;
          final double r =
              (i < chartData.reading.length) ? chartData.reading[i].toDouble() : 0;
          final double d = (i < chartData.dictation.length)
              ? chartData.dictation[i].toDouble()
              : 0;

          barGroups.add(
            BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: [
                _makeRod(grown ? w : 0, AdminSkillPalette.writing, maxY),
                _makeRod(grown ? s : 0, AdminSkillPalette.speaking, maxY),
                _makeRod(grown ? r : 0, AdminSkillPalette.reading, maxY),
                _makeRod(grown ? d : 0, AdminSkillPalette.listening, maxY),
              ],
            ),
          );
        }

        return BarChart(
          BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calculateInterval(maxY),
          getDrawingHorizontalLine: (value) =>
              FlLine(color: AppColors.chartGrid, strokeWidth: 1, dashArray: [5, 5]),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: _calculateInterval(maxY),
                  getTitlesWidget: (val, meta) => Text(
                      val.toInt().toString(),
                      style: AdminWebUi.webCaption(context).copyWith(fontSize: 10)))),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 &&
                    value.toInt() < chartData.labels.length) {
                  final label = chartData.labels[value.toInt()];
                  String displayLabel = label;
                  try {
                    if (_selectedRange == _AdminRange.day) {
                      if (label.contains(':'))
                        displayLabel = "${int.parse(label.split(':')[0])}h";
                    } else {
                      final date = DateTime.parse(label);
                      displayLabel = DateFormat('dd/MM').format(date);
                    }
                  } catch (_) {}
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      displayLabel,
                      style: AdminWebUi.webCaption(context).copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
        barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (group) => AppColors.surfaceInverse,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String skill = '';
            switch (rodIndex) {
              case 0:
                skill = 'Write';
                break;
              case 1:
                skill = 'Speak';
                break;
              case 2:
                skill = 'Read';
                break;
              case 3:
                skill = 'Dict';
                break;
            }
            return BarTooltipItem(
                '$skill: ${(rod.toY).toInt()}',
                const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold));
          },
        )),
          ),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
        );
      },
    );
  }

  double _calculateMaxY(ChartData data) {
    double maxVal = 0;
    for (var v in data.writing) if (v > maxVal) maxVal = v.toDouble();
    for (var v in data.speaking) if (v > maxVal) maxVal = v.toDouble();
    for (var v in data.reading) if (v > maxVal) maxVal = v.toDouble();
    for (var v in data.dictation) if (v > maxVal) maxVal = v.toDouble();
    if (maxVal == 0) return 5;
    return maxVal * 1.2;
  }

  double _calculateInterval(double maxY) {
    if (maxY <= 5) return 1;
    if (maxY <= 10) return 2;
    if (maxY <= 50) return 10;
    return 20;
  }

  BarChartRodData _makeRod(double y, Color color, double maxY) {
    return BarChartRodData(
      toY: y,
      color: color,
      width: 6,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xs)),
      backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxY, color: AppColors.surfaceSubtle),
    );
  }

  /// Khoá nhận diện tập dữ liệu hiện tại — đổi khoá thì chart mọc lại từ 0.
  String _chartKey(ChartData c) =>
      '${_selectedRange.name}|${c.labels.join(',')}|${c.writing.join(',')}'
      '|${c.speaking.join(',')}|${c.reading.join(',')}|${c.dictation.join(',')}';
}

/// Bọc [BarChart] để các cột "mọc" từ 0 lên khi xuất hiện lần đầu và mỗi khi
/// dữ liệu đổi (đổi Day/Week/Month). fl_chart tự tween 0 → giá trị thật.
class _GrowingBarChart extends StatefulWidget {
  const _GrowingBarChart({required this.dataKey, required this.builder});

  final String dataKey;
  final Widget Function(bool grown) builder;

  @override
  State<_GrowingBarChart> createState() => _GrowingBarChartState();
}

class _GrowingBarChartState extends State<_GrowingBarChart> {
  bool _grown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _grown = true);
    });
  }

  @override
  void didUpdateWidget(covariant _GrowingBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataKey != widget.dataKey) {
      _grown = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _grown = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(_grown);
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(AppRadius.xs))),
        const SizedBox(width: 6),
        Text(label, style: AdminWebUi.webCaption(context).copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}




