import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/get_it/get_it.dart';
import '../../../../core/entity/writing_topic_entity.dart';
// Đảm bảo file này tồn tại và chứa ShadcnCard, SectionHeader, etc.
import '../content_widgets.dart';
import 'bloc/admin_writing_bloc.dart';
import 'bloc/admin_writing_event.dart';
import 'bloc/admin_writing_state.dart';

class AdminWritingListView extends StatelessWidget {
  const AdminWritingListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminWritingBloc>()..add(const GetAdminWritingListEvent()),
      child: const _AdminWritingListBody(),
    );
  }
}

class _AdminWritingListBody extends StatefulWidget {
  const _AdminWritingListBody();

  @override
  State<_AdminWritingListBody> createState() => _AdminWritingListBodyState();
}

class _AdminWritingListBodyState extends State<_AdminWritingListBody> {
  final TextEditingController _searchCtrl = TextEditingController();

  void _openEditor(BuildContext context, String? id) async {
    await context.pushNamed(
      'ContentEditorRoute',
      pathParameters: {'type': 'writing'},
      extra: id,
    );
    if (mounted) {
      context.read<AdminWritingBloc>().add(const GetAdminWritingListEvent());
    }
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa chủ đề này? Dữ liệu bài làm của học viên liên quan cũng có thể bị ảnh hưởng."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminWritingBloc>().add(DeleteWritingTopicEvent(id));
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const kBgPage = Color(0xFFF9FAFB);
    const kWhite = Colors.white;
    const kTextMain = Color(0xFF09090B);
    const kTextMuted = Color(0xFF71717A);
    const kBorder = Color(0xFFE4E4E7);

    return Scaffold(
      backgroundColor: kBgPage,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextMain),
          onPressed: () => context.pop(),
        ),
        title: const Text('Writing Topics Management',
            style: TextStyle(color: kTextMain, fontWeight: FontWeight.w700, fontSize: 16)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: kBorder, height: 1)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline, color: kTextMain),
              tooltip: 'Thêm chủ đề mới',
              onPressed: () => _openEditor(context, null),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: kWhite,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorder),
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm chủ đề...',
                  prefixIcon: Icon(Icons.search, size: 18, color: kTextMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (val) {},
              ),
            ),
          ),

          // List Items
          Expanded(
            child: BlocBuilder<AdminWritingBloc, AdminWritingState>(
              builder: (context, state) {
                if (state.status == AdminWritingStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.topics.isEmpty) {
                  return const Center(child: Text("Chưa có chủ đề nào.", style: TextStyle(color: kTextMuted)));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.topics.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final topic = state.topics[index];
                    return _buildTopicItem(context, topic, kTextMain, kTextMuted, kBorder);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicItem(BuildContext context, WritingTopicEntity topic, Color kTextMain, Color kTextMuted, Color kBorder) {
    // FIX: Xử lý null safety cho aiConfig
    final level = topic.aiConfig?.level ?? 'Unknown';
    final taskCount = topic.aiConfig?.taskTypes?.length ?? 0;

    return ShadcnCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      onTap: () => _openEditor(context, topic.id),
      child: Row(
        children: [
          // Status Indicator
          Container(
            width: 4, height: 40,
            decoration: BoxDecoration(
              color: topic.isActive ? Colors.green : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.name,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: topic.isActive ? kTextMain : kTextMuted,
                      decoration: topic.isActive ? null : TextDecoration.lineThrough
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    _SmallBadge(text: level, color: Colors.blue.shade50, textColor: Colors.blue.shade700),
                    _SmallBadge(text: "$taskCount task types", color: Colors.purple.shade50, textColor: Colors.purple.shade700),
                  ],
                )
              ],
            ),
          ),

          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${topic.stats?.submissionsCount ?? 0}", style: TextStyle(fontWeight: FontWeight.bold, color: kTextMain)),
              Text("bài nộp", style: TextStyle(fontSize: 11, color: kTextMuted)),
            ],
          ),
          const SizedBox(width: 16),

          // Delete Btn
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _confirmDelete(context, topic.id),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  const _SmallBadge({required this.text, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor)),
    );
  }
}