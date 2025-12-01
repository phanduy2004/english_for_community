import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// ✅ SỬA 1: Dùng absolute import để tránh lỗi đường dẫn
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
  final _audioUrlCtrl = TextEditingController();
  final _cefrCtrl = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  ListeningDifficulty _difficulty = ListeningDifficulty.easy;
  List<Map<String, dynamic>> cues = [];
  bool _isLoadingDetail = false;

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
    _audioUrlCtrl.dispose();
    _cefrCtrl.dispose();
    _scrollController.dispose();
    getIt<AdminListeningBloc>().add(ClearSelectedListeningEvent());
    super.dispose();
  }

  void _populateData(ListeningEntity item) {
    _titleCtrl.text = item.title;
    _codeCtrl.text = item.code ?? '';
    _audioUrlCtrl.text = item.audioUrl;
    _cefrCtrl.text = item.cefr ?? '';
    _difficulty = item.difficulty ?? ListeningDifficulty.easy;

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

  void _onSubmit() {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_titleCtrl.text.isEmpty || _audioUrlCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập Title và Audio URL")),
      );
      return;
    }

    List<CueEntity> cueEntities = [];
    for (int i = 0; i < cues.length; i++) {
      final c = cues[i];
      final text = c['text']?.toString().trim() ?? '';

      // ✅ SỬA 2: Bỏ listeningId và idx vì CueEntity mới không cần nữa
      cueEntities.add(CueEntity(
        id: '', // Server tự sinh ID, client gửi rỗng
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
      audioUrl: _audioUrlCtrl.text,
      difficulty: _difficulty,
      cefr: _cefrCtrl.text,
      totalCues: cueEntities.length,
      cues: cueEntities,
    );

    if (widget.id != null) {
      context.read<AdminListeningBloc>().add(
          UpdateListeningEvent(
              id: widget.id!, listening: newListening, cues: cueEntities)
      );
    } else {
      context.read<AdminListeningBloc>().add(
          CreateListeningEvent(listening: newListening, cues: cueEntities)
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
    // ... (Giữ nguyên phần build UI, không thay đổi)
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

  // ... (Các widget _buildSectionHeader, _buildGeneralInfoCard, _buildCueCardsList, _buildCueCard, _CompactTableInput giữ nguyên như cũ)

  // (Tôi copy lại các helper widget để bạn copy-paste cho tiện, không cần tìm lại code cũ)
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
          ShadcnInput(label: "Audio URL", controller: _audioUrlCtrl, hint: "/assets/audio/file.mp3"),
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
                  children: [
                    Expanded(child: _CompactTableInput(hint: "Start", value: cue['startMs'], onChanged: (v) => cue['startMs'] = v, isNumber: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _CompactTableInput(hint: "End", value: cue['endMs'], onChanged: (v) => cue['endMs'] = v, isNumber: true)),
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