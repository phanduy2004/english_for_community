// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get profileAndSettings => 'Hồ sơ & Cài đặt';

  @override
  String get learningPreferences => 'TÙY CHỌN HỌC TẬP';

  @override
  String get dailyTimeGoal => 'Mục tiêu thời gian mỗi ngày';

  @override
  String get dailyLessonGoal => 'Mục tiêu số bài mỗi ngày';

  @override
  String get dailyReminder => 'Nhắc nhở hàng ngày';

  @override
  String get reminderTime => 'Giờ nhắc';

  @override
  String minutesShort(int mins) {
    return '$mins phút';
  }

  @override
  String lessonsShort(int n) {
    return '$n bài';
  }

  @override
  String get setDailyTimeGoal => 'Đặt mục tiêu thời gian';

  @override
  String minutesPerDayOption(int mins) {
    return '$mins phút / ngày';
  }

  @override
  String get setDailyLessonGoal => 'Đặt mục tiêu số bài';

  @override
  String lessonsPerDayOption(int n) {
    return '$n bài / ngày';
  }

  @override
  String get progress => 'TIẾN ĐỘ';

  @override
  String get exerciseHistory => 'Lịch sử bài tập';

  @override
  String get exerciseHistorySubtitle => 'Các lần làm theo kỹ năng';

  @override
  String get generalSettings => 'CÀI ĐẶT CHUNG';

  @override
  String get appLanguage => 'Ngôn ngữ ứng dụng';

  @override
  String get timezone => 'Múi giờ';

  @override
  String get accountAndSecurity => 'TÀI KHOẢN & BẢO MẬT';

  @override
  String get changePassword => 'Đổi mật khẩu';

  @override
  String get exportData => 'Xuất dữ liệu';

  @override
  String get exportDataSubtitle => 'Tải lịch sử học tập';

  @override
  String get signOut => 'Đăng xuất';

  @override
  String get deleteAccount => 'Xóa tài khoản';

  @override
  String get deleteAccountTitle => 'Xóa tài khoản?';

  @override
  String get deleteAccountBody =>
      'Thao tác này không thể hoàn tác. Toàn bộ dữ liệu sẽ bị xóa.';

  @override
  String get cancel => 'Hủy';

  @override
  String get deletePermanently => 'Xóa vĩnh viễn';

  @override
  String get member => 'Thành viên';

  @override
  String get admin => 'Quản trị';

  @override
  String get selectAppLanguage => 'Chọn ngôn ngữ giao diện';

  @override
  String get languageEnglish => 'Tiếng Anh';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get appLanguageFootnote => 'Ngôn ngữ giao diện (lưu trên thiết bị)';

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navMessages => 'Tin nhắn';

  @override
  String get navProgress => 'Tiến độ';

  @override
  String get navProfile => 'Hồ sơ';

  @override
  String get studentChatHubSubtitle => 'Nhóm chat các lớp bạn tham gia';

  @override
  String get studentChatHubSearchHint => 'Tìm lớp học…';

  @override
  String get studentChatHubFilterAll => 'Tất cả';

  @override
  String get studentChatHubFilterUnread => 'Chưa đọc';

  @override
  String get studentChatHubOverviewTitle => 'Kết nối lớp học';

  @override
  String get studentChatHubOverviewBody =>
      'Trò chuyện với bạn cùng lớp và giáo viên trong từng nhóm lớp.';

  @override
  String get studentChatHubSectionConversations => 'Cuộc trò chuyện';

  @override
  String studentChatHubUnreadCount(int count) {
    return '$count chưa đọc';
  }

  @override
  String studentChatHubClassCount(int count) {
    return '$count lớp';
  }

  @override
  String get studentChatHubEmptyTitle => 'Chưa có tin nhắn';

  @override
  String get studentChatHubEmptyBody =>
      'Các lớp bạn tham gia sẽ hiển thị ở đây.';

  @override
  String get studentChatHubSearchEmptyTitle => 'Không tìm thấy';

  @override
  String get studentChatHubSearchEmptyBody =>
      'Thử từ khóa khác hoặc xóa bộ lọc.';

  @override
  String get loginWelcomeBack => 'Chào mừng trở lại!';

  @override
  String get loginSubtitle => 'Nhập thông tin để tiếp tục.';

  @override
  String get labelEmail => 'Email';

  @override
  String get loginEmailOrUsername => 'Email hoặc tên đăng nhập';

  @override
  String get hintLoginEmailOrUsername => 'Nhập email hoặc tên đăng nhập';

  @override
  String get labelPassword => 'Mật khẩu';

  @override
  String get hintEmail => 'ten@email.com';

  @override
  String get hintPassword => 'Nhập mật khẩu của bạn';

  @override
  String get rememberMe => 'Ghi nhớ đăng nhập';

  @override
  String get forgotPasswordLink => 'Quên mật khẩu?';

  @override
  String get signIn => 'Đăng nhập';

  @override
  String get orDivider => 'HOẶC';

  @override
  String get continueWithGoogle => 'Tiếp tục với Google';

  @override
  String get noAccountPrompt => 'Chưa có tài khoản? ';

  @override
  String get signUp => 'Đăng ký';

  @override
  String get dictionary => 'Từ điển';

  @override
  String get close => 'Đóng';

  @override
  String get missingInfo => 'Thiếu thông tin';

  @override
  String get enterEmailPassword => 'Nhập email và mật khẩu.';

  @override
  String get loginFailed => 'Đăng nhập thất bại';

  @override
  String get errorTitle => 'Lỗi';

  @override
  String get fillRequiredFields => 'Vui lòng điền đủ các trường bắt buộc (*).';

  @override
  String get passwordErrorTitle => 'Lỗi mật khẩu';

  @override
  String get passwordMismatch => 'Mật khẩu xác nhận không khớp.';

  @override
  String get registerTitle => 'Tạo tài khoản';

  @override
  String get otpVerifyTitle => 'Xác minh email';

  @override
  String get forgotPasswordTitle => 'Quên mật khẩu';

  @override
  String get resetPasswordTitle => 'Đặt lại mật khẩu';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get loading => 'Đang tải...';

  @override
  String get practiceFallbackTitle => 'Luyện tập';

  @override
  String get barrierDismiss => 'Đóng';

  @override
  String get weeklyActivity => 'Hoạt động tuần';

  @override
  String get sameChartBadge => 'cùng biểu đồ Tiến độ';

  @override
  String get couldNotLoadStudyChart => 'Không tải được biểu đồ học';

  @override
  String weeklySummaryLine(String minutes, int done, int goal) {
    return '$minutes tuần này · $done / $goal bài hôm nay';
  }

  @override
  String get viewProgress => 'Xem tiến độ';

  @override
  String get onboardingSkip => 'Bỏ qua';

  @override
  String get onboardingSlide1Title => 'Lộ trình học cá nhân';

  @override
  String get onboardingSlide1Subtitle =>
      'Kế hoạch phù hợp mục tiêu, trình độ CEFR và lịch của bạn.';

  @override
  String get onboardingSlide2Title => 'Gia sư AI cho Nói & Viết';

  @override
  String get onboardingSlide2Subtitle =>
      'Phản hồi phát âm thời gian thực & chấm theo tiêu chí.';

  @override
  String get onboardingSlide3Title => 'Động lực với phần thưởng';

  @override
  String get onboardingSlide3Subtitle =>
      'Chuỗi ngày, XP và huy hiệu giúp bạn duy trì mỗi ngày.';

  @override
  String get getStarted => 'Bắt đầu';

  @override
  String get signInAction => 'Đăng nhập';

  @override
  String get readingPracticeTitle => 'Luyện đọc';

  @override
  String get speakingModeReadAloud => 'Đọc to';

  @override
  String get speakingModeShadowing => 'Shadowing';

  @override
  String get speakingModePronunciation => 'Phát âm';

  @override
  String get speakingModeFreeSpeaking => 'Nói tự do';

  @override
  String get difficultyBeginner => 'Cơ bản';

  @override
  String get difficultyIntermediate => 'Trung bình';

  @override
  String get difficultyAdvanced => 'Nâng cao';

  @override
  String sentenceIndex(int current, int total) {
    return 'Câu $current / $total';
  }

  @override
  String get finishPractice => 'Hoàn thành';

  @override
  String get nextSentence => 'Câu tiếp theo';

  @override
  String get microNotReady =>
      'Micro / nhận dạng giọng nói chưa sẵn sàng. Hãy cấp quyền và thử lại.';

  @override
  String get tryAgain => 'Thử lại';

  @override
  String get microInfoBanner =>
      'Micro / nhận dạng giọng nói chưa sẵn sàng. Cấp quyền và thử lại.';

  @override
  String get sampleListen => 'Nghe mẫu';

  @override
  String get sampleListenSub => 'Sample';

  @override
  String get yourTurn => 'Nói của bạn';

  @override
  String get yourTurnSub => 'Your turn';

  @override
  String get listeningForSpeech =>
      'Đang nghe… Chạm nút đỏ để dừng và chấm điểm.';

  @override
  String get submittingAnalysis => 'Đang gửi và phân tích…';

  @override
  String get tapMicToRecord =>
      'Chạm micro, đọc to cả câu rồi chạm lại để dừng.';

  @override
  String get yourSpeechSection => 'LỜI BẠN NÓI';

  @override
  String get transcriptPlaceholder => 'Sẽ hiện ở đây khi bạn nói…';

  @override
  String get accuracyLabel => 'Độ chính xác';

  @override
  String get levelLabel => 'Cơ bản';

  @override
  String get speakingPracticeTitle => 'Luyện nói';

  @override
  String get socketSessionEnded => 'Phiên đã kết thúc. Vui lòng đăng nhập lại.';

  @override
  String get socketKicked => 'Bạn đã bị đăng xuất từ thiết bị khác.';

  @override
  String get adminRetry => 'Thử lại';

  @override
  String get adminDashboard => 'Bảng quản trị';

  @override
  String get filterEasy => 'dễ';

  @override
  String get filterMedium => 'vừa';

  @override
  String get filterHard => 'khó';

  @override
  String get vocabularyTitle => 'Từ vựng';

  @override
  String get listeningTitle => 'Nghe';

  @override
  String get writingTitle => 'Viết';

  @override
  String get progressReportTitle => 'Tiến độ';

  @override
  String get exerciseHistoryTitle => 'Lịch sử bài tập';

  @override
  String get editProfileTitle => 'Sửa hồ sơ';

  @override
  String get changePasswordTitle => 'Đổi mật khẩu';

  @override
  String get notificationsTitle => 'Thông báo';

  @override
  String get aiAssistantTitle => 'Trợ lý AI';

  @override
  String get save => 'Lưu';

  @override
  String get delete => 'Xóa';

  @override
  String get edit => 'Sửa';

  @override
  String get search => 'Tìm';

  @override
  String get noData => 'Không có dữ liệu';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Có';

  @override
  String get no => 'Không';

  @override
  String get next => 'Tiếp';

  @override
  String get back => 'Quay lại';

  @override
  String get done => 'Xong';

  @override
  String get accountSuspended => 'Tài khoản bị khóa';

  @override
  String get sessionTerminated => 'Phiên của bạn đã bị kết thúc.';

  @override
  String get reasonLabel => 'Lý do:';

  @override
  String get adminConsoleTitle => 'Bảng quản trị';

  @override
  String get adminShellAppName => 'Quản trị';

  @override
  String get adminShellNavGroup => 'Tổng quan';

  @override
  String get adminShellOpsGroup => 'Vận hành';

  @override
  String get adminShellContentGroup => 'Nội dung';

  @override
  String get adminShellDesktopTitle => 'Dùng trình duyệt trên máy tính';

  @override
  String get adminShellDesktopBody =>
      'Bảng quản trị được tối ưu cho màn hình từ 768px trở lên. Hãy mở trên laptop hoặc máy tính để có trải nghiệm tốt nhất.';

  @override
  String get adminShellCollapseSidebar => 'Thu gọn thanh bên';

  @override
  String get adminShellExpandSidebar => 'Mở rộng thanh bên';

  @override
  String get adminNavSubmissions => 'Bài nộp';

  @override
  String get adminNavOps => 'Trung tâm vận hành';

  @override
  String get adminNavOpsSub => 'Kiểm duyệt, xuất dữ liệu, quyền';

  @override
  String get adminNavReleases => 'Phát hành app';

  @override
  String get adminNavReleasesSub => 'Duyệt, lên lịch, phát hành';

  @override
  String get adminContentItemCount => 'chủ đề';

  @override
  String get adminListeningDictation => 'Nghe chép';

  @override
  String get adminListeningDictationSub => 'Nghe chép chính tả (cues)';

  @override
  String get adminListeningComprehension => 'Nghe hiểu';

  @override
  String get adminListeningComprehensionSub => 'Trắc nghiệm nghe hiểu';

  @override
  String get adminOverviewTitle => 'Tổng quan';

  @override
  String get adminUserManagementTitle => 'Quản lý người dùng';

  @override
  String get adminReportManagementTitle => 'Quản lý báo cáo';

  @override
  String get adminActivityHistoryTitle => 'Lịch sử bài nộp';

  @override
  String get adminSearchUsersHint => 'Tìm theo tên hoặc email…';

  @override
  String get adminSearchReportsHint => 'Tìm theo tiêu đề hoặc người gửi…';

  @override
  String get adminNoUsersFound => 'Không tìm thấy người dùng';

  @override
  String get adminNoReportsFound => 'Không có báo cáo ở trạng thái này';

  @override
  String get adminUsersTrash => 'Thùng rác';

  @override
  String adminUserRestored(String name) {
    return 'Đã khôi phục $name';
  }

  @override
  String get adminReportStatusUpdated => 'Đã cập nhật trạng thái';

  @override
  String get adminActionSuccess => 'Thao tác thành công';

  @override
  String get adminReleaseConfirmCodeInvalid => 'Mã xác nhận không đúng';

  @override
  String get superAdminRole => 'Super Admin';

  @override
  String get managementSection => 'Quản lý';

  @override
  String get contentManagerTile => 'Quản lý nội dung';

  @override
  String get contentManagerSub => 'Đề bài, Reading & Listening';

  @override
  String get reportsMenuTitle => 'Báo cáo';

  @override
  String get reportsMenuSub => 'Phản hồi sự cố';

  @override
  String get usersMenuTitle => 'Người dùng';

  @override
  String get usersMenuSub => 'Danh sách user';

  @override
  String get submissionsMetric => 'Bài nộp';

  @override
  String get aiCostMetric => 'Chi phí AI (ước tính)';

  @override
  String get reportsMetric => 'Báo cáo';

  @override
  String get activeUsersMetric => 'User hoạt động';

  @override
  String get activityChart => 'Biểu đồ hoạt động';

  @override
  String get swipeToView => 'Vuốt để xem';

  @override
  String get appTagline => 'Học tiếng Anh cùng AI';

  @override
  String get alreadyHaveAccount => 'Đã có tài khoản? ';

  @override
  String get continueAction => 'Tiếp tục';

  @override
  String get appNameBrand => 'E4C';

  @override
  String streakDays(int n) {
    return 'Chuỗi $n ngày';
  }

  @override
  String get fullProgressStats => 'Xem đầy đủ tiến độ & thống kê';

  @override
  String get noStudyWeek => 'Chưa có phút học tuần này — hãy bắt đầu một bài!';

  @override
  String get speakingDescReadAloud => 'Đọc đoạn văn rõ ràng.';

  @override
  String get speakingDescShadowing => 'Nghe và nhắc lại ngay.';

  @override
  String get speakingDescPronunciation => 'Luyện phát âm từng âm tiết.';

  @override
  String get speakingDescFreeSpeaking => 'Trò chuyện tự do về mọi chủ đề.';

  @override
  String get speakingSelectModeTitle => 'Chọn chế độ luyện';

  @override
  String get speakingSelectModeSubtitle => 'Chọn cách để bắt đầu luyện nói.';

  @override
  String get speakingMasteryTitle => 'Luyện nói thành thạo';

  @override
  String get speakingMasterySubtitle =>
      'Luyện phát âm và độ trôi chảy với phản hồi AI.';

  @override
  String get aiPoweredBadge => 'Có AI';

  @override
  String get searchTopicHint => 'Tìm chủ đề, mã bài…';

  @override
  String get loadDataFailed => 'Không tải được dữ liệu';

  @override
  String get noSpeakingLessonsFound => 'Chưa có bài luyện nói';

  @override
  String get bestScoreLabel => 'Điểm cao nhất';

  @override
  String get noAttemptsYet => 'Chưa có lần làm';

  @override
  String get reviewAction => 'Xem lại';

  @override
  String get retakeAction => 'Làm lại';

  @override
  String get resumeAction => 'Tiếp tục';

  @override
  String get startAction => 'Bắt đầu';

  @override
  String percentDone(int pct) {
    return 'Đã hoàn thành $pct%';
  }

  @override
  String lessonMetaLine(int n, String topic) {
    return '$n câu · Chủ đề: $topic';
  }

  @override
  String get topicDailyLife => 'Đời sống hằng ngày';

  @override
  String get settings => 'Cài đặt';

  @override
  String get speechNotAvailableSnack =>
      'Chưa bật được nhận dạng giọng nói. Hãy cấp quyền micro và (iOS) quyền Speech Recognition.';

  @override
  String get micOpenFailedSnack =>
      'Không mở được micro. Trên Android cần dịch vụ nhận dạng của Google; hãy thử cài/cập nhật Google app và ngôn ngữ tiếng Anh.';

  @override
  String micStartError(String error) {
    return 'Lỗi khi bật micro: $error';
  }

  @override
  String get listeningPracticeTitle => 'Luyện nghe';

  @override
  String get listeningHeaderTitle => 'Nghe chép chính tả';

  @override
  String get listeningHeaderSubtitle =>
      'Rèn nghe và chính tả với bài tập ngắn mỗi ngày.';

  @override
  String get listeningPremiumBadge => 'Nội dung nổi bật';

  @override
  String get listeningSearchHint => 'Tìm bài, chủ đề hoặc mã…';

  @override
  String get listeningDictation => 'Chép chính tả';

  @override
  String get noReadingArticlesFound => 'Chưa có bài đọc';

  @override
  String get noListeningLessonsFound => 'Chưa có bài nghe';

  @override
  String questionsCount(int n) {
    return '$n câu hỏi';
  }

  @override
  String progressPercentLabel(int pct) {
    return 'Tiến độ: $pct%';
  }

  @override
  String get completedBadge => 'Hoàn thành';

  @override
  String get readingSkillsHeaderTitle => 'Kỹ năng đọc';

  @override
  String get readingSkillsHeaderSubtitle =>
      'Cải thiện đọc hiểu và từ vựng qua bài báo chọn lọc.';

  @override
  String get readingDailyArticlesBadge => 'Bài mỗi ngày';

  @override
  String get couldNotLoadExerciseHistory => 'Không tải được lịch sử bài tập';

  @override
  String get skillTabAll => 'Tất cả';

  @override
  String get skillTabReading => 'Đọc';

  @override
  String get skillTabListening => 'Nghe';

  @override
  String get skillTabSpeaking => 'Nói';

  @override
  String get skillTabWriting => 'Viết';

  @override
  String get historyEmptyRangeTitle => 'Không có bài trong khoảng này';

  @override
  String get historyEmptyRangeHint => 'Thử đổi khoảng ngày hoặc tab kỹ năng';

  @override
  String get dateRangeLabel => 'Khoảng ngày';

  @override
  String readingScorePercent(String score) {
    return 'Điểm: $score%';
  }

  @override
  String readingMinutesShort(int n) {
    return '$n phút';
  }

  @override
  String readingQuizCount(int n) {
    return '$n câu hỏi';
  }

  @override
  String get unknownLevel => 'Không rõ';

  @override
  String get registerHeroTitle => 'Tạo tài khoản';

  @override
  String get registerHeroSubtitle => 'Điền thông tin để bắt đầu học.';

  @override
  String get registerAccountTypeLabel => 'Loại tài khoản';

  @override
  String get registerAccountTypeStudent => 'Học sinh';

  @override
  String get registerAccountTypeTeacher => 'Giáo viên';

  @override
  String get registerAccountTypeTeacherHint =>
      'Sau khi đăng ký bạn có thể tạo lớp và quản lý bài kiểm tra ngay.';

  @override
  String get labelFullName => 'Họ và tên *';

  @override
  String get hintFullName => 'Nguyễn Văn A';

  @override
  String get labelUsername => 'Tên đăng nhập *';

  @override
  String get hintUsername => 'username123';

  @override
  String get labelPhone => 'Số điện thoại';

  @override
  String get hintPhoneShort => '0912…';

  @override
  String get labelDateOfBirth => 'Ngày sinh';

  @override
  String get hintDatePlaceholder => 'DD/MM/YYYY';

  @override
  String get labelConfirmPassword => 'Xác nhận mật khẩu *';

  @override
  String get hintPasswordMask => '••••••';

  @override
  String get registerButton => 'Đăng ký';

  @override
  String get registrationFailedTitle => 'Đăng ký thất bại';

  @override
  String get enterEmailRequired => 'Vui lòng nhập email.';

  @override
  String get otpSixDigitsRequired => 'Vui lòng nhập mã 6 số.';

  @override
  String get forgotHeroTitle => 'Đặt lại mật khẩu';

  @override
  String get forgotHeroSubtitle => 'Nhập email để nhận mã xác minh.';

  @override
  String get sendButton => 'Gửi';

  @override
  String get enterVerificationCode => 'Nhập mã xác minh';

  @override
  String get otpSentPrefix => 'Mã 6 số đã gửi đến\n';

  @override
  String get otpSentSuffix => '. Vui lòng kiểm tra hộp thư.';

  @override
  String resendCooldown(int seconds) {
    return 'Gửi lại sau $seconds giây';
  }

  @override
  String get verifyButton => 'Xác minh';

  @override
  String get verificationFailedTitle => 'Xác minh thất bại';

  @override
  String get resendingCodeSnack => 'Đang gửi lại mã…';

  @override
  String get otpSentEmailSnack => 'Đã gửi OTP tới email của bạn.';

  @override
  String get didNotReceiveCode => 'Chưa nhận được mã? ';

  @override
  String get resendAction => 'Gửi lại';

  @override
  String get setNewPasswordTitle => 'Mật khẩu mới';

  @override
  String get setNewPasswordSubtitle => 'Nhập mật khẩu mới cho tài khoản.';

  @override
  String get labelNewPassword => 'Mật khẩu mới';

  @override
  String get hintEnterNewPassword => 'Nhập mật khẩu mới…';

  @override
  String get labelConfirmNewPassword => 'Xác nhận mật khẩu mới';

  @override
  String get hintConfirmNewPassword => 'Nhập lại mật khẩu mới…';

  @override
  String get resetPasswordButton => 'Đặt lại mật khẩu';

  @override
  String get resetFailedTitle => 'Đặt lại thất bại';

  @override
  String get enterBothPasswords => 'Vui lòng nhập đủ hai ô mật khẩu.';

  @override
  String get passwordsDoNotMatchShort => 'Hai mật khẩu không khớp.';

  @override
  String get passwordMinSixChars => 'Mật khẩu cần ít nhất 6 ký tự.';

  @override
  String get homeNoData => 'Chưa có dữ liệu';

  @override
  String homeGreeting(String name) {
    return 'Chào $name 👋';
  }

  @override
  String get homeReadySubtitle => 'Sẵn sàng học tiếp?';

  @override
  String get homeDailyGoal => 'Mục tiêu hôm nay';

  @override
  String homeDailyLessonsLine(int done, int goal) {
    return '$done / $goal bài đã hoàn thành';
  }

  @override
  String get homeTodaysLessons => 'Bài học hôm nay';

  @override
  String get homeSeeAll => 'Xem tất cả';

  @override
  String get homeShowLess => 'Thu gọn';

  @override
  String get homeLessonListeningTitle => 'Luyện nghe';

  @override
  String get homeLessonListeningSubtitle => 'Hội thoại hằng ngày • 15 phút';

  @override
  String get homeLessonReadingTitle => 'Đọc hiểu';

  @override
  String get homeLessonReadingSubtitle => 'Truyện ngắn • 20 phút';

  @override
  String get homeLessonVocabTitle => 'Từ vựng';

  @override
  String get homeLessonVocabSubtitle => 'Từ mới • 10 phút';

  @override
  String get homeLessonSpeakingTitle => 'Luyện nói';

  @override
  String get homeLessonSpeakingSubtitle => 'Phát âm • 25 phút';

  @override
  String get homeLessonWritingTitle => 'Luyện viết';

  @override
  String get homeLessonWritingSubtitle => 'Chọn đề • 15 phút';

  @override
  String get homeQuickAccess => 'Lối tắt';

  @override
  String get homeQuickFavorites => 'Yêu thích';

  @override
  String get homeQuickFlashcards => 'Flashcard';

  @override
  String get homeQuickStats => 'Thống kê';

  @override
  String get statStreak => 'Chuỗi';

  @override
  String get statPoints => 'Điểm';

  @override
  String get statLevelLabel => 'Cấp';

  @override
  String get homeLoadFailed => 'Không tải được dữ liệu';

  @override
  String get homePleaseSignIn => 'Vui lòng đăng nhập';

  @override
  String get markAllRead => 'Đánh dấu đã đọc';

  @override
  String get timeJustNow => 'Vừa xong';

  @override
  String timeMinutesAgo(int n) {
    return '$n phút trước';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n giờ trước';
  }

  @override
  String get notificationsEmptyTitle => 'Chưa có thông báo';

  @override
  String get notificationsEmptyBody => 'Thông báo sẽ hiển thị tại đây.';

  @override
  String get notificationAccept => 'Chấp nhận';

  @override
  String get notificationDecline => 'Từ chối';

  @override
  String get notificationInviteAccepted => 'Đã chấp nhận lời mời';

  @override
  String get notificationInviteDeclined => 'Đã từ chối lời mời';

  @override
  String get notificationJoinApproved => 'Đã duyệt yêu cầu vào lớp';

  @override
  String get notificationJoinDeclined => 'Đã từ chối yêu cầu vào lớp';

  @override
  String get aiAssistantEmptyPrompt =>
      'Hỏi mình bất cứ điều gì về tiến độ học của bạn.';

  @override
  String get aiChatPlaceholder => 'Nhập câu hỏi…';

  @override
  String get listeningChooseSubtitle => 'Chọn cách luyện tai hôm nay.';

  @override
  String get listeningModeComprehensionTitle => 'Nghe hiểu';

  @override
  String get listeningModeDictationTileDesc =>
      'Nghe và gõ đúng những gì bạn nghe được.';

  @override
  String get listeningModeComprehensionDesc =>
      'Nghe audio và trả lời trắc nghiệm.';

  @override
  String get vocabReviewSessionTitle => 'Ôn tập';

  @override
  String get tapToSeeMeaning => 'Chạm để xem nghĩa';

  @override
  String get showAnswerButton => 'Xem đáp án';

  @override
  String get srsHard => 'Khó';

  @override
  String get srsGood => 'Ổn';

  @override
  String get srsEasy => 'Dễ';

  @override
  String get vocabSessionCompleteTitle => 'Hoàn thành phiên!';

  @override
  String get vocabSessionCompleteBody => 'Bạn đã ôn hết từ trong lượt này.';

  @override
  String get backToHome => 'Về trang chủ';

  @override
  String get genericLoadError => 'Đã có lỗi xảy ra';

  @override
  String get changePasswordSubtitle => 'Cập nhật mật khẩu để bảo vệ tài khoản.';

  @override
  String get labelCurrentPassword => 'Mật khẩu hiện tại';

  @override
  String get hintCurrentPassword => 'Nhập mật khẩu hiện tại';

  @override
  String get hintReenterNewPassword => 'Nhập lại mật khẩu mới';

  @override
  String get fillAllFields => 'Vui lòng điền đủ các ô';

  @override
  String get newPasswordMismatchToast => 'Mật khẩu mới không khớp';

  @override
  String get saveChanges => 'Lưu thay đổi';

  @override
  String get learningProgressTitle => 'Tiến độ học';

  @override
  String get reportIssueTooltip => 'Báo lỗi / góp ý';

  @override
  String get failedToLoadProfile => 'Không tải được hồ sơ người dùng.';

  @override
  String get failedToLoadData => 'Không tải được dữ liệu';

  @override
  String get pleaseTryAgainLater => 'Vui lòng thử lại sau';

  @override
  String get retry => 'Thử lại';

  @override
  String get progressOverview => 'Tổng quan';

  @override
  String get progressPerformanceMetrics => 'Chỉ số hiệu suất';

  @override
  String get progressFilterDay => 'Ngày';

  @override
  String get progressFilterWeek => 'Tuần';

  @override
  String get progressFilterMonth => 'Tháng';

  @override
  String get progressPeriodToday => 'Hôm nay';

  @override
  String get progressPeriodThisWeek => 'Tuần này';

  @override
  String get progressPeriodThisMonth => 'Tháng này';

  @override
  String progressDurationHm(int h, int m) {
    return '$h giờ $m phút';
  }

  @override
  String progressGoalLine(String time) {
    return 'Mục tiêu: $time';
  }

  @override
  String progressPercentCompleted(int pct) {
    return 'Hoàn thành $pct%';
  }

  @override
  String get progressDetailedStats => 'Thống kê chi tiết';

  @override
  String get progressStatVocabulary => 'Từ vựng';

  @override
  String get progressStatReading => 'Đọc';

  @override
  String get progressStatListening => 'Nghe';

  @override
  String get progressStatLessons => 'Bài học';

  @override
  String get progressStatWriting => 'Viết';

  @override
  String get progressStatSpeaking => 'Nói';

  @override
  String get progressLeaderboard => 'Bảng xếp hạng';

  @override
  String get progressActivity => 'Hoạt động';

  @override
  String get leaderboardLoadFailed => 'Không tải được bảng xếp hạng';

  @override
  String get leaderboardEmpty => 'Chưa có dữ liệu bảng xếp hạng';

  @override
  String get statDetailVocab => 'Chi tiết từ vựng';

  @override
  String get statDetailReading => 'Chi tiết bài đọc';

  @override
  String get statDetailDictation => 'Chi tiết nghe / chép chính tả';

  @override
  String get statDetailSpeaking => 'Chi tiết luyện nói';

  @override
  String get statDetailWriting => 'Chi tiết bài viết';

  @override
  String get statDetailLessons => 'Chi tiết bài học đã hoàn thành';

  @override
  String get statDetailGeneric => 'Chi tiết tiến độ';

  @override
  String statDetailPeriodLog(String period) {
    return 'Nhật ký $period.';
  }

  @override
  String statDetailReadingSubtitle(String score, String date) {
    return 'Độ chính xác: $score% · $date';
  }

  @override
  String statDetailScoreDateSubtitle(String score, String date) {
    return 'Điểm: $score% · $date';
  }

  @override
  String statDetailWritingSubtitle(String score, String date) {
    return 'Band: $score · $date';
  }

  @override
  String statDetailDateOnly(Object date) {
    return '$date';
  }

  @override
  String statDetailDateLine(String date) {
    return 'Ngày: $date';
  }

  @override
  String get statDetailLessonsGroupOther => 'Khác';

  @override
  String get statDetailNoData => 'Không có dữ liệu.';

  @override
  String get reportDialogTitle => 'Phản hồi & hỗ trợ';

  @override
  String get reportDialogSubtitle =>
      'Cho chúng tôi biết lỗi hoặc góp ý của bạn.';

  @override
  String get reportTypeLabel => 'Loại báo cáo';

  @override
  String get reportTypeBug => 'Báo lỗi';

  @override
  String get reportTypeFeature => 'Đề xuất tính năng';

  @override
  String get reportTypeImprovement => 'Cải thiện';

  @override
  String get reportTypeOther => 'Khác';

  @override
  String get reportTitleLabel => 'Tiêu đề';

  @override
  String get reportTitleHint => 'Tóm tắt ngắn vấn đề';

  @override
  String get reportDescriptionLabel => 'Mô tả';

  @override
  String get reportDescriptionHint => 'Mô tả chi tiết…';

  @override
  String get reportAttachmentsOptional => 'Đính kèm (tuỳ chọn)';

  @override
  String get submitReport => 'Gửi báo cáo';

  @override
  String get reportFillTitleDescription => 'Vui lòng nhập tiêu đề và mô tả.';

  @override
  String get reportSubmissionFailed => 'Gửi không thành công';

  @override
  String get reportThankYou => 'Cảm ơn bạn!';

  @override
  String get reportReceivedBody =>
      'Chúng tôi đã nhận báo cáo và sẽ xem xét sớm.';

  @override
  String get reportUploadScreenshots => 'Chạm để tải ảnh chụp màn hình';

  @override
  String get reportSupportedFormats => 'Định dạng: JPEG, PNG';

  @override
  String get vocabularyScreenTitle => 'Từ vựng';

  @override
  String get vocabTutorialTooltip => 'Hướng dẫn';

  @override
  String get vocabSearchDictionaryTooltip => 'Tra từ điển';

  @override
  String get vocabTabRecently => 'Gần đây';

  @override
  String get vocabTabLearning => 'Đang học';

  @override
  String get vocabTabSaved => 'Đã lưu';

  @override
  String get vocabReviewNowFab => 'Ôn ngay';

  @override
  String get vocabNoRecentWords => 'Chưa có từ tra gần đây.';

  @override
  String get vocabLearningEmpty => 'Bắt đầu học để xây bộ thẻ của bạn.';

  @override
  String get vocabSavedEmpty => 'Lưu từ để xem lại sau.';

  @override
  String vocabErrorWithMessage(String message) {
    return 'Lỗi: $message';
  }

  @override
  String vocabNoDetailsForWord(String word) {
    return 'Không tìm thấy chi tiết cho \"$word\"';
  }

  @override
  String get vocabUnknownError => 'Lỗi không xác định';

  @override
  String get vocabReviewNowBadge => 'Ôn ngay';

  @override
  String vocabReviewOnDate(String date) {
    return 'Ôn: $date';
  }

  @override
  String vocabLevelShort(int level) {
    return 'Cấp $level';
  }

  @override
  String get wordNoDefinition => 'Chưa có nghĩa';

  @override
  String get wordUnknownType => 'Chưa rõ loại từ';

  @override
  String get profileUpdatedSuccess => 'Đã cập nhật hồ sơ';

  @override
  String get changePhotoHint => 'Chạm để đổi ảnh';

  @override
  String get sectionPublicInfo => 'Thông tin công khai';

  @override
  String get sectionPrivateDetails => 'Thông tin riêng';

  @override
  String get sectionSystemInfo => 'Hệ thống';

  @override
  String get labelBio => 'Giới thiệu';

  @override
  String get hintBio => 'Giới thiệu ngắn về bạn…';

  @override
  String get labelGender => 'Giới tính';

  @override
  String get genderMale => 'Nam';

  @override
  String get genderFemale => 'Nữ';

  @override
  String get genderOther => 'Khác';

  @override
  String get labelBirthday => 'Sinh nhật';

  @override
  String get hintSelectDate => 'Chọn ngày';

  @override
  String get labelRole => 'Vai trò';

  @override
  String get labelUserId => 'ID người dùng';

  @override
  String get fieldRequired => 'Bắt buộc';

  @override
  String get copiedToClipboard => 'Đã sao chép';

  @override
  String get selectPlaceholder => 'Chọn';

  @override
  String get dictQuickSearchTitle => 'Tra nhanh';

  @override
  String get dictDictionaryTitle => 'Từ điển';

  @override
  String get dictSearchHint => 'Tra từ (vd. serendipity)…';

  @override
  String get dictStartTyping => 'Gõ để bắt đầu tra';

  @override
  String get dictNoResults => 'Không có kết quả';

  @override
  String get dictDefinitions => 'Nghĩa';

  @override
  String get dictSeeAlso => 'Xem thêm';

  @override
  String get dictTooltipStartLearning => 'Bắt đầu học';

  @override
  String get dictTooltipSaveWord => 'Lưu từ';

  @override
  String wordSavedSnackbar(String word) {
    return 'Đã lưu \"$word\"';
  }

  @override
  String wordAddedToLearningQueue(String word) {
    return 'Đã thêm \"$word\" vào hàng học!';
  }

  @override
  String get dictNoDefinitionAvailable => 'Chưa có định nghĩa';

  @override
  String get accountSuspendedTitle => 'Tài khoản bị khóa';

  @override
  String get accountSessionTerminated => 'Phiên của bạn đã bị kết thúc.';

  @override
  String get suspensionReasonLabel => 'Lý do:';

  @override
  String get agreeAndLogout => 'Đồng ý & đăng xuất';

  @override
  String get submissionHistoryTitle => 'Lịch sử nộp bài';

  @override
  String get writingHistoryLoadFailed => 'Không tải được lịch sử';

  @override
  String get writingNoHistoryForTopic => 'Chưa có bài nộp cho chủ đề này.';

  @override
  String get dateUnknown => 'Không rõ ngày';

  @override
  String get writingTaskDefaultTitle => 'Bài viết';

  @override
  String wordCountN(int n) {
    return '$n từ';
  }

  @override
  String listeningSentenceNumber(int n) {
    return 'Câu $n';
  }

  @override
  String get dictationCheckButton => 'Kiểm tra';

  @override
  String get dictationNextButton => 'Tiếp';

  @override
  String get dictationSaveContinue => 'Lưu & tiếp';

  @override
  String get dictationFinishButton => 'Hoàn thành';

  @override
  String get dictationTypeWhatYouHearHint => 'Gõ những gì bạn nghe…';

  @override
  String get meaningLabel => 'Nghĩa:';

  @override
  String get quizTimeUpSubmitting => 'Hết giờ! Đang nộp bài…';

  @override
  String get translationFailed => 'Không dịch được.';

  @override
  String get commonOk => 'OK';

  @override
  String get commonError => 'Đã có lỗi xảy ra';

  @override
  String get commonClose => 'Đóng';

  @override
  String get commonDone => 'Xong';

  @override
  String get listeningCompLoadError => 'Không tải được bài.';

  @override
  String get listeningCompTabTranscript => 'Bản ghi';

  @override
  String get listeningCompTranslateToggle => 'Dịch';

  @override
  String listeningCompQuestionNumber(int n) {
    return 'Câu $n';
  }

  @override
  String listeningCompHintSeekSeconds(int seconds) {
    return 'Nghe đoạn chứa đáp án (${seconds}s)';
  }

  @override
  String get listeningCompTranscriptLocked => 'Bản ghi đang khóa';

  @override
  String get listeningCompTranscriptLockedHint =>
      'Nộp bài trước để mở bản ghi đầy đủ.';

  @override
  String get listeningCompTranscriptOriginal => 'Bản gốc (Tiếng Anh)';

  @override
  String get listeningCompTranscriptTranslation => 'Bản dịch (Tiếng Việt)';

  @override
  String get readingQuizResultTitle => 'Kết quả';

  @override
  String readingQuizResultSummary(int correct, int total, int scorePct) {
    return 'Đúng: $correct / $total\nĐiểm: $scorePct%';
  }

  @override
  String get readingTabArticle => 'Bài đọc';

  @override
  String readingTabQuestionsCount(int n) {
    return 'Câu hỏi ($n)';
  }

  @override
  String get readingSubmitAnswers => 'Nộp bài';

  @override
  String get readingNoQuestionsAvailable => 'Chưa có câu hỏi.';

  @override
  String get readingFeedbackExplanation => 'Giải thích';

  @override
  String readingFeedbackLocationParagraph(int n) {
    return '• Vị trí: Đoạn $n';
  }

  @override
  String readingFeedbackKeySentence(String sentence) {
    return '• Câu then chốt: \"$sentence\"';
  }

  @override
  String get readingShowTranslation => 'Hiện bản dịch';

  @override
  String get readingHideTranslation => 'Ẩn bản dịch';

  @override
  String get readingSubmissionFailed => 'Nộp bài thất bại';

  @override
  String get readingReviewMode => 'Chế độ xem lại';

  @override
  String readingReviewingWithScore(int pct) {
    return 'Đang xem lại (điểm: $pct%)';
  }

  @override
  String get listeningSkillsPracticeTitle => 'Luyện tập';

  @override
  String get listeningSkillsHeaderTitle => 'Bài nghe';

  @override
  String get listeningSkillsTabPractice => 'Luyện tập';

  @override
  String get listeningSkillsTabDiscuss => 'Thảo luận';

  @override
  String get dictationSnackCorrect => 'Đúng rồi!';

  @override
  String get dictationSnackTryAgain => 'Thử lại nhé';

  @override
  String get writingFbErrorTitle => 'Lỗi';

  @override
  String get writingFbNoData => 'Không có dữ liệu nhận xét.';

  @override
  String get writingFbResultTitle => 'Kết quả nhận xét';

  @override
  String get writingFbTabOverview => 'Tổng quan';

  @override
  String get writingFbTabDetails => 'Chi tiết';

  @override
  String get writingFbTabRewrites => 'Bản sửa';

  @override
  String get writingFbTabSamples => 'Mẫu bài';

  @override
  String get writingFbTopicRequirement => 'Chủ đề & yêu cầu';

  @override
  String get writingFbNoPromptContent => 'Chưa có nội dung đề bài.';

  @override
  String get writingFbOverallBand => 'Điểm tổng (band)';

  @override
  String get writingFbSubscores => 'Điểm thành phần';

  @override
  String get writingFbCriterionTR => 'Đáp ứng đề';

  @override
  String get writingFbCriterionCC => 'Mạch lạc & liên kết';

  @override
  String get writingFbCriterionLR => 'Từ vựng';

  @override
  String get writingFbCriterionGRA => 'Ngữ pháp (độ đa dạng)';

  @override
  String get writingFbCriterionGrammar => 'Ngữ pháp';

  @override
  String get writingFbKeyTips => 'Gợi ý cải thiện';

  @override
  String get writingFbDetailedCorrection => 'Sửa chi tiết';

  @override
  String get writingFbTapHighlighted =>
      'Chạm vào chỗ được tô để xem giải thích.';

  @override
  String get writingFbNoCorrections => 'Chưa có phần sửa.';

  @override
  String get writingFbSampleMidTitle => 'Bản chỉnh sửa (Band 6.0–7.0)';

  @override
  String get writingFbSampleHighTitle => 'Bài mẫu lý tưởng (Band 8.0+)';

  @override
  String writingInstructionHowTo(String title) {
    return 'Cách viết: $title';
  }

  @override
  String get writingInstructionSubtitle => 'Hướng dẫn nhanh & cấu trúc';

  @override
  String get writingInstructionGotIt => 'Đã hiểu, bắt đầu viết!';

  @override
  String get writingInstructionWhatIsIt => 'Đây là dạng gì?';

  @override
  String get writingInstructionSuggestedStructure => 'Gợi ý cấu trúc';

  @override
  String get writingInstructionKeyTipsSection => 'Mẹo quan trọng';

  @override
  String get listeningAutoPlayNext => 'Tự phát câu tiếp';

  @override
  String get discussionsEmpty => 'Chưa có thảo luận';

  @override
  String replyingToUser(String user) {
    return 'Đang trả lời $user';
  }

  @override
  String get commentHintReply => 'Viết câu trả lời…';

  @override
  String get commentHintAsk => 'Đặt câu hỏi…';

  @override
  String get writingSaveDraftTitle => 'Lưu bản nháp?';

  @override
  String get writingSaveDraftMessage => 'Bạn có muốn lưu thay đổi?';

  @override
  String get writingDiscardButton => 'Bỏ qua';

  @override
  String get writingResumeTitle => 'Tiếp tục viết?';

  @override
  String get writingResumeMessage =>
      'Có bản nháp chưa hoàn thành. Tiếp tục chỗ bạn dừng lại?';

  @override
  String get writingStartNewButton => 'Viết mới';

  @override
  String get writingResumeButton => 'Tiếp tục';

  @override
  String get writingInstructionsTooltip => 'Hướng dẫn';

  @override
  String get writingPreparingTask => 'Đang chuẩn bị bài…';

  @override
  String get writingDraftSavedSnack => 'Đã lưu bản nháp.';

  @override
  String get writingTopicFallback => 'Chủ đề';

  @override
  String get writingPromptTapCollapse => 'Chạm để thu gọn';

  @override
  String get writingPromptTapExpand => 'Chạm để xem đề bài';

  @override
  String get writingEditorHint => 'Bắt đầu viết bài tại đây…';

  @override
  String get writingSubmitEssay => 'Nộp bài';

  @override
  String get writingNoTopicsFound => 'Chưa có chủ đề viết';

  @override
  String listeningCueProgress(int done, int total) {
    return 'Hoàn thành $done / $total câu';
  }

  @override
  String get writingSelectTaskType => 'Chọn dạng bài';

  @override
  String writingForTopic(String name) {
    return 'Chủ đề: \"$name\"';
  }

  @override
  String get writingSearchTopicsHint => 'Tìm chủ đề…';

  @override
  String get writingHeaderEssayTitle => 'Viết luận';

  @override
  String get writingHeaderEssaySubtitle =>
      'Luyện triển khai ý và xây dựng lập luận rõ ràng.';

  @override
  String get writingAiFeedbackBadge => 'Nhận xét AI';

  @override
  String get writingSearchTopicsTasksHint => 'Tìm chủ đề, dạng bài…';

  @override
  String get writingTaskDescOpinion => 'Trình bày quan điểm cá nhân';

  @override
  String get writingTaskDescDiscuss => 'Phân tích nhiều góc nhìn';

  @override
  String get writingTaskDescProblemSolution => 'Xác định vấn đề và hướng xử lý';

  @override
  String get writingTaskDescAdvantages => 'Cân nhắc ưu và nhược điểm';

  @override
  String get writingTaskDescGeneral => 'Luyện viết tổng hợp';

  @override
  String writingSubmissionsCount(int n) {
    return '$n bài viết';
  }

  @override
  String get writingAiSuggestionTitle => 'Gợi ý AI';

  @override
  String get writingWhyCorrection => 'Vì sao cần sửa?';

  @override
  String get writingGotIt => 'Đã hiểu';

  @override
  String get wordDetailsNotFound => 'Không tìm thấy chi tiết từ.';

  @override
  String get listeningCompTitle => 'Nghe hiểu';

  @override
  String get listeningCompSubtitle => 'Nghe audio và chọn đáp án trắc nghiệm.';

  @override
  String get listeningCompSearchHint => 'Tìm chủ đề, ID…';

  @override
  String listeningCompQuestionCount(int n) {
    return '$n câu';
  }

  @override
  String listeningCompHighScore(int pct) {
    return 'Điểm cao: $pct%';
  }

  @override
  String get listeningCompNotStarted => 'Chưa làm';

  @override
  String get listeningCompReview => 'Xem lại';

  @override
  String get listeningCompRetake => 'Làm lại';

  @override
  String get listeningCompStart => 'Bắt đầu';

  @override
  String get listeningCompEmpty => 'Chưa có bài nghe';

  @override
  String get listeningCompPlayedOnce => 'Đã nghe (chỉ 1 lần)';

  @override
  String get discussionReply => 'Trả lời';

  @override
  String get discussionReactTooltip => 'Cảm xúc';

  @override
  String get reactionLike => 'Thích';

  @override
  String get reactionLove => 'Yêu thích';

  @override
  String get reactionHaha => 'Haha';

  @override
  String get reactionWow => 'Wow';

  @override
  String get reactionSad => 'Buồn';

  @override
  String get reactionAngry => 'Giận';

  @override
  String get freeSpeakingTitle => 'Nói tự do';

  @override
  String get freeSpeakingLoadingConfig => 'Đang tải cấu hình…';

  @override
  String get freeSpeakingRetry => 'Thử lại';

  @override
  String get freeSpeakingMicDenied =>
      'Cần quyền micro để nói với AI. Hãy bật trong Cài đặt.';

  @override
  String get freeSpeakingEndCallToChangeVoice =>
      'Kết thúc cuộc gọi để đổi giọng.';

  @override
  String get freeSpeakingSelectVoiceTitle => 'Chọn giọng AI';

  @override
  String get freeSpeakingWelcome =>
      'Chào bạn! Chọn giọng và chạm mic để luyện tiếng Anh.';

  @override
  String get freeSpeakingConfigErrorShort => 'Không tải được cấu hình gọi.';

  @override
  String get freeSpeakingStatusConnecting => 'Đang kết nối…';

  @override
  String get freeSpeakingStatusOnline => 'Trực tuyến';

  @override
  String get freeSpeakingStatusOffline => 'Ngoại tuyến';

  @override
  String get freeSpeakingStatusAiSpeaking => 'AI đang nói';

  @override
  String get freeSpeakingHintConnecting => 'Đang kết nối…';

  @override
  String get freeSpeakingHintTypeMessage => 'Nhập tin nhắn…';

  @override
  String get freeSpeakingHintTapMic => 'Chạm mic để kết nối';

  @override
  String get vapiConfigHintAuth =>
      'Không tải được cấu hình gọi AI (chưa xác thực).\n\n• Đăng nhập trong app, rồi mở lại Nói tự do.\n• Nếu hết phiên, đăng xuất và đăng nhập lại.';

  @override
  String get vapiConfigHint503 =>
      'Server báo chưa cấu hình Vapi (503).\n\n• Trong .env backend cần: VAPI_PUBLIC_KEY và VAPI_ASSISTANT_ID (không dấu cách sau dấu =).\n• Lưu .env và khởi động lại backend.';

  @override
  String vapiConfigHintHttp(int code, String detail) {
    return 'API cấu hình Vapi trả lỗi (HTTP $code).\n\n$detail';
  }

  @override
  String vapiConfigHintNetwork(String detail) {
    return 'Không lấy được cấu hình từ server (mạng / URL).\n\n• Điện thoại và PC cùng Wi‑Fi.\n• Sửa IP trong api_config.dart trùng máy bạn.\n• Emulator Android: dùng 10.0.2.2.\n\nChi tiết: $detail';
  }

  @override
  String get vapiConfigHintMissingKeys =>
      'Chưa có public key hoặc assistant id.\n\n• Backend: thêm VAPI_PUBLIC_KEY và VAPI_ASSISTANT_ID vào .env, restart server.\n• Hoặc build: --dart-define=VAPI_PUBLIC_KEY=… --dart-define=VAPI_ASSISTANT_ID=…';

  @override
  String get vocabTutorialSlide1Title => 'Chào mừng đến Từ vựng';

  @override
  String get vocabTutorialSlide1a =>
      'Xây dựng vốn từ vựng vững chắc với phương pháp ';

  @override
  String get vocabTutorialSlide1b => 'Lặp lại ngắt quãng';

  @override
  String get vocabTutorialSlide1c => ' (Spaced Repetition).';

  @override
  String get vocabTutorialSlide2Title => 'Tra cứu & lưu trữ';

  @override
  String get vocabTutorialSlide2a => 'Tra từ nhanh chóng. Nhấn ';

  @override
  String get vocabTutorialSlide2SaveLabel => 'Lưu';

  @override
  String get vocabTutorialSlide2b => ' để đánh dấu, hoặc nhấn ';

  @override
  String get vocabTutorialSlide2LearnLabel => 'Học';

  @override
  String get vocabTutorialSlide2c => ' để học ngay.';

  @override
  String get vocabTutorialSlide3Title => 'Thuật toán thông minh';

  @override
  String get vocabTutorialSlide3a => 'Dựa trên lịch sử học của bạn, ';

  @override
  String get vocabTutorialSlide3b => 'máy chủ';

  @override
  String get vocabTutorialSlide3c => ' sẽ tự động tính toán ';

  @override
  String get vocabTutorialSlide3d => 'điểm rơi trí nhớ';

  @override
  String get vocabTutorialSlide3e =>
      ' để nhắc nhở ngay trước khi bạn sắp quên từ đó.';

  @override
  String get vocabTutorialSlide4Title => 'Ôn tập mỗi ngày';

  @override
  String get vocabTutorialSlide4a => 'Khi đến hạn, nhấn ';

  @override
  String get vocabTutorialSlide4c =>
      '. Đánh giá mức độ nhớ (Khó / Tốt / Dễ) để tối ưu lịch học.';

  @override
  String get vocabTutorialLetsGo => 'Bắt đầu';

  @override
  String get updateAvailableTitle => 'Có bản cập nhật mới';

  @override
  String get forceUpdateTitle => 'Yêu cầu cập nhật ứng dụng';

  @override
  String get updateAvailableBody =>
      'Đã có phiên bản mới của ứng dụng. Hãy cập nhật để có trải nghiệm tốt nhất.';

  @override
  String get updateNowButton => 'Cập nhật ngay';

  @override
  String get updateLaterButton => 'Để sau';

  @override
  String updateDialogVersionLine(String name, int code) {
    return '$name (+$code)';
  }

  @override
  String get updateDialogWhatsNewTitle => 'Có gì mới';

  @override
  String get updateLinkOpenFailed => 'Không mở được liên kết cập nhật.';

  @override
  String get appVersionLabel => 'Phiên bản ứng dụng';

  @override
  String get profileTeacherSectionTitle => 'Lớp học & giảng dạy';

  @override
  String get profileStudentClassesTitle => 'Lớp của tôi';

  @override
  String get profileStudentClassesSubtitle => 'Tham gia lớp bằng mã mời';

  @override
  String get profileTeacherHubTitle => 'Khu vực giáo viên';

  @override
  String get profileTeacherHubSubtitle => 'Lớp học và bài kiểm tra';

  @override
  String get profileApplyTeacherTitle => 'Đăng ký làm giáo viên';

  @override
  String get profileApplyTeacherSubtitle => 'Gửi yêu cầu tài khoản giáo viên';

  @override
  String get teacherApplyTitle => 'Trở thành giáo viên';

  @override
  String get teacherApplySubtitle =>
      'Hãy mô tả ngắn gọn về kinh nghiệm giảng dạy. Quản trị viên sẽ xét duyệt.';

  @override
  String get teacherApplyBioLabel => 'Giới thiệu';

  @override
  String get teacherApplyOrgLabel => 'Trường / tổ chức (tuỳ chọn)';

  @override
  String get teacherApplySubmit => 'Gửi đơn';

  @override
  String get teacherApplySubmitted => 'Đã gửi đơn';

  @override
  String get teacherDashboardTitle => 'Khu vực giáo viên';

  @override
  String get teacherNavDashboard => 'Tổng quan';

  @override
  String get teacherNavExams => 'Ngân hàng đề';

  @override
  String get teacherShellAppName => 'Giáo viên';

  @override
  String get teacherShellNavGroup => 'Không gian làm việc';

  @override
  String get teacherShellDesktopTitle => 'Dùng trình duyệt trên máy tính';

  @override
  String get teacherShellDesktopBody =>
      'Khu vực giáo viên được tối ưu cho màn hình từ 768px trở lên. Hãy mở trên laptop hoặc máy tính để có trải nghiệm tốt nhất.';

  @override
  String get teacherShellCollapseSidebar => 'Thu gọn thanh bên';

  @override
  String get teacherShellExpandSidebar => 'Mở rộng thanh bên';

  @override
  String get teacherAccountMenuTitle => 'Tài khoản & cài đặt';

  @override
  String get teacherAccountRoleTeacher => 'Giáo viên';

  @override
  String get teacherAccountSectionAbout => 'Thông tin ứng dụng';

  @override
  String get teacherAccountOpenMenu => 'Menu tài khoản';

  @override
  String get teacherAccountEditProfileSubtitle =>
      'Cập nhật tên, ảnh đại diện và thông tin liên hệ.';

  @override
  String get adminAccountRoleAdmin => 'Quản trị viên';

  @override
  String get adminAccountOpenMenu => 'Menu tài khoản';

  @override
  String get adminUserRoleStudent => 'Học sinh';

  @override
  String get adminUserRoleTeacher => 'Giáo viên';

  @override
  String get adminUserRoleAdmin => 'Quản trị viên';

  @override
  String get adminUserStatusOnline => 'Online';

  @override
  String get adminUserStatusOffline => 'Offline';

  @override
  String get adminUserActiveNow => 'Đang hoạt động';

  @override
  String get adminUserNeverActive => 'Chưa từng hoạt động';

  @override
  String adminUserLastActive(String when) {
    return 'Hoạt động lần cuối: $when';
  }

  @override
  String teacherDashboardGreeting(String name) {
    return 'Xin chào, $name';
  }

  @override
  String teacherDashboardTodayMeta(String time) {
    return 'Hôm nay · $time';
  }

  @override
  String get teacherDashboardActionNewExam => 'Đề mới';

  @override
  String get teacherClassFab => 'Lớp mới';

  @override
  String get teacherClassCreateTitle => 'Tạo lớp học';

  @override
  String get teacherClassNameLabel => 'Tên lớp';

  @override
  String get teacherClassCreated => 'Đã tạo lớp';

  @override
  String get teacherMyClassrooms => 'Lớp của tôi';

  @override
  String get teacherNoClassrooms => 'Chưa có lớp. Nhấn nút + để tạo.';

  @override
  String get teacherInviteCode => 'Mã mời';

  @override
  String get teacherClassroomDetailTitle => 'Lớp học';

  @override
  String get teacherNoExams => 'Hãy tạo đề mẫu từ khu vực giáo viên trước.';

  @override
  String get teacherAssignmentCreated => 'Đã giao bài kiểm tra cho lớp';

  @override
  String get teacherAssignFirstExam => 'Giao đề mới nhất cho lớp này';

  @override
  String teacherClassroomMemberCountActive(int count) {
    return '$count học sinh trong lớp';
  }

  @override
  String teacherClassroomMemberCountPending(int count) {
    return '$count đang chờ duyệt';
  }

  @override
  String get teacherAssignExamToClass => 'Giao đề cho lớp này';

  @override
  String get teacherPickExamToAssign => 'Chọn đề đã xuất bản';

  @override
  String get teacherNoPublishedExams =>
      'Chưa có đề đã xuất bản. Hãy xuất bản đề trong mục Đề thi của tôi trước.';

  @override
  String get copyInviteCode => 'Sao chép mã mời';

  @override
  String get teacherExamSessionShareTitle => 'Gửi gì cho học sinh';

  @override
  String get teacherExamSessionShareClassroom =>
      'Học sinh vào Lớp học → bài tập này → Vào phòng chờ. Không cần dán mã ở đây.';

  @override
  String get teacherExamSessionSharePublic =>
      'Học sinh mở Tham gia bài thi công khai và dán mã bên dưới (không phải mã phòng hay link session).';

  @override
  String get teacherExamSessionSharePublicCopy =>
      'Sao chép mã tham gia công khai';

  @override
  String get teacherExamSessionRoomCodeHint =>
      'Nhãn phòng (chỉ hiển thị trong lobby — không dùng để vào bài)';

  @override
  String get adminTeacherApplicationsTitle => 'Đơn xin làm giáo viên';

  @override
  String get adminTeacherApplicationsSubtitle => 'Xem và duyệt đơn chờ';

  @override
  String get adminTeacherApplicationsEmpty => 'Không có đơn ở trạng thái này.';

  @override
  String get adminTeacherApprove => 'Duyệt';

  @override
  String get adminTeacherReject => 'Từ chối';

  @override
  String get adminTeacherRejectReason => 'Lý do từ chối';

  @override
  String get studentClassesTitle => 'Lớp của tôi';

  @override
  String get studentClassesSubtitle =>
      'Mở từng lớp để xem đúng bài tập của lớp đó.';

  @override
  String get studentJoinClassTitle => 'Tham gia bằng mã mời';

  @override
  String get studentUnifiedJoinTitle => 'Tham gia';

  @override
  String get studentUnifiedJoinSubtitle =>
      'Dán mã hoặc link — app tự nhận loại và mở đúng chỗ.';

  @override
  String get studentUnifiedJoinHint =>
      'Mã lớp · link lớp · bài thi công khai · phòng thi live…';

  @override
  String get studentUnifiedJoinCompactHint =>
      'Dán mã hoặc link để vào thêm lớp.';

  @override
  String get studentUnifiedJoinButton => 'Tham gia';

  @override
  String get studentJoinInputInvalid =>
      'Không nhận dạng được mã. Kiểm tra lại hoặc hỏi giáo viên.';

  @override
  String get studentJoinDetectedClass => 'Nhận mã lớp — đang tham gia…';

  @override
  String get studentJoinDetectedSession =>
      'Nhận phòng thi live — đang mở phòng chờ…';

  @override
  String get studentJoinDetectedPublicExam =>
      'Nhận bài thi công khai — đang mở…';

  @override
  String get studentJoinClassSubtitle =>
      'Nhập mã giáo viên gửi. Bài tập sẽ hiển thị bên trong từng lớp.';

  @override
  String get studentInviteCodeLabel => 'Mã mời';

  @override
  String get studentJoinClassButton => 'Vào lớp';

  @override
  String get studentJoinClassSuccess => 'Đã tham gia lớp';

  @override
  String get studentMyClassesTitle => 'Các lớp bạn đang học';

  @override
  String studentClassesHubListHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lớp — chạm để xem bài tập và chat',
      one: '1 lớp — chạm để xem bài tập và chat',
    );
    return '$_temp0';
  }

  @override
  String get studentNoClasses => 'Bạn chưa tham gia lớp nào.';

  @override
  String get studentClassOpen => 'Mở lớp';

  @override
  String studentClassAssignmentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bài tập',
      one: '1 bài tập',
      zero: 'Chưa có bài tập',
    );
    return '$_temp0';
  }

  @override
  String studentClassLiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count phòng trực tiếp',
      one: '1 phòng trực tiếp',
    );
    return '$_temp0';
  }

  @override
  String get studentClassDetailTitle => 'Thông tin lớp';

  @override
  String get studentClassDetailAssignmentsTitle => 'Bài tập của lớp';

  @override
  String get studentClassDetailAssignmentsSubtitle =>
      'Chỉ hiển thị bài tập thuộc lớp học này.';

  @override
  String get studentClassNoAssignments => 'Lớp này chưa có bài tập nào.';

  @override
  String get studentClassAssignmentNotYetOpen =>
      'Chưa đến giờ mở bài — xem lịch giáo viên gửi.';

  @override
  String get studentClassAssignmentClosed => 'Bài tập đã hết thời gian làm.';

  @override
  String get studentClassInfoTitle => 'Thông tin lớp học';

  @override
  String studentClassMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count học sinh đang học',
      one: '1 học sinh đang học',
    );
    return '$_temp0';
  }

  @override
  String get studentClassJoinPolicyOpen => 'Vào lớp tự do';

  @override
  String get studentClassJoinPolicyApproval => 'Cần giáo viên duyệt';

  @override
  String studentClassCreatedAt(String date) {
    return 'Tạo ngày $date';
  }

  @override
  String studentClassUpdatedAt(String date) {
    return 'Cập nhật $date';
  }

  @override
  String studentClassScheduleDue(String date) {
    return 'Hạn: $date';
  }

  @override
  String studentClassScheduleWindow(String opens, String closes) {
    return '$opens – $closes';
  }

  @override
  String get studentClassPublicJoin => 'Vào bài thi công khai';

  @override
  String studentClassTeacher(String name) {
    return 'Giáo viên: $name';
  }

  @override
  String get studentClassNoDescription => 'Lớp này chưa có mô tả.';

  @override
  String get studentClassTabOverview => 'Tổng quan';

  @override
  String get studentClassTabAssignments => 'Bài tập';

  @override
  String get studentClassTabMembers => 'Thành viên';

  @override
  String get studentClassOpenChat => 'Nhóm chat';

  @override
  String get studentClassQuickActionChat => 'Chat';

  @override
  String get studentClassQuickActionAssignments => 'Bài tập';

  @override
  String get studentClassQuickActionMembers => 'Thành viên';

  @override
  String get studentClassSegmentOpen => 'Đang mở';

  @override
  String get studentClassSegmentSubmitted => 'Đã nộp';

  @override
  String get studentClassSegmentClosed => 'Hết hạn';

  @override
  String get studentClassOverviewRecentTitle => 'Cần làm';

  @override
  String get studentClassViewAllAssignments => 'Xem tất cả';

  @override
  String get studentClassMembersEmpty => 'Chưa có thành viên.';

  @override
  String get studentClassMemberYou => 'Bạn';

  @override
  String get studentClassMemberTeacher => 'Giáo viên';

  @override
  String get studentClassMemberCoTeacher => 'GV phụ';

  @override
  String get studentClassInviteCodeLabel => 'Mã mời lớp';

  @override
  String get studentClassReadMore => 'Xem thêm';

  @override
  String studentClassChatMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thành viên trong chat',
      one: '1 thành viên trong chat',
    );
    return '$_temp0';
  }

  @override
  String studentClassOverviewActionHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bài cần bạn làm ngay',
      one: '1 bài cần bạn làm ngay',
    );
    return '$_temp0';
  }

  @override
  String get studentClassOverviewEmptyBody =>
      'Khi giáo viên giao bài, bài tập sẽ hiện ở đây.';

  @override
  String get studentClassNoAssignmentsInSegment =>
      'Không có bài tập trong bộ lọc này.';

  @override
  String studentClassAssignmentsFilteredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bài tập',
      one: '1 bài tập',
    );
    return '$_temp0';
  }

  @override
  String get studentClassSegmentGraded => 'Đã chấm';

  @override
  String studentClassLiveBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bài thi trực tiếp đang diễn ra — mở tab Bài tập',
      one: '1 bài thi trực tiếp đang diễn ra — mở tab Bài tập',
    );
    return '$_temp0';
  }

  @override
  String get studentClassSortPriority => 'Ưu tiên cần làm';

  @override
  String get studentClassSortDueDate => 'Sắp xếp theo hạn';

  @override
  String get studentClassMembersSearchHint => 'Tìm thành viên…';

  @override
  String get studentClassMembersNoResults => 'Không có thành viên phù hợp.';

  @override
  String get studentClassMuteNotifications => 'Tắt thông báo lớp';

  @override
  String get studentClassMuteNotificationsHint => 'Chỉ lưu trên thiết bị này.';

  @override
  String get studentClassLeaveAction => 'Rời lớp';

  @override
  String get studentClassLeaveConfirmTitle => 'Rời lớp học này?';

  @override
  String get studentClassLeaveConfirmBody =>
      'Bạn sẽ mất quyền truy cập bài tập và chat của lớp. Giáo viên có thể mời bạn tham gia lại.';

  @override
  String get studentClassLeaveSuccess => 'Bạn đã rời lớp.';

  @override
  String get teacherClassDetailAssignmentsTitle => 'Bài được giao';

  @override
  String get teacherClassDetailAssignmentsSubtitle =>
      'Các bài thi trong lớp — lịch, định dạng và tiến độ học sinh.';

  @override
  String get teacherClassDetailActiveTitle => 'Bài đang hoạt động';

  @override
  String get teacherClassDetailActiveSubtitle =>
      'Phiên đang mở và bài học sinh vẫn có thể làm.';

  @override
  String get teacherClassDetailHistoryTitle => 'Lịch sử phiên thi';

  @override
  String get teacherClassDetailHistorySubtitle =>
      'Các bài thi trực tiếp đã kết thúc phiên gần nhất.';

  @override
  String get teacherClassHistoryOpenGrading => 'Chấm bài';

  @override
  String teacherClassHistorySessionEnded(String date) {
    return 'Phiên gần nhất kết thúc: $date';
  }

  @override
  String get teacherClassNoAssignments => 'Chưa có bài thi nào trong lớp.';

  @override
  String get teacherClassNoHistory =>
      'Chưa có phiên thi trực tiếp đã kết thúc trong lớp này.';

  @override
  String get teacherClassTabOverview => 'Tổng quan';

  @override
  String get teacherClassTabAssignments => 'Bài đã giao';

  @override
  String get teacherClassTabMembers => 'Thành viên';

  @override
  String get teacherClassTabSettings => 'Cài đặt';

  @override
  String get teacherClassMembersEmpty => 'Chưa có thành viên.';

  @override
  String get teacherClassMemberRemove => 'Xóa';

  @override
  String get teacherClassMemberRemoveConfirm => 'Xóa học sinh này khỏi lớp?';

  @override
  String get teacherClassMemberStatusPending => 'Chờ duyệt';

  @override
  String get teacherMembersSearchHint => 'Tìm theo tên hoặc email…';

  @override
  String get teacherMembersFilterAll => 'Tất cả';

  @override
  String get teacherMembersFilterActive => 'Hoạt động';

  @override
  String get teacherMembersFilterPending => 'Chờ duyệt';

  @override
  String get teacherMembersStatusPending => 'Chờ duyệt';

  @override
  String get teacherMembersActiveSection => 'Thành viên hoạt động';

  @override
  String get teacherMembersNoResults => 'Không tìm thấy thành viên phù hợp.';

  @override
  String get teacherMembersEmptyHint =>
      'Chia sẻ mã mời để thêm học sinh vào lớp.';

  @override
  String get teacherMembersInvite => 'Mời';

  @override
  String get teacherMembersCopyInvite => 'Sao chép mã mời';

  @override
  String get teacherClassSaveSettings => 'Lưu thay đổi';

  @override
  String get teacherClassSettingsSaved => 'Đã cập nhật lớp';

  @override
  String get teacherClassRotateInvite => 'Đổi mã mời';

  @override
  String get teacherClassRotateInviteConfirm =>
      'Tạo mã mới? Mã cũ sẽ không còn hiệu lực.';

  @override
  String get teacherClassArchive => 'Lưu trữ lớp';

  @override
  String get teacherClassArchiveConfirm =>
      'Lưu trữ lớp này? Học sinh sẽ không thấy bài giao mới.';

  @override
  String get teacherClassArchivedMessage => 'Đã lưu trữ lớp';

  @override
  String get teacherExamArchive => 'Lưu trữ đề';

  @override
  String get teacherExamArchiveConfirm =>
      'Lưu trữ đề này? Không thể giao đề đã lưu trữ.';

  @override
  String get teacherExamArchived => 'Đã lưu trữ đề';

  @override
  String get teacherExamDelete => 'Xóa vĩnh viễn';

  @override
  String get teacherExamDeleteConfirm =>
      'Xóa đề này vĩnh viễn? Các bài giao chưa có bài nộp sẽ bị xóa. Không thể hoàn tác.';

  @override
  String get teacherExamDeleted => 'Đã xóa đề';

  @override
  String get teacherExamRestore => 'Khôi phục đề';

  @override
  String get teacherExamRestoreConfirm => 'Khôi phục đề từ kho lưu trữ?';

  @override
  String get teacherExamRestored => 'Đã khôi phục đề';

  @override
  String get teacherExamsFilterAll => 'Tất cả';

  @override
  String get teacherExamsFilterDraft => 'Nháp';

  @override
  String get teacherExamsFilterPublished => 'Đã xuất bản';

  @override
  String get teacherExamsFilterArchived => 'Đã lưu trữ';

  @override
  String get teacherExamsFilterEmpty => 'Không có đề trong bộ lọc này.';

  @override
  String get teacherExamPublishConfirm => 'Xuất bản đề để có thể giao cho lớp?';

  @override
  String get teacherExamMoreActions => 'Thao tác khác';

  @override
  String get teacherAssignmentDelete => 'Xóa bài giao';

  @override
  String get teacherAssignmentDeleteConfirm =>
      'Xóa bài giao này? Chỉ được phép khi chưa có học sinh nộp bài.';

  @override
  String get teacherAssignmentDeleted => 'Đã xóa bài giao';

  @override
  String get teacherAssignmentClose => 'Đóng bài giao';

  @override
  String get teacherAssignmentCloseConfirm =>
      'Đóng bài giao? Học sinh không thể bắt đầu làm mới.';

  @override
  String get teacherAssignmentClosed => 'Đã đóng bài giao';

  @override
  String get teacherAssignmentAudience => 'Đối tượng';

  @override
  String get teacherAssignmentAudienceClassroom => 'Lớp học';

  @override
  String get teacherAssignmentAudienceClassroomHint =>
      'Giao cho một lớp cụ thể';

  @override
  String get teacherAssignmentAudiencePublic => 'Link công khai';

  @override
  String get teacherAssignmentAudiencePublicHint =>
      'Chia sẻ link cho học sinh tự tham gia';

  @override
  String get teacherAssignmentPublicMaxUsesHint => 'Giới hạn lượt (tuỳ chọn)';

  @override
  String get teacherAssignmentPublicExpiresHint => 'Chọn hết hạn (tuỳ chọn)';

  @override
  String get teacherAssignmentPublicTokenTitle => 'Mã tham gia công khai';

  @override
  String get teacherAssignmentPublicTokenBody =>
      'Gửi mã này cho học sinh. Họ dán vào mục “Tham gia bài thi công khai”.';

  @override
  String get teacherAssignmentPublicRealtimeNextSteps =>
      'Phòng chờ trực tiếp đã được tạo tự động. Mở bảng điều khiển live để giám sát học sinh, rồi bắt đầu bài khi sẵn sàng.';

  @override
  String get teacherAssignmentOpenLiveConsole => 'Mở bảng live';

  @override
  String get examPublicNoLiveSession =>
      'Giáo viên chưa mở phòng live. Vui lòng thử lại sau.';

  @override
  String get dashboardPublicCopyToken => 'Sao chép mã';

  @override
  String get dashboardPublicTokenCopied => 'Đã sao chép mã';

  @override
  String get dashboardPublicRotateLink => 'Link mới';

  @override
  String get dashboardPublicRotateConfirm =>
      'Tạo mã công khai mới? Link cũ sẽ không còn hiệu lực.';

  @override
  String get dashboardPublicCloseLink => 'Đóng link';

  @override
  String get dashboardPublicCloseConfirm =>
      'Đóng bài giao công khai? Người mới không thể bắt đầu.';

  @override
  String get teacherApplyStatusPending => 'Đơn của bạn đang chờ admin duyệt.';

  @override
  String get teacherApplyStatusApproved =>
      'Bạn đã được duyệt làm giáo viên. Mở khu giáo viên từ hồ sơ.';

  @override
  String get teacherApplyStatusRejected => 'Đơn của bạn bị từ chối.';

  @override
  String get teacherApplyStatusWithdrawn =>
      'Bạn đã rút đơn. Có thể gửi đơn mới.';

  @override
  String get teacherApplyStatusNone =>
      'Chưa có đơn — mô tả ngắn về bạn bên dưới.';

  @override
  String get teacherApplyRejectReason => 'Ghi chú từ người duyệt';

  @override
  String get teacherApplyWithdraw => 'Rút đơn';

  @override
  String get teacherApplyWithdrawConfirm => 'Rút đơn đang chờ duyệt?';

  @override
  String get teacherApplyGoToHub => 'Mở khu giáo viên';

  @override
  String get homeQuickMyClasses => 'Lớp học';

  @override
  String get homeQuickPublicExam => 'Bài thi công khai';

  @override
  String get studentJoinClassByTokenLabel => 'Mã từ link mời';

  @override
  String get studentJoinClassByTokenHint =>
      'Dán mã dài từ link lớp giáo viên gửi (không phải link phòng thi live)';

  @override
  String get studentJoinClassByTokenButton => 'Tham gia bằng link';

  @override
  String get studentJoinClassOpeningExamLobby =>
      'Đây là link phòng thi — đang mở phòng chờ…';

  @override
  String get studentJoinClassUsePublicExamLink =>
      'Đây là mã bài thi công khai. Dùng mục «Tham gia bằng liên kết công khai» bên dưới.';

  @override
  String get studentExamsHubTitle => 'Tham gia bài thi công khai';

  @override
  String get studentExamsHubSubtitle =>
      'Bài trong lớp nằm trong từng lớp. Màn hình này chỉ khi bạn có mã bài thi công khai từ giáo viên.';

  @override
  String studentExamTimeRemainingHM(int hours, int minutes) {
    return '${hours}g ${minutes}p';
  }

  @override
  String studentExamTimeRemainingMS(int minutes, int seconds) {
    return '${minutes}p ${seconds}s';
  }

  @override
  String studentExamTimeRemainingS(int seconds) {
    return '${seconds}s';
  }

  @override
  String get studentExamRunnerLoadFailed => 'Không tải được bài thi.';

  @override
  String get teacherMobileWorkspaceTitle => 'Khu giáo viên';

  @override
  String get teacherMobileWorkspaceBody =>
      'Dùng thanh tab bên dưới để điều hướng nhanh. Chỉnh sửa đề phức tạp nên dùng màn hình rộng hơn.';

  @override
  String teacherClassOverviewMeta(int students, String policy) {
    return '$students học sinh · $policy';
  }

  @override
  String get teacherClassStatActiveAssignments => 'Đang mở';

  @override
  String get teacherClassStatHistoryAssignments => 'Lịch sử';

  @override
  String get teacherClassStatStudents => 'Học sinh';

  @override
  String get teacherClassStatPendingMembers => 'Chờ duyệt';

  @override
  String get teacherClassCreatedLabel => 'Tạo lúc';

  @override
  String get teacherClassUpdatedLabel => 'Cập nhật';

  @override
  String get teacherClassInviteCardHint =>
      'Chia sẻ mã này để học sinh tham gia lớp.';

  @override
  String get teacherClassRecentAssignments => 'Bài giao gần đây';

  @override
  String get teacherClassViewAllAssignments => 'Xem tất cả bài giao';

  @override
  String get teacherClassSettingsAbout => 'Thông tin lớp';

  @override
  String get teacherClassSettingsJoin => 'Tham gia lớp';

  @override
  String get teacherClassAssignExamCta => 'Giao đề thi';

  @override
  String get examCardFormatClassic => 'Bài thi cổ điển';

  @override
  String get examCardFormatIntegrated => 'Tích hợp 4 kỹ năng';

  @override
  String get examCardFormatSkills => 'Kỹ năng + Ngữ pháp';

  @override
  String get examCardScheduleTitle => 'Lịch làm bài';

  @override
  String get examCardExamInfoTitle => 'Thông tin đề';

  @override
  String examCardQuestionsCount(int count) {
    return '$count câu / phần';
  }

  @override
  String examCardPointsMax(int points) {
    return 'Tối đa $points điểm';
  }

  @override
  String examCardGrammarSkillsCount(int grammar, int skills) {
    return '$grammar ngữ pháp · $skills phần kỹ năng';
  }

  @override
  String examCardAssignedAt(String date) {
    return 'Giao lúc $date';
  }

  @override
  String examCardRoomCode(String code) {
    return 'Mã phòng: $code';
  }

  @override
  String examCardOpensAt(String date) {
    return 'Mở $date';
  }

  @override
  String examCardClosesAt(String date) {
    return 'Đóng $date';
  }

  @override
  String examCardSessionStarted(String date) {
    return 'Phiên bắt đầu $date';
  }

  @override
  String get examCardStatusLobby => 'Phòng chờ — chờ giáo viên bắt đầu';

  @override
  String get examCardStatusLive => 'Đang diễn ra';

  @override
  String get examCardMyAttemptInProgress => 'Bạn đang làm dở';

  @override
  String get examCardMyAttemptSubmitted => 'Đã nộp — chờ kết quả';

  @override
  String get examCardMyAttemptVoid => 'Bài làm đã hủy';

  @override
  String examCardMyAttemptScore(num awarded, num max) {
    return 'Điểm: $awarded / $max';
  }

  @override
  String get examCardTeacherNoAttempts => 'Chưa có học sinh làm bài';

  @override
  String examCardTeacherAttemptsSummary(
      int submitted, int inProgress, int total) {
    return '$submitted đã nộp · $inProgress đang làm · $total lượt';
  }

  @override
  String get examCardManageSession => 'Mở phiên';

  @override
  String get studentExamsPageSubtitle =>
      'Bài tập theo từng lớp nằm trong mục Lớp của tôi. Chỉ dùng link công khai khi giáo viên gửi cho bạn.';

  @override
  String get studentExamsGoToClasses => 'Đến Lớp của tôi';

  @override
  String get studentExamsMenu => 'Bài thi';

  @override
  String get studentExamsTitle => 'Bài kiểm tra khả dụng';

  @override
  String get studentNoExams => 'Chưa có bài thi cho các lớp của bạn.';

  @override
  String get studentExamStart => 'Bắt đầu';

  @override
  String get studentExamResume => 'Tiếp tục làm';

  @override
  String get studentExamResumeHint => 'Đang làm dở — bấm để tiếp tục';

  @override
  String get examCardAlreadySubmitted => 'Đã nộp bài';

  @override
  String get studentExamUnknownTitle => 'Bài kiểm tra';

  @override
  String get studentExamRunnerTitle => 'Làm bài';

  @override
  String get studentExamSubmit => 'Nộp bài';

  @override
  String get studentExamSubmitted => 'Đã nộp bài';

  @override
  String get studentExamScore => 'Điểm';

  @override
  String studentExamQuestionProgress(int current, int total) {
    return 'Câu $current/$total';
  }

  @override
  String get studentExamPrevious => 'Trước';

  @override
  String get studentExamNext => 'Tiếp';

  @override
  String get studentExamItemUnsupported =>
      'Dạng câu này chưa làm được trên app. Bỏ qua hoặc liên hệ giáo viên.';

  @override
  String get studentExamEssayPlaceholder => 'Viết bài làm của bạn…';

  @override
  String studentExamScoreTotals(Object earned, Object max) {
    return 'Điểm: $earned / $max';
  }

  @override
  String get studentExamNoQuestions =>
      'Bài thi này chưa có câu hỏi có thể làm trên app.';

  @override
  String get examModeSelfPaced => 'Tự học';

  @override
  String get examModeScheduled => 'Theo lịch';

  @override
  String get examModeRealtime => 'Phòng thi trực tiếp';

  @override
  String get examOpenLobby => 'Vào phòng chờ';

  @override
  String get examWaitingForTeacher => 'Đang chờ giáo viên bắt đầu';

  @override
  String get examCardLiveSessionEnded =>
      'Giáo viên đã kết thúc phiên thi trực tiếp.';

  @override
  String examCardLiveSessionEndedAt(String date) {
    return 'Phiên kết thúc: $date';
  }

  @override
  String get examCardViewMySubmission => 'Xem bài đã nộp';

  @override
  String get examSessionEndedByTeacher =>
      'Giáo viên đã kết thúc phiên thi. Bài làm của bạn đã được lưu.';

  @override
  String get examJoinByLinkTitle => 'Tham gia bằng liên kết công khai';

  @override
  String get examJoinByLinkHint => 'Dán mã từ giáo viên';

  @override
  String get examJoinByLinkHintDetail =>
      'Dùng mã tham gia dài mà giáo viên gửi (khoảng 36 ký tự). Không dán link /student/exam-session/ vào đây.';

  @override
  String get examJoinWrongSessionLink =>
      'Đây là link phòng live, không phải mã tham gia công khai. Hãy xin giáo viên mã token hiển thị khi tạo bài giao.';

  @override
  String get examJoinInvalidToken =>
      'Không đọc được mã tham gia. Chỉ dán mã token giáo viên đã gửi.';

  @override
  String get examJoinPreview => 'Xem trước';

  @override
  String get examJoinStart => 'Bắt đầu làm bài';

  @override
  String get examSessionRoomCode => 'Mã phòng';

  @override
  String get examSessionGo => 'Vào làm bài';

  @override
  String get studentExamLeaveRealtimeTitle => 'Thoát bài thi?';

  @override
  String get studentExamLeaveRealtimeMessage =>
      'Nếu thoát bây giờ, bạn sẽ không được vào lại bài thi trực tiếp này. Bài làm của bạn sẽ bị đóng.';

  @override
  String get studentExamLeaveRealtimeConfirm => 'Thoát bài thi';

  @override
  String get studentExamLeaveRealtimeCancel => 'Tiếp tục làm';

  @override
  String get studentRunnerExitTitle => 'Thoát bài?';

  @override
  String get studentRunnerExitMessage =>
      'Tiến độ có thể mất nếu bạn thoát bây giờ.';

  @override
  String get studentRunnerExitConfirm => 'Thoát';

  @override
  String get studentRunnerExitCancel => 'Tiếp tục làm';

  @override
  String get studentAudioPlay => 'Phát';

  @override
  String get studentAudioPause => 'Tạm dừng';

  @override
  String get studentExamVoluntaryExitBlocked =>
      'Bạn đã thoát bài thi này và không thể vào lại.';

  @override
  String get studentExamCannotRejoinAfterLeave =>
      'Bạn không thể vào lại bài thi sau khi đã thoát.';

  @override
  String get teacherExamSessionLeavePageHint =>
      'Rời màn hình này không kết thúc bài thi với học sinh. Hãy bấm kết thúc phiên khi bạn muốn dừng bài thi.';

  @override
  String get teacherAssignmentsSection => 'Bài đã giao';

  @override
  String get teacherNoAssignments => 'Chưa có bài giao.';

  @override
  String get teacherDashboardSubtitle =>
      'Lớp, đề và chấm điểm trong một không gian gọn gàng.';

  @override
  String get teacherDashboardOverview => 'Tổng quan';

  @override
  String get teacherDashboardWorkZoneTitle => 'Việc cần làm hôm nay';

  @override
  String get teacherDashboardWorkZoneSubtitle =>
      'Hàng chờ chấm bài và phòng trực tiếp — bấm KPI phía trên để cuộn tới đây.';

  @override
  String get teacherDashboardQuickActionsTitle => 'Thao tác nhanh';

  @override
  String get teacherDashboardAssignmentHubSubtitle =>
      'Tìm, lọc và mở hub bài giao.';

  @override
  String teacherDashboardPendingJoinsCount(int count) {
    return '$count yêu cầu vào lớp';
  }

  @override
  String teacherDashboardDueSoonCount(int count) {
    return '$count sắp đến hạn';
  }

  @override
  String get teacherDashboardStatClasses => 'Lớp học';

  @override
  String get teacherDashboardStatStudents => 'Học sinh';

  @override
  String get teacherDashboardStatAssignments => 'Bài đã giao';

  @override
  String get teacherDashboardStatLiveModes => 'Phòng trực tiếp';

  @override
  String get teacherDashboardStatDraftExams => 'Đề nháp';

  @override
  String get teacherDashboardStatPublishedExams => 'Đã xuất bản';

  @override
  String get teacherDashboardStatNeedsAction => 'Cần xử lý';

  @override
  String get teacherDashboardShortcuts => 'Lối tắt';

  @override
  String get teacherDashboardShortcutExamBank => 'Kho đề thi';

  @override
  String get teacherDashboardShortcutNewSkillsExam => 'Đề kỹ năng mới';

  @override
  String get teacherDashboardShortcutOpen => 'Mở';

  @override
  String get teacherDashboardSectionLive => 'Phòng trực tiếp';

  @override
  String get teacherDashboardLiveEmpty =>
      'Chưa có bài giao ở chế độ trực tiếp. Giao đề ở chế độ Phòng thi trực tiếp để mở phiên.';

  @override
  String get teacherDashboardLiveWaitingSession =>
      'Chưa có phiên — mở phòng thi để bắt đầu';

  @override
  String get teacherDashboardLiveStatusGrading => 'Đang kết thúc phiên';

  @override
  String teacherDashboardLiveSessionStatus(String status) {
    return 'Phiên: $status';
  }

  @override
  String get teacherDashboardSectionGrading => 'Chờ chấm / xử lý';

  @override
  String teacherDashboardViewAllQueue(int count) {
    return 'Xem tất cả ($count)';
  }

  @override
  String get teacherDashboardViewAllQueueShort => 'Xem tất cả';

  @override
  String teacherDashboardQueueMoreHidden(int count) {
    return 'Còn thêm $count bài trong hàng chờ';
  }

  @override
  String get teacherDashboardGradingQueueAllTitle => 'Hàng chờ chấm điểm';

  @override
  String teacherDashboardGradingQueueAllSubtitle(int count) {
    return '$count bài cần bạn xử lý';
  }

  @override
  String teacherDashboardViewAllLiveQueue(int count) {
    return 'Tất cả phòng trực tiếp ($count)';
  }

  @override
  String get teacherDashboardLiveQueueAllTitle => 'Phòng trực tiếp';

  @override
  String teacherDashboardLiveQueueAllSubtitle(int count) {
    return '$count bài giao đang diễn ra realtime';
  }

  @override
  String get teacherDashboardScrollHint => 'Vuốt ngang để xem thêm phòng';

  @override
  String get teacherDashboardGradingEmpty =>
      'Hiện không có bài nộp nào cần bạn xử lý.';

  @override
  String get teacherDashboardGradingLoading => 'Đang tải hàng chờ chấm…';

  @override
  String get teacherDashboardSectionAssignments => 'Bài đã giao';

  @override
  String get teacherDashboardAssignmentsPerClassHint =>
      'Lọc theo lớp — xem lịch sử trong từng lớp.';

  @override
  String get teacherDashboardFilterByClass => 'Lớp';

  @override
  String get teacherDashboardAllClasses => 'Tất cả lớp';

  @override
  String get teacherDashboardFilterAll => 'Tất cả';

  @override
  String get teacherDashboardFilterPublic => 'Liên kết công khai';

  @override
  String get teacherDashboardSearchHint => 'Tìm theo tên đề';

  @override
  String get teacherDashboardAudienceClass => 'Lớp';

  @override
  String get teacherDashboardAudiencePublic => 'Công khai';

  @override
  String teacherDashboardDue(String date) {
    return 'Hạn: $date';
  }

  @override
  String teacherDashboardWindow(String opens, String closes) {
    return '$opens – $closes';
  }

  @override
  String teacherDashboardClassLabel(String name) {
    return 'Lớp: $name';
  }

  @override
  String get teacherInboxPublicAssignment => 'Bài giao công khai';

  @override
  String teacherInboxItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mục',
      one: '1 mục',
    );
    return '$_temp0';
  }

  @override
  String get teacherDashboardOpenConsole => 'Mở phòng thi';

  @override
  String get teacherDashboardOpenGrading => 'Mở chấm điểm';

  @override
  String get teacherDashboardStudentUnknown => 'Học viên';

  @override
  String get teacherDashboardGradingChipManual => 'Chấm tay';

  @override
  String get teacherDashboardGradingChipAi => 'Chấm AI';

  @override
  String get teacherDashboardGradingChipRelease => 'Công bố điểm';

  @override
  String get teacherExamConsoleTitle => 'Phòng thi trực tiếp';

  @override
  String get teacherExamSessionLiveRosterTitle => 'Học sinh trong phòng chờ';

  @override
  String get teacherExamSessionLiveRosterTitleLive => 'Học sinh trong bài thi';

  @override
  String get teacherExamSessionLiveRosterHint =>
      'Số lượng và danh sách cập nhật theo thời gian thực khi học sinh vào phòng.';

  @override
  String get teacherExamParticipantNotReady => 'Chưa sẵn sàng';

  @override
  String get teacherExamParticipantReady => 'Sẵn sàng';

  @override
  String get teacherExamParticipantInProgress => 'Đang làm';

  @override
  String get teacherExamParticipantSubmitted => 'Đã nộp';

  @override
  String get teacherExamParticipantExpired => 'Hết giờ';

  @override
  String get teacherExamParticipantVoided => 'Đã rời';

  @override
  String teacherExamSessionJoinedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count học sinh đã vào',
      one: '1 học sinh đã vào',
    );
    return '$_temp0';
  }

  @override
  String get teacherExamSessionNoParticipantsYet =>
      'Chưa có học sinh trong phòng chờ.';

  @override
  String get teacherExamSessionTabControl => 'Điều khiển phiên';

  @override
  String get teacherExamSessionTabLiveMonitor => 'Giám sát trực tiếp';

  @override
  String get teacherExamSessionShowDetails => 'Chi tiết';

  @override
  String get teacherExamSessionHideDetails => 'Thu gọn';

  @override
  String teacherLiveMonitorSummaryInProgress(int count) {
    return '$count đang làm';
  }

  @override
  String teacherLiveMonitorSummarySubmitted(int count) {
    return '$count đã nộp';
  }

  @override
  String teacherLiveMonitorSummaryFlagged(int count) {
    return '$count cảnh báo';
  }

  @override
  String teacherLiveMonitorSummaryAvgProgress(double percent) {
    return 'TB $percent%';
  }

  @override
  String teacherLiveMonitorSummaryLine(
      int inProgress, int submitted, int flagged, String avg) {
    return '$inProgress đang làm · $submitted đã nộp · $flagged cảnh báo · TB $avg%';
  }

  @override
  String get teacherLiveMonitorFilterAll => 'Tất cả';

  @override
  String get teacherLiveMonitorFilterInProgress => 'Đang làm';

  @override
  String get teacherLiveMonitorFilterSubmitted => 'Đã nộp';

  @override
  String get teacherLiveMonitorFilterFlagged => 'Cảnh báo';

  @override
  String get teacherLiveMonitorNoStudents =>
      'Không có học sinh phù hợp bộ lọc.';

  @override
  String teacherLiveMonitorProgressLabel(
      int answered, int total, double percent) {
    return '$answered/$total · $percent%';
  }

  @override
  String get teacherLiveMonitorIntegrityHigh => 'Rủi ro gian lận cao';

  @override
  String get teacherLiveMonitorIntegrityMedium => 'Rủi ro gian lận trung bình';

  @override
  String get teacherLiveMonitorCurrentQuestion => 'Đang làm';

  @override
  String get teacherLiveMonitorStatusSubmitted => 'Đã nộp';

  @override
  String get teacherLiveMonitorIntegrityLabel => 'Giám sát';

  @override
  String get teacherLiveMonitorTabSwitches => 'Chuyển tab';

  @override
  String get teacherLiveMonitorFocusLoss => 'Mất tiêu điểm';

  @override
  String get teacherLiveMonitorCopyPaste => 'Copy/paste';

  @override
  String get teacherLiveMonitorDetailProgress => 'Tiến độ';

  @override
  String get teacherLiveMonitorDetailSections => 'Kỹ năng';

  @override
  String get teacherLiveMonitorDetailGrammar => 'Đáp án ngữ pháp';

  @override
  String get teacherLiveMonitorGrammarQuestion => 'Câu';

  @override
  String get teacherLiveMonitorGrammarNotAnswered => 'Chưa trả lời';

  @override
  String get teacherLiveMonitorGrammarCorrect => 'Đúng';

  @override
  String get teacherLiveMonitorGrammarWrong => 'Sai';

  @override
  String get teacherLiveMonitorWatchScreen => 'Xem màn hình trực tiếp';

  @override
  String get teacherLiveMonitorQuestionStripLegend =>
      'Xanh: đúng · Đỏ: sai · Xám: chưa làm';

  @override
  String teacherLiveMirrorPageTitle(String name, String exam) {
    return '$name — $exam';
  }

  @override
  String teacherLiveMirrorPageTitleSimple(String name) {
    return 'Giám sát — $name';
  }

  @override
  String get teacherLiveMirrorLiveBadge =>
      'Trực tiếp — đang theo dõi màn hình học sinh';

  @override
  String get teacherLiveMirrorNoContent => 'Không có nội dung bài thi.';

  @override
  String get teacherLiveMirrorWritingDraft => 'Bài viết nháp (trực tiếp)';

  @override
  String get teacherLiveMirrorWritingEmpty => 'Học sinh chưa bắt đầu viết.';

  @override
  String teacherLiveMirrorWordCount(int count) {
    return '$count từ';
  }

  @override
  String get teacherLiveMirrorSkillCompleted => 'Đã hoàn thành phần kỹ năng';

  @override
  String teacherLiveMirrorSkillInProgress(String skill) {
    return 'Đang làm $skill…';
  }

  @override
  String teacherLiveMirrorBrowsingPart(String part) {
    return 'Đang xem: $part';
  }

  @override
  String get teacherLiveMirrorFollowStudent => 'Theo học sinh';

  @override
  String get teacherLiveMirrorQuestionMap => 'Bản đồ câu hỏi';

  @override
  String get teacherLiveMirrorWritingPrompt => 'Đề bài';

  @override
  String get teacherLiveMirrorListeningEmpty =>
      'Học sinh chưa nhập dictation nào.';

  @override
  String teacherLiveMirrorListeningProgress(int saved, int total) {
    return 'Tiến độ dictation: $saved / $total câu';
  }

  @override
  String teacherLiveMirrorListeningCue(int number) {
    return 'Câu $number';
  }

  @override
  String get teacherLiveMirrorSpeakingInProgress =>
      'Học sinh đang làm bài speaking.';

  @override
  String get teacherLiveMirrorReadingEmpty =>
      'Học sinh chưa trả lời câu reading nào.';

  @override
  String teacherLiveMirrorReadingQuestion(int number) {
    return 'Câu $number';
  }

  @override
  String teacherLiveMirrorExerciseLabel(int index, int total) {
    return 'Bài $index/$total';
  }

  @override
  String get examSessionStatusLobby => 'Phòng chờ';

  @override
  String get examSessionStatusLive => 'Đang làm bài';

  @override
  String get examSessionStatusClosed => 'Đã kết thúc';

  @override
  String get examSessionStatusCanceled => 'Đã hủy';

  @override
  String examSessionCreatedAt(String date) {
    return 'Tạo phiên lúc $date';
  }

  @override
  String examSessionScheduledEndAt(String date) {
    return 'Kết thúc dự kiến: $date';
  }

  @override
  String examSessionTimeLimitOnStart(int minutes) {
    return 'Giới hạn: $minutes phút (bắt đầu đếm khi bạn mở phiên)';
  }

  @override
  String get examSessionEndsWhenTeacherEnds =>
      'Không giới hạn thời gian — kết thúc khi giáo viên dừng phiên';

  @override
  String examSessionReadyCount(int ready, int total) {
    return '$ready sẵn sàng · $total trong phòng';
  }

  @override
  String get examSessionStudentReady => 'Sẵn sàng';

  @override
  String get examSessionStudentNotReady => 'Chưa sẵn sàng';

  @override
  String get examSessionMarkReady => 'Tôi đã sẵn sàng';

  @override
  String get examSessionMarkNotReady => 'Chưa sẵn sàng';

  @override
  String get examSessionCancelReady => 'Hủy sẵn sàng';

  @override
  String get examSessionReadyHint =>
      'Báo giáo viên bạn đã sẵn sàng. Cập nhật theo thời gian thực.';

  @override
  String get examSessionKickStudentTitle => 'Đưa học sinh ra khỏi phòng?';

  @override
  String examSessionKickStudentConfirm(String name) {
    return 'Đưa $name ra khỏi phòng thi? Học sinh sẽ thoát phòng chờ ngay.';
  }

  @override
  String get examSessionKickStudentAction => 'Đưa ra';

  @override
  String get examSessionKickStudentDone => 'Đã đưa học sinh ra khỏi phòng.';

  @override
  String get examSessionKickedByTeacher =>
      'Giáo viên đã đưa bạn ra khỏi phiên thi này.';

  @override
  String get examSessionLobbyParticipantsTitle => 'Người tham gia';

  @override
  String get examSessionLobbyParticipantsHint =>
      'Ai đã vào phòng chờ (cập nhật trực tiếp).';

  @override
  String get teacherExamCreateSession => 'Tạo / làm mới phòng chờ';

  @override
  String get teacherExamStartSession => 'Bắt đầu cho mọi người';

  @override
  String get teacherExamEndSession => 'Kết thúc và nộp tất cả';

  @override
  String get teacherExamEndSessionConfirm =>
      'Hành động này kết thúc phiên và nộp bài thay cho mọi học sinh — kể cả người đang làm dở. Không thể hoàn tác.';

  @override
  String teacherExamEndSessionTypePrompt(int count) {
    return 'Gõ $count để xác nhận nộp bài thay cho mọi học sinh trong phiên.';
  }

  @override
  String get teacherEmptyInboxCta => 'Xem lớp học';

  @override
  String get teacherEmptyCalendarCta => 'Tạo đề mới';

  @override
  String get teacherEmptyGradebookCta => 'Mở lớp học';

  @override
  String get teacherSaveStateSaving => 'Đang lưu…';

  @override
  String teacherSaveStateSavedAt(String time) {
    return 'Đã lưu $time';
  }

  @override
  String get teacherSaveStateError => 'Lưu thất bại';

  @override
  String get teacherSaveStateRetry => 'Thử lại';

  @override
  String get teacherExamValidationBanner =>
      'Sửa các lỗi bên dưới trước khi xuất bản.';

  @override
  String get teacherExamGradingTitle => 'Chấm điểm';

  @override
  String get teacherExamRunAi => 'Gợi ý AI';

  @override
  String get teacherExamReleaseResults => 'Công bố điểm';

  @override
  String get teacherExamGradingConsole => 'Phòng thi';

  @override
  String get teacherExamGradingGrade => 'Chấm';

  @override
  String get teacherMyExamsTitle => 'Đề thi của tôi';

  @override
  String get teacherExamNewExam => 'Đề mới';

  @override
  String get teacherExamsListEmpty => 'Chưa có đề nào. Nhấn + để tạo bản nháp.';

  @override
  String get teacherExamUntitled => 'Đề chưa đặt tên';

  @override
  String get teacherExamStatusDraft => 'Nháp';

  @override
  String get teacherExamStatusPublished => 'Đã xuất bản';

  @override
  String get teacherExamStatusArchived => 'Đã lưu trữ';

  @override
  String get teacherExamEditorTitle => 'Soạn đề';

  @override
  String get teacherExamSaveDraft => 'Lưu nháp';

  @override
  String get teacherExamPublish => 'Xuất bản';

  @override
  String get teacherExamAddMcq => 'Trắc nghiệm';

  @override
  String get teacherExamAddEssay => 'Tự luận';

  @override
  String get teacherExamStemLabel => 'Câu hỏi';

  @override
  String get teacherExamOptionsHint => 'Phương án';

  @override
  String get teacherExamOptionsPipeHint => 'Ngăn cách phương án bằng dấu |';

  @override
  String get teacherExamCorrectIndex => 'Chỉ số đáp án đúng (bắt đầu từ 0)';

  @override
  String get teacherExamEssayPrompt => 'Đề bài tự luận';

  @override
  String get teacherExamPoints => 'Điểm';

  @override
  String get teacherExamItemsTitle => 'Câu hỏi';

  @override
  String get teacherExamNoItemsHint =>
      'Thêm ít nhất một câu trước khi xuất bản.';

  @override
  String get teacherExamPublishNeedItems =>
      'Thêm ít nhất một câu trước khi xuất bản.';

  @override
  String get teacherExamDraftSaved => 'Đã lưu nháp';

  @override
  String get teacherExamPublished => 'Đã xuất bản đề';

  @override
  String get teacherExamOnlyDraftEditable =>
      'Chỉ đề ở trạng thái nháp mới chỉnh sửa được.';

  @override
  String get teacherExamReadOnlyPublished =>
      'Đề đã xuất bản. Tạo đề nháp mới để đổi nội dung.';

  @override
  String get teacherExamTitleLabel => 'Tiêu đề';

  @override
  String get teacherExamTitleHint => 'vd. Kiểm tra giữa kỳ — Đọc & Nghe';

  @override
  String get teacherExamDescriptionLabel => 'Mô tả';

  @override
  String get teacherExamResultsPolicy => 'Khi nào học viên xem điểm';

  @override
  String get teacherExamPolicyAfterSubmit =>
      'Ngay sau khi nộp (nếu chấm tự động)';

  @override
  String get teacherExamPolicyAfterRelease => 'Sau khi giáo viên công bố điểm';

  @override
  String get teacherExamPolicyNever => 'Không hiển thị';

  @override
  String get teacherAssignmentWizardTitle => 'Giao bài kiểm tra';

  @override
  String get teacherAssignExamDialogSubtitle =>
      'Chọn lớp, hình thức và thời gian giao bài.';

  @override
  String teacherAssignExamDialogSubtitleExam(String examTitle) {
    return 'Giao đề «$examTitle» cho lớp hoặc link.';
  }

  @override
  String get teacherAssignExamModeHintSelfPaced =>
      'Học sinh tự bắt đầu trước hạn nộp.';

  @override
  String get teacherAssignExamModeHintScheduled =>
      'Mở và đóng theo ngày giờ (hiện trên Lịch Schedule).';

  @override
  String get teacherAssignExamModeHintRealtime =>
      'Thi trực tiếp: mở phòng trên lớp, hoặc đặt giờ để học sinh biết khi vào làm.';

  @override
  String get teacherAssignExamModeHintPractice =>
      'Luyện tập — không tính điểm chính thức.';

  @override
  String get teacherAssignExamRealtimeNote =>
      'Sau khi giao, mở phòng trực tiếp trên tổng quan khi sẵn sàng. Thời gian làm bài (phút) bắt đầu khi bạn bấm Bắt đầu; hết giờ hệ thống tự nộp bài.';

  @override
  String get teacherAssignExamCalendarNote =>
      'Lịch Schedule hiển thị Mở / Hạn nộp / Đóng. «Đang diễn ra» trên lịch = đang trong khung giờ, không phải thi trực tiếp.';

  @override
  String get teacherAssignExamAdvancedRules => 'Lượt làm & kết quả';

  @override
  String get teacherAssignExamAdvancedRulesHint =>
      'Số lần làm, lúc xem điểm, nộp từng phần';

  @override
  String get teacherAssignExamRulesShow => 'Tùy chỉnh';

  @override
  String get teacherAssignExamRulesHide => 'Thu gọn';

  @override
  String get teacherAssignmentClassroom => 'Lớp học';

  @override
  String get teacherAssignmentPickClass => 'Hãy chọn lớp.';

  @override
  String get teacherAssignmentMode => 'Hình thức';

  @override
  String get teacherAssignmentDueDate => 'Hạn nộp (tuỳ chọn)';

  @override
  String get teacherAssignmentOpensAt => 'Mở lúc';

  @override
  String get teacherAssignmentClosesAt => 'Đóng lúc';

  @override
  String get teacherAssignmentTimeLimitSec =>
      'Giới hạn thời gian (giây, tuỳ chọn)';

  @override
  String get teacherAssignmentTimeLimitMinutes => 'Thời gian làm bài (phút)';

  @override
  String get teacherAssignmentTimeLimitMinutesHint => 'vd: 60';

  @override
  String get teacherAssignmentTimeLimitHelp =>
      'Đồng hồ bắt đầu khi học sinh vào làm (hoặc khi bạn bắt đầu phòng live). Để trống nếu không giới hạn từng lượt — chỉ áp dụng hạn nộp / khung giờ thi.';

  @override
  String teacherAssignmentTimeLimitPresetMinutes(int minutes) {
    return '$minutes phút';
  }

  @override
  String get teacherAssignmentCreate => 'Tạo bài giao';

  @override
  String get teacherAssignmentExamNotPublished =>
      'Hãy xuất bản đề trước, rồi mới giao.';

  @override
  String get teacherAssignmentOptional => 'Tuỳ chọn';

  @override
  String get teacherAssignmentAllowPartialSubmit =>
      'Cho phép nộp khi chưa làm hết';

  @override
  String get teacherAssignmentAllowPartialSubmitHint =>
      'Học sinh có thể nộp dù còn phần chưa làm; phần chưa làm được 0 điểm.';

  @override
  String get teacherAssignmentSectionAudience => 'Đối tượng';

  @override
  String get teacherAssignmentSectionDelivery => 'Hình thức & thời gian';

  @override
  String get teacherAssignmentSectionRules => 'Lượt làm & kết quả';

  @override
  String get teacherAssignmentAttemptPolicy => 'Số lần làm bài';

  @override
  String get teacherAssignmentAttemptSingle => 'Một lần';

  @override
  String get teacherAssignmentAttemptUnlimited => 'Không giới hạn';

  @override
  String get teacherAssignmentAttemptLimited => 'Giới hạn';

  @override
  String get teacherAssignmentMaxAttempts => 'Số lần tối đa';

  @override
  String get teacherAssignmentShowResults => 'Xem kết quả';

  @override
  String get examPartialSubmitTitle => 'Nộp bài chưa hoàn thành?';

  @override
  String get examPartialSubmitMessage =>
      'Bạn chưa hoàn thành mọi phần. Phần chưa làm sẽ không được tính điểm.';

  @override
  String get examPartialSubmitIncompleteHeader => 'Còn thiếu:';

  @override
  String get examPartialSubmitConfirm => 'Vẫn nộp bài';

  @override
  String get teacherGradingHubFilterAll => 'Tất cả';

  @override
  String get teacherGradingHubFilterInProgress => 'Đang làm';

  @override
  String get teacherGradingHubFilterSubmitted => 'Đã nộp';

  @override
  String get teacherGradingHubFilterPendingManual => 'Cần chấm';

  @override
  String get teacherGradingHubFilterFinalized => 'Đã chấm';

  @override
  String get teacherGradingHubFilterReleased => 'Đã công bố';

  @override
  String get teacherGradingHubFilterPartial => 'Nộp thiếu';

  @override
  String get teacherGradingHubPartialBadge => 'Nộp thiếu';

  @override
  String get teacherGradingHubForceEndBadge => 'Kết thúc phiên';

  @override
  String get teacherGradingHubBatchAi => 'Chấm AI tất cả bài đã nộp';

  @override
  String get teacherGradingHubBatchAiDone =>
      'Đã chạy chấm AI cho các bài đã nộp';

  @override
  String get teacherGradingHubNotReleased => 'Chưa công bố';

  @override
  String teacherGradingHubScoreLine(String awarded, String max) {
    return 'Điểm: $awarded / $max';
  }

  @override
  String teacherGradingHubSubmittedAt(String date) {
    return 'Nộp lúc $date';
  }

  @override
  String teacherGradingHubStatsLine(
      int submitted, int inProgress, int partial) {
    return '$submitted đã nộp · $inProgress đang làm · $partial nộp thiếu';
  }

  @override
  String get teacherGradingHubEmpty => 'Chưa có bài làm cho bài giao này.';

  @override
  String get teacherGradingHubOpenGrade => 'Chấm bài';

  @override
  String get teacherGradingHubBatchRelease => 'Công bố tất cả';

  @override
  String get teacherGradingHubBatchReleaseDone => 'Đã công bố kết quả';

  @override
  String get teacherGradingHubBatchFinalize => 'Hoàn tất tất cả';

  @override
  String get teacherGradingHubBatchFinalizeDone => 'Đã hoàn tất bài nộp';

  @override
  String get teacherGradingHubExportExcel => 'Xuất điểm Excel';

  @override
  String get teacherGradingHubExportDone => 'Đã tải file Excel';

  @override
  String get teacherGradingHubExportEmpty => 'Chưa có bài làm để xuất';

  @override
  String teacherGradingHubExportMobileHint(String filename) {
    return 'Xuất Excel trên web giáo viên; file: $filename';
  }

  @override
  String get teacherGradingHubExportMobileCopied =>
      'Xuất file trên web; đã sao chép gợi ý';

  @override
  String get teacherExamDuplicate => 'Nhân bản';

  @override
  String get teacherExamDuplicated => 'Đã nhân bản đề thi (bản nháp)';

  @override
  String get teacherAssignmentDuplicate => 'Nhân bản giao bài';

  @override
  String get teacherAssignmentDuplicated => 'Đã nhân bản giao bài';

  @override
  String get teacherAssignmentExtendDeadline => 'Gia hạn hạn nộp';

  @override
  String get teacherAssignmentDeadlineSaved => 'Đã cập nhật hạn';

  @override
  String get teacherMemberApprove => 'Duyệt';

  @override
  String get teacherMemberReject => 'Từ chối';

  @override
  String get teacherMemberApproved => 'Đã duyệt học sinh';

  @override
  String get teacherMemberRejected => 'Đã từ chối yêu cầu';

  @override
  String get teacherGradebookTitle => 'Sổ điểm';

  @override
  String get teacherGradebookStudent => 'Học sinh';

  @override
  String get teacherGradebookExport => 'Xuất CSV';

  @override
  String get teacherGradebookExportCopied =>
      'Đã sao chép sổ điểm (dán vào Excel)';

  @override
  String get teacherGradebookExportDownloaded => 'Đã tải file CSV sổ điểm';

  @override
  String get teacherGradebookNoAssignments => 'Lớp chưa có bài giao nào.';

  @override
  String get teacherGradebookKpiStudents => 'Học sinh';

  @override
  String get teacherGradebookKpiAssignments => 'Bài giao';

  @override
  String get teacherGradebookKpiClassAvg => 'Điểm TB lớp';

  @override
  String get teacherGradebookKpiPending => 'Ô cần chấm';

  @override
  String get teacherGradebookSearchHint => 'Tìm tên hoặc email học sinh';

  @override
  String get teacherGradebookFilterMode => 'Hình thức bài';

  @override
  String get teacherGradebookFilterAllModes => 'Tất cả hình thức';

  @override
  String get teacherGradebookSortLabel => 'Sắp xếp';

  @override
  String get teacherGradebookSortName => 'Tên A→Z';

  @override
  String get teacherGradebookSortAvg => 'Điểm TB';

  @override
  String get teacherGradebookHideEmpty => 'Ẩn HS chưa nộp bài';

  @override
  String teacherGradebookShowingCount(int count) {
    return 'Hiển thị $count học sinh';
  }

  @override
  String get teacherGradebookNoStudentsMatch =>
      'Không có học sinh khớp bộ lọc.';

  @override
  String get teacherGradebookNoColumnsForFilter =>
      'Không có bài giao theo hình thức đã chọn.';

  @override
  String get teacherGradebookColAvg => 'TB';

  @override
  String get teacherGradebookClassAverage => 'Trung bình lớp';

  @override
  String get teacherGradebookCellNotStarted => 'Chưa làm';

  @override
  String get teacherGradebookCellPendingGrading => 'Chờ chấm';

  @override
  String get teacherGradebookTapHint =>
      'Chạm điểm để mở chấm bài; chạm ô trống để mở hub bài giao.';

  @override
  String get teacherNavCalendar => 'Lịch';

  @override
  String get teacherCalendarEmpty =>
      'Không có sự kiện nào trong khoảng thời gian này.';

  @override
  String get teacherCalendarKindDue => 'Hạn nộp';

  @override
  String get teacherCalendarKindOpens => 'Mở';

  @override
  String get teacherCalendarKindCloses => 'Đóng';

  @override
  String get teacherCalendarKindLive => 'Đang diễn ra';

  @override
  String get teacherCalendarViewMonth => 'Tháng';

  @override
  String get teacherCalendarViewList => 'Danh sách';

  @override
  String get teacherCalendarToday => 'Hôm nay';

  @override
  String get teacherCalendarNoDayEvents => 'Không có sự kiện ngày này.';

  @override
  String get teacherCalendarGoToAssignment => 'Xem bài giao';

  @override
  String get teacherCalendarPageSubtitle =>
      'Hạn nộp, phòng trực tiếp và khung thời gian bài giao.';

  @override
  String get teacherCalendarViewWeek => 'Tuần';

  @override
  String get teacherCalendarKpiDueWeek => 'Hạn tuần này';

  @override
  String get teacherCalendarKpiOpens => 'Sắp mở';

  @override
  String get teacherCalendarKpiLive => 'Trực tiếp';

  @override
  String get teacherCalendarKpiTotal => 'Tổng sự kiện';

  @override
  String get teacherCalendarLegendTitle => 'Chú thích';

  @override
  String get teacherCalendarSearchHint => 'Tìm bài giao…';

  @override
  String get teacherCalendarFilterClassroomLabel => 'Lớp';

  @override
  String get teacherCalendarFilterClassroomAll => 'Tất cả lớp';

  @override
  String get teacherCalendarFilterAll => 'Tất cả';

  @override
  String get teacherCalendarAgendaTitle => 'Lịch trình';

  @override
  String teacherCalendarGroupsOnDay(int count) {
    return '$count nhóm bài giao';
  }

  @override
  String get teacherCalendarSectionToday => 'Hôm nay';

  @override
  String get teacherCalendarSectionUpcoming => 'Sắp tới';

  @override
  String get teacherCalendarSectionPast => 'Đã qua';

  @override
  String get teacherCalendarRelativeNow => 'Bây giờ';

  @override
  String teacherCalendarRelativeOverdueDays(int count) {
    return 'Quá hạn $count ngày';
  }

  @override
  String teacherCalendarRelativeOverdueHours(int count) {
    return 'Quá hạn $count giờ';
  }

  @override
  String teacherCalendarRelativeOverdueMinutes(int count) {
    return 'Quá hạn $count phút';
  }

  @override
  String teacherCalendarRelativeInDays(int count) {
    return 'Còn $count ngày';
  }

  @override
  String teacherCalendarRelativeInHours(int count) {
    return 'Còn $count giờ';
  }

  @override
  String teacherCalendarRelativeInMinutes(int count) {
    return 'Còn $count phút';
  }

  @override
  String get teacherDashboardActionItems => 'Cần xử lý';

  @override
  String get teacherDashboardPendingJoins => 'Chờ duyệt vào lớp';

  @override
  String get teacherDashboardDueSoon => 'Sắp đến hạn';

  @override
  String teacherDashboardNeedsGrading(int count) {
    return '$count bài cần chấm';
  }

  @override
  String get teacherAssignmentPresetLabel => 'Mẫu cấu hình';

  @override
  String get teacherAssignmentPresetSave => 'Lưu mẫu';

  @override
  String get teacherAssignmentPresetSaved => 'Đã lưu mẫu';

  @override
  String get teacherAssignmentPresetNone => 'Chưa có mẫu';

  @override
  String get examModePractice => 'Luyện tập (không tính điểm)';

  @override
  String get teacherAnalyticsTitle => 'Phân tích';

  @override
  String get teacherAnalyticsSubmissionsChart => 'Bài nộp theo ngày';

  @override
  String get teacherAnalyticsScoreChart => 'Phân bố điểm';

  @override
  String get teacherAnalyticsIntegrityChart => 'Cảnh báo gian lận';

  @override
  String get teacherAnalyticsIntegrityHigh => 'Rủi ro cao';

  @override
  String get teacherAnalyticsIntegrityMedium => 'Trung bình';

  @override
  String get teacherAnalyticsIntegrityLow => 'Thấp';

  @override
  String get teacherAnalyticsNoData => 'Chưa đủ dữ liệu';

  @override
  String get teacherAnalyticsPeriod7d => '7 ngày';

  @override
  String get teacherAnalyticsPeriod14d => '14 ngày';

  @override
  String get teacherAnalyticsPeriod30d => '30 ngày';

  @override
  String get teacherAnalyticsActiveStudents => 'Học sinh đang học';

  @override
  String get teacherAnalyticsActiveAssignments => 'Bài đang giao';

  @override
  String get teacherAnalyticsSubmissions => 'Bài đã nộp';

  @override
  String get teacherAnalyticsPendingGrading => 'Chờ chấm';

  @override
  String get teacherAnalyticsAvgScore => 'Điểm TB';

  @override
  String get teacherAnalyticsSkillBreakdown => 'Điểm TB từng kỹ năng';

  @override
  String get teacherAnalyticsSkillListening => 'Nghe';

  @override
  String get teacherAnalyticsSkillReading => 'Đọc';

  @override
  String get teacherAnalyticsSkillWriting => 'Viết';

  @override
  String get teacherAnalyticsSkillSpeaking => 'Nói';

  @override
  String get teacherAnalyticsSkillGrammar => 'Ngữ pháp';

  @override
  String teacherAnalyticsWeakSkillHint(String skill, String score) {
    return 'Kỹ năng $skill TB $score/10 — nên bổ sung bài luyện tập.';
  }

  @override
  String get teacherAnalyticsModeBreakdown => 'Loại bài giao';

  @override
  String get teacherAnalyticsModeHomework => 'Bài tập về nhà';

  @override
  String get teacherAnalyticsModeLive => 'Kiểm tra trực tiếp';

  @override
  String get teacherAnalyticsModeSelfPaced => 'Tự luyện';

  @override
  String get teacherNavAnalytics => 'Phân tích';

  @override
  String get teacherClassTabActivity => 'Hoạt động';

  @override
  String get teacherClassActivityEmpty => 'Chưa có hoạt động nào.';

  @override
  String get teacherCoTeacherAdd => 'Thêm giáo viên phụ';

  @override
  String get teacherCoTeacherEmailHint => 'Email giáo viên';

  @override
  String get teacherCoTeacherUsernameHint => 'Tìm theo username';

  @override
  String get teacherCoTeacherSearchPlaceholder => 'Nhập username để tìm…';

  @override
  String get teacherCoTeacherSearchEmpty => 'Không tìm thấy giáo viên';

  @override
  String get teacherCoTeacherPrimaryTeacher => 'Giáo viên chính';

  @override
  String get teacherCoTeacherListTitle => 'Giáo viên phụ';

  @override
  String get teacherCoTeacherNone => 'Chưa có giáo viên phụ';

  @override
  String get teacherCoTeacherRemove => 'Gỡ';

  @override
  String get teacherCoTeacherRemoveConfirm => 'Gỡ giáo viên phụ khỏi lớp này?';

  @override
  String get teacherClassSettingsTeam => 'Đội ngũ giảng dạy';

  @override
  String get teacherClassSettingsInvite => 'Mời & tham gia';

  @override
  String get teacherClassSettingsStats => 'Tóm tắt lớp';

  @override
  String get teacherClassSettingsDanger => 'Thao tác nâng cao';

  @override
  String get teacherInviteToken => 'Token link mời';

  @override
  String get teacherInviteTokenHint =>
      'Gửi token này để học sinh tham gia bằng invite link';

  @override
  String get copyInviteToken => 'Sao chép token';

  @override
  String get teacherCoTeacherAdded => 'Đã thêm giáo viên phụ';

  @override
  String get teacherCoTeacherInviteSent => 'Đã gửi lời mời';

  @override
  String get teacherCoTeacherPending => 'Chờ duyệt';

  @override
  String get teacherCoTeacherRemoved => 'Đã gỡ giáo viên phụ';

  @override
  String get teacherIntegrationsTitle => 'Tích hợp';

  @override
  String get teacherGoogleClassroomLink => 'Liên kết Google Classroom';

  @override
  String get teacherGoogleClassroomUnlink => 'Hủy liên kết Google Classroom';

  @override
  String get teacherGoogleClassroomCourseId => 'Mã khóa Google';

  @override
  String get teacherRubricTitle => 'Chấm theo rubric';

  @override
  String get teacherRubricCriterion => 'Tiêu chí';

  @override
  String get teacherAdaptiveEnabled => 'Độ khó thích ứng';

  @override
  String get teacherGradingLiveProgress => 'Tiến độ trực tiếp';

  @override
  String get teacherClassViewStudentAttempts => 'Bài làm học sinh';

  @override
  String get teacherClassTapToViewAttempts => 'Chạm để xem danh sách bài nộp';

  @override
  String get teacherClassOpenAttemptsList => 'Xem bài làm';

  @override
  String get teacherGradingStudentAttemptsTitle => 'Danh sách bài làm';

  @override
  String get teacherGradingStatusInProgress => 'Đang làm';

  @override
  String get teacherGradingStatusSubmitted => 'Đã nộp';

  @override
  String get teacherGradingStatePendingAuto => 'Chấm tự động';

  @override
  String get teacherGradingStatePendingAi => 'Chờ AI';

  @override
  String get teacherGradingStatePendingManual => 'Cần chấm tay';

  @override
  String get teacherGradingStateFinalized => 'Đã chấm';

  @override
  String teacherGradingStartedAt(String date) {
    return 'Bắt đầu $date';
  }

  @override
  String get teacherGradingFinalize => 'Hoàn tất chấm';

  @override
  String get teacherGradingFinalized => 'Đã hoàn tất chấm';

  @override
  String get teacherGradingCompletenessComplete => 'Nộp đủ';

  @override
  String get teacherGradingCompletenessPartial => 'Nộp thiếu';

  @override
  String get teacherGradingCompletenessForceEnd => 'Giáo viên kết thúc phiên';

  @override
  String get teacherGradingAiRationale => 'Nhận xét AI';

  @override
  String get teacherGradingIntegratedScores => 'Điểm từng phần';

  @override
  String get teacherGradingDetailTitle => 'Chấm bài làm';

  @override
  String get teacherGradingSaveScores => 'Lưu điểm';

  @override
  String get teacherGradingSaved => 'Đã lưu điểm';

  @override
  String get teacherGradingNotesHint => 'Nhận xét';

  @override
  String get teacherGradingAwardedPoints => 'Điểm cho';

  @override
  String get teacherGradingOnlySubmitted =>
      'Chỉnh điểm sau khi học viên đã nộp bài.';

  @override
  String get teacherAttemptGradeHeaderSubtitle =>
      'Xem bài làm, chỉnh điểm và công bố kết quả khi sẵn sàng.';

  @override
  String get teacherAttemptGradeExamLabel => 'Đề';

  @override
  String teacherAttemptGradeStartedLine(String date) {
    return 'Bắt đầu $date';
  }

  @override
  String teacherAttemptGradeSubmittedLine(String date) {
    return 'Nộp lúc $date';
  }

  @override
  String get teacherAttemptGradeReleasedYes => 'Đã công bố cho học sinh';

  @override
  String get teacherAttemptGradeReleasedNo => 'Chưa công bố';

  @override
  String get teacherAttemptGradeTotalScore => 'Điểm theo kỹ năng';

  @override
  String integratedSkillScoreLabel(String score) {
    return '$score / 10';
  }

  @override
  String get integratedSkillScorePending => 'Chờ chấm';

  @override
  String get integratedSkillNoSubmission => 'Không nộp';

  @override
  String get integratedSkillFinalAvg => 'Điểm TB';

  @override
  String get integratedSkillFinalPartial => 'TB tạm tính';

  @override
  String get integratedSkillGrammar => 'Ngữ pháp';

  @override
  String get integratedSkillListening => 'Nghe';

  @override
  String get integratedSkillReading => 'Đọc';

  @override
  String get integratedSkillWriting => 'Viết';

  @override
  String get integratedSkillSpeaking => 'Nói';

  @override
  String get integratedSkillEnterScore => 'Nhập điểm (0–10)';

  @override
  String get integratedSkillScoreSaved => 'Đã lưu điểm';

  @override
  String get integratedSkillSaveScore => 'Lưu điểm';

  @override
  String get integratedScoresAwaiting =>
      'Điểm đang được tính. Nếu lâu quá, hãy tải lại trang.';

  @override
  String get integratedGradingAvgFormulaHint =>
      'Điểm cuối = trung bình cộng các kỹ năng đã chấm (mỗi kỹ năng 0–10). Kỹ năng chờ chấm và kỹ năng học sinh không nộp đều không tính vào TB.';

  @override
  String get integratedGradingColumnSkill => 'Kỹ năng';

  @override
  String get integratedGradingColumnScore => 'Điểm';

  @override
  String get integratedWritingGradingEssayLabel => 'Bài viết học sinh';

  @override
  String integratedWritingGradingWordCount(String count) {
    return '$count từ';
  }

  @override
  String get integratedWritingGradingNoDraft =>
      'Chưa có nội dung bài viết trong lượt làm này.';

  @override
  String get integratedWritingGradingRunAi => 'Chấm bằng AI';

  @override
  String get integratedWritingGradingApplyAi => 'Dùng điểm AI';

  @override
  String get integratedWritingGradingManual => 'Chấm tay';

  @override
  String integratedWritingGradingAiBand(String band) {
    return 'Band AI: $band / 9';
  }

  @override
  String integratedWritingGradingAiExamScore(String score) {
    return 'Điểm đề xuất: $score / 10';
  }

  @override
  String integratedGrammarItemResult(String awarded, String max) {
    return '$awarded / $max đúng';
  }

  @override
  String get teacherAttemptGradeSectionBreakdown => 'Câu hỏi & chấm điểm';

  @override
  String teacherAttemptGradeItemKind(String kind) {
    return 'Dạng: $kind';
  }

  @override
  String teacherAttemptGradeMaxPts(int n) {
    return 'Tối đa $n điểm';
  }

  @override
  String get teacherAttemptGradeStudentFallback => 'Học sinh';

  @override
  String teacherAttemptGradePointsShort(Object awarded, Object max) {
    return '$awarded / $max điểm';
  }

  @override
  String get teacherAttemptGradeAnswerLabel => 'Bài làm';

  @override
  String get teacherAttemptGradeWorkAndScores => 'Xem bài làm & chấm điểm';

  @override
  String get teacherAttemptGradeCorrectAnswer => 'Đáp án đúng';

  @override
  String get teacherAttemptGradeSkillLinkedWork => 'Bài tập gắn với kỹ năng';

  @override
  String get teacherAttemptGradeSkillCmsHint =>
      'Học sinh làm bài trong màn kỹ năng và đánh dấu hoàn thành ở đây. Chi tiết bài làm nằm trong lịch sử bài tập kỹ năng, không gửi kèm payload bài thi.';

  @override
  String teacherAttemptGradeQuestionN(int n) {
    return 'Câu $n';
  }

  @override
  String get teacherAttemptGradeInstructions => 'Hướng dẫn';

  @override
  String get teacherAttemptGradeChoicesLabel => 'Các đáp án';

  @override
  String get teacherAttemptGradeNoSkillWork =>
      'Không có bài làm trong thời gian làm bài thi này.';

  @override
  String get teacherAttemptGradeNoEssayText =>
      'Học sinh chưa lưu bài viết cho lần làm này.';

  @override
  String get teacherAttemptGradeWritingPromptLabel => 'ĐỀ BÀI WRITING';

  @override
  String get teacherAttemptGradeSkillWorkExamInline =>
      'Bài làm được lưu trực tiếp trong lượt thi tích hợp (không qua bài luyện CMS riêng).';

  @override
  String get teacherAttemptGradeSkillWorkNearSession =>
      'Hiển thị bài làm gần thời gian thi (có thể lệch vài phút so với khung giờ chính xác).';

  @override
  String get teacherAttemptGradeSkillWorkLatestLinked =>
      'Hiển thị bài làm gần nhất của học sinh cho bài tập liên kết này.';

  @override
  String teacherAttemptGradeWordCount(int count) {
    return '$count từ';
  }

  @override
  String get teacherAttemptGradeViewSkillWork => 'Xem bài làm';

  @override
  String get teacherAttemptGradeHideSkillWork => 'Ẩn bài làm';

  @override
  String get teacherAttemptGradeListeningCue => 'Câu';

  @override
  String teacherAttemptGradeDictationScore(Object correct, Object total) {
    return 'Đúng từ: $correct / $total';
  }

  @override
  String teacherAttemptGradeSpeakingLine(String id) {
    return 'Câu $id';
  }

  @override
  String teacherAttemptGradeWritingScore(String score) {
    return 'Điểm: $score';
  }

  @override
  String get teacherAttemptGradeSkillOther => 'Phần';

  @override
  String get teacherExamTimeRemaining => 'Còn lại';

  @override
  String get teacherExamMcqNeedsStem =>
      'Mỗi câu trắc nghiệm cần có nội dung câu hỏi.';

  @override
  String get teacherExamEssayNeedsPrompt => 'Mỗi bài tự luận cần có đề bài.';

  @override
  String get teacherExamIntegratedUntitled => 'Bộ luyện 4 kỹ năng';

  @override
  String get teacherExamIntegratedNew => 'Đề 4 kỹ năng';

  @override
  String get teacherExamIntegratedBadge => '4 kỹ năng';

  @override
  String get teacherExamIntegratedEditorTitle => 'Đề 4 kỹ năng';

  @override
  String get teacherExamIntegratedPartsTitle =>
      'Các phần (Đọc → Nghe → Viết → Nói)';

  @override
  String get teacherExamIntegratedPartsHint =>
      'Chọn một bài đã có cho mỗi kỹ năng. Học sinh mở từng bài trong app, làm xong rồi đánh dấu hoàn thành trước khi nộp.';

  @override
  String get teacherExamIntegratedTapToPick => 'Chạm để chọn bài';

  @override
  String get teacherExamIntegratedPickAll =>
      'Hãy chọn đủ 4 bài trước khi xuất bản.';

  @override
  String get teacherExamIntegratedSkillListening => 'Nghe';

  @override
  String get teacherExamIntegratedSkillSpeaking => 'Nói';

  @override
  String get teacherExamIntegratedSkillReading => 'Đọc';

  @override
  String get teacherExamIntegratedSkillWriting => 'Viết';

  @override
  String get teacherExamIntegratedChooseExercise => 'Chọn bài tập';

  @override
  String get teacherExamIntegratedEmptyList => 'Không có mục nào.';

  @override
  String get teacherExamSkillsEditorTitle => 'Đề kiểm tra theo kỹ năng';

  @override
  String get teacherExamSkillsPartsTitle =>
      'Kỹ năng (chọn phần nào có trong đề)';

  @override
  String get teacherExamSkillsPartsHint =>
      'Tắt kỹ năng nếu đề không kiểm tra phần đó. Với mỗi kỹ năng bật, hãy thêm một hoặc nhiều bài từ thư viện.';

  @override
  String get teacherExamSkillsIncludeSubtitle => 'Đưa kỹ năng này vào đề';

  @override
  String get teacherExamGrammarTitle => 'Ngữ pháp';

  @override
  String get teacherExamGrammarIncludeSubtitle => 'Bật phần Ngữ pháp';

  @override
  String teacherExamGrammarQuestionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count câu hỏi',
      one: '1 câu hỏi',
    );
    return '$_temp0';
  }

  @override
  String get teacherExamGrammarEnabledNoItems =>
      'Đã bật Ngữ pháp nhưng chưa có câu hỏi. Hãy thêm ít nhất một câu hoặc tắt Ngữ pháp.';

  @override
  String get teacherExamGrammarHint =>
      'Tuỳ chọn. Có thể thêm đục lỗ, điền từ, nối cặp, sắp xếp câu hoặc trắc nghiệm; đều chấm tự động. Nếu đề có cả kỹ năng, tổng điểm phần Ngữ pháp không được vượt quá 100.';

  @override
  String get teacherExamWritingPublishNeedPrompt =>
      'Đã bật Writing: cần đặt đề bài (AI hoặc tự soạn). Chỉ chọn chủ đề thư viện là chưa đủ.';

  @override
  String get teacherExamWritingAiPickTaskTypeTitle => 'Dạng bài cho AI tạo đề';

  @override
  String get teacherExamWritingAiPickTaskTypeHint =>
      'Tuỳ chọn. Chọn “Bất kỳ” để nhận tối đa 3 dạng bài khác nhau.';

  @override
  String get teacherExamWritingAiTaskTypeAny => 'Bất kỳ (nhiều dạng)';

  @override
  String get teacherExamWritingAiNeedTopicOrTitle =>
      'Chọn chủ đề Writing hoặc nhập tiêu đề đề thi phía trên trước khi dùng AI tạo đề.';

  @override
  String get teacherExamGrammarAdd => 'Thêm câu';

  @override
  String get teacherExamGrammarEdit => 'Câu ngữ pháp';

  @override
  String get teacherExamPublishNeedSelection =>
      'Bật ít nhất một kỹ năng và chọn bài, hoặc thêm ít nhất một câu Ngữ pháp.';

  @override
  String get teacherExamListeningTypeLabel => 'Loại bài tập';

  @override
  String get teacherExamListeningTypeDictation => 'Chính tả';

  @override
  String get teacherExamListeningTypeComprehension => 'Nghe hiểu';

  @override
  String get teacherExamListeningTypeDictationHint =>
      'Điền từ còn thiếu theo các câu âm thanh';

  @override
  String get teacherExamListeningTypeComprehensionHint =>
      'Câu hỏi trắc nghiệm dựa trên đoạn nghe';

  @override
  String get teacherExamPublishPickEachIncludedSkill =>
      'Hãy thêm ít nhất một bài cho mọi kỹ năng đang bật.';

  @override
  String get teacherExamSpeakingExerciseRequired =>
      'Đã bật Nói nhưng chưa gắn bài. Bấm \"Thêm bài tập\" và chọn một Speaking set.';

  @override
  String get teacherExamWritingPromptSectionTitle => 'Đề bài Writing';

  @override
  String get teacherExamWritingPromptEmptyHint =>
      'Tất cả học sinh sẽ nhận cùng một đề bài. Chọn đề AI gợi ý hoặc tự soạn đề của bạn.';

  @override
  String get teacherExamWritingGenerateWithAI => 'Tạo đề bằng AI';

  @override
  String get teacherExamWritingWriteManually => 'Tự soạn đề';

  @override
  String get teacherExamWritingPromptNeedTopic =>
      'Vui lòng chọn chủ đề Writing trước để AI tạo đề.';

  @override
  String get teacherExamWritingPickPromptTitle => 'Chọn đề bài Writing';

  @override
  String get teacherExamWritingPickPromptSubtitle =>
      'Chọn một trong các đề AI gợi ý bên dưới. Tất cả học sinh sẽ nhận cùng đề này.';

  @override
  String get teacherExamWritingSelectThisPrompt => 'Chọn đề này';

  @override
  String get teacherExamWritingManualPromptTitle => 'Tự soạn đề bài';

  @override
  String get teacherExamWritingPromptTitleLabel => 'Tiêu đề đề bài';

  @override
  String get teacherExamWritingPromptTitleHint =>
      'VD: Công nghệ trong Giáo dục';

  @override
  String get teacherExamWritingPromptTaskTypeLabel => 'Dạng bài';

  @override
  String get teacherExamWritingPromptTextLabel => 'Nội dung đề bài';

  @override
  String get teacherExamWritingPromptTextHint =>
      'Viết toàn bộ câu hỏi thi ở đây. Bao gồm bối cảnh và hướng dẫn cụ thể cho học sinh...';

  @override
  String get teacherExamWritingPromptTextRequired =>
      'Hãy nhập nội dung đề Writing trước khi lưu.';

  @override
  String get teacherExamWritingPromptRequired =>
      'Vui lòng đặt đề bài Writing trước khi xuất bản.';

  @override
  String get teacherExamWritingPromptNotSet =>
      'Chưa có đề bài. Học sinh sẽ không thể hoàn thành phần này.';

  @override
  String get teacherExamWritingCustomPrompt => 'Đề tự soạn';

  @override
  String get teacherExamGrammarPointsCap100 =>
      'Tổng điểm Ngữ pháp không được quá 100 khi đề có phần kỹ năng.';

  @override
  String get teacherExamSkillsBadge => 'Đề kỹ năng';

  @override
  String get integratedExamGrammarSectionTitle => 'Ngữ pháp';

  @override
  String get integratedExamSubmitBlockedAll =>
      'Hoàn thành mọi phần kỹ năng và mọi câu Ngữ pháp trước khi nộp.';

  @override
  String get teacherExamSkillsWebSubtitle =>
      'Bố cục như đề giấy: Ngữ pháp trước, sau đó Đọc, Nghe, Viết, Nói. Mỗi kỹ năng bật có thể thêm một hoặc nhiều bài từ thư viện.';

  @override
  String get teacherExamSkillsBrowseContent => 'Duyệt thư viện';

  @override
  String get teacherExamSkillsNoGrammarYet =>
      'Chưa có câu Ngữ pháp. Nhấn Thêm câu để mở trình soạn.';

  @override
  String get teacherExamSkillsAddExercise => 'Thêm bài tập';

  @override
  String get teacherExamSkillsCreateNew => 'Tạo bài tập mới';

  @override
  String get teacherExamSkillsExercisesSelected => 'bài tập đã chọn';

  @override
  String get teacherExamSkillsAllAdded => 'Tất cả bài tập có sẵn đã được thêm.';

  @override
  String teacherExamPickerAddSelected(int count) {
    return 'Thêm $count bài đã chọn';
  }

  @override
  String get teacherExamCreateMenuLabel => 'Tạo đề';

  @override
  String get teacherExamIntegratedCreateClassicHint =>
      'Trắc nghiệm & tự luận trong một trình soạn';

  @override
  String get teacherExamIntegratedCreateFourHint =>
      'Bốn phần gắn với bài học có sẵn';

  @override
  String get integratedExamRunnerTitle => 'Bộ bài tập';

  @override
  String get integratedExamMetaClass => 'Lớp';

  @override
  String get integratedExamMetaSubject => 'Môn';

  @override
  String get integratedExamMetaTeacher => 'Giáo viên';

  @override
  String get integratedExamMetaStudent => 'Học sinh';

  @override
  String get integratedExamMetaDelivery => 'Hình thức';

  @override
  String get integratedExamMetaModeHomework => 'Bài tập về nhà';

  @override
  String get integratedExamMetaModeScheduled => 'Theo lịch / giờ thi';

  @override
  String get integratedExamMetaModeLive => 'Trực tiếp (phòng thi)';

  @override
  String get integratedExamMetaPublic => 'Liên kết công khai';

  @override
  String get integratedExamMetaTimeLimit => 'Giới hạn thời gian';

  @override
  String integratedExamMetaTimeLimitMinutes(int minutes) {
    return '$minutes phút';
  }

  @override
  String get integratedExamMetaNoTimeLimit => 'Không giới hạn thời gian làm';

  @override
  String get integratedExamMetaDeadline => 'Còn lại';

  @override
  String get integratedExamMetaDue => 'Hạn nộp';

  @override
  String get integratedExamMetaWindow => 'Đóng lúc';

  @override
  String get integratedExamMetaOpens => 'Mở lúc';

  @override
  String get integratedExamMetaStarted => 'Bắt đầu lúc';

  @override
  String get integratedExamSubjectDefault => 'Tiếng Anh';

  @override
  String get integratedExamNoClassName => '—';

  @override
  String get integratedExamGrammarNavHint =>
      'Viền đậm = đang làm; xanh = đã trả lời.';

  @override
  String integratedExamGrammarQuestionLabel(int n, int total) {
    return 'Câu $n / $total';
  }

  @override
  String get integratedExamTimeUpShort => 'Hết giờ';

  @override
  String get integratedExamGrammarPrevious => 'Câu ngữ pháp trước';

  @override
  String get integratedExamGrammarNext => 'Câu ngữ pháp sau';

  @override
  String get integratedExamOpenExercise => 'Mở bài';

  @override
  String get integratedExamMarkDone => 'Đã xong phần này';

  @override
  String get integratedExamUndoPart => 'Huỷ đánh dấu';

  @override
  String get integratedExamSubmit => 'Nộp cả bộ';

  @override
  String get integratedExamSubmitShort => 'Nộp bài';

  @override
  String get integratedExamSubmitBlocked =>
      'Hãy đánh dấu đủ 4 phần trước khi nộp.';

  @override
  String integratedExamProgress(int done, int total) {
    return 'Đã sẵn sàng $done/$total phần';
  }

  @override
  String get integratedExamListeningSubNavTitle => 'Bài tập trong phần Nghe';

  @override
  String get integratedExamListeningSubNavHint =>
      'Chọn Dictation hoặc Comprehension bên dưới';

  @override
  String integratedExamScoreSummary(Object earned) {
    return 'Điểm TB: $earned / 10';
  }

  @override
  String get integratedExamSkillsSectionTitle => 'Kỹ năng';

  @override
  String get integratedExamDetailsTitle => 'Thông tin bài kiểm tra';

  @override
  String get integratedExamSelectPartHint =>
      'Chọn một phần bên dưới. Làm từng phần một cho dễ theo dõi.';

  @override
  String get integratedExamPartDone => 'Xong';

  @override
  String get integratedExamPartNotStarted => 'Chưa làm';

  @override
  String get integratedExamEmbeddedHint =>
      'Làm bài tập ngay bên dưới. Chỉ dùng đồng hồ của bài kiểm tra.';

  @override
  String get integratedExamEmbeddedLocked =>
      'Phần này đã khóa sau khi bạn nộp bài.';

  @override
  String get integratedExamResultsAwaitingRelease =>
      'Giáo viên chưa công bố đáp án chi tiết. Bạn sẽ thấy câu đúng và câu sai tại đây sau khi giáo viên công bố điểm.';

  @override
  String get integratedExamResultsNeverShown =>
      'Bài giao này không hiển thị đáp án chi tiết.';

  @override
  String get integratedExamResultsScoreOnly =>
      'Giáo viên chỉ công bố điểm. Bài làm, đáp án chi tiết và nhận xét chưa được mở. Bạn có thể nhờ giáo viên bật xem kết quả chấm bài sau.';

  @override
  String get integratedExamReviewYourAnswer => 'Bài làm của bạn';

  @override
  String get integratedExamReviewCorrectAnswer => 'Đáp án đúng';

  @override
  String get integratedExamReviewNotAnswered => 'Chưa trả lời';

  @override
  String get integratedExamReviewTeacherFeedback => 'Nhận xét của giáo viên';

  @override
  String get teacherAssignmentResultsDetailLabel => 'Học sinh được xem gì';

  @override
  String get teacherResultsDetailScoreOnly => 'Chỉ điểm';

  @override
  String get teacherResultsDetailScoreOnlyHint =>
      'Học sinh chỉ thấy điểm tổng và điểm kỹ năng — không thấy bài làm, đáp án hay nhận xét.';

  @override
  String get teacherResultsDetailFull => 'Kết quả chấm bài đầy đủ';

  @override
  String get teacherResultsDetailFullHint =>
      'Học sinh thấy bài làm, câu đúng/sai và nhận xét của bạn.';

  @override
  String get teacherReleaseResultsDialogTitle => 'Công bố kết quả';

  @override
  String get teacherReleaseResultsDialogSubtitle =>
      'Chọn phần học sinh được xem sau khi công bố. Bạn có thể đổi lại sau trong cài đặt bài giao.';

  @override
  String get integratedExamEmbeddedNoResource =>
      'Chưa gắn bài tập cho phần này.';

  @override
  String get integratedExamEmbeddedNoSpeakingResource =>
      'Chưa gắn bài Nói. Nhờ giáo viên thêm bài Speaking trong soạn đề, rồi bắt đầu phiên thi mới.';

  @override
  String get integratedExamGrammarUnsupported =>
      'Ứng dụng chưa hỗ trợ dạng câu này.';

  @override
  String get integratedExamMatchPick => 'Nối với';

  @override
  String get integratedExamMatchHint =>
      'Chạm mục bên trái, rồi chạm mục bên phải để nối — hoặc giữ lâu và kéo sang đáp án đúng. Đường nối hiển thị từng cặp của bạn.';

  @override
  String get integratedExamMatchHintCompact =>
      'Chạm cụm bên trái, rồi chạm đáp án bên dưới — hoặc kéo thả vào ô đứt nét. Mỗi cặp một màu riêng.';

  @override
  String get integratedExamMatchAnswersPool => 'Đáp án';

  @override
  String get integratedExamMatchTapAnswer => 'Chạm đáp án bên dưới';

  @override
  String get integratedExamMatchDropHere => 'Thả đáp án vào đây';

  @override
  String get integratedExamReorderHint => 'Kéo các dòng để sắp đúng thứ tự.';

  @override
  String get teacherExamGrammarKindMcqSingle => 'Trắc nghiệm (một đáp án)';

  @override
  String get teacherExamGrammarKindMcqMulti => 'Trắc nghiệm (nhiều đáp án)';

  @override
  String get teacherExamGrammarKindCloze => 'Đục lỗ — điền trong đoạn văn';

  @override
  String get teacherExamGrammarKindGap => 'Điền từ — thiếu một chỗ trống';

  @override
  String get teacherExamGrammarKindMatching => 'Nối cặp';

  @override
  String get teacherExamGrammarKindReorder => 'Sắp xếp mảnh câu';

  @override
  String get teacherExamGrammarQuestionType => 'Dạng câu';

  @override
  String get teacherExamGrammarPassageLabel =>
      'Đoạn văn (đánh dấu ô trống bằng hai dấu ngoặc nhọn và số, ví dụ 0 và 1)';

  @override
  String get teacherExamGrammarTextBefore => 'Phần trước chỗ trống';

  @override
  String get teacherExamGrammarTextAfter => 'Phần sau chỗ trống';

  @override
  String get teacherExamGrammarAcceptedAnswers =>
      'Đáp án chấp nhận (cách nhau bởi dấu phẩy)';

  @override
  String get teacherExamGrammarBlankId => 'Mã ô trống';

  @override
  String get teacherExamGrammarLeftColumn => 'Cột trái';

  @override
  String get teacherExamGrammarRightColumn => 'Cột phải';

  @override
  String teacherExamGrammarPairCorrect(int row) {
    return 'Đáp án đúng cho dòng $row';
  }

  @override
  String get teacherExamGrammarFragments =>
      'Các mảnh câu (mỗi dòng một mảnh, theo thứ tự đọc đúng)';

  @override
  String get teacherExamGrammarReorderInstruction =>
      'Kéo các thẻ bên dưới để đặt thứ tự câu đúng mà học sinh cần xếp được.';

  @override
  String get teacherExamGrammarSaveItem => 'Lưu câu';

  @override
  String get teacherExamGrammarNewItem => 'Câu mới';

  @override
  String get teacherExamGrammarPanelTitle => 'Soạn câu ngữ pháp';

  @override
  String get teacherExamGrammarCloseEditor => 'Đóng';

  @override
  String get teacherExamGrammarImport => 'Nhập câu hỏi';

  @override
  String teacherExamGrammarImportSuccess(int count) {
    return 'Đã nhập $count câu hỏi thành công.';
  }

  @override
  String get teacherExamGrammarImportError =>
      'Không thể đọc file. Vui lòng kiểm tra định dạng và thử lại.';

  @override
  String get teacherExamGrammarImportEmpty =>
      'Không tìm thấy câu hỏi hợp lệ nào trong file.';

  @override
  String get teacherExamGrammarImportFormatTitle => 'Định dạng import (JSON)';

  @override
  String get teacherExamGrammarImportFormatHint =>
      'Tạo file .json chứa mảng các đối tượng câu hỏi. Mỗi đối tượng phải có trường \"kind\". Các loại hỗ trợ:';

  @override
  String get teacherExamGrammarDownloadSample => 'Sao chép mẫu vào clipboard';

  @override
  String get teacherExamGrammarImportPickFile => 'Chọn file .json';

  @override
  String get teacherExamGrammarAddOption => 'Thêm phương án';

  @override
  String get teacherExamGrammarCorrectOptions => 'Phương án đúng';

  @override
  String get studentExamExpired => 'Hết giờ';

  @override
  String get teacherAssignmentEditTitle => 'Chỉnh sửa bài giao';

  @override
  String get teacherAssignmentEditSubtitle =>
      'Điều chỉnh lịch, thời gian làm và quy tắc';

  @override
  String get teacherAssignmentEditSaved => 'Đã cập nhật bài giao';

  @override
  String get teacherAssignmentEditScheduleSection => 'Lịch nộp bài';

  @override
  String get teacherAssignmentEditRulesSection => 'Số lần nộp & kết quả';

  @override
  String get teacherAssignmentEditTooltip => 'Chỉnh sửa bài giao';

  @override
  String get teacherAssignmentModeFixed =>
      'Chế độ đã được chốt và không thể thay đổi sau khi tạo.';

  @override
  String get teacherAssignmentRealtimeLobbyOpens => 'Mở phòng chờ (tuỳ chọn)';

  @override
  String get teacherAssignmentRealtimeLobbyOpensHint =>
      'Sớm hơn giờ bắt đầu nếu cho học sinh vào chờ. Để trống = trùng giờ bắt đầu.';

  @override
  String get teacherAssignmentRealtimeScheduledStart => 'Giờ làm bài';

  @override
  String get teacherAssignmentRealtimeScheduledStartRequired =>
      'Hãy chọn giờ làm bài khi đặt lịch.';

  @override
  String get teacherAssignmentRealtimeHardEnd => 'Kết thúc cứng';

  @override
  String get teacherAssignmentRealtimeScheduleModeLabel =>
      'Học sinh vào lúc nào';

  @override
  String get teacherAssignmentRealtimeScheduleManual => 'Trên lớp';

  @override
  String get teacherAssignmentRealtimeScheduleScheduled => 'Đặt lịch';

  @override
  String get teacherAssignmentRealtimeScheduleManualHint =>
      'Không cố định giờ — mở phòng trên lớp; cả lớp làm khi bạn bấm Bắt đầu.';

  @override
  String get teacherAssignmentRealtimeScheduleScheduledHint =>
      'Học sinh thấy giờ làm bài trên bài giao. Vào phòng chờ từ giờ mở; làm bài khi bạn bấm Bắt đầu.';

  @override
  String examCardRealtimeScheduledStart(String date) {
    return 'Thi trực tiếp lúc $date';
  }

  @override
  String examCardRealtimeLobbyOpens(String date) {
    return 'Mở phòng chờ $date';
  }

  @override
  String get teacherAssignmentEditPracticeNote =>
      'Chế độ luyện tập không có lịch — học sinh có thể làm bài bất cứ lúc nào.';

  @override
  String get chatMediaDownloading => 'Đang tải file…';

  @override
  String get chatMediaDownloadDone => 'Đã tải file';

  @override
  String get chatMediaDownloadFailed => 'Không thể tải file';

  @override
  String get chatMediaVideoLoadFailed => 'Không thể phát video';
}
