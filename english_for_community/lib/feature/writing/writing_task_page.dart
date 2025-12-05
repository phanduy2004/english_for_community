import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:english_for_community/core/entity/writing_topic_entity.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/repository/writing_repository.dart';

// Import các file Bloc/Event/State
import 'writing_task_bloc/writing_task_bloc.dart';
import 'writing_task_bloc/writing_task_event.dart';
import 'writing_task_bloc/writing_task_state.dart';
import 'writing_feedback_page.dart';

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
    // Demo userId
    const userId = "USER_ID_HIEN_TAI_CUA_BAN";

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
  final ScrollController _scrollController = ScrollController(); // Thêm ScrollController để điều khiển cuộn
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
    _writingStopwatch.stop();
    super.dispose();
  }

  Future<void> _onWillPop(bool didPop) async {
    if (didPop) return;
    final state = context.read<WritingTaskBloc>().state;
    if (state.submission == null || !_isDirty) {
      Navigator.of(context).pop();
      return;
    }

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Save Draft?'),
        content: const Text('Do you want to save your work before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Don\'t Save', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save & Exit'),
          ),
        ],
      ),
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Draft Found'),
        content: Text(
          'You have an unfinished "$serverTaskType" essay.\n\n'
              '• Resume: Continue your previous work.\n'
              '• Start New: DELETE the old draft and start a new topic.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF52525B)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final currentState = context.read<WritingTaskBloc>().state;
              if (currentState.topic != null) {
                const userId = "USER_ID_HIEN_TAI_CUA_BAN";
                context.read<WritingTaskBloc>().add(
                    DiscardDraftAndStartNew(
                      oldSubmissionId: submissionId,
                      topic: currentState.topic!,
                      userId: userId,
                      taskType: _taskType ?? 'Discussion',
                    )
                );
                _text.clear();
                _isDirty = false;
              }
            },
            child: const Text('Start New', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _taskType = serverTaskType;
                _text.text = oldContent;
                _isDirty = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Resume Draft'),
          ),
        ],
      ),
    );
  }

  void _submit(WritingTaskState s) {
    if (s.submission == null || _taskType == null) return;
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        // resizeToAvoidBottomInset: true giúp body co lại khi bàn phím hiện
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF09090B)),
            onPressed: () => _onWillPop(false),
          ),
          title: Text(
            context.watch<WritingTaskBloc>().state.topic?.name ?? 'Writing Task',
            style: const TextStyle(color: Color(0xFF09090B), fontWeight: FontWeight.w600, fontSize: 16),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: const Color(0xFFE4E4E7), height: 1),
          ),
        ),
        body: BlocConsumer<WritingTaskBloc, WritingTaskState>(
          listenWhen: (p, c) => p.status != c.status || p.submission != c.submission,
          listener: (context, state) {
            // Logic xử lý status giữ nguyên như cũ
            if (state.status == WritingTaskStatus.promptReady && state.submission != null) {
              final hasDraftContent = state.submission!.content.isNotEmpty;
              final isDraftStatus = state.submission!.status == 'draft';
              if (hasDraftContent && isDraftStatus && !_hasShownResumeDialog) {
                Future.delayed(Duration.zero, () {
                  if (mounted) {
                    _showResumeConflictDialog(
                        context,
                        state.submission!.generatedPrompt?.taskType ?? 'Essay',
                        state.submission!.id,
                        state.submission!.content
                    );
                  }
                });
              } else if (!hasDraftContent && isDraftStatus) {
                _text.clear();
                _isDirty = false;
                _hasShownResumeDialog = false;
              }
            }
            if (state.status == WritingTaskStatus.savedSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Draft saved successfully!'), duration: Duration(seconds: 1)),
              );
              Navigator.of(context).pop();
            }
            if (state.status == WritingTaskStatus.success && state.submission != null) {
              _writingStopwatch.stop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => WritingFeedbackPage(submission: state.submission!)),
              );
            }
            if (state.status == WritingTaskStatus.error && state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
          },
          builder: (context, state) {
            if (state.status == WritingTaskStatus.loading) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            }

            final canShowEditor = (state.status == WritingTaskStatus.promptReady ||
                state.status == WritingTaskStatus.submitting ||
                state.status == WritingTaskStatus.savedSuccess) &&
                state.submission != null;

            if (!canShowEditor) {
              return const Center(child: Text('Initializing task...', style: TextStyle(color: Color(0xFF71717A))));
            }

            final isSubmitting = state.status == WritingTaskStatus.submitting;

            if (_taskType == null) {
              _taskType = state.submission!.generatedPrompt?.taskType ?? widget.initialTaskType;
            }

            // --- LAYOUT CHÍNH ĐÃ ĐƯỢC SỬA ---
            return Stack(
              children: [
                Column(
                  children: [
                    // 1. Phần nội dung có thể cuộn (Đề bài + Editor)
                    Expanded(
                      child: GestureDetector(
                        // Bấm ra ngoài để ẩn bàn phím
                        onTap: () => FocusScope.of(context).unfocus(),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          // physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // A. Prompt (Đề bài)
                              widget.promptBuilder != null
                                  ? widget.promptBuilder!(context, state, _taskType, (v) => setState(() => _taskType = v))
                                  : _ShadcnPrompt(
                                title: state.submission!.generatedPrompt?.title ?? 'Topic',
                                text: state.submission!.generatedPrompt?.text ?? '',
                                taskType: _taskType,
                              ),

                              // B. Editor (Soạn thảo)
                              // Không dùng Expanded ở đây nữa vì đã nằm trong SingleChildScrollView
                              widget.editorBuilder != null
                                  ? widget.editorBuilder!(context, _text, (_) {})
                                  : _ShadcnEditor(
                                controller: _text,
                                readOnly: isSubmitting,
                                // Truyền scroll controller vào nếu cần xử lý auto-scroll
                              ),

                              // Khoảng trống đệm để người dùng có thể cuộn text lên cao hơn bàn phím
                              SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 200 : 100),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 2. Bottom Bar (Luôn ghim ở dưới cùng)
                    // Khi bàn phím hiện, cái này sẽ được đẩy lên trên bàn phím nhờ resizeToAvoidBottomInset: true
                    widget.bottomBarBuilder != null
                        ? widget.bottomBarBuilder!(context, _wordCount, isSubmitting, () => _submit(state))
                        : _ShadcnBottomBar(
                      wordCount: _wordCount,
                      busy: isSubmitting,
                      onSubmit: () => _submit(state),
                    ),
                  ],
                ),
                if (isSubmitting)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white.withOpacity(0.5),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// --- CÁC WIDGET CON (ĐÃ ĐƯỢC CHỈNH SỬA) ---

class _ShadcnPrompt extends StatelessWidget {
  final String title;
  final String text;
  final String? taskType;

  const _ShadcnPrompt({
    required this.title,
    required this.text,
    required this.taskType,
  });

  @override
  Widget build(BuildContext context) {
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);
    const borderCol = Color(0xFFE4E4E7);
    const bgBadge = Color(0xFFF4F4F5);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borderCol)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textMain),
                ),
              ),
              if (taskType != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bgBadge,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: borderCol),
                  ),
                  child: Text(
                    taskType!.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 15, color: textMain, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _ShadcnEditor extends StatelessWidget {
  final TextEditingController controller;
  final bool readOnly;
  const _ShadcnEditor({required this.controller, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);

    // Tính toán chiều cao tối thiểu để vùng nhập liệu trông rộng rãi
    // Lấy chiều cao màn hình trừ đi các phần header (ước lượng)
    final minHeight = MediaQuery.of(context).size.height * 0.5;

    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: const Color(0xFFF9FAFB),
      child: TextField(
        controller: controller,
        // QUAN TRỌNG:
        // 1. maxLines: null để ô text tự động cao lên khi gõ nhiều
        // 2. Không dùng expands: true trong SingleChildScrollView
        maxLines: null,
        minLines: 10, // Mặc định hiển thị ít nhất 10 dòng
        keyboardType: TextInputType.multiline,
        readOnly: readOnly,
        // scrollPadding giúp tự động đẩy màn hình lên sao cho con trỏ
        // luôn nằm trên bàn phím một khoảng 80px
        scrollPadding: const EdgeInsets.only(bottom: 80),
        style: const TextStyle(fontSize: 16, height: 1.6, color: textMain),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Start writing your essay here...',
          hintStyle: TextStyle(color: textMuted),
        ),
      ),
    );
  }
}

class _ShadcnBottomBar extends StatelessWidget {
  final int wordCount;
  final bool busy;
  final VoidCallback onSubmit;

  const _ShadcnBottomBar({required this.wordCount, required this.busy, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    const borderCol = Color(0xFFE4E4E7);
    const textMuted = Color(0xFF71717A);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: borderCol)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Text(
              '$wordCount words',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: wordCount < 150 ? Colors.orange : textMuted,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: busy ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Essay'),
            ),
          ],
        ),
      ),
    );
  }
}