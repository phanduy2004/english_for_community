class AdminStatsEntity {
  final Metrics metrics;
  final ChartData chart;

  AdminStatsEntity({required this.metrics, required this.chart});

  factory AdminStatsEntity.fromJson(Map<String, dynamic> json) {
    return AdminStatsEntity(
      metrics: Metrics.fromJson(json['metrics']),
      chart: ChartData.fromJson(json['chart']),
    );
  }
}

class Metrics {
  final MetricItem submissions;
  final MetricItem reports;
  final MetricItem aiCost;
  final MetricItem activeUsers;

  Metrics({
    required this.submissions,
    required this.reports,
    required this.aiCost,
    required this.activeUsers,
  });

  factory Metrics.fromJson(Map<String, dynamic> json) {
    return Metrics(
      submissions: MetricItem.fromJson(json['submissions']),
      reports: MetricItem.fromJson(json['reports']),
      aiCost: MetricItem.fromJson(json['aiCost']),
      activeUsers: MetricItem.fromJson(json['activeUsers']),
    );
  }
}

class MetricItem {
  final dynamic value; // Có thể là int hoặc String ($0.123)
  final String? trend;
  final String? subLabel;
  final String? status;

  // --- MỚI THÊM ĐỂ KHỚP VỚI BACKEND & UI ---
  final String? trendLabel; // Ví dụ: "vs yesterday"
  final bool? isPositive;   // Ví dụ: true/false

  MetricItem({
    required this.value,
    this.trend,
    this.subLabel,
    this.status,
    this.trendLabel,
    this.isPositive,
  });

  factory MetricItem.fromJson(Map<String, dynamic> json) {
    return MetricItem(
      value: json['value'],
      trend: json['trend'],
      subLabel: json['subLabel'],
      status: json['status'],
      trendLabel: json['trendLabel'], // Map từ JSON
      isPositive: json['isPositive'], // Map từ JSON
    );
  }
}

class ChartData {
  final List<String> labels;
  final List<int> writing;
  final List<int> speaking;
  final List<int> reading;
  final List<int> dictation;

  ChartData({
    required this.labels,
    required this.writing,
    required this.speaking,
    required this.reading,
    required this.dictation,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      labels: List<String>.from(json['labels'] ?? []),
      writing: List<int>.from(json['writing'] ?? []),
      speaking: List<int>.from(json['speaking'] ?? []),
      reading: json['reading'] != null ? List<int>.from(json['reading']) : [],
      dictation: json['dictation'] != null ? List<int>.from(json['dictation']) : [],
    );
  }
}