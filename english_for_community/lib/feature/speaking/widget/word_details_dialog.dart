import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:translator_plus/translator_plus.dart';

import '../../../core/locale/l10n_context.dart';
import '../../../core/theme/app_color.dart';

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
    _initTtsSettings(); // Gọi hàm cấu hình TTS
    _fetchWordDetails();
  }

  // Phương thức mới để cấu hình FlutterTts theo kiểu Anh-Mỹ
  void _initTtsSettings() {
    // Sử dụng await hoặc .then để đảm bảo các thiết lập được áp dụng
    widget.tts.setLanguage("en-US").then((_) => debugPrint("TTS Language set to en-US."));
    widget.tts.setSpeechRate(0.5);
    widget.tts.setVolume(1.0);
    widget.tts.setPitch(1.0);
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

      if (_apiResult == null && _vietnameseMeaning == 'Cannot translate.') {
        throw Exception('__WORD_NOT_FOUND__');
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      final loc = context.l10n;
      setState(() {
        _isLoading = false;
        final msg = e.toString();
        final stripped = msg.contains('Exception:') ? msg.replaceFirst('Exception: ', '').trim() : msg;
        _error = stripped == '__WORD_NOT_FOUND__' ? loc.wordDetailsNotFound : (stripped.isEmpty ? loc.genericLoadError : stripped);
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
      // Gọi speak, lúc này tts đã được cấu hình en-US trong _initTtsSettings
      widget.tts.speak(widget.word);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
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
                  ? const Center(child: AppLoadingIndicator.center())
                  : _error.isNotEmpty
                  ? _buildErrorState()
                  : _buildSuccessState(),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.outline)),
              ),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.outline),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(t.close),
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
            const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
            const SizedBox(height: 16),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
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

    final t = context.l10n;
    final primaryColor = Theme.of(context).colorScheme.primary;
    const textMain = AppColors.textPrimary;
    const textMuted = AppColors.textSecondary;

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
                  backgroundColor: primaryColor.withValues(alpha: 0.1),
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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outline),
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
            Text(t.dictDefinitions, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textMuted)),
            const SizedBox(height: 12),
            ..._apiResult!.meanings.map((m) => _buildMeaningSection(m)),
          ],
        ],
      ),
    );
  }

  Widget _buildMeaningSection(WordMeaning meaning) {
    const textMain = AppColors.textPrimary;
    const textMuted = AppColors.textSecondary;

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