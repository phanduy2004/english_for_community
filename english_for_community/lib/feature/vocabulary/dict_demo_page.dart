import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/get_it/get_it.dart';
import '../../core/repository/dictionary_repository.dart';
import '../../core/repository/user_vocab_repository.dart';
import '../../core/router/app_router.dart';
import '../../core/sqflite/dict_db.dart';

class DictDemoPage extends StatefulWidget {
  const DictDemoPage({super.key});

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
    _userVocabRepository = getIt<UserVocabRepository>();
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
        title: const Text('Dictionary Lookup', style: TextStyle(color: textMain, fontWeight: FontWeight.w700, fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE4E4E7)))),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildSearchInput(),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: _controller,
        autofocus: true,
        style: const TextStyle(fontSize: 16, color: Color(0xFF09090B)),
        decoration: InputDecoration(
          hintText: 'Type a word (e.g., hello)...',
          hintStyle: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 15),
          prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF71717A)),
          suffixIcon: _isLoading
              ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              : (_controller.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.close, size: 18, color: Color(0xFF71717A)), onPressed: () { _controller.clear(); _search(''); })
              : null),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          // Khi focus, viền sẽ đậm hơn (giả lập Shadcn Input)
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF18181B), width: 1.5), // Zinc 900
          ),
          enabledBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error.isNotEmpty) return Center(child: Text(_error, style: const TextStyle(color: Colors.red)));
    if (_controller.text.trim().isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.manage_search_rounded, size: 48, color: Color(0xFFE4E4E7)),
        SizedBox(height: 12),
        Text('Start typing to search', style: TextStyle(color: Color(0xFF71717A))),
      ]));
    }
    if (!_isLoading && _results.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.search_off_rounded, size: 48, color: Color(0xFFE4E4E7)),
        SizedBox(height: 12),
        Text('No results found', style: TextStyle(color: Color(0xFF71717A))),
      ]));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = _results[index];
        return _ResultCard(entry: entry, onTap: () => _handleEntryTap(entry));
      },
    );
  }

  void _handleEntryTap(Entry entry) {
    FocusScope.of(context).unfocus();
    _userVocabRepository.logRecentWord(entry).ignore(); // Fire & Forget
    context.pushNamed(kDictDetailRouteName, extra: entry);
  }
}

class _ResultCard extends StatelessWidget {
  final Entry entry;
  final VoidCallback onTap;
  const _ResultCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final firstDef = entry.senses.isNotEmpty ? entry.senses.first.def : 'No definition available';
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
                      Row(
                        children: [
                          Text(entry.headword, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF09090B))),
                          if (entry.ipa != null && entry.ipa!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text('/${entry.ipa}/', style: const TextStyle(fontSize: 13, color: Color(0xFF71717A), fontFamily: 'NotoSans', fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(firstDef, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: Color(0xFF52525B))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFA1A1AA), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}