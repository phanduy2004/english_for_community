import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/feature/admin/dashboard_home/admin_dashboard.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/core/ui/widget/web_data_table.dart';
import 'package:english_for_community/feature/admin/layout/admin_page_scaffold.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:english_for_community/feature/admin/layout/admin_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/entity/admin/app_release_admin_entity.dart';
import '../../../core/get_it/get_it.dart';
import 'package:english_for_community/core/theme/admin_status_palette.dart';
import 'package:english_for_community/core/theme/app_color.dart';
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

Color _statusBg(String s) => AdminStatusPalette.releaseStatusBg(s);

Color _statusFg(String s) => AdminStatusPalette.releaseStatusFg(s);

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
    String? error;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
          title: const Text('Từ chối release'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl,
                decoration: AdminWebUi.formInputDecoration(
                  context,
                  hintText: 'Nhập lý do từ chối',
                ),
                maxLines: 3,
              ),
              AdminWebUi.formFieldError(context, error),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () {
                final reason = ctrl.text.trim();
                if (reason.isEmpty) {
                  setDialogState(() => error = 'Vui lòng nhập lý do từ chối.');
                  return;
                }
                Navigator.pop(context);
                context.read<ReleaseManagementBloc>().add(
                      ReleaseActionRequested(
                        action: 'reject',
                        releaseId: id,
                        payload: {'reason': reason},
                      ),
                    );
              },
              child: const Text('Từ chối'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rollbackDialog(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Xác nhận rollback'),
          ],
        ),
        content: Container(
          width: 460,
          padding: const EdgeInsets.all(AppSpacing.s3),
          decoration: BoxDecoration(
            color: AppColors.dangerBg,
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(color: AppColors.dangerBg),
          ),
          child: const Text(
            'Rollback là hành động nhạy cảm và có thể tác động trực tiếp đến người dùng. '
            'Chỉ tiếp tục khi bạn đã xác nhận ảnh hưởng và kế hoạch khắc phục.',
            style: TextStyle(color: AppColors.danger),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rollback'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    context.read<ReleaseManagementBloc>().add(
          ReleaseActionRequested(action: 'rollback', releaseId: id),
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
    if (pickedDate == null || !context.mounted) return;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
        title: Row(children: const [
          Icon(Icons.warning_amber_rounded, color: AppColors.danger),
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
                  backgroundColor: AppColors.danger),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
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
                            onRollback: (id) => _rollbackDialog(context, id),
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
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(color: AppColors.warningBg),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_top_rounded,
                    size: 16, color: AppColors.warning),
                const SizedBox(width: 6),
                Text('$pending chờ duyệt',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning)),
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
          final bg = isSelected ? _statusBg(s) : AppColors.surfaceSubtle;
          final fg = isSelected ? _statusFg(s) : AppColors.textMuted;
          final border = isSelected
              ? Border.all(color: _statusFg(s).withValues(alpha: 0.35), width: 1.5)
              : Border.all(color: AppColors.outline);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onTap(s),
              child: AnimatedContainer(
                duration: AppMotion.web,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppRadius.input),
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
                          borderRadius: BorderRadius.circular(AppRadius.pill),
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
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outline),
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
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    borderSide:
                        const BorderSide(color: AppColors.outline)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    borderSide:
                        const BorderSide(color: AppColors.outline)),
                filled: true,
                fillColor: AppColors.surface,
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
      return _SectionCard(
        title: 'Danh sách release',
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: AdminSkeleton.page(AdminSkeleton.table(rows: 6)),
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

    return _buildReleaseTable(context);
  }

  Widget _buildReleaseTable(BuildContext context) {
    final l10n = context.l10n;
    return WebDataTable(
      columns: [
        WebTableColumn(label: l10n.adminTableVersion, flex: 3),
        WebTableColumn(label: l10n.adminTablePlatform, width: 120),
        WebTableColumn(label: l10n.adminTableStatus, width: 130),
        WebTableColumn(label: l10n.adminTableMinimumVersion, width: 120, align: Alignment.centerRight, headAlign: Alignment.centerRight),
        WebTableColumn(label: l10n.adminTableCreated, width: 150),
        // Cột icon 56px — header để trống (nhãn "ACTIONS" không vừa, tự hiểu qua icon).
        WebTableColumn(label: '', width: 56, align: Alignment.center, headAlign: Alignment.center),
      ],
      rowCount: items.length,
      decoration: AdminWebUi.panelDecoration(),
      headStyle: AdminWebUi.webTableHead(context),
      onRowTap: (row) => () => _showReleaseDetail(context, items[row]),
      cellBuilder: (context, row, column) {
        final item = items[row];
        return switch (column) {
          0 => _versionCell(item),
          1 => _tableText(item.platform.toUpperCase()),
          2 => _StatusPill(status: item.status),
          3 => _tableText('${item.minSupportedVersionCode}'),
          4 => _tableText(fmtDate(item.createdAt), muted: true),
          5 => _releaseMenu(item),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  // Row-tap = read-only detail (safe). Status changes go through the ⋯ menu
  // (each with its own confirm guard) — never via a whole-row tap.
  void _showReleaseDetail(BuildContext context, AppReleaseAdminEntity item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
        title: Row(
          children: [
            Icon(item.platform.toLowerCase() == 'ios' ? Icons.apple : Icons.android,
                size: 20, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.s2),
            Expanded(
              child: Text('v${item.versionName}+${item.versionCode}', style: AdminWebUi.webH2(ctx)),
            ),
            _StatusPill(status: item.status),
            IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, size: 20)),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Platform', item.platform.toUpperCase()),
              _detailRow('Environment', item.environment),
              _detailRow('Update type', item.updateType),
              _detailRow('Force update', item.isForce ? 'Có' : 'Không'),
              _detailRow('Min version', '${item.minSupportedVersionCode}'),
              if (item.gitBranch != null && item.gitBranch!.isNotEmpty)
                _detailRow('Branch', item.gitBranch!),
              if (item.gitSha != null && item.gitSha!.isNotEmpty)
                _detailRow('Commit', item.gitSha!),
              if (item.ciRunId != null && item.ciRunId!.isNotEmpty)
                _detailRow('CI run', item.ciRunId!),
              _detailRow('Tạo', fmtDate(item.createdAt)),
              if (item.scheduledPublishAt != null)
                _detailRow('Lên lịch', fmtDate(item.scheduledPublishAt)),
              if (item.publishedAt != null)
                _detailRow('Publish', fmtDate(item.publishedAt)),
              if (item.changelog != null && item.changelog!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s3),
                const Text('Changelog',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.s1),
                Text(item.changelog!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
            ),
          ],
        ),
      );

  Widget _versionCell(AppReleaseAdminEntity item) => Row(children: [
        Icon(item.platform.toLowerCase() == 'ios' ? Icons.apple : Icons.android, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.s2),
        Flexible(child: _tableText('v${item.versionName}+${item.versionCode}', weight: FontWeight.w600)),
        if (item.isForce) ...[const SizedBox(width: AppSpacing.s2), _ForceBadge()],
      ]);

  Widget _releaseMenu(AppReleaseAdminEntity item) {
    final entries = <PopupMenuEntry<String>>[];
    if (item.status == 'pending_approval') {
      entries.add(_releaseMenuItem('approve', Icons.check_circle_outline, 'Approve'));
    }
    if (item.status == 'pending_approval' || item.status == 'approved' || item.status == 'scheduled') {
      entries.add(_releaseMenuItem('reject', Icons.cancel_outlined, 'Từ chối', danger: true));
    }
    if (item.status == 'approved') {
      entries.add(_releaseMenuItem('schedule', Icons.event_outlined, 'Lên lịch'));
    }
    if (item.status == 'approved' || item.status == 'scheduled') {
      entries.add(_releaseMenuItem('publish', Icons.rocket_launch_outlined, item.isForce ? 'Publish (FORCE)' : 'Publish', danger: item.isForce));
    }
    if (item.status == 'published') {
      entries.add(_releaseMenuItem('rollback', Icons.history, 'Rollback', danger: true));
    }
    return PopupMenuButton<String>(
      tooltip: 'Release actions',
      icon: const Icon(Icons.more_horiz, size: 20),
      onSelected: (value) {
        switch (value) {
          case 'approve': onApprove(item.id);
          case 'reject': onReject(item.id);
          case 'schedule': onSchedule(item.id);
          case 'publish': onPublish(item);
          case 'rollback': onRollback(item.id);
        }
      },
      itemBuilder: (_) => entries,
    );
  }

  PopupMenuItem<String> _releaseMenuItem(String value, IconData icon, String label, {bool danger = false}) {
    final color = danger ? AppColors.danger : AppColors.textPrimary;
    return PopupMenuItem(
      value: value,
      child: Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: AppSpacing.s2), Text(label, style: TextStyle(color: color))]),
    );
  }

  Widget _tableText(String value, {bool muted = false, FontWeight? weight}) => Text(
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
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outline),
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
    return Semantics(
      label: _kStatusLabel[status] ?? status,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: _statusBg(status),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          _kStatusLabel[status] ?? status,
          style: TextStyle(
              color: _statusFg(status),
              fontSize: 11,
              fontWeight: FontWeight.w700),
        ),
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
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.dangerBg),
      ),
      child: const Text('FORCE',
          style: TextStyle(
              color: AppColors.danger,
              fontSize: 10,
              fontWeight: FontWeight.w800)),
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: AppColors.outline),
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
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(color: AppColors.outline),
          ),
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}





