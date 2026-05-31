import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/datasource/admin_remote_datasource.dart';
import '../../../../../core/get_it/get_it.dart';
import '../../../../../core/ui/widget/app_corner_toast.dart';
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text("Delete speaking set?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          "This action cannot be undone.",
          style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminSpeakingBloc>().add(DeleteSpeakingEvent(id));
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _openDeletedSpeakingSheet(BuildContext context) async {
    final adminRemote = getIt<AdminRemoteDatasource>();
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
                    const Text('Deleted Speaking Sets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: adminRemote.getDeletedSpeakingSets(),
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
                            subtitle: Text('${item['level'] ?? ''} • ${item['mode'] ?? ''}'),
                            trailing: OutlinedButton(
                              onPressed: () async {
                                await adminRemote.restoreSpeakingSet(id);
                                if (!context.mounted) return;
                                Navigator.pop(ctx);
                                context.read<AdminSpeakingBloc>().add(GetAdminSpeakingListEvent(page: 1, limit: 9999));
                                AppCornerToast.show(context, 'Speaking set restored');
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
        title: const Text('Speaking Management', style: TextStyle(color: kTextMain, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: kWhite, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextMain), onPressed: () => context.pop()),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: kBorder, height: 1)),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore_from_trash_outlined, color: kTextMain),
            tooltip: 'Trash',
            onPressed: () => _openDeletedSpeakingSheet(context),
          ),
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
                          Text("${item.level} • ${item.mode}",
                              style: const TextStyle(fontSize: 12, color: kTextMuted)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _MetaBadge(
                                text: '${item.totalSentences} sentences',
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