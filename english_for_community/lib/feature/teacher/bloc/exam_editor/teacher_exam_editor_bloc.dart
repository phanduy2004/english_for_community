import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/teacher/bloc/exam_editor/teacher_exam_editor_event.dart';
import 'package:english_for_community/feature/teacher/bloc/exam_editor/teacher_exam_editor_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherExamEditorBloc extends Bloc<TeacherExamEditorEvent, TeacherExamEditorState> {
  TeacherExamEditorBloc({
    required this.repository,
    required this.examId,
  }) : super(TeacherExamEditorState.initial()) {
    on<TeacherExamEditorLoadRequested>(_onLoad);
    on<TeacherExamEditorTitleChanged>(_onTitle);
    on<TeacherExamEditorDescriptionChanged>(_onDescription);
    on<TeacherExamEditorResultsPolicyChanged>(_onPolicy);
    on<TeacherExamEditorItemsChanged>(_onItems);
    on<TeacherExamEditorSaveDraftRequested>(_onSave);
    on<TeacherExamEditorPublishRequested>(_onPublish);
  }

  final TeacherExamRepository repository;
  final String examId;

  Map<String, dynamic> _buildSectionsPayload() => {
        'sections': [
          {
            'sectionId': 'sec_1',
            'title': '',
            'order': 0,
            'instructions': '',
            'items': state.items,
          },
        ],
      };

  Map<String, dynamic> _draftPayload() => {
        'title': state.title.trim(),
        'description': state.description,
        'settings': {
          'showResultsPolicy': state.showResultsPolicy,
          'allowMultipleSubmissions': false,
        },
        ..._buildSectionsPayload(),
      };

  Future<void> _onLoad(
    TeacherExamEditorLoadRequested event,
    Emitter<TeacherExamEditorState> emit,
  ) async {
    emit(state.copyWith(status: TeacherExamEditorStatus.loading, clearError: true));
    final r = await repository.getExam(examId);
    r.fold(
      (f) => emit(state.copyWith(
        status: TeacherExamEditorStatus.error,
        errorMessage: f.message,
      )),
      (d) {
        final m = Map<String, dynamic>.from(d as Map);
        var items = <Map<String, dynamic>>[];
        final sections = m['sections'] as List?;
        if (sections != null && sections.isNotEmpty) {
          final sec = Map<String, dynamic>.from(sections.first as Map);
          final raw = sec['items'] as List? ?? [];
          items = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        var policy = 'after_submit';
        final settings = m['settings'];
        if (settings is Map) {
          policy = (settings['showResultsPolicy'] as String?) ?? policy;
        }
        emit(state.copyWith(
          status: TeacherExamEditorStatus.success,
          examStatus: (m['status'] as String?) ?? 'draft',
          title: (m['title'] as String?) ?? '',
          description: (m['description'] as String?) ?? '',
          showResultsPolicy: policy,
          items: items,
        ));
      },
    );
  }

  void _onTitle(TeacherExamEditorTitleChanged e, Emitter<TeacherExamEditorState> emit) =>
      emit(state.copyWith(title: e.title));

  void _onDescription(
    TeacherExamEditorDescriptionChanged e,
    Emitter<TeacherExamEditorState> emit,
  ) =>
      emit(state.copyWith(description: e.description));

  void _onPolicy(
    TeacherExamEditorResultsPolicyChanged e,
    Emitter<TeacherExamEditorState> emit,
  ) =>
      emit(state.copyWith(showResultsPolicy: e.policy));

  void _onItems(TeacherExamEditorItemsChanged e, Emitter<TeacherExamEditorState> emit) =>
      emit(state.copyWith(items: e.items));

  Future<void> _onSave(
    TeacherExamEditorSaveDraftRequested event,
    Emitter<TeacherExamEditorState> emit,
  ) async {
    if (!state.isDraft) return;
    // clearSuccess ở đầu → mỗi lần lưu, successMessage đổi null→'draft_saved' nên
    // listener luôn fire (chỉ báo "Saved" 1 lần trước đây do message không đổi).
    emit(state.copyWith(saving: true, clearSuccess: true));
    final r = await repository.updateExamDraft(examId, _draftPayload());
    emit(state.copyWith(saving: false));
    r.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      // KHÔNG reload sau save: autosave chạy khi đang gõ, reload sẽ nạp đè & revert
      // chữ đang nhập. Draft do client làm chủ; item id được backend giữ nguyên.
      (_) => emit(state.copyWith(successMessage: 'draft_saved')),
    );
  }

  Future<void> _onPublish(
    TeacherExamEditorPublishRequested event,
    Emitter<TeacherExamEditorState> emit,
  ) async {
    if (state.items.isEmpty) return;
    emit(state.copyWith(saving: true));
    final save = await repository.updateExamDraft(examId, _draftPayload());
    await save.fold(
      (f) async => emit(state.copyWith(saving: false, errorMessage: f.message)),
      (_) async {
        final r = await repository.publishExam(examId);
        emit(state.copyWith(saving: false));
        r.fold(
          (f) => emit(state.copyWith(errorMessage: f.message)),
          (_) {
            emit(state.copyWith(successMessage: 'published'));
            add(const TeacherExamEditorLoadRequested());
          },
        );
      },
    );
  }
}
