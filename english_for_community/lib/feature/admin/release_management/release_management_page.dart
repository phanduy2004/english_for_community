import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/feature/admin/dashboard_home/admin_dashboard.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/feature/admin/layout/admin_page_scaffold.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/entity/admin/app_release_admin_entity.dart';
import '../../../core/get_it/get_it.dart';
import '../../../core/theme/app_color.dart';
import 'bloc/release_management_bloc.dart';
import 'bloc/release_management_event.dart';
import 'bloc/release_management_state.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _kStatuses = [
  'pending_approval',
  'approved',
  'scheduled',
  'published',
  'rejected',
  'archived',
];

const _kStatusLabel = {
  'pending_approval': 'Chờ duyệt',
  'approved': 'Đã duyệt',
  'scheduled': 'Lên lịch',
  'published': 'Đã phát hành',
  'rejected': 'Từ chối',
  'archived': 'Lưu trữ',
};

Color _statusBg(String s) {
  switch (s) {
    case 'approved':
      return const Color(0xFFDCFCE7);
    case 'published':
      return const Color(0xFFD1FAE5);
    case 'pending_approval':
      return const Color(0xFFFEF3C7);
    case 'scheduled':
      return const Color(0xFFE0E7FF);
    case 'rejected':
      return const Color(0xFFFEE2E2);
    case 'archived':
      return const Color(0xFFF1F5F9);
    default:
      return const Color(0xFFF1F5F9);
  }
}

