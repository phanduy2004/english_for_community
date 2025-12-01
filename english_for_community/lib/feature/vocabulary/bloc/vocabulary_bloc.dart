import 'package:english_for_community/core/model/failure.dart';
import 'package:english_for_community/core/model/either.dart';
import 'package:english_for_community/core/entity/user_word_entity.dart';
import 'package:english_for_community/feature/vocabulary/bloc/vocabulary_event.dart';
import 'package:english_for_community/feature/vocabulary/bloc/vocabulary_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repository/user_vocab_repository.dart';

class VocabularyBloc extends Bloc<VocabularyEvent, VocabularyState> {
  // ✍️ Sửa dependency thành UserVocabRepository
  final UserVocabRepository userVocabRepository;

  VocabularyBloc({required this.userVocabRepository})
      : super(VocabularyState.initial()) {
    // ✍️ Đăng ký sự kiện
    on<FetchVocabularyData>(onFetchVocabularyData);
    on<StartLearningWordEvent>(onStartLearningWord);
  }
  Future<void> onStartLearningWord(
      StartLearningWordEvent event,
      Emitter<VocabularyState> emit,
      ) async {
    final result = await userVocabRepository.startLearningFromUserWord(event.userWord);
    result.fold(
          (failure) {
        print('Lỗi start learning: ${failure.message}');
        emit(state.copyWith(
            status: VocabularyStatus.error,
            errorMessage: 'Lỗi: ${failure.message}'));
        add(const FetchVocabularyData());
      },
          (_) {
        print('Bắt đầu học: ${event.userWord.headword}');
        add(const FetchVocabularyData());
      },
    );
  }
  Future<void> onFetchVocabularyData(
      FetchVocabularyData event,
      Emitter<VocabularyState> emit,
      ) async {
    // 1. Phát trạng thái Loading
    emit(state.copyWith(status: VocabularyStatus.loading));

    // 2. Gọi đồng thời 3
    // phương thức repository
    final results = await Future.wait([
      userVocabRepository.getRecentWords(),
      userVocabRepository.getLearningWords(),
      userVocabRepository.getSavedWords(),
    ]);

    // 3. Gán kết quả (vẫn đang ở dạng Either)
    // 🔽 ✍️ SỬA LỖI Ở ĐÂY: Sửa List<String> thành List<UserWordEntity>
    final recentResult = results[0] as Either<Failure, List<UserWordEntity>>;
    final learningResult = results[1] as Either<Failure, List<UserWordEntity>>;
    final savedResult = results[2] as Either<Failure, List<UserWordEntity>>;

    // 4. Xử lý kết quả (Fold lồng nhau để đảm bảo cả 3 đều thành công)
    recentResult.fold(
          (failure) {
        // 5a. Lỗi (ngay từ hàm đầu tiên)
        emit(state.copyWith(
          status: VocabularyStatus.error,
          errorMessage: failure.message,
        ));
      },
          (recentWords) { // 👈 Biến 'recentWords' này bây giờ đã là List<UserWordEntity>
        // Hàm 1 thành công, kiểm tra hàm 2
        learningResult.fold(
              (failure) {
            // 5b. Lỗi (ở hàm thứ 2)
            emit(state.copyWith(
              status: VocabularyStatus.error,
              errorMessage: failure.message,
            ));
          },
              (learningWords) {
            // Hàm 2 thành công, kiểm tra hàm 3
            savedResult.fold(
                  (failure) {
                // 5c. Lỗi (ở hàm thứ 3)
                emit(state.copyWith(
                  status: VocabularyStatus.error,
                  errorMessage: failure.message,
                ));
              },
                  (savedWords) {
                // 6. Thành công (Cả 3 đều thành công)
                emit(state.copyWith(
                  status: VocabularyStatus.success,
                  // 🔽 Dòng này bây giờ đã HỢP LỆ
                  recentWords: recentWords,
                  learningWords: learningWords,
                  savedWords: savedWords,
                ));
              },
            );
          },
        );
      },
    );
  }
}