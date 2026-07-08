import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/feature/teacher/bloc/integrated_exam_editor/teacher_integrated_exam_editor_event.dart';
import 'package:english_for_community/feature/teacher/bloc/integrated_exam_editor/teacher_integrated_exam_editor_payload.dart';
import 'package:english_for_community/feature/teacher/bloc/integrated_exam_editor/teacher_integrated_exam_editor_state.dart';
import 'package:english_for_community/feature/teacher/bloc/integrated_exam_editor/teacher_integrated_exam_editor_constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherIntegratedExamEditorBloc
    extends Bloc<TeacherIntegratedExamEditorEvent, TeacherIntegratedExamEditorState> {
  TeacherIntegratedExamEditorBloc({
    required this.repository,
    required this.examId,
  }) : super(TeacherIntegratedExamEditorState.initial()) {
    on<TeacherIntegratedExamEditorLoadRequested>(_onLoad);
    on<TeacherIntegratedExamEditorTitleChanged>(_onTitle);
    on<TeacherIntegratedExamEditorSkillIncludedChanged>(_onSkillIncluded);
    on<TeacherIntegratedExamEditorSkillSectionUpdated>(_onSkillSection);
    on<TeacherIntegratedExamEditorSkillResourceAdded>(_onResourceAdded);
    on<TeacherIntegratedExamEditorGrammarIncludedChanged>(_onGrammarIncluded);
    on<TeacherIntegratedExamEditorGrammarItemsUpdated>(_onGrammarItems);
    on<TeacherIntegratedExamEditorGrammarEditorIndexChanged>(_onGrammarEditorIndex);
    on<TeacherIntegratedExamEditorGrammarSaved>(_onGrammarSaved);
    on<TeacherIntegratedExamEditorRemoveResource>(_onRemoveResource);
    on<TeacherIntegratedExamEditorWritingFixedPromptChanged>(_onWritingPrompt);
    on<TeacherIntegratedExamEditorWritingGenerateRequested>(_onWritingGenerate);
    on<TeacherIntegratedExamEditorWritingPromptOptionsDismissed>(_onWritingOptionsDismissed);
    on<TeacherIntegratedExamEditorGrammarImportAppended>(_onGrammarImport);
    on<TeacherIntegratedExamEditorSaveDraftRequested>(_onSaveDraft);
    on<TeacherIntegratedExamEditorPublishRequested>(_onPublish);
  }

  final TeacherExamRepository repository;
  final String examId;

  Future<void> _onLoad(
    TeacherIntegratedExamEditorLoadRequested event,
    Emitter<TeacherIntegratedExamEditorState> emit,
  ) async {
    emit(state.copyWith(
      status: TeacherIntegratedExamEditorStatus.loading,
      clearError: true,
      clearPublishFailure: true,
    ));
    final r = await repository.getExam(examId);
    r.fold(
      (f) => emit(state.copyWith(
        status: TeacherIntegratedExamEditorStatus.error,
        errorMessage: f.message,
      )),
      (d) {
        final m = Map<String, dynamic>.from(d as Map);
        final examStatus = (m['status'] as String?) ?? 'draft';
        var loadedTitle = (m['title'] as String?)?.trim() ?? '';
        if (loadedTitle == event.legacyUntitledLabel) loadedTitle = '';

        final skillIncluded = teacherIntegratedExamEditorDefaultSkillIncluded();
        final skillSection = teacherIntegratedExamEditorDefaultSkillSections();
        for (final sk in teacherIntegratedExamSkillOrder) {
          skillIncluded[sk] = false;
        }

        final raw = m['sections'] as List?;
        final settings = Map<String, dynamic>.from((m['settings'] as Map?) ?? {});

        if (raw != null) {
          for (final e in raw) {
            final sec = Map<String, dynamic>.from(e as Map);
            final sk = sec['skill'] as String? ?? '';
            if (!teacherIntegratedExamSkillOrder.contains(sk)) continue;
            skillIncluded[sk] = true;
            if (!sec.containsKey('resources') || sec['resources'] == null) {
              final id = (sec['resourceId'] as String?)?.trim() ?? '';
              final title = (sec['resourceTitle'] as String?)?.trim() ?? '';
              sec['resources'] = id.isNotEmpty
                  ? [{'id': id, 'title': title}]
                  : <Map<String, dynamic>>[];
            }
            if (sk == 'listening') {
              // May have two listening sections (dictation + comprehension) — merge both.
              teacherIntegratedExamEditorMergeListeningSection(skillSection, sec);
            } else {
              skillSection[sk] = sec;
            }
          }
        }

        final fmt = settings['examFormat'] as String? ?? '';
        final gRaw = settings['grammarItems'];
        final hasGrammar = gRaw is List && gRaw.isNotEmpty;
        if (fmt == 'integrated_four_skills' || ((raw == null || raw.isEmpty) && !hasGrammar)) {
          for (final sk in teacherIntegratedExamSkillOrder) {
            skillIncluded[sk] = true;
            skillSection[sk] = skillSection[sk] ??
                teacherIntegratedExamEditorEmptySkillSection(
                  sk,
                  teacherIntegratedExamSkillOrder.indexOf(sk),
                );
          }
        }

        List<Map<String, dynamic>> grammarItems;
        final g = settings['grammarItems'];
        if (g is List) {
          grammarItems = g.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else {
          grammarItems = [];
        }
        final grammarEnabled = settings['grammarEnabled'];
        final grammarIncluded =
            grammarEnabled == true || (grammarEnabled != false && grammarItems.isNotEmpty);

        emit(state.copyWith(
          status: TeacherIntegratedExamEditorStatus.success,
          examStatus: examStatus,
          title: loadedTitle,
          skillIncluded: skillIncluded,
          skillSection: skillSection,
          grammarItems: grammarItems,
          grammarIncluded: grammarIncluded,
          legacyUntitledLabel: event.legacyUntitledLabel,
        ));
      },
    );
  }

  void _onTitle(TeacherIntegratedExamEditorTitleChanged e, Emitter<TeacherIntegratedExamEditorState> emit) =>
      emit(state.copyWith(title: e.title));

  void _onSkillIncluded(
    TeacherIntegratedExamEditorSkillIncludedChanged e,
    Emitter<TeacherIntegratedExamEditorState> emit,
  ) {
    final next = Map<String, bool>.from(state.skillIncluded)..[e.skill] = e.included;
    emit(state.copyWith(skillIncluded: next));
  }

  void _onSkillSection(
    TeacherIntegratedExamEditorSkillSectionUpdated e,
    Emitter<TeacherIntegratedExamEditorState> emit,
  ) {
    final next = Map<String, Map<String, dynamic>>.from(state.skillSection)..[e.skill] = e.section;
    emit(state.copyWith(skillSection: next));
  }

  void _onResourceAdded(
    TeacherIntegratedExamEditorSkillResourceAdded e,
    Emitter<TeacherIntegratedExamEditorState> emit,
  ) {
    final sec = state.skillSection[e.skill] ?? teacherIntegratedExamEditorEmptySkillSection(e.skill, 0);

    if (e.skill == 'listening' && e.listeningSubType == 'comprehension') {
      final compRes = teacherIntegratedExamEditorGetCompResources(sec);
      if (!compRes.any((r) => r['id'] == e.resourceId)) {
        compRes.add({'id': e.resourceId, 'title': e.resourceTitle});
      }
      final next = Map<String, Map<String, dynamic>>.from(state.skillSection)
        ..[e.skill] = {...sec, 'compResources': compRes};
      emit(state.copyWith(skillSection: next));
      return;
    }

    final resources = teacherIntegratedExamEditorGetResources(sec);
    if (!resources.any((r) => r['id'] == e.resourceId)) {
      resources.add({'id': e.resourceId, 'title': e.resourceTitle});
    }
    final next = Map<String, Map<String, dynamic>>.from(state.skillSection)
      ..[e.skill] = {...sec, 'resources': resources};
    emit(state.copyWith(skillSection: next));
  }

  void _onGrammarIncluded(
    TeacherIntegratedExamEditorGrammarIncludedChanged e,
    Emitter<TeacherIntegratedExamEditorState> emit,
  ) {
    emit(state.copyWith(
      grammarIncluded: e.included,
      clearGrammarEditorIndex: !e.included,
    ));
  }

  void _onGrammarItems(
    TeacherIntegratedExamEditorGrammarItemsUpdated e,
    Emitter<TeacherIntegratedExamEditorState> emit,
  ) =>
      emit(state.copyWith(grammarItems: e.items));

  void _onGrammarEditorIndex(
    TeacherIntegratedExamEditorGrammarEditorIndexChanged e,
    Emitter<TeacherIntegratedExamEditorState> emit,
  ) =>
      emit(state.copyWith(grammarEditorIndex: e.index));

  void _onGrammarSaved(
    TeacherIntegratedExamEditorGrammarSaved e,
    Emitter<TeacherIntegratedExamEditorState> emit,
  ) {
    final idx = state.grammarEditorIndex;
    List<Map<String, dynamic>> nextItems;
    if (idx == -1) {
      nextItems = [...state.grammarItems, e.item];
    } else if (idx != null && idx >= 0) {
      nextItems = [...state.grammarItems];
      nextItems[idx] = e.item;
    } else {
      nextItems = state.grammarItems;
    }
    emit(state.copyWith(
      grammarItems: nextItems,
      clearGrammarEditorIndex: true,
    ));
  }

  void _onRemoveResource(
    TeacherIntegratedExamEditorRemoveResource e,
    Emitter<TeacherIntegratedExamEditorState> emit,
  ) {
    final sec = state.skillSection[e.skill];
    if (sec == null) return;

    if (e.skill == 'listening' && e.listeningSubType == 'comprehension') {
      final compRes = teacherIntegratedExamEditorGetCompResources(sec)..removeAt(e.index);
      final next = Map<String, Map<String, dynamic>>.from(state.skillSection)
        ..[e.skill] = {...sec, 'compResources': compRes};
      emit(state.copyWith(skillSection: next));
      return;
    }

    final resources = teacherIntegratedExamEditorGetResources(sec)..removeAt(e.index);
    final next = Map<String, Map<String, dynamic>>.from(state.skillSection)
      ..[e.skill] = {...sec, 'resources': resources};
    emit(state.copyWith(skillSection: next));
  }

  void _onWritingPrompt(
    TeacherIntegratedExamEditorWritingFixedPromptChanged e,
    Emitter<TeacherIntegratedExamEditorState> emit,
  ) {
    final sec = state.skillSection['writing'] ?? teacherIntegratedExamEditorEmptySkillSection('writing', 2);
    final next = Map<String, Map<String, dynamic>>.from(state.skillSection);
    if (e.prompt == null) {
      final copy = Map<String, dynamic>.from(sec)..remove('fixedWritingPrompt');
      next['writing'] = copy;
    } else {
      next['writing'] = {...sec, 'fixedWritingPrompt': e.prompt};
    }
    emit(state.copyWith(skillSection: next));
  }

  Future<void> _onWritingGenerate(
    TeacherIntegratedExamEditorWritingGenerateRequested e,
    Emitter<TeacherIntegratedExamEditorState> emit,
  ) async {
    emit(state.copyWith(writingPromptGenerating: true, clearWritingPromptOptions: true));
    final r = await repository.generateWritingPromptOptions(
      topicId: e.topicId,
      topicName: e.topicName,
      taskType: e.taskType,
    );
    emit(state.copyWith(writingPromptGenerating: false));
    r.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      (options) => emit(state.copyWith(writingPromptOptions: options)),
    );
  }

  void _onWritingOptionsDismissed(
    TeacherIntegratedExamEditorWritingPromptOptionsDismissed event,
    Emitter<TeacherIntegratedExamEditorState> emit,
  ) =>
      emit(state.copyWith(clearWritingPromptOptions: true));

  void _onGrammarImport(
    TeacherIntegratedExamEditorGrammarImportAppended e,
    Emitter<TeacherIntegratedExamEditorState> emit,
  ) =>
      emit(state.copyWith(grammarItems: [...state.grammarItems, ...e.items]));

  Future<void> _onSaveDraft(
    TeacherIntegratedExamEditorSaveDraftRequested event,
    Emitter<TeacherIntegratedExamEditorState> emit,
  ) async {
    if (state.saving) return; // chặn double-submit khi đang lưu
    if (!state.canEditSkillContent) return;
    emit(state.copyWith(saving: true, clearError: true, clearSuccess: true));
    final r = await repository.updateExamDraft(
      examId,
      teacherIntegratedExamEditorDraftPayload(
        title: state.title,
        skillIncluded: state.skillIncluded,
        skillSection: state.skillSection,
        grammarIncluded: state.grammarIncluded,
        grammarItems: state.grammarItems,
      ),
    );
    emit(state.copyWith(saving: false));
    await r.fold(
      (f) async => emit(state.copyWith(errorMessage: f.message)),
      (_) async {
        emit(state.copyWith(successMessage: 'draft_saved'));
        add(TeacherIntegratedExamEditorLoadRequested(legacyUntitledLabel: state.legacyUntitledLabel));
      },
    );
  }

  Future<void> _onPublish(
    TeacherIntegratedExamEditorPublishRequested event,
    Emitter<TeacherIntegratedExamEditorState> emit,
  ) async {
    if (state.saving) return; // chặn double-submit khi đang publish/lưu
    final failure = teacherIntegratedExamEditorValidatePublish(
      skillIncluded: state.skillIncluded,
      skillSection: state.skillSection,
      grammarIncluded: state.grammarIncluded,
      grammarItems: state.grammarItems,
    );
    if (failure != null) {
      emit(state.copyWith(publishFailure: failure));
      return;
    }
    if (!state.canEditSkillContent) return;
    emit(state.copyWith(saving: true, clearPublishFailure: true));
    final save = await repository.updateExamDraft(
      examId,
      teacherIntegratedExamEditorDraftPayload(
        title: state.title,
        skillIncluded: state.skillIncluded,
        skillSection: state.skillSection,
        grammarIncluded: state.grammarIncluded,
        grammarItems: state.grammarItems,
      ),
    );
    await save.fold(
      (f) async => emit(state.copyWith(saving: false, errorMessage: f.message)),
      (_) async {
        if (!state.isDraft) {
          emit(state.copyWith(saving: false));
          return;
        }
        final r = await repository.publishExam(examId);
        emit(state.copyWith(saving: false));
        r.fold(
          (f) => emit(state.copyWith(errorMessage: f.message)),
          (_) => emit(state.copyWith(successMessage: 'published')),
        );
      },
    );
  }
}
