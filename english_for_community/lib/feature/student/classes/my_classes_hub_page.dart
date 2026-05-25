import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/feature/student/bloc/classes_hub/student_classes_hub_bloc.dart';
import 'package:english_for_community/feature/student/bloc/classes_hub/student_classes_hub_event.dart';
import 'package:english_for_community/feature/student/bloc/classes_hub/student_classes_hub_state.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:english_for_community/feature/student/classes/student_classroom_detail_page.dart';
import 'package:english_for_community/feature/student/exams/exam_assignments_page.dart';
import 'package:english_for_community/feature/student/exams/public_exam_join_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class MyClassesHubPage extends StatefulWidget {
  const MyClassesHubPage({super.key});

  static const String routePath = '/student/classes';
  static const String routeName = 'MyClassesHubPage';

  @override
  State<MyClassesHubPage> createState() => _MyClassesHubPageState();
}

class _MyClassesHubPageState extends State<MyClassesHubPage> {
  final _codeCtrl = TextEditingController();
  final _inviteTokenCtrl = TextEditingController();

  void _reload() {
    context.read<StudentClassesHubBloc>().add(const StudentClassesHubLoadRequested());
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _inviteTokenCtrl.dispose();
    super.dispose();
  }

  String _teacherLine(Map<String, dynamic> m) {
    final t = m['teacherId'];
    if (t is Map) {
      final name = (t['fullName'] as String?)?.trim();
      if (name != null && name.isNotEmpty) return name;
      final un = (t['username'] as String?)?.trim();
      if (un != null && un.isNotEmpty) return un;
    }
    return '';
  }

  void _openClass(String id) {
    if (id.isEmpty) return;
    context.push('${StudentClassroomDetailPage.routePath}/$id');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (_) => getIt<StudentClassesHubBloc>()..add(const StudentClassesHubLoadRequested()),
      child: BlocConsumer<StudentClassesHubBloc, StudentClassesHubState>(
        listenWhen: (p, c) =>
            c.joinSuccess && !p.joinSuccess ||
            (c.errorMessage != null && c.errorMessage != p.errorMessage),
        listener: (context, state) {
          if (state.joinSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.studentJoinClassSuccess)),
            );
            _codeCtrl.clear();
            _inviteTokenCtrl.clear();
          } else if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          final loading = state.status == StudentClassesHubStatus.loading;
          final error = state.status == StudentClassesHubStatus.error ? state.errorMessage : null;
          final classes = state.classes;

          return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: StudentMobileUi.skillAppBar(
        context,
        title: l10n.studentClassesTitle,
        skill: SkillType.speaking,
        actions: [
          TextButton(
            onPressed: () => context.push(ExamAssignmentsPage.routePath),
            child: Text(l10n.studentExamsMenu),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => _reload(),
        child: ListView(
          padding: StudentMobileUi.pagePadding,
          children: [
            _JoinCard(
              controller: _codeCtrl,
              tokenController: _inviteTokenCtrl,
              loading: state.joiningByCode,
              joiningByToken: state.joiningByToken,
              onJoin: () {
                final code = _codeCtrl.text.trim();
                if (code.isEmpty) return;
                context.read<StudentClassesHubBloc>().add(StudentClassesHubJoinByCodeRequested(code));
              },
              onJoinByToken: () {
                final token = _inviteTokenCtrl.text.trim();
                if (token.isEmpty) return;
                context.read<StudentClassesHubBloc>().add(StudentClassesHubJoinByTokenRequested(token));
              },
              onOpenPublicJoin: () => context.push(PublicExamJoinPage.routePath),
            ),
            const SizedBox(height: StudentMobileUi.sectionGap),
            _SectionHeader(
              title: l10n.studentMyClassesTitle,
              count: loading ? null : classes.length,
            ),
            const SizedBox(height: AppSpacing.s4),
            if (loading)
              const _LoadingList()
            else if (error != null)
              StudentMobileUi.errorBanner(message: error, onRetry: _reload, retryLabel: l10n.retry)
            else if (classes.isEmpty)
              StudentMobileUi.emptyState(
                context,
                icon: Icons.school_outlined,
                title: l10n.studentNoClasses,
                body: '',
              )
            else
              ...classes.map((raw) {
                final m = Map<String, dynamic>.from(raw as Map);
                final id = (m['id'] ?? m['_id'])?.toString() ?? '';
                final name = (m['name'] as String?)?.trim() ?? '';
                final desc = (m['description'] as String?)?.trim() ?? '';
                final teacher = _teacherLine(m);
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                  child: _ClassroomTile(
                    name: name.isEmpty ? l10n.studentClassDetailTitle : name,
                    teacher: teacher.isEmpty ? null : l10n.studentClassTeacher(teacher),
                    description: desc,
                    onOpen: id.isEmpty ? null : () => _openClass(id),
                  ),
                );
              }),
          ],
        ),
      ),
    );
        },
      ),
    );
  }
}

