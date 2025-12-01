import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'content_widgets.dart';

class WritingEditorPage extends StatefulWidget {
  final String? id;
  const WritingEditorPage({super.key, this.id});

  @override
  State<WritingEditorPage> createState() => _WritingEditorPageState();
}

class _WritingEditorPageState extends State<WritingEditorPage> {
  bool _isEditing = false;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _iconCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.id == null) {
      _isEditing = true;
    } else {
      // Mock data load
      _nameCtrl.text = "Technology";
      _slugCtrl.text = "technology";
      _iconCtrl.text = "memory";
      _colorCtrl.text = "#2E86C1";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPage,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: kTextMain),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.id == null ? 'New Writing Topic' : 'Edit Topic',
            style: const TextStyle(color: kTextMain, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () => setState(() => _isEditing = !_isEditing),
            child: Text(_isEditing ? 'Save' : 'Edit', style: const TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: kBorder, height: 1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ShadcnCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: "Topic Information"),
                  ShadcnInput(label: "Topic Name", hint: "e.g. Technology", controller: _nameCtrl, isReadOnly: !_isEditing),
                  const SizedBox(height: 12),
                  ShadcnInput(label: "Slug (URL Friendly)", hint: "e.g. technology", controller: _slugCtrl, isReadOnly: !_isEditing),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ShadcnInput(
                          label: "Icon Key (Material)",
                          hint: "memory",
                          controller: _iconCtrl,
                          isReadOnly: !_isEditing,
                          suffixIcon: const Icon(Icons.memory, color: kTextMuted), // Demo icon preview
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ShadcnInput(
                          label: "Color (Hex)",
                          hint: "#RRGGBB",
                          controller: _colorCtrl,
                          isReadOnly: !_isEditing,
                          suffixIcon: Container(
                            margin: const EdgeInsets.all(10),
                            width: 20, height: 20,
                            decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)), // Demo color
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ShadcnCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: "AI Configuration"),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Task Types: Opinion, Discussion, Problem-Solution", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        SizedBox(height: 4),
                        Text("Target Word Count: 250-320", style: TextStyle(fontSize: 13, color: kTextMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}