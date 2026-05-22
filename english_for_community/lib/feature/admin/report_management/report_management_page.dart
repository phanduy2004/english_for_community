import 'dart:async';

import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/admin/layout/admin_page_scaffold.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:english_for_community/feature/admin/layout/admin_widgets.dart';
import 'package:english_for_community/feature/admin/report_management/widget/report_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entity/report_entity.dart';
import '../../../core/get_it/get_it.dart';
import '../../admin/dashboard_home/bloc/admin_bloc.dart';
import '../../admin/dashboard_home/bloc/admin_event.dart';
import '../../admin/dashboard_home/bloc/admin_state.dart';

class ReportManagementPage extends StatelessWidget {
  const ReportManagementPage({super.key});
  static const String routeName = 'ReportManagementPage';
  static const String routePath = '/admin/reports';

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AdminBloc>(),
      child: const _ReportManagementView(),
    );
  }
}

class _ReportManagementView extends StatefulWidget {
  const _ReportManagementView();

  @override
  State<_ReportManagementView> createState() => _ReportManagementViewState();
}

class _ReportManagementViewState extends State<_ReportManagementView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchReports();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _fetchReports();
      }
    });
  }

  void _fetchReports() {
    String status = 'pending';
    switch (_tabController.index) {
      case 0: status = 'pending'; break;
      case 1: status = 'reviewed'; break;
      case 2: status = 'resolved'; break;
      case 3: status = 'rejected'; break;
    }
    context.read<AdminBloc>().add(GetReportsEvent(
      status: status,
      page: 1,
      limit: 20,
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
    ));
  }

  void _onSearchChanged(String _) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _fetchReports);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AdminPageScaffold(
      title: l10n.adminReportManagementTitle,
      scrollable: false,
      maxWidth: AdminWebUi.contentMaxTable,
      headerBottom: TabBar(
        controller: _tabController,
        labelColor: AppColors.primaryDark,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: AdminWebUi.webBody(context).copyWith(fontWeight: FontWeight.w600),
        isScrollable: false,
        tabs: const [
          Tab(text: 'Pending'),
          Tab(text: 'Reviewed'),
          Tab(text: 'Resolved'),
          Tab(text: 'Rejected'),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s5),
            child: AdminSearchField(
              controller: _searchController,
              hint: l10n.adminSearchReportsHint,
              onChanged: _onSearchChanged,
              width: double.infinity,
            ),
          ),
          Expanded(
            child: BlocConsumer<AdminBloc, AdminState>(
              listener: (context, state) {
                if (state.status == AdminStatus.actionSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status updated successfully'), backgroundColor: AppColors.success),
                  );
                }
                if (state.status == AdminStatus.error && state.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.errorMessage!), backgroundColor: AppColors.danger),
                  );
                }
              },
              builder: (context, state) {
                final reportsList = state.reports?.data ?? [];

                if (state.status == AdminStatus.loading && reportsList.isEmpty) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }

                if (reportsList.isEmpty) {
                  return AdminEmptyState(message: l10n.adminNoReportsFound);
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s7),
                  itemCount: reportsList.length,
                  separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.s4),
                  itemBuilder: (context, index) => ReportCard(report: reportsList[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}