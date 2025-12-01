import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/entity/admin/admin_stats_entity.dart';
import '../../../core/get_it/get_it.dart';
import '../../auth/bloc/user_bloc.dart';
import '../../auth/bloc/user_event.dart';
import '../content_management/content_dashboard_page.dart';
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
      create: (_) => getIt<AdminBloc>()..add(GetDashboardStatsEvent(range: 'week')),
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

  // --- COLOR PALETTE ---
  final bgPage = const Color(0xFFF8FAFC);
  final textMain = const Color(0xFF0F172A);
  final textMuted = const Color(0xFF64748B);
  final borderCol = const Color(0xFFE2E8F0);
  final white = Colors.white;

  // Colors for skills
  final colWriting = const Color(0xFFEF4444);
  final colSpeaking = const Color(0xFF3B82F6);
  final colReading = const Color(0xFFF59E0B);
  final colDictation = const Color(0xFF8B5CF6);

  void _handleLogout() {
    context.read<UserBloc>().add(SignOutEvent());
  }

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
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutQuart,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPage,
      appBar: _buildAppBar(),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state.status == AdminStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
            );
          }
          if (state.status == AdminStatus.success) {
            _scrollToEnd();
          }
        },
        builder: (context, state) {
          if (state.status == AdminStatus.loading && state.stats == null) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          if (state.stats == null) {
            return Center(
              child: OutlinedButton.icon(
                onPressed: () => context.read<AdminBloc>().add(GetDashboardStatsEvent(range: _selectedRange.name)),
                icon: const Icon(Icons.refresh),
                label: const Text("Thử lại"),
              ),
            );
          }

          final metrics = state.stats!.metrics;
          final chartData = state.stats!.chart;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AdminBloc>().add(GetDashboardStatsEvent(range: _selectedRange.name));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER & FILTER ---
                  // [FIX] Thay Row bằng Wrap để tránh lỗi overflow pixel
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.0, // Khoảng cách ngang
                    runSpacing: 12.0, // Khoảng cách dọc khi xuống dòng
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, d MMMM').format(DateTime.now()),
                            style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tổng quan',
                            style: TextStyle(color: textMain, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderCol),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // Đảm bảo Row này chỉ chiếm không gian tối thiểu
                          children: [
                            _FilterTab(label: 'Ngày', selected: _selectedRange == _AdminRange.day, onTap: () => _onRangeChanged(_AdminRange.day)),
                            _FilterTab(label: 'Tuần', selected: _selectedRange == _AdminRange.week, onTap: () => _onRangeChanged(_AdminRange.week)),
                            _FilterTab(label: 'Tháng', selected: _selectedRange == _AdminRange.month, onTap: () => _onRangeChanged(_AdminRange.month)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- METRICS GRID ---
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _MetricCard(
                        title: 'Bài nộp',
                        value: '${metrics.submissions.value}',
                        trend: metrics.submissions.trend ?? '',
                        subLabel: metrics.submissions.trendLabel ?? '',
                        icon: Icons.layers_outlined,
                        accentColor: colSpeaking,
                      ),
                      _MetricCard(
                        title: 'Chi phí AI (Est)',
                        value: '${metrics.aiCost.value}',
                        trend: 'Usage',
                        subLabel: metrics.aiCost.subLabel ?? '',
                        icon: Icons.token_outlined,
                        accentColor: colDictation,
                      ),
                      _MetricCard(
                        title: 'Báo cáo lỗi',
                        value: '${metrics.reports.value}',
                        trend: metrics.reports.status ?? '',
                        subLabel: "Chờ xử lý",
                        icon: Icons.flag_outlined,
                        accentColor: const Color(0xFFF43F5E),
                        isAlert: (metrics.reports.value is int && (metrics.reports.value as int) > 0),
                      ),
                      _MetricCard(
                        title: 'Người dùng',
                        value: '${metrics.activeUsers.value}',
                        trend: 'Online',
                        subLabel: "Hôm nay",
                        icon: Icons.group_outlined,
                        accentColor: const Color(0xFF10B981),
                        onTap: () {
                          context.pushNamed(
                              UserManagementPage.routeName,
                              queryParameters: {'filter': 'today'}
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- CHART SECTION ---
                  _ShadcnCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Biểu đồ hoạt động',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textMain)),
                                const SizedBox(height: 4),
                                Text(
                                  _getChartSubtitle(),
                                  style: TextStyle(fontSize: 12, color: textMuted),
                                ),
                              ],
                            ),
                            if (_selectedRange != _AdminRange.week)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                                child: Text("Vuốt ngang để xem", style: TextStyle(fontSize: 10, color: textMuted)),
                              )
                          ],
                        ),
                        const SizedBox(height: 16),

                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _LegendItem(color: colWriting, label: "Writing"), const SizedBox(width: 16),
                              _LegendItem(color: colSpeaking, label: "Speaking"), const SizedBox(width: 16),
                              _LegendItem(color: colReading, label: "Reading"), const SizedBox(width: 16),
                              _LegendItem(color: colDictation, label: "Dictation"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final int dataCount = chartData.labels.length;
                            double itemWidth = 60.0;
                            if (_selectedRange == _AdminRange.week) itemWidth = constraints.maxWidth / 7;

                            final double chartWidth = (dataCount * itemWidth).clamp(constraints.maxWidth, 5000.0);

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
                  ),

                  const SizedBox(height: 24),

                  // --- MANAGEMENT LINKS ---
                  Text('Quản lý', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textMain)),
                  const SizedBox(height: 12),
                  _ManagementTile(
                    icon: Icons.library_books_outlined,
                    title: 'Quản lý Nội dung',
                    subtitle: 'Tạo đề bài, chỉnh sửa bài đọc & nghe',
                    color: textMain,
                    onTap: () {
                      context.pushNamed(ContentDashboardPage.routeName);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ManagementTile(
                          icon: Icons.bug_report_outlined,
                          title: 'Báo cáo',
                          subtitle: 'Phản hồi lỗi',
                          color: const Color(0xFFF59E0B),
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ManagementTile(
                          icon: Icons.people_alt_outlined,
                          title: 'Người dùng',
                          subtitle: 'Danh sách User',
                          color: const Color(0xFF10B981),
                          onTap: () {
                            context.pushNamed(UserManagementPage.routeName);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Text phụ đề cho biểu đồ
  String _getChartSubtitle() {
    switch (_selectedRange) {
      case _AdminRange.day: return 'Hôm nay (Theo giờ: 0h - 23h)';
      case _AdminRange.week: return 'Tuần này (Bắt đầu từ Thứ 2)';
      case _AdminRange.month: return '30 ngày gần nhất';
    }
  }

  // Logic vẽ biểu đồ
  Widget _buildBarChart(ChartData chartData) {
    final List<BarChartGroupData> barGroups = [];
    final int dataLength = chartData.labels.length;

    final double maxY = _calculateMaxY(chartData);

    for (int i = 0; i < dataLength; i++) {
      final double w = (i < chartData.writing.length) ? chartData.writing[i].toDouble() : 0;
      final double s = (i < chartData.speaking.length) ? chartData.speaking[i].toDouble() : 0;
      final double r = (i < chartData.reading.length) ? chartData.reading[i].toDouble() : 0;
      final double d = (i < chartData.dictation.length) ? chartData.dictation[i].toDouble() : 0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 4,
          barRods: [
            _makeRod(w, colWriting, maxY),
            _makeRod(s, colSpeaking, maxY),
            _makeRod(r, colReading, maxY),
            _makeRod(d, colDictation, maxY),
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
          getDrawingHorizontalLine: (value) => FlLine(color: borderCol, strokeWidth: 1, dashArray: [5, 5]),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: _calculateInterval(maxY),
                  getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: TextStyle(color: textMuted, fontSize: 10))
              )
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < chartData.labels.length) {
                  final label = chartData.labels[value.toInt()];
                  String displayLabel = label;

                  try {
                    if (_selectedRange == _AdminRange.day) {
                      if (label.contains(':')) displayLabel = "${int.parse(label.split(':')[0])}h";
                    } else {
                      final date = DateTime.parse(label);
                      displayLabel = DateFormat('dd/MM').format(date);
                    }
                  } catch (_) {}

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(displayLabel, style: TextStyle(color: textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
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
            getTooltipColor: (group) => const Color(0xFF1E293B),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String skill = '';
              switch (rodIndex) { case 0: skill = 'Write'; break; case 1: skill = 'Speak'; break; case 2: skill = 'Read'; break; case 3: skill = 'Dict'; break; }
              return BarTooltipItem(
                  '$skill: ${(rod.toY).toInt()}',
                  const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
              );
            },
          ),
        ),
      ),
    );
  }

  double _calculateMaxY(ChartData data) {
    double maxVal = 0;
    for(var v in data.writing) if(v > maxVal) maxVal = v.toDouble();
    for(var v in data.speaking) if(v > maxVal) maxVal = v.toDouble();
    for(var v in data.reading) if(v > maxVal) maxVal = v.toDouble();
    for(var v in data.dictation) if(v > maxVal) maxVal = v.toDouble();
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
      borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
      backDrawRodData: BackgroundBarChartRodData(
          show: true,
          toY: maxY,
          color: const Color(0xFFF1F5F9)
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: white,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: textMain, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Admin Console', style: TextStyle(color: textMain, fontSize: 16, fontWeight: FontWeight.w700)),
              const Text('Super Admin', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w400)),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderCol, height: 1)),
      actions: [
        IconButton(onPressed: () {}, icon: Icon(Icons.notifications_outlined, color: textMuted)),
        IconButton(onPressed: _handleLogout, icon: Icon(Icons.logout, color: textMuted)),
        const SizedBox(width: 12),
      ],
    );
  }
}

// --- WIDGETS ---

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
        // 👇 Đã chỉnh nhỏ padding lại (cũ: h16, v6)
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1F5F9) : Colors.transparent,
          // 👇 Bo góc nhỏ hơn một chút (cũ: 6)
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            // 👇 Font chữ nhỏ hơn (cũ: 13)
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
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
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title, value, trend, subLabel;
  final IconData icon;
  final Color accentColor;
  final bool isAlert;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.subLabel,
    required this.icon,
    required this.accentColor,
    this.isAlert = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ShadcnCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis)),
            Icon(icon, size: 18, color: accentColor),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isAlert ? const Color(0xFFE11D48) : const Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Row(children: [
              if (trend.isNotEmpty) ...[
                Text(trend, style: TextStyle(fontSize: 11, color: isAlert ? const Color(0xFFE11D48) : const Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
              ],
              Flexible(child: Text(subLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ])
        ],
      ),
    );
  }
}

class _ManagementTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final VoidCallback onTap;

  const _ManagementTile({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _ShadcnCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }
}

class _ShadcnCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  const _ShadcnCard({required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      ),
    );
  }
}