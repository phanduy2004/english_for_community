import 'package:flutter/material.dart';

import '../../admin/submission_managerment/model/activity_model.dart';

abstract class MyExerciseHistoryEvent {}

/// Tải trang 1 (làm mới sau đổi filter / khoảng ngày). Luôn gửi đủ [dateRange] + [skillFilter].
class MyExerciseHistoryFetch extends MyExerciseHistoryEvent {
  final DateTimeRange dateRange;
  final ActivityType? skillFilter;
  final bool forceRefresh;

  MyExerciseHistoryFetch({
    required this.dateRange,
    required this.skillFilter,
    this.forceRefresh = false,
  });
}

/// Cuộn xuống tải thêm
class MyExerciseHistoryLoadMore extends MyExerciseHistoryEvent {}
