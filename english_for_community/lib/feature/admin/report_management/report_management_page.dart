import 'dart:async';

import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/feature/admin/layout/admin_page_scaffold.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:english_for_community/feature/admin/layout/admin_widgets.dart';
import 'package:english_for_community/feature/admin/report_management/widget/report_card.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:english_for_community/feature/admin/layout/admin_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    // create (không .value) → provider tự close bloc factory khi rời trang (hết leak).
    return BlocProvider(
      create: (_) => getIt<AdminBloc>(),
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
  int _page = 1;
  int _rowsPerPage = kAdminDefaultRowsPerPage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchReports();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _page = 1);
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
      page: _page,
      limit: _rowsPerPage,
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
    ));
  }

  void _onSearchChanged(String _) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(AppMotion.base, () {
      setState(() => _page = 1);
      _fetchReports();
    });
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
                  AppCornerToast.show(context, l10n.adminReportStatusUpdated);
                }
                if (state.status == AdminStatus.error && state.errorMessage != null) {
                  AppCornerToast.show(context, state.errorMessage!, error: true);
                }
              },
              builder: (context, state) {
                final reportsList = state.reports?.data ?? [];
                final pagination = state.reports?.pagination;

                if (state.status == AdminStatus.loading && reportsList.isEmpty) {
                  return AdminSkeleton.page(AdminSkeleton.cardList());
                }

                if (reportsList.isEmpty) {
                  return Center(
                    child: AdminEmptyCard(
                      message: l10n.adminNoReportsFound,
                      actionLabel: _searchController.text.trim().isNotEmpty ? l10n.retry : null,
                      onAction: _searchController.text.trim().isNotEmpty
                          ? () {
                              _searchController.clear();
                              setState(() => _page = 1);
                              _fetchReports();
                            }
                          : null,
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                        itemCount: reportsList.length,
                        separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.s4),
                        itemBuilder: (context, index) => ReportCard(report: reportsList[index]),
                      ),
                    ),
                    if (pagination != null && pagination.totalPages > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.s4, bottom: AppSpacing.s7),
                        child: AdminPaginationBar(
                          page: pagination.page,
                          totalPages: pagination.totalPages,
                          totalRows: pagination.total,
                          rowsPerPage: _rowsPerPage,
                          onRowsPerPageChanged: (v) {
                            setState(() {
                              _rowsPerPage = v;
                              _page = 1;
                            });
                            _fetchReports();
                          },
                          onPageChanged: (p) {
                            setState(() => _page = p);
                            _fetchReports();
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


