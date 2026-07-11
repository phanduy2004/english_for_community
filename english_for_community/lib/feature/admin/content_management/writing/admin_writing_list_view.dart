import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/widget/web_data_table.dart';
import 'package:english_for_community/feature/admin/layout/admin_skeleton.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:english_for_community/feature/admin/layout/admin_widgets.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
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
  final AdminRemoteDatasource _adminRemote = getIt<AdminRemoteDatasource>();
  int _page = 1;
  int _rowsPerPage = kAdminDefaultRowsPerPage;

  void _openEditor(BuildContext context, String? id) async {
    await context.pushNamed(
      'ContentEditorRoute',
      pathParameters: {'type': 'writing'},
      extra: id,
    );
    if (context.mounted) {
      context.read<AdminWritingBloc>().add(const GetAdminWritingListEvent());
    }
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text("Delete writing topic?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          "This action can impact related learner submissions. You should only delete if the topic is invalid or duplicated.",
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminWritingBloc>().add(DeleteWritingTopicEvent(id));
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _openDeletedTopicsSheet() async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
          side: const BorderSide(color: AppColors.outline),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 560),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.restore_from_trash_outlined, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    const Text('Deleted Writing Topics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const Text(
                  'Restore deleted topics back to active content.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _adminRemote.getDeletedWritingTopics(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return AdminSkeleton.page(AdminSkeleton.cardList());
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
                                if (!mounted || !ctx.mounted || !context.mounted) return;
                                Navigator.pop(ctx);
                                context.read<AdminWritingBloc>().add(const GetAdminWritingListEvent());
                                AppCornerToast.show(context, 'Topic restored');
                              },
                              child: const Text('Restore'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Align(alignment: Alignment.centerRight, child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))),
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
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
          title: Row(
            children: [
              const Icon(Icons.verified_outlined, color: Colors.indigo, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Approval Workflow - ${topic.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
            ],
          ),
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
            OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('Apply'),
            ),
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
    AppCornerToast.show(context, 'Workflow updated');
  }

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: BlocBuilder<AdminWritingBloc, AdminWritingState>(
              builder: (context, state) {
                if (state.status == AdminWritingStatus.loading) {
                  return AdminSkeleton.page(AdminSkeleton.table(rows: 6));
                }

                if (state.topics.isEmpty) {
                  return Center(
                    child: AdminEmptyCard(
                      message: 'Chưa có chủ đề nào.',
                      icon: Icons.edit_note_outlined,
                      actionLabel: 'Tạo chủ đề đầu tiên',
                      onAction: () => _openEditor(context, null),
                    ),
                  );
                }

                final pageItems = state.topics
                    .skip((_page - 1) * _rowsPerPage)
                    .take(_rowsPerPage)
                    .toList();

                return _buildTopicsTable(context, pageItems);
              },
            ),
          ),
          BlocBuilder<AdminWritingBloc, AdminWritingState>(
            builder: (context, state) {
              if (state.topics.length <= _rowsPerPage) {
                return const SizedBox.shrink();
              }
              final totalPages = (state.topics.length / _rowsPerPage).ceil().clamp(1, 9999);
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: AdminPaginationBar(
                  page: _page,
                  totalPages: totalPages,
                  totalRows: state.topics.length,
                  rowsPerPage: _rowsPerPage,
                  onRowsPerPageChanged: (v) => setState(() {
                    _rowsPerPage = v;
                    _page = 1;
                  }),
                  onPageChanged: (p) => setState(() => _page = p),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsTable(BuildContext context, List<WritingTopicEntity> topics) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: WebDataTable(
        columns: [
          WebTableColumn(label: l10n.adminTableContent, flex: 4),
          WebTableColumn(label: l10n.adminTableLevel, width: 110),
          WebTableColumn(label: l10n.adminTableTasks, width: 80, align: Alignment.centerRight, headAlign: Alignment.centerRight),
          WebTableColumn(label: l10n.adminTableSubmissions, width: 110, align: Alignment.centerRight, headAlign: Alignment.centerRight),
          WebTableColumn(label: l10n.adminTableStatus, width: 120),
          WebTableColumn(label: '', width: 56, align: Alignment.center, headAlign: Alignment.center),
        ],
        rowCount: topics.length,
        decoration: AdminWebUi.panelDecoration(),
        headStyle: AdminWebUi.webTableHead(context),
        scrollable: true,
        onRowTap: (row) => () => _openEditor(context, topics[row].id),
        cellBuilder: (context, row, column) {
          final topic = topics[row];
          final taskCount = topic.aiConfig?.taskTypes?.length ?? 0;
          return switch (column) {
            0 => Row(children: [
                const Icon(Icons.edit_note_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.s2),
                Expanded(child: _tableText(topic.name, weight: FontWeight.w600)),
              ]),
            1 => _tableText(topic.aiConfig?.level ?? 'Unknown'),
            2 => _tableText('$taskCount'),
            3 => _tableText('${topic.stats?.submissionsCount ?? 0}'),
            4 => StatusBadge(text: topic.approvalStatus, color: _approvalColor(topic.approvalStatus)),
            5 => _topicMenu(
                onEdit: () => _openEditor(context, topic.id),
                onApprove: () => _showApprovalAction(topic),
                onDelete: () => _confirmDelete(context, topic.id),
              ),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }

  Widget _topicMenu({required VoidCallback onEdit, required VoidCallback onApprove, required VoidCallback onDelete}) => PopupMenuButton<String>(
        tooltip: 'Content actions',
        icon: const Icon(Icons.more_horiz, size: 20),
        onSelected: (value) => switch (value) { 'edit' => onEdit(), 'approve' => onApprove(), _ => onDelete() },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
          PopupMenuItem(value: 'approve', child: Row(children: [Icon(Icons.verified_outlined, size: 18), SizedBox(width: 8), Text('Approval')])),
          PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppColors.danger), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.danger))])),
        ],
      );

  Color _approvalColor(String status) => switch (status.toLowerCase()) {
        'approved' || 'published' => AppColors.success,
        'rejected' => AppColors.danger,
        _ => AppColors.warning,
      };

  Widget _tableText(String value, {FontWeight? weight}) => Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, fontWeight: weight, color: AppColors.textPrimary, fontFeatures: const [FontFeature.tabularFigures()]),
      );

  @Deprecated('The writing list uses WebDataTable.')
  Widget buildLegacyTopicItem(BuildContext context, WritingTopicEntity topic, Color kTextMain, Color kTextMuted, Color kBorder) {
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
              borderRadius: BorderRadius.circular(AppRadius.xs),
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
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.xs)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor)),
    );
  }
}


