import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/get_it/get_it.dart';
import '../../core/repository/dictionary_repository.dart';
import '../../core/repository/user_vocab_repository.dart';
import '../../core/router/app_router.dart';
import '../../core/sqflite/dict_db.dart';
import '../../core/locale/l10n_context.dart';

class DictDemoPage extends StatefulWidget {
  // 🔥 Thêm cờ nhận diện chế độ khách
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

    // Chỉ cần lấy user repo nếu không phải là guest (để tránh lỗi nếu repo yêu cầu auth ngay lúc init)
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
    _debouncer = Timer(const Duration(milliseconds: 300), () {
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
    setState(() { _isLoading = true; _error = ''; });

    final result = await _dictionaryRepository.searchWord(query);
    if (mounted) {
      result.fold(
            (failure) => setState(() { _isLoading = false; _error = failure.message; }),
            (entries) => setState(() { _isLoading = false; _results = entries; }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    const bgPage = Color(0xFFF9FAFB);
    const textMain = Color(0xFF09090B);

    return Scaffold(
      backgroundColor: bgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textMain),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // Hiển thị tiêu đề khác nếu là Guest
        title: Text(
            widget.isGuest ? t.dictQuickSearchTitle : t.dictDictionaryTitle,
            style: const TextStyle(color: textMain, fontWeight: FontWeight.w700, fontSize: 18)
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE4E4E7)))),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildSearchInput(context),
          ),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildSearchInput(BuildContext context) {
    final t = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E4E7), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: _controller,
        autofocus: true,
        style: const TextStyle(fontSize: 16, color: Color(0xFF09090B), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: t.dictSearchHint,
          hintStyle: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 15),
          prefixIcon: const Icon(Icons.search_rounded, size: 22, color: Color(0xFF09090B)),
          suffixIcon: _isLoading
              ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              : (_controller.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF71717A)), onPressed: () { _controller.clear(); _search(''); })
              : null),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final t = context.l10n;
    if (_error.isNotEmpty) return Center(child: Text(_error, style: const TextStyle(color: Colors.red)));
    if (_controller.text.trim().isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.manage_search_rounded, size: 48, color: Color(0xFFE4E4E7)),
        const SizedBox(height: 12),
        Text(t.dictStartTyping, style: const TextStyle(color: Color(0xFF71717A))),
      ]));
    }
    if (!_isLoading && _results.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFFE4E4E7)),
        const SizedBox(height: 12),
        Text(t.dictNoResults, style: const TextStyle(color: Color(0xFF71717A))),
      ]));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = _results[index];
        return _ResultCard(entry: entry, onTap: () => _handleEntryTap(entry), noDefinition: context.l10n.dictNoDefinitionAvailable);
      },
    );
  }

  void _handleEntryTap(Entry entry) {
    FocusScope.of(context).unfocus();

    // 🔥 Chỉ lưu history nếu KHÔNG phải là Guest
    if (!widget.isGuest) {
      _userVocabRepository.logRecentWord(entry).ignore();
    }

    // 🔥 Truyền tiếp cờ isGuest sang trang Detail
    // Lưu ý: Cần update router của bạn để nhận Map hoặc Object chứa cả entry và isGuest
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
  const _ResultCard({required this.entry, required this.onTap, required this.noDefinition});

  @override
  Widget build(BuildContext context) {
    final firstDef = entry.senses.isNotEmpty ? entry.senses.first.def : noDefinition;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: entry.headword,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF09090B), fontFamily: 'Inter'),
                            ),
                            if (entry.ipa != null && entry.ipa!.isNotEmpty)
                              TextSpan(
                                text: ' /${entry.ipa}/',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF71717A), fontFamily: 'NotoSans', fontStyle: FontStyle.italic),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(firstDef, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: Color(0xFF52525B))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Color(0xFFA1A1AA), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}