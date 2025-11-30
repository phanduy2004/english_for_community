import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/get_it/get_it.dart';
import '../content_widgets.dart';
import 'bloc/admin_speaking_bloc.dart';
import 'bloc/admin_speaking_event.dart';
import 'bloc/admin_speaking_state.dart';

class AdminSpeakingListView extends StatelessWidget {
  const AdminSpeakingListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminSpeakingBloc>()..add(GetAdminSpeakingListEvent(page: 1, limit: 9999)),
      child: const _SpeakingListBody(),
    );
  }
}

class _SpeakingListBody extends StatelessWidget {
  const _SpeakingListBody();

  void _openEditor(BuildContext context, String? id) async {
    await context.pushNamed(
      'ContentEditorRoute',
      pathParameters: {'type': 'speaking'},
      extra: id,
    );
    if (context.mounted) {
      context.read<AdminSpeakingBloc>().add(GetAdminSpeakingListEvent(page: 1, limit: 9999));
    }
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Set"),
        content: const Text("Are you sure you want to delete this speaking set?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminSpeakingBloc>().add(DeleteSpeakingEvent(id));
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
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
        title: const Text('Speaking Management', style: TextStyle(color: kTextMain, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: kWhite, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextMain), onPressed: () => context.pop()),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: kBorder, height: 1)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: kTextMain),
            onPressed: () => _openEditor(context, null),
          )
        ],
      ),
      body: BlocBuilder<AdminSpeakingBloc, AdminSpeakingState>(
        builder: (context, state) {
          if (state.status == AdminSpeakingStatus.loading && state.speakingSets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == AdminSpeakingStatus.failure && state.speakingSets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 8),
                  Text("Lỗi tải dữ liệu:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(state.errorMessage ?? "Unknown error", textAlign: TextAlign.center),
                  ),
                  OutlinedButton(
                    onPressed: () => context.read<AdminSpeakingBloc>().add(GetAdminSpeakingListEvent(page: 1, limit: 9999)),
                    child: const Text("Thử lại"),
                  )
                ],
              ),
            );
          }

          if (state.speakingSets.isEmpty) {
            return const Center(child: Text("Chưa có bài nói nào.", style: TextStyle(color: kTextMuted)));
          }
          if (state.speakingSets.isEmpty) {
            return const Center(child: Text("No speaking sets found.", style: TextStyle(color: kTextMuted)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.speakingSets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = state.speakingSets[index];
              return ShadcnCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                onTap: () => _openEditor(context, item.id),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFDBEAFE))),
                      child: const Icon(Icons.mic, color: Colors.blue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTextMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          // Hiển thị Level và Mode
                          Text("${item.level} • ${item.mode} • ${item.totalSentences} sentences",
                              style: const TextStyle(fontSize: 12, color: kTextMuted)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmDelete(context, item.id)),
                    const Icon(Icons.chevron_right, color: kTextMuted, size: 18),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}