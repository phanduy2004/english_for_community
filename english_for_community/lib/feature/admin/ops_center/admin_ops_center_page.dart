import 'package:english_for_community/core/theme/admin_status_palette.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/feature/admin/dashboard_home/admin_dashboard.dart';
import 'package:english_for_community/feature/admin/layout/admin_page_scaffold.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:english_for_community/feature/admin/layout/admin_skeleton.dart';
import 'package:english_for_community/feature/admin/layout/admin_widgets.dart';
import 'package:english_for_community/core/ui/widget/web_data_table.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/datasource/admin_remote_datasource.dart';
import '../../../core/get_it/get_it.dart';

class AdminOpsCenterPage extends StatefulWidget {
  const AdminOpsCenterPage({super.key});

  static const String routeName = 'AdminOpsCenterPage';
  static const String routePath = '/admin/ops-center';

  @override
  State<AdminOpsCenterPage> createState() => _AdminOpsCenterPageState();
}

class _AdminOpsCenterPageState extends State<AdminOpsCenterPage> {
  final _datasource = getIt<AdminRemoteDatasource>();
  bool _loadingQueue = true;
  bool _loadingPerms = true;
  List<Map<String, dynamic>> _queue = const [];
  Map<String, dynamic> _permissionMatrix = const {};
  String? _error;
  
  final TextEditingController _queueSearchCtrl = TextEditingController();
  final TextEditingController _csvSearchCtrl = TextEditingController();

  String _queuePriorityFilter = 'all';
  String _queueSlaFilter = 'all';
  int _queueRowsPerPage = 8;
  int _queuePage = 1;

  List<List<String>> _csvRows = const [];
  String _csvTitle = '';
  int _csvPage = 1;
  int _csvRowsPerPage = 15;

  int get _breachedCount => _queue.where((item) {
        final triage = Map<String, dynamic>.from(item['triage'] as Map? ?? const {});
        return triage['isSlaBreached'] == true;
      }).length;

  int get _highPriorityCount => _queue.where((item) {
        final triage = Map<String, dynamic>.from(item['triage'] as Map? ?? const {});
        return (triage['priority'] ?? '').toString() == 'high';
      }).length;

  List<Map<String, dynamic>> get _filteredQueue {
    final query = _queueSearchCtrl.text.trim().toLowerCase();
    return _queue.where((item) {
      final triage = Map<String, dynamic>.from(item['triage'] as Map? ?? const {});
      final title = (item['title'] ?? '').toString().toLowerCase();
      final type = (item['type'] ?? '').toString().toLowerCase();
      final priority = (triage['priority'] ?? '').toString().toLowerCase();
      final isBreached = triage['isSlaBreached'] == true;
      final passText = query.isEmpty || title.contains(query) || type.contains(query);
      final passPriority = _queuePriorityFilter == 'all' || priority == _queuePriorityFilter;
      final passSla = _queueSlaFilter == 'all' || (_queueSlaFilter == 'breached' ? isBreached : !isBreached);
      return passText && passPriority && passSla;
    }).toList();
  }

  /// API now returns `{ roles: [...], defaults: { role: [...] }, allPermissions: [...] }`.
  List<Map<String, dynamic>> get _permissionRows {
    final defaults = Map<String, dynamic>.from(
      (_permissionMatrix['defaults'] as Map<String, dynamic>?) ?? const {},
    );
    if (defaults.isEmpty) return const [];
    return defaults.entries.map((entry) {
      final perms = entry.value is List
          ? (entry.value as List).map((e) => e.toString()).toList()
          : <String>[];
      return {'role': entry.key, 'permissions': perms};
    }).toList();
  }

  List<String> get _allPermissions {
    final list = _permissionMatrix['allPermissions'];
    if (list is List) return list.map((e) => e.toString()).toList();
    return const [];
  }

  List<List<String>> get _filteredCsvRows {
    if (_csvRows.isEmpty) return const [];
    final headers = _csvRows.first;
    final query = _csvSearchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _csvRows;
    final rows = _csvRows.skip(1).where((row) => row.any((cell) => cell.toLowerCase().contains(query))).toList();
    return [headers, ...rows];
  }

  @override
  void initState() {
    super.initState();
    _queueSearchCtrl.addListener(() => setState(() => _queuePage = 1));
    _csvSearchCtrl.addListener(() => setState(() => _csvPage = 1));
    _loadAll();
  }

