import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/admin/layout/admin_skeleton.dart';
import 'package:english_for_community/feature/admin/layout/admin_widgets.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';

// 👇 Import GetIt để lấy Dependency (Repository/Bloc)
import '../../../../../core/datasource/admin_remote_datasource.dart';
import '../../../../../core/get_it/get_it.dart';
import '../../../../../core/entity/reading/reading_entity.dart';
import '../content_widgets.dart';
import 'bloc/admin_reading_bloc.dart';
import 'bloc/admin_reading_event.dart';
import 'bloc/admin_reading_state.dart';

// ==========================================
// 1. CLASS PUBLIC (Dùng để gọi trong Router)
// Nhiệm vụ: Cung cấp Bloc (BlocProvider)
// ==========================================
class AdminReadingListView extends StatelessWidget {
  final String skillType;

  const AdminReadingListView({super.key, required this.skillType});

  @override
  Widget build(BuildContext context) {
    // 👇 WRAP BẰNG BLOC PROVIDER TẠI ĐÂY
    return BlocProvider(
      // Sử dụng getIt để tạo Bloc mới mỗi khi vào trang này
      create: (_) => getIt<AdminReadingBloc>(),
      child: _AdminReadingListBody(skillType: skillType),
    );
  }
}

// ==========================================
// 2. CLASS PRIVATE (Logic UI & State)
// Nhiệm vụ: Hiển thị UI, Fetch data
// ==========================================
class _AdminReadingListBody extends StatefulWidget {
  final String skillType;

  const _AdminReadingListBody({required this.skillType});

  @override
  State<_AdminReadingListBody> createState() => _AdminReadingListBodyState();
}

class _AdminReadingListBodyState extends State<_AdminReadingListBody> {
  final AdminRemoteDatasource _adminRemote = getIt<AdminRemoteDatasource>();
  int _page = 1;
  int _rowsPerPage = kAdminDefaultRowsPerPage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    context.read<AdminReadingBloc>().add(
      GetAdminReadingListEvent(limit: _rowsPerPage, page: _page),
    );
  }

  void _openEditor(BuildContext context, String? id) async {
    await context.pushNamed(
      'ContentEditorRoute',
      pathParameters: {'type': widget.skillType},
      extra: id,
    );

    if (mounted) {
      context.read<AdminReadingBloc>().add(
        GetAdminReadingListEvent(limit: _rowsPerPage, page: _page),
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
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextMain),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '${widget.skillType[0].toUpperCase()}${widget.skillType.substring(
              1)} Management',
          style: const TextStyle(
              color: kTextMain, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: kBorder, height: 1)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: IconButton(
              icon: const Icon(Icons.restore_from_trash_outlined, color: kTextMain),
              tooltip: 'Trash',
              onPressed: _openDeletedReadingsSheet,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline, color: kTextMain),
              tooltip: 'Thêm bài mới',
              onPressed: () => _openEditor(context, null),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<AdminReadingBloc, AdminReadingState>(
              builder: (context, state) {
                if (state.status == AdminReadingStatus.loading &&
                    state.readings.isEmpty) {
                  return AdminSkeleton.page(AdminSkeleton.cardList());
                }

                if (state.status == AdminReadingStatus.failure &&
                    state.readings.isEmpty) {
                  return Center(
                      child: Text("Lỗi: ${state.errorMessage ?? 'Unknown'}"));
                }

                if (state.readings.isEmpty) {
                  return Center(
                    child: AdminEmptyCard(
                      message: 'Chưa có bài đọc nào.',
                      icon: Icons.menu_book_outlined,
                      actionLabel: 'Tạo bài đầu tiên',
                      onAction: () => _openEditor(context, null),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _fetchData();
                  },
                  child: _buildListItems(context, state.readings),
                );
              },
            ),
          ),
          BlocBuilder<AdminReadingBloc, AdminReadingState>(
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
            Text("Delete reading lesson?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          "This action cannot be undone.",
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx), // Đóng dialog
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx); // Đóng dialog trước
              // Gọi Event Xóa
              context.read<AdminReadingBloc>().add(DeleteReadingEvent(id));
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _openDeletedReadingsSheet() async {
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
                    const Text('Deleted Reading Lessons', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _adminRemote.getDeletedReadings(),
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
                            subtitle: Text((item['difficulty'] ?? '').toString()),
                            trailing: OutlinedButton(
                              onPressed: () async {
                                await _adminRemote.restoreReading(id);
                                if (!mounted) return;
                                Navigator.pop(ctx);
                                _fetchData();
                                AppCornerToast.show(context, 'Reading restored');
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

  Widget _buildListItems(BuildContext context, List<ReadingEntity> readings) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: readings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final reading = readings[index];
        return ShadcnCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Chỉnh padding
          onTap: () => _openEditor(context, reading.id),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    image: (reading.imageUrl != null && reading.imageUrl!.startsWith('http'))
                        ? DecorationImage(image: NetworkImage(reading.imageUrl!), fit: BoxFit.cover)
                        : null
                ),
                child: (reading.imageUrl == null || !reading.imageUrl!.startsWith('http'))
                    ? Center(child: Text(reading.title.isNotEmpty ? reading.title[0] : "?", style: const TextStyle(fontWeight: FontWeight.bold, color: kTextMuted)))
                    : null,
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reading.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextMain),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _MetaBadge(
                          text: reading.difficulty?.name.toUpperCase() ?? 'UNKNOWN',
                          color: Colors.blue.shade50,
                          textColor: Colors.blue.shade700,
                        ),
                        _MetaBadge(
                          text: '${reading.minutesToRead} mins',
                          color: Colors.purple.shade50,
                          textColor: Colors.purple.shade700,
                        ),
                        _MetaBadge(
                          text: '${reading.attemptsCount} submissions',
                          color: Colors.orange.shade50,
                          textColor: Colors.orange.shade800,
                        ),
                        _MetaBadge(
                          text: reading.adminStatus,
                          color: Colors.green.shade50,
                          textColor: Colors.green.shade700,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 👇 NÚT XÓA (Thùng rác)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  // Dừng sự kiện onTap của Card để tránh mở Editor
                  // (Tuy nhiên IconButton đã tự capture touch event nên ổn)
                  _confirmDelete(context, reading.id);
                },
              ),

              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: kTextMuted, size: 20),
            ],
          ),
        );
      },
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


