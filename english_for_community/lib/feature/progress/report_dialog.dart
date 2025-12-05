import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';

// 🔥 Import các file Bloc/Event/State/GetIt
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

  // Quản lý danh sách ảnh
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  // Map hiển thị tiếng Việt
  final Map<String, String> _reportTypes = {
    'bug': 'Báo lỗi (Bug)',
    'feature': 'Đề xuất tính năng',
    'improvement': 'Cải thiện trải nghiệm',
    'other': 'Khác'
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // Chọn ảnh từ thư viện
  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 70);
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  // Xóa ảnh đã chọn
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // 🔥 Hàm Submit dùng Bloc
  Future<void> _submit(BuildContext context) async {
    // 1. Validate
    if (_titleController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề và mô tả')),
      );
      return;
    }

    // 2. Lấy thông tin thiết bị (Device Info)
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

    // 3. Gửi Event sang Bloc
    context.read<ReportBloc>().add(SendReportEvent(
      title: _titleController.text,
      description: _descController.text,
      type: _selectedType,
      images: _selectedImages.map((e) => e.path).toList(),
      deviceData: deviceData,
    ));
  }

  @override
  Widget build(BuildContext context) {
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);

    // 🔥 Bọc trong BlocProvider để cấp phát Bloc mới cho Dialog này
    return BlocProvider(
      create: (_) => getIt<ReportBloc>(),
      child: BlocConsumer<ReportBloc, ReportState>(
        listener: (context, state) {
          if (state.status == ReportStatus.success) {
            Navigator.of(context).pop(); // Đóng form nhập
            _showSuccessDialog(context); // Hiện thông báo thành công
          }
          if (state.status == ReportStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Gửi thất bại'), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state.status == ReportStatus.loading;

          return Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            insetPadding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Góp ý & Báo lỗi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textMain)),
                              SizedBox(height: 4),
                              Text('Giúp chúng tôi cải thiện ứng dụng.', style: TextStyle(fontSize: 13, color: textMuted)),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: textMuted, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Loại báo cáo
                      const _Label('Loại phản hồi'),
                      _ShadcnDropdown(
                        value: _selectedType,
                        items: _reportTypes,
                        onChanged: (val) => setState(() => _selectedType = val!),
                      ),
                      const SizedBox(height: 16),

                      // Tiêu đề
                      const _Label('Tiêu đề'),
                      _ShadcnInput(
                        controller: _titleController,
                        hint: 'Tóm tắt vấn đề...',
                      ),
                      const SizedBox(height: 16),

                      // Mô tả
                      const _Label('Mô tả chi tiết'),
                      _ShadcnInput(
                        controller: _descController,
                        hint: 'Mô tả chi tiết lỗi hoặc ý tưởng của bạn...',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),

                      // Chọn ảnh
                      const _Label('Ảnh đính kèm (Tùy chọn)'),
                      _buildImagePicker(),

                      const SizedBox(height: 24),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Hủy', style: TextStyle(color: textMain)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: isLoading ? null : () => _submit(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: isLoading
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Gửi báo cáo', style: TextStyle(fontWeight: FontWeight.w600)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Column(children: [
          Icon(Icons.check_circle, color: Colors.green, size: 48),
          SizedBox(height: 12),
          Text("Đã gửi báo cáo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        content: const Text("Cảm ơn đóng góp của bạn!", textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Đóng"),
          )
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImages.isNotEmpty)
          Container(
            height: 80,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_selectedImages[index].path),
                        width: 80, height: 80, fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 2, right: 2,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
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
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE4E4E7), style: BorderStyle.solid),
            ),
            child: const Column(
              children: [
                Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF71717A)),
                SizedBox(height: 4),
                Text("Thêm ảnh minh họa", style: TextStyle(fontSize: 12, color: Color(0xFF71717A))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- Các Widget Shadcn (Input, Label, Dropdown) ---

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF09090B))),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, color: Color(0xFF09090B)),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF71717A), fontSize: 14),
          border: InputBorder.none,
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
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF71717A)),
          style: const TextStyle(fontSize: 14, color: Color(0xFF09090B)),
          items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}