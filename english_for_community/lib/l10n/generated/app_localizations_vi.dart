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
  String get navProgress => 'Tiến độ';

  @override
  String get navProfile => 'Hồ sơ';

  @override
  String get loginWelcomeBack => 'Chào mừng trở lại!';

  @override
  String get loginSubtitle => 'Nhập thông tin để tiếp tục.';

  @override
  String get labelEmail => 'Email';

  @override
  String get labelPassword => 'Mật khẩu';

  @override
  String get hintEmail => 'ten@email.com';

  @override
  String get hintPassword => 'Nhập mật khẩu...';

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
  String get appNameBrand => 'LearnLingo';

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
}
