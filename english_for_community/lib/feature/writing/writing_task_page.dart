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
  final Widget Function(BuildContext, WritingTaskState, String?, ValueChanged<String?>)? promptBuilder;
  final Widget Function(BuildContext, TextEditingController, ValueChanged<String>)? editorBuilder;
  final Widget Function(BuildContext, int, bool, VoidCallback)? bottomBarBuilder;

  const WritingTaskPage({
    super.key,
    required this.topic,
    required this.selectedTaskType,
    this.promptBuilder,
    this.editorBuilder,
    this.bottomBarBuilder,
  });

  @override
  Widget build(BuildContext context) {
    const userId = "USER_ID_HIEN_TAI_CUA_BAN"; // TODO: Thay bằng User ID thật

    return BlocProvider(
      create: (_) => WritingTaskBloc(
        writingRepository: getIt<WritingRepository>(),
      )..add(GeneratePromptAndStartTask(
        topic: topic,
        userId: userId,
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
  final _text = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  String? _taskType;
  int _wordCount = 0;
  bool _isDirty = false;
  late final Stopwatch _writingStopwatch;
  bool _hasShownResumeDialog = false;

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
      });
    });
  }

  @override
  void dispose() {
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
        context.read<WritingTaskBloc>().add(SaveDraftEvent(
          submissionId: state.submission!.id,
          content: _text.text,
        ));
      }
    }
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
                const userId = "USER_ID_HIEN_TAI_CUA_BAN";
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
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.writingDraftSavedSnack)));
              Navigator.of(context).pop();
            }
            if (state.status == WritingTaskStatus.success && state.submission != null) {
              _writingStopwatch.stop();
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => WritingFeedbackPage(submission: state.submission!)));
            }
            if (state.status == WritingTaskStatus.error) {
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
                    busy: isSubmitting,
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
  final bool busy;
  final VoidCallback onSubmit;

  const _ClassicBottomBar({required this.wordCount, required this.busy, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _Colors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Text(
              t.wordCountN(wordCount),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: wordCount < 150 ? Colors.orange : _Colors.textMuted,
              ),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: busy ? null : onSubmit,
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
      ),
    );
  }
}