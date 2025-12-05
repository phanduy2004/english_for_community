import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/entity/report_entity.dart';
import '../../../core/repository/report_repository.dart';
import 'report_event.dart';
import 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ReportRepository reportRepository;

  ReportBloc({required this.reportRepository}) : super(ReportState.initial()) {
    // Đăng ký sự kiện
    on<SendReportEvent>(_onSendReport);
  }

  Future<void> _onSendReport(
      SendReportEvent event,
      Emitter<ReportState> emit,
      ) async {
    // 1. Cập nhật trạng thái Loading
    emit(state.copyWith(status: ReportStatus.loading));

    // 2. Chuyển đổi dữ liệu từ Event sang Entity
    final reportEntity = ReportEntity(
      type: event.type,
      title: event.title,
      description: event.description,
      images: event.images,
      // Chuyển Map -> Object DeviceInfo
      deviceInfo: ReportDeviceInfo.fromJson(event.deviceData),
    );

    // 3. Gọi Repository
    final result = await reportRepository.sendReport(reportEntity);

    // 4. Xử lý kết quả (Fold)
    result.fold(
          (failure) {
        // Thất bại
        emit(state.copyWith(
          status: ReportStatus.error,
          errorMessage: failure.message,
        ));
      },
          (success) {
        // Thành công
        emit(state.copyWith(
          status: ReportStatus.success,
          // Xóa lỗi cũ nếu có
          errorMessage: null,
        ));
      },
    );
  }
}