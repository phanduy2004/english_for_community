import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../../../core/api/api_config.dart';
import '../../../core/entity/cue_entity.dart';
import '../../../core/get_it/get_it.dart';

// Cue BLoC
import 'bloc/cue_bloc.dart';
import 'bloc/cue_event.dart';
import 'bloc/cue_state.dart';

/// =====================
/// Helpers (FE local)
/// =====================

String _removeVietnameseDiacritics(String s) {
  // 1. ADD the missing 'src' string
  const src =
      'àáảãạăằắẳẵặâầấẩẫậ'
      'èéẻẽẹêềếểễệ'
      'ìíỉĩị'
      'òóỏõọôồốổỗộơờớởỡợ'
      'ùúủũụưừứửữự'
      'ỳýỷỹỵ'
      'đ'
      'ÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬ'
      'ÈÉẺẼẸÊỀẾỂỄỆ'
      'ÌÍỈĨỊ'
      'ÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢ'
      'ÙÚỦŨỤƯỪỨỬỮỰ'
      'ỲÝỶỸỴ'
      'Đ';

  // 2. CORRECT the 'dst' string (it was 132 chars, should be 134)
  const dst =
      'aaaaaaaaaaaaaaaaa' // 17
      'eeeeeeeeeee' // 11
      'iiiii' // 5
      'ooooooooooooooooo' // 17 (was 16 in your code)
      'uuuuuuuuuuu' // 11 (was 10 in your code)
      'yyyyy' // 5
      'd' // 1
      'AAAAAAAAAAAAAAAAA' // 17
      'EEEEEEEEEEE' // 11
      'IIIII' // 5
      'OOOOOOOOOOOOOOOOO' // 17
      'UUUUUUUUUUU' // 11 (was 10 in your code)
      'YYYYY' // 5
      'D'; // 1

  // Both strings now have length 134
  final map = <String, String>{};
  for (var i = 0; i < src.length; i++) {
    map[src[i]] = dst[i];
  }
  final sb = StringBuffer();
  for (final ch in s.split('')) {
    sb.write(map[ch] ?? ch);
  }
  return sb.toString();
}

/// Chuẩn hoá: lowercase + bỏ dấu TV + hợp nhất nháy + bỏ dấu câu + gộp space
String _normalizeText(String s) {
  final lower = s.toLowerCase();
  final noDia = _removeVietnameseDiacritics(lower);
  final fixedQuote = noDia.replaceAll(RegExp(r"[’`´]"), "'");
  final stripped = fixedQuote.replaceAll(RegExp(r"[^a-z0-9'\s]"), ' ');
  return stripped.replaceAll(RegExp(r'\s+'), ' ').trim();
}

List<String> _tok(String s) =>
    _normalizeText(s).split(' ').where((e) => e.isNotEmpty).toList();

