import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/get_it/get_it.dart';
import '../../../../../core/datasource/admin_remote_datasource.dart';
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
  final AdminRemoteDatasource _adminRemote = getIt<AdminRemoteDatasource>();

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

  Future<void> _openDeletedTopicsSheet() async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 560),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Deleted Writing Topics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _adminRemote.getDeletedWritingTopics(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final data = snapshot.data!;
                      if (data.isEmpty) return const Center(child: Text('Trash is empty'));
                      return ListView.separated(
                        itemCount: data.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final item = data[index];
                          final id = (item['_id'] ?? item['id'] ?? '').toString();
                          final name = (item['name'] ?? 'Untitled').toString();
                          return ListTile(
                            title: Text(name),
                            trailing: OutlinedButton(
                              onPressed: () async {
                                await _adminRemote.restoreWritingTopic(id);
                                if (!mounted) return;
                                Navigator.pop(ctx);
                                context.read<AdminWritingBloc>().add(const GetAdminWritingListEvent());
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Topic restored')),
                                );
                              },
                              child: const Text('Restore'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showApprovalAction(WritingTopicEntity topic) async {
    String selected = 'approved';
    final noteCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text('Approval Workflow - ${topic.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selected,
                decoration: const InputDecoration(
                  labelText: 'Action',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'submit', child: Text('Submit for approval')),
                  DropdownMenuItem(value: 'approved', child: Text('Approve / Publish')),
                  DropdownMenuItem(value: 'rejected', child: Text('Reject')),
                ],
                onChanged: (v) => setLocalState(() => selected = v ?? 'approved'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Optional note',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, selected), child: const Text('Apply')),
          ],
        ),
      ),
    );
    if (result == null) return;
    if (result == 'submit') {
      await _adminRemote.submitWritingTopicApproval(topic.id);
    } else {
      await _adminRemote.reviewWritingTopicApproval(
        topicId: topic.id,
        decision: result,
        reviewNote: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      );
    }
    if (!mounted) return;
    context.read<AdminWritingBloc>().add(const GetAdminWritingListEvent());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workflow updated')),
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
            padding: const EdgeInsets.only(right: 4.0),
            child: IconButton(
              icon: const Icon(Icons.restore_from_trash_outlined, color: kTextMain),
              tooltip: 'Trash',
              onPressed: _openDeletedTopicsSheet,
            ),
          ),
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
                    _SmallBadge(
                      text: topic.approvalStatus,
                      color: Colors.orange.shade50,
                      textColor: Colors.orange.shade800,
                    ),
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
            icon: const Icon(Icons.verified_outlined, color: Colors.indigo, size: 20),
            onPressed: () => _showApprovalAction(topic),
          ),
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