// ─── Join card ────────────────────────────────────────────────────────────────

class _JoinCard extends StatelessWidget {
  const _JoinCard({
    required this.controller,
    required this.tokenController,
    required this.loading,
    required this.joiningByToken,
    required this.onJoin,
    required this.onJoinByToken,
    required this.onOpenPublicJoin,
  });

  final TextEditingController controller;
  final TextEditingController tokenController;
  final bool loading;
  final bool joiningByToken;
  final VoidCallback onJoin;
  final VoidCallback onJoinByToken;
  final VoidCallback onOpenPublicJoin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      variant: AppCardVariant.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StudentMobileUi.skillIconBox(Icons.qr_code_2_rounded, size: 36, skill: SkillType.speaking),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.studentJoinClassTitle, style: StudentMobileUi.cardTitle(context)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s5),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
            ],
            onSubmitted: (_) => onJoin(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              letterSpacing: 0.4,
            ),
            decoration: InputDecoration(
              hintText: l10n.studentInviteCodeLabel,
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
              filled: true,
              fillColor: AppColors.surfaceSubtle,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              prefixIcon: const Icon(Icons.tag_rounded, size: 18, color: AppColors.textMuted),
              prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          SizedBox(
            height: 44,
            child: FilledButton(
              onPressed: loading ? null : onJoin,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                disabledBackgroundColor: AppColors.outlineStrong,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
              ),
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n.studentJoinClassButton),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          TextField(
            controller: tokenController,
            onSubmitted: (_) => onJoinByToken(),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: l10n.studentJoinClassByTokenLabel,
              hintText: l10n.studentJoinClassByTokenHint,
              filled: true,
              fillColor: AppColors.surfaceSubtle,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: joiningByToken ? null : onJoinByToken,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
              ),
              child: joiningByToken
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.studentJoinClassByTokenButton),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          const Divider(height: 1, color: AppColors.outlineMuted),
          const SizedBox(height: AppSpacing.s3),
          InkWell(
            onTap: onOpenPublicJoin,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.examJoinByLinkTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: StudentMobileUi.sectionTitle(context)),
        if (count != null) ...[
          const SizedBox(width: AppSpacing.s3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                height: 1.2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Classroom tile ───────────────────────────────────────────────────────────

class _ClassroomTile extends StatelessWidget {
  const _ClassroomTile({
    required this.name,
    required this.teacher,
    required this.description,
    required this.onOpen,
  });

  final String name;
  final String? teacher;
  final String description;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return StudentMobileUi.skillAccentCard(
      skill: SkillType.speaking,
      onTap: onOpen,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          StudentMobileUi.skillIconBox(Icons.menu_book_rounded, size: 44, skill: SkillType.speaking),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StudentMobileUi.cardTitle(context),
                ),
                if (teacher != null) ...[
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    teacher!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StudentMobileUi.body(context),
                  ),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: StudentMobileUi.caption(context),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          Icon(Icons.chevron_right_rounded, size: 18, color: AppSkillColors.speaking.color),
        ],
      ),
    );
  }
}

// ─── Loading skeleton ─────────────────────────────────────────────────────────

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s4),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.outline),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(AppRadius.input),
                  ),
                ),
                const SizedBox(width: AppSpacing.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(height: 10, width: 140, color: AppColors.surfaceSubtle),
                      const SizedBox(height: 8),
                      Container(height: 8, width: 80, color: AppColors.outlineMuted),
                    ],
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

