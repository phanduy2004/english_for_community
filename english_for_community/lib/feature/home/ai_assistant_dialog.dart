import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_skill_colors.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/feature/home/bloc_ai/ai_chat_bloc.dart';
import 'package:english_for_community/feature/home/bloc_ai/ai_chat_event.dart';
import 'package:english_for_community/feature/home/bloc_ai/ai_chat_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get_it/get_it.dart';

class AiAssistantDialog extends StatelessWidget {
  const AiAssistantDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: GetIt.I<AiChatBloc>(),
      child: const _AiAssistantView(),
    );
  }
}

class _AiAssistantView extends StatefulWidget {
  const _AiAssistantView();

  @override
  State<_AiAssistantView> createState() => _AiAssistantViewState();
}

class _AiAssistantViewState extends State<_AiAssistantView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    context.read<AiChatBloc>().add(SendMessageEvent(text));
    _controller.clear();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      insetPadding: const EdgeInsets.all(AppSpacing.s5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sheet + 2),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s5, AppSpacing.s5, AppSpacing.s3, AppSpacing.s4),
              child: Row(
                children: [
                  StudentMobileUi.skillIconBox(
                    Icons.auto_awesome,
                    size: 40,
                    colors: SkillColorSet(
                      color: AppColors.accent,
                      tint: AppColors.accentTint,
                      dark: AppColors.accentDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  Expanded(
                    child: Text(t.aiAssistantTitle, style: StudentMobileUi.sectionTitle(context)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.outline),
            Expanded(
              child: BlocConsumer<AiChatBloc, AiChatState>(
                listener: (context, state) {
                  if (state.status == AiChatStatus.loading || state.status == AiChatStatus.success) {
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                  }
                },
                builder: (context, state) {
                  final messages = state.messages;
                  final isLoading = state.status == AiChatStatus.loading;

                  if (messages.isEmpty && !isLoading) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s8),
                        child: Text(
                          t.aiAssistantEmptyPrompt,
                          textAlign: TextAlign.center,
                          style: StudentMobileUi.body(context),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.s5),
                    itemCount: messages.length + (isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return const _TypingIndicator();
                      }
                      final msg = messages[index];
                      return _MessageBubble(text: msg.text, isUser: msg.isUser);
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1, color: AppColors.outline),
            Container(
              padding: const EdgeInsets.all(AppSpacing.s5),
              color: AppColors.surfaceSubtle,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: AppTypography.body(),
                      decoration: InputDecoration(
                        hintText: t.aiChatPlaceholder,
                        hintStyle: AppTypography.body(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfaceCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.input + 2),
                          borderSide: const BorderSide(color: AppColors.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.input + 2),
                          borderSide: const BorderSide(color: AppColors.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.input + 2),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s4),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _sendMessage(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  FilledButton(
                    onPressed: () => _sendMessage(context),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input + 2)),
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s5),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surfaceSubtle,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
          ),
          border: isUser ? null : Border.all(color: AppColors.outline),
        ),
        child: isUser
            ? Text(text, style: AppTypography.body(color: AppColors.onPrimary))
            : MarkdownBody(
                data: text,
                styleSheet: MarkdownStyleSheet(
                  p: AppTypography.body(),
                  strong: AppTypography.body().copyWith(fontWeight: FontWeight.w700),
                  listBullet: AppTypography.body(),
                  tableBody: AppTypography.body(),
                  tableHead: AppTypography.label(),
                  tableBorder: TableBorder.all(color: AppColors.outline, width: 1),
                  tableCellsPadding: const EdgeInsets.all(AppSpacing.s3),
                ),
              ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s5),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s5),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(AppRadius.input + 2),
          border: Border.all(color: AppColors.outline),
        ),
        child: SizedBox(
          width: 40,
          height: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) => _Dot(index: index)),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.index});
  final int index;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    Future.delayed(Duration(milliseconds: widget.index * 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.textMuted,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
