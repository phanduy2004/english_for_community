import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/theme/app_typography.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/ui/widget/app_corner_toast.dart';
import 'package:english_for_community/feature/progress/bloc_report/report_bloc.dart';
import 'package:english_for_community/feature/progress/bloc_report/report_event.dart';
import 'package:english_for_community/feature/progress/bloc_report/report_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

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

  Map<String, String> _reportTypesFor(BuildContext context) {
    final t = context.l10n;
    return {
      'bug': t.reportTypeBug,
      'feature': t.reportTypeFeature,
      'improvement': t.reportTypeImprovement,
      'other': t.reportTypeOther,
    };
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 70);
    if (images.isNotEmpty) {
      setState(() => _selectedImages.addAll(images));
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _submit(BuildContext context) async {
    if (_titleController.text.trim().isEmpty || _descController.text.trim().isEmpty) {
      _showToast(context, context.l10n.reportFillTitleDescription, isError: true);
      return;
    }

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

    context.read<ReportBloc>().add(SendReportEvent(
          title: _titleController.text,
          description: _descController.text,
          type: _selectedType,
          images: _selectedImages.map((e) => e.path).toList(),
          deviceData: deviceData,
        ));
  }

  void _showToast(BuildContext context, String message, {bool isError = false}) {
    AppCornerToast.show(context, message, error: isError);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReportBloc>(),
      child: BlocConsumer<ReportBloc, ReportState>(
        listener: (context, state) {
          if (state.status == ReportStatus.success) {
            Navigator.of(context).pop();
            _showSuccessDialog(context);
          }
          if (state.status == ReportStatus.error) {
            _showToast(
              context,
              state.errorMessage ?? context.l10n.reportSubmissionFailed,
              isError: true,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state.status == ReportStatus.loading;
          final t = context.l10n;
          final reportTypes = _reportTypesFor(context);

          return StudentDialogShell(
            title: t.reportDialogTitle,
            subtitle: t.reportDialogSubtitle,
            maxWidth: 480,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(t.cancel),
              ),
              FilledButton(
                onPressed: isLoading ? null : () => _submit(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: AppLoadingIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                      )
                    : Text(t.submitReport),
              ),
            ],
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FormLabel(t.reportTypeLabel),
                  _ReportDropdown(
                    value: _selectedType,
                    items: reportTypes,
                    onChanged: (val) => setState(() => _selectedType = val!),
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  _FormLabel(t.reportTitleLabel),
                  _ReportInput(controller: _titleController, hint: t.reportTitleHint),
                  const SizedBox(height: AppSpacing.s5),
                  _FormLabel(t.reportDescriptionLabel),
                  _ReportInput(controller: _descController, hint: t.reportDescriptionHint, maxLines: 4),
                  const SizedBox(height: AppSpacing.s5),
                  _FormLabel(t.reportAttachmentsOptional),
                  _buildImagePicker(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    final t = context.l10n;
    showDialog(
      context: context,
      builder: (_) => StudentDialogShell(
        title: t.reportThankYou,
        subtitle: t.reportReceivedBody,
        maxWidth: 360,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: Text(t.close),
          ),
        ],
        child: Center(
          child: StudentMobileUi.skillIconBox(Icons.check_rounded, size: 56),
        ),
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    final t = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImages.isNotEmpty)
          Container(
            height: 72,
            margin: const EdgeInsets.only(bottom: AppSpacing.s4),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s4),
              itemBuilder: (context, index) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.input),
                        border: Border.all(color: AppColors.outline),
                        image: DecorationImage(
                          image: FileImage(File(_selectedImages[index].path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: const Icon(Icons.close, size: 12, color: AppColors.textPrimary),
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
          borderRadius: BorderRadius.circular(AppRadius.input),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s5),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              children: [
                const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textMuted, size: 24),
                const SizedBox(height: AppSpacing.s3),
                Text(t.reportUploadScreenshots, style: AppTypography.label()),
                Text(t.reportSupportedFormats, style: StudentMobileUi.caption(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: Text(text, style: AppTypography.label()),
    );
  }
}

class _ReportInput extends StatelessWidget {
  const _ReportInput({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: AppTypography.body(),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surfaceCard,
        hintText: hint,
        hintStyle: AppTypography.body(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s4),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _ReportDropdown extends StatelessWidget {
  const _ReportDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: AppColors.outline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.unfold_more, size: 18, color: AppColors.textMuted),
          style: AppTypography.body(),
          borderRadius: BorderRadius.circular(AppRadius.input),
          items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
