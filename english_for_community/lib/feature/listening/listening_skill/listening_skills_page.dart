import 'dart:async';
import 'package:english_for_community/feature/auth/bloc/user_bloc.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../../../core/api/api_config.dart';
import '../../../core/locale/l10n_context.dart';
import '../../../core/ui/widget/app_corner_toast.dart';
import '../../../core/theme/app_color.dart';
import '../../../core/theme/app_skill_colors.dart';
import '../../../core/ui/student_mobile_ui.dart';
import '../../../core/entity/comment_entity.dart';
import '../../../core/entity/cue_entity.dart';
import '../../../core/socket/socket_service.dart';

import '../widget/discussion_tab.dart';
import '../widget/listening_common_widgets.dart';
import '../widget/practice_tab.dart';
import 'bloc/cue_bloc.dart';
import 'bloc/cue_event.dart';
import 'bloc/cue_state.dart';

class ListeningSkillsPage extends StatefulWidget {
  final String listeningId;
  final String audioUrl;
  final String? title;
  final String? levelText;

  // 🔥 THÊM 2 THAM SỐ MỚI
  final int initialTab; // 0: Practice, 1: Discussion
  final String? targetCommentId; // ID comment cần highlight
  final bool embedded;
  final bool examPracticeMode;
  final bool readOnlyReview;
  final VoidCallback? onPartComplete;
  final void Function(Map<String, String> cueTextsByIndex, int savedCount, int totalCount)?
      onExamListeningProgress;

