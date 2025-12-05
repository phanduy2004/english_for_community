import 'dart:async';
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

  // Shadcn Palette
  final bgPage = const Color(0xFFF8FAFC);
  final textMain = const Color(0xFF0F172A);
  final textMuted = const Color(0xFF64748B);
  final borderCol = const Color(0xFFE2E8F0);
  final white = Colors.white;
  final primary = const Color(0xFF0F172A);

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
    context.read<AdminBloc>().add(GetReportsEvent(status: status, page: 1, limit: 20));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPage,
      appBar: AppBar(
        backgroundColor: white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Report Management', style: TextStyle(color: textMain, fontWeight: FontWeight.w700, fontSize: 16)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: white,
            // 🔥 SỬA PHẦN NÀY:
            child: TabBar(
              controller: _tabController,
              labelColor: primary,
              unselectedLabelColor: textMuted,
              indicatorColor: primary,
              indicatorWeight: 2,

              // 1. Dùng .tab để gạch chân full chiều rộng tab
              indicatorSize: TabBarIndicatorSize.tab,

              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),

              // 2. Tắt cuộn để tab tự giãn đều màn hình
              isScrollable: false,

              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Reviewed'),
                Tab(text: 'Resolved'),
                Tab(text: 'Rejected'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: white,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderCol),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: textMain, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search by title or sender...',
                  hintStyle: TextStyle(color: textMuted),
                  prefixIcon: Icon(Icons.search, size: 18, color: textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // List Content
          Expanded(
            child: BlocConsumer<AdminBloc, AdminState>(
              listener: (context, state) {
                if (state.status == AdminStatus.actionSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status updated successfully'), backgroundColor: Color(0xFF10B981)),
                  );
                }
                if (state.status == AdminStatus.error && state.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.errorMessage!), backgroundColor: const Color(0xFFEF4444)),
                  );
                }
              },
              builder: (context, state) {
                final paginatedData = state.reports;
                final List<ReportEntity> reportsList = paginatedData?.data ?? [];

                if (state.status == AdminStatus.loading && reportsList.isEmpty) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }

                if (reportsList.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reportsList.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return ReportCard(report: reportsList[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: textMuted.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text("No reports found in this status", style: TextStyle(color: textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}