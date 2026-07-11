import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/feature/admin/dashboard_home/admin_dashboard.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/core/ui/widget/web_data_table.dart';
import 'package:english_for_community/feature/admin/layout/admin_page_scaffold.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:english_for_community/feature/admin/layout/admin_widgets.dart';
import 'package:english_for_community/feature/admin/submission_managerment/widget/user_dropdown_search.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/admin/layout/admin_skeleton.dart';
import 'package:english_for_community/feature/admin/content_management/content_widgets.dart';
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
                    ? AdminSkeleton.page(AdminSkeleton.table(rows: 6))
                    : filteredList.isEmpty
                    ? AdminEmptyState(message: l10n.noData, icon: Icons.history_outlined)
                    : Padding(
                        padding: const EdgeInsets.all(AppSpacing.s4),
                        child: WebDataTable(
                          columns: [
                            WebTableColumn(label: l10n.adminTableUser, flex: 3),
                            WebTableColumn(label: l10n.adminTableSkill, width: 120),
                            WebTableColumn(label: l10n.adminTableType, width: 130),
                            WebTableColumn(label: l10n.adminTableContent, flex: 3),
                            WebTableColumn(label: l10n.adminTableStatus, width: 120),
                            WebTableColumn(label: l10n.adminTableScore, width: 90, align: Alignment.centerRight, headAlign: Alignment.centerRight),
                            WebTableColumn(label: l10n.adminTableDate, width: 150),
                          ],
                          rowCount: filteredList.length,
                          decoration: AdminWebUi.panelDecoration(),
                          headStyle: AdminWebUi.webTableHead(context),
                          scrollable: true,
                          onRowTap: (row) => () => _openDetail(filteredList[row]),
                          cellBuilder: (context, row, column) {
                            final item = filteredList[row];
                            return switch (column) {
                              0 => _userCell(item),
                              1 => _skillCell(item.type),
                              2 => _tableText(item.subType ?? '-'),
                              3 => _tableText(item.title, weight: FontWeight.w600),
                              4 => _statusCell(item.status),
                              5 => _scoreCell(item),
                              6 => _tableText(_formatDate(item.date), muted: true),
                              _ => const SizedBox.shrink(),
                            };
                          },
                        ),
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

  void _openDetail(ActivityModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityDetailPage(
          id: item.id,
          type: item.type,
          summaryTitle: item.title,
          summaryDate: item.date,
          subType: item.subType,
        ),
      ),
    );
  }

  Widget _userCell(ActivityModel item) {
    final user = item.user;
    return Row(
      children: [
        AdminWebUi.userAvatarCircle(
          avatarUrl: user?.avatar,
          displayName: user?.name ?? 'Unknown User',
          radius: 14,
        ),
        const SizedBox(width: AppSpacing.s2),
        Expanded(child: _tableText(user?.name ?? 'Unknown User', weight: FontWeight.w600)),
      ],
    );
  }

  Widget _skillCell(ActivityType type) {
    final (icon, label) = switch (type) {
      ActivityType.writing => (Icons.edit_note_outlined, 'Writing'),
      ActivityType.reading => (Icons.menu_book_outlined, 'Reading'),
      ActivityType.listening => (Icons.headphones_outlined, 'Listening'),
      ActivityType.speaking => (Icons.mic_none_outlined, 'Speaking'),
      ActivityType.unknown => (Icons.article_outlined, 'Unknown'),
    };
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.s2),
        Flexible(child: _tableText(label)),
      ],
    );
  }

  Widget _statusCell(ActivityStatus status) {
    final (label, color) = switch (status) {
      ActivityStatus.pending => ('Pending', AppColors.warning),
      ActivityStatus.reviewed => ('Reviewed', AppColors.success),
      ActivityStatus.draft => ('Draft', AppColors.textSecondary),
      ActivityStatus.completed => ('Completed', AppColors.success),
      ActivityStatus.unknown => ('Unknown', AppColors.textSecondary),
    };
    return Semantics(
      label: '${context.l10n.adminTableStatus}: $label',
      child: StatusBadge(text: label, color: color),
    );
  }

  Widget _scoreCell(ActivityModel item) {
    if (item.type == ActivityType.writing &&
        (item.status == ActivityStatus.pending || item.status == ActivityStatus.draft)) {
      return _tableText('-', muted: true);
    }
    final score = item.type == ActivityType.writing ? '${item.score} Band' : '${item.score.toInt()}%';
    return _tableText(score, weight: FontWeight.w600);
  }

  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());

  Widget _tableText(String value, {bool muted = false, FontWeight? weight}) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        fontWeight: weight,
        color: muted ? AppColors.textSecondary : AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

}

