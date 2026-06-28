import 'package:english_for_community/core/entity/classroom_chat_entity.dart';
import 'package:english_for_community/feature/student/classes/student_classroom_assignment_utils.dart';
import 'package:equatable/equatable.dart';

enum StudentClassroomDetailStatus { initial, loading, success, error }

enum StudentClassroomMembersStatus { initial, loading, success, error }

enum StudentClassroomLeaveStatus { idle, leaving, success, error }

class StudentClassroomDetailState extends Equatable {
  const StudentClassroomDetailState({
    required this.status,
    this.errorMessage,
    this.classroom,
    this.assignments = const [],
    this.members = const [],
    this.membersStatus = StudentClassroomMembersStatus.initial,
    this.assignmentSegment = StudentClassAssignmentSegment.open,
    this.assignmentSort = StudentClassAssignmentSort.priority,
    this.chatSettings,
    this.isRefreshing = false,
    this.leaveStatus = StudentClassroomLeaveStatus.idle,
    this.leaveError,
  });

  final StudentClassroomDetailStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? classroom;
  final List<dynamic> assignments;
  final List<ChatMember> members;
  final StudentClassroomMembersStatus membersStatus;
  final StudentClassAssignmentSegment assignmentSegment;
  final StudentClassAssignmentSort assignmentSort;
  final ClassroomChatSettings? chatSettings;
  final bool isRefreshing;
  final StudentClassroomLeaveStatus leaveStatus;
  final String? leaveError;

  factory StudentClassroomDetailState.initial() =>
      const StudentClassroomDetailState(status: StudentClassroomDetailStatus.initial);

  List<Map<String, dynamic>> get filteredAssignments =>
      StudentClassAssignmentUtils.filterAndSort(
        assignments,
        assignmentSegment,
        assignmentSort,
      );

  int get memberCountActive {
    final c = classroom;
    if (c == null) return members.length;
    final v = c['memberCountActive'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    final parsed = int.tryParse('$v');
    if (parsed != null && parsed > 0) return parsed;
    return members.length;
  }

  StudentClassroomDetailState copyWith({
    StudentClassroomDetailStatus? status,
    String? errorMessage,
    Map<String, dynamic>? classroom,
    List<dynamic>? assignments,
    List<ChatMember>? members,
    StudentClassroomMembersStatus? membersStatus,
    StudentClassAssignmentSegment? assignmentSegment,
    StudentClassAssignmentSort? assignmentSort,
    ClassroomChatSettings? chatSettings,
    bool? isRefreshing,
    StudentClassroomLeaveStatus? leaveStatus,
    String? leaveError,
    bool clearError = false,
    bool clearLeaveError = false,
  }) {
    return StudentClassroomDetailState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      classroom: classroom ?? this.classroom,
      assignments: assignments ?? this.assignments,
      members: members ?? this.members,
      membersStatus: membersStatus ?? this.membersStatus,
      assignmentSegment: assignmentSegment ?? this.assignmentSegment,
      assignmentSort: assignmentSort ?? this.assignmentSort,
      chatSettings: chatSettings ?? this.chatSettings,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      leaveStatus: leaveStatus ?? this.leaveStatus,
      leaveError: clearLeaveError ? null : (leaveError ?? this.leaveError),
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        classroom,
        assignments,
        members,
        membersStatus,
        assignmentSegment,
        assignmentSort,
        chatSettings,
        isRefreshing,
        leaveStatus,
        leaveError,
      ];
}
