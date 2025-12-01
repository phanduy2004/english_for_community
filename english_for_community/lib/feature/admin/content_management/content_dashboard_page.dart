import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'content_widgets.dart';
// ❌ XÓA import 'content_list_page.dart'; // KHÔNG DÙNG NỮA

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
      body: Padding(
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
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  _SkillCard(
                    title: 'Writing',
                    count: 15,
                    color: const Color(0xFFEF4444),
                    icon: Icons.edit_note,
                    onTap: () => _navToList(context, 'writing'),
                  ),
                  _SkillCard(
                    title: 'Speaking',
                    count: 8,
                    color: const Color(0xFF3B82F6),
                    icon: Icons.mic_none,
                    onTap: () => _navToList(context, 'speaking'),
                  ),
                  _SkillCard(
                    title: 'Reading',
                    count: 5,
                    color: const Color(0xFFF59E0B),
                    icon: Icons.menu_book,
                    onTap: () => _navToList(context, 'reading'),
                  ),
                  _SkillCard(
                    title: 'Listening',
                    count: 12,
                    color: const Color(0xFF8B5CF6),
                    icon: Icons.headphones,
                    onTap: () => _navToList(context, 'listening'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _navToList(BuildContext context, String skillType) {
    // 👇 Dùng tên route mới (ContentListViewRoute)
    context.pushNamed('ContentListViewRoute', pathParameters: {'type': skillType});
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kTextMain)),
              Text('$count topics',
                  style: const TextStyle(fontSize: 13, color: kTextMuted)),
            ],
          )
        ],
      ),
    );
  }
}