Color _statusFg(String s) {
  switch (s) {
    case 'approved':
      return const Color(0xFF166534);
    case 'published':
      return const Color(0xFF065F46);
    case 'pending_approval':
      return const Color(0xFF92400E);
    case 'scheduled':
      return const Color(0xFF3730A3);
    case 'rejected':
      return const Color(0xFF991B1B);
    case 'archived':
      return const Color(0xFF475569);
    default:
      return const Color(0xFF334155);
  }
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class ReleaseManagementPage extends StatefulWidget {
  const ReleaseManagementPage({super.key});

  static const String routeName = 'ReleaseManagementPage';
  static const String routePath = '/admin/releases';

  @override
  State<ReleaseManagementPage> createState() => _ReleaseManagementPageState();
}

class _ReleaseManagementPageState extends State<ReleaseManagementPage> {
  final _searchCtrl = TextEditingController();
  late final ReleaseManagementBloc _bloc;
  String _statusFilter = 'pending_approval';
  ReleaseSortBy _sortBy = ReleaseSortBy.createdAt;
  bool _sortDesc = true;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<ReleaseManagementBloc>()
      ..add(ReleaseLoadRequested(status: _statusFilter));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _bloc.close();
    super.dispose();
  }

  // ── dialogs ─────────────────────────────────────────────────────────────

  Future<void> _rejectDialog(BuildContext context, String id) async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Từ chối release'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Lý do từ chối',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ReleaseManagementBloc>().add(ReleaseActionRequested(
                    action: 'reject',
                    releaseId: id,
                    payload: {
                      'reason': ctrl.text.trim().isEmpty
                          ? 'Rejected by admin'
                          : ctrl.text.trim()
                    },
                  ));
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Future<void> _scheduleDialog(BuildContext context, String id) async {
    final now = DateTime.now().add(const Duration(minutes: 5));
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: now,
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(now));
    if (pickedTime == null) return;
    final scheduled = DateTime(pickedDate.year, pickedDate.month,
            pickedDate.day, pickedTime.hour, pickedTime.minute)
        .toUtc();
    if (!context.mounted) return;
    context.read<ReleaseManagementBloc>().add(ReleaseActionRequested(
          action: 'schedule',
          releaseId: id,
          payload: {'scheduledPublishAt': scheduled.toIso8601String()},
        ));
  }

  Future<void> _publishWithConfirm(
      BuildContext context, AppReleaseAdminEntity item) async {
    if (!item.isForce) {
      context
          .read<ReleaseManagementBloc>()
          .add(ReleaseActionRequested(action: 'publish', releaseId: item.id));
      return;
    }

    final first = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(children: const [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
          SizedBox(width: 8),
          Text('Cảnh báo FORCE UPDATE'),
        ]),
        content: const Text(
          'Bản phát hành này đang ở chế độ FORCE UPDATE và sẽ chặn người dùng'
          ' sử dụng ứng dụng nếu không cập nhật.\n\nBạn có chắc muốn tiếp tục?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tiếp tục')),
        ],
      ),
    );
    if (first != true || !context.mounted) return;

    final codeCtrl = TextEditingController();
    final second = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Xác nhận bước 2'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nhập chính xác "FORCE" để xác nhận.'),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), hintText: 'FORCE'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xác nhận')),
        ],
      ),
    );
    if (second != true || !context.mounted) return;
    if (codeCtrl.text.trim().toUpperCase() != 'FORCE') {
      AppCornerToast.show(context, context.l10n.adminReleaseConfirmCodeInvalid, error: true);
      return;
    }
    context.read<ReleaseManagementBloc>().add(
          ReleaseActionRequested(action: 'publish', releaseId: item.id),
        );
  }

  // ── utils ────────────────────────────────────────────────────────────────

  String _fmtDate(dynamic v) {
    if (v == null) return '-';
    final dt = DateTime.tryParse(v.toString());
    return dt == null ? '-' : DateFormat('dd/MM/yyyy HH:mm').format(dt.toLocal());
  }

  // ── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<ReleaseManagementBloc, ReleaseManagementState>(
        listener: (context, state) {
          if (state.status == ReleaseManagementStatus.error &&
              state.errorMessage != null) {
            AppCornerToast.show(context, state.errorMessage!, error: true);
          } else if (state.status == ReleaseManagementStatus.actionSuccess) {
            AppCornerToast.show(context, context.l10n.adminActionSuccess);
          }
        },
        builder: (context, state) {
          final bloc = _bloc;
          final isLoading = state.status == ReleaseManagementStatus.loading ||
              state.status == ReleaseManagementStatus.initial;

          final l10n = context.l10n;
          return AdminPageScaffold(
            title: l10n.adminNavReleases,
            subtitle: l10n.adminNavReleasesSub,
            scrollable: false,
            maxWidth: AdminWebUi.contentMaxTable,
            breadcrumbs: [
              AdminBreadcrumb(label: l10n.adminOverviewTitle, location: AdminDashboardPage.routePath),
              AdminBreadcrumb(label: l10n.adminNavReleases),
            ],
            actions: [
              IconButton(
                tooltip: 'Chạy publish theo lịch ngay',
                onPressed: () => bloc.add(ReleaseActionRequested(action: 'publish-due-run', releaseId: '')),
                icon: const Icon(Icons.schedule_send_outlined, size: 20),
              ),
              IconButton(
                tooltip: 'Làm mới',
                onPressed: () => bloc.add(ReleaseLoadRequested(status: _statusFilter)),
                icon: const Icon(Icons.refresh, size: 20),
              ),
            ],
            body: RefreshIndicator(
              onRefresh: () async =>
                  bloc.add(ReleaseLoadRequested(status: _statusFilter)),
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Overview header ────────────────────────────
                          _OverviewHeader(counts: state.statusCounts),
                          const SizedBox(height: 20),

                          // ── Status tab filter ──────────────────────────
                          _StatusTabBar(
                            selected: _statusFilter,
                            counts: state.statusCounts,
                            onTap: (s) {
                              setState(() => _statusFilter = s);
                              bloc.add(ReleaseLoadRequested(status: s));
                            },
                          ),
                          const SizedBox(height: 16),

                          // ── Search & sort bar ──────────────────────────
                          _SearchSortBar(
                            searchCtrl: _searchCtrl,
                            sortBy: _sortBy,
                            sortDesc: _sortDesc,
                            onSearch: (v) => bloc.add(ReleaseSearchChanged(v)),
                            onSortBy: (v) {
                              setState(() => _sortBy = v);
                              bloc.add(ReleaseSortChanged(
                                  sortBy: v, descending: _sortDesc));
                            },
                            onToggleDesc: () {
                              setState(() => _sortDesc = !_sortDesc);
                              bloc.add(ReleaseSortChanged(
                                  sortBy: _sortBy, descending: _sortDesc));
                            },
                          ),
                          const SizedBox(height: 16),

                          // ── Release list ───────────────────────────────
                          _ReleaseListSection(
                            isLoading: isLoading,
                            items: state.visibleReleases,
                            fmtDate: _fmtDate,
                            onApprove: (id) => bloc.add(ReleaseActionRequested(
                                action: 'approve', releaseId: id)),
                            onReject: (id) => _rejectDialog(context, id),
                            onSchedule: (id) => _scheduleDialog(context, id),
                            onPublish: (item) =>
                                _publishWithConfirm(context, item),
                            onRollback: (id) => bloc.add(ReleaseActionRequested(
                                action: 'rollback', releaseId: id)),
                          ),
                        ],
                      ),
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
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _OverviewHeader extends StatelessWidget {
  const _OverviewHeader({required this.counts});
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final pending = counts['pending_approval'] ?? 0;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quản lý phiên bản',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('Duyệt và phát hành phiên bản ứng dụng Android / iOS.',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textMuted)),
            ],
          ),
        ),
        if (pending > 0)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_top_rounded,
                    size: 16, color: Color(0xFF92400E)),
                const SizedBox(width: 6),
                Text('$pending chờ duyệt',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E))),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatusTabBar extends StatelessWidget {
  const _StatusTabBar({
    required this.selected,
    required this.counts,
    required this.onTap,
  });

  final String selected;
  final Map<String, int> counts;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _kStatuses.map((s) {
          final isSelected = s == selected;
          final count = counts[s] ?? 0;
          final bg = isSelected ? _statusBg(s) : const Color(0xFFF1F5F9);
          final fg = isSelected ? _statusFg(s) : AppColors.textMuted;
          final border = isSelected
              ? Border.all(color: _statusFg(s).withValues(alpha: 0.35), width: 1.5)
              : Border.all(color: const Color(0xFFE2E8F0));

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onTap(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                  border: border,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_kStatusLabel[s] ?? s,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: fg)),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _statusFg(s)
                              : AppColors.textMuted,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('$count',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SearchSortBar extends StatelessWidget {
  const _SearchSortBar({
    required this.searchCtrl,
    required this.sortBy,
    required this.sortDesc,
    required this.onSearch,
    required this.onSortBy,
    required this.onToggleDesc,
  });

  final TextEditingController searchCtrl;
  final ReleaseSortBy sortBy;
  final bool sortDesc;
  final ValueChanged<String> onSearch;
  final ValueChanged<ReleaseSortBy> onSortBy;
  final VoidCallback onToggleDesc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              controller: searchCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon:
                    const Icon(Icons.search, size: 18, color: Colors.black45),
                hintText: 'Tìm theo version, SHA, status...',
                hintStyle:
                    const TextStyle(fontSize: 13, color: Colors.black45),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 9),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide:
                        const BorderSide(color: Color(0xFFCBD5E1))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide:
                        const BorderSide(color: Color(0xFFCBD5E1))),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
              onChanged: onSearch,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sắp xếp:',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(width: 8),
              _CompactDropdown<ReleaseSortBy>(
                value: sortBy,
                items: const {
                  ReleaseSortBy.createdAt: 'Ngày tạo',
                  ReleaseSortBy.versionCode: 'Version code',
                  ReleaseSortBy.status: 'Trạng thái',
                },
                onChanged: (v) { if (v != null) onSortBy(v); },
              ),
              const SizedBox(width: 4),
              _IconToggleButton(
                icon: sortDesc ? Icons.arrow_downward : Icons.arrow_upward,
                tooltip: sortDesc ? 'Giảm dần' : 'Tăng dần',
                onTap: onToggleDesc,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReleaseListSection extends StatelessWidget {
  const _ReleaseListSection({
    required this.isLoading,
    required this.items,
    required this.fmtDate,
    required this.onApprove,
    required this.onReject,
    required this.onSchedule,
    required this.onPublish,
    required this.onRollback,
  });

  final bool isLoading;
  final List<AppReleaseAdminEntity> items;
  final String Function(dynamic) fmtDate;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;
  final ValueChanged<String> onSchedule;
  final ValueChanged<AppReleaseAdminEntity> onPublish;
  final ValueChanged<String> onRollback;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _SectionCard(
        title: 'Danh sách release',
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: AppLoadingIndicator.center()),
        ),
      );
    }

    if (items.isEmpty) {
      return _SectionCard(
        title: 'Danh sách release',
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.inbox_outlined,
                  size: 40, color: AppColors.textMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              const Text('Không có release nào theo bộ lọc hiện tại.',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return _SectionCard(
      title: 'Danh sách release (${items.length})',
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++)
            _ReleaseItemCard(
              item: items[i],
              fmtDate: fmtDate,
              showDivider: i < items.length - 1,
              onApprove: onApprove,
              onReject: onReject,
              onSchedule: onSchedule,
              onPublish: onPublish,
              onRollback: onRollback,
            ),
        ],
      ),
    );
  }
}

