import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Import Entity & GetIt
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
        title: const Text("Delete Listening"),
        content: const Text("Are you sure you want to delete this listening lesson? All cues will be deleted too."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Đóng dialog
              // Gọi Bloc Xóa
              context.read<AdminListeningBloc>().add(DeleteListeningEvent(id));
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
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
                  "Code: ${item.code ?? 'N/A'} • ${item.totalCues ?? 0} Cues",
                  style: const TextStyle(fontSize: 12, color: kTextMuted),
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