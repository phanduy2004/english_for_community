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
import '../auth/bloc/user_bloc.dart';

// --- 1. ĐỊNH NGHĨA MÀU SẮC (Theme Local) ---
class _Colors {
  static const bgSubtle = Color(0xFFFAFAFA); // Nền xám rất nhạt
  static const border = Color(0xFFE4E4E7);   // Viền xám
  static const textMain = Color(0xFF09090B); // Chữ đen đậm
  static const textMuted = Color(0xFF71717A);// Chữ xám ghi
  static const primary = Color(0xFF18181B);  // Đen (Primary Button)
  static const accent = Color(0xFFF4F4F5);   // Nền icon
  static const error = Color(0xFFEF4444);    // Đỏ
}

class WritingTaskPage extends StatelessWidget {
  final WritingTopicEntity topic;
  final String selectedTaskType;
  final String? userId;
  final Widget Function(BuildContext, WritingTaskState, String?, ValueChanged<String?>)? promptBuilder;
  final Widget Function(BuildContext, TextEditingController, ValueChanged<String>)? editorBuilder;
  final Widget Function(BuildContext, int, bool, VoidCallback)? bottomBarBuilder;

  const WritingTaskPage({
    super.key,
    required this.topic,
    required this.selectedTaskType,
    this.userId,
    this.promptBuilder,
    this.editorBuilder,
    this.bottomBarBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUserId = userId ?? _tryResolveUserIdFromBloc(context);
    if (resolvedUserId == null || resolvedUserId.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
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
      )),
      child: WritingTaskView(
        initialTaskType: selectedTaskType,
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
  final Widget Function(BuildContext, WritingTaskState, String?, ValueChanged<String?>)? promptBuilder;
  final Widget Function(BuildContext, TextEditingController, ValueChanged<String>)? editorBuilder;
  final Widget Function(BuildContext, int, bool, VoidCallback)? bottomBarBuilder;

  const WritingTaskView({
    super.key,
    this.initialTaskType,
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
  Timer? _savedStatusTicker;
  DateTime? _lastAutoSavedAt;
  String _lastAutoSavedContent = '';
  bool _isProgrammaticEdit = false;
  TextEditingValue _lastEditingValue = const TextEditingValue();
  final List<TextEditingValue> _undoStack = <TextEditingValue>[];
  final List<TextEditingValue> _redoStack = <TextEditingValue>[];

  @override
  void initState() {
    super.initState();
    _taskType = widget.initialTaskType;
    _writingStopwatch = Stopwatch()..start();
    _lastEditingValue = _text.value;

    _text.addListener(() {
      if (!_isProgrammaticEdit && _text.value != _lastEditingValue) {
        _undoStack.add(_lastEditingValue);
        if (_undoStack.length > 120) {
          _undoStack.removeAt(0);
        }
        _redoStack.clear();
        _lastEditingValue = _text.value;
      }
      final t = _text.text;
      setState(() {
        _wordCount = t.trim().isEmpty ? 0 : t.trim().split(RegExp(r'\s+')).length;
        if (_wordCount > 0) _isDirty = true;
      });
      _scheduleAutoSave();
    });

    _savedStatusTicker = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      if (_lastAutoSavedAt != null) {
        setState(() {});
      }
    });
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please write at least $_minimumSubmitWords words before submitting.')),
      );
      return;
    }
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
  Future<void> _onWillPop(bool didPop) async {
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(t.writingSaveDraftTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
        content: Text(
          t.writingSaveDraftMessage,
          style: const TextStyle(color: _Colors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(t.cancel, style: const TextStyle(color: _Colors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.writingDiscardButton, style: const TextStyle(color: _Colors.error)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.saveChanges, style: const TextStyle(fontWeight: FontWeight.bold, color: _Colors.primary)),
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

  void _scheduleAutoSave() {
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
      setState(() => _isAutoSaving = true);
      context.read<WritingTaskBloc>().add(
            SaveDraftEvent(
              submissionId: submissionId,
              content: _text.text,
            ),
          );
    });
  }

  void _insertAtCursor(String insertion) {
    final value = _text.value;
    final selection = value.selection;
    if (!selection.isValid) {
      _applyEditingValue(
        TextEditingValue(
          text: value.text + insertion,
          selection: TextSelection.collapsed(offset: value.text.length + insertion.length),
        ),
      );
      return;
    }
    final start = selection.start;
    final end = selection.end;
    final newText = value.text.replaceRange(start, end, insertion);
    final newOffset = start + insertion.length;
    _applyEditingValue(
      TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      ),
    );
  }

  void _applyEditingValue(TextEditingValue next) {
    _isProgrammaticEdit = true;
    _text.value = next;
    _lastEditingValue = next;
    _isProgrammaticEdit = false;
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final current = _text.value;
    final prev = _undoStack.removeLast();
    _redoStack.add(current);
    _applyEditingValue(prev);
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    final current = _text.value;
    final next = _redoStack.removeLast();
    _undoStack.add(current);
    _applyEditingValue(next);
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(t.writingResumeTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
        content: Text(
          t.writingResumeMessage,
          style: const TextStyle(color: _Colors.textMuted),
        ),
        actions: [
          TextButton(
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
            child: Text(t.writingStartNewButton, style: const TextStyle(color: _Colors.error)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _taskType = serverTaskType;
                _text.text = oldContent;
                _isDirty = false;
              });
            },
            child: Text(t.writingResumeButton, style: const TextStyle(fontWeight: FontWeight.bold, color: _Colors.primary)),
          ),
        ],
      );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return PopScope(
      canPop: false,
      onPopInvoked: _onWillPop,
      child: Scaffold(
        backgroundColor: _Colors.bgSubtle,
        // Quan trọng: Co lại khi bàn phím hiện
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          shape: const Border(bottom: BorderSide(color: _Colors.border)),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: _Colors.textMain),
            onPressed: () => _onWillPop(false),
          ),
          title: Column(
            children: [
              Text(
                context.watch<WritingTaskBloc>().state.topic?.name ?? t.writingTaskDefaultTitle,
                style: const TextStyle(color: _Colors.textMain, fontWeight: FontWeight.w600, fontSize: 16),
              ),
              if (_taskType != null)
                Text(
                  _taskType!,
                  style: const TextStyle(color: _Colors.textMuted, fontSize: 11, fontWeight: FontWeight.w400),
                ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.lightbulb_outline, color: _Colors.textMain),
              tooltip: t.writingInstructionsTooltip,
              onPressed: _showInstructionDialog,
            ),
          ],
        ),
        body: BlocConsumer<WritingTaskBloc, WritingTaskState>(
          listenWhen: (p, c) => p.status != c.status || p.submission != c.submission,
          listener: (context, state) {
            // ... Logic Listener giữ nguyên
            if (state.status == WritingTaskStatus.promptReady && state.submission != null) {
              final hasDraftContent = state.submission!.content.isNotEmpty;
              final isDraftStatus = state.submission!.status == 'draft';
              if (hasDraftContent && isDraftStatus && !_hasShownResumeDialog) {
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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.writingDraftSavedSnack)));
                Navigator.of(context).pop();
              }
            }
            if (state.status == WritingTaskStatus.success && state.submission != null) {
              _writingStopwatch.stop();
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => WritingFeedbackPage(submission: state.submission!)));
            }
            if (state.status == WritingTaskStatus.error) {
              _isAutoSaving = false;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage ?? context.l10n.genericLoadError)));
            }
          },
          builder: (context, state) {
            if (state.status == WritingTaskStatus.loading) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _Colors.primary));
            }
            if (state.submission == null) {
              return Center(child: Text(context.l10n.writingPreparingTask, style: const TextStyle(color: _Colors.textMuted)));
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
                              readOnly: isSubmitting,
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: _EditorQuickToolbar(
                                onUndo: _undoStack.isEmpty ? null : _undo,
                                onRedo: _redoStack.isEmpty ? null : _redo,
                                onInsertPeriod: () => _insertAtCursor('. '),
                                onInsertComma: () => _insertAtCursor(', '),
                                onInsertNewLine: () => _insertAtCursor('\n'),
                              ),
                            ),

                            // C. Spacer
                            SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 300 : 100),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 2. BOTTOM BAR (Layout Cũ: Ngang)
                  widget.bottomBarBuilder != null
                      ? widget.bottomBarBuilder!(context, _wordCount, isSubmitting, () => _submit(state))
                      : _ClassicBottomBar(
                    wordCount: _wordCount,
                    minWords: _minimumSubmitWords,
                    busy: isSubmitting,
                    canSubmit: _canSubmitNow,
                    isAutoSaving: _isAutoSaving,
                    savedLabel: _savedLabel,
                    onSubmit: () => _submit(state),
                  ),
                ],
              ),
            );
          },
        ),
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
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Colors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _Colors.accent, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.article_outlined, size: 20, color: _Colors.textMain),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _Colors.textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(_isExpanded ? t.writingPromptTapCollapse : t.writingPromptTapExpand, style: const TextStyle(fontSize: 12, color: _Colors.textMuted)),
                      ],
                    ),
                  ),
                  Icon(_isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: _Colors.textMuted),
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
                decoration: BoxDecoration(color: _Colors.bgSubtle, borderRadius: BorderRadius.circular(8), border: Border.all(color: _Colors.border.withOpacity(0.5))),
                child: Text(widget.text, style: const TextStyle(fontSize: 14, height: 1.5, color: _Colors.textMain)),
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
    return Container(
      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        readOnly: readOnly,
        maxLines: null,
        minLines: 1,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(fontSize: 16, height: 1.6, color: _Colors.textMain),
        cursorColor: _Colors.primary,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: t.writingEditorHint,
          hintStyle: const TextStyle(color: Color(0xFFD4D4D8)),
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
  final VoidCallback onSubmit;

  const _ClassicBottomBar({
    required this.wordCount,
    required this.minWords,
    required this.busy,
    required this.canSubmit,
    required this.isAutoSaving,
    required this.savedLabel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final progress = (wordCount / minWords).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _Colors.border)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  '${t.wordCountN(wordCount)}  ($minWords+)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: canSubmit ? _Colors.textMuted : Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                if (isAutoSaving)
                  const Text(
                    'Saving...',
                    style: TextStyle(fontSize: 12, color: _Colors.textMuted),
                  )
                else if (savedLabel != null)
                  Text(
                    savedLabel!,
                    style: const TextStyle(fontSize: 12, color: _Colors.textMuted),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: busy || !canSubmit ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Colors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: busy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(t.writingSubmitEssay, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: const Color(0xFFF4F4F5),
                color: canSubmit ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorQuickToolbar extends StatelessWidget {
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback onInsertPeriod;
  final VoidCallback onInsertComma;
  final VoidCallback onInsertNewLine;

  const _EditorQuickToolbar({
    required this.onUndo,
    required this.onRedo,
    required this.onInsertPeriod,
    required this.onInsertComma,
    required this.onInsertNewLine,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _QuickToolButton(icon: Icons.undo_rounded, label: 'Undo', onTap: onUndo),
          const SizedBox(width: 8),
          _QuickToolButton(icon: Icons.redo_rounded, label: 'Redo', onTap: onRedo),
          const SizedBox(width: 8),
          _QuickTextButton(text: '. ', onTap: onInsertPeriod),
          const SizedBox(width: 8),
          _QuickTextButton(text: ', ', onTap: onInsertComma),
          const SizedBox(width: 8),
          _QuickTextButton(text: 'New line', onTap: onInsertNewLine),
        ],
      ),
    );
  }
}

class _QuickToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickToolButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: enabled ? const Color(0xFFE4E4E7) : const Color(0xFFF4F4F5)),
        foregroundColor: enabled ? const Color(0xFF09090B) : const Color(0xFFA1A1AA),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _QuickTextButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _QuickTextButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE4E4E7)),
        foregroundColor: const Color(0xFF09090B),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}