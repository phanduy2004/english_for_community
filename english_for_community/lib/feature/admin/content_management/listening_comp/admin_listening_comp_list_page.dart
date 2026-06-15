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
      create: (_) => getIt<AdminListeningCompBloc>()..add(const GetAdminListeningCompListEvent(limit: 9999, page: 1)),
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

  void _openEditor(BuildContext context, String? id) async {
    await context.pushNamed(
      'ContentEditorRoute',
      pathParameters: {'type': 'listening-comp'},
      extra: id,
    );

    if (mounted) {
      context.read<AdminListeningCompBloc>().add(const GetAdminListeningCompListEvent(limit: 9999, page: 1));
    }
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text("Delete listening quiz?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          "This will remove all questions and explanations in this quiz.",
          style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
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
                      if (!snapshot.hasData) return const Center(child: AppLoadingIndicator.center());
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
                                context.read<AdminListeningCompBloc>().add(const GetAdminListeningCompListEvent(limit: 9999, page: 1));
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
        body: BlocConsumer<AdminListeningCompBloc, AdminListeningCompState>(
          listener: (context, state) {
            if (state.status == AdminListeningCompStatus.failure) {
              AppCornerToast.show(context, state.errorMessage ?? "Có lỗi xảy ra!", error: true);
            }
          },
          builder: (context, state) {
            if (state.status == AdminListeningCompStatus.loading && state.listenings.isEmpty) {
              return const Center(child: AppLoadingIndicator.center());
            }

            if (state.listenings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.quiz_outlined, size: 64, color: kTextMuted),
                    const SizedBox(height: 16),
                    const Text("Chưa có bài tập trắc nghiệm nào.", style: TextStyle(color: kTextMuted)),
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
                context.read<AdminListeningCompBloc>().add(const GetAdminListeningCompListEvent(limit: 9999, page: 1));
              },
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
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE9D5FF))
                          ),
                          child: const Icon(Icons.quiz, color: Color(0xFF9333EA)),
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
                                  overflow: TextOverflow.ellipsis
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  "${item.difficulty.toUpperCase()} • ${item.minutesToComplete} Min",
                                  style: const TextStyle(fontSize: 12, color: kTextMuted)
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  _MetaBadge(
                                    text: '${item.totalQuestions} questions',
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
                        IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _confirmDelete(context, item.id)
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: kTextMuted, size: 20),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        )
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