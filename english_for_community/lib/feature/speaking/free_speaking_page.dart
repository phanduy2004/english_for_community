import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
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
import '../../core/entity/speaking_conversation_entity.dart';
import '../../core/entity/speaking_phase2_entity.dart';
import '../../core/get_it/get_it.dart';
import '../../core/theme/app_color.dart' as app_color;
import '../../core/theme/app_skill_colors.dart';
import '../../core/locale/l10n_context.dart';
import '../../core/ui/feedback/app_feedback.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/ui/student_mobile_ui.dart';
import '../../l10n/generated/app_localizations.dart';
import 'speaking_feedback_page.dart';
import 'speaking_progress_dashboard_page.dart';
import 'speaking_notebook_page.dart';

// --- 2. MODELS ---
enum MessageRole { user, ai, system }

class ChatMessage {
  final String id;
  final String text;
  final MessageRole role;
  final bool isFinal;

  ChatMessage(
      {required this.id,
      required this.text,
      required this.role,
      this.isFinal = true});

  ChatMessage copyWith({String? text, bool? isFinal}) {
    return ChatMessage(
        id: id,
        role: role,
        text: text ?? this.text,
        isFinal: isFinal ?? this.isFinal);
  }
}

/// Gộp các [ChatMessage] liên tiếp cùng role (user / AI) để hiển thị **một** bong bóng.
class _ConversationTurn {
  _ConversationTurn({required this.role, required List<ChatMessage> parts})
      : parts = List<ChatMessage>.from(parts);

  final MessageRole role;
  final List<ChatMessage> parts;

  String get combinedText {
    var out = '';
    for (final p in parts) {
      final t = p.text.trim();
      if (t.isEmpty) continue;
      out = out.isEmpty ? t : _mergeOverlap(out, t);
    }
    return out;
  }

  /// Nối 2 đoạn transcript, bỏ phần ĐẦU của [next] trùng với ĐUÔI của [prev]
  /// (Vapi finalize câu giữa chừng rồi gửi lại từ đầu câu → tránh lặp
  /// "…Would you like to Would you like to…"). So khớp theo TỪ, tối thiểu 2 từ
  /// trùng để không cắt nhầm.
  static String _mergeOverlap(String prev, String next) {
    final pw = prev.split(RegExp(r'\s+'));
    final nw = next.split(RegExp(r'\s+'));
    final maxK = pw.length < nw.length ? pw.length : nw.length;
    for (var k = maxK; k >= 2; k--) {
      final tail = pw.sublist(pw.length - k).join(' ').toLowerCase();
      final head = nw.sublist(0, k).join(' ').toLowerCase();
      if (tail == head) {
        final rest = nw.sublist(k).join(' ');
        return rest.isEmpty ? prev : '$prev $rest';
      }
    }
    return '$prev $next';
  }

  bool get allFinal => parts.isNotEmpty && parts.every((p) => p.isFinal);
}

enum _VapiBootstrap { loading, ready, error }

// --- 3. MAIN PAGE ---
class FreeSpeakingPage extends StatefulWidget {
  const FreeSpeakingPage({super.key, this.scenario});
  static const routeName = 'FreeSpeakingPage';
  static const routePath = '/free-speaking';

  final SpeakingScenarioEntity? scenario;

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
  DateTime? _callStartedAt;
  bool _evaluateAfterCallEnds = false;

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
        final msg =
            event.data?['message'] as String? ?? context.l10n.genericLoadError;
        SpeakingTelemetry.logError(code);
        AppFeedback.error(context, msg);
        break;

      case 'status':
        final prev = _callStatus;
        setState(() => _callStatus = event.value as VapiCallStatus);
        if (_callStatus == VapiCallStatus.active &&
            prev != VapiCallStatus.active) {
          _callStartedAt = DateTime.now();
          _evaluateAfterCallEnds = true;
          SpeakingTelemetry.logCallStart();
        }
        if (_callStatus == VapiCallStatus.ended ||
            _callStatus == VapiCallStatus.disconnected) {
          if (prev == VapiCallStatus.active) {
            SpeakingTelemetry.logCallEnd();
            if (_evaluateAfterCallEnds) {
              _openFeedbackIfEligible();
            }
          }
          _evaluateAfterCallEnds = false;
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
      if (mounted) {
        setState(() => _volumeLevel = 0.2 + Random().nextDouble() * 0.8);
      }
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
    if (_callStatus == VapiCallStatus.disconnected ||
        _callStatus == VapiCallStatus.ended) {
      final hasMicAccess =
          kIsWeb || (await Permission.microphone.request()).isGranted;
      if (!hasMicAccess) {
        await SpeakingTelemetry.logMicDenied();
        if (mounted) {
          AppFeedback.error(context, context.l10n.freeSpeakingMicDenied);
        }
        return;
      }
      setState(() {
        _messages
          ..clear()
          ..add(
              ChatMessage(id: 'sys_init', text: '', role: MessageRole.system));
      });
      await _vapiService!.start(
        voiceId: _selectedVoice.id,
        // Free-chat (scenario null) vẫn cần nâng maxTokens để AI không cụt câu.
        assistantOverrides: widget.scenario?.toVapiOverrides() ??
            const {
              'model': {'maxTokens': kVapiReplyMaxTokens},
            },
      );
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
      _evaluateAfterCallEnds = true;
      await _vapiService!.stop();
    }
  }

