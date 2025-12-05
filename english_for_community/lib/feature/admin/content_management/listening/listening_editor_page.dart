import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/entity/cue_entity.dart';
import 'package:english_for_community/core/entity/listening_entity.dart';

import '../content_widgets.dart';
import 'bloc/admin_listening_bloc.dart';
import 'bloc/admin_listening_event.dart';
import 'bloc/admin_listening_state.dart';

class ListeningEditorPage extends StatelessWidget {
  final String? id;
  const ListeningEditorPage({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AdminListeningBloc>(),
      child: _ListeningEditorView(id: id),
    );
  }
}

class _ListeningEditorView extends StatefulWidget {
  final String? id;
  const _ListeningEditorView({this.id});

  @override
  State<_ListeningEditorView> createState() => _ListeningEditorViewState();
}

class _ListeningEditorViewState extends State<_ListeningEditorView> {
  final _titleCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _cefrCtrl = TextEditingController();

  PlatformFile? _selectedAudioFile;
  String? _currentAudioUrl;

  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  ListeningDifficulty _difficulty = ListeningDifficulty.easy;
  List<Map<String, dynamic>> cues = [];
  bool _isLoadingDetail = false;
  String? _playingCueKey;

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      _isLoadingDetail = true;
      context.read<AdminListeningBloc>().add(GetListeningDetailEvent(widget.id!));
    } else {
      _addNewCue();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _codeCtrl.dispose();
    _cefrCtrl.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    getIt<AdminListeningBloc>().add(ClearSelectedListeningEvent());
    super.dispose();
  }

  void _populateData(ListeningEntity item) {
    _titleCtrl.text = item.title;
    _codeCtrl.text = item.code ?? '';
    _cefrCtrl.text = item.cefr ?? '';
    _difficulty = item.difficulty ?? ListeningDifficulty.easy;
    _currentAudioUrl = item.audioUrl;

    final cuesList = item.cues;

    setState(() {
      cues = cuesList.map((c) => {
        "key": UniqueKey(),
        "startMs": "${c.startMs}",
        "endMs": "${c.endMs}",
        "spk": c.spk ?? "",
        "text": c.text ?? "",
      }).toList();
      _isLoadingDetail = false;
    });
  }

  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: kIsWeb,
    );

    if (result != null) {
      setState(() {
        _selectedAudioFile = result.files.first;
      });
    }
  }
  String _getMimeType(String filename) {
    final name = filename.toLowerCase();
    if (name.endsWith('.wav')) return 'audio/wav';
    if (name.endsWith('.m4a')) return 'audio/mp4';
    if (name.endsWith('.aac')) return 'audio/aac';
    if (name.endsWith('.ogg')) return 'audio/ogg';
    return 'audio/mpeg'; // Mặc định cho mp3
  }
  Future<void> _previewAudioSegment(String key, String? startStr, String? endStr) async {
    final int startMs = int.tryParse(startStr ?? '') ?? 0;
    final int endMs = int.tryParse(endStr ?? '') ?? 0;

    if (endMs <= startMs) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thời gian kết thúc phải lớn hơn bắt đầu")));
      return;
    }

    try {
      UriAudioSource? source;

      // TRƯỜNG HỢP 1: Đang chọn file mới từ máy
      if (_selectedAudioFile != null) {
        if (kIsWeb) {
          // 🔥 FIX CHO WEB: Dùng Bytes chuyển thành Data URI
          if (_selectedAudioFile!.bytes != null) {
            final mimeType = _getMimeType(_selectedAudioFile!.name);
            source = AudioSource.uri(
                Uri.dataFromBytes(_selectedAudioFile!.bytes!, mimeType: mimeType)
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi: Không đọc được dữ liệu file trên Web")));
            return;
          }
        } else {
          // 📱 MOBILE/DESKTOP: Dùng đường dẫn file (path)
          if (_selectedAudioFile!.path != null) {
            source = AudioSource.file(_selectedAudioFile!.path!);
          }
        }
      }
      // TRƯỜNG HỢP 2: Đang sửa bài cũ (Dùng URL có sẵn)
      else if (_currentAudioUrl != null && _currentAudioUrl!.isNotEmpty) {
        source = AudioSource.uri(Uri.parse(_currentAudioUrl!));
      }

      if (source == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chưa có file audio")));
        return;
      }

      // Cắt đoạn audio cần nghe
      final clippingSource = ClippingAudioSource(
        child: source,
        start: Duration(milliseconds: startMs),
        end: Duration(milliseconds: endMs),
      );

      // Cập nhật trạng thái đang play
      setState(() => _playingCueKey = key);

      await _audioPlayer.stop();
      await _audioPlayer.setAudioSource(clippingSource);
      await _audioPlayer.play();

      // Khi phát xong (hoặc dừng)
      if (mounted) {
        setState(() => _playingCueKey = null);
      }

    } catch (e) {
      print("Error playing preview: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi phát audio: $e")));
        setState(() => _playingCueKey = null);
      }
    }
  }

  void _onSubmit() {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập Title")),
      );
      return;
    }

    if (widget.id == null && _selectedAudioFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn file Audio để tạo bài nghe")),
      );
      return;
    }

    List<CueEntity> cueEntities = [];
    for (int i = 0; i < cues.length; i++) {
      final c = cues[i];
      final text = c['text']?.toString().trim() ?? '';

      cueEntities.add(CueEntity(
        id: '',
        startMs: int.tryParse(c['startMs'].toString()) ?? 0,
        endMs: int.tryParse(c['endMs'].toString()) ?? 0,
        spk: c['spk']?.toString().trim(),
        text: text,
        textNorm: text.toLowerCase(),
      ));
    }

    final newListening = ListeningEntity(
      id: widget.id ?? '',
      title: _titleCtrl.text,
      code: _codeCtrl.text,
      audioUrl: '',
      difficulty: _difficulty,
      cefr: _cefrCtrl.text,
      totalCues: cueEntities.length,
      cues: cueEntities,
    );

    if (widget.id != null) {
      context.read<AdminListeningBloc>().add(
          UpdateListeningEvent(
              id: widget.id!,
              listening: newListening,
              cues: cueEntities,
              audioFile: _selectedAudioFile
          )
      );
    } else {
      context.read<AdminListeningBloc>().add(
          CreateListeningEvent(
              listening: newListening,
              cues: cueEntities,
              audioFile: _selectedAudioFile
          )
      );
    }
  }

  void _addNewCue() {
    setState(() {
      int nextStart = 0;
      if (cues.isNotEmpty) {
        nextStart = int.tryParse(cues.last['endMs'].toString()) ?? 0;
      }
      cues.add({
        "key": UniqueKey(),
        "startMs": nextStart.toString(),
        "endMs": (nextStart + 2000).toString(),
        "spk": cues.isNotEmpty ? cues.last['spk'] : "A",
        "text": ""
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _deleteCue(int index) {
    setState(() => cues.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminListeningBloc, AdminListeningState>(
      listener: (context, state) {
        if (state.status == AdminListeningStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage ?? "Error"), backgroundColor: Colors.red));
        }

        if (state.status == AdminListeningStatus.success && state.selectedListening != null && widget.id != null) {
          if (state.selectedListening!.id == widget.id && _isLoadingDetail) {
            _populateData(state.selectedListening!);
          }
        }

        if (state.status == AdminListeningStatus.success && !_isLoadingDetail && state.selectedListening == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thao tác thành công!"), backgroundColor: Colors.green));
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: kBgPage,
        appBar: AppBar(
          title: Text(widget.id == null ? 'New Listening' : 'Edit Listening',
              style: const TextStyle(color: kTextMain, fontWeight: FontWeight.bold, fontSize: 16)),
          backgroundColor: kWhite,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextMain), onPressed: () => context.pop()),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: FilledButton(
                onPressed: _onSubmit,
                style: FilledButton.styleFrom(
                    backgroundColor: kTextMain,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10)
                ),
                child: Text(
                  widget.id == null ? "Create" : "Update",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
          bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: kBorder, height: 1)),
        ),
        body: BlocBuilder<AdminListeningBloc, AdminListeningState>(
          builder: (context, state) {
            if (state.status == AdminListeningStatus.loading && (_isLoadingDetail || (cues.isEmpty && widget.id != null))) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("General Information"),
                  const SizedBox(height: 12),
                  _buildGeneralInfoCard(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader("Transcript Cues (${cues.length})"),
                      OutlinedButton.icon(
                        onPressed: _addNewCue,
                        style: OutlinedButton.styleFrom(
                            foregroundColor: kTextMain,
                            side: const BorderSide(color: kBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("Add Line"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCueCardsList(),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kTextMain));
  }

  Widget _buildGeneralInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          ShadcnInput(label: "Title", controller: _titleCtrl, hint: "e.g. Daily Conversation"),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: ShadcnInput(label: "Code", controller: _codeCtrl, hint: "p1_wakeup")),
              const SizedBox(width: 16),
              Expanded(child: ShadcnInput(label: "CEFR", controller: _cefrCtrl, hint: "A2")),
            ],
          ),
          const SizedBox(height: 16),

          _buildAudioUploader(),

          const SizedBox(height: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Difficulty", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTextMain)),
              const SizedBox(height: 8),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kBorder),
                  color: const Color(0xFFF8F9FA),
                ),
                child: Row(
                  children: ListeningDifficulty.values.map((level) {
                    final isSelected = _difficulty == level;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _difficulty = level),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isSelected ? kTextMain : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              level.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : kTextMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAudioUploader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Audio Source", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTextMain)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickAudio,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.audio_file_outlined, size: 20, color: kTextMain),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedAudioFile != null
                            ? _selectedAudioFile!.name
                            : (_currentAudioUrl != null && _currentAudioUrl!.isNotEmpty
                            ? "Current: ...${_currentAudioUrl!.substring((_currentAudioUrl!.length - 20).clamp(0, _currentAudioUrl!.length))}"
                            : "Click to select audio file"),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: _selectedAudioFile != null ? FontWeight.w600 : FontWeight.normal,
                            color: kTextMain
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_selectedAudioFile == null && _currentAudioUrl == null)
                        const Text("Supports MP3, WAV, M4A", style: TextStyle(fontSize: 12, color: kTextMuted)),
                    ],
                  ),
                ),
                if (_selectedAudioFile != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                    onPressed: () => setState(() => _selectedAudioFile = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                else
                  const Icon(Icons.upload_file_rounded, size: 18, color: kTextMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCueCardsList() {
    if (cues.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: const Column(
          children: [
            Icon(Icons.subtitles_off_outlined, size: 48, color: kTextMuted),
            SizedBox(height: 12),
            Text("Chưa có nội dung hội thoại.", style: TextStyle(color: kTextMuted)),
          ],
        ),
      );
    }
    return Column(
      children: cues.asMap().entries.map((entry) => _buildCueCard(entry.key, entry.value)).toList(),
    );
  }

  Widget _buildCueCard(int index, Map<String, dynamic> cue) {
    final String cueKeyStr = cue['key'].toString();
    final bool isPlaying = _playingCueKey == cueKeyStr;

    return Container(
      key: cue['key'],
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))]
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
                color: Color(0xFFFAFAFA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(bottom: BorderSide(color: kBorder))
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: kTextMain, borderRadius: BorderRadius.circular(4)),
                  child: Text("#${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  onPressed: () => _deleteCue(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Timing (ms)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMuted)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _CompactTableInput(hint: "Start", value: cue['startMs'], onChanged: (v) => cue['startMs'] = v, isNumber: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _CompactTableInput(hint: "End", value: cue['endMs'], onChanged: (v) => cue['endMs'] = v, isNumber: true)),
                    const SizedBox(width: 8),

                    InkWell(
                      onTap: () {
                        if (isPlaying) {
                          _audioPlayer.stop();
                          setState(() => _playingCueKey = null);
                        } else {
                          _previewAudioSegment(cueKeyStr, cue['startMs'], cue['endMs']);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: isPlaying ? Colors.red.withOpacity(0.1) : kTextMain.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isPlaying ? Colors.red : kTextMain),
                        ),
                        child: isPlaying
                            ? const Icon(Icons.stop_rounded, color: Colors.red)
                            : const Icon(Icons.play_arrow_rounded, color: kTextMain),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Speaker", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMuted)),
                const SizedBox(height: 6),
                _CompactTableInput(hint: "A / Waiter", value: cue['spk'], onChanged: (v) => cue['spk'] = v),
                const SizedBox(height: 16),
                const Text("Content", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMuted)),
                const SizedBox(height: 6),
                _CompactTableInput(hint: "Enter conversation text...", value: cue['text'], onChanged: (v) => cue['text'] = v, maxLines: 4),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _CompactTableInput extends StatefulWidget {
  final String? value;
  final String hint;
  final Function(String) onChanged;
  final bool isNumber;
  final TextAlign textAlign;
  final int? maxLines;

  const _CompactTableInput({
    required this.hint,
    required this.onChanged,
    this.value,
    this.isNumber = false,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
  });

  @override
  State<_CompactTableInput> createState() => _CompactTableInputState();
}

class _CompactTableInputState extends State<_CompactTableInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _CompactTableInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _controller.text) {
      final newValue = widget.value ?? '';
      if (_controller.text != newValue) {
        _controller.text = newValue;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      keyboardType: widget.isNumber ? TextInputType.number : TextInputType.multiline,
      maxLines: widget.maxLines,
      minLines: 1,
      textAlign: widget.textAlign,
      style: const TextStyle(fontSize: 14, height: 1.3),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintText: widget.hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black, width: 1.5),
        ),
      ),
    );
  }
}