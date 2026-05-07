import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/entity/admin/app_release_admin_entity.dart';
import '../../../core/get_it/get_it.dart';
import '../../../core/theme/app_color.dart';
import 'bloc/release_management_bloc.dart';
import 'bloc/release_management_event.dart';
import 'bloc/release_management_state.dart';

class ReleaseManagementPage extends StatefulWidget {
  const ReleaseManagementPage({super.key});

  static const String routeName = 'ReleaseManagementPage';
  static const String routePath = '/admin/releases';

  @override
  State<ReleaseManagementPage> createState() => _ReleaseManagementPageState();
}

class _ReleaseManagementPageState extends State<ReleaseManagementPage> {
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'pending_approval';
  ReleaseSortBy _sortBy = ReleaseSortBy.createdAt;
  bool _sortDesc = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _rejectDialog(BuildContext context, String id) async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
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
            onPressed: () async {
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
    final scheduled = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    ).toUtc();
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
      context.read<ReleaseManagementBloc>().add(
            ReleaseActionRequested(action: 'publish', releaseId: item.id),
          );
      return;
    }

    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cảnh báo FORCE UPDATE'),
        content: const Text(
          'Bản phát hành này đang ở chế độ FORCE UPDATE và có thể chặn người dùng sử dụng ứng dụng nếu không cập nhật.\n\nBạn có chắc muốn tiếp tục publish?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tiếp tục')),
        ],
      ),
    );
    if (firstConfirm != true || !context.mounted) return;

    final codeCtrl = TextEditingController();
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận bước 2'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Nhập chính xác "FORCE" để xác nhận publish force update.'),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'FORCE',
              ),
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
    if (secondConfirm != true || !context.mounted) return;
    if (codeCtrl.text.trim().toUpperCase() != 'FORCE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Mã xác nhận không đúng'),
            backgroundColor: Colors.red),
      );
      return;
    }

    context.read<ReleaseManagementBloc>().add(
          ReleaseActionRequested(action: 'publish', releaseId: item.id),
        );
  }

  String _fmtDate(dynamic value) {
    if (value == null) return '-';
    final dt = DateTime.tryParse(value.toString());
    if (dt == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt.toLocal());
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'approved':
      case 'published':
        return const Color(0xFFDCFCE7);
      case 'pending_approval':
      case 'scheduled':
        return const Color(0xFFFEF3C7);
      case 'rejected':
      case 'archived':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _statusFg(String status) {
    switch (status) {
      case 'approved':
      case 'published':
        return const Color(0xFF166534);
      case 'pending_approval':
      case 'scheduled':
        return const Color(0xFF92400E);
      case 'rejected':
      case 'archived':
        return const Color(0xFF991B1B);
      default:
        return const Color(0xFF334155);
    }
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusBg(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _statusFg(status),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    VoidCallback? onRefresh,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (onRefresh != null)
                  SizedBox(
                    height: 30,
                    child: OutlinedButton.icon(
                      onPressed: onRefresh,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.outline),
                      ),
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text('Refresh'),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }

  Widget _buildReleaseItem(
    BuildContext context,
    ReleaseManagementBloc bloc,
    AppReleaseAdminEntity item,
  ) {
    final title = '${item.platform} • v${item.versionName}+${item.versionCode}';
    final meta =
        'min=${item.minSupportedVersionCode} • created=${_fmtDate(item.createdAt)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(item.status),
              if (item.isForce) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'FORCE',
                    style: TextStyle(
                      color: Color(0xFF991B1B),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (item.status == 'pending_approval')
                OutlinedButton(
                  onPressed: () => bloc.add(
                    ReleaseActionRequested(action: 'approve', releaseId: item.id),
                  ),
                  child: const Text('Approve'),
                ),
              if (item.status == 'pending_approval' ||
                  item.status == 'approved' ||
                  item.status == 'scheduled')
                OutlinedButton(
                  onPressed: () => _rejectDialog(context, item.id),
                  child: const Text('Reject'),
                ),
              if (item.status == 'approved')
                OutlinedButton(
                  onPressed: () => _scheduleDialog(context, item.id),
                  child: const Text('Schedule'),
                ),
              if (item.status == 'approved' || item.status == 'scheduled')
                FilledButton(
                  onPressed: () => _publishWithConfirm(context, item),
                  child: Text(item.isForce ? 'Publish (force)' : 'Publish'),
                ),
              if (item.status == 'published')
                TextButton(
                  onPressed: () => bloc.add(
                    ReleaseActionRequested(action: 'rollback', releaseId: item.id),
                  ),
                  child: const Text('Rollback'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReleaseManagementBloc>()
        ..add(ReleaseLoadRequested(status: _statusFilter)),
      child: BlocConsumer<ReleaseManagementBloc, ReleaseManagementState>(
        listener: (context, state) {
          if (state.status == ReleaseManagementStatus.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red),
            );
          } else if (state.status == ReleaseManagementStatus.actionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Thao tác thành công')),
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<ReleaseManagementBloc>();
          final isLoading = state.status == ReleaseManagementStatus.loading ||
              state.status == ReleaseManagementStatus.initial;
          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: AppBar(
              title: const Text('Release Management'),
              actions: [
                IconButton(
                  tooltip: 'Chạy publish theo lịch ngay',
                  onPressed: () => bloc.add(
                    ReleaseActionRequested(
                        action: 'publish-due-run', releaseId: ''),
                  ),
                  icon: const Icon(Icons.schedule_send),
                ),
                IconButton(
                  onPressed: () =>
                      bloc.add(ReleaseLoadRequested(status: _statusFilter)),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async =>
                  bloc.add(ReleaseLoadRequested(status: _statusFilter)),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionCard(
                                title: 'Filters & Controls',
                                onRefresh: () =>
                                    bloc.add(ReleaseLoadRequested(status: _statusFilter)),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 10,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text('Trạng thái:'),
                                              const SizedBox(width: 8),
                                              DropdownButton<String>(
                                                value: _statusFilter,
                                                items: const [
                                                  DropdownMenuItem(
                                                      value: 'pending_approval',
                                                      child:
                                                          Text('pending_approval')),
                                                  DropdownMenuItem(
                                                      value: 'approved',
                                                      child: Text('approved')),
                                                  DropdownMenuItem(
                                                      value: 'scheduled',
                                                      child: Text('scheduled')),
                                                  DropdownMenuItem(
                                                      value: 'published',
                                                      child: Text('published')),
                                                  DropdownMenuItem(
                                                      value: 'rejected',
                                                      child: Text('rejected')),
                                                  DropdownMenuItem(
                                                      value: 'archived',
                                                      child: Text('archived')),
                                                ],
                                                onChanged: (v) {
                                                  if (v == null) return;
                                                  setState(() => _statusFilter = v);
                                                  bloc.add(
                                                      ReleaseLoadRequested(status: v));
                                                },
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text('Sort:'),
                                              const SizedBox(width: 8),
                                              DropdownButton<ReleaseSortBy>(
                                                value: _sortBy,
                                                items: const [
                                                  DropdownMenuItem(
                                                      value: ReleaseSortBy.createdAt,
                                                      child: Text('createdAt')),
                                                  DropdownMenuItem(
                                                      value:
                                                          ReleaseSortBy.versionCode,
                                                      child: Text('versionCode')),
                                                  DropdownMenuItem(
                                                      value: ReleaseSortBy.status,
                                                      child: Text('status')),
                                                ],
                                                onChanged: (v) {
                                                  if (v == null) return;
                                                  setState(() => _sortBy = v);
                                                  bloc.add(ReleaseSortChanged(
                                                      sortBy: _sortBy,
                                                      descending: _sortDesc));
                                                },
                                              ),
                                              IconButton(
                                                tooltip: _sortDesc
                                                    ? 'Giảm dần'
                                                    : 'Tăng dần',
                                                onPressed: () {
                                                  setState(
                                                      () => _sortDesc = !_sortDesc);
                                                  bloc.add(ReleaseSortChanged(
                                                      sortBy: _sortBy,
                                                      descending: _sortDesc));
                                                },
                                                icon: Icon(_sortDesc
                                                    ? Icons.south
                                                    : Icons.north),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      TextField(
                                        controller: _searchCtrl,
                                        decoration: const InputDecoration(
                                          prefixIcon: Icon(Icons.search),
                                          hintText:
                                              'Tìm theo version, status, commit SHA...',
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (v) =>
                                            bloc.add(ReleaseSearchChanged(v)),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          for (final key in const [
                                            'pending_approval',
                                            'approved',
                                            'scheduled',
                                            'published',
                                            'rejected',
                                            'archived'
                                          ])
                                            Chip(
                                              label: Text(
                                                  '$key: ${state.statusCounts[key] ?? 0}'),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _sectionCard(
                                title:
                                    'Releases (${state.visibleReleases.length})',
                                child: isLoading
                                    ? const Padding(
                                        padding: EdgeInsets.all(28),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    : state.visibleReleases.isEmpty
                                        ? const Padding(
                                            padding: EdgeInsets.all(22),
                                            child: Text(
                                              'Không có release theo bộ lọc hiện tại.',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          )
                                        : Column(
                                            children: [
                                              for (final item
                                                  in state.visibleReleases)
                                                _buildReleaseItem(
                                                    context, bloc, item),
                                            ],
                                          ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
