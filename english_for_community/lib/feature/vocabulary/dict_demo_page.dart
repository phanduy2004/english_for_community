import 'dart:async';
import 'package:flutter/material.dart';
import 'package:english_for_community/core/theme/app_motion.dart';
import 'package:go_router/go_router.dart';
import '../../core/get_it/get_it.dart';
import '../../core/repository/dictionary_repository.dart';
import '../../core/repository/user_vocab_repository.dart';
import '../../core/router/app_router.dart';
import '../../core/sqflite/dict_db.dart';
import '../../core/locale/l10n_context.dart';
import '../../core/theme/app_color.dart';
import '../../core/theme/app_skill_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/ui/student_mobile_ui.dart';

class DictDemoPage extends StatefulWidget {
  final bool isGuest;
  const DictDemoPage({super.key, this.isGuest = false});

  @override
  State<DictDemoPage> createState() => _DictDemoPageState();
}

class _DictDemoPageState extends State<DictDemoPage> {
  final _controller = TextEditingController();
  List<Entry> _results = [];
  bool _isLoading = false;
  String _error = '';
  Timer? _debouncer;

  late final DictionaryRepository _dictionaryRepository;
  late final UserVocabRepository _userVocabRepository;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
    _dictionaryRepository = getIt<DictionaryRepository>();
    if (!widget.isGuest) {
      _userVocabRepository = getIt<UserVocabRepository>();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    _debouncer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debouncer?.isActive ?? false) _debouncer!.cancel();
    _debouncer = Timer(AppMotion.base, () {
      _search(_controller.text);
    });
  }

  Future<void> _search(String query) async {
    if (!mounted) return;
    if (query.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _results = [];
        _error = '';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final result = await _dictionaryRepository.searchWord(query);
    if (mounted) {
      result.fold(
        (failure) => setState(() {
          _isLoading = false;
          _error = failure.message;
        }),
        (entries) => setState(() {
          _isLoading = false;
          _results = entries;
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final title = widget.isGuest ? t.dictQuickSearchTitle : t.dictDictionaryTitle;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: StudentMobileUi.skillAppBar(context, title: title, skill: SkillType.vocabulary),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              StudentMobileUi.pageHPadding,
              0,
              StudentMobileUi.pageHPadding,
              AppSpacing.s4,
            ),
            child: StudentMobileUi.searchField(
              controller: _controller,
              hintText: t.dictSearchHint,
              showClear: _controller.text.isNotEmpty,
              onClear: () {
                _controller.clear();
                _search('');
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.s4),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final t = context.l10n;
    if (_error.isNotEmpty) {
      return Center(child: Text(_error, style: StudentMobileUi.body(context).copyWith(color: AppColors.danger)));
    }
    if (_controller.text.trim().isEmpty) {
      return StudentMobileUi.emptyState(
        context,
        icon: Icons.manage_search_rounded,
        title: t.dictStartTyping,
        body: '',
        skill: SkillType.vocabulary,
      );
    }
    if (!_isLoading && _results.isEmpty) {
      return StudentMobileUi.emptyState(
        context,
        icon: Icons.search_off_rounded,
        title: t.dictNoResults,
        body: '',
        skill: SkillType.vocabulary,
      );
    }

    return ListView.separated(
      padding: StudentMobileUi.pagePadding.copyWith(top: 0),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: StudentMobileUi.cardGap),
      itemBuilder: (context, index) {
        final entry = _results[index];
        return _ResultCard(
          entry: entry,
          onTap: () => _handleEntryTap(entry),
          noDefinition: context.l10n.dictNoDefinitionAvailable,
        );
      },
    );
  }

  void _handleEntryTap(Entry entry) {
    FocusScope.of(context).unfocus();
    if (!widget.isGuest) {
      _userVocabRepository.logRecentWord(entry).ignore();
    }
    context.pushNamed(
      kDictDetailRouteName,
      extra: {'entry': entry, 'isGuest': widget.isGuest},
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Entry entry;
  final VoidCallback onTap;
  final String noDefinition;

  const _ResultCard({
    required this.entry,
    required this.onTap,
    required this.noDefinition,
  });

  @override
  Widget build(BuildContext context) {
    final firstDef = entry.senses.isNotEmpty ? entry.senses.first.def : noDefinition;

    return StudentMobileUi.skillAccentCard(
      skill: SkillType.vocabulary,
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.headword, style: StudentMobileUi.cardTitle(context)),
                if (entry.ipa != null && entry.ipa!.isNotEmpty)
                  Text(
                    '/${entry.ipa}/',
                    style: StudentMobileUi.caption(context),
                  ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  firstDef,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StudentMobileUi.body(context),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppSkillColors.vocabulary.color,
          ),
        ],
      ),
    );
  }
}