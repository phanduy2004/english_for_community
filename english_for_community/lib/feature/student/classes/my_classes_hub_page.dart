import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/feature/student/bloc/classes_hub/student_classes_hub_bloc.dart';
import 'package:english_for_community/feature/student/bloc/classes_hub/student_classes_hub_event.dart';
import 'package:english_for_community/feature/student/bloc/classes_hub/student_classes_hub_state.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
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
      appBar: AppBar(
        title: Text(l10n.studentClassesTitle, style: context.h2Style),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: () => context.push(ExamAssignmentsPage.routePath),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: context.appTextTheme.labelLarge,
            ),
            child: Text(l10n.studentExamsMenu),
          ),
          const SizedBox(width: AppSpacing.s2),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => _reload(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s5, AppSpacing.s2, AppSpacing.s5, AppSpacing.s7),
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
            const SizedBox(height: AppSpacing.s7),
            _SectionHeader(
              title: l10n.studentMyClassesTitle,
              count: loading ? null : classes.length,
            ),
            const SizedBox(height: AppSpacing.s4),
            if (loading)
              const _LoadingList()
            else if (error != null)
              _ErrorState(message: error, onRetry: _reload)
            else if (classes.isEmpty)
              const _EmptyClassesCard()
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s5),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: const Icon(Icons.qr_code_2_rounded, size: 20, color: AppColors.textPrimary),
              ),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.studentJoinClassTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: 0.2,
            height: 1.2,
          ),
        ),
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
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outline),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 22,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.1,
                        height: 1.3,
                      ),
                    ),
                    if (teacher != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        teacher!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
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

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyClassesCard extends StatelessWidget {
  const _EmptyClassesCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s8),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: const Icon(Icons.school_outlined, size: 26, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            l10n.studentNoClasses,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s5),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.danger),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              child: Text(l10n.retry),
            ),
          ),
        ],
      ),
    );
  }
}
