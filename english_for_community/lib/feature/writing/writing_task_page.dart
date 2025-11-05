import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart'; // ⬅ forui
import '../../core/entity/writing_topic_entity.dart';
import 'bloc/writing_task_bloc.dart';
import 'writing_feedback_page.dart';

class WritingTaskPage extends StatelessWidget {
  final WritingTopicEntity topic;

  /// Slot tuỳ biến (ưu tiên dùng nếu bạn muốn tự render bằng forui nâng cao)
  final Widget Function(
          BuildContext, WritingTaskState, String?, ValueChanged<String?>)?
      promptBuilder;
  final Widget Function(
      BuildContext, TextEditingController, ValueChanged<String>)? editorBuilder;
  final Widget Function(BuildContext, int, bool, VoidCallback)?
      bottomBarBuilder;

  const WritingTaskPage({
    super.key,
    required this.topic,
    this.promptBuilder,
    this.editorBuilder,
    this.bottomBarBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          WritingTaskBloc()..add(GeneratePromptAndStartTask(topic: topic)),
      child: WritingTaskView(
        promptBuilder: promptBuilder,
        editorBuilder: editorBuilder,
        bottomBarBuilder: bottomBarBuilder,
      ),
    );
  }
}

class WritingTaskView extends StatefulWidget {
  final Widget Function(
          BuildContext, WritingTaskState, String?, ValueChanged<String?>)?
      promptBuilder;
  final Widget Function(
      BuildContext, TextEditingController, ValueChanged<String>)? editorBuilder;
  final Widget Function(BuildContext, int, bool, VoidCallback)?
      bottomBarBuilder;

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

  @override
  void initState() {
    super.initState();
    _text.addListener(() {
      final t = _text.text.trim();
      setState(
          () => _wordCount = t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length);
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit(WritingTaskState s) {
    if (s.submission == null || _taskType == null) return;
    context.read<WritingTaskBloc>().add(
          SubmitForFeedback(
            submissionId: s.submission!.id,
            essayContent: _text.text,
            taskType: _taskType!,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    // AppBar giữ Material để tương thích, nhưng theme sẽ đồng bộ qua FTheme
    return Scaffold(
      appBar: AppBar(
        title: Text(
            context.watch<WritingTaskBloc>().state.topic?.name ?? 'Writing'),
      ),
      body: BlocConsumer<WritingTaskBloc, WritingTaskState>(
        listenWhen: (p, c) => p.status != c.status,
        listener: (context, state) {
          if (state.status == WritingTaskStatus.success &&
              state.submission != null) {
            // SỬA LỖI: Dùng .push() thay vì .pushReplacement()
            // để người dùng có thể "Back" từ trang Feedback về trang Task
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) =>
                      WritingFeedbackPage(submission: state.submission!)),
            );
          }
          if (state.status == WritingTaskStatus.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          if (state.status == WritingTaskStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final canShowEditor = (state.status == WritingTaskStatus.promptReady ||
              state.status == WritingTaskStatus.submitting) &&
              state.submission != null;

          if (!canShowEditor) {
            return const Center(child: Text('Failed to load task.'));
          }

          final isSubmitting = state.status == WritingTaskStatus.submitting;
          if (_taskType == null) {
            final gp = state.submission!.generatedPrompt;
            _taskType = gp?.taskType
                ?? state.topic?.aiConfig?.defaultTaskType
                ?? (state.topic?.aiConfig?.taskTypes?.isNotEmpty == true
                    ? state.topic!.aiConfig!.taskTypes?.first
                    : 'Discussion'); // fallback
          }
          // 👉 Dùng Stack để overlay loader khi submitting
          return Stack(
            children: [
              Column(
                children: [
                  (widget.promptBuilder != null)
                      ? widget.promptBuilder!(context, state, _taskType,
                          (v) => setState(() => _taskType = v))
                      : _FPrompt(
                    title: state.submission!.generatedPrompt?.title ?? 'Prompt',
                    text:  state.submission!.generatedPrompt?.text  ?? '',
                    taskType: _taskType,
                    taskTypes: state.topic?.aiConfig?.taskTypes ?? const [],
                    onChanged: (v) => setState(() => _taskType = v),
                  ),

                  Expanded(
                    child: (widget.editorBuilder != null)
                        ? widget.editorBuilder!(context, _text, (_) {})
                        : _FEditor(controller: _text, readOnly: isSubmitting), // 👈 khóa khi submit
                  ),

                  (widget.bottomBarBuilder != null)
                      ? widget.bottomBarBuilder!(
                      context, _wordCount, isSubmitting, () => _submit(state))
                      : _FBottomBar(
                    wordCount: _wordCount,
                    busy: isSubmitting,
                    onSubmit: () => _submit(state),
                  ),
                ],
              ),

              // 👉 Overlay mờ + loader khi submitting
              if (isSubmitting)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: true,
                    child: ColoredBox(
                      color: Colors.black.withOpacity(0.08),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
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

/* -------------------- Forui-flavored minimal components -------------------- */

class _FPrompt extends StatelessWidget {
  final String title;
  final String text;
  final String? taskType;
  final List<String> taskTypes;
  final ValueChanged<String?> onChanged;

  const _FPrompt({
    required this.title,
    required this.text,
    required this.taskType,
    required this.taskTypes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showSelector = taskTypes.isNotEmpty;


    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest, // subtle như shadcn/forui
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w300)),
          if (showSelector) ...[
            const SizedBox(height: 12),
            Text('Task type',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            // Dropdown Material tạm thời; nếu bạn dùng forui cho select, thay vào đây.
            DropdownButtonFormField<String>(
              value: taskType,
              isExpanded: true,
              items: taskTypes
                  .map((e) => DropdownMenuItem(
                      value: e,
                      child:
                          Text(e, style: Theme.of(context).textTheme.bodySmall)))
                  .toList(),
              onChanged: onChanged,
              decoration: InputDecoration(
                isDense: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _FEditor extends StatelessWidget {
  final TextEditingController controller;
  final bool readOnly;
  const _FEditor({required this.controller, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            keyboardType: TextInputType.multiline,
            readOnly: readOnly,                 // 👈 khóa khi submit
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Start writing…',
            ),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w300),
          ),
        ),
      ),
    );
  }
}

class _FBottomBar extends StatelessWidget {
  final int wordCount;
  final bool busy;
  final VoidCallback onSubmit;

  const _FBottomBar(
      {required this.wordCount, required this.busy, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(
          children: [
            Text(
              '$wordCount words',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: wordCount < 250 ? cs.error : cs.primary,
                  ),
            ),
            const Spacer(),
            // ⬇ Forui button (shadcn-like)
            FButton(
              style: FButtonStyle.primary((s) => s.copyWith(
                    contentStyle: s.contentStyle.copyWith(
                      // thu nhỏ khoảng cách với mép nút
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      // nếu lib có field `gap` giữa icon & text thì giảm luôn, ví dụ:
                      // gap: 6,
                    ),
                  )),
              onPress: busy ? null : onSubmit,
              mainAxisSize: MainAxisSize.max, // full-width cho mobile
              child: Row(
                children: [
                  if (busy)
                    const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    const Icon(Icons.check_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    busy ? 'Evaluating…' : 'Submit & Review',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 10, color: Colors.white),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
