import 'package:english_for_community/core/entity/writing_topic_entity.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/feature/writing/bloc/writing_bloc.dart';
import 'package:english_for_community/feature/writing/bloc/writing_event.dart';
import 'package:english_for_community/feature/writing/bloc/writing_state.dart';
import 'package:english_for_community/feature/writing/writing_task_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import các Widgets đã tách
import 'widgets/writing_card.dart';
import 'widgets/history_modal.dart';
import 'widgets/writing_common_widgets.dart';

class WritingTopicsPage extends StatefulWidget {
  const WritingTopicsPage({super.key});

  static const routeName = 'WritingTopicsPage';
  static const routePath = '/writing-topics';

  @override
  State<WritingTopicsPage> createState() => _WritingTopicsPageState();
}

class _WritingTopicsPageState extends State<WritingTopicsPage> {
  // Shadcn Color Palette
  static const Color zinc100 = Color(0xFFF4F4F5);
  static const Color zinc200 = Color(0xFFE4E4E7);
  static const Color zinc500 = Color(0xFF71717A);
  static const Color zinc900 = Color(0xFF09090B);

  late final WritingBloc _writingBloc;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 👇 1. THÊM BIẾN CHO BỘ LỌC
  int _selectedFilterIndex = 0;
  final _filters = ['All', 'Beginner', 'Intermediate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    _writingBloc = getIt<WritingBloc>();
    _writingBloc.add(GetWritingTopicsEvent());

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 👇 2. HÀM LẤY MÀU THEO ĐỘ KHÓ
  Color _getLevelColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF16A34A); // Green
      case 'intermediate':
        return const Color(0xFFEA580C); // Orange
      case 'advanced':
        return const Color(0xFFDC2626); // Red
      default:
        return const Color(0xFF6366F1); // Default Indigo (nếu ko có level)
    }
  }

  // --- CONFIG ICON & MÀU SẮC CHO TASK TYPE ---
  ({IconData icon, Color color, String desc}) _getTaskTypeConfig(String type) {
    final t = type.toLowerCase();
    if (t.contains('opinion') || t.contains('agree')) {
      return (icon: Icons.lightbulb_outline, color: const Color(0xFFF59E0B), desc: 'Express your personal view'); // Amber
    } else if (t.contains('discuss')) {
      return (icon: Icons.people_outline, color: const Color(0xFF3B82F6), desc: 'Analyze multiple perspectives'); // Blue
    } else if (t.contains('problem') || t.contains('solution') || t.contains('cause')) {
      return (icon: Icons.build_circle_outlined, color: const Color(0xFFEF4444), desc: 'Identify issues & fixes'); // Red
    } else if (t.contains('advantage')) {
      return (icon: Icons.balance, color: const Color(0xFF10B981), desc: 'Weigh pros and cons'); // Emerald
    }
    return (icon: Icons.edit_note, color: const Color(0xFF6366F1), desc: 'General writing practice'); // Indigo
  }

  // --- MODAL CHỌN TASK (SHADCN STYLE) ---
  void _showTaskSelectionModal(BuildContext context, WritingTopicEntity topic) {
    final taskTypes = topic.aiConfig?.taskTypes ??
        ['Opinion', 'Discussion', 'Problem-Solution', 'Advantages-Disadvantages'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48, height: 4,
                  decoration: BoxDecoration(color: zinc200, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: zinc100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.dashboard_customize_outlined, color: zinc900, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Task Type',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: zinc900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'For topic: "${topic.name}"',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: zinc500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: taskTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final type = taskTypes[index];
                    final config = _getTaskTypeConfig(type);

                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WritingTaskPage(
                              topic: topic,
                              selectedTaskType: type,
                            ),
                          ),
                        ).then((_) {
                          if (mounted) _writingBloc.add(GetWritingTopicsEvent());
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: zinc200),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: config.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(config.icon, color: config.color, size: 22),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: zinc900
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    config.desc,
                                    style: const TextStyle(fontSize: 12, color: zinc500),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: zinc200),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showHistoryModal(BuildContext context, WritingTopicEntity topic) {
    _writingBloc.add(GetTopicHistoryEvent(topic.id));
    // Sử dụng màu theo level để modal cũng đồng bộ màu
    final levelColor = _getLevelColor(topic.aiConfig?.level);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: _writingBloc,
        child: HistoryModal(
          topicName: topic.name,
          primaryColor: levelColor,
        ),
      ),
    );
  }

  void _onCardTap(WritingTopicEntity item) {
    _showTaskSelectionModal(context, item);
  }

  // 👇 3. WIDGET BỘ LỌC (FILTER BAR)
  Widget _buildFilterBar(Color primaryColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: _filters.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          final isSelected = index == _selectedFilterIndex;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedFilterIndex = index);
              },
              selectedColor: primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : zinc500,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? primaryColor : zinc200,
                ),
              ),
              showCheckmark: false, // Tắt dấu tích cho gọn
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: zinc200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 14, color: zinc900),
        decoration: InputDecoration(
          hintText: 'Search topics...',
          hintStyle: const TextStyle(fontSize: 14, color: zinc500),
          prefixIcon: const Icon(Icons.search, size: 20, color: zinc500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          isDense: true,
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close, size: 16, color: zinc500),
            onPressed: () {
              _searchController.clear();
              FocusScope.of(context).unfocus();
            },
          ) : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Màu chủ đạo mặc định (Dùng cho thanh filter, search box)
    final themePrimaryColor = Theme.of(context).colorScheme.primary;

    return BlocProvider.value(
      value: _writingBloc,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: zinc200, height: 1),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: zinc900, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Writing Practice',
            style: TextStyle(color: zinc900, fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WritingHeader(),
                    const SizedBox(height: 24),
                    _buildSearchBox(),
                    const SizedBox(height: 16),
                    // 👇 4. HIỂN THỊ BỘ LỌC
                    _buildFilterBar(themePrimaryColor),
                  ],
                ),
              ),
            ),
            BlocBuilder<WritingBloc, WritingState>(
              builder: (context, state) {
                if (state.status == WritingStatus.loading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                if (state.status == WritingStatus.error) {
                  return SliverFillRemaining(
                    child: WritingErrorView(message: state.errorMessage ?? 'An error occurred'),
                  );
                }

                var topics = state.topics;

                // 👇 5. LOGIC LỌC DỮ LIỆU

                // Lọc theo Text
                if (_searchQuery.isNotEmpty) {
                  topics = topics.where((t) =>
                      t.name.toLowerCase().contains(_searchQuery.toLowerCase())
                  ).toList();
                }

                // Lọc theo Level (Dựa vào _selectedFilterIndex)
                final selectedLevel = _filters[_selectedFilterIndex];
                if (selectedLevel != 'All') {
                  topics = topics.where((t) =>
                  (t.aiConfig?.level ?? '').toLowerCase() == selectedLevel.toLowerCase()
                  ).toList();
                }

                if (topics.isEmpty) {
                  return const SliverFillRemaining(child: WritingEmptyView());
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final t = topics[index];
                        const commonIcon = Icons.history_edu;

                        // 👇 6. LẤY MÀU THEO ĐỘ KHÓ
                        final levelColor = _getLevelColor(t.aiConfig?.level);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: WritingCard(
                            title: t.name,
                            leadingIcon: commonIcon,
                            onTap: () => _onCardTap(t),
                            onHistoryTap: () => _showHistoryModal(context, t),
                            level: t.aiConfig?.level,
                            submissions: t.stats?.submissionsCount,
                            avgScore: t.stats?.avgScore,

                            // 👇 7. TRUYỀN MÀU VÀO CARD
                            // WritingCard của bạn sẽ dùng màu này để tô Badge và các icon
                            primaryColor: themePrimaryColor,
                          ),
                        );
                      },
                      childCount: topics.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}