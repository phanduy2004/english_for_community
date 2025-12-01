import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Import GetIt & Entities
import '../../../../../core/get_it/get_it.dart';
import '../../../../core/entity/speaking/sentence_entity.dart';
import '../../../../core/entity/speaking/speaking_set_entity.dart';

// Import Widgets
import '../content_widgets.dart'; // ShadcnCard, ShadcnInput...

// Import Bloc
import 'bloc/admin_speaking_bloc.dart';
import 'bloc/admin_speaking_event.dart';
import 'bloc/admin_speaking_state.dart';

class SpeakingEditorPage extends StatelessWidget {
  final String? id;
  const SpeakingEditorPage({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = getIt<AdminSpeakingBloc>();
        if (id != null) {
          bloc.add(GetSpeakingDetailEvent(id!));
        }
        return bloc;
      },
      child: _SpeakingEditorView(id: id),
    );
  }
}

class _SpeakingEditorView extends StatefulWidget {
  final String? id;
  const _SpeakingEditorView({this.id});

  @override
  State<_SpeakingEditorView> createState() => _SpeakingEditorViewState();
}

class _SpeakingEditorViewState extends State<_SpeakingEditorView> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _level = 'Beginner';
  String _mode = 'readAloud';

  List<Map<String, dynamic>> sentences = [];
  bool _isDataLoaded = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.id == null) {
      _addNewSentence();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _populateData(SpeakingSetEntity item) {
    _titleCtrl.text = item.title;
    _descCtrl.text = item.description;
    _level = item.level;
    _mode = item.mode;

    setState(() {
      sentences = item.sentences.map((s) => {
        "key": UniqueKey(),
        "speaker": s.speaker,
        "script": s.script,
        "phonetic": s.phoneticScript,
      }).toList();
      _isDataLoaded = true;
    });
  }

  void _onSubmit() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter title"))
      );
      return;
    }

    List<SentenceEntity> sentEntities = [];
    for (int i = 0; i < sentences.length; i++) {
      final s = sentences[i];
      sentEntities.add(SentenceEntity(
        id: '',
        order: i + 1,
        speaker: s['speaker']?.toString().trim() ?? 'You',
        script: s['script']?.toString().trim() ?? '',
        phoneticScript: s['phonetic']?.toString().trim() ?? '',
      ));
    }

    final entity = SpeakingSetEntity(
      id: widget.id ?? '',
      title: _titleCtrl.text,
      description: _descCtrl.text,
      level: _level,
      mode: _mode,
      sentences: sentEntities,
    );

    if (widget.id == null) {
      context.read<AdminSpeakingBloc>().add(CreateSpeakingEvent(entity));
    } else {
      context.read<AdminSpeakingBloc>().add(UpdateSpeakingEvent(id: widget.id!, speakingSet: entity));
    }
  }

  void _addNewSentence() {
    setState(() {
      sentences.add({
        "key": UniqueKey(),
        "speaker": "You",
        "script": "",
        "phonetic": ""
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut
        );
      }
    });
  }

  void _deleteSentence(int index) {
    setState(() => sentences.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminSpeakingBloc, AdminSpeakingState>(
      listener: (context, state) {
        if (state.status == AdminSpeakingStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? "Error"), backgroundColor: Colors.red)
          );
        }
        if (state.status == AdminSpeakingStatus.success && state.selectedSet != null && widget.id != null) {
          if (!_isDataLoaded) {
            _populateData(state.selectedSet!);
          }
        }
        if (state.status == AdminSpeakingStatus.success && _isDataLoaded && state.selectedSet == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Saved successfully!"), backgroundColor: Colors.green)
          );
          context.pop();
        }
        if (state.status == AdminSpeakingStatus.success && widget.id == null && state.selectedSet == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Created successfully!"), backgroundColor: Colors.green)
          );
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: kBgPage,
        appBar: AppBar(
          title: Text(
              widget.id == null ? 'New Speaking Set' : 'Edit Speaking',
              style: const TextStyle(color: kTextMain, fontWeight: FontWeight.bold, fontSize: 16)
          ),
          backgroundColor: kWhite,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: kTextMain),
              onPressed: () => context.pop()
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: FilledButton(
                onPressed: _onSubmit,
                style: FilledButton.styleFrom(backgroundColor: kTextMain),
                child: Text(
                    widget.id == null ? "Create" : "Update",
                    style: const TextStyle(fontWeight: FontWeight.bold)
                ),
              ),
            )
          ],
          bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: kBorder, height: 1)
          ),
        ),
        body: BlocBuilder<AdminSpeakingBloc, AdminSpeakingState>(
          builder: (context, state) {
            if (state.status == AdminSpeakingStatus.loading && widget.id != null && !_isDataLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16), // Padding vừa phải cho mobile
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Topic Info"),
                  const SizedBox(height: 12),
                  _buildMetadataCard(),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader("Sentences (${sentences.length})"),
                      TextButton.icon(
                        onPressed: _addNewSentence,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Add Sentence", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(foregroundColor: kTextMain),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Render danh sách dạng Column các Card thay vì Table
                  if (sentences.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: Text("No sentences yet.", style: TextStyle(color: kTextMuted))))
                  else
                    ...sentences.asMap().entries.map((e) => _buildSentenceCard(e.key, e.value)),

                  const SizedBox(height: 80), // Bottom spacing
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kTextMain));

  Widget _buildMetadataCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShadcnInput(label: "Title", controller: _titleCtrl, hint: "E.g. Ordering Coffee"),
          const SizedBox(height: 16),
          ShadcnInput(label: "Description", controller: _descCtrl, maxLines: 3, hint: "Short description..."),
          const SizedBox(height: 16),

          // Row cho Level và Mode (Mobile vẫn đủ chỗ cho 2 cái này)
          Row(
            children: [
              Expanded(child: _buildDropdown("Level", _level, ['Beginner', 'Intermediate', 'Advanced'], (v) => setState(() => _level = v!))),
              const SizedBox(width: 12),
              Expanded(child: _buildDropdown("Mode", _mode, ['readAloud', 'Shadowing', 'Pronunciation', 'FreeSpeaking'], (v) => setState(() => _mode = v!))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kTextMuted)),
        const SizedBox(height: 6),
        Container(
          height: 48, // Chiều cao chuẩn cho touch target
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: kTextMuted),
              items: items.map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // Widget hiển thị từng câu hỏi dạng Card (Tối ưu cho Mobile)
  Widget _buildSentenceCard(int index, Map<String, dynamic> s) {
    return Container(
      key: s['key'],
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]
      ),
      child: Column(
        children: [
          // Header của Card (Số thứ tự + Nút xóa)
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
                InkWell(
                  onTap: () => _deleteSentence(index),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  ),
                )
              ],
            ),
          ),

          // Body của Card (Các ô nhập liệu xếp dọc)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Speaker Input
                _buildCompactLabel("Speaker"),
                _CompactTableInput(hint: "E.g. You, Waiter...", value: s['speaker'], onChanged: (v) => s['speaker'] = v),

                const SizedBox(height: 12),

                // Script Input (Quan trọng nhất - cho to hơn)
                _buildCompactLabel("Script (English)"),
                _CompactTableInput(hint: "Type sentence here...", value: s['script'], onChanged: (v) => s['script'] = v, maxLines: 3),

                const SizedBox(height: 12),

                // Phonetic Input
                _buildCompactLabel("IPA / Phonetic (Optional)"),
                _CompactTableInput(hint: "/aɪ-pi-eɪ/", value: s['phonetic'], onChanged: (v) => s['phonetic'] = v),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCompactLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMuted)),
    );
  }
}

// Giữ nguyên _CompactTableInput nhưng style lại chút cho hợp mobile
class _CompactTableInput extends StatefulWidget {
  final String? value;
  final String hint;
  final Function(String) onChanged;
  final int? maxLines;
  const _CompactTableInput({required this.hint, required this.onChanged, this.value, this.maxLines = 1});
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
      _controller.text = widget.value ?? '';
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
      maxLines: widget.maxLines,
      minLines: 1,
      style: const TextStyle(
        // 🔥 SỬA DÒNG NÀY
          fontFamily: 'NotoSans',
          fontSize: 14,
          height: 1.4,
          color: kTextMain
      ),      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Padding rộng hơn để dễ tap
        hintText: widget.hint,
      hintStyle: const TextStyle(
          fontFamily: 'NotoSans', // Hoặc bỏ qua nếu font mặc định là NotoSans
          color: Color(0xFF94A3B8),
          fontSize: 12
      ),        filled: true, fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
      ),
    );
  }
}