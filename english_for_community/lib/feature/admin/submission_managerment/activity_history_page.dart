import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/feature/admin/dashboard_home/admin_dashboard.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/feature/admin/layout/admin_page_scaffold.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:english_for_community/feature/admin/layout/admin_widgets.dart';
import 'package:english_for_community/feature/admin/submission_managerment/widget/user_dropdown_search.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/admin/layout/admin_skeleton.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// --- CORE & BLOC ---
import '../../../../core/get_it/get_it.dart';
import '../../../core/entity/user_entity.dart';
import 'bloc/history_bloc.dart';
import 'bloc/history_event.dart';
import 'bloc/history_state.dart';
import 'model/activity_model.dart';
import 'activity_detail_page.dart';

// --- SHADCN COLOR PALETTE ---
const Color kBgPage = AppColors.surfaceSubtle;      // Slate 100
const Color kWhite = Colors.white;
const Color kBorder = AppColors.outline;      // Slate 200
const Color kTextMain = AppColors.textPrimary;    // Slate 900
const Color kTextMuted = AppColors.textMuted;   // Slate 500
const Color kPrimary = AppColors.textPrimary;     // Slate 900

// Skill Colors (Pastel & Bold versions)
const Color kColWriting = AppColors.danger;  // Rose
const Color kColWritingBg = AppColors.dangerBg;
const Color kColReading = AppColors.warning;  // Amber
const Color kColReadingBg = AppColors.warningBg;
const Color kColSpeaking = AppColors.info; // Blue
const Color kColSpeakingBg = AppColors.infoBg;
const Color kColListening = AppColors.info;// Violet
const Color kColListeningBg = AppColors.infoBg;

class ActivityHistoryPage extends StatelessWidget {
  static const String routeName = 'ActivityHistoryPage';
  static const String routePath = '/activity-history';

  // Optional: Nếu Admin muốn xem user cụ thể, truyền ID vào đây
  final String? userId;

  const ActivityHistoryPage({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<HistoryBloc>()
        ..add(FetchHistoryEvent(
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          endDate: DateTime.now(),
          userId: userId,
        )),
      child: const _ActivityHistoryView(),
    );
  }
}

class _ActivityHistoryView extends StatefulWidget {
  const _ActivityHistoryView();

  @override
  State<_ActivityHistoryView> createState() => _ActivityHistoryViewState();
}

