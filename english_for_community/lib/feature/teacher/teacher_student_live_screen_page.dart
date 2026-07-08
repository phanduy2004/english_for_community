import 'package:english_for_community/feature/teacher/layout/teacher_skeleton.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/feature/student/exams/student_exam_live_mirror_view.dart';
import 'package:english_for_community/feature/teacher/bloc/student_live_screen/teacher_student_live_screen_bloc.dart';
import 'package:english_for_community/feature/teacher/bloc/student_live_screen/teacher_student_live_screen_event.dart';
import 'package:english_for_community/feature/teacher/bloc/student_live_screen/teacher_student_live_screen_state.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_page_scaffold.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Full-screen teacher view mirroring what the student sees on their exam runner.
class TeacherStudentLiveScreenPage extends StatelessWidget {
  const TeacherStudentLiveScreenPage({
    super.key,
    required this.attemptId,
    required this.studentName,
    this.initialLiveScreen,
  });

  final String attemptId;
  final String studentName;
  final Map<String, dynamic>? initialLiveScreen;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TeacherStudentLiveScreenBloc>(param1: attemptId)
        ..add(TeacherStudentLiveScreenStarted(
          attemptId: attemptId,
          initialLiveScreen: initialLiveScreen,
        )),
      child: _TeacherStudentLiveScreenDisposeScope(
        child: _TeacherStudentLiveScreenView(
          attemptId: attemptId,
          studentName: studentName,
          initialLiveScreen: initialLiveScreen,
        ),
      ),
    );
  }
}

class _TeacherStudentLiveScreenDisposeScope extends StatefulWidget {
  const _TeacherStudentLiveScreenDisposeScope({required this.child});

  final Widget child;

  @override
  State<_TeacherStudentLiveScreenDisposeScope> createState() =>
      _TeacherStudentLiveScreenDisposeScopeState();
}

class _TeacherStudentLiveScreenDisposeScopeState extends State<_TeacherStudentLiveScreenDisposeScope> {
  // Lưu ref bloc từ didChangeDependencies — KHÔNG lookup ancestor trong dispose()
  // (lúc đó element đã deactivate → "deactivated widget's ancestor is unsafe").
  TeacherStudentLiveScreenBloc? _bloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bloc = context.read<TeacherStudentLiveScreenBloc>();
  }

  @override
  void dispose() {
    _bloc?.add(const TeacherStudentLiveScreenStopped());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _TeacherStudentLiveScreenView extends StatelessWidget {
  const _TeacherStudentLiveScreenView({
    required this.attemptId,
    required this.studentName,
    this.initialLiveScreen,
  });

  final String attemptId;
  final String studentName;
  final Map<String, dynamic>? initialLiveScreen;

  String _title(BuildContext context, Map<String, dynamic>? liveScreen) {
    final l10n = context.l10n;
    final exam = (liveScreen?['examTitle'] as String?)?.trim();
    if (exam != null && exam.isNotEmpty) {
      return l10n.teacherLiveMirrorPageTitle(studentName, exam);
    }
    return l10n.teacherLiveMirrorPageTitleSimple(studentName);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<TeacherStudentLiveScreenBloc, TeacherStudentLiveScreenState>(
      builder: (context, state) {
        final loading = state.status == TeacherStudentLiveScreenStatus.loading && state.liveScreen == null;
        final error = state.status == TeacherStudentLiveScreenStatus.error && state.liveScreen == null;

        return TeacherPageScaffold(
          title: _title(context, state.liveScreen),
          maxWidth: TeacherWebUi.contentMaxTable,
          scrollable: false,
          showBack: true,
          body: loading
              ? TeacherSkeleton.page(TeacherSkeleton.table(rows: 8))
              : error
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(state.errorMessage ?? '', textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          TeacherRetryButton(
                            onPressed: () => context.read<TeacherStudentLiveScreenBloc>().add(
                                  TeacherStudentLiveScreenStarted(
                                    attemptId: attemptId,
                                    initialLiveScreen: initialLiveScreen,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    )
                  : state.liveScreen == null
                      ? Center(child: Text(l10n.teacherLiveMirrorNoContent))
                      : Padding(
                          padding: TeacherWebUi.pageScrollPadding(context),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              border: Border.all(color: AppColors.outlineMuted),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.s4),
                              child: StudentExamLiveMirrorView(liveScreen: state.liveScreen!),
                            ),
                          ),
                        ),
        );
      },
    );
  }
}