  const ListeningSkillsPage({
    super.key,
    required this.listeningId,
    required this.audioUrl,
    this.title,
    this.levelText,
    this.initialTab = 0, // Mặc định là Practice
    this.targetCommentId,
    this.embedded = false,
    this.examPracticeMode = false,
    this.readOnlyReview = false,
    this.onPartComplete,
    this.onExamListeningProgress,
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
  bool _autoPlayAfterClip = true;
  String? _lastHint;
  bool _showHint = false;
  int _currentIndex = -1;
  StreamSubscription<ja.PlayerState>? _psSub;

  /// Tracks cue indices whose audio clip has been fully played (exam-only).
  final Set<int> _playedCues = {};
  bool get _currentCuePlayed => widget.examPracticeMode && _playedCues.contains(_currentIndex);

  @override
  void initState() {
    super.initState();
    _player = ja.AudioPlayer();

    // 🔥 SỬ DỤNG initialTab ĐỂ KHỞI TẠO TAB CONTROLLER
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );

    _initAudio();
    if (!widget.embedded) {
      _initSocketListeners();
    }

    _psSub = _player.playerStateStream.listen((st) async {
      if (st.processingState == ja.ProcessingState.completed) {
        await _player.pause();
        await _player.seek(Duration.zero);
        if (widget.examPracticeMode && _currentIndex >= 0) {
          setState(() => _playedCues.add(_currentIndex));
        }
      }
    });

    _cueStopwatch.start();
  }

  void _initSocketListeners() {
    final socketService = GetIt.I<SocketService>();
    socketService.joinListeningRoom(widget.listeningId);

    socketService.listenToReactionUpdates((data) {
      // Parse data từ Socket (JSON object)
      final String commentId = data['commentId'];
      final String cueId = data['cueId'] ?? "";
      final List<dynamic> reactionsJson = data['reactions'];

      final reactions = reactionsJson.map((e) => ReactionEntity.fromJson(e)).toList();

      if (mounted) {
        context.read<CueBloc>().add(IncomingSocketReaction(
            commentId: commentId,
            cueId: cueId,
            reactions: reactions
        ));
      }
    });

    socketService.listenToNewComments((data) {
      try {
        final String cueId = data['cueId'] ?? "";
        final newCommentJson = data['comment'];

        if (newCommentJson != null) {
          final newComment = CommentEntity.fromJson(newCommentJson);
          if (mounted) {
            context.read<CueBloc>().add(IncomingSocketComment(
                cueId: cueId,
                comment: newComment
            ));
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
    if (!widget.embedded) {
      GetIt.I<SocketService>().leaveListeningRoom(widget.listeningId);
    }
    super.dispose();
  }

  Future<void> _initAudio() async {
    if (widget.audioUrl.isEmpty) return; // Tránh lỗi nếu audio rỗng
    try {
      final url = widget.audioUrl.startsWith('http')
          ? widget.audioUrl
          : '${ApiConfig.Base_URL}${widget.audioUrl.startsWith('/') ? '' : '/'}${widget.audioUrl}';

      await _player.setUrl(url);

      if (mounted) {
        setState(() => _audioReady = true);
        final state = context.read<CueBloc>().state;
        if (state.currentCue != null) {
          _currentIndex = state.selectedIndex;
          // Nếu đang ở Tab Discussion thì đừng auto play
          bool shouldPause = widget.initialTab == 1 ? true : true;
          await _applyCueClip(state.currentCue!, forcePause: shouldPause);
        }
      }
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _applyCueClip(CueEntity cue, {bool forcePause = false}) async {
    if (!_audioReady) return;
    try {
      final start = Duration(milliseconds: cue.startMs);
      final end = cue.endMs > cue.startMs
          ? Duration(milliseconds: cue.endMs)
          : null;
      await _player.setClip(start: start, end: end);
      await _player.seek(Duration.zero);
      if (forcePause || !_autoPlayAfterClip) {
        await _player.pause();
      } else {
        _player.play();
      }
    } catch (_) {}
  }

  Map<String, String> _examCueTexts(CueState st) {
    final map = <String, String>{};
    for (final e in st.latestAttempts.entries) {
      final t = e.value.userText?.trim() ?? '';
      if (t.isNotEmpty) map['${e.key}'] = t;
    }
    final cur = st.userAnswer.trim();
    if (cur.isNotEmpty) map['${st.selectedIndex}'] = cur;
    return map;
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
    if (text.isEmpty) return;

    final silent = widget.examPracticeMode;
    if (!silent) {
      final cue = st.currentCue;
      if (cue?.text != null && cue!.text!.isNotEmpty) {
        setState(() => _lastHint = _buildMaskedHint(cue.text!, text));
      }
    }

    final result = await bloc.submitCue(
      listeningId: widget.listeningId,
      cueIdx: st.selectedIndex,
      userText: text,
      playedMs: _player.position.inMilliseconds,
      durationInSeconds: _cueStopwatch.elapsed.inSeconds,
      examSilentMode: silent,
    );

    if (!mounted) return;

    if (silent) {
      final next = bloc.state;
      widget.onExamListeningProgress?.call(
        _examCueTexts(next),
        next.completedIdx.length,
        next.cues.length,
      );
      if (next.selectedIndex < next.cues.length - 1) {
        bloc.add(const NextCue());
      }
      return;
    }

    setState(() => _showHint = !result.passed);
    if (!mounted) return;
    final t = context.l10n;
    AppCornerToast.show(
      context,
      result.passed ? '✅ ${t.dictationSnackCorrect}' : '⚠️ ${t.dictationSnackTryAgain}',
      error: !result.passed,
    );
  }

  Widget _buildCueContent(BuildContext context, String myUserId) {
    final t = context.l10n;
    return BlocConsumer<CueBloc, CueState>(
          listenWhen: (p, c) => p.selectedIndex != c.selectedIndex || p.userAnswer != c.userAnswer,
          listener: (context, state) {
            if (_dictationCtrl.text != state.userAnswer) {
              _dictationCtrl.text = state.userAnswer;
              _dictationCtrl.selection = TextSelection.collapsed(offset: state.userAnswer.length);
            }
            if (state.currentCue != null && state.selectedIndex != _currentIndex) {
              _currentIndex = state.selectedIndex;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _cueStopwatch.reset();
                _cueStopwatch.start();
                setState(() { _lastHint = null; _showHint = false; });
                if (_audioReady) {
                  _applyCueClip(state.currentCue!);
                }
              });
            }
          },
          builder: (context, state) {
            if (state.status == CueStatus.loading) return const Center(child: AppLoadingIndicator.center());
            if (state.status == CueStatus.error) {
              return Center(child: Text(state.errorMessage ?? context.l10n.commonError));
            }

            final practice = PracticeTab(
              state: state,
              controller: _dictationCtrl,
              onTextChange: (v) => context.read<CueBloc>().add(UpdateUserAnswer(v)),
              onSubmit: () => _submitAndScore(context),
              onReplay: widget.examPracticeMode || _currentCuePlayed
                  ? null
                  : () async {
                      await _player.seek(Duration.zero);
                      _player.play();
                    },
              onNext: () => context.read<CueBloc>().add(const NextCue()),
              onPrev: () => context.read<CueBloc>().add(const PrevCue()),
              showHint: _showHint,
              lastHint: _lastHint,
              autoPlay: _autoPlayAfterClip,
              onToggleAutoPlay: (v) => setState(() => _autoPlayAfterClip = v),
              onAllFinished: widget.onPartComplete,
              examPracticeMode: widget.examPracticeMode,
              readOnlyReview: widget.readOnlyReview,
            );

            if (widget.embedded) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListeningHeader(
                    title: widget.title ?? t.listeningSkillsHeaderTitle,
                    levelText: widget.levelText,
                    doneCount: state.completedIdx.length,
                    totalCount: state.cues.length,
                  ),
                  const SizedBox(height: 16),
                  ListeningPlayer(
                    player: _player,
                    onTogglePlay: _currentCuePlayed ? null : () => _player.playing ? _player.pause() : _player.play(),
                    onSeek: widget.examPracticeMode ? null : (d) => _player.seek(d),
                    allowSeek: !widget.examPracticeMode,
                    disabled: _currentCuePlayed,
                  ),
                  const SizedBox(height: 16),
                  CueSelector(
                    count: state.cues.length,
                    selectedIndex: state.selectedIndex,
                    completedIdx: state.completedIdx,
                    skillAccent: widget.examPracticeMode ? AppSkillColors.listening : null,
                    onSelect: (i) => context.read<CueBloc>().add(SelectCueByIndex(i)),
                  ),
                  const SizedBox(height: 16),
                  practice,
                ],
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  ListeningHeader(
                    title: widget.title ?? t.listeningSkillsHeaderTitle,
                    levelText: widget.levelText,
                    doneCount: state.completedIdx.length,
                    totalCount: state.cues.length,
                  ),
                  const SizedBox(height: 24),
                  ListeningPlayer(
                    player: _player,
                    onTogglePlay: () => _player.playing ? _player.pause() : _player.play(),
                    onSeek: (d) => _player.seek(d),
                  ),
                  const SizedBox(height: 24),
                  CueSelector(
                    count: state.cues.length,
                    selectedIndex: state.selectedIndex,
                    completedIdx: state.completedIdx,
                    skillAccent: widget.examPracticeMode ? AppSkillColors.listening : null,
                    onSelect: (i) => context.read<CueBloc>().add(SelectCueByIndex(i)),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          labelColor: Theme.of(context).primaryColor,
                          unselectedLabelColor: Colors.grey,
                          indicatorSize: TabBarIndicatorSize.tab,
                          tabs: [
                            Tab(icon: const Icon(Icons.edit_note), text: t.listeningSkillsTabPractice),
                            Tab(icon: const Icon(Icons.forum_outlined), text: t.listeningSkillsTabDiscuss),
                          ],
                        ),
                        const Divider(height: 1, color: AppColors.outline),
                        SizedBox(
                          height: 450,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              practice,
                              DiscussionTab(
                                comments: state.comments,
                                isLoading: state.isCommentsLoading,
                                currentUserId: myUserId,
                                targetCommentId: widget.targetCommentId,
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
        );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final String myUserId = context.select((UserBloc bloc) => bloc.state.userEntity?.id ?? "");
    final content = _buildCueContent(context, myUserId);

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: StudentMobileUi.skillAppBar(
        context,
        title: widget.title ?? t.listeningSkillsPracticeTitle,
        skill: SkillType.listening,
      ),
      body: SafeArea(child: content),
    );
  }
}