class _ReleaseItemCard extends StatelessWidget {
  const _ReleaseItemCard({
    required this.item,
    required this.fmtDate,
    required this.showDivider,
    required this.onApprove,
    required this.onReject,
    required this.onSchedule,
    required this.onPublish,
    required this.onRollback,
  });

  final AppReleaseAdminEntity item;
  final String Function(dynamic) fmtDate;
  final bool showDivider;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;
  final ValueChanged<String> onSchedule;
  final ValueChanged<AppReleaseAdminEntity> onPublish;
  final ValueChanged<String> onRollback;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: platform icon + version + badges
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Platform icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.platform.toLowerCase() == 'ios'
                          ? Icons.apple
                          : Icons.android,
                      size: 22,
                      color: item.platform.toLowerCase() == 'ios'
                          ? const Color(0xFF475569)
                          : const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Version info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'v${item.versionName}+${item.versionCode}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusPill(status: item.status),
                            if (item.isForce) ...[
                              const SizedBox(width: 6),
                              _ForceBadge(),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 12,
                          children: [
                            _MetaText(
                                icon: Icons.smartphone_outlined,
                                label: item.platform.toUpperCase()),
                            _MetaText(
                                icon: Icons.low_priority_outlined,
                                label: 'min: ${item.minSupportedVersionCode}'),
                            _MetaText(
                                icon: Icons.schedule_outlined,
                                label: fmtDate(item.createdAt)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Action buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (item.status == 'pending_approval')
                    _ActionButton(
                      label: 'Approve',
                      icon: Icons.check_circle_outline,
                      color: const Color(0xFF16A34A),
                      onTap: () => onApprove(item.id),
                    ),
                  if (item.status == 'pending_approval' ||
                      item.status == 'approved' ||
                      item.status == 'scheduled')
                    _ActionButton(
                      label: 'Từ chối',
                      icon: Icons.cancel_outlined,
                      color: const Color(0xFFDC2626),
                      outlined: true,
                      onTap: () => onReject(item.id),
                    ),
                  if (item.status == 'approved')
                    _ActionButton(
                      label: 'Lên lịch',
                      icon: Icons.event_outlined,
                      color: const Color(0xFF6366F1),
                      outlined: true,
                      onTap: () => onSchedule(item.id),
                    ),
                  if (item.status == 'approved' || item.status == 'scheduled')
                    _ActionButton(
                      label: item.isForce ? 'Publish (FORCE)' : 'Publish',
                      icon: Icons.rocket_launch_outlined,
                      color: item.isForce
                          ? const Color(0xFFDC2626)
                          : AppColors.primary,
                      onTap: () => onPublish(item),
                    ),
                  if (item.status == 'published')
                    _ActionButton(
                      label: 'Rollback',
                      icon: Icons.history,
                      color: const Color(0xFF92400E),
                      outlined: true,
                      onTap: () => onRollback(item.id),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Small reusable widgets
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _statusBg(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _kStatusLabel[status] ?? status,
        style: TextStyle(
            color: _statusFg(status),
            fontSize: 11,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ForceBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: const Text('FORCE',
          style: TextStyle(
              color: Color(0xFF991B1B),
              fontSize: 10,
              fontWeight: FontWeight.w800)),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          textStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        icon: Icon(icon, size: 15),
        label: Text(label),
      );
    }
    return FilledButton.icon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        textStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      icon: Icon(icon, size: 15),
      label: Text(label),
    );
  }
}

class _CompactDropdown<T> extends StatelessWidget {
  const _CompactDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontFamily: 'Inter'),
          icon: const Icon(Icons.unfold_more, size: 16),
          items: items.entries
              .map((e) =>
                  DropdownMenuItem<T>(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _IconToggleButton extends StatelessWidget {
  const _IconToggleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
