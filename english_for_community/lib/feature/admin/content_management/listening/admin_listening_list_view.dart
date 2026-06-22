import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/admin/layout/admin_skeleton.dart';
import 'package:english_for_community/feature/admin/layout/admin_widgets.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';

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
      create: (_) => getIt<AdminListeningBloc>()..add(GetAdminListeningListEvent(limit: kAdminDefaultRowsPerPage, page: 1)),
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
  int _page = 1;
  int _rowsPerPage = kAdminDefaultRowsPerPage;

  void _fetchData() {
    context.read<AdminListeningBloc>().add(
      GetAdminListeningListEvent(limit: _rowsPerPage, page: _page),
    );
  }

  void _openEditor(BuildContext context, String? id) async {

    await context.pushNamed(
      'ContentEditorRoute',
      pathParameters: {'type': 'listening'}, // Bắt buộc phải có cái này để router hiểu :type là gì
      extra: id,
    );

    if (mounted) {
      _fetchData();
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
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<AdminListeningBloc, AdminListeningState>(
              builder: (context, state) {
                if (state.status == AdminListeningStatus.loading && state.listenings.isEmpty) {
                  return AdminSkeleton.page(AdminSkeleton.cardList());
                }

                if (state.listenings.isEmpty) {
                  return Center(
                    child: AdminEmptyCard(
                      message: 'Chưa có bài nghe nào.',
                      icon: Icons.headphones_outlined,
                      actionLabel: 'Tạo bài đầu tiên',
                      onAction: () => _openEditor(context, null),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _fetchData(),
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
          ),
          BlocBuilder<AdminListeningBloc, AdminListeningState>(
            builder: (context, state) {
              final p = state.pagination;
              if (p.totalPages <= 1 && p.totalItems <= _rowsPerPage) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: AdminPaginationBar(
                  page: p.currentPage,
                  totalPages: p.totalPages.clamp(1, 9999),
                  totalRows: p.totalItems,
                  rowsPerPage: _rowsPerPage,
                  onRowsPerPageChanged: (v) {
                    setState(() {
                      _rowsPerPage = v;
                      _page = 1;
                    });
                    _fetchData();
                  },
                  onPageChanged: (p) {
                    setState(() => _page = p);
                    _fetchData();
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
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
            Text("Delete listening lesson?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          "This will remove this listening lesson and all related cues.",
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
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
                      if (!snapshot.hasData) return AdminSkeleton.page(AdminSkeleton.cardList());
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
                                _fetchData();
                                AppCornerToast.show(context, 'Listening restored');
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
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(color: AppColors.infoBg),
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
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.xs)),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}