  List<SpeakingTurnEntity> _conversationTurnsForFeedback() {
    final turns = <SpeakingTurnEntity>[];
    for (final entry in _chatEntriesForList()) {
      if (entry is! _ConversationTurn) continue;
      if (!entry.allFinal) continue;
      final text = entry.combinedText.trim();
      if (text.isEmpty) continue;
      turns.add(SpeakingTurnEntity(
        role: entry.role == MessageRole.user ? 'user' : 'ai',
        text: text,
        ts: entry.parts.first.id == 'sys_init'
            ? null
            : int.tryParse(entry.parts.first.id),
      ));
    }
    return turns;
  }

  int _feedbackDurationSeconds(DateTime endedAt) {
    final startedAt = _callStartedAt;
    if (startedAt == null) return 0;
    return endedAt.difference(startedAt).inSeconds.clamp(0, 24 * 60 * 60);
  }

  bool _isLongEnoughForFeedback(List<SpeakingTurnEntity> turns, int duration) {
    final userTurns = turns.where((turn) => turn.role == 'user').length;
    if (userTurns == 0) return false;
    return userTurns >= 3 || duration >= 30;
  }

  void _openFeedbackIfEligible() {
    final endedAt = DateTime.now();
    final turns = _conversationTurnsForFeedback();
    final durationSeconds = _feedbackDurationSeconds(endedAt);
    if (!_isLongEnoughForFeedback(turns, durationSeconds)) {
      if (mounted) {
        AppFeedback.info(context, context.l10n.speakingFbTooShort);
      }
      return;
    }
    if (!mounted) return;
    context.pushNamed(
      SpeakingFeedbackPage.routeName,
      extra: SpeakingFeedbackPageArgs.evaluate(
        turns: turns,
        durationSeconds: durationSeconds,
        startedAt: _callStartedAt,
        endedAt: endedAt,
        level: widget.scenario?.levelSuggested,
        scenarioId: widget.scenario?.id,
      ),
    );
  }