bool isSentenceCompleteFE(String refRaw, String userText) {
  final a = _tok(refRaw), b = _tok(userText);
  if (a.isEmpty || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Hint: show đúng tới từ sai (bao gồm từ sai ở dạng ĐÚNG), phần sau che "*****"
String buildMaskedHintFE(String refRaw, String userText) {
  final refT = _tok(refRaw);
  final hypT = _tok(userText);

  int firstErr = -1;
  for (var i = 0; i < refT.length; i++) {
    final rt = refT[i];
    final ht = (i < hypT.length) ? hypT[i] : '';
    final wrong = rt != ht && !rt.startsWith(ht);
    if (wrong) {
      firstErr = i;
      break;
    }
  }
  if (firstErr == -1 && hypT.length < refT.length) {
    firstErr = hypT.length; // đang gõ dở
  }
  if (firstErr < 0) {
    firstErr = (hypT.isEmpty ? 0 : hypT.length)
        .clamp(0, (refT.length - 1).clamp(0, refT.length));
  }

  // dùng refRaw để giữ hoa/thường & dấu câu ở phần hiển thị
  final rawTokens = refRaw.split(RegExp(r'\s+'));
  final upto = (firstErr + 1).clamp(0, rawTokens.length);
  final shown = rawTokens.take(upto).join(' ');
  return (upto < rawTokens.length) ? '$shown *****' : shown;
}

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

  bool _audioReady = false;
  bool _autoPlayAfterClip = true;

  // Hint chỉ hiển thị sau submit
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
  }

  @override
  void dispose() {
    _psSub?.cancel();
    _dictationCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _initAudio() async {
    try {
      final url = _normalizeAudioUrl(widget.audioUrl);
      await _player.setUrl(url);
      setState(() => _audioReady = true);
    } catch (e) {
      _toast('Cannot load audio: $e');
    }
  }

  String _normalizeAudioUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    final base = ApiConfig.Base_URL;
    final baseNoTrail =
    base.endsWith('/') ? base.substring(0, base.length - 1) : base;
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
    } catch (e) {
      _toast('Cannot set clip: $e');
    }
  }

  Future<void> _replay() async {
    await _player.seek(Duration.zero);
    await _player.play();
  }

  Future<void> _togglePlay() async =>
      _player.playing ? _player.pause() : _player.play();

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = (d.inSeconds.remainder(60)).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _submitAndScore(BuildContext blocCtx) async {
    final bloc = blocCtx.read<CueBloc>();
    final st = bloc.state;
    final idx = st.selectedIndex;
    final text = _dictationCtrl.text.trim();
    final cue = st.currentCue; // ref từ FE

    // 1) Hint local từ userText + refRaw (chỉ xuất hiện sau submit)
    String? localHint;
    if (cue?.text != null && cue!.text!.isNotEmpty) {
      localHint = buildMaskedHintFE(cue.text!, text);
    }

    // 2) Gọi BE để chấm pass + lưu attempt
    final result = await bloc.submitCue(
      listeningId: widget.listeningId,
      cueIdx: idx,
      userText: text,
      playedMs: _player.position.inMilliseconds,
    );

    // 3) Ưu tiên hint local; chỉ hiển thị nếu FAIL
    setState(() {
      _lastHint = localHint /* fallback:  ?? result.maskedHint */;
      _showHint = (result.passed == false) &&
          (_lastHint != null && _lastHint!.isNotEmpty);
    });

    if (result.passed /* hoặc isSentenceCompleteFE(cue.text!, text) */) {
      _toast('✅ Correct! Moving on.');
      _dictationCtrl.text = '';
      bloc.add(const NextCue());
    } else {
      _toast('⚠️ Keep typing until the full sentence matches.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CueBloc>(
      create: (_) => getIt<CueBloc>()
        ..add(LoadCuesAndAttempts(listeningId: widget.listeningId)),
      child: Builder(
        builder: (blocCtx) => Scaffold(
          appBar: AppBar(title: Text(widget.title ?? 'Listening')),
          body: BlocConsumer<CueBloc, CueState>(
            listenWhen: (prev, curr) =>
            (prev.status != curr.status &&
                curr.status == CueStatus.success) ||
                prev.selectedIndex != curr.selectedIndex ||
                (prev.justCompletedAll != curr.justCompletedAll &&
                    curr.justCompletedAll),
            listener: (blocCtx, state) async {
              final cue = state.currentCue;
              if (cue != null) {
                await _applyCueClip(cue, autoPlay: _autoPlayAfterClip);
              }
              final auto = state.latestAttempts[state.selectedIndex]?.userText ??
                  state.userAnswer;
              if (_dictationCtrl.text != auto) {
                _dictationCtrl.text = auto;
                _dictationCtrl.selection =
                    TextSelection.collapsed(offset: auto.length);
              }
              // đổi cue -> reset hint
              setState(() {
                _lastHint = null;
                _showHint = false;
              });
              if (state.justCompletedAll) {
                _toast('🎉 You completed this listening!');
              }
            },
            builder: (blocCtx, state) {
              if (state.status == CueStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == CueStatus.error) {
                return Center(child: Text(state.errorMessage ?? 'Error'));
              }

              final cs = Theme.of(blocCtx).colorScheme;
              final tt = Theme.of(blocCtx).textTheme;
              final cue = state.currentCue;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _headerCard(tt, cs),
                    const SizedBox(height: 12),
                    _playerCard(tt, cs),
                    const SizedBox(height: 12),
                    _cueChips(tt, cs, state, blocCtx),
                    const SizedBox(height: 12),
                    _cueCard(tt, cs, state, cue, blocCtx),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ===== UI helpers =====

  Widget _headerCard(TextTheme tt, ColorScheme cs) => _Card(
    child: Row(
      children: [
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title ?? 'Listening', style: tt.headlineSmall),
                if ((widget.levelText ?? '').isNotEmpty)
                  Text(widget.levelText!,
                      style: tt.bodyMedium
                          ?.copyWith(color: Colors.black54)),
              ]),
        ),
        StreamBuilder<ja.PlayerState>(
          stream: _player.playerStateStream,
          initialData: _player.playerState,
          builder: (_, snap) {
            final buffering =
                snap.data?.processingState == ja.ProcessingState.buffering;
            final playing = _player.playing;
            return InkWell(
              onTap: buffering ? null : _togglePlay,
              borderRadius: BorderRadius.circular(28),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: cs.primary,
                child: buffering
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.4),
                )
                    : Icon(playing ? Icons.pause : Icons.play_arrow,
                    color: cs.onPrimary),
              ),
            );
          },
        ),
      ],
    ),
  );

  Widget _playerCard(TextTheme tt, ColorScheme cs) => _Card(
    child: StreamBuilder<Duration?>(
      stream: _player.durationStream,
      builder: (_, dSnap) {
        final dur = dSnap.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: _player.positionStream,
          initialData: Duration.zero,
          builder: (_, pSnap) {
            final pos = pSnap.data ?? Duration.zero;
            final v = dur.inMilliseconds == 0
                ? 0.0
                : (pos.inMilliseconds / dur.inMilliseconds)
                .clamp(0.0, 1.0);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Slider(
                  value: v.isNaN ? 0 : v,
                  onChanged: (x) => _player.seek(
                      Duration(milliseconds: (dur.inMilliseconds * x).round())),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(pos),
                        style: tt.bodySmall
                            ?.copyWith(color: Colors.black54)),
                    Text(_fmt(dur),
                        style: tt.bodySmall
                            ?.copyWith(color: Colors.black54)),
                  ],
                ),
              ],
            );
          },
        );
      },
    ),
  );

  Widget _cueChips(TextTheme tt, ColorScheme cs, CueState state,
      BuildContext blocCtx) {
    if (state.cues.isEmpty) return const SizedBox.shrink();
    return _Card(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(state.cues.length, (i) {
          final passed = state.completedIdx.contains(i);
          final selected = i == state.selectedIndex;
          return ChoiceChip(
            label: Row(mainAxisSize: MainAxisSize.min, children: [
              if (passed)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(Icons.check,
                      size: 14, color: selected ? cs.onPrimary : Colors.green),
                ),
              Text('${i + 1}'),
            ]),
            selected: selected,
            onSelected: (_) =>
                blocCtx.read<CueBloc>().add(SelectCueByIndex(i)),
            selectedColor: cs.primary,
            labelStyle: TextStyle(color: selected ? cs.onPrimary : null),
          );
        }),
      ),
    );
  }

  Widget _cueCard(
      TextTheme tt,
      ColorScheme cs,
      CueState state,
      CueEntity? cue,
      BuildContext blocCtx) =>
      _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(
                state.cues.isEmpty
                    ? 'No cues'
                    : 'Cue ${state.selectedIndex + 1}/${state.cues.length}',
                style: tt.titleMedium,
              ),
              const Spacer(),
              IconButton(
                onPressed: state.selectedIndex <= 0
                    ? null
                    : () => blocCtx.read<CueBloc>().add(const PrevCue()),
                icon: const Icon(Icons.skip_previous),
              ),
              IconButton(
                onPressed: state.selectedIndex >= state.cues.length - 1
                    ? null
                    : () => blocCtx.read<CueBloc>().add(const NextCue()),
                icon: const Icon(Icons.skip_next),
              ),
            ]),
            const SizedBox(height: 8),

            // ===== Input =====
            TextField(
              controller: _dictationCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Type what you hear...',
                filled: true,
                fillColor: cs.surfaceVariant.withOpacity(.3),
              ),
              onChanged: (t) =>
                  blocCtx.read<CueBloc>().add(UpdateUserAnswer(t)),
            ),
            const SizedBox(height: 8),

            // ===== HINT chỉ sau submit & chỉ khi fail =====
            if (_showHint) _submittedHint(context),

            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _submitAndScore(blocCtx),
                  child: const Text('Check Answer'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _replay,
                icon: const Icon(Icons.replay),
                label: const Text('Replay'),
              ),
            ]),

            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Autoplay each cue', style: tt.bodyMedium),
              Switch(
                  value: _autoPlayAfterClip,
                  onChanged: (v) =>
                      setState(() => _autoPlayAfterClip = v)),
            ]),
          ],
        ),
      );

  Widget _submittedHint(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        _lastHint ?? '',
        style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              blurRadius: 8, color: Color(0x1A000000), offset: Offset(0, 2))
        ],
      ),
      child: child,
    );
  }
}
