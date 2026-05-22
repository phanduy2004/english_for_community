import 'package:english_for_community/feature/teacher/layout/teacher_assign_exam_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Legacy route `/teacher/exams/:id/assign` — opens assign dialog then pops with result.
class TeacherAssignmentWizardPage extends StatefulWidget {
  const TeacherAssignmentWizardPage({
    super.key,
    required this.examId,
    this.initialClassroomId,
  });

  final String examId;
  final String? initialClassroomId;

  static const String routePathPrefix = '/teacher/exams';

  @override
  State<TeacherAssignmentWizardPage> createState() => _TeacherAssignmentWizardPageState();
}

class _TeacherAssignmentWizardPageState extends State<TeacherAssignmentWizardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openDialog());
  }

  Future<void> _openDialog() async {
    final result = await TeacherAssignExamDialog.show(
      context,
      examId: widget.examId,
      initialClassroomId: widget.initialClassroomId,
    );
    if (!mounted) return;
    context.pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}
