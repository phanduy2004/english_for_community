import 'dart:async';

import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:english_for_community/feature/admin/layout/admin_skeleton.dart';
import 'package:english_for_community/feature/admin/layout/admin_web_ui.dart';
import 'package:english_for_community/feature/admin/layout/admin_widgets.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';

// Import Entities & BloC
import '../../../../../core/entity/reading/reading_entity.dart';
import '../../../../../core/entity/reading/reading_feedback_entity.dart';
import '../../../../../core/entity/reading/translation_entity.dart';
import '../../../../../core/get_it/get_it.dart';
import '../content_widgets.dart'; // Contains ShadcnCard, ShadcnInput, etc.
import 'bloc/admin_reading_bloc.dart';
import 'bloc/admin_reading_event.dart';
import 'bloc/admin_reading_state.dart';

class ReadingEditorPage extends StatelessWidget {
  final String? id;
  const ReadingEditorPage({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AdminReadingBloc>(),
      child: _ReadingEditorView(id: id),
    );
  }
}

class _ReadingEditorView extends StatefulWidget {
  final String? id;
  const _ReadingEditorView({this.id});

  @override
  State<_ReadingEditorView> createState() => _ReadingEditorViewState();
}

class _ReadingEditorViewState extends State<_ReadingEditorView> {
  bool _isEditingMode = true;
  AdminSaveState _saveState = AdminSaveState.idle;
  DateTime? _savedAt;
  bool _suppressNavigateOnSave = false;
  String? _titleError;
  String? _contentError;
  Timer? _autosaveDebounce;

  // --- CONTROLLERS ---
  // General Info
  final _titleCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _minutesCtrl = TextEditingController();
  String _difficulty = 'medium';

  // Content & Translation
  final _contentCtrl = TextEditingController();
  final _transTitleCtrl = TextEditingController();
  final _transContentCtrl = TextEditingController();

  // Questions Data
  List<Map<String, dynamic>> questions = [];

  @override
  void initState() {
    super.initState();

    if (widget.id != null) {
      // EDIT MODE: Fetch details
      context.read<AdminReadingBloc>().add(GetReadingDetailEvent(widget.id!));
      _isEditingMode = false; // View mode by default
    } else {
      // CREATE MODE
      _isEditingMode = true;
      _addNewQuestion(); // Add empty question
    }
    _titleCtrl.addListener(_onFieldChanged);
    _contentCtrl.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (_titleError != null && _titleCtrl.text.trim().isNotEmpty) {
      setState(() => _titleError = null);
    }
    if (_contentError != null && _contentCtrl.text.trim().isNotEmpty) {
      setState(() => _contentError = null);
    }
    if (widget.id == null || !_isEditingMode) return;
    _autosaveDebounce?.cancel();
    _autosaveDebounce = Timer(AppMotion.autosave, () => _onSubmit(autosave: true));
  }

  @override
  void dispose() {
    _autosaveDebounce?.cancel();
    getIt<AdminReadingBloc>().add(ClearSelectedReadingEvent());

    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _imageUrlCtrl.dispose();
    _minutesCtrl.dispose();
    _contentCtrl.dispose();
    _transTitleCtrl.dispose();
    _transContentCtrl.dispose();
    super.dispose();
  }

  void _populateData(ReadingEntity reading) {
    _titleCtrl.text = reading.title;
    _summaryCtrl.text = reading.summary;
    _imageUrlCtrl.text = reading.imageUrl ?? '';
    _minutesCtrl.text = reading.minutesToRead.toString();
    _difficulty = reading.difficulty?.name ?? 'medium';

    _contentCtrl.text = reading.content;
    _transTitleCtrl.text = reading.translation?.title ?? '';
    _transContentCtrl.text = reading.translation?.content ?? '';

    setState(() {
      questions = reading.questions.map((q) {
        return {
          "questionText": q.questionText,
          "options": List<String>.from(q.options),
          "correctAnswerIndex": q.correctAnswerIndex,
          "feedback": {
            "reasoning": q.feedback?.reasoning ?? "",
            "paragraphIndex": q.feedback?.paragraphIndex,
            "keySentence": q.feedback?.keySentence ?? ""
          },
          "translation": {
            "questionText": q.translation?.questionText ?? "",
            "options": q.translation?.options != null
                ? List<String>.from(q.translation!.options)
                : ["", "", "", ""]
          }
        };
      }).toList();

      _isEditingMode = true;
    });
  }

  ReadingDifficulty _parseDifficulty(String value) {
    switch (value) {
      case 'easy': return ReadingDifficulty.easy;
      case 'hard': return ReadingDifficulty.hard;
      default: return ReadingDifficulty.medium;
    }
  }

