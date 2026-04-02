import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // Để dùng kIsWeb
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/entity/listening_comp_entity.dart';
import '../../../../../core/repository/listening_comp_repository.dart';
import 'admin_listening_comp_event.dart';
import 'admin_listening_comp_state.dart';

class AdminListeningCompBloc extends Bloc<AdminListeningCompEvent, AdminListeningCompState> {
  final ListeningCompRepository repository;

  AdminListeningCompBloc({required this.repository}) : super(const AdminListeningCompState()) {

    // 1. LẤY DANH SÁCH
    on<GetAdminListeningCompListEvent>((event, emit) async {
      emit(state.copyWith(status: AdminListeningCompStatus.loading));
      final result = await repository.getListenings(
        page: event.page,
        limit: event.limit,
        difficulty: event.difficulty,
      );

      result.fold(
            (failure) => emit(state.copyWith(
          status: AdminListeningCompStatus.failure,
          errorMessage: failure.message,
        )),
            (pageData) => emit(state.copyWith(
          status: AdminListeningCompStatus.success,
          listenings: pageData.data,
          currentPage: pageData.currentPage,
          totalPages: pageData.totalPages,
        )),
      );
    });

    // 2. LẤY CHI TIẾT
    on<GetListeningCompDetailEvent>((event, emit) async {
      emit(state.copyWith(status: AdminListeningCompStatus.loading));
      final result = await repository.getListeningById(event.id);

      result.fold(
            (failure) => emit(state.copyWith(
          status: AdminListeningCompStatus.failure,
          errorMessage: failure.message,
        )),
            (entity) => emit(state.copyWith(
          status: AdminListeningCompStatus.success,
          selectedListening: entity,
        )),
      );
    });

    // 3. TẠO MỚI
    on<CreateListeningCompEvent>((event, emit) async {
      emit(state.copyWith(status: AdminListeningCompStatus.loading));
      try {
        final multipartFile = await _convertToMultipart(event.audioFile);
        final dataMap = _buildPayloadMap(event.entity);

        final result = await repository.createListeningComp(
          data: dataMap,
          audioFile: multipartFile,
        );

        result.fold(
              (failure) => emit(state.copyWith(status: AdminListeningCompStatus.failure, errorMessage: failure.message)),
              (_) => emit(state.copyWith(status: AdminListeningCompStatus.success)),
        );
      } catch (e) {
        emit(state.copyWith(status: AdminListeningCompStatus.failure, errorMessage: e.toString()));
      }
    });

    // 4. CẬP NHẬT
    on<UpdateListeningCompEvent>((event, emit) async {
      emit(state.copyWith(status: AdminListeningCompStatus.loading));
      try {
        final multipartFile = await _convertToMultipart(event.audioFile);
        final dataMap = _buildPayloadMap(event.entity);

        final result = await repository.updateListeningComp(
          id: event.id,
          data: dataMap,
          audioFile: multipartFile,
        );

        result.fold(
              (failure) => emit(state.copyWith(status: AdminListeningCompStatus.failure, errorMessage: failure.message)),
              (_) => emit(state.copyWith(status: AdminListeningCompStatus.success)),
        );
      } catch (e) {
        emit(state.copyWith(status: AdminListeningCompStatus.failure, errorMessage: e.toString()));
      }
    });

    // 5. XÓA
    on<DeleteListeningCompEvent>((event, emit) async {
      emit(state.copyWith(status: AdminListeningCompStatus.loading));
      final result = await repository.deleteListeningComp(event.id);

      result.fold(
            (failure) => emit(state.copyWith(
          status: AdminListeningCompStatus.failure,
          errorMessage: failure.message,
        )),
            (_) {
          // Cập nhật lại list ở UI ngay lập tức để đỡ phải fetch lại API
          final updatedList = state.listenings.where((item) => item.id != event.id).toList();
          emit(state.copyWith(
            status: AdminListeningCompStatus.success,
            listenings: updatedList,
          ));
        },
      );
    });

    // 6. CLEAR
    on<ClearSelectedListeningCompEvent>((event, emit) {
      emit(state.copyWith(clearSelected: true));
    });
  }

  // =========================================================
  // HELPER FUNCTIONS
  // =========================================================

  // Chuyển đổi PlatformFile sang MultipartFile cho Dio (Hỗ trợ Web + Mobile)
  Future<MultipartFile?> _convertToMultipart(PlatformFile? file) async {
    if (file == null) return null;

    if (kIsWeb && file.bytes != null) {
      return MultipartFile.fromBytes(file.bytes!, filename: file.name);
    } else if (!kIsWeb && file.path != null) {
      return await MultipartFile.fromFile(file.path!, filename: file.name);
    }
    return null;
  }

  // Đóng gói Entity thành Map<String, dynamic> để gửi API
  Map<String, dynamic> _buildPayloadMap(ListeningCompEntity entity) {
    return {
      'title': entity.title,
      'difficulty': entity.difficulty,
      'minutesToComplete': entity.minutesToComplete,
      // Map list các câu hỏi thành JSON Object
      'questions': entity.questions.map((q) {
        final qMap = {
          'questionText': q.questionText,
          'options': q.options,
          'correctAnswerIndex': q.correctAnswerIndex,
          'feedback': {
            'reasoning': q.feedback?.reasoning ?? '',
            'hintTimestampSeconds': q.feedback?.hintTimestampSeconds,
          }
        };
        // Chỉ gửi id nếu đang update câu hỏi cũ
        if (q.id.isNotEmpty) {
          qMap['_id'] = q.id;
        }
        return qMap;
      }).toList(),
    };
  }
}