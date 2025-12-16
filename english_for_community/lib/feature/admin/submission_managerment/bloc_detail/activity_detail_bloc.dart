import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/get_it/get_it.dart';
import '../../../../../../core/entity/writing_submission_entity.dart';
import '../../../../../../core/entity/reading/reading_attempt_entity.dart';
import '../../../../../../core/entity/speaking/speaking_set_entity.dart';
import '../../../../../../core/entity/dictation_attempt_entity.dart';
import '../../../../core/repository/history_repository.dart';
import '../bloc/history_event.dart';
import '../model/activity_model.dart';
import 'activity_detail_state.dart';

class ActivityDetailBloc extends Bloc<ActivityDetailEvent, ActivityDetailState> {
  // 🔥 Chỉ cần HistoryRepository
  final HistoryRepository _repository = getIt<HistoryRepository>();

  ActivityDetailBloc() : super(const ActivityDetailState()) {
    on<FetchActivityDetailEvent>(_onFetchDetail);
  }

  Future<void> _onFetchDetail(
      FetchActivityDetailEvent event,
      Emitter<ActivityDetailState> emit,
      ) async {
    emit(state.copyWith(status: DetailStatus.loading));

    // Gọi hàm chung getActivityDetail
    final result = await _repository.getActivityDetail(event.id, event.type);

    result.fold(
          (failure) => emit(state.copyWith(
          status: DetailStatus.error,
          errorMessage: failure.message
      )),
          (data) {
        // 🔥 Cast dữ liệu về đúng State dựa trên Type
        switch (event.type) {
          case ActivityType.writing:
            emit(state.copyWith(
                status: DetailStatus.success,
                writingData: data as WritingSubmissionEntity
            ));
            break;
          case ActivityType.reading:
            emit(state.copyWith(
                status: DetailStatus.success,
                readingData: data as ReadingAttemptEntity
            ));
            break;
          case ActivityType.speaking:
            emit(state.copyWith(
                status: DetailStatus.success,
                speakingData: data as SpeakingSetEntity
            ));
            break;
          case ActivityType.listening:
            emit(state.copyWith(
                status: DetailStatus.success,
                listeningData: data as List<DictationAttemptEntity>
            ));
            break;
          default:
            emit(state.copyWith(status: DetailStatus.error, errorMessage: "Unknown data type"));
        }
      },
    );
  }
}