  void _onSubmit({bool autosave = false}) {
    FocusManager.instance.primaryFocus?.unfocus();

    final titleEmpty = _titleCtrl.text.trim().isEmpty;
    final contentEmpty = _contentCtrl.text.trim().isEmpty;
    if (titleEmpty || contentEmpty) {
      setState(() {
        _titleError = titleEmpty ? 'Title is required' : null;
        _contentError = contentEmpty ? 'Content is required' : null;
        _saveState = AdminSaveState.error;
      });
      return;
    }

    setState(() {
      _titleError = null;
      _contentError = null;
      _saveState = AdminSaveState.saving;
      _suppressNavigateOnSave = autosave;
    });

    List<ReadingQuestionEntity> questionEntities = [];
    try {
      for (var q in questions) {
        final qText = q['questionText']?.toString().trim() ?? '';
        if (qText.isEmpty) continue;

        final fbMap = q['feedback'] as Map<String, dynamic>? ?? {};
        final transMap = q['translation'] as Map<String, dynamic>? ?? {};

        List<String> options = [];
        if (q['options'] is List) {
          options = (q['options'] as List).map((e) => e.toString()).toList();
        }
        while (options.length < 4) options.add("");

        List<String> transOptions = [];
        if (transMap['options'] is List) {
          transOptions = (transMap['options'] as List).map((e) => e.toString()).toList();
        }
        while (transOptions.length < 4) transOptions.add("");

        questionEntities.add(ReadingQuestionEntity(
          id: '',
          questionText: qText,
          options: options,
          correctAnswerIndex: (q['correctAnswerIndex'] as int?) ?? 0,
          feedback: ReadingFeedbackEntity(
            reasoning: fbMap['reasoning']?.toString() ?? '',
            paragraphIndex: int.tryParse(fbMap['paragraphIndex']?.toString() ?? ''),
            keySentence: fbMap['keySentence']?.toString(),
          ),
          translation: QuestionTranslationEntity(
            questionText: transMap['questionText']?.toString() ?? '',
            options: transOptions,
          ),
        ));
      }

      final newReading = ReadingEntity(
        id: widget.id ?? '',
        title: _titleCtrl.text,
        summary: _summaryCtrl.text,
        content: _contentCtrl.text,
        imageUrl: _imageUrlCtrl.text.isNotEmpty ? _imageUrlCtrl.text : null,
        difficulty: _parseDifficulty(_difficulty),
        minutesToRead: int.tryParse(_minutesCtrl.text) ?? 5,
        questions: questionEntities,
        translation: TranslationEntity(
          title: _transTitleCtrl.text,
          content: _transContentCtrl.text,
        ),
      );

      // Edit mode (có id) → Update (tránh tạo bản trùng); ngược lại → Create.
      final bloc = context.read<AdminReadingBloc>();
      if (widget.id != null && widget.id!.isNotEmpty) {
        bloc.add(UpdateReadingEvent(widget.id!, newReading));
      } else {
        bloc.add(CreateReadingEvent(newReading));
      }

    } catch (e) {
      AppCornerToast.show(context, "Error processing data: $e", error: true);
    }
  }

  void _addNewQuestion() {
    setState(() {
      questions.add({
        "questionText": "",
        "options": ["", "", "", ""],
        "correctAnswerIndex": 0,
        "feedback": {"reasoning": "", "paragraphIndex": "", "keySentence": ""},
        "translation": {"questionText": "", "options": ["", "", "", ""]}
      });
    });
  }

