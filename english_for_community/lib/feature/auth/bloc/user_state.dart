import 'package:equatable/equatable.dart';
import '../../../core/entity/user_entity.dart';

enum UserStatus {
  initial,
  loading, // Chỉ dùng cho Splash lúc mở app
  success,
  error,
  unauthenticated,
  otpRequired
}

class UserState extends Equatable {
  final UserStatus status;
  final String? errorMessage;
  final UserEntity? userEntity;
  final String? banReason;

  // --- 🆕 BIẾN MỚI: Dùng cho nút loading ở Login/Register ---
  final bool isFormLoading;

  const UserState._({
    required this.status,
    this.errorMessage,
    this.userEntity,
    this.banReason,
    this.isFormLoading = false, // Mặc định false
  });

  factory UserState.initial() => const UserState._(status: UserStatus.initial);

  UserState copyWith({
    UserStatus? status,
    String? errorMessage,
    UserEntity? userEntity,
    String? banReason,
    bool? isFormLoading, // Thêm vào copyWith
  }) =>
      UserState._(
        status: status ?? this.status,
        errorMessage: errorMessage, // Nếu truyền null sẽ giữ nguyên (cần cẩn thận), ở đây logic simple
        // Lưu ý: Logic reset error message nên xử lý ở Bloc
        userEntity: userEntity ?? this.userEntity,
        banReason: banReason,
        isFormLoading: isFormLoading ?? this.isFormLoading,
      );

  @override
  List<Object?> get props => [status, errorMessage, userEntity, banReason, isFormLoading];
}