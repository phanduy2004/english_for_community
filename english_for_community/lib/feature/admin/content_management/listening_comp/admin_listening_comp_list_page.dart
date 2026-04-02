import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/get_it/get_it.dart';
import '../../../../core/entity/listening_comp_entity.dart';
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
        title: const Text("Xóa Bài Nghe"),
        content: const Text("Bạn có chắc chắn muốn xóa bài trắc nghiệm này? Toàn bộ câu hỏi và giải thích sẽ bị xóa theo."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Hủy", style: TextStyle(color: kTextMuted))
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminListeningCompBloc>().add(DeleteListeningCompEvent(id));
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
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
            // Lắng nghe trạng thái lỗi để hiển thị SnackBar
            if (state.status == AdminListeningCompStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? "Có lỗi xảy ra!"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.status == AdminListeningCompStatus.loading && state.listenings.isEmpty) {
              return const Center(child: CircularProgressIndicator());
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
                                  "${item.totalQuestions} Questions • ${item.minutesToComplete} Min • ${item.difficulty.toUpperCase()}",
                                  style: const TextStyle(fontSize: 12, color: kTextMuted)
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