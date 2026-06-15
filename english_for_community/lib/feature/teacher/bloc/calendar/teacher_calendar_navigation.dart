import 'package:english_for_community/feature/teacher/bloc/calendar/teacher_calendar_filter.dart';
import 'package:english_for_community/feature/teacher/teacher_classroom_detail_page.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_grading_page.dart';
import 'package:english_for_community/feature/teacher/teacher_exam_session_console_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Opens the most relevant teacher screen for a calendar milestone.
void teacherCalendarNavigateToEvent(BuildContext context, Map<String, dynamic> event) {
  final assignmentId = event['assignmentId'] as String? ?? '';
  if (assignmentId.isEmpty) return;

  final kind = event['kind'] as String?;
  final mode = event['mode'] as String?;

  if (mode == 'realtime' && (kind == 'live' || kind == 'opens')) {
    context.push('${TeacherExamSessionConsolePage.routePath}/$assignmentId');
    return;
  }

  if (kind == 'due' || kind == 'live') {
    context.push('${TeacherExamGradingPage.routePath}/$assignmentId');
    return;
  }

  final classroomId = event['classroomId'] as String? ?? '';
  if (classroomId.isNotEmpty) {
    context.push('${TeacherClassroomDetailPage.routePath}/$classroomId');
    return;
  }

  context.push('${TeacherExamGradingPage.routePath}/$assignmentId');
}

void teacherCalendarNavigateToGroup(BuildContext context, TeacherCalendarAssignmentGroup group) {
  final primary = teacherCalendarPrimaryMilestone(group.milestones);
  if (primary != null) {
    teacherCalendarNavigateToEvent(context, primary);
    return;
  }
  teacherCalendarNavigateToEvent(context, group.anchor);
}
