import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/get_it/get_it.dart';
import '../../../../core/datasource/admin_remote_datasource.dart';
import 'content_widgets.dart';

class ContentDashboardPage extends StatelessWidget {
  static const String routeName = 'ContentDashboardPage';
  static const String routePath = '/admin/content';

  const ContentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPage,
      appBar: AppBar(
        backgroundColor: kWhite,
        surfaceTintColor: Colors.transparent, // Fix màu ám khi scroll
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextMain),
          onPressed: () => context.pop(),
        ),
        title: const Text('Quản lý Nội dung',
            style: TextStyle(
                color: kTextMain, fontWeight: FontWeight.w700, fontSize: 16)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: kBorder, height: 1)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 900;
          final int crossAxisCount = isWide ? 4 : 2;
          final double childAspectRatio = isWide ? 1.1 : 1.3;

          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Chọn kỹ năng cần quản lý",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: kTextMain)),
                  const SizedBox(height: 6),
                  const Text("Quản lý bài tập, đề bài và tài nguyên học tập.",
                      style: TextStyle(fontSize: 14, color: kTextMuted)),

                  const SizedBox(height: 24),

                  Expanded(
                    child: FutureBuilder<Map<String, int>>(
                      future: getIt<AdminRemoteDatasource>().getContentSummary(),
                      builder: (context, snapshot) {
                        final counts = snapshot.data ??
                            const {
                              'writing': 0,
                              'speaking': 0,
                              'reading': 0,
                              'listening': 0,
                            };
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: childAspectRatio,
                          children: [
                            _SkillCard(
                              title: 'Writing',
                              count: counts['writing'] ?? 0,
                              color: const Color(0xFFEF4444),
                              icon: Icons.edit_note,
                              onTap: () => _navToList(context, 'writing'),
                            ),
                            _SkillCard(
                              title: 'Speaking',
                              count: counts['speaking'] ?? 0,
                              color: const Color(0xFF3B82F6),
                              icon: Icons.mic_none,
                              onTap: () => _navToList(context, 'speaking'),
                            ),
                            _SkillCard(
                              title: 'Reading',
                              count: counts['reading'] ?? 0,
                              color: const Color(0xFFF59E0B),
                              icon: Icons.menu_book,
                              onTap: () => _navToList(context, 'reading'),
                            ),
                            _SkillCard(
                              title: 'Listening',
                              count: counts['listening'] ?? 0,
                              color: const Color(0xFF8B5CF6),
                              icon: Icons.headphones,
                              onTap: () => _showListeningTypeDialog(context),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _navToList(BuildContext context, String skillType) {
    context.pushNamed('ContentListViewRoute', pathParameters: {'type': skillType});
  }

  // 🔥 HÀM MỚI: Hiển thị Dialog chọn dạng bài Listening
  void _showListeningTypeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: kWhite,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          titlePadding: const EdgeInsets.fromLTRB(20, 16, 14, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          title: Row(
            children: [
              const Icon(Icons.headphones_outlined, size: 20, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Listening Content Type',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kTextMain),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, size: 20),
                splashRadius: 18,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogOption(
                title: 'Dictation',
                subtitle: 'Nghe chép chính tả (Cues)',
                icon: Icons.edit_document,
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.pop(ctx); // Đóng dialog
                  _navToList(context, 'listening'); // Dùng luồng cũ cho Dictation
                },
              ),
              const SizedBox(height: 12),
              _buildDialogOption(
                title: 'Comprehension',
                subtitle: 'Nghe hiểu (Trắc nghiệm)',
                icon: Icons.quiz_outlined,
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.pop(ctx); // Đóng dialog
                  // Thay tên Route này thành Route bạn định nghĩa cho danh sách Comprehension
                  context.pushNamed('ContentListViewRoute', pathParameters: {'type': 'listening-comp'});                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔥 WIDGET MỚI: Giao diện cho từng lựa chọn trong Dialog
  Widget _buildDialogOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: kTextMain, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: kTextMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kTextMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
class _SkillCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _SkillCard(
      {required this.title,
        required this.count,
        required this.color,
        required this.icon,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ShadcnCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12), // Thêm khoảng cách nhỏ cho thoáng
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kTextMain)),
              const SizedBox(height: 4),
              Text('$count topics',
                  style: const TextStyle(fontSize: 13, color: kTextMuted)),
            ],
          )
        ],
      ),
    );
  }
}