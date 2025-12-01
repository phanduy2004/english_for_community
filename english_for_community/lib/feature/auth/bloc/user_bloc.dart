import 'dart:async';
import 'package:english_for_community/core/repository/user_repository.dart';
import 'package:english_for_community/feature/auth/bloc/user_event.dart';
import 'package:english_for_community/feature/auth/bloc/user_state.dart';
import 'package:bloc/bloc.dart';
import '../../../core/api/token_storage.dart';
import '../../../core/repository/auth_repository.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final AuthRepository authRepository;
  final UserRepository userRepository;

  UserBloc({required this.authRepository, required this.userRepository})
      : super(UserState.initial()) {
    on<LoginEvent>(onLoginEvent);
    on<GetProfileEvent>(onGetProfileEvent);
    on<DeleteAccountEvent>(onDeleteAccountEvent);
    on<UpdateProfileEvent>(onUpdateProfileEvent);
    on<CheckAuthStatusEvent>(onCheckAuthStatusEvent);
    on<SignOutEvent>(onSignOutEvent);
    on<ForceLogoutEvent>(_onForceLogoutEvent);
    on<ClearUserDataEvent>(_onClearUserDataEvent);
    on<SignUpEvent>(onSignUpEvent);
    on<VerifyOtpEvent>(onVerifyOtpEvent);
    on<ResendOtpEvent>(onResendOtpEvent);
    on<RequestForgotPasswordEvent>(onRequestForgotPasswordEvent);
    on<ResetPasswordEvent>(onResetPasswordEvent);
    on<RefreshTokenEvent>(onRefreshTokenEvent);
  }
  Future<void> onRequestForgotPasswordEvent(RequestForgotPasswordEvent event, Emitter<UserState> emit) async {
    emit(state.copyWith(isFormLoading: true, errorMessage: null));

    final result = await authRepository.requestPasswordReset(event.email);

    result.fold(
          (failure) {
        emit(state.copyWith(
          isFormLoading: false,
          status: UserStatus.error,
          errorMessage: failure.message,
        ));
      },
          (_) {
        // Thành công: Chuyển sang trạng thái OTP_REQUIRED tương tự signup
        emit(state.copyWith(
          isFormLoading: false,
          status: UserStatus.otpRequired,
          errorMessage: event.email, // Lưu email để dùng sau
        ));
      },
    );
  }

  // 🔥 THÊM: Xử lý Reset Password (kết hợp verify OTP)
  Future<void> onResetPasswordEvent(ResetPasswordEvent event, Emitter<UserState> emit) async {
    emit(state.copyWith(isFormLoading: true, errorMessage: null));

    final result = await authRepository.resetPassword(
      event.email,
      event.otp,
      event.newPassword,
    );

    result.fold(
          (failure) {
        emit(state.copyWith(
          isFormLoading: false,
          status: UserStatus.error,
          errorMessage: failure.message,
        ));
      },
          (_) {
        // Thành công: Đẩy về trạng thái unauthenticated với message
        emit(state.copyWith(
          isFormLoading: false,
          status: UserStatus.unauthenticated,
          errorMessage: "Mật khẩu đã được đặt lại thành công! Vui lòng đăng nhập.",
        ));
      },
    );
  }

  // 🔥 THÊM: Xử lý Refresh Token (nếu gọi thủ công)
  Future<void> onRefreshTokenEvent(RefreshTokenEvent event, Emitter<UserState> emit) async {
    emit(state.copyWith(isFormLoading: true, errorMessage: null));

    final result = await authRepository.refreshToken(event.refreshToken);

    result.fold(
          (failure) {
        emit(state.copyWith(
          isFormLoading: false,
          status: UserStatus.error,
          errorMessage: failure.message,
        ));
      },
          (newAccessToken) {
        // Thành công: Có thể cập nhật state nếu cần, ví dụ giữ authenticated
        emit(state.copyWith(
          isFormLoading: false,
          // Không thay đổi status chính, chỉ reset error
          errorMessage: null,
        ));
      },
    );
  }
  Future<void> onSignUpEvent(SignUpEvent event, Emitter<UserState> emit) async {
    emit(state.copyWith(isFormLoading: true, errorMessage: null));

    final result = await authRepository.register(
      username: event.username,
      email: event.email,
      password: event.password,
      fullName: event.fullName,
      phone: event.phone,
      dateOfBirth: event.dateOfBirth,
    );

    result.fold(
          (failure) {
        emit(state.copyWith(
          isFormLoading: false,
          status: UserStatus.error,
          errorMessage: failure.message,
        ));
      },
          (_) {
        // Thành công: Chuyển sang trạng thái OTP_REQUIRED và lưu email tạm thời vào errorMessage
        // (Đây là một cách để truyền data giữa các state khi không dùng field riêng)
        emit(state.copyWith(
          isFormLoading: false,
          status: UserStatus.otpRequired,
          errorMessage: event.email,
        ));
      },
    );
  }

  // 🔥 HÀM MỚI: Xử lý Xác thực OTP (Verify)
  Future<void> onVerifyOtpEvent(VerifyOtpEvent event, Emitter<UserState> emit) async {
    emit(state.copyWith(isFormLoading: true, errorMessage: null));

    final result = await authRepository.verifyOtp(
      event.email,
      event.otp,
      event.purpose,
    );

    result.fold(
          (failure) {
        emit(state.copyWith(
          isFormLoading: false,
          status: UserStatus.error,
          errorMessage: failure.message,
        ));
      },
          (_) {
        // Xác thực thành công: Đẩy về trạng thái Unauthenticated để GoRouter chuyển về Login
        emit(state.copyWith(
            isFormLoading: false,
            status: UserStatus.unauthenticated,
            errorMessage: "Xác thực email thành công! Vui lòng đăng nhập."
        ));
      },
    );
  }

  // 🔥 HÀM MỚI: Xử lý Gửi lại OTP (Resend)
  Future<void> onResendOtpEvent(ResendOtpEvent event, Emitter<UserState> emit) async {
    // Không cần bật loading vì nó là action nhanh
    final result = await authRepository.resendOtp(event.email);

    result.fold(
          (failure) {
        emit(state.copyWith(
          status: UserStatus.error,
          errorMessage: failure.message,
        ));
      },
          (_) {
        // Gửi lại thành công (Có thể show SnackBar ở UI)
        // Không cần đổi trạng thái, chỉ reset lỗi
        emit(state.copyWith(
          errorMessage: "Mã OTP mới đã được gửi lại.",
        ));
      },
    );
  }
  Future<void> _onForceLogoutEvent(ForceLogoutEvent event, Emitter<UserState> emit) async {
    await TokenStorage.clearAllTokens(); // Xóa token ngay
    emit(state.copyWith(
      status: UserStatus.unauthenticated,
      banReason: event.reason,
      userEntity: null,
    ));
  }
  Future<void> _onClearUserDataEvent(ClearUserDataEvent event, Emitter<UserState> emit) async {
    print("🧹 [UserBloc] Clearing tokens immediately due to Ban.");
    await TokenStorage.clearAllTokens();

    // LƯU Ý QUAN TRỌNG:
    // Không gọi emit(unauthenticated) ở đây.
    // Vì nếu emit, GoRouter sẽ chuyển trang ngay lập tức làm mất Dialog.
  }
  Future<void> onCheckAuthStatusEvent(
      CheckAuthStatusEvent event, Emitter<UserState> emit) async {
    emit(state.copyWith(status: UserStatus.loading));
    final refreshToken = await TokenStorage.readRefreshToken();

    if (refreshToken == null) {
      emit(state.copyWith(status: UserStatus.unauthenticated));
      return;
    }

    var result = await userRepository.getProfile();
    result.fold((l) {
      emit(state.copyWith(
          status: UserStatus.unauthenticated, errorMessage: l.message));
    }, (r) {
      emit(state.copyWith(status: UserStatus.success, userEntity: r));
    });
  }

  Future<void> onSignOutEvent(
      SignOutEvent event, Emitter<UserState> emit) async {
    await TokenStorage.clearAllTokens();
    await authRepository.logout();
    emit(UserState.initial().copyWith(status: UserStatus.unauthenticated));
  }

  Future<void> onDeleteAccountEvent(
      DeleteAccountEvent event, Emitter<UserState> emit) async {
    emit(state.copyWith(status: UserStatus.loading));
    var result = await userRepository.deleteAccount();
    result.fold((l) {
      emit(state.copyWith(status: UserStatus.error, errorMessage: l.message));
    }, (r) {
      emit(state.copyWith(status: UserStatus.unauthenticated));
    });
  }

  Future<void> onUpdateProfileEvent(
      UpdateProfileEvent event, Emitter<UserState> emit) async {
    emit(state.copyWith(status: UserStatus.loading));

    var result = await userRepository.updateProfile(
      fullName: event.fullName,
      username: event.username,
      phone: event.phone,
      dateOfBirth: event.dateOfBirth,
      bio: event.bio,
      avatarFile: event.avatarFile, // Truyền File từ Event
      timezone: event.timezone,
      language: event.language,
      strictCorrection: event.strictCorrection,
      reminder: event.reminder,
      dailyMinutes: event.dailyMinutes,
      cefr: event.cefr,
      goal: event.goal,
    );

    result.fold((l) {
      emit(state.copyWith(status: UserStatus.error, errorMessage: l.message));
    }, (r) {
      emit(state.copyWith(status: UserStatus.success, userEntity: r));
    });
  }

  Future<void> onGetProfileEvent(
      GetProfileEvent event, Emitter<UserState> emit) async {
    emit(state.copyWith(status: UserStatus.loading));
    var result = await userRepository.getProfile();
    result.fold((l) {
      emit(state.copyWith(status: UserStatus.error, errorMessage: l.message));
    }, (r) {
      emit(state.copyWith(status: UserStatus.success, userEntity: r));
    });
  }

  Future<void> onLoginEvent(LoginEvent event, Emitter<UserState> emit) async {
    // 1. Bắt đầu loading form -> Spinner quay
    // 🔥 QUAN TRỌNG: Chỉ bật isFormLoading, KHÔNG đổi status sang loading
    // Điều này ngăn Router chuyển hướng sang màn hình Splash
    emit(state.copyWith(
        isFormLoading: true,
        errorMessage: null // Reset lỗi cũ nếu có
    ));

    // 2. Gọi API
    final result = await authRepository.login(event.email, event.password);

    // 3. Xử lý kết quả
    result.fold(
          (failure) {
        // Thất bại: Tắt spinner, set status error để UI hiện Dialog báo lỗi
        emit(state.copyWith(
            isFormLoading: false,
            status: UserStatus.error,
            errorMessage: failure.message
        ));
      },
          (data) {
        // Thành công: Tắt spinner, set status success để Router chuyển vào App
        emit(state.copyWith(
            isFormLoading: false,
            status: UserStatus.success,
            userEntity: data
        ));
      },
    );
  }

}