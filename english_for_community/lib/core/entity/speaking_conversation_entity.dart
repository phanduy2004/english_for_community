import 'package:equatable/equatable.dart';
import 'speaking_phase2_entity.dart';

class SpeakingTurnEntity extends Equatable {
  final String role;
  final String text;
  final int? ts;

  const SpeakingTurnEntity({required this.role, required this.text, this.ts});

  factory SpeakingTurnEntity.fromJson(Map<String, dynamic> json) =>
      SpeakingTurnEntity(
        role: (json['role'] ?? '') as String,
        text: (json['text'] ?? '') as String,
        ts: (json['ts'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'role': role,
        'text': text,
        if (ts != null) 'ts': ts,
      };

  @override
  List<Object?> get props => [role, text, ts];
}

class SpeakingConversationEntity extends Equatable {
  final String id;
  final String userId;
  final String mode;
  final String? level;
  final String? scenario;
  final String? scenarioId;
  final List<SpeakingTurnEntity> turns;
  final int? wordCount;
  final int durationSeconds;
  final String status;
  final SpeakingFeedbackEntity? feedback;
  final double? score;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? errorMessage;

  const SpeakingConversationEntity({
    required this.id,
    required this.userId,
    this.mode = 'freeSpeaking',
    this.level,
    this.scenario,
    this.scenarioId,
    this.turns = const [],
    this.wordCount,
    this.durationSeconds = 0,
    this.status = 'evaluating',
    this.feedback,
    this.score,
    this.startedAt,
    this.endedAt,
    this.createdAt,
    this.updatedAt,
    this.errorMessage,
  });

  factory SpeakingConversationEntity.fromJson(Map<String, dynamic> json) {
    final id = _parseId(json['_id'] ?? json['id']);
    return SpeakingConversationEntity(
      id: id,
      userId: _parseId(json['userId']),
      mode: (json['mode'] ?? 'freeSpeaking') as String,
      level: json['level'] as String?,
      scenario: json['scenario'] as String?,
      scenarioId: _parseId(json['scenarioId']),
      turns: (json['turns'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => SpeakingTurnEntity.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      wordCount: (json['wordCount'] as num?)?.toInt(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? 'evaluating') as String,
      feedback: json['feedback'] is Map
          ? SpeakingFeedbackEntity.fromJson(
              Map<String, dynamic>.from(json['feedback'] as Map),
            )
          : null,
      score: (json['score'] as num?)?.toDouble(),
      startedAt: _parseDate(json['startedAt']),
      endedAt: _parseDate(json['endedAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      errorMessage: json['errorMessage'] as String?,
    );
  }

  static String _parseId(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      return value['_id']?.toString() ?? value['id']?.toString() ?? '';
    }
    return value.toString();
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        mode,
        level,
        scenario,
        scenarioId,
        turns,
        wordCount,
        durationSeconds,
        status,
        feedback,
        score,
        startedAt,
        endedAt,
        createdAt,
        updatedAt,
        errorMessage,
      ];
}

class SpeakingConversationSummaryEntity extends Equatable {
  final String id;
  final DateTime? createdAt;
  final double? overall;
  final String? cefr;
  final int durationSeconds;
  final int turnCount;
  final String title;

  const SpeakingConversationSummaryEntity({
    required this.id,
    this.createdAt,
    this.overall,
    this.cefr,
    this.durationSeconds = 0,
    this.turnCount = 0,
    this.title = '',
  });

  factory SpeakingConversationSummaryEntity.fromJson(
          Map<String, dynamic> json) =>
      SpeakingConversationSummaryEntity(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        createdAt: SpeakingConversationEntity._parseDate(json['createdAt']),
        overall: (json['overall'] as num?)?.toDouble(),
        cefr: json['cefr'] as String?,
        durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
        turnCount: (json['turnCount'] as num?)?.toInt() ?? 0,
        title: (json['title'] ?? '').toString(),
      );

  @override
  List<Object?> get props =>
      [id, createdAt, overall, cefr, durationSeconds, turnCount, title];
}

class SpeakingFeedbackEntity extends Equatable {
  final double overall;
  final String cefr;
  final String summary;
  final double fc;
  final List<String> fcBullets;
  final String fcNote;
  final double lr;
  final List<String> lrBullets;
  final String lrNote;
  final double gra;
  final List<String> graBullets;
  final String graNote;
  final double ia;
  final List<String> iaBullets;
  final String iaNote;
  final double? taskAchievement;
  final List<String> taskBullets;
  final String taskNote;
  final String scenarioTitle;
  final SpeakingTrendEntity? trends;
  final List<String> strengths;
  final List<SpeakingImprovementEntity> improvements;
  final List<SpeakingCorrectionEntity> corrections;
  final List<SpeakingVocabUpgradeEntity> vocabUpgrades;
  final List<SpeakingModelAnswerEntity> modelAnswers;
  final List<String> nextSteps;
  final SpeakingStatsEntity? stats;
  final SpeakingModelInfoEntity? modelInfo;
  final DateTime? evaluatedAt;

  const SpeakingFeedbackEntity({
    this.overall = 0,
    this.cefr = 'A1',
    this.summary = '',
    this.fc = 0,
    this.fcBullets = const [],
    this.fcNote = '',
    this.lr = 0,
    this.lrBullets = const [],
    this.lrNote = '',
    this.gra = 0,
    this.graBullets = const [],
    this.graNote = '',
    this.ia = 0,
    this.iaBullets = const [],
    this.iaNote = '',
    this.taskAchievement,
    this.taskBullets = const [],
    this.taskNote = '',
    this.scenarioTitle = '',
    this.trends,
    this.strengths = const [],
    this.improvements = const [],
    this.corrections = const [],
    this.vocabUpgrades = const [],
    this.modelAnswers = const [],
    this.nextSteps = const [],
    this.stats,
    this.modelInfo,
    this.evaluatedAt,
  });

  factory SpeakingFeedbackEntity.fromJson(Map<String, dynamic> json) =>
      SpeakingFeedbackEntity(
        overall: (json['overall'] as num?)?.toDouble() ?? 0,
        cefr: (json['cefr'] ?? 'A1') as String,
        summary: (json['summary'] ?? '') as String,
        fc: (json['fc'] as num?)?.toDouble() ?? 0,
        fcBullets: _stringList(json['fcBullets']),
        fcNote: (json['fcNote'] ?? '') as String,
        lr: (json['lr'] as num?)?.toDouble() ?? 0,
        lrBullets: _stringList(json['lrBullets']),
        lrNote: (json['lrNote'] ?? '') as String,
        gra: (json['gra'] as num?)?.toDouble() ?? 0,
        graBullets: _stringList(json['graBullets']),
        graNote: (json['graNote'] ?? '') as String,
        ia: (json['ia'] as num?)?.toDouble() ?? 0,
        iaBullets: _stringList(json['iaBullets']),
        iaNote: (json['iaNote'] ?? '') as String,
        taskAchievement: (json['taskAchievement'] as num?)?.toDouble(),
        taskBullets: _stringList(json['taskBullets']),
        taskNote: (json['taskNote'] ?? '') as String,
        scenarioTitle: (json['scenarioTitle'] ?? '') as String,
        trends: json['trends'] is Map
            ? SpeakingTrendEntity.fromJson(
                Map<String, dynamic>.from(json['trends'] as Map),
              )
            : null,
        strengths: _stringList(json['strengths']),
        improvements: _objectList(json['improvements'])
            .map(SpeakingImprovementEntity.fromJson)
            .toList(),
        corrections: _objectList(json['corrections'])
            .map(SpeakingCorrectionEntity.fromJson)
            .toList(),
        vocabUpgrades: _objectList(json['vocabUpgrades'])
            .map(SpeakingVocabUpgradeEntity.fromJson)
            .toList(),
        modelAnswers: _objectList(json['modelAnswers'])
            .map(SpeakingModelAnswerEntity.fromJson)
            .toList(),
        nextSteps: _stringList(json['nextSteps']),
        stats: json['stats'] is Map
            ? SpeakingStatsEntity.fromJson(
                Map<String, dynamic>.from(json['stats'] as Map),
              )
            : null,
        modelInfo: json['modelInfo'] is Map
            ? SpeakingModelInfoEntity.fromJson(
                Map<String, dynamic>.from(json['modelInfo'] as Map),
              )
            : null,
        evaluatedAt: SpeakingConversationEntity._parseDate(json['evaluatedAt']),
      );

  static List<String> _stringList(dynamic value) =>
      (value as List? ?? const []).map((e) => e.toString()).toList();

  static List<Map<String, dynamic>> _objectList(dynamic value) =>
      (value as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  @override
  List<Object?> get props => [
        overall,
        cefr,
        summary,
        fc,
        fcBullets,
        fcNote,
        lr,
        lrBullets,
        lrNote,
        gra,
        graBullets,
        graNote,
        ia,
        iaBullets,
        iaNote,
        taskAchievement,
        taskBullets,
        taskNote,
        scenarioTitle,
        trends,
        strengths,
        improvements,
        corrections,
        vocabUpgrades,
        modelAnswers,
        nextSteps,
        stats,
        modelInfo,
        evaluatedAt,
      ];
}

class SpeakingImprovementEntity extends Equatable {
  final String issue;
  final String before;
  final String after;
  final String explain;

  const SpeakingImprovementEntity({
    this.issue = '',
    this.before = '',
    this.after = '',
    this.explain = '',
  });

  factory SpeakingImprovementEntity.fromJson(Map<String, dynamic> json) =>
      SpeakingImprovementEntity(
        issue: (json['issue'] ?? '') as String,
        before: (json['before'] ?? '') as String,
        after: (json['after'] ?? '') as String,
        explain: (json['explain'] ?? '') as String,
      );

  @override
  List<Object?> get props => [issue, before, after, explain];
}

class SpeakingCorrectionEntity extends Equatable {
  final String type;
  final String before;
  final String after;
  final String reason;

  const SpeakingCorrectionEntity({
    this.type = '',
    this.before = '',
    this.after = '',
    this.reason = '',
  });

  factory SpeakingCorrectionEntity.fromJson(Map<String, dynamic> json) =>
      SpeakingCorrectionEntity(
        type: (json['type'] ?? '') as String,
        before: (json['before'] ?? '') as String,
        after: (json['after'] ?? '') as String,
        reason: (json['reason'] ?? '') as String,
      );

  @override
  List<Object?> get props => [type, before, after, reason];
}

class SpeakingVocabUpgradeEntity extends Equatable {
  final String said;
  final String better;
  final String note;

  const SpeakingVocabUpgradeEntity({
    this.said = '',
    this.better = '',
    this.note = '',
  });

  factory SpeakingVocabUpgradeEntity.fromJson(Map<String, dynamic> json) =>
      SpeakingVocabUpgradeEntity(
        said: (json['said'] ?? '') as String,
        better: (json['better'] ?? '') as String,
        note: (json['note'] ?? '') as String,
      );

  @override
  List<Object?> get props => [said, better, note];
}

class SpeakingModelAnswerEntity extends Equatable {
  final String context;
  final String yourTurn;
  final String modelTurn;

  const SpeakingModelAnswerEntity({
    this.context = '',
    this.yourTurn = '',
    this.modelTurn = '',
  });

  factory SpeakingModelAnswerEntity.fromJson(Map<String, dynamic> json) =>
      SpeakingModelAnswerEntity(
        context: (json['context'] ?? '') as String,
        yourTurn: (json['yourTurn'] ?? '') as String,
        modelTurn: (json['modelTurn'] ?? '') as String,
      );

  @override
  List<Object?> get props => [context, yourTurn, modelTurn];
}

class SpeakingStatsEntity extends Equatable {
  final int words;
  final int durationSec;
  final double wpm;
  final int fillerCount;
  final int questionCount;
  final int turnCount;

  const SpeakingStatsEntity({
    this.words = 0,
    this.durationSec = 0,
    this.wpm = 0,
    this.fillerCount = 0,
    this.questionCount = 0,
    this.turnCount = 0,
  });

  factory SpeakingStatsEntity.fromJson(Map<String, dynamic> json) =>
      SpeakingStatsEntity(
        words: (json['words'] as num?)?.toInt() ?? 0,
        durationSec: (json['durationSec'] as num?)?.toInt() ?? 0,
        wpm: (json['wpm'] as num?)?.toDouble() ?? 0,
        fillerCount: (json['fillerCount'] as num?)?.toInt() ?? 0,
        questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
        turnCount: (json['turnCount'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props =>
      [words, durationSec, wpm, fillerCount, questionCount, turnCount];
}

class SpeakingModelInfoEntity extends Equatable {
  final String? provider;
  final String? model;

  const SpeakingModelInfoEntity({this.provider, this.model});

  factory SpeakingModelInfoEntity.fromJson(Map<String, dynamic> json) =>
      SpeakingModelInfoEntity(
        provider: json['provider'] as String?,
        model: json['model'] as String?,
      );

  @override
  List<Object?> get props => [provider, model];
}
