import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProgressReportPage extends StatefulWidget {
  const ProgressReportPage({super.key});

  static String routeName = 'ProgressReportPage';
  static String routePath = '/progress';

  @override
  State<ProgressReportPage> createState() => _ProgressReportPageState();
}

enum _Range { day, week, month }

class _ProgressReportPageState extends State<ProgressReportPage> {
  _Range _range = _Range.day;

  // Sample data (bạn có thể bind sang provider/BLoC sau)
  final int _todayMinutes = 165; // 2h45m
  final int _goalMinutes = 240;  // 4h
  final int _vocabLearned = 1247;
  final int _quizAccuracy = 87;  // %
  final int _readingWpm = 165;
  final double _speakingWritingScore = 8.2;

  // 7 ngày gần nhất (đơn vị phút học)
  final List<int> _weeklyMinutes = const [60, 45, 80, 35, 70, 55, 90];
  final List<String> _weekdayLabels = const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  // Điều hướng (đổi sang route thực tế)
  void _downloadReport() {
    // TODO: xuất PDF ở giai đoạn sau
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng xuất PDF sẽ bổ sung ở giai đoạn sau.')),
    );
  }

  void _viewAllCertificates() => context.pushNamed('CertificatesPage');
  void _viewProgressDetail() => context.pushNamed('ProgressDetailPage');

  String _fmtHhMm(int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    final double progress = (_todayMinutes / _goalMinutes).clamp(0.0, 1.0);

    return Scaffold(

      backgroundColor: cs.background,
      appBar: AppBar(
        backgroundColor: cs.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onBackground),
          onPressed: () => context.pop(),
        ),
        title: Text('Progress',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w500)),
        actions: [
          IconButton(
            tooltip: 'Download Report',
            icon: Icon(Icons.download_rounded, color: cs.onBackground),
            onPressed: _downloadReport,
          ),
        ],
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header + filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Báo cáo Tiến độ',
                              style: txt.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Theo dõi quá trình học tập của bạn',
                              style: txt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _FilterPill(
                          label: 'Ngày',
                          selected: _range == _Range.day,
                          onTap: () => setState(() => _range = _Range.day),
                        ),
                        const SizedBox(width: 8),
                        _FilterPill(
                          label: 'Tuần',
                          selected: _range == _Range.week,
                          onTap: () => setState(() => _range = _Range.week),
                        ),
                        const SizedBox(width: 8),
                        _FilterPill(
                          label: 'Tháng',
                          selected: _range == _Range.month,
                          onTap: () => setState(() => _range = _Range.month),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Hôm nay / mục tiêu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Thời gian học hôm nay', style: txt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                            ),
                            Text(_fmtHhMm(_todayMinutes),
                                style: txt.bodyMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: progress,
                            color: cs.primary,
                            backgroundColor: cs.outlineVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Mục tiêu: ${_fmtHhMm(_goalMinutes)}',
                                style: txt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                            Text('${(progress * 100).round()}% hoàn thành',
                                style: txt.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Grid chỉ số
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView(
                  shrinkWrap: true,
                  primary: false,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  children: [
                    _StatCard(
                      icon: Icons.psychology_rounded,
                      iconColor: cs.primary,
                      value: '$_vocabLearned',
                      label: 'Từ đã nhớ',
                    ),
                    _StatCard(
                      icon: Icons.quiz_rounded,
                      iconColor: Colors.green,
                      value: '$_quizAccuracy%',
                      label: 'Độ chính xác',
                    ),
                    _StatCard(
                      icon: Icons.speed_rounded,
                      iconColor: cs.secondary,
                      value: '$_readingWpm',
                      label: 'WPM đọc',
                    ),
                    _StatCard(
                      icon: Icons.record_voice_over_rounded,
                      iconColor: cs.tertiary,
                      value: _speakingWritingScore.toStringAsFixed(1),
                      label: 'Điểm nói/viết',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Biểu đồ 7 ngày
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Biểu đồ tiến độ 7 ngày',
                                  style: txt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                            ),
                            Icon(Icons.show_chart_rounded, color: cs.onSurfaceVariant, size: 20),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 140,
                          child: _Bars(
                            values: _weeklyMinutes,
                            labels: _weekdayLabels,
                            barColor: cs.primary,
                            highlightIndex: 6, // CN
                            highlightColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Chứng nhận
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Chứng nhận đã đạt',
                                  style: txt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                            ),
                            InkWell(
                              onTap: _viewAllCertificates,
                              child: Text('Xem tất cả',
                                  style: txt.bodyMedium?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _CertificateCard(
                                borderColor: cs.primary,
                                iconColor: cs.primary,
                                title: 'Cơ bản A1',
                                dateOrStatus: '15/11/2024',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CertificateCard(
                                borderColor: Colors.green,
                                iconColor: Colors.green,
                                title: 'Ngữ pháp',
                                dateOrStatus: '22/11/2024',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CertificateCard(
                                borderColor: cs.outlineVariant,
                                iconColor: cs.onSurfaceVariant,
                                title: 'Từ vựng A2',
                                dateOrStatus: 'Đang học',
                                muted: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Callout “Tiến bộ tuyệt vời!”
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer.withOpacity(.35),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(Icons.trending_up_rounded, color: cs.primary, size: 48),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tiến bộ tuyệt vời!',
                                  style: txt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text(
                                'Bạn đã học liên tục 7 ngày và cải thiện 23% so với tuần trước.',
                                style: txt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 36,
                                child: OutlinedButton(
                                  onPressed: _viewProgressDetail,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: cs.primary,
                                    side: BorderSide(color: cs.primary, width: 2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  child: const Text('Xem chi tiết'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ------- Reusable widgets -------

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: selected ? null : Border.all(color: cs.outlineVariant, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: txt.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? cs.onPrimary : cs.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 8),
            Text(value, style: txt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: txt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _Bars extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxVal = (values.isEmpty
                ? 1
                : values.reduce((a, b) => a > b ? a : b))
            .toDouble();

        // Dự trữ không gian cho label và khoảng cách
        const double labelHeight = 20; // ~ chiều cao text 10–12px
        const double gap = 8;
        const double minBar = 12;

        final double totalH = constraints.maxHeight;
        final double barArea =
            (totalH - labelHeight - gap).clamp(0.0, totalH);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(values.length, (i) {
            final ratio = maxVal == 0 ? 0.0 : (values[i] / maxVal);
            final isHi = highlightIndex != null && i == highlightIndex;
            final c = isHi ? (highlightColor ?? Colors.green) : (barColor ?? cs.primary);
            final opacity = isHi ? 1.0 : (0.6 + ratio * 0.4);

            // Bar luôn nằm trong barArea
            final double barHeight =
                minBar + ratio.clamp(0.0, 1.0) * (barArea - minBar);

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 24,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: gap),
                SizedBox(
                  height: labelHeight,
                  child: Text(
                    labels[i],
                    style: txt.bodySmall?.copyWith(
                      fontSize: 10,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }
}


class _CertificateCard extends StatelessWidget {
  const _CertificateCard({
    required this.borderColor,
    required this.iconColor,
    required this.title,
    required this.dateOrStatus,
    this.muted = false,
  });

  final Color borderColor;
  final Color iconColor;
  final String title;
  final String dateOrStatus;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    final bg = muted ? cs.surfaceVariant : cs.surface;
    final fg = muted ? cs.onSurfaceVariant : cs.onSurface;

    return Container(
      // Increase the height slightly to accommodate the content
      height: 130,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: muted ? 1 : 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Add this to minimize the column height
          children: [
            Icon(
              muted ? Icons.workspace_premium_outlined : Icons.workspace_premium_rounded,
              color: iconColor,
              size: 28, // Slightly reduce icon size
            ),
            const SizedBox(height: 6),
            Text(
              title, 
              textAlign: TextAlign.center, 
              style: txt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600, 
                color: fg,
                fontSize: 13, // Slightly reduce text size
              ),
              maxLines: 1, // Ensure single line
              overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
            ),
            const SizedBox(height: 4),
            Text(
              dateOrStatus,
              textAlign: TextAlign.center,
              style: txt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 10),
              maxLines: 1, // Ensure single line
              overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
            ),
          ],
        ),
      ),
    );
  }
}
