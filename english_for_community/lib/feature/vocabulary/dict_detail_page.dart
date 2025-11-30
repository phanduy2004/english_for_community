import 'package:flutter/material.dart';
import '../../core/get_it/get_it.dart';
import '../../core/repository/user_vocab_repository.dart';
import '../../core/sqflite/dict_db.dart';

class DictDetailPage extends StatelessWidget {
  final Entry entry;
  final UserVocabRepository _userVocabRepository = getIt<UserVocabRepository>();

  DictDetailPage({super.key, required this.entry});

  Widget _buildExampleRow(String text, BuildContext context) {
    const textMuted = Color(0xFF71717A);
    final primaryColor = Theme.of(context).colorScheme.primary;

    String mainText = text;
    String? translationText;

    final separators = [' : ', ' → ', '\n'];

    for (var sep in separators) {
      final parts = mainText.split(sep);
      if (parts.length > 1) {
        mainText = parts.first.trim();
        translationText = parts.sublist(1).join(sep).trim();
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(color: textMuted)),
              Expanded(
                child: Text(
                  mainText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF52525B),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          if (translationText != null && translationText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12.0, top: 4.0),
              child: Text(
                translationText,
                style: TextStyle(
                  fontSize: 14,
                  color: primaryColor,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgPage = Color(0xFFF9FAFB);
    const borderCol = Color(0xFFE4E4E7);
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);
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
        title: Text(
          entry.headword,
          style: const TextStyle(color: textMain, fontWeight: FontWeight.w600, fontSize: 16),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderCol, height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: textMain),
            tooltip: 'Save word',
            onPressed: () async {
              final result = await _userVocabRepository.saveWord(entry);
              if (context.mounted) {
                result.fold(
                      (failure) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${failure.message}'), backgroundColor: Colors.red),
                  ),
                      (_) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saved "${entry.headword}"'), duration: const Duration(seconds: 2)),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.school_outlined, color: textMain),
            tooltip: 'Start learning',
            onPressed: () async {
              final result = await _userVocabRepository.startLearningWord(entry);
              if (context.mounted) {
                result.fold(
                      (failure) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${failure.message}'), backgroundColor: Colors.red),
                  ),
                      (_) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added "${entry.headword}" to learning queue'), duration: const Duration(seconds: 2)),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADWORD & IPA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.headword,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: textMain,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (entry.ipa != null && entry.ipa!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '/${entry.ipa}/',
                            style: const TextStyle(
                              fontSize: 18,
                              color: textMuted,
                              fontFamily: 'NotoSans',
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  // Optional: Play button placeholder if you have audio
                  // Container(...)
                ],
              ),

              const SizedBox(height: 16),

              // 2. TAGS & POS
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  if (entry.pos != null && entry.pos!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: primaryColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        entry.pos!,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primaryColor),
                      ),
                    ),
                  ...entry.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderCol),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textMuted),
                    ),
                  )),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(height: 1, color: borderCol),
              const SizedBox(height: 24),

              // 3. DEFINITIONS & EXAMPLES
              if (entry.senses.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entry.senses.asMap().entries.map((mapEntry) {
                    final index = mapEntry.key;
                    final sense = mapEntry.value;

                    String mainDef = sense.def;
                    String? exampleInDef;

                    const String posSep = ' ■ ';
                    int posSepIndex = mainDef.indexOf(posSep);
                    if (posSepIndex != -1) {
                      mainDef = mainDef.substring(posSepIndex + posSep.length).trim();
                    } else {
                      const String defSep = ' • ';
                      int defSepIndex = mainDef.indexOf(defSep);
                      if (defSepIndex != -1) {
                        exampleInDef = mainDef.substring(defSepIndex + defSep.length).trim();
                        mainDef = mainDef.substring(0, defSepIndex).trim();
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${index + 1}. ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textMuted)),
                              Expanded(
                                child: Text(
                                  mainDef,
                                  style: const TextStyle(fontSize: 16, height: 1.5, color: textMain),
                                ),
                              ),
                            ],
                          ),
                          if (exampleInDef != null || sense.examples.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 24.0, top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (exampleInDef != null) _buildExampleRow(exampleInDef, context),
                                  ...sense.examples.map((ex) => _buildExampleRow(ex, context)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              // 4. SEE ALSO
              if (entry.seeAlso.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('See also', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: entry.seeAlso.map((see) =>
                      GestureDetector(
                        // Add navigation logic here if needed
                        child: Text(
                          see,
                          style: TextStyle(
                            fontSize: 14,
                            color: primaryColor,
                            decoration: TextDecoration.underline,
                            decorationColor: primaryColor.withOpacity(0.5),
                          ),
                        ),
                      )
                  ).toList(),
                ),
              ],

              // 5. SOURCE
              if (entry.source != null && entry.source!.isNotEmpty) ...[
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Source: ${entry.source}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFA1A1AA), fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}