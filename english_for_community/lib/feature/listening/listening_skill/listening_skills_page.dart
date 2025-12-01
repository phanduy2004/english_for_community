import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../../../core/api/api_config.dart';
import '../../../core/entity/cue_entity.dart';
import 'bloc/cue_bloc.dart';
import 'bloc/cue_event.dart';
import 'bloc/cue_state.dart';

// --- HELPER FUNCTIONS ---
String _removeVietnameseDiacritics(String s) {
  const src = 'àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ';
  const dst = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydAAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
  final map = <String, String>{};
  for (var i = 0; i < src.length; i++) map[src[i]] = dst[i];
  final sb = StringBuffer();
  for (final ch in s.split('')) sb.write(map[ch] ?? ch);
  return sb.toString();
}

String _normalizeText(String s) {
  final lower = s.toLowerCase();
  final noDia = _removeVietnameseDiacritics(lower);
  final fixedQuote = noDia.replaceAll(RegExp(r"[’`´]"), "'");
  final stripped = fixedQuote.replaceAll(RegExp(r"[^a-z0-9'\s]"), ' ');
  return stripped.replaceAll(RegExp(r'\s+'), ' ').trim();
}

List<String> _tok(String s) => _normalizeText(s).split(' ').where((e) => e.isNotEmpty).toList();

String buildMaskedHintFE(String refRaw, String userText) {
  final refT = _tok(refRaw);
  final hypT = _tok(userText);
  int firstErr = -1;
  for (var i = 0; i < refT.length; i++) {
    final rt = refT[i];
    final ht = (i < hypT.length) ? hypT[i] : '';
    if (rt != ht && !rt.startsWith(ht)) {
      firstErr = i;
      break;
    }
  }
  if (firstErr == -1 && hypT.length < refT.length) firstErr = hypT.length;
  if (firstErr < 0) firstErr = (hypT.isEmpty ? 0 : hypT.length).clamp(0, (refT.length - 1).clamp(0, refT.length));
  final rawTokens = refRaw.split(RegExp(r'\s+'));
  final upto = (firstErr + 1).clamp(0, rawTokens.length);
  final shown = rawTokens.take(upto).join(' ');
  return (upto < rawTokens.length) ? '$shown *****' : shown;
}

// --- MAIN PAGE ---

class ListeningSkillsPage extends StatefulWidget {
  const ListeningSkillsPage({
    super.key,
    required this.listeningId,
    required this.audioUrl,
    this.title,
    this.levelText,
  });

  final String listeningId;
  final String audioUrl;
  final String? title;
  final String? levelText;

  @override
  State<ListeningSkillsPage> createState() => _ListeningSkillsPageState();
}

class _ListeningSkillsPageState extends State<ListeningSkillsPage> {
  late final ja.AudioPlayer _player;
  final _dictationCtrl = TextEditingController();
  late final Stopwatch _cueStopwatch;

  bool _audioReady = false;
  bool _autoPlayAfterClip = true;
  String? _lastHint;
  bool _showHint = false;
  StreamSubscription<ja.PlayerState>? _psSub;

  @override
  void initState() {
    super.initState();
    _player = ja.AudioPlayer();
    _initAudio();
    _psSub = _player.playerStateStream.listen((st) async {
      if (st.processingState == ja.ProcessingState.completed) {
        await _player.pause();
        await _player.seek(Duration.zero);
      }
    });
    _cueStopwatch = Stopwatch()..start();
  }

  @override
  void dispose() {
    _psSub?.cancel();
    _dictationCtrl.dispose();
    _player.dispose();
    _cueStopwatch.stop();
    super.dispose();
  }

  Future<void> _initAudio() async {
    try {
      final url = _normalizeAudioUrl(widget.audioUrl);
      await _player.setUrl(url);
      if (!mounted) return;
      setState(() => _audioReady = true);
    } catch (e) {
      _toast('Cannot load audio: $e');
    }
  }