class _ActivityHistoryViewState extends State<_ActivityHistoryView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserEntity? _selectedUser; // State lưu user đang chọn

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // Check if mounted before reacting to tab changes if necessary,
    // though usually safe in synchronous listeners unless they trigger async work.
    if (!mounted) return;

    if (!_tabController.indexIsChanging) {
      ActivityType? type;
      switch (_tabController.index) {
        case 1: type = ActivityType.reading; break;
        case 2: type = ActivityType.listening; break;
        case 3: type = ActivityType.speaking; break;
        case 4: type = ActivityType.writing; break;
        default: type = null;
      }
      context.read<HistoryBloc>().add(FilterHistoryEvent(filterType: type));
    }
  }

  // Hàm xử lý khi chọn User từ Dropdown
  void _handleUserSelected(UserEntity? user) {
    // Ensure widget is mounted before updating state
    if (!mounted) return;

    setState(() => _selectedUser = user);

    final currentState = context.read<HistoryBloc>().state;
    final currentRange = currentState.dateRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now()
    );

    context.read<HistoryBloc>().add(FetchHistoryEvent(
      startDate: currentRange.start,
      endDate: currentRange.end,
      userId: user?.id, // Null nếu user bấm nút X
    ));
  }

  Future<void> _pickDateRange(BuildContext context, DateTimeRange currentRange) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: currentRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: kTextMain,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    // 🔥 Added check for mounted
    if (picked != null && context.mounted) {
      context.read<HistoryBloc>().add(FetchHistoryEvent(
          startDate: picked.start,
          endDate: picked.end,
          userId: _selectedUser?.id // Giữ nguyên user đang chọn nếu có
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AdminPageScaffold(
      title: l10n.adminActivityHistoryTitle,
      subtitle: l10n.adminNavSubmissions,
      scrollable: false,
      maxWidth: AdminWebUi.contentMaxTable,
      breadcrumbs: [
        AdminBreadcrumb(label: l10n.adminOverviewTitle, location: AdminDashboardPage.routePath),
        AdminBreadcrumb(label: l10n.adminActivityHistoryTitle),
      ],
      body: BlocConsumer<HistoryBloc, HistoryState>(
        listener: (context, state) {
          if (state.status == HistoryStatus.error) {
            AppCornerToast.show(context, state.errorMessage ?? 'Error', error: true);
          }
        },
        builder: (context, state) {
          final filteredList = state.filteredActivities;
          final dateRange = state.dateRange ?? DateTimeRange(start: DateTime.now(), end: DateTime.now());

          return Column(
            children: [
              // 1. CONTROL BAR
              Container(
                color: kWhite,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // DATE PICKER (Flex 3)
                        Expanded(
                            flex: 3,
                            child: _buildDateFilter(context, dateRange)
                        ),

                        const SizedBox(width: 8),

                        // 🔥 USER DROPDOWN (Flex 4) - Sử dụng Widget mới
                        Expanded(
                            flex: 4,
                            child: UserDropdownSearch(
                              selectedUser: _selectedUser,
                              onUserSelected: _handleUserSelected,
                            )
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: kBorder),

              // 2. FILTER TABS
              Container(
                color: kWhite,
                width: double.infinity,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: kTextMain,
                  unselectedLabelColor: kTextMuted,
                  indicatorColor: kPrimary,
                  indicatorWeight: 2,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabAlignment: TabAlignment.start,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Reading'),
                    Tab(text: 'Listening'),
                    Tab(text: 'Speaking'),
                    Tab(text: 'Writing'),
                  ],
                ),
              ),

              // 3. LIST CONTENT
              Expanded(
                child: state.status == HistoryStatus.loading
                    ? AdminSkeleton.page(AdminSkeleton.cardList())
                    : filteredList.isEmpty
                    ? AdminEmptyState(message: l10n.noData, icon: Icons.history_outlined)
                    : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _AdminHistoryCard(item: filteredList[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- UI COMPONENTS ---
  Widget _buildDateFilter(BuildContext context, DateTimeRange range) {
    final start = DateFormat('MMM dd, yy').format(range.start);
    final end = DateFormat('MMM dd, yy').format(range.end);

    return InkWell(
      onTap: () => _pickDateRange(context, range),
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(AppRadius.input),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: kBgPage, borderRadius: BorderRadius.circular(AppRadius.xs)),
              child: const Icon(Icons.calendar_today, size: 14, color: kTextMain),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Date", style: TextStyle(fontSize: 9, color: kTextMuted, fontWeight: FontWeight.w500)),
                  Text("$start - $end", overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMain)),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: kTextMuted),
          ],
        ),
      ),
    );
  }

}

// --- CARD & META TAGS (Giữ nguyên phần UI Card đã đẹp từ trước) ---
class _AdminHistoryCard extends StatelessWidget {
  final ActivityModel item;
  const _AdminHistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    // Determine colors based on type
    Color accentColor = kTextMuted;
    Color accentBg = kBgPage;
    IconData icon = Icons.article;

    switch (item.type) {
      case ActivityType.writing:
        accentColor = kColWriting; accentBg = kColWritingBg; icon = Icons.edit_note; break;
      case ActivityType.reading:
        accentColor = kColReading; accentBg = kColReadingBg; icon = Icons.menu_book; break;
      case ActivityType.listening:
        accentColor = kColListening; accentBg = kColListeningBg; icon = Icons.headphones; break;
      case ActivityType.speaking:
        accentColor = kColSpeaking; accentBg = kColSpeakingBg; icon = Icons.mic; break;
      default: break;
    }

    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActivityDetailPage(
                  id: item.id,       // Truyền ID từ item trong danh sách
                  type: item.type,   // Truyền Type (reading, writing...)

                  // (Optional) Truyền thêm mấy cái này để hiện giao diện tạm
                  // trong lúc chờ loading cho đỡ trống
                  summaryTitle: item.title,
                  summaryDate: item.date,
                  subType: item.subType,
                ),
              ),
            );          },
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER: User Info
                if (item.user != null) ...[
                  Row(
                    children: [
                      AdminWebUi.userAvatarCircle(
                        avatarUrl: item.user!.avatar,
                        displayName: item.user!.name,
                        radius: 14,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.user!.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kTextMain)),
                          Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(
                                  item.date.toUtc().add(const Duration(hours: 7))
                              ),
                              style: const TextStyle(fontSize: 11, color: kTextMuted)
                          ),                        ],
                      ),
                      const Spacer(),
                      _buildStatusBadge(item.status),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: kBgPage)),
                ],

                // 2. BODY: Activity Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: accentBg, borderRadius: BorderRadius.circular(AppRadius.input)),
                      child: Icon(icon, color: accentColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.subType != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(item.subType!.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kTextMuted, letterSpacing: 0.5)),
                            ),
                          Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kTextMain, height: 1.3)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildScore(item),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widgets cho Card
  Widget _buildScore(ActivityModel item) {
    if ((item.status == ActivityStatus.pending || item.status == ActivityStatus.draft) && item.type == ActivityType.writing) {
      return const SizedBox.shrink();
    }

    String display = item.type == ActivityType.writing ? item.score.toString() : '${item.score.toInt()}';
    String unit = item.type == ActivityType.writing ? 'Band' : '%';

    bool isGood = item.type == ActivityType.writing ? item.score >= 5.0 : item.score >= 50;
    Color color = isGood ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kBgPage,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Text(display, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
          Text(unit, style: const TextStyle(fontSize: 10, color: kTextMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ActivityStatus status) {
    String text;
    Color color;
    Color bg;

    switch (status) {
      case ActivityStatus.pending: text = 'Pending'; color = AppColors.warning; bg = AppColors.warningBg; break;
      case ActivityStatus.reviewed: text = 'Reviewed'; color = AppColors.success; bg = AppColors.successBg; break;
      case ActivityStatus.draft: text = 'Draft'; color = kTextMuted; bg = kBgPage; break;
      default: return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.chip)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}



