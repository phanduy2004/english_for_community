import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Đảm bảo import đúng các file entity/bloc của dự án bạn
import 'package:english_for_community/core/entity/writing_topic_entity.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/repository/writing_repository.dart';
import 'package:english_for_community/feature/writing/writing_task_bloc/writing_task_bloc.dart';
import 'package:english_for_community/feature/writing/writing_task_bloc/writing_task_event.dart';
import 'package:english_for_community/feature/writing/writing_task_bloc/writing_task_state.dart';
import 'package:english_for_community/feature/writing/writing_feedback_page.dart';
import 'package:english_for_community/feature/writing/writing_task_instruction_dialog.dart';
import '../../core/locale/l10n_context.dart';
import '../../core/ui/feedback/app_feedback.dart';
import '../../core/theme/app_color.dart';
import '../../core/theme/app_skill_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/ui/exam_system_ui.dart';
import '../../core/ui/student_mobile_ui.dart';
import '../../l10n/generated/app_localizations.dart';
import '../student/exams/exam_embedded_skill_scope.dart';
import '../student/exams/exam_integrity_tracker.dart';
import '../auth/bloc/user_bloc.dart';

class WritingTaskPage extends StatelessWidget {
  final WritingTopicEntity topic;
  final String selectedTaskType;
  final String? userId;
  final bool embedded;
  final bool examPracticeMode;
  final bool readOnlyReview;
  final String? initialExamDraft;
  final VoidCallback? onPartComplete;
  final void Function(String text)? onEmbeddedDraftChanged;
  final Widget Function(BuildContext, WritingTaskState, String?, ValueChanged<String?>)? promptBuilder;
  final Widget Function(BuildContext, TextEditingController, ValueChanged<String>)? editorBuilder;
  final Widget Function(BuildContext, int, bool, VoidCallback)? bottomBarBuilder;
  /// When provided, bypasses AI generation and uses this teacher-assigned prompt.
  final Map<String, dynamic>? fixedPrompt;

  const WritingTaskPage({
    super.key,
    required this.topic,
    required this.selectedTaskType,
    this.userId,
    this.embedded = false,
    this.examPracticeMode = false,
    this.readOnlyReview = false,
    this.initialExamDraft,
    this.onPartComplete,
    this.onEmbeddedDraftChanged,
    this.promptBuilder,
    this.editorBuilder,
    this.bottomBarBuilder,
    this.fixedPrompt,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUserId = userId ?? _tryResolveUserIdFromBloc(context);
    if (resolvedUserId == null || resolvedUserId.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: StudentMobileUi.appBar(context, title: context.l10n.commonError),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              context.l10n.commonError,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return BlocProvider(
      create: (_) => WritingTaskBloc(
        writingRepository: getIt<WritingRepository>(),
      )..add(GeneratePromptAndStartTask(
        topic: topic,
        userId: resolvedUserId,
        taskType: selectedTaskType,
        freshStart: examPracticeMode,
        fixedPrompt: fixedPrompt,
      )),
      child: WritingTaskView(
        initialTaskType: selectedTaskType,
        embedded: embedded,
        examPracticeMode: examPracticeMode,
        readOnlyReview: readOnlyReview,
        initialExamDraft: initialExamDraft,
        onPartComplete: onPartComplete,
        onEmbeddedDraftChanged: onEmbeddedDraftChanged,
        promptBuilder: promptBuilder,
        editorBuilder: editorBuilder,
        bottomBarBuilder: bottomBarBuilder,
      ),
    );
  }

  String? _tryResolveUserIdFromBloc(BuildContext context) {
    try {
      return BlocProvider.of<UserBloc>(context).state.userEntity?.id;
    } catch (_) {
      return null;
    }
  }
}

class WritingTaskView extends StatefulWidget {
  final String? initialTaskType;
  final bool embedded;
  final bool examPracticeMode;
  final bool readOnlyReview;
  final String? initialExamDraft;
  final VoidCallback? onPartComplete;
  final void Function(String text)? onEmbeddedDraftChanged;
  final Widget Function(BuildContext, WritingTaskState, String?, ValueChanged<String?>)? promptBuilder;
  final Widget Function(BuildContext, TextEditingController, ValueChanged<String>)? editorBuilder;
  final Widget Function(BuildContext, int, bool, VoidCallback)? bottomBarBuilder;

  const WritingTaskView({
    super.key,
    this.initialTaskType,
    this.embedded = false,
    this.examPracticeMode = false,
    this.readOnlyReview = false,
    this.initialExamDraft,
    this.onPartComplete,
    this.onEmbeddedDraftChanged,
    this.promptBuilder,
    this.editorBuilder,
    this.bottomBarBuilder,
  });

  @override
  State<WritingTaskView> createState() => _WritingTaskViewState();
}

class _WritingTaskViewState extends State<WritingTaskView> {
  static const int _minimumSubmitWords = 50;
  static const Duration _autoSaveDebounce = Duration(seconds: 4);

  final _text = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  String? _taskType;
  int _wordCount = 0;
  bool _isDirty = false;
  late final Stopwatch _writingStopwatch;
  bool _hasShownResumeDialog = false;
  bool _isAutoSaving = false;
  bool _shouldCloseAfterSave = false;
  Timer? _autoSaveTimer;
  Timer? _embeddedDraftNotifyTimer;
  Timer? _savedStatusTicker;
  DateTime? _lastAutoSavedAt;
  String _lastAutoSavedContent = '';
  bool _showMinWordsError = false;

  @override
  void initState() {
    super.initState();
    _taskType = widget.initialTaskType;
    _writingStopwatch = Stopwatch()..start();

    _text.addListener(() {
      final t = _text.text;
      setState(() {
        _wordCount = t.trim().isEmpty ? 0 : t.trim().split(RegExp(r'\s+')).length;
        if (_wordCount > 0) _isDirty = true;
        if (_canSubmitNow) _showMinWordsError = false;
      });
      _scheduleAutoSave();
      _scheduleEmbeddedDraftNotify();
    });

    _savedStatusTicker = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      if (_lastAutoSavedAt != null) {
        setState(() {});
      }
    });

    _applyInitialExamDraft(widget.initialExamDraft);
  }

