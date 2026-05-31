import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/admin_teacher_application_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/admin/dashboard_home/admin_dashboard.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/feature/admin/layout/admin_page_scaffold.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:english_for_community/feature/admin/layout/admin_widgets.dart';
import 'package:flutter/material.dart';

class AdminTeacherApplicationsPage extends StatefulWidget {
  const AdminTeacherApplicationsPage({super.key});

  static const String routePath = '/admin/teacher-applications';
  static const String routeName = 'AdminTeacherApplicationsPage';

  @override
  State<AdminTeacherApplicationsPage> createState() => _AdminTeacherApplicationsPageState();
}

class _AdminTeacherApplicationsPageState extends State<AdminTeacherApplicationsPage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await getIt<AdminTeacherApplicationRepository>().list(status: 'pending');
    r.fold(
      (f) => setState(() => _error = f.message),
      (map) {
        final items = map['items'];
        setState(() => _items = items is List ? items : []);
      },
    );
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _approve(String id) async {
    final r = await getIt<AdminTeacherApplicationRepository>().approve(id);
    r.fold(
      (f) => AppCornerToast.show(context, f.message, error: true),
      (_) {
        AppCornerToast.show(context, context.l10n.adminTeacherApprove);
        _load();
      },
    );
  }

  Future<void> _reject(String id) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.adminTeacherReject),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(labelText: context.l10n.adminTeacherRejectReason),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(context.l10n.adminTeacherReject)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final reason = ctrl.text.trim();
    if (reason.isEmpty) return;
    final r = await getIt<AdminTeacherApplicationRepository>().reject(id, reason);
    r.fold(
      (f) => AppCornerToast.show(context, f.message, error: true),
      (_) {
        AppCornerToast.show(context, context.l10n.adminTeacherReject);
        _load();
      },
    );
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AdminPageScaffold(
      title: l10n.adminTeacherApplicationsTitle,
      subtitle: l10n.adminTeacherApplicationsSubtitle,
      breadcrumbs: [
        AdminBreadcrumb(label: l10n.adminOverviewTitle, location: AdminDashboardPage.routePath),
        AdminBreadcrumb(label: l10n.adminTeacherApplicationsTitle),
      ],
      actions: [
        IconButton(
          style: AdminWebUi.compactHeaderIconStyle(),
          onPressed: _load,
          icon: const Icon(Icons.refresh_outlined, size: 18),
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _items.isEmpty
                  ? AdminEmptyState(message: l10n.adminTeacherApplicationsEmpty)
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      itemBuilder: (context, i) {
                        final m = Map<String, dynamic>.from(_items[i] as Map);
                        final id = m['id'] as String? ?? '';
                        final user = m['userId'];
                        String name = '';
                        if (user is Map) name = (user['fullName'] as String?) ?? '';
                        final bio = (m['payload'] is Map ? (m['payload'] as Map)['bio'] : null)?.toString() ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppCard(
                            variant: AppCardVariant.outline,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: Theme.of(context).textTheme.titleMedium),
                                if (bio.isNotEmpty) Text(bio, style: const TextStyle(color: AppColors.textSecondary)),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    FilledButton(onPressed: id.isEmpty ? null : () => _approve(id), child: Text(l10n.adminTeacherApprove)),
                                    OutlinedButton(onPressed: id.isEmpty ? null : () => _reject(id), child: Text(l10n.adminTeacherReject)),
                                  ],
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
