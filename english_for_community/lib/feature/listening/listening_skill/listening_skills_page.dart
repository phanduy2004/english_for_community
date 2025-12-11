import 'dart:async';
import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../../../core/api/api_config.dart';
import '../../../core/entity/comment_entity.dart';
import '../../../core/entity/cue_entity.dart';
import '../../../core/socket/socket_service.dart';

import '../widget/discussion_tab.dart';
import '../widget/listening_common_widgets.dart';
import '../widget/practice_tab.dart'; // Import gốc của bạn
import 'bloc/cue_bloc.dart';
import 'bloc/cue_event.dart';
import 'bloc/cue_state.dart';

class ListeningSkillsPage extends StatefulWidget {
  final String listeningId;
  final String audioUrl;
  final String? title;
  final String? levelText;

  const ListeningSkillsPage({
    super.key,
    required this.listeningId,
    required this.audioUrl,
    this.title,
    this.levelText,
  });

  @override
  State<ListeningSkillsPage> createState() => _ListeningSkillsPageState();
}

class _ListeningSkillsPageState extends State<ListeningSkillsPage> with SingleTickerProviderStateMixin {
  late final ja.AudioPlayer _player;
  late final TabController _tabController;
  final _dictationCtrl = TextEditingController();
  final Stopwatch _cueStopwatch = Stopwatch();

  bool _audioReady = false;

  // Mặc định là true để khi Next/Prev thì tự chạy.
  // Nhưng lần đầu vào (Cue 1) sẽ được xử lý riêng để KHÔNG tự chạy.
  bool _autoPlayAfterClip = true;

  String? _lastHint;
  bool _showHint = false;

  // 🔥 Biến mới: Theo dõi index hiện tại để tránh xung đột khi gõ phím
  int _currentIndex = -1;

  StreamSubscription<ja.PlayerState>? _psSub;

  @override
  void initState() {
    super.initState();
    _player = ja.AudioPlayer();
    _tabController = TabController(length: 2, vsync: this);

    // Khởi tạo Audio và Socket
    _initAudio();
    _initSocketListeners();

    // Logic: Khi chạy hết clip (Cue) thì pause và tua về đầu Cue đó
    _psSub = _player.playerStateStream.listen((st) async {
      if (st.processingState == ja.ProcessingState.completed) {
        await _player.pause();
        await _player.seek(Duration.zero);
      }
    });

    _cueStopwatch.start();
  }

