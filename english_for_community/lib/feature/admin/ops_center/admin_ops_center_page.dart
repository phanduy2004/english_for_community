import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/feature/admin/dashboard_home/admin_dashboard.dart';
import 'package:english_for_community/feature/admin/layout/admin_page_scaffold.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
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
            if (rows.isEmpty) {
              return AlertDialog(
                title: Text('CSV Preview: $_csvTitle', style: const TextStyle(fontSize: 16)),
                content: const Text('No data found.', style: TextStyle(fontSize: 14)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                ],
              );
            }

            final rawHeaders = rows.first;
            final displayHeaders = rawHeaders.map(_prettyCsvHeader).toList();
            final dataRows = rows.skip(1).toList();
            final totalPages = (dataRows.length / _csvRowsPerPage).ceil().clamp(1, 9999);
            final page = _csvPage.clamp(1, totalPages);
            final start = (page - 1) * _csvRowsPerPage;
            final end = (start + _csvRowsPerPage).clamp(0, dataRows.length);
            final pagedRows = dataRows.sublist(start, end);
            final totalCells = dataRows.fold<int>(0, (sum, row) => sum + row.length);
            final emptyCells = dataRows.fold<int>(
              0,
              (sum, row) => sum + row.where((c) => c.trim().isEmpty).length,
            );
            final dataCompletion = totalCells == 0 ? 100 : (((totalCells - emptyCells) / totalCells) * 100).round();

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.white,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- HEADER ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                      child: Row(
                        children: [
                          Icon(Icons.table_chart_outlined, color: Colors.blueGrey[700], size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _csvDialogTitle(_csvTitle),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            splashRadius: 20,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),

                    // --- TOOLBAR ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _csvSearchCtrl,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: _inputDecoration('Search by value, email, status...'),
                                  onChanged: (_) {
                                    setState(() => _csvPage = 1);
                                    setDialogState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                dataRows.isEmpty
                                    ? '0 rows'
                                    : 'Rows ${start + 1}–$end of ${dataRows.length}',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _DialogMetricPill(label: 'Columns', value: rawHeaders.length.toString(), icon: Icons.view_week_outlined),
                              const SizedBox(width: 8),
                              _DialogMetricPill(label: 'Rows', value: dataRows.length.toString(), icon: Icons.table_rows_outlined),
                              const SizedBox(width: 8),
                              _DialogMetricPill(label: 'Data quality', value: '$dataCompletion%', icon: Icons.verified_outlined),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // --- TABLE ---
                    Expanded(
                      child: Container(
                        color: const Color(0xFFF8FAFC),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 20,
                              headingRowHeight: 44,
                              dataRowMinHeight: 40,
                              dataRowMaxHeight: 56,
                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                              columns: displayHeaders
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                    final h = entry.value;
                                    final idx = entry.key;
                                    final hint = _csvColumnHint(rawHeaders[idx]);
                                    return DataColumn(
                                        label: Text(
                                          hint.isEmpty ? h : '$h\n$hint',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: hint.isEmpty ? 12 : 11,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                      );
                                  })
                                  .toList(),
                              rows: pagedRows
                                  .map((row) => DataRow(
                                        cells: rawHeaders.asMap().entries.map((entry) {
                                          final rawHeader = entry.value;
                                          final text = entry.key < row.length ? row[entry.key] : '';
                                          return DataCell(_buildCsvDataCell(rawHeader, text));
                                        }).toList(),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),

                    // --- FOOTER ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: _PaginationBar(
                        page: page,
                        totalPages: totalPages,
                        totalRows: dataRows.length,
                        rowsPerPage: _csvRowsPerPage,
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
    final lower = rawValue.toLowerCase();
    final isStatus = h.contains('status') || h.contains('decision');
    final isBoolean = rawValue == 'true' || rawValue == 'false';
    if (isStatus || isBoolean) {
      Color bg = const Color(0xFFF1F5F9);
      Color fg = const Color(0xFF334155);
      if (lower == 'approved' || lower == 'resolved' || lower == 'active' || lower == 'true') {
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
      } else if (lower == 'rejected' || lower == 'banned' || lower == 'deleted' || lower == 'false') {
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
      } else if (lower == 'pending' || lower == 'inactive') {
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(
          formatted,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
        ),
      );
    }

    final textWidget = SelectableText(
      formatted,
      style: TextStyle(
        fontSize: 12,
        fontFamily: _isIdLikeColumn(rawHeader) ? 'monospace' : null,
        color: const Color(0xFF334155),
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


  // --- REUSABLE STYLES ---
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.black45),
      prefixIcon: const Icon(Icons.search, size: 18, color: Colors.black45),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: [
            // --- HEADER OVERVIEW ---
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Monitor moderation, roles, and export system data.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 12,
                  children: [
                    _MetricChip(label: 'Pending', value: _queue.length.toString(), color: const Color(0xFFE0E7FF), textColor: const Color(0xFF3730A3)),
                    _MetricChip(label: 'High Priority', value: _highPriorityCount.toString(), color: const Color(0xFFFEE2E2), textColor: const Color(0xFF991B1B)),
                    _MetricChip(label: 'SLA Breached', value: _breachedCount.toString(), color: const Color(0xFFFFEDD5), textColor: const Color(0xFF9A3412)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
              ),
              const SizedBox(height: 16),
            ],

            // --- QUEUE SECTION ---
            _SectionCard(
              title: 'Moderation Queue',
              onRefresh: _loadQueue,
              child: _loadingQueue
                  ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _queueSearchCtrl,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: _inputDecoration('Search by title or type...'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: _CompactDropdown(
                                  key: ValueKey<String>('qp_$_queuePriorityFilter'),
                                  value: _queuePriorityFilter,
                                  items: const {'all': 'All Priorities', 'high': 'High', 'medium': 'Medium', 'low': 'Low'},
                                  onChanged: (v) => setState(() {
                                    _queuePriorityFilter = v!;
                                    _queuePage = 1;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: _CompactDropdown(
                                  key: ValueKey<String>('qs_$_queueSlaFilter'),
                                  value: _queueSlaFilter,
                                  items: const {'all': 'All SLAs', 'breached': 'Breached', 'ontime': 'On Track'},
                                  onChanged: (v) => setState(() {
                                    _queueSlaFilter = v!;
                                    _queuePage = 1;
                                  }),
                                ),
                              ),
                              if (_queuePriorityFilter != 'all' || _queueSlaFilter != 'all' || _queueSearchCtrl.text.trim().isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: TextButton(
                                    onPressed: () => setState(() {
                                      _queueSearchCtrl.clear();
                                      _queuePriorityFilter = 'all';
                                      _queueSlaFilter = 'all';
                                      _queuePage = 1;
                                    }),
                                    child: const Text('Clear filters', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (_queue.isEmpty)
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                            child: Text('No pending items from the server.', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                          )
                        else if (filteredQueue.isEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            child: Row(
                              children: [
                                const Icon(Icons.filter_alt_off_outlined, size: 18, color: Color(0xFF64748B)),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'No rows match the current filters. Adjust search or filters, or clear them.',
                                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 32,
                              headingRowHeight: 40,
                              dataRowMinHeight: 36,
                              dataRowMaxHeight: 46,
                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                              columns: const [
                                DataColumn(label: Text('Title', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                DataColumn(label: Text('Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                DataColumn(label: Text('Priority', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                DataColumn(label: Text('Age (h)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                DataColumn(label: Text('SLA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                              ],
                              rows: queuePageRows.map((item) {
                                final triage = Map<String, dynamic>.from(item['triage'] as Map? ?? const {});
                                final priority = (triage['priority'] ?? 'low').toString();
                                final ageRaw = triage['ageHours'];
                                final age = ageRaw is num ? ageRaw.toStringAsFixed(ageRaw % 1 == 0 ? 0 : 1) : (ageRaw ?? '0').toString();
                                final isBreached = triage['isSlaBreached'] == true;
                                final title = (item['title'] ?? '').toString().trim().isEmpty ? '(No title)' : (item['title'] ?? '').toString();
                                final typeLabel = _prettyModerationType((item['type'] ?? 'other').toString());

                                return DataRow(cells: [
                                  DataCell(
                                    Tooltip(
                                      message: title.length > 48 ? title : '',
                                      child: SizedBox(
                                        width: 280,
                                        child: Text(title, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(typeLabel, style: const TextStyle(fontSize: 13))),
                                  DataCell(_PriorityChip(priority: priority)),
                                  DataCell(Text(age, style: const TextStyle(fontSize: 13))),
                                  DataCell(
                                    Text(
                                      isBreached ? 'Breached' : 'On track',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isBreached ? Colors.red[700] : Colors.green[700],
                                      ),
                                    ),
                                  ),
                                ]);
                              }).toList(),
                            ),
                          ),
                          const Divider(height: 1, thickness: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: _PaginationBar(
                              page: queuePage,
                              totalPages: queueTotalPages,
                              totalRows: filteredQueue.length,
                              rowsPerPage: _queueRowsPerPage,
                              onRowsPerPageChanged: (v) => setState(() {
                                _queueRowsPerPage = v;
                                _queuePage = 1;
                              }),
                              onPageChanged: (next) => setState(() => _queuePage = next),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // --- EXPORT SECTION ---
            _SectionCard(
              title: 'Data Export (CSV)',
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a dataset below. Preview will clean and explain columns for easier reading.',
                      style: TextStyle(fontSize: 12, color: Colors.blueGrey[600]),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        _ExportDatasetCard(
                          title: 'Active Users',
                          subtitle: 'Current user accounts',
                          icon: Icons.group_outlined,
                          highlight: const Color(0xFFDBEAFE),
                          keyPoints: const ['Profile info', 'Learning status', 'Account flags'],
                          onTap: () => _previewCsv('users'),
                        ),
                        _ExportDatasetCard(
                          title: 'Deleted Users',
                          subtitle: 'Soft-deleted accounts',
                          icon: Icons.restore_from_trash_outlined,
                          highlight: const Color(0xFFFFEDD5),
                          keyPoints: const ['Deletion time', 'Basic profile', 'Recovery check'],
                          onTap: () => _previewCsv('users', onlyDeleted: true),
                        ),
                        _ExportDatasetCard(
                          title: 'Issue Reports',
                          subtitle: 'User report tickets',
                          icon: Icons.bug_report_outlined,
                          highlight: const Color(0xFFFEE2E2),
                          keyPoints: const ['Report type', 'Current status', 'Admin response'],
                          onTap: () => _previewCsv('reports'),
                        ),
                        _ExportDatasetCard(
                          title: 'Audit Logs',
                          subtitle: 'Admin action history',
                          icon: Icons.fact_check_outlined,
                          highlight: const Color(0xFFE0E7FF),
                          keyPoints: const ['Action', 'Actor', 'Target + time'],
                          onTap: () => _previewCsv('audit_logs'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- ROLE & PERMISSION OVERVIEW ---
            _SectionCard(
              title: 'Roles & Permissions',
              onRefresh: _loadPermissions,
              child: _loadingPerms
                  ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                  : permissionRows.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('No permission data.', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Text(
                                'Only 2 roles: Admin (full access) and User (no admin access). '
                                'To promote/demote users, go to User Management → user details.',
                                style: TextStyle(fontSize: 12, color: Colors.blueGrey[600]),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...permissionRows.map((row) {
                              final role = row['role'].toString();
                              final perms = (row['permissions'] as List).cast<String>();
                              final isWildcard = perms.contains('*');
                              return _RolePermissionTile(
                                role: role,
                                permissions: perms,
                                isWildcard: isWildcard,
                                allPermissions: allPerms,
                              );
                            }),
                            const SizedBox(height: 8),
                          ],
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
  const _CompactDropdown({super.key, required this.value, required this.items, required this.onChanged});
  final String value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      icon: const Icon(Icons.arrow_drop_down, size: 20),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
      ),
      items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
      onChanged: onChanged,
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value, required this.color, required this.textColor});
  final String label;
  final String value;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ExportDatasetCard extends StatelessWidget {
  const _ExportDatasetCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.highlight,
    required this.keyPoints,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color highlight;
  final List<String> keyPoints;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: highlight, borderRadius: BorderRadius.circular(8)),
                      child: Icon(icon, size: 20, color: const Color(0xFF334155)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...keyPoints.map((point) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              point,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: const Text('Preview', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogMetricPill extends StatelessWidget {
  const _DialogMetricPill({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.onRefresh});
  final String title;
  final Widget child;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                if (onRefresh != null)
                  SizedBox(
                    height: 28,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh, size: 14, color: Colors.black87),
                      label: const Text('Refresh', style: TextStyle(fontSize: 12, color: Colors.black87)),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          child,
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.totalRows,
    required this.rowsPerPage,
    required this.onRowsPerPageChanged,
    required this.onPageChanged,
  });

  final int page;
  final int totalPages;
  final int totalRows;
  final int rowsPerPage;
  final ValueChanged<int> onRowsPerPageChanged;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Total: $totalRows rows', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Rows per page:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(width: 8),
            SizedBox(
              height: 28,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: rowsPerPage,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  icon: const Icon(Icons.arrow_drop_down, size: 16),
                  items: const [5, 8, 10, 15, 20, 50].map((e) => DropdownMenuItem<int>(value: e, child: Text('$e'))).toList(),
                  onChanged: (v) { if (v != null) onRowsPerPageChanged(v); },
                ),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              splashRadius: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.chevron_left, color: page > 1 ? Colors.black87 : Colors.grey),
              onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
            ),
            const SizedBox(width: 12),
            Text('Page $page of $totalPages', style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 12),
            IconButton(
              splashRadius: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.chevron_right, color: page < totalPages ? Colors.black87 : Colors.grey),
              onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});
  final String priority;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (priority) {
      case 'high':
        bg = const Color(0xFFFEE2E2); fg = const Color(0xFFB91C1C); break;
      case 'medium':
        bg = const Color(0xFFFEF3C7); fg = const Color(0xFF92400E); break;
      default:
        bg = const Color(0xFFDCFCE7); fg = const Color(0xFF166534);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(priority.toUpperCase(), style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }
}

class _RolePermissionTile extends StatelessWidget {
  const _RolePermissionTile({
    required this.role,
    required this.permissions,
    required this.isWildcard,
    required this.allPermissions,
  });
  final String role;
  final List<String> permissions;
  final bool isWildcard;
  final List<String> allPermissions;

  @override
  Widget build(BuildContext context) {
    final displayRole = '${role[0].toUpperCase()}${role.substring(1)}';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                role == 'admin' ? Icons.admin_panel_settings : Icons.person_outline,
                size: 18,
                color: role == 'admin' ? const Color(0xFFB91C1C) : const Color(0xFF475569),
              ),
              const SizedBox(width: 8),
              Text(
                displayRole,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: role == 'admin' ? const Color(0xFFB91C1C) : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              if (isWildcard)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'FULL ACCESS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
                  ),
                ),
              if (!isWildcard && permissions.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NO ADMIN ACCESS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                ),
            ],
          ),
          if (isWildcard) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: allPermissions.map((p) {
                return _PermissionTag(label: p, granted: true);
              }).toList(),
            ),
          ] else if (permissions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: permissions.map((p) {
                return _PermissionTag(label: p, granted: true);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _PermissionTag extends StatelessWidget {
  const _PermissionTag({required this.label, required this.granted});
  final String label;
  final bool granted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: granted ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: granted ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: granted ? const Color(0xFF166534) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}