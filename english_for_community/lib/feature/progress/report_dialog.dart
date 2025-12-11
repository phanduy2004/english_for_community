import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';

// 🔥 Import your project specific files
import '../../../core/get_it/get_it.dart';
import 'bloc_report/report_bloc.dart';
import 'bloc_report/report_event.dart';
import 'bloc_report/report_state.dart';

class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedType = 'bug';

  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  // English Mapping
  final Map<String, String> _reportTypes = {
    'bug': 'Bug Report',
    'feature': 'Feature Request',
    'improvement': 'Improvement',
    'other': 'Other'
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 70);
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submit(BuildContext context) async {
    // 1. Validation
    if (_titleController.text.trim().isEmpty || _descController.text.trim().isEmpty) {
      _showToast(context, 'Please enter a title and description.', isError: true);
      return;
    }

    // 2. Device Info
    final deviceInfoPlugin = DeviceInfoPlugin();
    Map<String, dynamic> deviceData = {};

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceData = {
          'platform': 'Android',
          'device': '${androidInfo.brand} ${androidInfo.model}',
          'version': androidInfo.version.release,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceData = {
          'platform': 'iOS',
          'device': iosInfo.name,
          'version': iosInfo.systemVersion,
        };
      }
    } catch (_) {
      deviceData = {'platform': 'Unknown', 'device': 'Unknown', 'version': ''};
    }

    // 3. Send Event
    context.read<ReportBloc>().add(SendReportEvent(
      title: _titleController.text,
      description: _descController.text,
      type: _selectedType,
      images: _selectedImages.map((e) => e.path).toList(),
      deviceData: deviceData,
    ));
  }

  void _showToast(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Shadcn Colors
    const textMain = Color(0xFF09090B); // Zinc 950
    const textMuted = Color(0xFF71717A); // Zinc 500

    return BlocProvider(
      create: (_) => getIt<ReportBloc>(),
      child: BlocConsumer<ReportBloc, ReportState>(
        listener: (context, state) {
          if (state.status == ReportStatus.success) {
            Navigator.of(context).pop();
            _showSuccessDialog(context);
          }
          if (state.status == ReportStatus.error) {
            _showToast(context, state.errorMessage ?? 'Submission failed', isError: true);
          }
        },
        builder: (context, state) {
          final isLoading = state.status == ReportStatus.loading;

          return Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Header ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Feedback & Support',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textMain, letterSpacing: -0.5)
                                ),
                                SizedBox(height: 6),
                                Text('Let us know about an issue or suggestion.',
                                    style: TextStyle(fontSize: 14, color: textMuted)
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.close, color: textMuted, size: 22),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- Form Fields ---
                      const _ShadcnLabel('Report Type'),
                      _ShadcnDropdown(
                        value: _selectedType,
                        items: _reportTypes,
                        onChanged: (val) => setState(() => _selectedType = val!),
                      ),
                      const SizedBox(height: 16),

                      const _ShadcnLabel('Title'),
                      _ShadcnInput(
                        controller: _titleController,
                        hint: 'Brief summary of the issue',
                      ),
                      const SizedBox(height: 16),

                      const _ShadcnLabel('Description'),
                      _ShadcnInput(
                        controller: _descController,
                        hint: 'Please describe the details...',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),

                      const _ShadcnLabel('Attachments (Optional)'),
                      _buildImagePicker(),

                      const SizedBox(height: 28),

                      // --- Actions ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Cancel Button (Outline)
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: textMain,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: Color(0xFFE4E4E7)),
                              ),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 12),

                          // Submit Button (Primary Black)
                          ElevatedButton(
                            onPressed: isLoading ? null : () => _submit(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: textMain, // Black background
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: isLoading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Submit Report', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle), // Green-100
              child: const Icon(Icons.check, color: Color(0xFF15803D), size: 32), // Green-700
            ),
            const SizedBox(height: 16),
            const Text("Thank you!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 8),
            const Text("We have received your report and will look into it shortly.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF71717A))
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImages.isNotEmpty)
          Container(
            height: 72,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE4E4E7)),
                          image: DecorationImage(
                            image: FileImage(File(_selectedImages[index].path)),
                            fit: BoxFit.cover,
                          )
                      ),
                    ),
                    Positioned(
                      top: -6, right: -6,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE4E4E7)),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)]
                          ),
                          child: const Icon(Icons.close, size: 12, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        InkWell(
          onTap: _pickImages,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA), // Zinc 50
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE4E4E7), style: BorderStyle.solid), // Dashed look simulated with solid light gray
            ),
            child: const Column(
              children: [
                Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF71717A), size: 24),
                SizedBox(height: 6),
                Text("Click to upload screenshots", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF09090B))),
                Text("Supported formats: JPEG, PNG", style: TextStyle(fontSize: 11, color: Color(0xFF71717A))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// SHADCN UI COMPONENTS (Reusable)
// -----------------------------------------------------------------------------

class _ShadcnLabel extends StatelessWidget {
  final String text;
  const _ShadcnLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF09090B))
      ),
    );
  }
}

class _ShadcnInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  const _ShadcnInput({required this.controller, required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: Color(0xFF09090B)),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 14), // Zinc 400
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE4E4E7)), // Zinc 200
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF18181B), width: 1.5), // Zinc 900
        ),
      ),
    );
  }
}

class _ShadcnDropdown extends StatelessWidget {
  final String value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;
  const _ShadcnDropdown({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.unfold_more, size: 18, color: Color(0xFF71717A)),
          style: const TextStyle(fontSize: 14, color: Color(0xFF09090B), fontWeight: FontWeight.w400),
          borderRadius: BorderRadius.circular(8),
          items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}