  String _normalizeAudioUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    final base = ApiConfig.Base_URL;
    final baseNoTrail = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final path = raw.startsWith('/') ? raw : '/$raw';
    return '$baseNoTrail$path';
  }

  Future<void> _applyCueClip(CueEntity cue, {bool autoPlay = true}) async {
    if (!_audioReady) return;
    final start = Duration(milliseconds: cue.startMs ?? 0);
    final end = cue.endMs != null ? Duration(milliseconds: cue.endMs!) : null;
    try {
      await _player.setClip(start: start, end: end);
      await _player.seek(Duration.zero);
      if (autoPlay) await _player.play();
      else await _player.pause();
    } catch (e) {
      debugPrint('Cannot set clip: $e');
    }
  }

  Future<void> _replay() async {
    if (!_audioReady) return;
    await _player.seek(Duration.zero);
    await _player.play();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(milliseconds: 1500)));
  }

  Future<void> _submitAndScore(BuildContext blocCtx) async {
    final bloc = blocCtx.read<CueBloc>();
    final st = bloc.state;
    final text = _dictationCtrl.text.trim();
    final cue = st.currentCue;

    if (cue?.text != null && cue!.text!.isNotEmpty) {
      final localHint = buildMaskedHintFE(cue.text!, text);
      setState(() => _lastHint = localHint);
    }

    final result = await bloc.submitCue(
      listeningId: widget.listeningId,
      cueIdx: st.selectedIndex,
      userText: text,
      playedMs: _player.position.inMilliseconds,
      durationInSeconds: _cueStopwatch.elapsed.inSeconds,
    );

    setState(() => _showHint = (result.passed == false));

    if (result.passed) {
      _toast('✅ Correct!');
    } else {
      _toast('⚠️ Try again');
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgPage = Color(0xFFF9FAFB);
    const borderCol = Color(0xFFE4E4E7);
    const textMain = Color(0xFF09090B);

    return Builder(
      builder: (blocCtx) => Scaffold(
        backgroundColor: bgPage,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: borderCol, height: 1),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: textMain),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: const Text('Practice', style: TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 16)),
        ),
        body: SafeArea(
          child: BlocConsumer<CueBloc, CueState>(
            listenWhen: (prev, curr) =>
            prev.selectedIndex != curr.selectedIndex ||
                prev.userAnswer != curr.userAnswer ||
                prev.status != curr.status,

            listener: (blocCtx, state) {
              // 1. Đồng bộ Text Controller
              if (_dictationCtrl.text != state.userAnswer) {
                _dictationCtrl.text = state.userAnswer;
                _dictationCtrl.selection = TextSelection.collapsed(offset: state.userAnswer.length);
              }

              // Lưu ý: Logic play audio đã được chuyển xuống callback onIndexChanged
              // để xử lý chính xác hơn và tránh gọi thừa.
            },
            builder: (context, state) {
              return _BodyContent(
                state: state,
                player: _player,
                controller: _dictationCtrl,
                onTogglePlay: () {
                  if (_player.playing) _player.pause(); else _player.play();
                },
                onSeek: (pos) => _player.seek(pos),
                onReplay: _replay,
                onSubmit: () => _submitAndScore(blocCtx),
                onNext: () => blocCtx.read<CueBloc>().add(const NextCue()),
                onPrev: () => blocCtx.read<CueBloc>().add(const PrevCue()),
                onSelect: (i) => blocCtx.read<CueBloc>().add(SelectCueByIndex(i)),
                onTextChange: (val) => blocCtx.read<CueBloc>().add(UpdateUserAnswer(val)),
                showHint: _showHint,
                lastHint: _lastHint,
                autoPlay: _autoPlayAfterClip,
                onToggleAutoPlay: (v) => setState(() => _autoPlayAfterClip = v),

                // 🔥 KHẮC PHỤC LỖI SETSTATE HERE
                onIndexChanged: (cue) {
                  // Dùng addPostFrameCallback để đợi Build xong mới SetState/Play nhạc
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _cueStopwatch..reset()..start();
                    // Reset hint khi qua câu mới
                    setState(() {
                      _lastHint = null;
                      _showHint = false;
                    });
                    if (_audioReady) {
                      _applyCueClip(cue, autoPlay: _autoPlayAfterClip);
                    }
                  });
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// --- TÁCH WIDGET ĐỂ CODE GỌN GÀNG ---

class _BodyContent extends StatefulWidget {
  final CueState state;
  final ja.AudioPlayer player;
  final TextEditingController controller;
  final VoidCallback onTogglePlay;
  final Function(Duration) onSeek;
  final VoidCallback onReplay;
  final VoidCallback onSubmit;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final Function(int) onSelect;
  final Function(String) onTextChange;
  final Function(CueEntity) onIndexChanged;
  final bool showHint;
  final String? lastHint;
  final bool autoPlay;
  final Function(bool) onToggleAutoPlay;

  const _BodyContent({
    required this.state,
    required this.player,
    required this.controller,
    required this.onTogglePlay,
    required this.onSeek,
    required this.onReplay,
    required this.onSubmit,
    required this.onNext,
    required this.onPrev,
    required this.onSelect,
    required this.onTextChange,
    required this.onIndexChanged,
    required this.showHint,
    this.lastHint,
    required this.autoPlay,
    required this.onToggleAutoPlay,
  });

  @override
  State<_BodyContent> createState() => _BodyContentState();
}

class _BodyContentState extends State<_BodyContent> {
  int _prevIndex = -1;

  @override
  void didUpdateWidget(covariant _BodyContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Chỉ trigger callback khi index thực sự thay đổi
    if (widget.state.status == CueStatus.success && widget.state.selectedIndex != _prevIndex) {
      _prevIndex = widget.state.selectedIndex;
      if (widget.state.currentCue != null) {
        widget.onIndexChanged(widget.state.currentCue!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.status == CueStatus.loading) return const Center(child: CircularProgressIndicator());
    if (widget.state.status == CueStatus.error) return Center(child: Text(widget.state.errorMessage ?? 'Error'));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          _HeaderCard(
            title: 'Listening Task',
            doneCount: widget.state.completedIdx.length,
            totalCount: widget.state.cues.length,
          ),
          const SizedBox(height: 24),
          _PlayerCard(
            player: widget.player,
            onTogglePlay: widget.onTogglePlay,
            onSeek: widget.onSeek,
          ),
          const SizedBox(height: 24),
          _CueSelector(
            count: widget.state.cues.length,
            selectedIndex: widget.state.selectedIndex,
            completedIdx: widget.state.completedIdx,
            onSelect: widget.onSelect,
          ),
          const SizedBox(height: 24),
          _InteractionArea(
            state: widget.state,
            controller: widget.controller,
            onTextChange: widget.onTextChange,
            onSubmit: widget.onSubmit,
            onReplay: widget.onReplay,
            onNext: widget.onNext,
            onPrev: widget.onPrev,
            showHint: widget.showHint,
            lastHint: widget.lastHint,
            autoPlay: widget.autoPlay,
            onToggleAutoPlay: widget.onToggleAutoPlay,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// --- SUB WIDGETS ---

class _HeaderCard extends StatelessWidget {
  final String title;
  final int doneCount;
  final int totalCount;

  const _HeaderCard({required this.title, required this.doneCount, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : doneCount / totalCount;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [Color(0xFF18181B), Color(0xFF27272A)]),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Completed $doneCount / $totalCount sentences', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(width: 44, height: 44, child: CircularProgressIndicator(value: progress, backgroundColor: Colors.white24, color: Colors.greenAccent, strokeWidth: 4)),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final ja.AudioPlayer player;
  final VoidCallback onTogglePlay;
  final Function(Duration) onSeek;

  const _PlayerCard({required this.player, required this.onTogglePlay, required this.onSeek});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE4E4E7))),
      child: StreamBuilder<Duration?>(
        stream: player.durationStream,
        builder: (_, dSnap) {
          final dur = dSnap.data ?? Duration.zero;
          return StreamBuilder<Duration>(
            stream: player.positionStream,
            initialData: Duration.zero,
            builder: (_, pSnap) {
              final pos = pSnap.data ?? Duration.zero;
              final v = dur.inMilliseconds == 0 ? 0.0 : (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
              return Row(
                children: [
                  GestureDetector(
                    onTap: onTogglePlay,
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(10)),
                      child: StreamBuilder<ja.PlayerState>(
                        stream: player.playerStateStream,
                        builder: (_, s) => Icon(s.data?.playing == true ? Icons.pause : Icons.play_arrow, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), overlayShape: SliderComponentShape.noOverlay),
                      child: Slider(
                        value: v,
                        activeColor: primary,
                        onChanged: (val) => onSeek(Duration(milliseconds: (dur.inMilliseconds * val).round())),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CueSelector extends StatelessWidget {
  final int count;
  final int selectedIndex;
  final Set<int> completedIdx;
  final Function(int) onSelect;

  const _CueSelector({required this.count, required this.selectedIndex, required this.completedIdx, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(count, (i) {
          final isSel = i == selectedIndex;
          final isDone = completedIdx.contains(i);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: isSel ? Theme.of(context).primaryColor : (isDone ? const Color(0xFFECFDF5) : Colors.white),
                  border: Border.all(color: isSel ? Theme.of(context).primaryColor : (isDone ? const Color(0xFF86EFAC) : const Color(0xFFE4E4E7))),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('${i + 1}', style: TextStyle(color: isSel ? Colors.white : (isDone ? const Color(0xFF15803D) : Colors.black54), fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _InteractionArea extends StatelessWidget {
  final CueState state;
  final TextEditingController controller;
  final Function(String) onTextChange;
  final VoidCallback onSubmit;
  final VoidCallback onReplay;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final bool showHint;
  final String? lastHint;
  final bool autoPlay;
  final Function(bool) onToggleAutoPlay;

  const _InteractionArea({
    required this.state,
    required this.controller,
    required this.onTextChange,
    required this.onSubmit,
    required this.onReplay,
    required this.onNext,
    required this.onPrev,
    required this.showHint,
    this.lastHint,
    required this.autoPlay,
    required this.onToggleAutoPlay,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = state.completedIdx.contains(state.selectedIndex);
    final isLast = state.selectedIndex == state.cues.length - 1;
    final isAllDone = state.completedIdx.length == state.cues.length;

    String btnText = 'Check';
    Color btnColor = Theme.of(context).primaryColor;
    VoidCallback onBtn = onSubmit;
    IconData btnIcon = Icons.check;

    if (isDone) {
      if (isLast) {
        if (isAllDone) {
          btnText = 'Finish';
          btnColor = Colors.green;
          onBtn = () => Navigator.pop(context, true);
        } else {
          btnText = 'Review Missing';
          btnColor = Colors.orange;
          onBtn = () {};
        }
      } else {
        btnText = 'Next';
        btnColor = const Color(0xFF10B981);
        btnIcon = Icons.arrow_forward;
        onBtn = onNext;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE4E4E7))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sentence ${state.selectedIndex + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(onPressed: state.selectedIndex > 0 ? onPrev : null, icon: const Icon(Icons.chevron_left)),
                  IconButton(onPressed: !isLast ? onNext : null, icon: const Icon(Icons.chevron_right)),
                ],
              )
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Type what you hear...',
              filled: true, fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE4E4E7))),
            ),
            onChanged: onTextChange,
          ),
          if (showHint && lastHint != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
              child: Text(lastHint!, style: const TextStyle(color: Color(0xFFB91C1C))),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onBtn,
                  style: ElevatedButton.styleFrom(backgroundColor: btnColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12)),
                  icon: Icon(btnIcon, size: 18),
                  label: Text(btnText),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: onReplay,
                style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16)),
                child: const Icon(Icons.replay),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Auto-play next', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const Spacer(),
              Switch(value: autoPlay, onChanged: onToggleAutoPlay, activeColor: Theme.of(context).primaryColor),
            ],
          )
        ],
      ),
    );
  }
}