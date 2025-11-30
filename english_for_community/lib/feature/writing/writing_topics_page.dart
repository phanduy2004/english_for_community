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
  final _filters = const ['By Topic', 'By Essay Type'];
  int _selectedIndex = 0;

  // 1. Khai báo biến để giữ instance của Bloc
  late final WritingBloc _writingBloc;

  @override
  void initState() {
    super.initState();
    // 2. Lấy instance MỘT LẦN DUY NHẤT
    _writingBloc = getIt<WritingBloc>();

    // 3. Gọi event trên chính instance đó
    _writingBloc.add(GetWritingTopicsEvent());
  }

  // (Optional) Dispose nếu cần thiết, nhưng thường với GetIt factory thì không bắt buộc nếu Bloc tự đóng stream
  // @override
  // void dispose() {
  //   _writingBloc.close();
  //   super.dispose();
  // }

  void _onSearchTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Open search page…')),
    );
  }

  void _onCardTap(WritingTopicEntity item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WritingTaskPage(topic: item),
      ),
    );
  }

  void _showHistoryModal(BuildContext context, WritingTopicEntity topic, Color primaryColor) {
    // Gọi event lấy lịch sử trên cùng instance _writingBloc
    _writingBloc.add(GetTopicHistoryEvent(topic.id));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: _writingBloc, // Sử dụng lại _writingBloc
        child: HistoryModal(
          topicName: topic.name,
          primaryColor: primaryColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgPage = Color(0xFFF9FAFB);
    const borderCol = Color(0xFFE4E4E7);
    const textMain = Color(0xFF09090B);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return BlocProvider.value(
      // 4. Cung cấp đúng biến _writingBloc cho UI lắng nghe
      value: _writingBloc,
      child: Scaffold(
        backgroundColor: bgPage,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: borderCol, height: 1),
          ),
          leading: const Icon(Icons.menu, color: textMain),
          title: const Text(
            'Writing Skills',
            style: TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 17),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.history, color: textMain),
              onPressed: () {},
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 20),
                    const WritingHeader(),
                    const SizedBox(height: 20),
                    WritingSearchBox(
                        primaryColor: primaryColor,
                        onTap: _onSearchTap
                    ),
                    const SizedBox(height: 16),
                    WritingFilterRow(
                      filters: _filters,
                      selectedIndex: _selectedIndex,
                      primaryColor: primaryColor,
                      onSelected: (i) => setState(() => _selectedIndex = i),
                    ),
                    const SizedBox(height: 20),
                    BlocBuilder<WritingBloc, WritingState>(
                      builder: (context, state) {
                        if (state.status == WritingStatus.loading) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }

                        // Debug log để kiểm tra state
                        // print("DEBUG STATE: ${state.status} - Count: ${state.topics.length}");

                        if (state.status == WritingStatus.error) {
                          return WritingErrorView(message: state.errorMessage ?? 'An error occurred');
                        }

                        final topics = state.topics;
                        if (topics.isEmpty) return const WritingEmptyView();

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: topics.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, i) {
                            final t = topics[i];
                            final icon = _iconFromString(t.icon);

                            return WritingCard(
                              title: t.name,
                              leadingIcon: icon,
                              onTap: () => _onCardTap(t),
                              onHistoryTap: () => _showHistoryModal(context, t, primaryColor),
                              taskType: t.aiConfig?.defaultTaskType,
                              level: t.aiConfig?.level,
                              submissions: t.stats?.submissionsCount,
                              avgScore: t.stats?.avgScore,
                              primaryColor: primaryColor,
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFromString(String? name) {
    switch (name) {
      case 'brush': return Icons.brush_outlined;
      case 'memory': return Icons.memory_outlined;
      case 'school': return Icons.school_outlined;
      case 'public': return Icons.public_outlined;
      case 'favorite': return Icons.favorite_border;
      case 'science': return Icons.science_outlined;
      case 'diversity_3': return Icons.diversity_3_outlined;
      case 'gavel': return Icons.gavel_outlined;
      case 'business': return Icons.business_center_outlined;
      case 'campaign': return Icons.campaign_outlined;
      case 'flight': return Icons.flight_takeoff_outlined;
      case 'location_city': return Icons.location_city_outlined;
      case 'work': return Icons.work_outline;
      case 'family_restroom': return Icons.family_restroom_outlined;
      case 'restaurant': return Icons.restaurant_outlined;
      default: return Icons.article_outlined;
    }
  }
}