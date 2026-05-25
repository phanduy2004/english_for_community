import 'package:english_for_community/core/get_it/get_it.dart';
import 'package:english_for_community/core/locale/l10n_context.dart';
import 'package:english_for_community/core/repository/teacher_exam_repository.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:english_for_community/core/theme/app_spacing.dart';
import 'package:english_for_community/core/ui/student_mobile_ui.dart';
import 'package:english_for_community/core/ui/widget/app_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Join a [public_link] exam using the opaque token (logged-in students only).
class PublicExamJoinPage extends StatefulWidget {
  const PublicExamJoinPage({super.key});

  static const String routePath = '/student/exams/join';
  static const String routeName = 'PublicExamJoinPage';

  @override
  State<PublicExamJoinPage> createState() => _PublicExamJoinPageState();
}

class _PublicExamJoinPageState extends State<PublicExamJoinPage> {
  final _tokenCtrl = TextEditingController();
  Map<String, dynamic>? _preview;
  bool _busy = false;

  String? _modeLabelFromPreview() {
    if (_preview == null) return null;
    final mode = _preview!['mode'] as String?;
    final l10n = context.l10n;
    switch (mode) {
      case 'scheduled':
        return l10n.examModeScheduled;
      case 'realtime':
        return l10n.examModeRealtime;
      default:
        return l10n.examModeSelfPaced;
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    final t = _tokenCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() => _busy = true);
    final r = await getIt<TeacherExamRepository>().previewPublicExam(t);
    if (!mounted) return;
    setState(() => _busy = false);
    r.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
      (d) => setState(() => _preview = Map<String, dynamic>.from(d as Map)),
    );
  }

  Future<void> _start() async {
    final t = _tokenCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() => _busy = true);
    final r = await getIt<TeacherExamRepository>().startPublicExamAttempt(t);
    if (!mounted) return;
    setState(() => _busy = false);
    await r.fold(
      (f) async => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
      (attempt) async {
        final map = Map<String, dynamic>.from(attempt as Map);
        final attemptId = map['id'] as String? ?? '';
        if (!context.mounted || attemptId.isEmpty) return;
        await context.push('/student/exam-run/$attemptId');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: StudentMobileUi.appBar(context, title: l10n.examJoinByLinkTitle),
      body: ListView(
        padding: StudentMobileUi.pagePadding,
        children: [
          TextField(
            controller: _tokenCtrl,
            style: StudentMobileUi.body(context),
            decoration: InputDecoration(
              labelText: l10n.examJoinByLinkHint,
              filled: true,
              fillColor: AppColors.surfaceSubtle,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.s5),
          Wrap(
            spacing: AppSpacing.s4,
            runSpacing: AppSpacing.s4,
            children: [
              OutlinedButton(onPressed: _busy ? null : _loadPreview, child: Text(l10n.examJoinPreview)),
              FilledButton(
                onPressed: _busy ? null : _start,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: Text(l10n.examJoinStart),
              ),
            ],
          ),
          if (_preview != null) ...[
            const SizedBox(height: StudentMobileUi.sectionGap),
            AppCard(
              variant: AppCardVariant.outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _preview!['examTitle'] as String? ?? '',
                    style: StudentMobileUi.cardTitle(context),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  Text(
                    _modeLabelFromPreview() ?? '',
                    style: StudentMobileUi.body(context),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
