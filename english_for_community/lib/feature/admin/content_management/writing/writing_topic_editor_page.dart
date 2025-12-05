import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/get_it/get_it.dart';
import '../../../../core/entity/writing_topic_entity.dart';
// FIX: Import widgets giao diện
import '../content_widgets.dart';
import 'bloc/admin_writing_bloc.dart';
import 'bloc/admin_writing_event.dart';
import 'bloc/admin_writing_state.dart';

class WritingTopicEditorPage extends StatelessWidget {
  final String? id;
  const WritingTopicEditorPage({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AdminWritingBloc>(),
      child: _EditorView(id: id),
    );
  }
}

class _EditorView extends StatefulWidget {
  final String? id;
  const _EditorView({this.id});

  @override
  State<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<_EditorView> {
  // Constants
  final List<String> kAllTaskTypes = [
    'Opinion',
    'Discussion',
    'Advantages-Disadvantages',
    'Problem-Solution',
    'Discuss both views and give your own opinion',
    'Two-part question',
  ];

  final List<String> kLevels = ['Beginner', 'Intermediate', 'Advanced'];

  // Controllers
  final _nameCtrl = TextEditingController();
  final _wordCountCtrl = TextEditingController();
  final _templateCtrl = TextEditingController();

  // State Variables
  bool _isActive = true;
  String _language = 'vi-VN';
  String _level = 'Intermediate';
  String _defaultTaskType = 'Discussion';
  List<String> _selectedTaskTypes = ['Discussion'];

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      context.read<AdminWritingBloc>().add(GetWritingTopicDetailEvent(widget.id!));
    } else {
      _wordCountCtrl.text = '250–320';
    }
  }

  @override
  void dispose() {
    context.read<AdminWritingBloc>().add(ClearSelectedWritingTopicEvent());
    _nameCtrl.dispose();
    _wordCountCtrl.dispose();
    _templateCtrl.dispose();
    super.dispose();
  }

  void _populateData(WritingTopicEntity topic) {
    _nameCtrl.text = topic.name;
    _isActive = topic.isActive;

    // FIX: Null Safety Checks
    _language = topic.aiConfig?.language ?? 'vi-VN';
    _level = topic.aiConfig?.level ?? 'Intermediate';
    _wordCountCtrl.text = topic.aiConfig?.targetWordCount ?? '250–320';
    _templateCtrl.text = topic.aiConfig?.generationTemplate ?? '';

    // FIX: Convert list an toàn
    _selectedTaskTypes = List<String>.from(topic.aiConfig?.taskTypes ?? ['Discussion']);
    _defaultTaskType = topic.aiConfig?.defaultTaskType ?? 'Discussion';

    setState(() {});
  }

  void _onSubmit() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tên chủ đề không được để trống")));
      return;
    }
    if (_selectedTaskTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Phải chọn ít nhất 1 loại bài (Task Type)")));
      return;
    }

    if (!_selectedTaskTypes.contains(_defaultTaskType)) {
      _defaultTaskType = _selectedTaskTypes.first;
    }

    final newTopic = WritingTopicEntity(
      id: widget.id ?? '',
      name: _nameCtrl.text.trim(),
      isActive: _isActive,
      // FIX: Tên class đúng là AiConfig, không phải AiConfigEntity
      aiConfig: AiConfig(
        language: _language,
        taskTypes: _selectedTaskTypes,
        defaultTaskType: _defaultTaskType,
        level: _level,
        targetWordCount: _wordCountCtrl.text.trim(),
        generationTemplate: _templateCtrl.text.trim().isEmpty ? null : _templateCtrl.text.trim(),
      ),
    );

    context.read<AdminWritingBloc>().add(SaveWritingTopicEvent(newTopic));
  }

  @override
  Widget build(BuildContext context) {
    const kBgPage = Color(0xFFF9FAFB);
    const kWhite = Colors.white;
    const kTextMain = Color(0xFF09090B);
    const kBorder = Color(0xFFE4E4E7);

    return BlocListener<AdminWritingBloc, AdminWritingState>(
      listener: (context, state) {
        if (state.status == AdminWritingStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage ?? "Error"), backgroundColor: Colors.red));
        }
        if (state.status == AdminWritingStatus.success && state.selectedTopic != null && widget.id != null) {
          if (state.selectedTopic!.id == widget.id) {
            _populateData(state.selectedTopic!);
            context.read<AdminWritingBloc>().add(ClearSelectedWritingTopicEvent());
          }
        }
        if (state.status == AdminWritingStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lưu thành công!"), backgroundColor: Colors.green));
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: kBgPage,
        appBar: AppBar(
          backgroundColor: kWhite,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextMain), onPressed: () => context.pop()),
          title: Text(widget.id == null ? 'New Writing Topic' : 'Edit Writing Topic',
              style: const TextStyle(color: kTextMain, fontWeight: FontWeight.w700, fontSize: 16)),
          bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: kBorder, height: 1)),
          actions: [
            TextButton(
              onPressed: _onSubmit,
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            )
          ],
        ),
        body: BlocBuilder<AdminWritingBloc, AdminWritingState>(
          builder: (context, state) {
            if (state.status == AdminWritingStatus.loading && widget.id != null && _nameCtrl.text.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // --- 1. BASIC INFO ---
                  ShadcnCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // FIX: Xóa const vì SectionHeader có thể không phải const
                        SectionHeader(title: "Basic Information"),
                        ShadcnInput(label: "Topic Name", controller: _nameCtrl, hint: "E.g. Technology & Society"),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Is Active?", style: TextStyle(fontWeight: FontWeight.w600)),
                            Switch(value: _isActive, onChanged: (v) => setState(() => _isActive = v)),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- 2. AI CONFIGURATION ---
                  ShadcnCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // FIX: Xóa const
                        SectionHeader(title: "AI Configuration (Prompting)"),

                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                label: "Level",
                                value: _level,
                                items: kLevels,
                                onChanged: (v) => setState(() => _level = v!),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ShadcnInput(label: "Target Word Count", controller: _wordCountCtrl),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        const Text("Supported Task Types", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextMain)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: kAllTaskTypes.map((type) {
                            final isSelected = _selectedTaskTypes.contains(type);
                            return FilterChip(
                              label: Text(type),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedTaskTypes.add(type);
                                  } else {
                                    if (_selectedTaskTypes.length > 1) {
                                      _selectedTaskTypes.remove(type);
                                    }
                                  }
                                  if (!_selectedTaskTypes.contains(_defaultTaskType) && _selectedTaskTypes.isNotEmpty) {
                                    _defaultTaskType = _selectedTaskTypes.first;
                                  }
                                });
                              },
                              backgroundColor: Colors.white,
                              selectedColor: Colors.blue.shade100,
                              checkmarkColor: Colors.blue.shade700,
                              side: BorderSide(color: isSelected ? Colors.blue : kBorder),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        _buildDropdown(
                          label: "Default Task Type (Khi user bấm vào)",
                          value: _defaultTaskType,
                          items: _selectedTaskTypes,
                          onChanged: (v) {
                            if (v != null) setState(() => _defaultTaskType = v);
                          },
                        ),
                        const SizedBox(height: 16),

                        ShadcnInput(
                            label: "Custom Prompt Template (Optional)",
                            controller: _templateCtrl,
                            maxLines: 3,
                            hint: "Ghi đè prompt mặc định của hệ thống..."
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDropdown({required String label, required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF09090B))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE4E4E7)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : null,
              isExpanded: true,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}