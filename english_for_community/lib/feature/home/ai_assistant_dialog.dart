import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'bloc_ai/ai_chat_bloc.dart';
import 'bloc_ai/ai_chat_event.dart';
import 'bloc_ai/ai_chat_state.dart';

// Widget Dialog chính
class AiAssistantDialog extends StatelessWidget {
  const AiAssistantDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Dùng BlocProvider.value để nhận Bloc đã tạo từ HomePage (Singleton)
    // Điều này đảm bảo lịch sử chat không bị mất khi đóng/mở dialog
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

  // Màu sắc Shadcn
  static const Color textMain = Color(0xFF09090B);
  static const Color textMuted = Color(0xFF71717A);
  static const Color primaryBlack = Color(0xFF09090B);

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
    // Hiệu ứng nền kính mờ (Glassmorphism)
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        elevation: 0,
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            children: [
              // --- HEADER ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryBlack.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Trợ lý AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textMain)),
                            Text('Gemini 2.0 Flash', style: TextStyle(fontSize: 12, color: textMuted)),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: textMuted),
                    )
                  ],
                ),
              ),

              // --- CHAT LIST ---
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
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text("Hãy hỏi tôi bất cứ điều gì về tiến độ học tập của bạn!",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54)),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
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

              // --- INPUT AREA ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.8)),
                        ),
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(fontSize: 14, color: textMain),
                          decoration: const InputDecoration(
                            hintText: 'Nhập câu hỏi...',
                            hintStyle: TextStyle(color: textMuted, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onSubmitted: (_) => _sendMessage(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _sendMessage(context),
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: primaryBlack,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _MessageBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
            color: isUser ? const Color(0xFF09090B) : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
              bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
            ),
            boxShadow: [
              if (!isUser) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))
            ]
        ),
        child: isUser
            ? Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
        )
            : MarkdownBody( // Sử dụng MarkdownBody để hiển thị bảng, in đậm...
          data: text,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(color: Color(0xFF09090B), fontSize: 14, height: 1.5),
            strong: const TextStyle(color: Color(0xFF09090B), fontWeight: FontWeight.w700),
            listBullet: const TextStyle(color: Color(0xFF09090B)),
            // Style cho bảng (Table)
            tableBody: const TextStyle(color: Color(0xFF09090B), fontSize: 13),
            tableHead: const TextStyle(color: Color(0xFF09090B), fontWeight: FontWeight.bold),
            tableBorder: TableBorder.all(color: Colors.grey.shade300, width: 1),
            tableCellsPadding: const EdgeInsets.all(8),
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
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
  final int index;
  const _Dot({required this.index});

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
          color: Color(0xFF71717A),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}