  @override
  void dispose() {
    _queueSearchCtrl.dispose();
    _csvSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadQueue(), _loadPermissions()]);
  }

  Future<void> _loadQueue() async {
    setState(() => _loadingQueue = true);
    try {
      final data = await _datasource.getModerationQueue(limit: 200);
      if (!mounted) return;
      setState(() {
        _queue = data;
        _queuePage = 1;
        _loadingQueue = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingQueue = false;
      });
    }
  }

  Future<void> _loadPermissions() async {
    setState(() => _loadingPerms = true);
    try {
      final data = await _datasource.getPermissionMatrix();
      if (!mounted) return;
      setState(() {
        _permissionMatrix = data;
        _loadingPerms = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingPerms = false;
      });
    }
  }

  Future<void> _previewCsv(String resource, {bool onlyDeleted = false}) async {
    final csv = await _datasource.exportCsvPreview(resource: resource, onlyDeleted: onlyDeleted);
    if (!mounted) return;
    final rows = _parseCsv(csv, maxRows: 1000);
    setState(() {
      _csvRows = rows;
      _csvTitle = resource.toUpperCase();
      _csvPage = 1;
      _csvSearchCtrl.clear();
    });
    _openCsvDialog();
  }

  void _openCsvDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final rows = _filteredCsvRows;
            final rawHeaders = rows.isEmpty ? const <String>[] : rows.first;
            final displayHeaders = rawHeaders.map(_prettyCsvHeader).toList();
            final dataRows = rows.isEmpty ? const <List<String>>[] : rows.skip(1).toList();
            final totalPages = (dataRows.length / _csvRowsPerPage).ceil().clamp(1, 9999);
            final page = _csvPage.clamp(1, totalPages);
            final start = (page - 1) * _csvRowsPerPage;
            final end = (start + _csvRowsPerPage).clamp(0, dataRows.length);
            final pagedRows = dataRows.isEmpty ? const <List<String>>[] : dataRows.sublist(start, end);
            final totalCells = dataRows.fold<int>(0, (sum, row) => sum + row.length);
            final emptyCells = dataRows.fold<int>(0, (sum, row) => sum + row.where((c) => c.trim().isEmpty).length);
            final filled = totalCells == 0 ? 100 : (((totalCells - emptyCells) / totalCells) * 100).round();

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
              backgroundColor: AppColors.surfaceCard,
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040, maxHeight: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header — dataset title + a one-line stats summary.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.s5, AppSpacing.s4, AppSpacing.s3, AppSpacing.s4),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(AppRadius.input),
                              border: Border.all(color: AppColors.outlineMuted),
                            ),
                            child: const Icon(Icons.table_chart_outlined, size: 17, color: AppColors.textPrimary),
                          ),
                          const SizedBox(width: AppSpacing.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_csvDialogTitle(_csvTitle), style: AdminWebUi.webH2(context)),
                                const SizedBox(height: 1),
                                Text(
                                  '${rawHeaders.length} columns · ${dataRows.length} rows · $filled% filled',
                                  style: AdminWebUi.metaMuted,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.outlineMuted),

                    // Toolbar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.s5, AppSpacing.s3, AppSpacing.s5, AppSpacing.s3),
                      child: Row(
                        children: [
                          AdminSearchField(
                            controller: _csvSearchCtrl,
                            hint: 'Search by value, email, status',
                            width: 300,
                            onChanged: (_) {
                              setState(() => _csvPage = 1);
                              setDialogState(() {});
                            },
                          ),
                          const Spacer(),
                          Text(
                            dataRows.isEmpty ? '0 rows' : 'Showing ${start + 1}–$end of ${dataRows.length}',
                            style: AdminWebUi.metaMuted,
                          ),
                        ],
                      ),
                    ),

                    // Body — data grid (horizontal + vertical scroll) or empty state.
                    Expanded(
                      child: dataRows.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.s6),
                                child: AdminEmptyCard(
                                  message: _csvSearchCtrl.text.trim().isEmpty
                                      ? 'This dataset has no rows.'
                                      : 'No rows match your search.',
                                  icon: Icons.search_off_outlined,
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.surface,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columnSpacing: AppSpacing.s6,
                                    headingRowHeight: 42,
                                    dataRowMinHeight: 40,
                                    dataRowMaxHeight: 54,
                                    dividerThickness: 1,
                                    headingRowColor: WidgetStateProperty.all(AppColors.surfaceSubtle),
                                    columns: [
                                      for (var i = 0; i < displayHeaders.length; i++)
                                        DataColumn(
                                          numeric: _csvColumnHint(rawHeaders[i]) == 'numeric',
                                          label: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(displayHeaders[i], style: AdminWebUi.webTableHead(context)),
                                              if (_csvColumnHint(rawHeaders[i]).isNotEmpty)
                                                Text(_csvColumnHint(rawHeaders[i]), style: AdminWebUi.metaMuted),
                                            ],
                                          ),
                                        ),
                                    ],
                                    rows: [
                                      for (final row in pagedRows)
                                        DataRow(
                                          cells: [
                                            for (var i = 0; i < rawHeaders.length; i++)
                                              DataCell(_buildCsvDataCell(rawHeaders[i], i < row.length ? row[i] : '')),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                    const Divider(height: 1, color: AppColors.outlineMuted),

                    // Footer
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s3),
                      child: AdminPaginationBar(
                        page: page,
                        totalPages: totalPages,
                        totalRows: dataRows.length,
                        rowsPerPage: _csvRowsPerPage,
                        rowsPerPageOptions: const [5, 8, 10, 15, 20, 50],
                        onRowsPerPageChanged: (value) {
                          setState(() {
                            _csvRowsPerPage = value;
                            _csvPage = 1;
                          });
                          setDialogState(() {});
                        },
                        onPageChanged: (next) {
                          setState(() => _csvPage = next);
                          setDialogState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _csvDialogTitle(String key) {
    switch (key.toUpperCase()) {
      case 'USERS':
        return 'Export: Users';
      case 'REPORTS':
        return 'Export: Reports';
      case 'AUDIT_LOGS':
        return 'Export: Audit logs';
      default:
        return 'Export: $key';
    }
  }

  String _prettyCsvHeader(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return '—';
    const aliases = {
      'id': 'Record ID',
      'user_id': 'User ID',
      'report_id': 'Report ID',
      'created_at': 'Created Time',
      'updated_at': 'Updated Time',
      'deleted_at': 'Deleted Time',
      'email': 'Email Address',
      'full_name': 'Full Name',
      'phone': 'Phone Number',
      'is_banned': 'Banned',
      'is_verified': 'Verified',
      'admin_response': 'Admin Note',
      'target_type': 'Target Type',
      'target_id': 'Target ID',
      'actor_role': 'Actor Role',
      'actor_email': 'Actor Email',
      'user_agent': 'Browser / Device',
    };
    final key = s.toLowerCase();
    if (aliases.containsKey(key)) return aliases[key]!;
    final spaced = s
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ');
    if (spaced.length <= 1) return spaced.toUpperCase();
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  String _csvColumnHint(String rawHeader) {
    final h = rawHeader.toLowerCase();
    if (_isIdLikeColumn(rawHeader)) return 'system identifier';
    if (h.contains('status')) return 'workflow state';
    if (h.contains('role')) return 'user role';
    if (h.contains('email')) return 'contact';
    if (h.contains('phone')) return 'contact';
    if (h.contains('created') || h.contains('updated') || h.contains('date') || h.contains('time')) return 'date & time';
    if (h.contains('score') || h.contains('count') || h.contains('total') || h.contains('duration')) return 'numeric';
    if (h.startsWith('is_') || h.startsWith('has_')) return 'yes / no';
    return '';
  }

  bool _isIdLikeColumn(String header) {
    final h = header.toLowerCase();
    return h == 'id' || h.endsWith('id') || h.contains('_id');
  }

  String _formatCsvCell(String header, String raw) {
    final v = raw.trim();
    if (v.isEmpty) return '—';
    final h = header.toLowerCase();
    const statusMap = {
      'pending': 'Pending',
      'resolved': 'Resolved',
      'rejected': 'Rejected',
      'approved': 'Approved',
      'active': 'Active',
      'inactive': 'Inactive',
      'deleted': 'Deleted',
      'banned': 'Banned',
      'unbanned': 'Unbanned',
    };

    if (v == 'true' || v == 'false') return v == 'true' ? 'Yes' : 'No';
    if (statusMap.containsKey(v.toLowerCase())) return statusMap[v.toLowerCase()]!;

    if ((h.contains('at') || h.contains('date') || h == 'created' || h == 'updated') &&
        (v.contains('T') || RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(v))) {
      final dt = DateTime.tryParse(v.replaceAll(' ', 'T'));
      if (dt != null) {
        return DateFormat('dd/MM/yyyy HH:mm').format(dt.toLocal());
      }
    }

    if (RegExp(r'^-?\d+(\.\d+)?$').hasMatch(v) &&
        (h.contains('count') || h.contains('total') || h.contains('score') || h.contains('age') || h.contains('hours'))) {
      final number = num.tryParse(v);
      if (number != null) {
        return NumberFormat('#,##0.##').format(number);
      }
    }

    if (_isIdLikeColumn(header) && v.length > 14) {
      return '${v.substring(0, 8)}…${v.substring(v.length - 4)}';
    }

    if (v.length > 64) {
      return '${v.substring(0, 61)}…';
    }
    return v;
  }

  Widget _buildCsvDataCell(String rawHeader, String rawValue) {
    final formatted = _formatCsvCell(rawHeader, rawValue);
    final h = rawHeader.toLowerCase();
    final isStatus = h.contains('status') || h.contains('decision');
    final isBoolean = rawValue == 'true' || rawValue == 'false';
    if (isStatus || isBoolean) {
      final colors = AdminStatusPalette.csvSemanticColors(rawValue);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: colors.bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Text(
          formatted,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.fg),
        ),
      );
    }

    final textWidget = SelectableText(
      formatted,
      style: TextStyle(
        fontSize: 12,
        fontFamily: _isIdLikeColumn(rawHeader) ? 'monospace' : null,
        color: AppColors.textSecondary,
      ),
    );
    if (formatted != rawValue && rawValue.length > 24) {
      return Tooltip(message: rawValue, child: textWidget);
    }
    return textWidget;
  }

  String _prettyModerationType(String raw) {
    final s = raw.replaceAll('-', '_').trim();
    if (s.isEmpty) return 'Other';
    final spaced = s
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ');
    if (spaced.length <= 1) return spaced.toUpperCase();
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  List<List<String>> _parseCsv(String csv, {int maxRows = 50}) {
    final lines = csv.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).take(maxRows).toList();
    return lines.map(_splitCsvLine).toList();
  }

  List<String> _splitCsvLine(String line) {
    final fields = <String>[];
    final current = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        fields.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }
    fields.add(current.toString());
    return fields;
  }


  Widget _buildQueueBody(
    List<Map<String, dynamic>> filteredQueue,
    List<Map<String, dynamic>> pageRows,
    int page,
    int totalPages,
  ) {
    void clear() => setState(() {
          _queueSearchCtrl.clear();
          _queuePriorityFilter = 'all';
          _queueSlaFilter = 'all';
          _queuePage = 1;
        });
    final hasFilter = _queuePriorityFilter != 'all' ||
        _queueSlaFilter != 'all' ||
        _queueSearchCtrl.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Wrap(
            spacing: AppSpacing.s3,
            runSpacing: AppSpacing.s3,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AdminSearchField(controller: _queueSearchCtrl, hint: 'Search by title or type', width: 260),
              SizedBox(
                width: 150,
                child: _CompactDropdown(
                  value: _queuePriorityFilter,
                  items: const {'all': 'All priorities', 'high': 'High', 'medium': 'Medium', 'low': 'Low'},
                  onChanged: (v) => setState(() {
                    _queuePriorityFilter = v!;
                    _queuePage = 1;
                  }),
                ),
              ),
              SizedBox(
                width: 150,
                child: _CompactDropdown(
                  value: _queueSlaFilter,
                  items: const {'all': 'All SLA', 'breached': 'Breached', 'ontime': 'On track'},
                  onChanged: (v) => setState(() {
                    _queueSlaFilter = v!;
                    _queuePage = 1;
                  }),
                ),
              ),
              if (hasFilter)
                TextButton(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: clear,
                  child: Text('Clear filters', style: AdminWebUi.webCaption(context)),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.outlineMuted),
        if (_queue.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.s5),
            child: AdminEmptyCard(message: 'No items in the moderation queue.'),
          )
        else if (filteredQueue.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s5),
            child: AdminEmptyCard(
              message: 'No items match the current filters.',
              icon: Icons.filter_alt_off_outlined,
              actionLabel: 'Clear filters',
              onAction: clear,
            ),
          )
        else ...[
          WebDataTable(
            columns: const [
              WebTableColumn(label: 'Title', flex: 4),
              WebTableColumn(label: 'Type', width: 130),
              WebTableColumn(label: 'Priority', width: 110),
              WebTableColumn(label: 'Age (h)', width: 90, align: Alignment.centerRight, headAlign: Alignment.centerRight),
              WebTableColumn(label: 'SLA', width: 120),
            ],
            rowCount: pageRows.length,
            decoration: const BoxDecoration(),
            headStyle: AdminWebUi.webTableHead(context),
            cellBuilder: (context, row, col) {
              final item = pageRows[row];
              final triage = Map<String, dynamic>.from(item['triage'] as Map? ?? const {});
              final priority = (triage['priority'] ?? 'low').toString();
              final ageRaw = triage['ageHours'];
              final age = ageRaw is num
                  ? ageRaw.toStringAsFixed(ageRaw % 1 == 0 ? 0 : 1)
                  : (ageRaw ?? '0').toString();
              final isBreached = triage['isSlaBreached'] == true;
              final rawTitle = (item['title'] ?? '').toString().trim();
              return switch (col) {
                0 => rawTitle.isEmpty
                    ? Text('Untitled', style: AdminWebUi.webBody(context).copyWith(color: AppColors.textMuted))
                    : Text(rawTitle, style: AdminWebUi.webBody(context).copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                1 => Text(_prettyModerationType((item['type'] ?? 'other').toString()), style: AdminWebUi.webBody(context).copyWith(color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                2 => _StatusPill.priority(priority),
                3 => Text(age, style: AdminWebUi.webBody(context).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                4 => isBreached
                    ? const _StatusPill(text: 'Breached', bg: AppColors.dangerBg, fg: AppColors.danger)
                    : const _StatusPill(text: 'On track', bg: AppColors.successBg, fg: AppColors.success),
                _ => const SizedBox.shrink(),
              };
            },
          ),
          const Divider(height: 1, color: AppColors.outlineMuted),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s3),
            child: AdminPaginationBar(
              page: page,
              totalPages: totalPages,
              totalRows: filteredQueue.length,
              rowsPerPage: _queueRowsPerPage,
              rowsPerPageOptions: const [5, 8, 10, 15, 20, 50],
              onRowsPerPageChanged: (v) => setState(() {
                _queueRowsPerPage = v;
                _queuePage = 1;
              }),
              onPageChanged: (next) => setState(() => _queuePage = next),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredQueue = _filteredQueue;
    final queueTotalPages = (filteredQueue.length / _queueRowsPerPage).ceil().clamp(1, 9999);
    final queuePage = _queuePage.clamp(1, queueTotalPages);
    final queueStart = (queuePage - 1) * _queueRowsPerPage;
    final queueEnd = (queueStart + _queueRowsPerPage).clamp(0, filteredQueue.length);
    final queuePageRows = filteredQueue.sublist(queueStart, queueEnd);

    final permissionRows = _permissionRows;
    final allPerms = _allPermissions;

    final l10n = context.l10n;
    return AdminPageScaffold(
      title: l10n.adminNavOps,
      subtitle: l10n.adminNavOpsSub,
      scrollable: false,
      maxWidth: AdminWebUi.contentMaxTable,
      breadcrumbs: [
        AdminBreadcrumb(label: l10n.adminOverviewTitle, location: AdminDashboardPage.routePath),
        AdminBreadcrumb(label: l10n.adminNavOps),
      ],
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6, vertical: AppSpacing.s5),
          children: [
            // KPI health strip — replaces the duplicate in-body page title.
            AdminKpiGrid(
              children: [
                AdminKpiCard(icon: Icons.inbox_outlined, value: _queue.length.toString(), label: 'Pending review', meta: 'In the moderation queue', accent: AppColors.info),
                AdminKpiCard(icon: Icons.priority_high_rounded, value: _highPriorityCount.toString(), label: 'High priority', meta: 'Need attention first', accent: AppColors.warning),
                AdminKpiCard(icon: Icons.timer_off_outlined, value: _breachedCount.toString(), label: 'SLA breached', meta: 'Past the response window', accent: AppColors.danger),
              ],
            ),
            const SizedBox(height: AppSpacing.s7),
            if (_error != null) ...[
              AdminEmptyCard(message: _error!, icon: Icons.error_outline, actionLabel: 'Retry', onAction: _loadAll),
              const SizedBox(height: AppSpacing.s5),
            ],

            // Moderation queue
            _OpsPanel(
              title: 'Moderation queue',
              subtitle: 'Reports and flagged items awaiting a decision',
              onRefresh: _loadQueue,
              child: _loadingQueue
                  ? Padding(padding: const EdgeInsets.all(AppSpacing.s5), child: AdminSkeleton.table(rows: 6))
                  : _buildQueueBody(filteredQueue, queuePageRows, queuePage, queueTotalPages),
            ),
            const SizedBox(height: AppSpacing.s7),

            // Data export
            _OpsPanel(
              title: 'Data export (CSV)',
              subtitle: 'Preview cleans and explains every column before download',
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pick a dataset. The preview renames raw fields to plain labels so the file is easy to read.',
                      style: AdminWebUi.webCaption(context),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    AdminCardGrid(
                      children: [
                        _ExportCard(icon: Icons.group_outlined, title: 'Active users', subtitle: 'Current, non-deleted accounts', points: const ['Profile & contact info', 'Learning progress', 'Account flags & status'], onPreview: () => _previewCsv('users')),
                        _ExportCard(icon: Icons.restore_from_trash_outlined, title: 'Deleted users', subtitle: 'Soft-deleted accounts', points: const ['When it was deleted', 'Basic profile', 'Recovery eligibility'], onPreview: () => _previewCsv('users', onlyDeleted: true)),
                        _ExportCard(icon: Icons.flag_outlined, title: 'Issue reports', subtitle: 'User report tickets', points: const ['Report type & reason', 'Current status', 'Admin response'], onPreview: () => _previewCsv('reports')),
                        _ExportCard(icon: Icons.fact_check_outlined, title: 'Audit logs', subtitle: 'Admin action history', points: const ['Action performed', 'Who did it', 'Target & timestamp'], onPreview: () => _previewCsv('audit_logs')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s7),

            // Roles & permissions
            _OpsPanel(
              title: 'Roles & permissions',
              subtitle: 'What each role can do',
              onRefresh: _loadPermissions,
              child: _loadingPerms
                  ? Padding(padding: const EdgeInsets.all(AppSpacing.s5), child: AdminSkeleton.table(rows: 2))
                  : permissionRows.isEmpty
                      ? const Padding(padding: EdgeInsets.all(AppSpacing.s5), child: AdminEmptyCard(message: 'No permission data yet.'))
                      : Padding(
                          padding: const EdgeInsets.all(AppSpacing.s5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(AppRadius.input),
                                  border: Border.all(color: AppColors.outlineMuted),
                                ),
                                child: Text(
                                  'There are two roles: Admin (full access) and User (no admin access). To promote or demote someone, open Users → user details.',
                                  style: AdminWebUi.webCaption(context),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.s4),
                              for (final row in permissionRows) ...[
                                _RoleCard(
                                  role: row['role'].toString(),
                                  permissions: (row['permissions'] as List).cast<String>(),
                                  allPermissions: allPerms,
                                ),
                                const SizedBox(height: AppSpacing.s3),
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET COMPONENTS THU GỌN ---

class _CompactDropdown extends StatelessWidget {
  const _CompactDropdown({required this.value, required this.items, required this.onChanged});
  final String value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
      icon: const Icon(Icons.arrow_drop_down, size: 20),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.chip), borderSide: const BorderSide(color: AppColors.outline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.chip), borderSide: const BorderSide(color: AppColors.outline)),
        filled: true,
        fillColor: AppColors.surfaceCard,
        isDense: true,
      ),
      items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
      onChanged: onChanged,
    );
  }
}

/// Semantic status pill (priority / SLA) — tinted, never row-tint.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.bg, required this.fg});
  final String text;
  final Color bg;
  final Color fg;

  factory _StatusPill.priority(String p) {
    final (Color b, Color f, String label) = switch (p) {
      'high' => (AdminStatusPalette.highBg, AdminStatusPalette.highFg, 'High'),
      'medium' => (AdminStatusPalette.medBg, AdminStatusPalette.medFg, 'Medium'),
      'low' => (AdminStatusPalette.lowBg, AdminStatusPalette.lowFg, 'Low'),
      _ => (AppColors.surfaceSubtle, AppColors.textSecondary, p.isEmpty ? '—' : p),
    };
    return _StatusPill(text: label, bg: b, fg: f);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Status: $text',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Text(
          text,
          style: AdminWebUi.webCaption(context).copyWith(color: fg, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

/// Export dataset card — neutral (Editorial Black: no decorative color).
/// The whole card is the single tap target; the Preview chip is its affordance.
class _ExportCard extends StatelessWidget {
  const _ExportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.onPreview,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> points;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Preview $title export',
      child: AdminWebUi.focusableTile(
        onTap: onPreview,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          decoration: AdminWebUi.panelDecoration(),
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      border: Border.all(color: AppColors.outlineMuted),
                    ),
                    child: Icon(icon, size: 17, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AdminWebUi.webBody(context).copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 1),
                        Text(subtitle, style: AdminWebUi.metaMuted, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s3),
              for (final point in points)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      const Icon(Icons.check, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: AppSpacing.s2),
                      Expanded(child: Text(point, style: AdminWebUi.webCaption(context))),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.s2),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    border: Border.all(color: AppColors.outlineMuted),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.visibility_outlined, size: 14, color: AppColors.textPrimary),
                      const SizedBox(width: AppSpacing.s2),
                      Text(
                        'Preview',
                        style: AdminWebUi.webCaption(context).copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Titled section — flat panel (border only), token header + optional refresh.
class _OpsPanel extends StatelessWidget {
  const _OpsPanel({required this.title, required this.child, this.subtitle, this.onRefresh});
  final String title;
  final Widget child;
  final String? subtitle;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AdminWebUi.panelDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.s5, AppSpacing.s4, AppSpacing.s4, AppSpacing.s4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AdminWebUi.webH2(context)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(subtitle!, style: AdminWebUi.metaMuted),
                      ],
                    ],
                  ),
                ),
                if (onRefresh != null)
                  OutlinedButton.icon(
                    style: AdminWebUi.compactOutlinedStyle(context),
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh, size: 15),
                    label: const Text('Refresh'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.outlineMuted),
          child,
        ],
      ),
    );
  }
}

/// Role access badge — Admin = authority (navy tint), User = neutral. Never danger red.
class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.admin});
  final bool admin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: 2),
      decoration: BoxDecoration(
        color: admin ? AppColors.primaryTint : AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        admin ? 'Full access' : 'No admin access',
        style: AdminWebUi.webCaption(context).copyWith(
          color: admin ? AppColors.primaryDark : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Role row — neutral icon tile + authority badge + a granted/denied permission matrix.
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.permissions,
    required this.allPermissions,
  });
  final String role;
  final List<String> permissions;
  final List<String> allPermissions;

  @override
  Widget build(BuildContext context) {
    final isWildcard = permissions.contains('*');
    final isAdmin = role == 'admin' || isWildcard;
    final displayRole = role.isEmpty ? role : '${role[0].toUpperCase()}${role.substring(1)}';
    final perms = allPermissions.isNotEmpty ? allPermissions : permissions.where((p) => p != '*').toList();
    bool granted(String p) => isWildcard || permissions.contains(p);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  border: Border.all(color: AppColors.outlineMuted),
                ),
                child: Icon(isAdmin ? Icons.shield_outlined : Icons.person_outline, size: 17, color: AppColors.textPrimary),
              ),
              const SizedBox(width: AppSpacing.s3),
              Text(displayRole, style: AdminWebUi.webBody(context).copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: AppSpacing.s3),
              _RoleBadge(admin: isAdmin),
            ],
          ),
          if (perms.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s3),
            Wrap(
              spacing: AppSpacing.s2,
              runSpacing: AppSpacing.s2,
              children: [for (final p in perms) _PermChip(label: p, granted: granted(p))],
            ),
          ],
        ],
      ),
    );
  }
}

/// Permission chip — granted (check/success) vs denied (dash/muted).
class _PermChip extends StatelessWidget {
  const _PermChip({required this.label, required this.granted});
  final String label;
  final bool granted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: 3),
      decoration: BoxDecoration(
        color: granted ? AppColors.successBg : AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(granted ? Icons.check : Icons.remove, size: 12, color: granted ? AppColors.success : AppColors.textMuted),
          const SizedBox(width: 5),
          Text(
            label,
            style: AdminWebUi.webCaption(context).copyWith(
              color: granted ? AppColors.success : AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


