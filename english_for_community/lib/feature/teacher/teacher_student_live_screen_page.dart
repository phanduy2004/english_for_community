import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/socket/socket_service.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/feature/student/exams/student_exam_live_mirror_view.dart';
import 'package:english_for_community/feature/teacher/bloc/live_monitor/teacher_live_monitor_bloc.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_page_scaffold.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_action_bar.dart';
import 'package:english_for_community/feature/teacher/layout/teacher_web_ui.dart';
import 'package:flutter/material.dart';

/// Full-screen teacher view mirroring what the student sees on their exam runner.
class TeacherStudentLiveScreenPage extends StatefulWidget {
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
  State<TeacherStudentLiveScreenPage> createState() => _TeacherStudentLiveScreenPageState();
}

class _TeacherStudentLiveScreenPageState extends State<TeacherStudentLiveScreenPage> {
  Map<String, dynamic>? _liveScreen;
  bool _loading = true;
  String? _error;
  void Function(Map<String, dynamic>)? _onLiveScreen;
  void Function(Map<String, dynamic>)? _onLiveProgress;

  @override
  void initState() {
    super.initState();
    if (widget.initialLiveScreen != null && widget.initialLiveScreen!.isNotEmpty) {
      _liveScreen = Map<String, dynamic>.from(widget.initialLiveScreen!);
      _loading = false;
    }
    _load();
    final socket = getIt<SocketService>();
    _onLiveScreen = _handleLivePayload;
    _onLiveProgress = _handleLivePayload;
    socket.listenExamSessionLiveScreen(_onLiveScreen!);
    socket.listenExamSessionLiveProgress(_onLiveProgress!);
  }

  @override
  void dispose() {
    final socket = getIt<SocketService>();
    if (_onLiveScreen != null) socket.offExamSessionLiveScreen(_onLiveScreen);
    if (_onLiveProgress != null) socket.offExamSessionLiveProgress(_onLiveProgress);
    super.dispose();
  }

  void _handleLivePayload(Map<String, dynamic> payload) {
    if (payload['attemptId']?.toString() != widget.attemptId) return;
    if (!mounted) return;
    setState(() {
      final prev = _liveScreen;
      if (prev == null || prev.isEmpty) {
        _liveScreen = Map<String, dynamic>.from(payload);
      } else {
        _liveScreen = mergeTeacherLivePayload(prev, payload);
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await getIt<TeacherExamRepository>().getAttemptLiveScreen(widget.attemptId);
    if (!mounted) return;
    r.fold(
      (f) => setState(() {
        _error = f.message;
        _loading = false;
      }),
      (data) {
        if (data is Map) {
          setState(() {
            _liveScreen = Map<String, dynamic>.from(data);
            _loading = false;
          });
        } else {
          setState(() => _loading = false);
        }
      },
    );
  }

  String _title(BuildContext context) {
    final l10n = context.l10n;
    final exam = (_liveScreen?['examTitle'] as String?)?.trim();
    if (exam != null && exam.isNotEmpty) {
      return l10n.teacherLiveMirrorPageTitle(widget.studentName, exam);
    }
    return l10n.teacherLiveMirrorPageTitleSimple(widget.studentName);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return TeacherPageScaffold(
      title: _title(context),
      maxWidth: TeacherWebUi.contentMaxTable,
      scrollable: false,
      showBack: true,
      body: _loading && _liveScreen == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _liveScreen == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      TeacherRetryButton(onPressed: _load),
                    ],
                  ),
                )
              : _liveScreen == null
                  ? Center(child: Text(l10n.teacherLiveMirrorNoContent))
                  : Padding(
                      padding: TeacherWebUi.pageScrollPadding(context),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.outlineMuted),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.72,
                            child: StudentExamLiveMirrorView(liveScreen: _liveScreen!),
                          ),
                        ),
                      ),
                    ),
    );
  }
}
