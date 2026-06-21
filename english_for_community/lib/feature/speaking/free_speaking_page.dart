import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:translator/translator.dart';

// Import service
import 'package:english_for_community/feature/speaking/vapi/real_vapi_service.dart';
import 'package:english_for_community/feature/speaking/vapi/vapi_service.dart';

import '../../core/analytics/speaking_telemetry.dart';
import '../../core/api/api_client.dart';
import '../../core/config/vapi_env_config.dart';
import '../../core/datasource/vapi_config_remote_datasource.dart';
import '../../core/get_it/get_it.dart';
import '../../core/theme/app_color.dart' as T;
import '../../core/theme/app_skill_colors.dart';
import '../../core/locale/l10n_context.dart';
import '../../core/ui/feedback/app_feedback.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/ui/student_mobile_ui.dart';
import '../../l10n/generated/app_localizations.dart';

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

/// Gộp các [ChatMessage] liên tiếp cùng role (user / AI) để hiển thị **một** bong bóng.
class _ConversationTurn {
  _ConversationTurn({required this.role, required List<ChatMessage> parts})
      : parts = List<ChatMessage>.from(parts);

  final MessageRole role;
  final List<ChatMessage> parts;

  String get combinedText {
    final buf = StringBuffer();
    for (final p in parts) {
      final t = p.text.trim();
      if (t.isEmpty) continue;
      if (buf.isNotEmpty) buf.write(' ');
      buf.write(t);
    }
    return buf.toString();
  }

  bool get allFinal => parts.isNotEmpty && parts.every((p) => p.isFinal);
}

enum _VapiBootstrap { loading, ready, error }

// --- 3. MAIN PAGE ---
class FreeSpeakingPage extends StatefulWidget {
  const FreeSpeakingPage({super.key});
  static const routeName = 'FreeSpeakingPage';
  static const routePath = '/free-speaking';

  @override
  State<FreeSpeakingPage> createState() => _FreeSpeakingPageState();
}