  void _handleTranscript(Map<String, dynamic> data) {
    final String text = (data['text'] ?? '') as String;
    final bool isFinal = data['isFinal'] == true;
    final roleStr = data['role'];
    final MessageRole role =
        roleStr == 'user' ? MessageRole.user : MessageRole.ai;

    setState(() {
      if (_messages.isNotEmpty &&
          _messages.last.role == role &&
          !_messages.last.isFinal) {
        // Ghi đè tin nhắn đang nói dở (tránh lặp)
        final updated = _messages.last.copyWith(text: text, isFinal: isFinal);
        _messages[_messages.length - 1] = updated;
      } else {
        // Thêm tin nhắn mới
        _messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: text,
            role: role,
            isFinal: isFinal));
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
    if (_callStatus != VapiCallStatus.disconnected &&
        _callStatus != VapiCallStatus.ended) {
      AppFeedback.error(context, context.l10n.freeSpeakingEndCallToChangeVoice);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      builder: (sheetContext) {
        final st = sheetContext.l10n;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(st.freeSpeakingSelectVoiceTitle,
                    style: const TextStyle(
                        fontSize: AppTypography.mobileDisplay, fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1, color: app_color.AppColors.outline),
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
                        backgroundColor: isSelected
                            ? app_color.AppColors.primary.withValues(alpha: 0.1)
                            : app_color.AppColors.surface,
                        child: Icon(
                            voice.gender == 'Male' ? Icons.face : Icons.face_3,
                            color: isSelected
                                ? app_color.AppColors.primary
                                : app_color.AppColors.textMuted),
                      ),
                      title: Text(voice.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? app_color.AppColors.primary
                                  : app_color.AppColors.textPrimary)),
                      subtitle: Text("${voice.gender} • ${voice.accent}",
                          style: const TextStyle(
                              color: Colors.grey, fontSize: AppTypography.mobileCaption)),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: app_color.AppColors.primary)
                          : null,
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
        backgroundColor: app_color.AppColors.surface,
        appBar: StudentMobileUi.skillAppBar(context,
            title: t.freeSpeakingTitle, skill: SkillType.speaking),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StudentMobileUi.runnerLoading(),
              const SizedBox(height: 16),
              Text(t.freeSpeakingLoadingConfig,
                  style: StudentMobileUi.body(context)
                      .copyWith(color: app_color.AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    if (_vapiBootstrap == _VapiBootstrap.error) {
      return Scaffold(
        backgroundColor: app_color.AppColors.surface,
        appBar: StudentMobileUi.skillAppBar(context,
            title: t.freeSpeakingTitle, skill: SkillType.speaking),
        body: Center(
          child: SingleChildScrollView(
            padding: StudentMobileUi.pagePadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.settings_ethernet,
                    size: 48, color: app_color.AppColors.textMuted),
                const SizedBox(height: 16),
                Text(
                  _vapiBootstrapError ?? t.freeSpeakingConfigErrorShort,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: app_color.AppColors.textSecondary,
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
      backgroundColor: app_color.AppColors.surface,
      appBar: AppBar(
        toolbarHeight: StudentMobileUi.appBarHeight,
        backgroundColor: app_color.AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: app_color.AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isConnected
                ? app_color.AppColors.successBg
                : app_color.AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
                color: isConnected
                    ? app_color.AppColors.success.withValues(alpha: 0.2)
                    : Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isConnecting)
                SizedBox(
                    width: 8,
                    height: 8,
                    child: AppLoadingIndicator(
                        strokeWidth: 1.5, color: app_color.AppColors.textMuted))
              else
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isConnected
                        ? app_color.AppColors.success
                        : app_color.AppColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                isConnecting
                    ? t.freeSpeakingStatusConnecting
                    : (isConnected
                        ? (_isAiSpeaking
                            ? t.freeSpeakingStatusAiSpeaking
                            : t.freeSpeakingStatusOnline)
                        : t.freeSpeakingStatusOffline),
                style: TextStyle(
                  fontSize: AppTypography.mobileBody,
                  fontWeight: FontWeight.w600,
                  color: isConnected
                      ? app_color.AppColors.success
                      : app_color.AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),

        // --- 2. NÚT CHỌN GIỌNG ---
        actions: [
          IconButton(
            tooltip: t.speakingFbHistoryTitle,
            icon: const Icon(Icons.history_rounded,
                size: 20, color: app_color.AppColors.textPrimary),
            onPressed: () =>
                context.pushNamed(SpeakingFeedbackHistoryPage.routeName),
          ),
          PopupMenuButton<String>(
            tooltip: t.speakingDashboardTitle,
            icon: const Icon(Icons.more_vert_rounded,
                size: 20, color: app_color.AppColors.textPrimary),
            onSelected: (value) {
              if (value == 'progress') {
                context.pushNamed(SpeakingProgressDashboardPage.routeName);
              }
              if (value == 'notebook') {
                context.pushNamed(SpeakingNotebookPage.routeName);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'progress',
                child: Text(t.speakingDashboardTitle),
              ),
              PopupMenuItem(
                value: 'notebook',
                child: Text(t.speakingNotebookTitle),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s4),
            child: InkWell(
              onTap: _showVoiceSelector,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 112),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: app_color.AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: app_color.AppColors.outline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.record_voice_over_rounded,
                        size: 16, color: app_color.AppColors.textPrimary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _selectedVoice.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: AppTypography.mobileCaption, fontWeight: FontWeight.w600),
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
          child: Container(color: app_color.AppColors.outline, height: 1),
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
              color: app_color.AppColors.surfaceCard,
              border:
                  Border(top: BorderSide(color: app_color.AppColors.outline)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sóng âm khi AI nói
                if (isConnected && _isAiSpeaking)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                        height: 24, child: _Waveform(volume: _volumeLevel)),
                  ),
                if (isConnected && !_isTyping)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rate_review_outlined,
                            size: 16, color: Colors.red.shade500),
                        const SizedBox(width: 6),
                        Text(
                          t.speakingFbEndAndEvaluate,
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: AppTypography.mobileBody,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                Row(
                  children: [
                    // Ô nhập liệu
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: app_color.AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.sheet),
                        ),
                        child: TextField(
                          controller: _textController,
                          enabled: isConnected, // Chỉ nhập được khi đã kết nối
                          style: const TextStyle(
                              fontSize: AppTypography.mobileBodyLg,
                              color: app_color.AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: isConnecting
                                ? t.freeSpeakingHintConnecting
                                : (isConnected
                                    ? t.freeSpeakingHintTypeMessage
                                    : t.freeSpeakingHintTapMic),
                            hintStyle: const TextStyle(
                                color: app_color.AppColors.textMuted,
                                fontSize: AppTypography.mobileH2),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            prefixIcon: const Icon(Icons.keyboard_alt_outlined,
                                size: 20, color: app_color.AppColors.textMuted),
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
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                            color: (isConnected && !_isTyping)
                                ? Colors.red.shade500
                                : app_color.AppColors.primary,
                            borderRadius:
                                BorderRadius.circular(AppRadius.sheet),
                            boxShadow: [
                              BoxShadow(
                                  color: (isConnected && !_isTyping)
                                      ? Colors.red.withValues(alpha: 0.3)
                                      : app_color.AppColors.primary
                                          .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4))
                            ]),
                        child: Center(
                          child: isConnecting
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: AppLoadingIndicator.button(
                                      color: Colors.white))
                              : Icon(
                                  (!isConnected)
                                      ? Icons.mic_rounded // Icon bắt đầu
                                      : (_isTyping
                                          ? Icons.arrow_upward_rounded
                                          : Icons.stop_rounded),
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
    final displayText = message.id == 'sys_init'
        ? context.l10n.freeSpeakingWelcome
        : message.text;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: app_color.AppColors.outlineMuted,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: app_color.AppColors.outline),
          ),
          child: Text(
            displayText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: app_color.AppColors.textMuted,
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
  State<_ConversationTurnBubble> createState() =>
      _ConversationTurnBubbleState();
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
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser)
          Container(
            margin: const EdgeInsets.only(right: 10, top: 4),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: app_color.AppColors.primaryTint,
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(color: app_color.AppColors.outline),
            ),
            child: Icon(Icons.auto_awesome_rounded,
                color: app_color.AppColors.primary, size: 18),
          ),
        Flexible(
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: AppMotion.base,
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser
                      ? app_color.AppColors.primary
                      : app_color.AppColors.surfaceCard,
                  border: isUser
                      ? null
                      : Border.all(color: app_color.AppColors.outline),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(AppRadius.lg),
                    topRight: const Radius.circular(AppRadius.lg),
                    bottomLeft: Radius.circular(isUser ? 20 : 6),
                    bottomRight: Radius.circular(isUser ? 6 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isUser
                          ? app_color.AppColors.primary.withValues(alpha: 0.22)
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
                              fontSize: AppTypography.mobileBodyLg,
                              height: 1.5,
                              color: isUser
                                  ? Colors.white
                                  : app_color.AppColors.textPrimary,
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
                                  fontSize: AppTypography.mobileDisplay,
                                  color: isUser
                                      ? Colors.white70
                                      : scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_showTranslation) ...[
                      const SizedBox(height: 10),
                      Divider(
                          height: 1,
                          color: isUser
                              ? Colors.white24
                              : app_color.AppColors.outline),
                      const SizedBox(height: 8),
                      if (_isTranslating)
                        SizedBox(
                          height: 14,
                          width: 14,
                          child: AppLoadingIndicator(
                            strokeWidth: 2,
                            color: isUser
                                ? Colors.white70
                                : app_color.AppColors.primary,
                          ),
                        )
                      else
                        Text(
                          _translatedText ?? "",
                          style: TextStyle(
                            fontSize: AppTypography.mobileH2,
                            fontStyle: FontStyle.italic,
                            height: 1.45,
                            color: isUser
                                ? Colors.white.withValues(alpha: 0.92)
                                : app_color.AppColors.textMuted,
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
                        icon: _isPlaying
                            ? Icons.stop_circle_outlined
                            : Icons.volume_up_rounded,
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
              color: app_color.AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                  color: app_color.AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Icon(Icons.person_rounded,
                color: app_color.AppColors.primary, size: 20),
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

  const _ActionButton(
      {required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: active
              ? app_color.AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active
              ? app_color.AppColors.primary
              : app_color.AppColors.textMuted,
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
            color: app_color.AppColors.primary.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        );
      }),
    );
  }
}