  void _initSocketListeners() {
    final socketService = GetIt.I<SocketService>();
    socketService.joinListeningRoom(widget.listeningId);

    socketService.listenToReactionUpdates((commentId, reactionsJson) {
      final reactions = reactionsJson.map((e) => ReactionEntity.fromJson(e)).toList();
      if (mounted) {
        context.read<CueBloc>().add(IncomingSocketReaction(commentId: commentId, reactions: reactions));
      }
    });

    socketService.listenToNewComments((data) {
      try {
        final newCommentJson = data['comment'];
        if (newCommentJson != null) {
          final newComment = CommentEntity.fromJson(newCommentJson);
          if (mounted) {
            context.read<CueBloc>().add(IncomingSocketComment(newComment));
          }
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _psSub?.cancel();
    _dictationCtrl.dispose();
    _player.dispose();
    _tabController.dispose();
    _cueStopwatch.stop();
    GetIt.I<SocketService>().leaveListeningRoom(widget.listeningId);
    super.dispose();
  }

  // 🔥 FIX 1: Load Audio và chuẩn bị sẵn Cue 1 (nhưng không phát)
  Future<void> _initAudio() async {
    try {
      final url = widget.audioUrl.startsWith('http')
          ? widget.audioUrl
          : '${ApiConfig.Base_URL}${widget.audioUrl.startsWith('/') ? '' : '/'}${widget.audioUrl}';

      await _player.setUrl(url);

      if (mounted) {
        setState(() => _audioReady = true);

        // Lấy state hiện tại (thường là Cue 0)
        final state = context.read<CueBloc>().state;
        if (state.currentCue != null) {
          // Cập nhật index để đồng bộ
          _currentIndex = state.selectedIndex;
          // Cắt audio cho Cue 1, nhưng ép PAUSE (forcePause: true)
          await _applyCueClip(state.currentCue!, forcePause: true);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Audio Error: $e')));
    }
  }

  // Hàm xử lý cắt clip audio
  Future<void> _applyCueClip(CueEntity cue, {bool forcePause = false}) async {
    if (!_audioReady) return;
    try {
      final start = Duration(milliseconds: cue.startMs ?? 0);
      final end = cue.endMs != null ? Duration(milliseconds: cue.endMs!) : null;

      // Cắt vùng nghe
      await _player.setClip(start: start, end: end);
      // Đưa con trỏ về đầu clip
      await _player.seek(Duration.zero);

      // Nếu là lần đầu (forcePause) hoặc người dùng tắt autoPlay -> Pause
      if (forcePause || !_autoPlayAfterClip) {
        await _player.pause();
      } else {
        _player.play();
      }
    } catch (_) {}
  }

  String _buildMaskedHint(String refRaw, String userText) {
    final refTokens = refRaw.toLowerCase().split(RegExp(r'\s+'));
    final userTokens = userText.toLowerCase().split(RegExp(r'\s+'));
    int errorIndex = -1;
    for (int i = 0; i < refTokens.length; i++) {
      if (i >= userTokens.length || refTokens[i] != userTokens[i]) {
        errorIndex = i;
        break;
      }
    }
    if (errorIndex == -1) return refRaw;
    final shown = refTokens.take(errorIndex + 1).join(' ');
    return '$shown *****';
  }

  Future<void> _submitAndScore(BuildContext context) async {
    final bloc = context.read<CueBloc>();
    final st = bloc.state;
    final text = _dictationCtrl.text.trim();
    final cue = st.currentCue;

    if (cue?.text != null && cue!.text!.isNotEmpty) {
      setState(() => _lastHint = _buildMaskedHint(cue.text!, text));
    }

    final result = await bloc.submitCue(
      listeningId: widget.listeningId,
      cueIdx: st.selectedIndex,
      userText: text,
      playedMs: _player.position.inMilliseconds,
      durationInSeconds: _cueStopwatch.elapsed.inSeconds,
    );

    setState(() => _showHint = !result.passed);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.passed ? '✅ Correct!' : '⚠️ Try again'),
      duration: const Duration(milliseconds: 1000),
      backgroundColor: result.passed ? Colors.green : Colors.orange,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final String myUserId = context.select((UserBloc bloc) => bloc.state.userEntity?.id ?? "");

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(widget.title ?? 'Practice', style: const TextStyle(color: Color(0xFF09090B), fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF09090B)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: const Color(0xFFE4E4E7), height: 1)),
      ),
      body: SafeArea(
        child: BlocConsumer<CueBloc, CueState>(
          listenWhen: (p, c) => p.selectedIndex != c.selectedIndex || p.userAnswer != c.userAnswer,
          listener: (context, state) {
            // 1. Đồng bộ Text hiển thị (nếu cần)
            if (_dictationCtrl.text != state.userAnswer) {
              _dictationCtrl.text = state.userAnswer;
              _dictationCtrl.selection = TextSelection.collapsed(offset: state.userAnswer.length);
            }

            // 🔥 FIX 2: Chỉ reset Audio khi CHUYỂN CÂU (Index thay đổi)
            // Không chạy khi người dùng đang gõ phím
            if (state.currentCue != null && state.selectedIndex != _currentIndex) {
              _currentIndex = state.selectedIndex; // Cập nhật index mới

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _cueStopwatch.reset();
                _cueStopwatch.start();
                setState(() { _lastHint = null; _showHint = false; });

                // Audio đã sẵn sàng thì cắt và tự play (theo biến _autoPlayAfterClip)
                if (_audioReady) {
                  _applyCueClip(state.currentCue!);
                }
              });
            }
          },
          builder: (context, state) {
            if (state.status == CueStatus.loading) return const Center(child: CircularProgressIndicator());
            if (state.status == CueStatus.error) return Center(child: Text(state.errorMessage ?? 'Error'));

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  ListeningHeader(
                    title: widget.title ?? 'Listening Task',
                    levelText: widget.levelText,
                    doneCount: state.completedIdx.length,
                    totalCount: state.cues.length,
                  ),
                  const SizedBox(height: 24),
                  ListeningPlayer(
                    player: _player,
                    // Nút Play/Pause ở Player chính
                    onTogglePlay: () => _player.playing ? _player.pause() : _player.play(),
                    onSeek: (d) => _player.seek(d),
                  ),
                  const SizedBox(height: 24),
                  CueSelector(
                    count: state.cues.length,
                    selectedIndex: state.selectedIndex,
                    completedIdx: state.completedIdx,
                    onSelect: (i) => context.read<CueBloc>().add(SelectCueByIndex(i)),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE4E4E7)),
                    ),
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          labelColor: Theme.of(context).primaryColor,
                          unselectedLabelColor: Colors.grey,
                          indicatorSize: TabBarIndicatorSize.tab,
                          tabs: const [
                            Tab(icon: Icon(Icons.edit_note), text: "Practice"),
                            Tab(icon: Icon(Icons.forum_outlined), text: "Discuss"),
                          ],
                        ),
                        const Divider(height: 1, color: Color(0xFFE4E4E7)),
                        SizedBox(
                          height: 450,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              PracticeTab(
                                state: state,
                                controller: _dictationCtrl,
                                // Khi gõ, chỉ gửi event update text, KHÔNG ảnh hưởng audio
                                onTextChange: (v) => context.read<CueBloc>().add(UpdateUserAnswer(v)),
                                onSubmit: () => _submitAndScore(context),
                                // Nút Replay: Tua về đầu Clip và Play
                                onReplay: () async {
                                  await _player.seek(Duration.zero);
                                  _player.play();
                                },
                                onNext: () => context.read<CueBloc>().add(const NextCue()),
                                onPrev: () => context.read<CueBloc>().add(const PrevCue()),
                                showHint: _showHint,
                                lastHint: _lastHint,
                                autoPlay: _autoPlayAfterClip,
                                onToggleAutoPlay: (v) => setState(() => _autoPlayAfterClip = v),
                              ),
                              DiscussionTab(
                                comments: state.comments,
                                isLoading: state.isCommentsLoading,
                                currentUserId: myUserId,
                                onSend: (content, parentId) {
                                  if (myUserId.isEmpty) return;
                                  context.read<CueBloc>().add(PostCommentEvent(content: content, parentId: parentId));
                                },
                                onReact: (commentId, type) {
                                  if (myUserId.isEmpty) return;
                                  context.read<CueBloc>().add(ReactToCommentEvent(
                                      commentId: commentId,
                                      type: type,
                                      userId: myUserId
                                  ));
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}