class _FreeSpeakingPageState extends State<FreeSpeakingPage> {
  VapiService? _vapiService;
  StreamSubscription<VapiEvent>? _vapiSub;
  _VapiBootstrap _vapiBootstrap = _VapiBootstrap.loading;
  String? _vapiBootstrapError;

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
  List<VapiVoice> _voiceList = [];
  late VapiVoice _selectedVoice;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final isTyping = _textController.text.trim().isNotEmpty;
      if (_isTyping != isTyping) setState(() => _isTyping = isTyping);
    });
    _bootstrapVapi();
  }

  Future<void> _bootstrapVapi() async {
    setState(() {
      _vapiBootstrap = _VapiBootstrap.loading;
      _vapiBootstrapError = null;
    });

    await _vapiSub?.cancel();
    _vapiSub = null;
    _vapiService?.dispose();
    _vapiService = null;
    _messages.clear();

    String pk = '';
    String aid = '';
    var source = 'none';
    VapiConfigFetchOutcome? remoteOutcome;

    final ds = VapiConfigRemoteDatasource(apiClient: getIt<ApiClient>());
    remoteOutcome = await ds.fetchConfig();
    if (remoteOutcome.hasKeys) {
      pk = remoteOutcome.publicKey!.trim();
      aid = remoteOutcome.assistantId!.trim();
      source = 'backend';
    }

    if (pk.isEmpty || aid.isEmpty) {
      pk = VapiEnvConfig.publicKey.trim();
      aid = VapiEnvConfig.assistantId.trim();
      if (VapiEnvConfig.hasEnvKeys) source = 'dart_define';
    }

    if (pk.isEmpty || aid.isEmpty) {
      if (!mounted) return;
      final hint = _vapiConfigErrorHint(remoteOutcome, context.l10n);
      setState(() {
        _vapiBootstrap = _VapiBootstrap.error;
        _vapiBootstrapError = hint;
      });
      return;
    }

    _vapiService = RealVapiService(publicKey: pk, vapiAssistantId: aid);
    _voiceList = _vapiService!.getAvailableVoices();
    _selectedVoice = _voiceList.isNotEmpty
        ? _voiceList.first
        : const VapiVoice(id: "", name: "Default", gender: "AI");

    await SpeakingTelemetry.logVapiConfigLoaded(source: source);

    _vapiSub = _vapiService!.onEvent.listen(_onVapiEvent);

    _messages.add(ChatMessage(
      id: 'sys_init',
      text: '',
      role: MessageRole.system,
    ));

    if (!mounted) return;
    setState(() => _vapiBootstrap = _VapiBootstrap.ready);
  }

  String _vapiConfigErrorHint(VapiConfigFetchOutcome? o, AppLocalizations t) {
    final code = o?.statusCode;
    if (code == 401 || code == 403) {
      return t.vapiConfigHintAuth;
    }
    if (code == 503) {
      return t.vapiConfigHint503;
    }
    if (code != null && code >= 400) {
      return t.vapiConfigHintHttp(code, o?.message ?? '');
    }
    if (o?.message != null && (o!.publicKey == null || o.assistantId == null)) {
      return t.vapiConfigHintNetwork(o.message ?? '');
    }
    return t.vapiConfigHintMissingKeys;
  }

  void _onVapiEvent(VapiEvent event) {
    if (!mounted) return;
    switch (event.type) {
      case 'error':
        final code = event.data?['code'] as String? ?? 'unknown';
        final msg = event.data?['message'] as String? ?? context.l10n.genericLoadError;
        SpeakingTelemetry.logError(code);
        AppFeedback.error(context, msg);
        break;

      case 'status':
        final prev = _callStatus;
        setState(() => _callStatus = event.value as VapiCallStatus);
        if (_callStatus == VapiCallStatus.active && prev != VapiCallStatus.active) {
          SpeakingTelemetry.logCallStart();
        }
        if (_callStatus == VapiCallStatus.ended || _callStatus == VapiCallStatus.disconnected) {
          if (prev == VapiCallStatus.active) {
            SpeakingTelemetry.logCallEnd();
          }
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
    _waveTimer = Timer.periodic(AppMotion.micro, (_) {
      if (mounted) setState(() => _volumeLevel = 0.2 + Random().nextDouble() * 0.8);
    });
  }

  void _stopWaveAnimation() {
    _waveTimer?.cancel();
    if (mounted) setState(() => _volumeLevel = 0.0);
  }

  @override
  void dispose() {
    _vapiSub?.cancel();
    _vapiService?.dispose();
    _scrollController.dispose();
    _textController.dispose();
    _waveTimer?.cancel();
    super.dispose();
  }

  // --- LOGIC XỬ LÝ ---

  Future<void> _handleBottomButtonPress() async {
    if (_vapiBootstrap != _VapiBootstrap.ready || _vapiService == null) return;

    // Nếu đang kết nối thì không làm gì (để tránh spam)
    if (_callStatus == VapiCallStatus.connecting) return;

    // 1. Nếu chưa kết nối -> Bắt đầu gọi
    if (_callStatus == VapiCallStatus.disconnected || _callStatus == VapiCallStatus.ended) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        await SpeakingTelemetry.logMicDenied();
        if (mounted) {
          AppFeedback.error(context, context.l10n.freeSpeakingMicDenied);
        }
        return;
      }
      await _vapiService!.start(voiceId: _selectedVoice.id);
      return;
    }

    // 2. Nếu đang nhập text -> Gửi tin nhắn
    if (_isTyping) {
      final text = _textController.text.trim();
      if (text.isNotEmpty) {
        _vapiService!.sendMessage(text);
        _textController.clear();
      }
      return;
    }

    // 3. Nếu đang gọi mà không nhập -> Tắt cuộc gọi
    if (_callStatus == VapiCallStatus.active) {
      await _vapiService!.stop();
    }
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

  /// System giữ từng dòng; user/AI gộp các đoạn transcript liên tiếp thành một lượt.
  List<Object> _chatEntriesForList() {
    final entries = <Object>[];
    for (final m in _messages) {
      if (m.role == MessageRole.system) {
        entries.add(m);
        continue;
      }
      if (entries.isNotEmpty && entries.last is _ConversationTurn) {
        final turn = entries.last as _ConversationTurn;
        if (turn.role == m.role) {
          turn.parts.add(m);
          continue;
        }
      }
      entries.add(_ConversationTurn(role: m.role, parts: [m]));
    }
    return entries;
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(AppMotion.fast, () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: AppMotion.base,
            curve: Curves.easeOutQuart,
          );
        }
      });
    }
  }

  // Hiển thị BottomSheet chọn giọng
  void _showVoiceSelector() {
    if (_callStatus != VapiCallStatus.disconnected && _callStatus != VapiCallStatus.ended) {
      AppFeedback.error(context, context.l10n.freeSpeakingEndCallToChangeVoice);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      builder: (sheetContext) {
        final st = sheetContext.l10n;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(st.freeSpeakingSelectVoiceTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1, color: T.AppColors.outline),
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
                        backgroundColor: isSelected ? T.AppColors.primary.withValues(alpha: 0.1) : T.AppColors.surface,
                        child: Icon(
                            voice.gender == 'Male' ? Icons.face : Icons.face_3,
                            color: isSelected ? T.AppColors.primary : T.AppColors.textMuted
                        ),
                      ),
                      title: Text(voice.name, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? T.AppColors.primary : T.AppColors.textPrimary)),
                      subtitle: Text("${voice.gender} • ${voice.accent}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: T.AppColors.primary) : null,
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
    final t = context.l10n;
    if (_vapiBootstrap == _VapiBootstrap.loading) {
      return Scaffold(
        backgroundColor: T.AppColors.surface,
        appBar: StudentMobileUi.skillAppBar(context, title: t.freeSpeakingTitle, skill: SkillType.speaking),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StudentMobileUi.runnerLoading(),
              const SizedBox(height: 16),
              Text(t.freeSpeakingLoadingConfig, style: StudentMobileUi.body(context).copyWith(color: T.AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    if (_vapiBootstrap == _VapiBootstrap.error) {
      return Scaffold(
        backgroundColor: T.AppColors.surface,
        appBar: StudentMobileUi.skillAppBar(context, title: t.freeSpeakingTitle, skill: SkillType.speaking),
        body: Center(
          child: SingleChildScrollView(
            padding: StudentMobileUi.pagePadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.settings_ethernet, size: 48, color: T.AppColors.textMuted),
                const SizedBox(height: 16),
                Text(
                  _vapiBootstrapError ?? t.freeSpeakingConfigErrorShort,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: T.AppColors.textSecondary,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _bootstrapVapi,
                  icon: const Icon(Icons.refresh),
                  label: Text(t.freeSpeakingRetry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bool isConnected = _callStatus == VapiCallStatus.active;
    final bool isConnecting = _callStatus == VapiCallStatus.connecting;
    final chatEntries = _chatEntriesForList();

    return Scaffold(
      backgroundColor: T.AppColors.surface,
      appBar: AppBar(
        toolbarHeight: StudentMobileUi.appBarHeight,
        backgroundColor: T.AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: T.AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isConnected ? T.AppColors.successBg : T.AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: isConnected ? T.AppColors.success.withValues(alpha: 0.2) : Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isConnecting)
                SizedBox(width: 8, height: 8, child: AppLoadingIndicator(strokeWidth: 1.5, color: T.AppColors.textMuted))
              else
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: isConnected ? T.AppColors.success : T.AppColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                isConnecting
                    ? t.freeSpeakingStatusConnecting
                    : (isConnected
                        ? (_isAiSpeaking ? t.freeSpeakingStatusAiSpeaking : t.freeSpeakingStatusOnline)
                        : t.freeSpeakingStatusOffline),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isConnected ? T.AppColors.success : T.AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),

        // --- 2. NÚT CHỌN GIỌNG ---
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s4),
            child: InkWell(
              onTap: _showVoiceSelector,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 112),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: T.AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: T.AppColors.outline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.record_voice_over_rounded, size: 16, color: T.AppColors.textPrimary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _selectedVoice.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: T.AppColors.outline, height: 1),
        ),
      ),
      body: Column(
        children: [
          // --- DANH SÁCH TIN NHẮN ---
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: chatEntries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final e = chatEntries[index];
                if (e is ChatMessage) {
                  return _SystemHintBubble(message: e);
                }
                return _ConversationTurnBubble(turn: e as _ConversationTurn);
              },
            ),
          ),

          // --- KHU VỰC INPUT ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            decoration: const BoxDecoration(
              color: T.AppColors.surfaceCard,
              border: Border(top: BorderSide(color: T.AppColors.outline)),
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
                          color: T.AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.sheet),
                        ),
                        child: TextField(
                          controller: _textController,
                          enabled: isConnected, // Chỉ nhập được khi đã kết nối
                          style: const TextStyle(fontSize: 15, color: T.AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: isConnecting
                                ? t.freeSpeakingHintConnecting
                                : (isConnected ? t.freeSpeakingHintTypeMessage : t.freeSpeakingHintTapMic),
                            hintStyle: const TextStyle(color: T.AppColors.textMuted, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            prefixIcon: const Icon(Icons.keyboard_alt_outlined, size: 20, color: T.AppColors.textMuted),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Nút Action (Có Loading)
                    GestureDetector(
                      onTap: _handleBottomButtonPress,
                      child: AnimatedContainer(
                        duration: AppMotion.base,
                        height: 50, width: 50,
                        decoration: BoxDecoration(
                            color: (isConnected && !_isTyping) ? Colors.red.shade500 : T.AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadius.sheet),
                            boxShadow: [
                              BoxShadow(
                                  color: (isConnected && !_isTyping)
                                      ? Colors.red.withValues(alpha: 0.3)
                                      : T.AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4)
                              )
                            ]
                        ),
                        child: Center(
                          child: isConnecting
                              ? const SizedBox(
                              height: 24, width: 24,
                              child: AppLoadingIndicator(color: Colors.white, strokeWidth: 2.5)
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

// --- 4. BONG BÓNG CHAT (gộp nhiều transcript cùng lượt + Loa / Dịch) ---

class _SystemHintBubble extends StatelessWidget {
  final ChatMessage message;
  const _SystemHintBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final displayText =
        message.id == 'sys_init' ? context.l10n.freeSpeakingWelcome : message.text;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: T.AppColors.outlineMuted,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: T.AppColors.outline),
          ),
          child: Text(
            displayText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: T.AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
          ),
        ),
      ),
    );
  }
}

class _ConversationTurnBubble extends StatefulWidget {
  final _ConversationTurn turn;
  const _ConversationTurnBubble({required this.turn});

  @override
  State<_ConversationTurnBubble> createState() => _ConversationTurnBubbleState();
}

class _ConversationTurnBubbleState extends State<_ConversationTurnBubble> {
  final FlutterTts _flutterTts = FlutterTts();
  final GoogleTranslator _translator = GoogleTranslator();

  bool _isPlaying = false;
  bool _isTranslating = false;
  bool _showTranslation = false;
  String? _translatedText;
  String? _translationSourceText;

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
  void didUpdateWidget(_ConversationTurnBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldText = oldWidget.turn.combinedText;
    final newText = widget.turn.combinedText;
    if (oldText != newText) {
      setState(() {
        _translatedText = null;
        _showTranslation = false;
        _translationSourceText = null;
      });
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  String get _displayText => widget.turn.combinedText;

  Future<void> _speak() async {
    final text = _displayText;
    if (text.isEmpty) return;
    if (_isPlaying) {
      await _flutterTts.stop();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      await _flutterTts.speak(text);
    }
  }

  Future<void> _translate() async {
    final text = _displayText;
    if (text.isEmpty) return;

    if (_showTranslation) {
      setState(() => _showTranslation = false);
      return;
    }
    if (_translatedText != null && _translationSourceText == text) {
      setState(() => _showTranslation = true);
      return;
    }

    setState(() {
      _isTranslating = true;
      _showTranslation = true;
    });
    try {
      final translation = await _translator.translate(text, to: 'vi');
      if (mounted) {
        setState(() {
          _translatedText = translation.text;
          _translationSourceText = text;
          _isTranslating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _translatedText = context.l10n.translationFailed;
          _translationSourceText = text;
          _isTranslating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.turn.role == MessageRole.user;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser)
          Container(
            margin: const EdgeInsets.only(right: 10, top: 4),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: T.AppColors.primaryTint,
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(color: T.AppColors.outline),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: T.AppColors.primary, size: 18),
          ),
        Flexible(
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: AppMotion.base,
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? T.AppColors.primary : T.AppColors.surfaceCard,
                  border: isUser ? null : Border.all(color: T.AppColors.outline),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(AppRadius.lg),
                    topRight: const Radius.circular(AppRadius.lg),
                    bottomLeft: Radius.circular(isUser ? 20 : 6),
                    bottomRight: Radius.circular(isUser ? 6 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isUser
                          ? T.AppColors.primary.withValues(alpha: 0.22)
                          : Colors.black.withValues(alpha: 0.06),
                      blurRadius: isUser ? 12 : 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            _displayText.isEmpty ? '…' : _displayText,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: isUser ? Colors.white : T.AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (!widget.turn.allFinal)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: AnimatedOpacity(
                              opacity: 0.55,
                              duration: AppMotion.tooltipWait,
                              child: Text(
                                '…',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: isUser ? Colors.white70 : scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_showTranslation) ...[
                      const SizedBox(height: 10),
                      Divider(height: 1, color: isUser ? Colors.white24 : T.AppColors.outline),
                      const SizedBox(height: 8),
                      if (_isTranslating)
                        SizedBox(
                          height: 14,
                          width: 14,
                          child: AppLoadingIndicator(
                            strokeWidth: 2,
                            color: isUser ? Colors.white70 : T.AppColors.primary,
                          ),
                        )
                      else
                        Text(
                          _translatedText ?? "",
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            height: 1.45,
                            color: isUser ? Colors.white.withValues(alpha: 0.92) : T.AppColors.textMuted,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              if (widget.turn.allFinal && _displayText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActionButton(
                        icon: _isPlaying ? Icons.stop_circle_outlined : Icons.volume_up_rounded,
                        onTap: _speak,
                        active: _isPlaying,
                      ),
                      const SizedBox(width: 10),
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
        if (isUser)
          Container(
            margin: const EdgeInsets.only(left: 10, top: 4),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: T.AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: T.AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Icon(Icons.person_rounded, color: T.AppColors.primary, size: 20),
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
          color: active ? T.AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? T.AppColors.primary : T.AppColors.textMuted,
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
          duration: AppMotion.micro,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 3,
          height: 10 + (volume * 30 * scale),
          decoration: BoxDecoration(
            color: T.AppColors.primary.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        );
      }),
    );
  }
}