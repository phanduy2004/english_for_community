import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';

// Import service
import 'package:english_for_community/feature/speaking/vapi/real_vapi_service.dart';
import 'package:english_for_community/feature/speaking/vapi/vapi_service.dart';

// --- 1. CẤU HÌNH THEME (Shadcn/ForUI Style) ---
class AppColors {
  // Primary: Màu chủ đạo (Xanh dương đậm)
  static const primary = Color(0xFF2563EB);
  static const primaryLight = Color(0xFFEFF6FF);

  // Success: Trạng thái Online (Xanh lá)
  static const success = Color(0xFF22C55E);
  static const successBg = Color(0xFFDCFCE7);

  // Neutral: Màu nền và văn bản (Zinc Palette)
  static const background = Colors.white;
  static const surface = Color(0xFFF4F4F5);
  static const textMain = Color(0xFF09090B);
  static const textMuted = Color(0xFF71717A);
  static const border = Color(0xFFE4E4E7);
}

// --- 2. MODELS ---
enum MessageRole { user, ai, system }

class ChatMessage {
  final String id;
  final String text;
  final MessageRole role;
  final bool isFinal;

  ChatMessage({required this.id, required this.text, required this.role, this.isFinal = true});

  ChatMessage copyWith({String? text, bool? isFinal}) {
    return ChatMessage(id: id, role: role, text: text ?? this.text, isFinal: isFinal ?? this.isFinal);
  }
}

// --- 3. MAIN PAGE ---
class FreeSpeakingPage extends StatefulWidget {
  const FreeSpeakingPage({super.key});
  static const routeName = 'FreeSpeakingPage';
  static const routePath = '/free-speaking';

  @override
  State<FreeSpeakingPage> createState() => _FreeSpeakingPageState();
}

class _FreeSpeakingPageState extends State<FreeSpeakingPage> {
  late final VapiService _vapiService;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  // Quản lý tin nhắn
  final List<ChatMessage> _messages = [];

  // Trạng thái cuộc gọi
  VapiCallStatus _callStatus = VapiCallStatus.disconnected;
  bool _isAiSpeaking = false;
  bool _isTyping = false;

  // Animation sóng âm
  Timer? _waveTimer;
  double _volumeLevel = 0.0;

  // Quản lý giọng nói
  late List<VapiVoice> _voiceList;
  late VapiVoice _selectedVoice;

  @override
  void initState() {
    super.initState();
    _vapiService = RealVapiService();

    // Lấy danh sách giọng từ Service và chọn mặc định cái đầu tiên
    _voiceList = _vapiService.getAvailableVoices();
    _selectedVoice = _voiceList.isNotEmpty ? _voiceList.first :
    const VapiVoice(id: "", name: "Default", gender: "AI");

    // Tin nhắn mở đầu
    _addMessage(ChatMessage(
      id: 'sys_init',
      text: 'Hello! Choose a voice and tap the microphone to start practicing English.',
      role: MessageRole.system,
    ));

    // Lắng nghe sự kiện từ Vapi
    _vapiService.onEvent.listen((event) {
      if (!mounted) return;
      switch (event.type) {
        case 'status':
          setState(() => _callStatus = event.value);
          if (_callStatus == VapiCallStatus.ended || _callStatus == VapiCallStatus.disconnected) {
            _resetState();
          }
          break;

        case 'transcript':
          if (event.data != null) _handleTranscript(event.data!);
          break;

        case 'speech_start':
          if (event.data?['role'] == 'ai') {
            setState(() => _isAiSpeaking = true);
            _startWaveAnimation();
          }
          break;

        case 'speech_end':
          if (event.data?['role'] == 'ai') {
            setState(() => _isAiSpeaking = false);
            _stopWaveAnimation();
          }
          break;
      }
    });

    // Lắng nghe ô nhập liệu
    _textController.addListener(() {
      final isTyping = _textController.text.trim().isNotEmpty;
      if (_isTyping != isTyping) setState(() => _isTyping = isTyping);
    });
  }

  void _resetState() {
    setState(() {
      _isAiSpeaking = false;
      _volumeLevel = 0.0;
      _isTyping = false;
    });
    _waveTimer?.cancel();
  }

