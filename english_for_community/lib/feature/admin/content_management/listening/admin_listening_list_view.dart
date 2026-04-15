import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Import Entity & GetIt
import '../../../../../core/datasource/admin_remote_datasource.dart';
import '../../../../../core/get_it/get_it.dart';
import '../../../../core/entity/listening_entity.dart';
import '../content_widgets.dart';

// Import Bloc
import 'bloc/admin_listening_bloc.dart';
import 'bloc/admin_listening_event.dart';
import 'bloc/admin_listening_state.dart';

class AdminListeningListView extends StatefulWidget {
  // Màn hình này được gọi từ Router, nó cần tự cung cấp Bloc cho chính nó
  const AdminListeningListView({super.key});

  @override
  State<AdminListeningListView> createState() => _AdminListeningListViewState();
}

class _AdminListeningListViewState extends State<AdminListeningListView> {
  @override
  Widget build(BuildContext context) {
    // Bọc BlocProvider ở cấp cao nhất của widget build
    return BlocProvider(
      create: (_) => getIt<AdminListeningBloc>()..add(const GetAdminListeningListEvent(limit: 9999, page: 1)),
      child: const _AdminListeningListBody(),
    );
  }
}

class _AdminListeningListBody extends StatefulWidget {
  const _AdminListeningListBody();

  @override
  State<_AdminListeningListBody> createState() => _AdminListeningListBodyState();
}

class _AdminListeningListBodyState extends State<_AdminListeningListBody> {
  final AdminRemoteDatasource _adminRemote = getIt<AdminRemoteDatasource>();

  void _openEditor(BuildContext context, String? id) async {
    print("DEBUG LIST VIEW - Opening Editor for ID: $id"); // 👇 Log kiểm tra

    await context.pushNamed(
      'ContentEditorRoute',
      pathParameters: {'type': 'listening'}, // Bắt buộc phải có cái này để router hiểu :type là gì
      extra: id,
    );

    if (mounted) {
      // ✅ Refresh list TẠI ĐÂY là an toàn nhất
      context.read<AdminListeningBloc>().add(
        const GetAdminListeningListEvent(limit: 9999, page: 1),
      );
    }
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
        title: const Text(
          'Listening Management',
          style: TextStyle(color: kTextMain, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: kBorder, height: 1),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: IconButton(
              icon: const Icon(Icons.restore_from_trash_outlined, color: kTextMain),
              tooltip: 'Trash',
              onPressed: _openDeletedListeningsSheet,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline, color: kTextMain),
              tooltip: 'Thêm mới',
              onPressed: () => _openEditor(context, null),
            ),
          )
        ],
      ),
      body: BlocBuilder<AdminListeningBloc, AdminListeningState>(
        builder: (context, state) {
          if (state.status == AdminListeningStatus.loading && state.listenings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.listenings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.headphones, size: 64, color: kTextMuted),
                  const SizedBox(height: 16),
                  const Text("Chưa có bài nghe nào.", style: TextStyle(color: kTextMuted)),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Tạo bài đầu tiên"),
                    onPressed: () => _openEditor(context, null),
                  )
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AdminListeningBloc>().add(
                const GetAdminListeningListEvent(limit: 9999, page: 1),
              );
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.listenings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = state.listenings[index];
                return _buildListItem(context, item);
              },
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text("Delete listening lesson?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          "This will remove this listening lesson and all related cues.",
          style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx); // Đóng dialog
              // Gọi Bloc Xóa
              context.read<AdminListeningBloc>().add(DeleteListeningEvent(id));
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _openDeletedListeningsSheet() async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
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
                    const Icon(Icons.restore_from_trash_outlined, color: Color(0xFF475569)),
                    const SizedBox(width: 8),
                    const Text('Deleted Listening Lessons', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _adminRemote.getDeletedListenings(),
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
                          final title = (item['title'] ?? 'Untitled').toString();
                          return ListTile(
                            title: Text(title),
                            subtitle: Text((item['code'] ?? '').toString()),
                            trailing: OutlinedButton(
                              onPressed: () async {
                                await _adminRemote.restoreListening(id);
                                if (!mounted) return;
                                Navigator.pop(ctx);
                                context.read<AdminListeningBloc>().add(
                                  const GetAdminListeningListEvent(limit: 9999, page: 1),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Listening restored')),
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
                  child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 2. Sửa widget Item
  Widget _buildListItem(BuildContext context, ListeningEntity item) {
    return ShadcnCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => _openEditor(context, item.id),
      child: Row(
        children: [
          // Icon Thumbnail
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: const Icon(Icons.graphic_eq, color: Colors.blue),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextMain),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "Code: ${item.code ?? 'N/A'}",
                  style: const TextStyle(fontSize: 12, color: kTextMuted),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _MetaBadge(
                      text: '${item.totalCues ?? 0} cues',
                      color: Colors.purple.shade50,
                      textColor: Colors.purple.shade700,
                    ),
                    _MetaBadge(
                      text: '${item.attemptsCount} submissions',
                      color: Colors.orange.shade50,
                      textColor: Colors.orange.shade800,
                    ),
                    _MetaBadge(
                      text: item.adminStatus,
                      color: Colors.green.shade50,
                      textColor: Colors.green.shade700,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 👇 NÚT XÓA
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(context, item.id),
          ),

          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: kTextMuted, size: 20),
        ],
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({
    required this.text,
    required this.color,
    required this.textColor,
  });
  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}