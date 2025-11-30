import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:translator_plus/translator_plus.dart';

class WordDetailsDialog extends StatefulWidget {
  final String word;
  final FlutterTts tts;

  const WordDetailsDialog({
    super.key,
    required this.word,
    required this.tts,
  });

  @override
  State<WordDetailsDialog> createState() => _WordDetailsDialogState();
}

class _WordDetailsDialogState extends State<WordDetailsDialog> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isLoading = true;
  String _vietnameseMeaning = '';
  String _error = '';
  ApiWordResult? _apiResult;

  @override
  void initState() {
    super.initState();
    _fetchWordDetails();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchWordDetails() async {
    try {
      final results = await Future.wait([
        _fetchDictionaryData(widget.word),
        _fetchTranslation(widget.word),
      ]);

      if (!mounted) return;

      _apiResult = results[0] as ApiWordResult?;
      _vietnameseMeaning = results[1] as String;

      if (_apiResult == null && _vietnameseMeaning == 'Không thể dịch.') {
        throw Exception("Cannot find word details.");
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().contains("Exception:")
            ? e.toString().replaceFirst("Exception: ", "")
            : "An error occurred.";
      });
    }
  }

  Future<ApiWordResult?> _fetchDictionaryData(String word) async {
    try {
      final response = await http.get(
          Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$word'));

      if (response.statusCode == 200) {
        final List<dynamic> dataList = json.decode(response.body);
        if (dataList.isEmpty) return null;

        final data = dataList[0];
        String phonetic = data['phonetic'] as String? ?? '';
        String audioUrl = '';
        List<WordMeaning> meanings = [];

        final phonetics = data['phonetics'] as List<dynamic>? ?? [];
        final audioItem = phonetics.firstWhere(
              (p) => (p['audio'] as String?)?.endsWith('.mp3') ?? false,
          orElse: () => phonetics.firstWhere(
                (p) => (p['audio'] as String?)?.isNotEmpty ?? false,
            orElse: () => null,
          ),
        );

        if (audioItem != null) {
          audioUrl = audioItem['audio'];
          if (phonetic.isEmpty) {
            phonetic = audioItem['text'] as String? ?? '';
          }
        }
        if (phonetic.isEmpty && phonetics.isNotEmpty) {
          phonetic = phonetics[0]['text'] as String? ?? '';
        }

        final meaningsData = data['meanings'] as List<dynamic>? ?? [];
        for (var meaningData in meaningsData) {
          final partOfSpeech = meaningData['partOfSpeech'] as String? ?? 'N/A';
          final definitionsData =
              meaningData['definitions'] as List<dynamic>? ?? [];
          List<WordDefinition> definitions = [];

          for (var defData in definitionsData) {
            final definition = defData['definition'] as String? ?? '';
            final example = defData['example'] as String? ?? '';
            if (definition.isNotEmpty) {
              definitions.add(WordDefinition(definition, example));
            }
          }

          if(definitions.isNotEmpty) {
            meanings.add(WordMeaning(partOfSpeech, definitions));
          }
        }

        return ApiWordResult(phonetic, audioUrl, meanings);
      }
      return null;
    } catch (e) {
      debugPrint("Dictionary API Error: $e");
      return null;
    }
  }

  Future<String> _fetchTranslation(String word) async {
    try {
      final translation = await word.translate(from: 'en', to: 'vi');
      return translation.text;
    } catch (e) {
      debugPrint("Translator Error: $e");
      return 'Cannot translate.';
    }
  }

  void _pronounceWord() {
    widget.tts.stop();
    _audioPlayer.stop();

    if (_apiResult?.audioUrl.isNotEmpty ?? false) {
      _audioPlayer.play(UrlSource(_apiResult!.audioUrl));
    } else {
      widget.tts.speak(widget.word);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : _error.isNotEmpty
                  ? _buildErrorState()
                  : _buildSuccessState(),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE4E4E7))),
              ),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF09090B),
                  side: const BorderSide(color: Color(0xFFE4E4E7)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 40),
            const SizedBox(height: 16),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF71717A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    if (_apiResult == null && _vietnameseMeaning == "Cannot translate.") {
      return _buildErrorState();
    }

    final primaryColor = Theme.of(context).colorScheme.primary;
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.word,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textMain),
                    ),
                    if (_apiResult?.phonetic.isNotEmpty ?? false) ...[
                      const SizedBox(height: 4),
                      Text(
                        _apiResult!.phonetic,
                        style: const TextStyle(fontSize: 16, color: textMuted, fontFamily: 'NotoSans'),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: _pronounceWord,
                style: IconButton.styleFrom(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(Icons.volume_up_rounded, color: primaryColor),
              ),
            ],
          ),

          const SizedBox(height: 24),

          if (_vietnameseMeaning.isNotEmpty && _vietnameseMeaning != "Cannot translate.")
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE4E4E7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.translate, size: 18, color: textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _vietnameseMeaning,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primaryColor),
                    ),
                  ),
                ],
              ),
            ),

          if (_apiResult?.meanings.isNotEmpty ?? false) ...[
            const SizedBox(height: 24),
            const Text("Definitions", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textMuted)),
            const SizedBox(height: 12),
            ..._apiResult!.meanings.map((m) => _buildMeaningSection(m)),
          ],
        ],
      ),
    );
  }

  Widget _buildMeaningSection(WordMeaning meaning) {
    const textMain = Color(0xFF09090B);
    const textMuted = Color(0xFF71717A);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meaning.partOfSpeech,
            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, color: textMain),
          ),
          const SizedBox(height: 8),
          ...meaning.definitions.asMap().entries.map((entry) {
            final index = entry.key;
            final def = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${index + 1}. ", style: const TextStyle(fontSize: 14, color: textMuted)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(def.definition, style: const TextStyle(fontSize: 14, color: textMain, height: 1.4)),
                        if (def.example != null && def.example!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              "\"${def.example}\"",
                              style: const TextStyle(fontSize: 13, color: textMuted, fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class ApiWordResult {
  final String phonetic;
  final String audioUrl;
  final List<WordMeaning> meanings;

  ApiWordResult(this.phonetic, this.audioUrl, this.meanings);
}

class WordMeaning {
  final String partOfSpeech;
  final List<WordDefinition> definitions;

  WordMeaning(this.partOfSpeech, this.definitions);
}

class WordDefinition {
  final String definition;
  final String? example;

  WordDefinition(this.definition, this.example);
}