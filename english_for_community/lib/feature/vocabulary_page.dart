import 'package:flutter/material.dart';

class VocabularyPage extends StatefulWidget {
  const VocabularyPage({super.key});
  static String routeName = 'VocabularyPage';
  static String routePath = '/vocabularyPage';

  @override
  State<VocabularyPage> createState() =>
      _VocabularyPageState();
}

class _VocabularyPageState extends State<VocabularyPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final sets = [
      _VocabSet(icon: Icons.restaurant, iconBg: const Color(0xFFF4F6FF), iconColor: const Color(0xFF6366F1),
          title: 'Food & Drinks', meta: '45 words • Beginner level', favorites: 8, progress: 0.85, pillColor: const Color(0xFF10B981)),
      _VocabSet(icon: Icons.school, iconBg: const Color(0xFFFEF3C7), iconColor: const Color(0xFFF59E0B),
          title: 'IELTS Academic', meta: '120 words • Advanced level', favorites: 23, progress: 0.62, pillColor: const Color(0xFFF59E0B)),
      _VocabSet(icon: Icons.business, iconBg: const Color(0xFFE0F2FE), iconColor: const Color(0xFF0EA5E9),
          title: 'Business English', meta: '80 words • Intermediate level', favorites: 15, progress: 0.00, pillColor: Colors.grey),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Vocabulary', style: text.headlineLarge),
        centerTitle: false, elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            // Daily review
            _Card(
              child: Row(
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Daily Review', style: text.headlineSmall),
                    const SizedBox(height: 4),
                    Text('12 words due for review today', style: text.bodyMedium!.copyWith(color: Colors.black54, fontSize: 14)),
                  ])),
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.schedule, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search vocabulary sets or words...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: (_searchCtrl.text.isNotEmpty)
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); setState(() {}); })
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Vocabulary Sets', style: text.titleMedium),
                Text('View All', style: text.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.primary)),
              ],
            ),
            const SizedBox(height: 8),

            // Sets list
            ...sets.where((s) => s.matches(_searchCtrl.text)).map((s) => _VocabSetTile(set: s)).toList(),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(.2)),
      boxShadow: const [BoxShadow(blurRadius: 4, color: Color(0x0D000000), offset: Offset(0,1))],
    ),
    child: child,
  );
}

class _VocabSet {
  final IconData icon; final Color iconBg; final Color iconColor;
  final String title; final String meta; final int favorites;
  final double progress; final Color pillColor;
  _VocabSet({required this.icon, required this.iconBg, required this.iconColor, required this.title, required this.meta, required this.favorites, required this.progress, required this.pillColor});
  bool matches(String q) => q.trim().isEmpty || title.toLowerCase().contains(q.toLowerCase());
}

class _VocabSetTile extends StatelessWidget {
  const _VocabSetTile({required this.set});
  final _VocabSet set;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _Card(
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: set.iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(set.icon, color: set.iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(set.title, style: text.titleSmall!.copyWith(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 4),
            Text(set.meta, style: text.bodySmall!.copyWith(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.favorite, color: Color(0xFFEF4444), size: 16),
              const SizedBox(width: 4),
              Text('${set.favorites} favorites', style: text.bodySmall!.copyWith(color: Colors.black54, fontSize: 12)),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            CircleAvatar(radius: 12, backgroundColor: set.pillColor, child: Icon(set.progress >= 1 ? Icons.check : Icons.play_arrow, color: Colors.white, size: 14)),
            const SizedBox(height: 4),
            Text('${(set.progress * 100).round()}%', style: text.bodySmall!.copyWith(color: set.pillColor, fontWeight: FontWeight.w600, fontSize: 12)),
          ]),
        ]),
      ),
    );
  }
}
