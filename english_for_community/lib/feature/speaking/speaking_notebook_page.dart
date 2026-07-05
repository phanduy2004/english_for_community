import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/entity/speaking_phase2_entity.dart';
import '../../core/get_it/get_it.dart';
import '../../core/locale/l10n_context.dart';
import '../../core/repository/user_vocab_repository.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_color.dart';
import '../../core/theme/app_skill_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/ui/feedback/app_feedback.dart';
import '../../core/ui/student_mobile_ui.dart';
import '../../core/ui/widget/app_card.dart';
import 'speaking_phase2_bloc/speaking_phase2_bloc.dart';
import 'speaking_phase2_bloc/speaking_phase2_event.dart';
import 'speaking_phase2_bloc/speaking_phase2_state.dart';

class SpeakingNotebookPage extends StatelessWidget {
  static const routeName = 'SpeakingNotebookPage';
  static const routePath = '/speaking-notebook';

  const SpeakingNotebookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<SpeakingPhase2Bloc>()..add(const LoadSpeakingNotebookEvent()),
      child: const _SpeakingNotebookView(),
    );
  }
}

class _SpeakingNotebookView extends StatelessWidget {
  const _SpeakingNotebookView();

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          title: Text(t.speakingNotebookTitle,
              style: StudentMobileUi.sectionTitle(context)),
          bottom: TabBar(
            labelColor: AppSkillColors.speaking.color,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: t.speakingNotebookRepeated),
              Tab(text: t.speakingFbCorrections),
              Tab(text: t.speakingFbVocabUpgrades),
            ],
          ),
        ),
        body: BlocBuilder<SpeakingPhase2Bloc, SpeakingPhase2State>(
          buildWhen: (prev, next) =>
              prev.status != next.status || prev.notebook != next.notebook,
          builder: (context, state) {
            if (state.status == SpeakingPhase2Status.loading) {
              return Center(child: StudentMobileUi.runnerLoading());
            }
            if (state.status == SpeakingPhase2Status.error) {
              return StudentMobileUi.errorRetry(
                context,
                title: t.speakingErrorTitle,
                message: t.speakingErrorBody,
                onRetry: () => context
                    .read<SpeakingPhase2Bloc>()
                    .add(const LoadSpeakingNotebookEvent()),
                retryLabel: t.commonRetry,
              );
            }
            final notebook = state.notebook;
            if (notebook == null || notebook.conversations == 0) {
              return StudentMobileUi.emptyState(
                context,
                icon: Icons.menu_book_outlined,
                title: t.speakingNotebookEmptyTitle,
                body: t.speakingNotebookEmptyBody,
                skill: SkillType.speaking,
              );
            }
            return TabBarView(
              children: [
                _CorrectionList(items: notebook.repeatedErrors, repeated: true),
                _CorrectionList(items: notebook.corrections),
                _VocabList(items: notebook.vocab),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CorrectionList extends StatelessWidget {
  final List<SpeakingNotebookCorrectionEntity> items;
  final bool repeated;

  const _CorrectionList({required this.items, this.repeated = false});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return StudentMobileUi.emptyState(
        context,
        icon: Icons.check_circle_outline,
        title: context.l10n.speakingNotebookNoItems,
        body: '',
        skill: SkillType.speaking,
      );
    }
    return ListView.builder(
      padding: StudentMobileUi.pagePadding,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s3),
          child: AppCard(
            variant: AppCardVariant.outline,
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.type.toUpperCase(),
                          style: StudentMobileUi.cardTitle(context)),
                    ),
                    if (repeated)
                      Chip(
                        label: Text('x${item.count}'),
                        backgroundColor: AppColors.warningBg,
                        side: const BorderSide(color: AppColors.outline),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(item.before, style: StudentMobileUi.body(context)),
                const SizedBox(height: AppSpacing.s1),
                Text(item.after,
                    style: StudentMobileUi.body(context)
                        .copyWith(color: AppColors.success)),
                if (item.reason.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s2),
                  Text(item.reason,
                      style: StudentMobileUi.body(context)
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VocabList extends StatelessWidget {
  final List<SpeakingNotebookVocabEntity> items;

  const _VocabList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return StudentMobileUi.emptyState(
        context,
        icon: Icons.bookmark_outline,
        title: context.l10n.speakingNotebookNoItems,
        body: '',
        skill: SkillType.speaking,
      );
    }
    return ListView.builder(
      padding: StudentMobileUi.pagePadding,
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s3),
            child: FilledButton.icon(
              onPressed: () => context.pushNamed(kReviewSessionRouteName),
              icon: const Icon(Icons.school_outlined),
              label: Text(context.l10n.speakingNotebookReviewVocab),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s3),
          child: _VocabCard(item: items[index - 1]),
        );
      },
    );
  }
}

class _VocabCard extends StatefulWidget {
  final SpeakingNotebookVocabEntity item;

  const _VocabCard({required this.item});

  @override
  State<_VocabCard> createState() => _VocabCardState();
}

class _VocabCardState extends State<_VocabCard> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _save() async {
    if (_saving || _saved || widget.item.better.trim().isEmpty) return;
    setState(() => _saving = true);
    final result = await getIt<UserVocabRepository>().saveRawWord(
      headword: widget.item.better.trim(),
      shortDefinition:
          widget.item.note.trim().isEmpty ? null : widget.item.note,
    );
    if (!mounted) return;
    result.fold(
      (failure) => AppFeedback.error(context, failure.message),
      (_) {
        setState(() => _saved = true);
        AppFeedback.success(context, context.l10n.speakingFbSaved);
      },
    );
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.outline,
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.item.better, style: StudentMobileUi.cardTitle(context)),
          if (widget.item.said.isNotEmpty)
            Text(widget.item.said,
                style: StudentMobileUi.body(context)
                    .copyWith(color: AppColors.textSecondary)),
          if (widget.item.note.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(widget.item.note, style: StudentMobileUi.body(context)),
          ],
          const SizedBox(height: AppSpacing.s3),
          OutlinedButton.icon(
            onPressed: _saved ? null : _save,
            icon: Icon(
                _saved ? Icons.check_rounded : Icons.bookmark_add_outlined),
            label: Text(_saved
                ? context.l10n.speakingFbSaved
                : context.l10n.speakingFbSaveWord),
          ),
        ],
      ),
    );
  }
}