  // Hiệu ứng sóng âm giả lập
  void _startWaveAnimation() {
    _waveTimer?.cancel();
    _waveTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (mounted) setState(() => _volumeLevel = 0.2 + Random().nextDouble() * 0.8);
    });
  }

  void _stopWaveAnimation() {
    _waveTimer?.cancel();
    if (mounted) setState(() => _volumeLevel = 0.0);
  }

  @override
  void dispose() {
    _vapiService.dispose();
    _scrollController.dispose();
    _textController.dispose();
    _waveTimer?.cancel();
    super.dispose();
  }

  // --- LOGIC XỬ LÝ ---

  Future<void> _handleBottomButtonPress() async {
    // Nếu đang kết nối thì không làm gì (để tránh spam)
    if (_callStatus == VapiCallStatus.connecting) return;

    // 1. Nếu chưa kết nối -> Bắt đầu gọi
    if (_callStatus == VapiCallStatus.disconnected || _callStatus == VapiCallStatus.ended) {
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        // Truyền giọng đã chọn vào hàm start
        _vapiService.start(voiceId: _selectedVoice.id);
      }
      return;
    }

    // 2. Nếu đang nhập text -> Gửi tin nhắn
    if (_isTyping) {
      final text = _textController.text.trim();
      if (text.isNotEmpty) {
        _vapiService.sendMessage(text);
        _textController.clear();
      }
      return;
    }

    // 3. Nếu đang gọi mà không nhập -> Tắt cuộc gọi
    if (_callStatus == VapiCallStatus.active) {
      await _vapiService.stop();
    }
  }

  void _addMessage(ChatMessage msg) {
    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  void _handleTranscript(Map<String, dynamic> data) {
    final String text = data['text'];
    final bool isFinal = data['isFinal'];
    final roleStr = data['role'];
    final MessageRole role = roleStr == 'user' ? MessageRole.user : MessageRole.ai;

    setState(() {
      if (_messages.isNotEmpty && _messages.last.role == role && !_messages.last.isFinal) {
        // Ghi đè tin nhắn đang nói dở (tránh lặp)
        final updated = _messages.last.copyWith(text: text, isFinal: isFinal);
        _messages[_messages.length - 1] = updated;
      } else {
        // Thêm tin nhắn mới
        _messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: text, role: role, isFinal: isFinal
        ));
      }
    });

    if (!isFinal || role == MessageRole.user) _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuart,
          );
        }
      });
    }
  }

  // Hiển thị BottomSheet chọn giọng
  void _showVoiceSelector() {
    if (_callStatus != VapiCallStatus.disconnected && _callStatus != VapiCallStatus.ended) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please end the call to change voice."))
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text("Select AI Voice", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 8),
              // List giọng
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _voiceList.length,
                  itemBuilder: (context, index) {
                    final voice = _voiceList[index];
                    final isSelected = _selectedVoice.id == voice.id;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
                        child: Icon(
                            voice.gender == 'Male' ? Icons.face : Icons.face_3,
                            color: isSelected ? AppColors.primary : AppColors.textMuted
                        ),
                      ),
                      title: Text(voice.name, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textMain)),
                      subtitle: Text("${voice.gender} • ${voice.accent}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                      onTap: () {
                        setState(() => _selectedVoice = voice);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- BUILD UI ---

  @override
  Widget build(BuildContext context) {
    final bool isConnected = _callStatus == VapiCallStatus.active;
    final bool isConnecting = _callStatus == VapiCallStatus.connecting;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textMain, size: 20),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,

        // --- 1. STATUS BAR ONLINE/OFFLINE ---
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isConnected ? AppColors.successBg : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isConnected ? AppColors.success.withOpacity(0.2) : Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isConnecting)
                SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.textMuted))
              else
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: isConnected ? AppColors.success : AppColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                isConnecting ? "Connecting..." : (isConnected ? (_isAiSpeaking ? "AI Speaking" : "Online") : "Offline"),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isConnected ? AppColors.success : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),

        // --- 2. NÚT CHỌN GIỌNG ---
        actions: [
          InkWell(
            onTap: _showVoiceSelector,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.record_voice_over_rounded, size: 16, color: AppColors.textMain),
                  const SizedBox(width: 6),
                  Text(_selectedVoice.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: Column(
        children: [
          // --- DANH SÁCH TIN NHẮN ---
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: _messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 24),
              itemBuilder: (context, index) => _InteractiveMessageBubble(message: _messages[index]),
            ),
          ),

          // --- KHU VỰC INPUT ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sóng âm khi AI nói
                if (isConnected && _isAiSpeaking)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(height: 24, child: _Waveform(volume: _volumeLevel)),
                  ),

                Row(
                  children: [
                    // Ô nhập liệu
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _textController,
                          enabled: isConnected, // Chỉ nhập được khi đã kết nối
                          style: const TextStyle(fontSize: 15, color: AppColors.textMain),
                          decoration: InputDecoration(
                            hintText: isConnecting
                                ? "Connecting..."
                                : (isConnected ? "Type message..." : "Tap mic to connect"),
                            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            prefixIcon: const Icon(Icons.keyboard_alt_outlined, size: 20, color: AppColors.textMuted),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Nút Action (Có Loading)
                    GestureDetector(
                      onTap: _handleBottomButtonPress,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 50, width: 50,
                        decoration: BoxDecoration(
                            color: (isConnected && !_isTyping) ? Colors.red.shade500 : AppColors.primary,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: (isConnected && !_isTyping)
                                      ? Colors.red.withOpacity(0.3)
                                      : AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4)
                              )
                            ]
                        ),
                        child: Center(
                          child: isConnecting
                              ? const SizedBox(
                              height: 24, width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                          )
                              : Icon(
                            (!isConnected)
                                ? Icons.mic_rounded // Icon bắt đầu
                                : (_isTyping ? Icons.arrow_upward_rounded : Icons.stop_rounded),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- 4. INTERACTIVE BUBBLE (Chat + Loa + Dịch) ---

class _InteractiveMessageBubble extends StatefulWidget {
  final ChatMessage message;
  const _InteractiveMessageBubble({required this.message});

  @override
  State<_InteractiveMessageBubble> createState() => _InteractiveMessageBubbleState();
}

class _InteractiveMessageBubbleState extends State<_InteractiveMessageBubble> {
  final FlutterTts _flutterTts = FlutterTts();
  final GoogleTranslator _translator = GoogleTranslator();

  bool _isPlaying = false;
  bool _isTranslating = false;
  bool _showTranslation = false;
  String? _translatedText;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  void _speak() async {
    if (_isPlaying) {
      await _flutterTts.stop();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      await _flutterTts.speak(widget.message.text);
    }
  }

  void _translate() async {
    if (_showTranslation) {
      setState(() => _showTranslation = false);
      return;
    }
    if (_translatedText != null) {
      setState(() => _showTranslation = true);
      return;
    }

    setState(() { _isTranslating = true; _showTranslation = true; });
    try {
      final translation = await _translator.translate(widget.message.text, to: 'vi');
      if (mounted) setState(() { _translatedText = translation.text; _isTranslating = false; });
    } catch (e) {
      if (mounted) setState(() { _translatedText = "Lỗi dịch thuật"; _isTranslating = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == MessageRole.user;
    final isSystem = widget.message.role == MessageRole.system;

    // System Bubble
    if (isSystem) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.message.text,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    // User & AI Bubble
    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Avatar
        if (!isUser)
          Container(
            margin: const EdgeInsets.only(right: 12, top: 4),
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.auto_awesome, color: AppColors.textMain, size: 16),
          ),

        // Nội dung
        Flexible(
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.primary : Colors.white,
                  border: isUser ? null : Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  boxShadow: isUser ? [
                    BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
                  ] : [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.message.text,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: isUser ? Colors.white : AppColors.textMain,
                      ),
                    ),

                    // Widget Dịch
                    if (_showTranslation) ...[
                      const SizedBox(height: 8),
                      Divider(height: 1, color: isUser ? Colors.white24 : Colors.black12),
                      const SizedBox(height: 8),
                      if (_isTranslating)
                        SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2, color: isUser ? Colors.white70 : Colors.grey))
                      else
                        Text(
                          _translatedText ?? "",
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: isUser ? Colors.white.withOpacity(0.9) : AppColors.textMuted,
                          ),
                        ),
                    ]
                  ],
                ),
              ),

              // Công cụ (Loa & Dịch) - Chỉ hiện khi tin nhắn đã chốt (Final)
              if (widget.message.isFinal)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActionButton(
                        icon: _isPlaying ? Icons.stop_circle_outlined : Icons.volume_up_rounded,
                        onTap: _speak,
                        active: _isPlaying,
                      ),
                      const SizedBox(width: 12),
                      _ActionButton(
                        icon: Icons.translate_rounded,
                        onTap: _translate,
                        active: _showTranslation,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // User Avatar
        if (isUser)
          Container(
            margin: const EdgeInsets.only(left: 12, top: 4),
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person, color: AppColors.primary, size: 18),
          ),
      ],
    );
  }
}

// Nút bấm nhỏ
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _ActionButton({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? AppColors.primary : AppColors.textMuted,
        ),
      ),
    );
  }
}

// Sóng âm
class _Waveform extends StatelessWidget {
  final double volume;
  const _Waveform({required this.volume});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(20, (index) {
        final dist = (index - 10).abs();
        final scale = (1.0 - (dist / 10)).clamp(0.2, 1.0);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 3,
          height: 10 + (volume * 30 * scale),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.7),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}