  void _deleteQuestion(int index) {
    setState(() {
      questions.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminReadingBloc, AdminReadingState>(
      listener: (context, state) {
        if (state.status == AdminReadingStatus.failure) {
          if (mounted) {
            setState(() => _saveState = AdminSaveState.error);
          }
          if (!_suppressNavigateOnSave) {
            AppCornerToast.show(context, "Error: ${state.errorMessage}", error: true);
          }
        }

        if (state.selectedReading != null && widget.id != null) {
          if (state.selectedReading!.id == widget.id) {
            _populateData(state.selectedReading!);
            context.read<AdminReadingBloc>().add(ClearSelectedReadingEvent());
          }
        }

        if (state.status == AdminReadingStatus.saved) {
          if (_suppressNavigateOnSave) {
            setState(() {
              _saveState = AdminSaveState.saved;
              _savedAt = DateTime.now();
              _suppressNavigateOnSave = false;
            });
          } else {
            AppCornerToast.show(context, "Saved successfully!");
            context.pop();
          }
        }

        if (state.status == AdminReadingStatus.loading && _saveState == AdminSaveState.idle) {
          setState(() => _saveState = AdminSaveState.saving);
        }
      },
      child: Scaffold(
        backgroundColor: kBgPage,
        appBar: AppBar(
          backgroundColor: kWhite,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: kTextMain),
              onPressed: () => context.pop()),
          title: Text(widget.id == null ? 'New Reading' : 'Edit Reading',
              style: const TextStyle(color: kTextMain, fontWeight: FontWeight.w700, fontSize: 16)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s3),
              child: AdminSaveStateIndicator(
                state: _saveState,
                savedAt: _savedAt,
                onRetry: _saveState == AdminSaveState.error ? () => _onSubmit() : null,
              ),
            ),
            TextButton(
              onPressed: _saveState == AdminSaveState.saving ? null : () => _onSubmit(),
              child: const Text('Save',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
            const SizedBox(width: AppSpacing.s3),
          ],
          bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: kBorder, height: 1)),
        ),

        body: BlocBuilder<AdminReadingBloc, AdminReadingState>(
          builder: (context, state) {
            if (state.status == AdminReadingStatus.loading && widget.id != null && questions.isEmpty) {
              return AdminSkeleton.page(AdminSkeleton.cardList());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // --- CARD 1: GENERAL INFORMATION ---
                  ShadcnCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: "General Information"),

                        if (_imageUrlCtrl.text.isNotEmpty)
                          Container(
                            height: 160,
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppRadius.input),
                                border: Border.all(color: kBorder),
                                color: AppColors.surfaceSubtle,
                                image: DecorationImage(
                                  image: NetworkImage(_imageUrlCtrl.text),
                                  fit: BoxFit.cover,
                                  onError: (_,__) => const SizedBox(),
                                )
                            ),
                          ),

                        ShadcnInput(
                          label: "Image URL",
                          controller: _imageUrlCtrl,
                          isReadOnly: !_isEditingMode,
                          hint: "https://example.com/image.png",
                          onChanged: (val) => setState((){}),
                        ),
                        const SizedBox(height: 16),

                        ShadcnInput(label: "Title (English) *", controller: _titleCtrl, isReadOnly: !_isEditingMode),
                        AdminWebUi.formFieldError(context, _titleError),
                        const SizedBox(height: 16),

                        ShadcnInput(label: "Summary", controller: _summaryCtrl, maxLines: 2, isReadOnly: !_isEditingMode),
                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              flex: 2,
                              child: ShadcnInput(
                                  label: "Time (mins)",
                                  controller: _minutesCtrl,
                                  isReadOnly: !_isEditingMode,
                                  keyboardType: TextInputType.number
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Difficulty", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextMain)),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 48,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: _isEditingMode ? kWhite : AppColors.surfaceSubtle,
                                      borderRadius: BorderRadius.circular(AppRadius.input),
                                      border: Border.all(color: kBorder),
                                    ),
                                    child: Row(
                                      children: ['easy', 'medium', 'hard'].map((level) {
                                        final isSelected = _difficulty == level;
                                        return Expanded(
                                          child: GestureDetector(
                                            onTap: _isEditingMode ? () => setState(() => _difficulty = level) : null,
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 2),
                                              decoration: BoxDecoration(
                                                color: isSelected ? kTextMain : Colors.transparent,
                                                borderRadius: BorderRadius.circular(AppRadius.chip),
                                              ),
                                              alignment: Alignment.center,
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  level.toUpperCase(),
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: isSelected ? Colors.white : kTextMuted
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- CARD 2: CONTENT & TRANSLATION ---
                  ShadcnCard(
                    child: Column(
                      children: [
                        const SectionHeader(title: "Content & Translation"),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.infoBg,
                            borderRadius: BorderRadius.circular(AppRadius.input),
                            border: Border.all(color: AppColors.infoBg),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("🇬🇧 English Original", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.info)),
                              const SizedBox(height: 8),
                              ShadcnInput(label: "", controller: _contentCtrl, maxLines: 8, isReadOnly: !_isEditingMode, hint: "Paste English text here..."),
                              AdminWebUi.formFieldError(context, _contentError),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warningBg,
                            borderRadius: BorderRadius.circular(AppRadius.input),
                            border: Border.all(color: AppColors.warningBg),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("🇻🇳 Vietnamese Translation", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warning)),
                              const SizedBox(height: 8),
                              ShadcnInput(label: "Translated Title", controller: _transTitleCtrl, isReadOnly: !_isEditingMode),
                              const SizedBox(height: 8),
                              ShadcnInput(label: "Translated Content", controller: _transContentCtrl, maxLines: 8, isReadOnly: !_isEditingMode),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- CARD 3: QUESTIONS ---
                  ShadcnCard(
                    child: Column(
                      children: [
                        SectionHeader(
                          title: "Quiz Questions (${questions.length})",
                          action: _isEditingMode
                              ? OutlinedButton.icon(
                            onPressed: _addNewQuestion,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text("Add Question"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kTextMain,
                              side: const BorderSide(color: kBorder),
                            ),
                          )
                              : null,
                        ),
                        const SizedBox(height: 8),

                        if (questions.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text("No questions yet.", style: TextStyle(color: kTextMuted)),
                          )
                        else
                          ...questions.asMap().entries.map((entry) {
                            return _buildQuestionEditor(entry.key, entry.value);
                          }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuestionEditor(int index, Map<String, dynamic> q) {
    final options = List<String>.from(q['options'] ?? []);
    final transMap = q['translation'] as Map<String, dynamic>? ?? {};
    final transOptions = List<String>.from(transMap['options'] ?? []);
    final feedback = q['feedback'] as Map<String, dynamic>? ?? {};

    while (options.length < 4) options.add("");
    while (transOptions.length < 4) transOptions.add("");

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(AppRadius.input),
        color: kWhite,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: index == 0,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          backgroundColor: AppColors.surfaceSubtle,
          collapsedBackgroundColor: kWhite,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: kTextMain, borderRadius: BorderRadius.circular(AppRadius.chip)),
                child: Text("Q${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  q['questionText']?.toString().isEmpty ?? true ? "(New Question)" : q['questionText'],
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          trailing: _isEditingMode
              ? IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteQuestion(index))
              : null,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: kBorder)),
                color: kWhite,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShadcnInput(
                    label: "Question (English)",
                    controller: TextEditingController(text: q['questionText']),
                    isReadOnly: !_isEditingMode,
                    onChanged: (val) => q['questionText'] = val,
                  ),
                  const SizedBox(height: 12),
                  ShadcnInput(
                    label: "Question (Vietnamese)",
                    controller: TextEditingController(text: transMap['questionText']),
                    isReadOnly: !_isEditingMode,
                    onChanged: (val) => transMap['questionText'] = val,
                  ),
                  const SizedBox(height: 20),

                  const Text("Options & Correct Answer", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextMuted)),
                  const SizedBox(height: 8),

                  RadioGroup<int>(
                    groupValue: q['correctAnswerIndex'] as int?,
                    onChanged: (val) {
                      if (_isEditingMode) setState(() => q['correctAnswerIndex'] = val);
                    },
                    child: Column(
                      children: List.generate(4, (optIdx) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Transform.scale(
                                  scale: 1.1,
                                  child: Radio<int>(
                                    value: optIdx,
                                    fillColor: const WidgetStatePropertyAll(Colors.green),
                                  ),
                                ),
                              ),
                          Expanded(
                            child: Column(
                              children: [
                                ShadcnInput(
                                  label: "",
                                  hint: "Option ${optIdx + 1} (EN)",
                                  controller: TextEditingController(text: options[optIdx]),
                                  isReadOnly: !_isEditingMode,
                                  onChanged: (val) => (q['options'] as List)[optIdx] = val,
                                ),
                                const SizedBox(height: 6),
                                ShadcnInput(
                                  label: "",
                                  hint: "Option ${optIdx + 1} (VN)",
                                  controller: TextEditingController(text: transOptions[optIdx]),
                                  isReadOnly: !_isEditingMode,
                                  onChanged: (val) => (transMap['options'] as List)[optIdx] = val,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                      }),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Feedback Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: AppColors.successBg,
                        border: Border.all(color: AppColors.successBg),
                        borderRadius: BorderRadius.circular(AppRadius.input)
                    ),
                    child: Column(
                      children: [
                        Row(children: [
                          const Icon(Icons.lightbulb, size: 18, color: AppColors.success),
                          const SizedBox(width: 8),
                          const Text("Explanation / Feedback", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success))
                        ]),
                        const SizedBox(height: 12),
                        ShadcnInput(
                          label: "Reasoning",
                          controller: TextEditingController(text: feedback['reasoning']),
                          isReadOnly: !_isEditingMode,
                          maxLines: 2,
                          onChanged: (val) => feedback['reasoning'] = val,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: ShadcnInput(
                                label: "Para Index",
                                hint: "1",
                                controller: TextEditingController(text: feedback['paragraphIndex']?.toString()),
                                isReadOnly: !_isEditingMode,
                                keyboardType: TextInputType.number,
                                onChanged: (val) => feedback['paragraphIndex'] = val,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: ShadcnInput(
                                label: "Key Sentence",
                                controller: TextEditingController(text: feedback['keySentence']),
                                isReadOnly: !_isEditingMode,
                                onChanged: (val) => feedback['keySentence'] = val,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}