  void _applyInitialExamDraft(String? draft) {
    final t = draft?.trim() ?? '';
    if (t.isEmpty) return;
    if (_text.text.trim() == t) return;
    _text.text = t;
    _wordCount = t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  @override
  void didUpdateWidget(covariant WritingTaskView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialExamDraft != oldWidget.initialExamDraft) {
      _applyInitialExamDraft(widget.initialExamDraft);
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _savedStatusTicker?.cancel();
    _text.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _writingStopwatch.stop();
    super.dispose();
  }

  void _showInstructionDialog() {
    if (_taskType == null) return;
    showDialog(
      context: context,
      builder: (context) => WritingTaskInstructionDialog(taskType: _taskType!),
    );
  }

  void _submit(WritingTaskState s) {
    if (s.submission == null || _taskType == null) return;
    if (!_canSubmitNow) {
      setState(() => _showMinWordsError = true);
      return;
    }
    // Huỷ autosave đang chờ để nó không bắn SaveDraft đè mất trạng thái submitting.
    _autoSaveTimer?.cancel();
    FocusScope.of(context).unfocus();
    final durationInSeconds = _writingStopwatch.elapsed.inSeconds;
    context.read<WritingTaskBloc>().add(
      SubmitForFeedback(
        submissionId: s.submission!.id,
        essayContent: _text.text,
        taskType: _taskType!,
        durationInSeconds: durationInSeconds,
      ),
    );
  }

  // --- DIALOG THOÁT (Chuẩn Android) ---
  Future<void> _onWillPop(bool didPop, Object? result) async {
    if (didPop) return;
    final state = context.read<WritingTaskBloc>().state;
    if (state.submission == null || !_isDirty) {
      Navigator.of(context).pop();
      return;
    }

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final t = ctx.l10n;
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          surfaceTintColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sheet),
          ),
          title: Text(
            t.writingSaveDraftTitle,
            style: StudentMobileUi.sectionTitle(ctx),
          ),
          content: Text(
            t.writingSaveDraftMessage,
            style: StudentMobileUi.body(ctx),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
              ),
              child: Text(t.writingDiscardButton),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: Text(t.saveChanges),
            ),
          ],
        );
      },
    );

    if (shouldSave == null) return;
    if (shouldSave == false) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (shouldSave == true) {
      if (mounted) {
        _shouldCloseAfterSave = true;
        context.read<WritingTaskBloc>().add(SaveDraftEvent(
          submissionId: state.submission!.id,
          content: _text.text,
        ));
      }
    }
  }

  bool get _canSubmitNow => _wordCount >= _minimumSubmitWords;

  String? get _savedLabel {
    final last = _lastAutoSavedAt;
    if (last == null) return null;
    final elapsed = DateTime.now().difference(last);
    if (elapsed.inSeconds < 10) return 'Saved just now';
    if (elapsed.inSeconds < 60) return 'Saved ${elapsed.inSeconds}s ago';
    if (elapsed.inMinutes < 60) return 'Saved ${elapsed.inMinutes}m ago';
    return 'Saved';
  }

  String? _resolveUserId() {
    try {
      return BlocProvider.of<UserBloc>(context).state.userEntity?.id;
    } catch (_) {
      return null;
    }
  }

  void _scheduleEmbeddedDraftNotify() {
    if (!widget.embedded || widget.onEmbeddedDraftChanged == null) return;
    _embeddedDraftNotifyTimer?.cancel();
    _embeddedDraftNotifyTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      widget.onEmbeddedDraftChanged!(_text.text);
    });
  }

  void _scheduleAutoSave() {
    if (widget.examPracticeMode) return;
    final blocState = context.read<WritingTaskBloc>().state;
    final submissionId = blocState.submission?.id;
    final text = _text.text.trim();
    if (submissionId == null || submissionId.isEmpty) return;
    if (!_isDirty || text.isEmpty) return;
    if (blocState.status == WritingTaskStatus.submitting) return;
    if (text == _lastAutoSavedContent.trim()) return;

    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDebounce, () {
      if (!mounted) return;
      // Đừng autosave khi đang nộp bài (tránh đè mất trạng thái submitting).
      if (context.read<WritingTaskBloc>().state.status ==
          WritingTaskStatus.submitting) {
        return;
      }
      setState(() => _isAutoSaving = true);
      context.read<WritingTaskBloc>().add(
            SaveDraftEvent(
              submissionId: submissionId,
              content: _text.text,
            ),
          );
    });
  }

  void _showResumeConflictDialog(BuildContext context, String serverTaskType, String submissionId, String oldContent) {
    if (_hasShownResumeDialog) return;
    _hasShownResumeDialog = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final t = ctx.l10n;
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          surfaceTintColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sheet),
          ),
          title: Text(
            t.writingResumeTitle,
            style: StudentMobileUi.sectionTitle(ctx),
          ),
          content: Text(
            t.writingResumeMessage,
            style: StudentMobileUi.body(ctx),
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(ctx);
                final currentState = context.read<WritingTaskBloc>().state;
                if (currentState.topic != null) {
                  final userId = _resolveUserId();
                  if (userId == null || userId.isEmpty) return;
                  context.read<WritingTaskBloc>().add(DiscardDraftAndStartNew(
                    oldSubmissionId: submissionId,
                    topic: currentState.topic!,
                    userId: userId,
                    taskType: _taskType ?? 'Discussion',
                  ));
                  _text.clear();
                  _isDirty = false;
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
              ),
              child: Text(t.writingStartNewButton),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _taskType = serverTaskType;
                  _text.text = oldContent;
                  _isDirty = false;
                });
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: Text(t.writingResumeButton),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaskScaffold(BuildContext context, AppLocalizations t, Widget child) {
    if (widget.embedded) {
      return child;
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        resizeToAvoidBottomInset: true,
        appBar: StudentMobileUi.skillAppBar(
          context,
          title: context.watch<WritingTaskBloc>().state.topic?.name ?? t.writingTaskDefaultTitle,
          skill: SkillType.writing,
          actions: [
            IconButton(
              icon: const Icon(Icons.lightbulb_outline, size: 20),
              color: AppColors.textPrimary,
              tooltip: t.writingInstructionsTooltip,
              onPressed: _showInstructionDialog,
            ),
          ],
        ),
        body: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return _buildTaskScaffold(
      context,
      t,
      BlocConsumer<WritingTaskBloc, WritingTaskState>(
          listenWhen: (p, c) => p.status != c.status || p.submission != c.submission,
          listener: (context, state) {
            // ... Logic Listener giữ nguyên
            if (state.status == WritingTaskStatus.promptReady && state.submission != null) {
              final examDraft = widget.initialExamDraft?.trim() ?? '';
              if (widget.examPracticeMode && examDraft.isNotEmpty && _text.text.isEmpty) {
                _text.text = examDraft;
                _wordCount = examDraft.trim().isEmpty ? 0 : examDraft.trim().split(RegExp(r'\s+')).length;
                widget.onEmbeddedDraftChanged?.call(examDraft);
              }
              final hasDraftContent = state.submission!.content.isNotEmpty;
              final isDraftStatus = state.submission!.status == 'draft';
              if (!widget.examPracticeMode &&
                  hasDraftContent &&
                  isDraftStatus &&
                  !_hasShownResumeDialog) {
                Future.delayed(Duration.zero, () {
                  if (mounted) {
                    _showResumeConflictDialog(context, state.submission!.generatedPrompt?.taskType ?? 'Essay', state.submission!.id, state.submission!.content);
                  }
                });
              } else if (!hasDraftContent && isDraftStatus) {
                _text.clear();
                _isDirty = false;
                _hasShownResumeDialog = false;
              }
            }
            if (state.status == WritingTaskStatus.savedSuccess) {
              _lastAutoSavedContent = _text.text;
              _lastAutoSavedAt = DateTime.now();
              _isAutoSaving = false;
              if (_shouldCloseAfterSave) {
                _shouldCloseAfterSave = false;
                AppFeedback.success(context, context.l10n.writingDraftSavedSnack);
                Navigator.of(context).pop();
              }
            }
            if (state.status == WritingTaskStatus.success && state.submission != null) {
              _writingStopwatch.stop();
              if (widget.examPracticeMode) {
                return;
              }
              if (widget.embedded) {
                widget.onPartComplete?.call();
                AppFeedback.success(context, context.l10n.studentExamSubmitted);
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => WritingFeedbackPage(submission: state.submission!)),
                );
              }
            }
            if (state.status == WritingTaskStatus.error) {
              _isAutoSaving = false;
              AppFeedback.error(context, state.errorMessage ?? context.l10n.genericLoadError, blocking: true);
            }
          },
          builder: (context, state) {
            if (state.status == WritingTaskStatus.loading) {
              return StudentMobileUi.runnerLoading();
            }
            if (state.submission == null) {
              return Center(child: Text(context.l10n.writingPreparingTask, style: const TextStyle(color: AppColors.textSecondary)));
            }
            if (_taskType == null) {
              _taskType = state.submission!.generatedPrompt?.taskType ?? widget.initialTaskType;
            }

            final isSubmitting = state.status == WritingTaskStatus.submitting;

            return SafeArea(
              child: Column(
                children: [
                  // 1. PHẦN CUỘN (Prompt + Editor)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (!_focusNode.hasFocus) _focusNode.requestFocus();
                      },
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // A. Prompt Card
                            widget.promptBuilder != null
                                ? widget.promptBuilder!(context, state, _taskType, (v) => setState(() => _taskType = v))
                                : _PromptCard(
                              title: state.submission!.generatedPrompt?.title ?? context.l10n.writingTopicFallback,
                              text: state.submission!.generatedPrompt?.text ?? '',
                            ),

                            // B. Editor
                            widget.editorBuilder != null
                                ? widget.editorBuilder!(context, _text, (_) {})
                                : _Editor(
                              controller: _text,
                              focusNode: _focusNode,
                              readOnly: isSubmitting || widget.readOnlyReview,
                            ),

                            SizedBox(
                              height: MediaQuery.of(context).viewInsets.bottom > 0
                                  ? AppSpacing.s5
                                  : AppSpacing.s3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 2. BOTTOM BAR (Layout Cũ: Ngang)
                  if (!widget.examPracticeMode)
                    widget.bottomBarBuilder != null
                        ? widget.bottomBarBuilder!(context, _wordCount, isSubmitting, () => _submit(state))
                        : _ClassicBottomBar(
                      wordCount: _wordCount,
                      minWords: _minimumSubmitWords,
                      busy: isSubmitting,
                      canSubmit: _canSubmitNow,
                      isAutoSaving: _isAutoSaving,
                      savedLabel: _savedLabel,
                      validationMessage: _showMinWordsError
                          ? 'Please write at least $_minimumSubmitWords words before submitting.'
                          : null,
                      onSubmit: () => _submit(state),
                    )
                  else if (widget.readOnlyReview)
                    const SizedBox.shrink()
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Text(
                        '${context.l10n.wordCountN(_wordCount)} · ${context.l10n.integratedExamEmbeddedHint}',
                        style: ExamSystemUi.captionSecondary,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
    );
  }
}

// --- CÁC WIDGET CON ---

// 1. Prompt Card (Có thể thu gọn)
class _PromptCard extends StatefulWidget {
  final String title;
  final String text;
  const _PromptCard({required this.title, required this.text});

  @override
  State<_PromptCard> createState() => _PromptCardState();
}

class _PromptCardState extends State<_PromptCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final compact = ExamEmbeddedSkillScope.compactOf(context);
    return Container(
      margin: EdgeInsets.all(compact ? 10 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outline),
        boxShadow: compact ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.outlineMuted, borderRadius: BorderRadius.circular(AppRadius.input)),
                    child: const Icon(Icons.article_outlined, size: 20, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: compact
                              ? ExamSystemUi.embeddedListTitle(context)
                              : const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isExpanded ? t.writingPromptTapCollapse : t.writingPromptTapExpand,
                          style: compact ? ExamSystemUi.embeddedCaptionStyle : const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(_isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.surfaceSubtle, borderRadius: BorderRadius.circular(AppRadius.input), border: Border.all(color: AppColors.outline.withValues(alpha: 0.5))),
                child: Text(
                  widget.text,
                  style: compact ? ExamSystemUi.embeddedBodyStyle : const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textPrimary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// 2. Editor (Clean UI)
class _Editor extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool readOnly;

  const _Editor({required this.controller, required this.focusNode, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final compact = ExamEmbeddedSkillScope.compactOf(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final editorMinHeight = (screenHeight * (compact ? 0.26 : 0.30))
        .clamp(compact ? 120.0 : 160.0, compact ? 180.0 : 240.0)
        .toDouble();

    return Container(
      constraints: BoxConstraints(minHeight: editorMinHeight),
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
      child: TextField(
        controller: controller,
        contextMenuBuilder: examPasteAwareContextMenu,
        focusNode: focusNode,
        readOnly: readOnly,
        maxLines: null,
        minLines: 1,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        style: compact
            ? ExamSystemUi.embeddedBodyStyle.copyWith(color: AppColors.textPrimary)
            : StudentMobileUi.bodyLg(context),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: t.writingEditorHint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }
}

// 3. Bottom Bar (Layout Cũ: Ngang + Nút Submit)
class _ClassicBottomBar extends StatelessWidget {
  final int wordCount;
  final int minWords;
  final bool busy;
  final bool canSubmit;
  final bool isAutoSaving;
  final String? savedLabel;
  final String? validationMessage;
  final VoidCallback onSubmit;

  const _ClassicBottomBar({
    required this.wordCount,
    required this.minWords,
    required this.busy,
    required this.canSubmit,
    required this.isAutoSaving,
    required this.savedLabel,
    this.validationMessage,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final progress = (wordCount / minWords).clamp(0.0, 1.0);
    final progressLabel = isAutoSaving
        ? 'Saving…'
        : savedLabel != null
            ? '${t.wordCountN(wordCount)} · $savedLabel'
            : '${t.wordCountN(wordCount)} ($minWords+)';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            StudentMobileUi.pageHPadding,
            AppSpacing.s3,
            StudentMobileUi.pageHPadding,
            0,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.outlineMuted,
              color: canSubmit ? AppColors.success : AppColors.warning,
            ),
          ),
        ),
        AppFeedback.fieldError(validationMessage),
        StudentMobileUi.bottomActionBar(
          context: context,
          progressLabel: progressLabel,
          ctaLabel: t.writingSubmitEssay,
          onCta: onSubmit,
          ctaEnabled: canSubmit,
          loading: busy,
        ),
      ],
    );
  }
}
