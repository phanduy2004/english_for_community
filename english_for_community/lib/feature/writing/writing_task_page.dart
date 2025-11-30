import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/entity/writing_topic_entity.dart';
import 'bloc/writing_task_bloc.dart';
import 'writing_feedback_page.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/repository/writing_repository.dart';

class WritingTaskPage extends StatelessWidget {
  final WritingTopicEntity topic;

  final Widget Function(BuildContext, WritingTaskState, String?, ValueChanged<String?>)? promptBuilder;
  final Widget Function(BuildContext, TextEditingController, ValueChanged<String>)? editorBuilder;
  final Widget Function(BuildContext, int, bool, VoidCallback)? bottomBarBuilder;

  const WritingTaskPage({
    super.key,
    required this.topic,
    this.promptBuilder,
    this.editorBuilder,
    this.bottomBarBuilder,
  });

  @override
  Widget build(BuildContext context) {
    const userId = "USER_ID_HIEN_TAI_CUA_BAN";

    return BlocProvider(
      create: (_) => WritingTaskBloc(
        writingRepository: getIt<WritingRepository>(),
      )..add(GeneratePromptAndStartTask(
        topic: topic,
        userId: userId,
      )),
      child: WritingTaskView(
        promptBuilder: promptBuilder,
        editorBuilder: editorBuilder,
        bottomBarBuilder: bottomBarBuilder,
      ),
    );
  }
}

class WritingTaskView extends StatefulWidget {
  final Widget Function(BuildContext, WritingTaskState, String?, ValueChanged<String?>)? promptBuilder;
  final Widget Function(BuildContext, TextEditingController, ValueChanged<String>)? editorBuilder;
  final Widget Function(BuildContext, int, bool, VoidCallback)? bottomBarBuilder;

  const WritingTaskView({
    super.key,
    this.promptBuilder,
    this.editorBuilder,
    this.bottomBarBuilder,
  });

  @override
  State<WritingTaskView> createState() => _WritingTaskViewState();
}

class _WritingTaskViewState extends State<WritingTaskView> {
  final _text = TextEditingController();
  String? _taskType;
  int _wordCount = 0;
  late final Stopwatch _writingStopwatch;

  @override
  void initState() {
    super.initState();
    _writingStopwatch = Stopwatch()..start();

    _text.addListener(() {
      final t = _text.text.trim();
      setState(() => _wordCount = t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length);
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _writingStopwatch.stop();
    super.dispose();
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
    const bgPage = Color(0xFFF9FAFB);
    const borderCol = Color(0xFFE4E4E7);
    const textMain = Color(0xFF09090B);

    return Scaffold(
      backgroundColor: bgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderCol, height: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: textMain),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.watch<WritingTaskBloc>().state.topic?.name ?? 'Writing Task',
          style: const TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      body: BlocConsumer<WritingTaskBloc, WritingTaskState>(
        listenWhen: (p, c) => p.status != c.status,
        listener: (context, state) {
          if (state.status == WritingTaskStatus.success && state.submission != null) {
            _writingStopwatch.stop();
            Navigator.of(context).push(
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
              state.status == WritingTaskStatus.submitting) &&
              state.submission != null;

          if (!canShowEditor) {
            return const Center(child: Text('Failed to load task', style: TextStyle(color: Color(0xFF71717A))));
          }

          final isSubmitting = state.status == WritingTaskStatus.submitting;
          if (_taskType == null) {
            final gp = state.submission!.generatedPrompt;
            _taskType = gp?.taskType ??
                state.topic?.aiConfig?.defaultTaskType ??
                (state.topic?.aiConfig?.taskTypes?.isNotEmpty == true
                    ? state.topic!.aiConfig!.taskTypes?.first
                    : 'Discussion');
          }

          return Stack(
            children: [
              Column(
                children: [
                  widget.promptBuilder != null
                      ? widget.promptBuilder!(context, state, _taskType, (v) => setState(() => _taskType = v))
                      : _ShadcnPrompt(
                    title: state.submission!.generatedPrompt?.title ?? 'Topic',
                    text: state.submission!.generatedPrompt?.text ?? '',
                    taskType: _taskType,
                    taskTypes: state.topic?.aiConfig?.taskTypes ?? const [],
                    onChanged: (v) => setState(() => _taskType = v),
                  ),
                  Expanded(
                    child: widget.editorBuilder != null
                        ? widget.editorBuilder!(context, _text, (_) {})
                        : _ShadcnEditor(controller: _text, readOnly: isSubmitting),
                  ),
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
    );
  }
}

class _ShadcnPrompt extends StatelessWidget {
  final String title;
  final String text;
  final String? taskType;
  final List<String> taskTypes;
  final ValueChanged<String?> onChanged;

  const _ShadcnPrompt({
    required this.title,
    required this.text,
    required this.taskType,
    required this.taskTypes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);
    const borderCol = Color(0xFFE4E4E7);

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
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textMain)),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontSize: 14, color: textMuted, height: 1.5)),
          if (taskTypes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderCol),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: taskType,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: textMuted),
                  style: const TextStyle(fontSize: 14, color: textMain),
                  items: taskTypes.map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  )).toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: const Color(0xFFF9FAFB),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        keyboardType: TextInputType.multiline,
        readOnly: readOnly,
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