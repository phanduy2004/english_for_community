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
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final result = await _dictionaryRepository.searchWord(query);

    result.fold(
          (failure) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = failure.message;
          });
        }
      },
          (entries) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _results = entries;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgPage = Color(0xFFF9FAFB);
    const borderCol = Color(0xFFE4E4E7);
    const textMain = Color(0xFF09090B);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: bgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textMain),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Dictionary Lookup',
          style: TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 16),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: borderCol)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: _buildSearchBox(primaryColor),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildSearchBox(Color primaryColor) {
    const borderCol = Color(0xFFE4E4E7);
    const textMuted = Color(0xFF71717A);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        autofocus: true,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Type a word...',
          hintStyle: const TextStyle(color: textMuted, fontSize: 15),
          prefixIcon: const Icon(Icons.search, size: 20, color: textMuted),
          suffixIcon: _isLoading
              ? const Padding(
            padding: EdgeInsets.all(12.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
              : (_controller.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, size: 18, color: textMuted),
            onPressed: () {
              _controller.clear();
              _search('');
            },
          )
              : null),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          isDense: true,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    const textMuted = Color(0xFF71717A);

    if (_error.isNotEmpty) {
      return _ErrorView(message: _error);
    }
    if (_controller.text.trim().isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 48, color: textMuted),
            SizedBox(height: 12),
            Text('Start typing to search', style: TextStyle(color: textMuted, fontSize: 14)),
          ],
        ),
      );
    }
    if (!_isLoading && _results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: textMuted),
            SizedBox(height: 12),
            Text('No results found', style: TextStyle(color: textMuted, fontSize: 14)),
          ],
        ),
      );
    }
    if (_isLoading && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = _results[index];
        return _ResultCard(
          entry: entry,
          onTap: () => _handleEntryTap(entry),
        );
      },
    );
  }

  void _handleEntryTap(Entry entry) {
    FocusScope.of(context).unfocus();
    try {
      _userVocabRepository.logRecentWord(entry);
    } catch (e) {
      debugPrint('Log recent failed: $e');
    }
    context.pushNamed(kDictDetailRouteName, extra: entry);
  }
}

class _ResultCard extends StatelessWidget {
  final Entry entry;
  final VoidCallback onTap;

  const _ResultCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const borderCol = Color(0xFFE4E4E7);
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);

    final firstDef = entry.senses.isNotEmpty ? entry.senses.first.def : 'No definition available';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
                      // 1. Từ vựng (Headword)
                      Text(
                        entry.headword,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: textMain,
                        ),
                      ),

                      // 2. Phiên âm (IPA) - Xuống dòng nằm dưới
                      if (entry.ipa != null && entry.ipa!.isNotEmpty) ...[
                        const SizedBox(height: 2), // Khoảng cách nhỏ giữa từ và phiên âm
                        Text(
                          '/${entry.ipa}/',
                          style: const TextStyle(
                            fontSize: 13,
                            color: textMuted,
                            fontFamily: 'NotoSans',
                            fontStyle: FontStyle.italic, // (Tuỳ chọn) In nghiêng cho đẹp
                          ),
                        ),
                      ],

                      // 3. Định nghĩa (Definition)
                      const SizedBox(height: 6), // Khoảng cách tách biệt với phần định nghĩa
                      Text(
                        firstDef,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF52525B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.chevron_right, color: Color(0xFFA1A1AA), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Color(0xFFEF4444)),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Color(0xFF71717A))),
        ],
      ),
    );
  }
}