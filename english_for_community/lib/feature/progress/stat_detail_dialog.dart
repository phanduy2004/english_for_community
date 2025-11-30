import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Đảm bảo import đúng đường dẫn
import 'package:english_for_community/feature/progress/bloc/progress_bloc.dart';
import 'package:english_for_community/feature/progress/bloc/progress_state.dart';
import 'package:english_for_community/feature/progress/bloc/progress_event.dart';
import '../../core/entity/progress_summary_entity.dart';

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

  // ... (Các hàm _rangeToString, _getTitle, initState giữ nguyên)
  String _rangeToString(StatDetailRange range) {
    switch (range) {
      case StatDetailRange.day: return 'day';
      case StatDetailRange.week: return 'week';
      case StatDetailRange.month: return 'month';
    }
  }

  String _getTitle() {
    switch (widget.statKey) {
      case 'vocab': return 'Vocabulary Detail';
      case 'reading': return 'Reading Attempts Detail';
      case 'dictation': return 'Listening/Dictation Detail';
      case 'speaking': return 'Speaking Practice Detail';
      case 'writing': return 'Writing Submissions Detail';
      case 'lessons': return 'Lessons Completed Detail';
      default: return 'Progress Detail';
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

  // Helper: Định dạng ngày
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

  // 🔥 1. Widget Item đơn lẻ (Đã tinh chỉnh cho Grouped List)
  Widget _buildDetailItem(ProgressDetailEntity item, String statKey, Color primaryColor) {
    final dateDisplay = _formatDate(item.date);

    String subtitle;
    String valueDisplay;
    String unit;
    IconData icon;

    // Logic cho lessons (Khi đã nằm trong nhóm, không cần hiện Type ở subtitle nữa)
    if (statKey == 'lessons') {
      icon = Icons.check_circle_outline_rounded; // Icon mặc định cho item con
      subtitle = dateDisplay; // Chỉ hiện ngày
      valueDisplay = '';
      unit = '';

      return _DetailRow(
        icon: icon,
        title: item.title,
        subtitle: subtitle,
        value: valueDisplay,
        unit: unit,
        isCompact: true, // Flag để render nhỏ gọn hơn
      );
    }

    // ... (Giữ nguyên logic cho các statKey khác: reading, speaking, vocab...)
    if (statKey == 'reading') {
      final scoreDisplay = (item.score).toString();
      subtitle = 'Accuracy: ${scoreDisplay}% | Date: $dateDisplay';
      valueDisplay = scoreDisplay;
      unit = '%';
      icon = Icons.menu_book_rounded;
    } else if (statKey == 'speaking') {
      subtitle = 'Score: ${item.score}% | Date: $dateDisplay';
      valueDisplay = item.score.toString();
      unit = '%';
      icon = Icons.mic_external_on_rounded;
    } else if (statKey == 'writing') {
      subtitle = 'Band Score: ${item.score} | Date: $dateDisplay';
      valueDisplay = item.score.toString();
      unit = '';
      icon = Icons.edit_note_rounded;
    } else if (statKey == 'dictation' || statKey == 'listening') {
      subtitle = 'Score: ${item.score}% | Date: $dateDisplay';
      valueDisplay = item.score.toString();
      unit = '%';
      icon = Icons.headphones_rounded;
    } else {
      subtitle = 'Date: $dateDisplay';
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

  // 🔥 2. Hàm xây dựng danh sách gom nhóm (Dành riêng cho Lessons)
  Widget _buildGroupedLessonsList(List<ProgressDetailEntity> data, Color primaryColor) {
    // Gom nhóm data theo item.type
    Map<String, List<ProgressDetailEntity>> groupedData = {};
    for (var item in data) {
      // Nếu type rỗng thì cho vào nhóm 'Other'
      String key = (item.type.isEmpty) ? 'Other' : item.type;
      if (!groupedData.containsKey(key)) {
        groupedData[key] = [];
      }
      groupedData[key]!.add(item);
    }

    // Dựng UI từ Map
    return ListView(
      shrinkWrap: true, // Quan trọng để nằm trong Column
      physics: const NeverScrollableScrollPhysics(), // Để cha (Dialog) scroll
      children: groupedData.entries.map((entry) {
        String groupTitle = entry.key;
        List<ProgressDetailEntity> groupItems = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Nhóm (Ví dụ: Reading) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF4F4F5), width: 1)),
              ),
              child: Text(
                groupTitle.toUpperCase(),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                    letterSpacing: 0.5
                ),
              ),
            ),

            // --- Danh sách item trong nhóm ---
            ...groupItems.map((item) => _buildDetailItem(item, 'lessons', primaryColor)),

            const SizedBox(height: 8), // Khoảng cách giữa các nhóm
          ],
        );
      }).toList(),
    );
  }

  // 🔥 3. Hàm dựng list chính
  Widget _buildDetailList(BuildContext context, ProgressState state) {
    const textMuted = Color(0xFF71717A);
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (state.detailStatus == ProgressDetailStatus.loading) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
    }

    if (state.detailStatus == ProgressDetailStatus.error) {
      return Center(child: Padding(padding: EdgeInsets.all(20), child: Text(state.errorMessage ?? 'Error')));
    }

    if (state.detailStatus == ProgressDetailStatus.success) {
      final List<ProgressDetailEntity> data = state.detailData.cast<ProgressDetailEntity>();

      if (data.isEmpty) {
        return Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No data found.', style: TextStyle(color: textMuted))));
      }

      // 🔥 NẾU LÀ LESSONS => GỌI HÀM GOM NHÓM
      if (widget.statKey == 'lessons') {
        return _buildGroupedLessonsList(data, primaryColor);
      }

      // Các trường hợp khác giữ nguyên list phẳng
      return Column(
        children: data
            .map((item) => _buildDetailItem(item, widget.statKey, primaryColor))
            .toList(),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    // ... (Giữ nguyên phần khung Dialog)
    const textMain = Color(0xFF09090B);
    const borderCol = Color(0xFFE4E4E7);

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600), // Giới hạn chiều cao
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getTitle(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textMain)),
                        const SizedBox(height: 4),
                        Text('Showing ${widget.rangeLabel.toLowerCase()} log.', style: const TextStyle(fontSize: 13, color: Color(0xFF71717A))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFA1A1AA), size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: borderCol, height: 1),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: BlocBuilder<ProgressBloc, ProgressState>(
                  builder: (context, state) => _buildDetailList(context, state),
                ),
              ),
            ),

            const Divider(color: borderCol, height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textMain,
                    side: const BorderSide(color: borderCol),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// Widget DetailRow có thêm cờ isCompact để hiển thị nhỏ gọn hơn trong list gom nhóm
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String unit;
  final bool isCompact; // Thêm cờ này

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
    const textMuted = Color(0xFF71717A);
    const borderCol = Color(0xFFF4F4F5);

    return Container(
      padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 16), // Compact thì padding ít hơn
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: borderCol, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: isCompact ? Colors.grey : Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xFF09090B))
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: textMuted)),
                ]
              ],
            ),
          ),
          if (value.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF09090B))),
                const SizedBox(width: 2),
                Text(unit, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textMuted)),
              ],
            ),
        ],
      ),
    );
  }
}