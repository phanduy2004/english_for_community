import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/entity/listening_comp_entity.dart';
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

Widget _buildListeningCompTable(
  BuildContext context,
  List<ListeningCompEntity> items, {
  required void Function(String id) onOpen,
  required void Function(String id) onDelete,
}) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: WebDataTable(
        columns: [
          WebTableColumn(label: l10n.adminTableContent, flex: 4),
          WebTableColumn(label: l10n.adminTableDifficulty, width: 120),
          WebTableColumn(label: l10n.adminTableDuration, width: 90, align: Alignment.centerRight, headAlign: Alignment.centerRight),
          WebTableColumn(label: l10n.adminTableSubmissions, width: 110, align: Alignment.centerRight, headAlign: Alignment.centerRight),
          WebTableColumn(label: l10n.adminTableStatus, width: 120),
          WebTableColumn(label: '', width: 56, align: Alignment.center, headAlign: Alignment.center),
        ],
        rowCount: items.length,
        decoration: AdminWebUi.panelDecoration(),
        headStyle: AdminWebUi.webTableHead(context),
        scrollable: true,
        onRowTap: (row) => () => onOpen(items[row].id),
        cellBuilder: (context, row, column) {
          final item = items[row];
          return switch (column) {
            0 => Row(children: [
                const Icon(Icons.quiz_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.s2),
                Expanded(child: _tableText(item.title, weight: FontWeight.w600)),
              ]),
            1 => _tableText(item.difficulty.toUpperCase()),
            2 => _tableText('${item.minutesToComplete} min'),
            3 => _tableText('${item.attemptsCount}'),
            4 => StatusBadge(text: item.adminStatus, color: item.adminStatus.toLowerCase() == 'published' ? AppColors.success : AppColors.textSecondary),
            5 => _contentMenu(
                onEdit: () => onOpen(item.id),
                onDelete: () => onDelete(item.id),
              ),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
}

Widget _contentMenu({required VoidCallback onEdit, required VoidCallback onDelete}) => PopupMenuButton<String>(
        tooltip: 'Content actions',
        icon: const Icon(Icons.more_horiz, size: 20),
        onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
          PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppColors.danger), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.danger))])),
        ],
      );

Widget _tableText(String value, {FontWeight? weight}) => Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, fontWeight: weight, color: AppColors.textPrimary, fontFeatures: const [FontFeature.tabularFigures()]),
      );

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
                                if (!mounted || !ctx.mounted || !context.mounted) return;
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
                    return AdminSkeleton.page(AdminSkeleton.table(rows: 6));
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
                    child: _buildListeningCompTable(
                      context,
                      state.listenings,
                      onOpen: (id) => _openEditor(context, id),
                      onDelete: (id) => _confirmDelete(context, id),
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

@Deprecated('The listening comprehension list uses WebDataTable.')
class ListeningCompLegacyMetaBadge extends StatelessWidget {
  const ListeningCompLegacyMetaBadge({
    super.key,
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



