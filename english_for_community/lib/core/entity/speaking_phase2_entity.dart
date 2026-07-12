import 'package:equatable/equatable.dart';

/// Ngân sách token cho MỖI lượt trả lời của trợ lý thoại Vapi. Áp cho cả scenario
/// lẫn free-chat để AI nói trọn câu (Vapi mặc định/dashboard có thể cắt giữa chừng).
const int kVapiReplyMaxTokens = 500;

DateTime? _date(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

List<String> _strings(dynamic value) =>
    (value as List? ?? const []).map((e) => e.toString()).toList();

class SpeakingScenarioEntity extends Equatable {
  final String id;
  final String slug;
  final String title;
  final String description;
  final String group;
  final String levelSuggested;
  final List<String> goals;
  final String roleForAI;
  final String firstMessage;
  final List<String> successCriteria;
  final List<String> starterHints;

  const SpeakingScenarioEntity({
    required this.id,
    required this.slug,
    required this.title,
    this.description = '',
    this.group = 'daily',
    this.levelSuggested = 'Beginner',
    this.goals = const [],
    this.roleForAI = '',
    this.firstMessage = '',
    this.successCriteria = const [],
    this.starterHints = const [],
  });

  factory SpeakingScenarioEntity.freeChat() => const SpeakingScenarioEntity(
        id: '',
        slug: 'free-chat',
        title: 'Free chat',
        description: 'Open conversation',
        roleForAI: '',
        firstMessage: '',
      );

  factory SpeakingScenarioEntity.fromJson(Map<String, dynamic> json) =>
      SpeakingScenarioEntity(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        slug: (json['slug'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        group: (json['group'] ?? 'daily').toString(),
        levelSuggested: (json['levelSuggested'] ?? 'Beginner').toString(),
        goals: _strings(json['goals']),
        roleForAI: (json['roleForAI'] ?? '').toString(),
        firstMessage: (json['firstMessage'] ?? '').toString(),
        successCriteria: _strings(json['successCriteria']),
        starterHints: _strings(json['starterHints']),
      );

  Map<String, dynamic> toVapiOverrides() {
    // maxTokens: Vapi mặc định/dashboard có thể cắt reply GIỮA câu (nhất là model
    // reasoning ăn hết token) → nâng budget để AI nói TRỌN câu hỏi. Deep-merge với
    // dashboard nên chỉ set maxTokens (+messages), giữ provider/model gốc.
    if (id.isEmpty) {
      return const {
        'model': {'maxTokens': kVapiReplyMaxTokens},
      };
    }
    final goalText = goals.map((goal) => '- $goal').join('\n');
    return {
      if (firstMessage.isNotEmpty) 'firstMessage': firstMessage,
      'model': {
        'maxTokens': kVapiReplyMaxTokens,
        'messages': [
          {
            'role': 'system',
            'content':
                '$roleForAI\n\nScenario goals for the learner:\n$goalText\n\nKeep the conversation in English. Ask concise follow-up questions and stay in role.',
          }
        ],
      },
    };
  }

  @override
  List<Object?> get props => [
        id,
        slug,
        title,
        description,
        group,
        levelSuggested,
        goals,
        roleForAI,
        firstMessage,
        successCriteria,
        starterHints,
      ];
}

class SpeakingTrendEntity extends Equatable {
  final double overall;
  final double fc;
  final double lr;
  final double gra;
  final double ia;

  const SpeakingTrendEntity({
    this.overall = 0,
    this.fc = 0,
    this.lr = 0,
    this.gra = 0,
    this.ia = 0,
  });

  factory SpeakingTrendEntity.fromJson(Map<String, dynamic> json) =>
      SpeakingTrendEntity(
        overall: (json['overall'] as num?)?.toDouble() ?? 0,
        fc: (json['fc'] as num?)?.toDouble() ?? 0,
        lr: (json['lr'] as num?)?.toDouble() ?? 0,
        gra: (json['gra'] as num?)?.toDouble() ?? 0,
        ia: (json['ia'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props => [overall, fc, lr, gra, ia];
}

class SpeakingProgressSummaryEntity extends Equatable {
  final int sessions;
  final int minutes;
  final double averageOverall;
  final double averageWpm;
  final double bestOverall;
  final int speakingStreak;
  final int xp;
  final List<String> badges;
  final SpeakingTrendEntity trends;
  final List<String> labels;
  final List<double> overallSeries;
  final List<int> wpmSeries;
  final List<int> minuteSeries;
  final List<SpeakingProgressRecentEntity> recent;

  const SpeakingProgressSummaryEntity({
    this.sessions = 0,
    this.minutes = 0,
    this.averageOverall = 0,
    this.averageWpm = 0,
    this.bestOverall = 0,
    this.speakingStreak = 0,
    this.xp = 0,
    this.badges = const [],
    this.trends = const SpeakingTrendEntity(),
    this.labels = const [],
    this.overallSeries = const [],
    this.wpmSeries = const [],
    this.minuteSeries = const [],
    this.recent = const [],
  });

  factory SpeakingProgressSummaryEntity.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map? ?? const {};
    final averages = json['averages'] as Map? ?? const {};
    final chart = json['chart'] as Map? ?? const {};
    return SpeakingProgressSummaryEntity(
      sessions: (totals['sessions'] as num?)?.toInt() ?? 0,
      minutes: (totals['minutes'] as num?)?.toInt() ?? 0,
      averageOverall: (averages['overall'] as num?)?.toDouble() ?? 0,
      averageWpm: (averages['wpm'] as num?)?.toDouble() ?? 0,
      bestOverall: (totals['bestOverall'] as num?)?.toDouble() ?? 0,
      speakingStreak: (totals['speakingStreak'] as num?)?.toInt() ?? 0,
      xp: (totals['xp'] as num?)?.toInt() ?? 0,
      badges: _strings(totals['badges']),
      trends: json['trends'] is Map
          ? SpeakingTrendEntity.fromJson(
              Map<String, dynamic>.from(json['trends'] as Map))
          : const SpeakingTrendEntity(),
      labels: _strings(chart['labels']),
      overallSeries: (chart['overall'] as List? ?? const [])
          .map((e) => (e as num?)?.toDouble() ?? 0)
          .toList(),
      wpmSeries: (chart['wpm'] as List? ?? const [])
          .map((e) => (e as num?)?.toInt() ?? 0)
          .toList(),
      minuteSeries: (chart['minutes'] as List? ?? const [])
          .map((e) => (e as num?)?.toInt() ?? 0)
          .toList(),
      recent: (json['recent'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => SpeakingProgressRecentEntity.fromJson(
              Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        sessions,
        minutes,
        averageOverall,
        averageWpm,
        bestOverall,
        speakingStreak,
        xp,
        badges,
        trends,
        labels,
        overallSeries,
        wpmSeries,
        minuteSeries,
        recent,
      ];
}

class SpeakingProgressRecentEntity extends Equatable {
  final String id;
  final String title;
  final DateTime? createdAt;
  final double overall;
  final int durationSeconds;
  final double wpm;

  const SpeakingProgressRecentEntity({
    required this.id,
    this.title = '',
    this.createdAt,
    this.overall = 0,
    this.durationSeconds = 0,
    this.wpm = 0,
  });

  factory SpeakingProgressRecentEntity.fromJson(Map<String, dynamic> json) =>
      SpeakingProgressRecentEntity(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        createdAt: _date(json['createdAt']),
        overall: (json['overall'] as num?)?.toDouble() ?? 0,
        durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
        wpm: (json['wpm'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props =>
      [id, title, createdAt, overall, durationSeconds, wpm];
}

class SpeakingNotebookEntity extends Equatable {
  final int conversations;
  final int correctionsCount;
  final int vocabCount;
  final int repeatedErrorsCount;
  final List<SpeakingNotebookCorrectionEntity> repeatedErrors;
  final List<SpeakingNotebookCorrectionEntity> corrections;
  final List<SpeakingNotebookVocabEntity> vocab;

  const SpeakingNotebookEntity({
    this.conversations = 0,
    this.correctionsCount = 0,
    this.vocabCount = 0,
    this.repeatedErrorsCount = 0,
    this.repeatedErrors = const [],
    this.corrections = const [],
    this.vocab = const [],
  });

  factory SpeakingNotebookEntity.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map? ?? const {};
    return SpeakingNotebookEntity(
      conversations: (totals['conversations'] as num?)?.toInt() ?? 0,
      correctionsCount: (totals['corrections'] as num?)?.toInt() ?? 0,
      vocabCount: (totals['vocab'] as num?)?.toInt() ?? 0,
      repeatedErrorsCount: (totals['repeatedErrors'] as num?)?.toInt() ?? 0,
      repeatedErrors: (json['repeatedErrors'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => SpeakingNotebookCorrectionEntity.fromJson(
              Map<String, dynamic>.from(e)))
          .toList(),
      corrections: (json['corrections'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => SpeakingNotebookCorrectionEntity.fromJson(
              Map<String, dynamic>.from(e)))
          .toList(),
      vocab: (json['vocab'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => SpeakingNotebookVocabEntity.fromJson(
              Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        conversations,
        correctionsCount,
        vocabCount,
        repeatedErrorsCount,
        repeatedErrors,
        corrections,
        vocab,
      ];
}

class SpeakingNotebookCorrectionEntity extends Equatable {
  final String type;
  final String before;
  final String after;
  final String reason;
  final int count;
  final DateTime? lastSeenAt;

  const SpeakingNotebookCorrectionEntity({
    this.type = '',
    this.before = '',
    this.after = '',
    this.reason = '',
    this.count = 1,
    this.lastSeenAt,
  });

  factory SpeakingNotebookCorrectionEntity.fromJson(
          Map<String, dynamic> json) =>
      SpeakingNotebookCorrectionEntity(
        type: (json['type'] ?? '').toString(),
        before: (json['before'] ?? '').toString(),
        after: (json['after'] ?? '').toString(),
        reason: (json['reason'] ?? '').toString(),
        count: (json['count'] as num?)?.toInt() ?? 1,
        lastSeenAt: _date(json['lastSeenAt']),
      );

  @override
  List<Object?> get props => [type, before, after, reason, count, lastSeenAt];
}

class SpeakingNotebookVocabEntity extends Equatable {
  final String said;
  final String better;
  final String note;

  const SpeakingNotebookVocabEntity({
    this.said = '',
    this.better = '',
    this.note = '',
  });

  factory SpeakingNotebookVocabEntity.fromJson(Map<String, dynamic> json) =>
      SpeakingNotebookVocabEntity(
        said: (json['said'] ?? '').toString(),
        better: (json['better'] ?? '').toString(),
        note: (json['note'] ?? '').toString(),
      );

  @override
  List<Object?> get props => [said, better, note];
}
