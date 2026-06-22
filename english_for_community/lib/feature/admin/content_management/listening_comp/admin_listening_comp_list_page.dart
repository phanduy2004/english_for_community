import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/admin/layout/admin_skeleton.dart';
import 'package:english_for_community/feature/admin/layout/admin_widgets.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import '../../../../../core/datasource/admin_remote_datasource.dart';
import '../../../../../core/get_it/get_it.dart';
import '../content_widgets.dart';

import 'bloc/admin_listening_comp_bloc.dart';
import 'bloc/admin_listening_comp_event.dart';
import 'bloc/admin_listening_comp_state.dart';

// 🔥 Đã đổi tên Class thành Page cho đồng bộ
class AdminListeningCompListPage extends StatefulWidget {
  const AdminListeningCompListPage({super.key});

  @override
  State<AdminListeningCompListPage> createState() => _AdminListeningCompListPageState();
}

class _AdminListeningCompListPageState extends State<AdminListeningCompListPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminListeningCompBloc>()..add(GetAdminListeningCompListEvent(limit: kAdminDefaultRowsPerPage, page: 1)),
      child: const _AdminListeningCompListBody(),
    );
  }
}

class _AdminListeningCompListBody extends StatefulWidget {
  const _AdminListeningCompListBody();

  @override
  State<_AdminListeningCompListBody> createState() => _AdminListeningCompListBodyState();
}

class _AdminListeningCompListBodyState extends State<_AdminListeningCompListBody> {
  final AdminRemoteDatasource _adminRemote = getIt<AdminRemoteDatasource>();
  int _page = 1;
  int _rowsPerPage = kAdminDefaultRowsPerPage;

  void _fetchData() {
    context.read<AdminListeningCompBloc>().add(
      GetAdminListeningCompListEvent(limit: _rowsPerPage, page: _page),
    );
  }

  void _openEditor(BuildContext context, String? id) async {
    await context.pushNamed(
      'ContentEditorRoute',
      pathParameters: {'type': 'listening-comp'},
      extra: id,
    );

    if (mounted) {
      _fetchData();
    }
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text("Delete listening quiz?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          "This will remove all questions and explanations in this quiz.",
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        actions: [
          OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel")
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminListeningCompBloc>().add(DeleteListeningCompEvent(id));
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _openDeletedListeningCompSheet() async {
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
                    const Text('Deleted Listening Quizzes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _adminRemote.getDeletedListeningComprehensions(),
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
                                await _adminRemote.restoreListeningComprehension(id);
                                if (!mounted) return;
                                Navigator.pop(ctx);
                                _fetchData();
                                AppCornerToast.show(context, 'Listening quiz restored');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPage,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kTextMain),
            onPressed: () => context.pop()
        ),
        title: const Text(
            'Listening Comprehension',
            style: TextStyle(color: kTextMain, fontWeight: FontWeight.w700, fontSize: 16)
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: kBorder, height: 1)
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: IconButton(
              icon: const Icon(Icons.restore_from_trash_outlined, color: kTextMain),
              tooltip: 'Trash',
              onPressed: _openDeletedListeningCompSheet,
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
              child: BlocConsumer<AdminListeningCompBloc, AdminListeningCompState>(
                listener: (context, state) {
                  if (state.status == AdminListeningCompStatus.failure) {
                    AppCornerToast.show(context, state.errorMessage ?? 'Có lỗi xảy ra!', error: true);
                  }
                },
                builder: (context, state) {
                  if (state.status == AdminListeningCompStatus.loading && state.listenings.isEmpty) {
                    return AdminSkeleton.page(AdminSkeleton.cardList());
                  }

                  if (state.listenings.isEmpty) {
                    return Center(
                      child: AdminEmptyCard(
                        message: 'Chưa có bài tập trắc nghiệm nào.',
                        icon: Icons.quiz_outlined,
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
                        return ShadcnCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          onTap: () => _openEditor(context, item.id),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.infoBg,
                                  borderRadius: BorderRadius.circular(AppRadius.input),
                                  border: Border.all(color: AppColors.outline),
                                ),
                                child: const Icon(Icons.quiz, color: AppColors.info),
                              ),
                              const SizedBox(width: 16),
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
                                      '${item.difficulty.toUpperCase()} • ${item.minutesToComplete} Min',
                                      style: const TextStyle(fontSize: 12, color: kTextMuted),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _confirmDelete(context, item.id),
                              ),
                              const Icon(Icons.chevron_right, color: kTextMuted, size: 18),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            BlocBuilder<AdminListeningCompBloc, AdminListeningCompState>(
              builder: (context, state) {
                if (state.totalPages <= 1 && state.listenings.length <= _rowsPerPage) {
                  return const SizedBox.shrink();
                }
                final totalRows = state.currentPage >= state.totalPages
                    ? (state.totalPages - 1) * _rowsPerPage + state.listenings.length
                    : state.totalPages * _rowsPerPage;
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  child: AdminPaginationBar(
                    page: state.currentPage,
                    totalPages: state.totalPages.clamp(1, 9999),
                    totalRows: totalRows,
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



