// writing_submission_entity.dart
import 'package:equatable/equatable.dart';

class WritingSubmissionEntity extends Equatable {
  final String id;               // _id / id
  final String userId;
  final String topicId;
  final GeneratedPrompt? generatedPrompt;
  final String content;
  final int? wordCount;

  final String status;           // draft | submitted | reviewed
  final DateTime? startedAt;
  final DateTime? submittedAt;

  final FeedbackEntity? feedback;
  final double? score;
  final DateTime? reviewedAt;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WritingSubmissionEntity({
    required this.id,
    required this.userId,
    required this.topicId,
    this.generatedPrompt,
    this.content = '',
    this.wordCount,
    this.status = 'draft',
    this.startedAt,
    this.submittedAt,
    this.feedback,
    this.score,
    this.reviewedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory WritingSubmissionEntity.fromJson(Map<String, dynamic> json) {
    final _id = (json['_id'] ?? json['id']) as String?;
    if (_id == null) {
      throw ArgumentError('WritingSubmissionEntity.fromJson: missing id/_id');
    }
    return WritingSubmissionEntity(
      id: _id,
      userId: (json['userId'] ?? '') as String,
      topicId: (json['topicId'] ?? '') as String,
      generatedPrompt: json['generatedPrompt'] != null
          ? GeneratedPrompt.fromJson(json['generatedPrompt'] as Map<String, dynamic>)
          : null,
      content: (json['content'] ?? '') as String,
      wordCount: (json['wordCount'] as num?)?.toInt(),
      status: (json['status'] ?? 'draft') as String,
      startedAt: _parseDate(json['startedAt']),
      submittedAt: _parseDate(json['submittedAt']),
      feedback: json['feedback'] != null
          ? FeedbackEntity.fromJson(json['feedback'] as Map<String, dynamic>)
          : null,
      score: (json['score'] as num?)?.toDouble(),
      reviewedAt: _parseDate(json['reviewedAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'topicId': topicId,
    'generatedPrompt': generatedPrompt?.toJson(),
    'content': content,
    'wordCount': wordCount,
    'status': status,
    'startedAt': startedAt?.toIso8601String(),
    'submittedAt': submittedAt?.toIso8601String(),
    'feedback': feedback?.toJson(),
    'score': score,
    'reviewedAt': reviewedAt?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  static DateTime? _parseDate(Object? v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    topicId,
    generatedPrompt,
    content,
    wordCount,
    status,
    startedAt,
    submittedAt,
    feedback,
    score,
    reviewedAt,
    createdAt,
    updatedAt,
  ];
}

class GeneratedPrompt extends Equatable {
  final String? title;
  final String? text;
  final String? taskType;
  final String? level;
  final String? targetWordCount; // nếu backend có trả

  const GeneratedPrompt({this.title, this.text, this.taskType, this.level, this.targetWordCount});

  factory GeneratedPrompt.fromJson(Map<String, dynamic> json) => GeneratedPrompt(
    title: json['title'] as String?,
    text: json['text'] as String?,
    taskType: json['taskType'] as String?,
    level: json['level'] as String?,
    targetWordCount: json['targetWordCount'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'text': text,
    'taskType': taskType,
    'level': level,
    'targetWordCount': targetWordCount,
  };

  @override
  List<Object?> get props => [title, text, taskType, level, targetWordCount];
}

class FeedbackEntity extends Equatable {
  final double? overall; // có thể là số thập phân
  final int? tr, cc, lr, gra;

  final List<String>? trBullets, ccBullets, lrBullets, graBullets;
  final String? trNote, ccNote, lrNote, graNote;

  final List<ParagraphImprove>? paragraphs;

  final String? taskType;
  final List<String>? keyTips;
  final List<String>? outline;

  final List<VocabRow>? vocab;
  final List<GrammarRow>? grammarRows;
  final List<CoherenceRow>? coherenceRows;

  final String? sampleMid;
  final String? sampleHigh;

  final ModelInfo? modelInfo;
  final DateTime? evaluatedAt;

  const FeedbackEntity({
    this.overall,
    this.tr, this.cc, this.lr, this.gra,
    this.trBullets, this.ccBullets, this.lrBullets, this.graBullets,
    this.trNote, this.ccNote, this.lrNote, this.graNote,
    this.paragraphs,
    this.taskType,
    this.keyTips,
    this.outline,
    this.vocab,
    this.grammarRows,
    this.coherenceRows,
    this.sampleMid,
    this.sampleHigh,
    this.modelInfo,
    this.evaluatedAt,
  });

  factory FeedbackEntity.fromJson(Map<String, dynamic> json) => FeedbackEntity(
    overall: (json['overall'] as num?)?.toDouble(),
    tr: (json['tr'] as num?)?.toInt(),
    cc: (json['cc'] as num?)?.toInt(),
    lr: (json['lr'] as num?)?.toInt(),
    gra: (json['gra'] as num?)?.toInt(),
    trBullets: (json['trBullets'] as List?)?.map((e) => e as String).toList(),
    ccBullets: (json['ccBullets'] as List?)?.map((e) => e as String).toList(),
    lrBullets: (json['lrBullets'] as List?)?.map((e) => e as String).toList(),
    graBullets: (json['graBullets'] as List?)?.map((e) => e as String).toList(),
    trNote: json['trNote'] as String?,
    ccNote: json['ccNote'] as String?,
    lrNote: json['lrNote'] as String?,
    graNote: json['graNote'] as String?,
    paragraphs: (json['paragraphs'] as List?)
        ?.map((e) => ParagraphImprove.fromJson(e as Map<String, dynamic>))
        .toList(),
    taskType: json['taskType'] as String?,
    keyTips: (json['keyTips'] as List?)?.map((e) => e as String).toList(),
    outline: (json['outline'] as List?)?.map((e) => e as String).toList(),
    vocab: (json['vocab'] as List?)
        ?.map((e) => VocabRow.fromJson(e as Map<String, dynamic>))
        .toList(),
    grammarRows: (json['grammarRows'] as List?)
        ?.map((e) => GrammarRow.fromJson(e as Map<String, dynamic>))
        .toList(),
    coherenceRows: (json['coherenceRows'] as List?)
        ?.map((e) => CoherenceRow.fromJson(e as Map<String, dynamic>))
        .toList(),
    sampleMid: json['sampleMid'] as String?,
    sampleHigh: json['sampleHigh'] as String?,
    modelInfo: json['modelInfo'] != null
        ? ModelInfo.fromJson(json['modelInfo'] as Map<String, dynamic>)
        : null,
    evaluatedAt: _parseDate(json['evaluatedAt']),
  );

  Map<String, dynamic> toJson() => {
    'overall': overall,
    'tr': tr, 'cc': cc, 'lr': lr, 'gra': gra,
    'trBullets': trBullets, 'ccBullets': ccBullets, 'lrBullets': lrBullets, 'graBullets': graBullets,
    'trNote': trNote, 'ccNote': ccNote, 'lrNote': lrNote, 'graNote': graNote,
    'paragraphs': paragraphs?.map((e) => e.toJson()).toList(),
    'taskType': taskType,
    'keyTips': keyTips,
    'outline': outline,
    'vocab': vocab?.map((e) => e.toJson()).toList(),
    'grammarRows': grammarRows?.map((e) => e.toJson()).toList(),
    'coherenceRows': coherenceRows?.map((e) => e.toJson()).toList(),
    'sampleMid': sampleMid,
    'sampleHigh': sampleHigh,
    'modelInfo': modelInfo?.toJson(),
    'evaluatedAt': evaluatedAt?.toIso8601String(),
  };

  static DateTime? _parseDate(Object? v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return null;
  }

  @override
  List<Object?> get props => [
    overall, tr, cc, lr, gra,
    trBullets, ccBullets, lrBullets, graBullets,
    trNote, ccNote, lrNote, graNote,
    paragraphs, taskType, keyTips, outline,
    vocab, grammarRows, coherenceRows,
    sampleMid, sampleHigh, modelInfo, evaluatedAt,
  ];
}

class ParagraphImprove extends Equatable {
  final String? title;
  final String? comment;
  final String? rewrite;

  const ParagraphImprove({this.title, this.comment, this.rewrite});

  factory ParagraphImprove.fromJson(Map<String, dynamic> json) => ParagraphImprove(
    title: json['title'] as String?,
    comment: json['comment'] as String?,
    rewrite: json['rewrite'] as String?,
  );

  Map<String, dynamic> toJson() => {'title': title, 'comment': comment, 'rewrite': rewrite};

  @override
  List<Object?> get props => [title, comment, rewrite];
}

class VocabRow extends Equatable {
  final String? word;
  final String? type;
  final String? def;

  const VocabRow({this.word, this.type, this.def});

  factory VocabRow.fromJson(Map<String, dynamic> json) =>
      VocabRow(word: json['word'] as String?, type: json['type'] as String?, def: json['def'] as String?);

  Map<String, dynamic> toJson() => {'word': word, 'type': type, 'def': def};

  @override
  List<Object?> get props => [word, type, def];
}

class GrammarRow extends Equatable {
  final String? structure;
  final String? original;
  final String? rephrased;

  const GrammarRow({this.structure, this.original, this.rephrased});

  factory GrammarRow.fromJson(Map<String, dynamic> json) => GrammarRow(
    structure: json['structure'] as String?,
    original: json['original'] as String?,
    rephrased: json['rephrased'] as String?,
  );

  Map<String, dynamic> toJson() => {'structure': structure, 'original': original, 'rephrased': rephrased};

  @override
  List<Object?> get props => [structure, original, rephrased];
}

class CoherenceRow extends Equatable {
  final String? original;
  final String? improved;
  final String? explain;

  const CoherenceRow({this.original, this.improved, this.explain});

  factory CoherenceRow.fromJson(Map<String, dynamic> json) => CoherenceRow(
    original: json['original'] as String?,
    improved: json['improved'] as String?,
    explain: json['explain'] as String?,
  );

  Map<String, dynamic> toJson() => {'original': original, 'improved': improved, 'explain': explain};

  @override
  List<Object?> get props => [original, improved, explain];
}

class ModelInfo extends Equatable {
  final String? provider;
  final String? model;

  const ModelInfo({this.provider, this.model});

  factory ModelInfo.fromJson(Map<String, dynamic> json) =>
      ModelInfo(provider: json['provider'] as String?, model: json['model'] as String?);

  Map<String, dynamic> toJson() => {'provider': provider, 'model': model};

  @override
  List<Object?> get props => [provider, model];
}
