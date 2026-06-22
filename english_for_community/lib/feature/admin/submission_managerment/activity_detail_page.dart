import 'package:english_for_community/feature/admin/submission_managerment/reading_detail_view.dart';
import 'package:english_for_community/core/ui/motion/app_loading_indicator.dart';
import 'package:english_for_community/feature/admin/layout/admin_skeleton.dart';
import 'package:english_for_community/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc_detail/activity_detail_event.dart';
import 'bloc_detail/activity_detail_bloc.dart';
import 'bloc_detail/activity_detail_state.dart';
import 'model/activity_model.dart';

import 'package:english_for_community/feature/admin/submission_managerment/writing_detail_view.dart';
import 'package:english_for_community/feature/admin/submission_managerment/speaking_detail_view.dart';
import 'package:english_for_community/feature/admin/submission_managerment/listening_detail_view.dart';
import 'package:english_for_community/feature/admin/submission_managerment/listening_comp_detail_view.dart';

const Color kBgPage = AppColors.surfaceSubtle;
const Color kWhite = Colors.white;
const Color kTextMain = AppColors.textPrimary;

class ActivityDetailPage extends StatelessWidget {
  final String id;
  final ActivityType type;
  final String? summaryTitle;
  final DateTime? summaryDate;

  // 🔥 THÊM THUỘC TÍNH NÀY ĐỂ PHÂN BIỆT DICTATION VÀ COMPREHENSION
  final String? subType;

  /// User xem lại bài của chính mình → API `/users/me/activities/...`
  final bool useUserActivityApi;

  const ActivityDetailPage({
    super.key,
    required this.id,
    required this.type,
    this.summaryTitle,
    this.summaryDate,
    this.subType, // Truyền từ ActivityHistoryPage sang
    this.useUserActivityApi = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Truyền thêm subType vào event để BLoC biết đường gọi API
      create: (context) => ActivityDetailBloc()
        ..add(FetchActivityDetailEvent(
          id: id,
          type: type,
          subType: subType,
          useUserActivityApi: useUserActivityApi,
        )),
      child: Scaffold(
        backgroundColor: kBgPage,
        appBar: AppBar(
          title: const Text('Detail Review', style: TextStyle(fontWeight: FontWeight.bold, color: kTextMain)),
          backgroundColor: kWhite,
          elevation: 0,
          leading: const BackButton(color: kTextMain),
        ),
        body: BlocBuilder<ActivityDetailBloc, ActivityDetailState>(
          builder: (context, state) {
            if (state.status == DetailStatus.loading) {
              return AdminSkeleton.page(AdminSkeleton.cardList());
            }
            if (state.status == DetailStatus.error) {
              return Center(child: Text("Error: ${state.errorMessage}"));
            }
            if (state.status == DetailStatus.success) {
              switch (type) {
                case ActivityType.writing:
                  if (state.writingData != null) {
                    return WritingDetailView(data: state.writingData!);
                  }
                  break;
                case ActivityType.reading:
                  if (state.readingData != null) {
                    return ReadingDetailView(data: state.readingData!);
                  }
                  break;
                case ActivityType.speaking:
                  if (state.speakingData != null) {
                    return SpeakingDetailView(data: state.speakingData!);
                  }
                  break;
                case ActivityType.listening:
                // 🔥 KIỂM TRA SUBTYPE ĐỂ HIỂN THỊ ĐÚNG VIEW
                  if (subType == 'Comprehension' && state.listeningCompData != null) {
                    return ListeningCompDetailView(
                        data: state.listeningCompData!,
                        listeningDetail: state.listeningCompDetail // Bạn cần truyền thêm cái này từ state
                    );
                  } else if (state.listeningData != null) {
                    // Mặc định là Dictation
                    return ListeningDetailView(data: state.listeningData!);
                  }
                  break;
                default:
                  return const SizedBox.shrink();
              }
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

