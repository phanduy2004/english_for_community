// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get profileAndSettings => 'Profile & Settings';

  @override
  String get learningPreferences => 'LEARNING PREFERENCES';

  @override
  String get dailyTimeGoal => 'Daily Time Goal';

  @override
  String get dailyLessonGoal => 'Daily Lesson Goal';

  @override
  String get dailyReminder => 'Daily Reminder';

  @override
  String get reminderTime => 'Reminder Time';

  @override
  String minutesShort(int mins) {
    return '$mins mins';
  }

  @override
  String lessonsShort(int n) {
    return '$n lessons';
  }

  @override
  String get setDailyTimeGoal => 'Set Daily Time Goal';

  @override
  String minutesPerDayOption(int mins) {
    return '$mins minutes / day';
  }

  @override
  String get setDailyLessonGoal => 'Set Daily Lesson Goal';

  @override
  String lessonsPerDayOption(int n) {
    return '$n lessons / day';
  }

  @override
  String get progress => 'PROGRESS';

  @override
  String get exerciseHistory => 'Exercise history';

  @override
  String get exerciseHistorySubtitle => 'Past attempts by skill';

  @override
  String get generalSettings => 'GENERAL SETTINGS';

  @override
  String get appLanguage => 'App Language';

  @override
  String get timezone => 'Timezone';

  @override
  String get accountAndSecurity => 'ACCOUNT & SECURITY';

  @override
  String get changePassword => 'Change Password';

  @override
  String get exportData => 'Export Data';

  @override
  String get exportDataSubtitle => 'Download learning history';

  @override
  String get signOut => 'Sign Out';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountTitle => 'Delete Account?';

  @override
  String get deleteAccountBody =>
      'This action cannot be undone. All data will be deleted.';

  @override
  String get cancel => 'Cancel';

  @override
  String get deletePermanently => 'Delete Permanently';

  @override
  String get member => 'Member';

  @override
  String get admin => 'Admin';

  @override
  String get selectAppLanguage => 'Choose app language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageVietnamese => 'Vietnamese';

  @override
  String get appLanguageFootnote => 'Interface language (saved on this device)';

  @override
  String get navHome => 'Home';

  @override
  String get navProgress => 'Progress';

  @override
  String get navProfile => 'Profile';

  @override
  String get loginWelcomeBack => 'Welcome Back!';

  @override
  String get loginSubtitle => 'Enter your details to continue.';

  @override
  String get labelEmail => 'Email';

  @override
  String get loginEmailOrUsername => 'Email or username';

  @override
  String get hintLoginEmailOrUsername => 'Enter your email or username';

  @override
  String get labelPassword => 'Password';

  @override
  String get hintEmail => 'name@example.com';

  @override
  String get hintPassword => 'Enter your password';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get forgotPasswordLink => 'Forgot password?';

  @override
  String get signIn => 'Sign In';

  @override
  String get orDivider => 'OR';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get noAccountPrompt => 'Don\'t have an account? ';

  @override
  String get signUp => 'Sign Up';

  @override
  String get dictionary => 'Dictionary';

  @override
  String get close => 'Close';

  @override
  String get missingInfo => 'Missing Info';

  @override
  String get enterEmailPassword => 'Enter email and password.';

  @override
  String get loginFailed => 'Login Failed';

  @override
  String get errorTitle => 'Error';

  @override
  String get fillRequiredFields => 'Please fill in all required fields (*).';

  @override
  String get passwordErrorTitle => 'Password Error';

  @override
  String get passwordMismatch => 'Confirmation password does not match.';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get otpVerifyTitle => 'Verify Email';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get commonRetry => 'Retry';

  @override
  String get loading => 'Loading...';

  @override
  String get practiceFallbackTitle => 'Practice';

  @override
  String get barrierDismiss => 'Dismiss';

  @override
  String get weeklyActivity => 'Weekly activity';

  @override
  String get sameChartBadge => 'same chart as Progress';

  @override
  String get couldNotLoadStudyChart => 'Could not load study chart';

  @override
  String weeklySummaryLine(String minutes, int done, int goal) {
    return '$minutes this week · $done / $goal lessons today';
  }

  @override
  String get viewProgress => 'View progress';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingSlide1Title => 'Personalized Learning Path';

  @override
  String get onboardingSlide1Subtitle =>
      'A plan tailored to your goals, CEFR level, and schedule.';

  @override
  String get onboardingSlide2Title => 'AI Tutor for Speaking & Writing';

  @override
  String get onboardingSlide2Subtitle =>
      'Realtime pronunciation feedback & rubric-based review.';

  @override
  String get onboardingSlide3Title => 'Stay Motivated with Rewards';

  @override
  String get onboardingSlide3Subtitle =>
      'Streaks, XP, and badges keep you engaged daily.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get signInAction => 'Sign in';

  @override
  String get readingPracticeTitle => 'Reading Practice';

  @override
  String get speakingModeReadAloud => 'Read Aloud';

  @override
  String get speakingModeShadowing => 'Shadowing';

  @override
  String get speakingModePronunciation => 'Pronunciation';

  @override
  String get speakingModeFreeSpeaking => 'Free Speaking';

  @override
  String get difficultyBeginner => 'Beginner';

  @override
  String get difficultyIntermediate => 'Intermediate';

  @override
  String get difficultyAdvanced => 'Advanced';

  @override
  String sentenceIndex(int current, int total) {
    return 'Sentence $current / $total';
  }

  @override
  String get finishPractice => 'Finish';

  @override
  String get nextSentence => 'Next sentence';

  @override
  String get microNotReady =>
      'Microphone / speech recognition is not ready. Grant permission and try again.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get microInfoBanner =>
      'Micro / speech recognition is not ready. Grant permission and try again.';

  @override
  String get sampleListen => 'Sample';

  @override
  String get sampleListenSub => 'Listen';

  @override
  String get yourTurn => 'Your turn';

  @override
  String get yourTurnSub => 'Your speech';

  @override
  String get listeningForSpeech =>
      'Listening… Tap the red button to stop and score.';

  @override
  String get submittingAnalysis => 'Sending and analyzing…';

  @override
  String get tapMicToRecord =>
      'Tap the mic, read the sentence aloud, then tap again to stop.';

  @override
  String get yourSpeechSection => 'YOUR SPEECH';

  @override
  String get transcriptPlaceholder => 'Will appear here when you speak…';

  @override
  String get accuracyLabel => 'Accuracy';

  @override
  String get levelLabel => 'Beginner';

  @override
  String get speakingPracticeTitle => 'Speaking practice';

  @override
  String get socketSessionEnded => 'Session ended. Please sign in again.';

  @override
  String get socketKicked => 'You were signed out from another device.';

  @override
  String get adminRetry => 'Retry';

  @override
  String get adminDashboard => 'Admin dashboard';

  @override
  String get filterEasy => 'easy';

  @override
  String get filterMedium => 'medium';

  @override
  String get filterHard => 'hard';

  @override
  String get vocabularyTitle => 'Vocabulary';

  @override
  String get listeningTitle => 'Listening';

  @override
  String get writingTitle => 'Writing';

  @override
  String get progressReportTitle => 'Progress';

  @override
  String get exerciseHistoryTitle => 'Exercise history';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get aiAssistantTitle => 'AI Assistant';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get search => 'Search';

  @override
  String get noData => 'No data';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get done => 'Done';

  @override
  String get accountSuspended => 'Account Suspended';

  @override
  String get sessionTerminated => 'Your session has been terminated.';

  @override
  String get reasonLabel => 'Reason:';

  @override
  String get adminConsoleTitle => 'Admin Console';

  @override
  String get adminShellAppName => 'Admin';

  @override
  String get adminShellNavGroup => 'Overview';

  @override
  String get adminShellOpsGroup => 'Operations';

  @override
  String get adminShellContentGroup => 'Content';

  @override
  String get adminShellDesktopTitle => 'Use a desktop browser';

  @override
  String get adminShellDesktopBody =>
      'The admin console is optimized for screens 768px and wider. Open this page on a laptop or desktop for the best experience.';

  @override
  String get adminShellCollapseSidebar => 'Collapse sidebar';

  @override
  String get adminShellExpandSidebar => 'Expand sidebar';

  @override
  String get adminNavSubmissions => 'Submissions';

  @override
  String get adminNavOps => 'Ops center';

  @override
  String get adminNavOpsSub => 'Moderation, export, permissions';

  @override
  String get adminNavReleases => 'Releases';

  @override
  String get adminNavReleasesSub => 'Approve, schedule, publish';

  @override
  String get adminContentItemCount => 'topics';

  @override
  String get adminListeningDictation => 'Dictation';

  @override
  String get adminListeningDictationSub => 'Listen and type (cues)';

  @override
  String get adminListeningComprehension => 'Comprehension';

  @override
  String get adminListeningComprehensionSub => 'Multiple-choice listening quiz';

  @override
  String get adminOverviewTitle => 'Overview';

  @override
  String get adminUserManagementTitle => 'User management';

  @override
  String get adminReportManagementTitle => 'Report management';

  @override
  String get adminActivityHistoryTitle => 'Submission history';

  @override
  String get adminSearchUsersHint => 'Search by name or email…';

  @override
  String get adminSearchReportsHint => 'Search by title or sender…';

  @override
  String get adminNoUsersFound => 'No users found';

  @override
  String get adminNoReportsFound => 'No reports in this status';

  @override
  String get adminUsersTrash => 'Trash';

  @override
  String adminUserRestored(String name) {
    return 'Restored $name';
  }

  @override
  String get adminReportStatusUpdated => 'Status updated successfully';

  @override
  String get adminActionSuccess => 'Action completed successfully';

  @override
  String get adminReleaseConfirmCodeInvalid => 'Confirmation code is incorrect';

  @override
  String get superAdminRole => 'Super Admin';

  @override
  String get managementSection => 'Management';

  @override
  String get contentManagerTile => 'Content Manager';

  @override
  String get contentManagerSub => 'Tasks, Reading & Listening editor';

  @override
  String get reportsMenuTitle => 'Reports';

  @override
  String get reportsMenuSub => 'Issue feedback';

  @override
  String get usersMenuTitle => 'Users';

  @override
  String get usersMenuSub => 'User list';

  @override
  String get submissionsMetric => 'Submissions';

  @override
  String get aiCostMetric => 'AI Cost (Est)';

  @override
  String get reportsMetric => 'Reports';

  @override
  String get activeUsersMetric => 'Active Users';

  @override
  String get activityChart => 'Activity Chart';

  @override
  String get swipeToView => 'Swipe to view';

  @override
  String get appTagline => 'Master English with AI-powered learning';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get continueAction => 'Continue';

  @override
  String get appNameBrand => 'LearnLingo';

  @override
  String streakDays(int n) {
    return '$n day streak';
  }

  @override
  String get fullProgressStats => 'Full progress & stats';

  @override
  String get noStudyWeek => 'No study minutes this week yet — start a lesson!';

  @override
  String get speakingDescReadAloud => 'Read text passages clearly.';

  @override
  String get speakingDescShadowing => 'Listen and repeat instantly.';

  @override
  String get speakingDescPronunciation => 'Practice syllable precision.';

  @override
  String get speakingDescFreeSpeaking => 'Chat freely about any topic.';

  @override
  String get speakingSelectModeTitle => 'Select Practice Mode';

  @override
  String get speakingSelectModeSubtitle =>
      'Choose a method to start your speaking journey.';

  @override
  String get speakingMasteryTitle => 'Speaking Mastery';

  @override
  String get speakingMasterySubtitle =>
      'Practice pronunciation and fluency with AI feedback.';

  @override
  String get aiPoweredBadge => 'AI Powered';

  @override
  String get searchTopicHint => 'Search topic, ID…';

  @override
  String get loadDataFailed => 'Failed to load data';

  @override
  String get noSpeakingLessonsFound => 'No speaking lessons found';

  @override
  String get bestScoreLabel => 'Best Score';

  @override
  String get noAttemptsYet => 'No attempts';

  @override
  String get reviewAction => 'Review';

  @override
  String get retakeAction => 'Retake';

  @override
  String get resumeAction => 'Resume';

  @override
  String get startAction => 'Start';

  @override
  String percentDone(int pct) {
    return '$pct% done';
  }

  @override
  String lessonMetaLine(int n, String topic) {
    return '$n sentences · Topic: $topic';
  }

  @override
  String get topicDailyLife => 'Daily Life';

  @override
  String get settings => 'Settings';

  @override
  String get speechNotAvailableSnack =>
      'Speech recognition is not available. Grant microphone permission and (on iOS) Speech Recognition.';

  @override
  String get micOpenFailedSnack =>
      'Could not open the microphone. On Android you need Google\'s recognition service; try installing or updating the Google app and English language.';

  @override
  String micStartError(String error) {
    return 'Error starting microphone: $error';
  }

  @override
  String get listeningPracticeTitle => 'Listening Practice';

  @override
  String get listeningHeaderTitle => 'Dictation Master';

  @override
  String get listeningHeaderSubtitle =>
      'Improve listening and spelling skills with short daily exercises.';

  @override
  String get listeningPremiumBadge => 'Premium Content';

  @override
  String get listeningSearchHint => 'Search lessons, topics, or ID…';

  @override
  String get listeningDictation => 'Dictation';

  @override
  String get noReadingArticlesFound => 'No reading articles found';

  @override
  String get noListeningLessonsFound => 'No listening lessons found';

  @override
  String questionsCount(int n) {
    return '$n questions';
  }

  @override
  String progressPercentLabel(int pct) {
    return 'Progress: $pct%';
  }

  @override
  String get completedBadge => 'Completed';

  @override
  String get readingSkillsHeaderTitle => 'Reading Skills';

  @override
  String get readingSkillsHeaderSubtitle =>
      'Improve comprehension and vocabulary with curated articles.';

  @override
  String get readingDailyArticlesBadge => 'Daily Articles';

  @override
  String get couldNotLoadExerciseHistory => 'Could not load exercise history';

  @override
  String get skillTabAll => 'All';

  @override
  String get skillTabReading => 'Reading';

  @override
  String get skillTabListening => 'Listening';

  @override
  String get skillTabSpeaking => 'Speaking';

  @override
  String get skillTabWriting => 'Writing';

  @override
  String get historyEmptyRangeTitle => 'No exercises in this range';

  @override
  String get historyEmptyRangeHint => 'Try another date range or skill tab';

  @override
  String get dateRangeLabel => 'Date range';

  @override
  String readingScorePercent(String score) {
    return 'Score: $score%';
  }

  @override
  String readingMinutesShort(int n) {
    return '$n min';
  }

  @override
  String readingQuizCount(int n) {
    return '$n quiz';
  }

  @override
  String get unknownLevel => 'Unknown';

  @override
  String get registerHeroTitle => 'Create Your Account';

  @override
  String get registerHeroSubtitle =>
      'Fill in the details to start your journey.';

  @override
  String get labelFullName => 'Full Name *';

  @override
  String get hintFullName => 'John Doe';

  @override
  String get labelUsername => 'Username *';

  @override
  String get hintUsername => 'username123';

  @override
  String get labelPhone => 'Phone Number';

  @override
  String get hintPhoneShort => '0912…';

  @override
  String get labelDateOfBirth => 'Date of Birth';

  @override
  String get hintDatePlaceholder => 'DD/MM/YYYY';

  @override
  String get labelConfirmPassword => 'Confirm Password *';

  @override
  String get hintPasswordMask => '••••••';

  @override
  String get registerButton => 'Register';

  @override
  String get registrationFailedTitle => 'Registration Failed';

  @override
  String get enterEmailRequired => 'Please enter your email.';

  @override
  String get otpSixDigitsRequired => 'Please enter the 6-digit code.';

  @override
  String get forgotHeroTitle => 'Reset Your Password';

  @override
  String get forgotHeroSubtitle =>
      'Enter your email to receive a verification code.';

  @override
  String get sendButton => 'Send';

  @override
  String get enterVerificationCode => 'Enter Verification Code';

  @override
  String get otpSentPrefix => 'A 6-digit code has been sent to\n';

  @override
  String get otpSentSuffix => '. Please check your inbox.';

  @override
  String resendCooldown(int seconds) {
    return 'Resend in $seconds s';
  }

  @override
  String get verifyButton => 'Verify';

  @override
  String get verificationFailedTitle => 'Verification Failed';

  @override
  String get resendingCodeSnack => 'Resending code…';

  @override
  String get otpSentEmailSnack => 'OTP sent to your email.';

  @override
  String get didNotReceiveCode => 'Didn\'t receive the code? ';

  @override
  String get resendAction => 'Resend';

  @override
  String get setNewPasswordTitle => 'Set New Password';

  @override
  String get setNewPasswordSubtitle => 'Enter a new password for your account.';

  @override
  String get labelNewPassword => 'New Password';

  @override
  String get hintEnterNewPassword => 'Enter new password…';

  @override
  String get labelConfirmNewPassword => 'Confirm New Password';

  @override
  String get hintConfirmNewPassword => 'Confirm new password…';

  @override
  String get resetPasswordButton => 'Reset Password';

  @override
  String get resetFailedTitle => 'Reset Failed';

  @override
  String get enterBothPasswords => 'Please enter both passwords.';

  @override
  String get passwordsDoNotMatchShort => 'Passwords do not match.';

  @override
  String get passwordMinSixChars => 'Password must be at least 6 characters.';

  @override
  String get homeNoData => 'No data available';

  @override
  String homeGreeting(String name) {
    return 'Hi, $name 👋';
  }

  @override
  String get homeReadySubtitle => 'Ready to continue learning?';

  @override
  String get homeDailyGoal => 'Daily Goal';

  @override
  String homeDailyLessonsLine(int done, int goal) {
    return '$done / $goal lessons completed';
  }

  @override
  String get homeTodaysLessons => 'Today\'s Lessons';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeShowLess => 'Show less';

  @override
  String get homeLessonListeningTitle => 'Listening Practice';

  @override
  String get homeLessonListeningSubtitle => 'Daily conversations • 15 min';

  @override
  String get homeLessonReadingTitle => 'Reading Comprehension';

  @override
  String get homeLessonReadingSubtitle => 'Short stories • 20 min';

  @override
  String get homeLessonVocabTitle => 'Vocabulary Builder';

  @override
  String get homeLessonVocabSubtitle => 'New words • 10 min';

  @override
  String get homeLessonSpeakingTitle => 'Speaking Practice';

  @override
  String get homeLessonSpeakingSubtitle => 'Pronunciation • 25 min';

  @override
  String get homeLessonWritingTitle => 'Writing Practice';

  @override
  String get homeLessonWritingSubtitle => 'Select a topic • 15 min';

  @override
  String get homeQuickAccess => 'Quick Access';

  @override
  String get homeQuickFavorites => 'Favorites';

  @override
  String get homeQuickFlashcards => 'Flashcards';

  @override
  String get homeQuickStats => 'Stats';

  @override
  String get statStreak => 'Streak';

  @override
  String get statPoints => 'Points';

  @override
  String get statLevelLabel => 'Level';

  @override
  String get homeLoadFailed => 'Unable to load data';

  @override
  String get homePleaseSignIn => 'Please sign in';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int n) {
    return '${n}m ago';
  }

  @override
  String timeHoursAgo(int n) {
    return '${n}h ago';
  }

  @override
  String get notificationsEmptyTitle => 'No notifications yet';

  @override
  String get notificationsEmptyBody => 'You will receive notifications here.';

  @override
  String get aiAssistantEmptyPrompt =>
      'Ask me anything about your learning progress.';

  @override
  String get aiChatPlaceholder => 'Type a question…';

  @override
  String get listeningChooseSubtitle =>
      'Choose how you want to train your ear today.';

  @override
  String get listeningModeComprehensionTitle => 'Comprehension';

  @override
  String get listeningModeDictationTileDesc =>
      'Listen and type exactly what you hear.';

  @override
  String get listeningModeComprehensionDesc =>
      'Listen to audio and answer multiple choice questions.';

  @override
  String get vocabReviewSessionTitle => 'Review Session';

  @override
  String get tapToSeeMeaning => 'Tap to see meaning';

  @override
  String get showAnswerButton => 'Show Answer';

  @override
  String get srsHard => 'Hard';

  @override
  String get srsGood => 'Good';

  @override
  String get srsEasy => 'Easy';

  @override
  String get vocabSessionCompleteTitle => 'Session complete!';

  @override
  String get vocabSessionCompleteBody => 'You\'ve reviewed all words for now.';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get genericLoadError => 'Something went wrong';

  @override
  String get changePasswordSubtitle =>
      'Update your password to keep your account secure.';

  @override
  String get labelCurrentPassword => 'Current Password';

  @override
  String get hintCurrentPassword => 'Enter current password';

  @override
  String get hintReenterNewPassword => 'Re-enter new password';

  @override
  String get fillAllFields => 'Please fill in all fields';

  @override
  String get newPasswordMismatchToast => 'New passwords do not match';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get learningProgressTitle => 'Learning Progress';

  @override
  String get reportIssueTooltip => 'Report issue';

  @override
  String get failedToLoadProfile => 'Failed to load user profile.';

  @override
  String get failedToLoadData => 'Failed to load data';

  @override
  String get pleaseTryAgainLater => 'Please try again later';

  @override
  String get retry => 'Retry';

  @override
  String get progressOverview => 'Overview';

  @override
  String get progressPerformanceMetrics => 'Performance metrics';

  @override
  String get progressFilterDay => 'Day';

  @override
  String get progressFilterWeek => 'Week';

  @override
  String get progressFilterMonth => 'Month';

  @override
  String get progressPeriodToday => 'Today';

  @override
  String get progressPeriodThisWeek => 'This Week';

  @override
  String get progressPeriodThisMonth => 'This Month';

  @override
  String progressDurationHm(int h, int m) {
    return '${h}h ${m}m';
  }

  @override
  String progressGoalLine(String time) {
    return 'Goal: $time';
  }

  @override
  String progressPercentCompleted(int pct) {
    return '$pct% completed';
  }

  @override
  String get progressDetailedStats => 'Detailed stats';

  @override
  String get progressStatVocabulary => 'Vocabulary';

  @override
  String get progressStatReading => 'Reading';

  @override
  String get progressStatListening => 'Listening';

  @override
  String get progressStatLessons => 'Lessons';

  @override
  String get progressStatWriting => 'Writing';

  @override
  String get progressStatSpeaking => 'Speaking';

  @override
  String get progressLeaderboard => 'Leaderboard';

  @override
  String get progressActivity => 'Activity';

  @override
  String get leaderboardLoadFailed => 'Cannot load leaderboard';

  @override
  String get leaderboardEmpty => 'No leaderboard data available';

  @override
  String get statDetailVocab => 'Vocabulary detail';

  @override
  String get statDetailReading => 'Reading attempts detail';

  @override
  String get statDetailDictation => 'Listening / dictation detail';

  @override
  String get statDetailSpeaking => 'Speaking practice detail';

  @override
  String get statDetailWriting => 'Writing submissions detail';

  @override
  String get statDetailLessons => 'Lessons completed detail';

  @override
  String get statDetailGeneric => 'Progress detail';

  @override
  String statDetailPeriodLog(String period) {
    return 'Showing $period log.';
  }

  @override
  String statDetailReadingSubtitle(String score, String date) {
    return 'Accuracy: $score% · $date';
  }

  @override
  String statDetailScoreDateSubtitle(String score, String date) {
    return 'Score: $score% · $date';
  }

  @override
  String statDetailWritingSubtitle(String score, String date) {
    return 'Band score: $score · $date';
  }

  @override
  String statDetailDateOnly(Object date) {
    return '$date';
  }

  @override
  String statDetailDateLine(String date) {
    return 'Date: $date';
  }

  @override
  String get statDetailLessonsGroupOther => 'Other';

  @override
  String get statDetailNoData => 'No data found.';

  @override
  String get reportDialogTitle => 'Feedback & support';

  @override
  String get reportDialogSubtitle =>
      'Let us know about an issue or suggestion.';

  @override
  String get reportTypeLabel => 'Report type';

  @override
  String get reportTypeBug => 'Bug report';

  @override
  String get reportTypeFeature => 'Feature request';

  @override
  String get reportTypeImprovement => 'Improvement';

  @override
  String get reportTypeOther => 'Other';

  @override
  String get reportTitleLabel => 'Title';

  @override
  String get reportTitleHint => 'Brief summary of the issue';

  @override
  String get reportDescriptionLabel => 'Description';

  @override
  String get reportDescriptionHint => 'Please describe the details…';

  @override
  String get reportAttachmentsOptional => 'Attachments (optional)';

  @override
  String get submitReport => 'Submit report';

  @override
  String get reportFillTitleDescription =>
      'Please enter a title and description.';

  @override
  String get reportSubmissionFailed => 'Submission failed';

  @override
  String get reportThankYou => 'Thank you!';

  @override
  String get reportReceivedBody =>
      'We have received your report and will look into it shortly.';

  @override
  String get reportUploadScreenshots => 'Tap to upload screenshots';

  @override
  String get reportSupportedFormats => 'Supported formats: JPEG, PNG';

  @override
  String get vocabularyScreenTitle => 'Vocabulary';

  @override
  String get vocabTutorialTooltip => 'Tutorial';

  @override
  String get vocabSearchDictionaryTooltip => 'Search dictionary';

  @override
  String get vocabTabRecently => 'Recently';

  @override
  String get vocabTabLearning => 'Learning';

  @override
  String get vocabTabSaved => 'Saved';

  @override
  String get vocabReviewNowFab => 'Review now';

  @override
  String get vocabNoRecentWords => 'No words looked up recently.';

  @override
  String get vocabLearningEmpty => 'Start learning to build your deck.';

  @override
  String get vocabSavedEmpty => 'Bookmark words to verify later.';

  @override
  String vocabErrorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String vocabNoDetailsForWord(String word) {
    return 'No details found for \"$word\"';
  }

  @override
  String get vocabUnknownError => 'Unknown error';

  @override
  String get vocabReviewNowBadge => 'Review now';

  @override
  String vocabReviewOnDate(String date) {
    return 'Review: $date';
  }

  @override
  String vocabLevelShort(int level) {
    return 'Lv.$level';
  }

  @override
  String get wordNoDefinition => 'No definition';

  @override
  String get wordUnknownType => 'Unknown type';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully';

  @override
  String get changePhotoHint => 'Tap to change photo';

  @override
  String get sectionPublicInfo => 'Public info';

  @override
  String get sectionPrivateDetails => 'Private details';

  @override
  String get sectionSystemInfo => 'System info';

  @override
  String get labelBio => 'Bio';

  @override
  String get hintBio => 'Tell us about yourself…';

  @override
  String get labelGender => 'Gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get labelBirthday => 'Birthday';

  @override
  String get hintSelectDate => 'Select date';

  @override
  String get labelRole => 'Role';

  @override
  String get labelUserId => 'User ID';

  @override
  String get fieldRequired => 'Required';

  @override
  String get copiedToClipboard => 'Copied';

  @override
  String get selectPlaceholder => 'Select';

  @override
  String get dictQuickSearchTitle => 'Quick search';

  @override
  String get dictDictionaryTitle => 'Dictionary';

  @override
  String get dictSearchHint => 'Search words (e.g. serendipity)…';

  @override
  String get dictStartTyping => 'Start typing to search';

  @override
  String get dictNoResults => 'No results found';

  @override
  String get dictDefinitions => 'Definitions';

  @override
  String get dictSeeAlso => 'See also';

  @override
  String get dictTooltipStartLearning => 'Start learning';

  @override
  String get dictTooltipSaveWord => 'Save word';

  @override
  String wordSavedSnackbar(String word) {
    return 'Saved \"$word\"';
  }

  @override
  String wordAddedToLearningQueue(String word) {
    return 'Added \"$word\" to your learning queue!';
  }

  @override
  String get dictNoDefinitionAvailable => 'No definition available';

  @override
  String get accountSuspendedTitle => 'Account suspended';

  @override
  String get accountSessionTerminated => 'Your session has been terminated.';

  @override
  String get suspensionReasonLabel => 'Reason:';

  @override
  String get agreeAndLogout => 'Agree & sign out';

  @override
  String get submissionHistoryTitle => 'Submission history';

  @override
  String get writingHistoryLoadFailed => 'Could not load history';

  @override
  String get writingNoHistoryForTopic => 'No submissions for this topic yet.';

  @override
  String get dateUnknown => 'Unknown date';

  @override
  String get writingTaskDefaultTitle => 'Writing task';

  @override
  String wordCountN(int n) {
    return '$n words';
  }

  @override
  String listeningSentenceNumber(int n) {
    return 'Sentence $n';
  }

  @override
  String get dictationCheckButton => 'Check';

  @override
  String get dictationNextButton => 'Next';

  @override
  String get dictationSaveContinue => 'Save & continue';

  @override
  String get dictationFinishButton => 'Finish';

  @override
  String get dictationTypeWhatYouHearHint => 'Type what you hear…';

  @override
  String get meaningLabel => 'Meaning:';

  @override
  String get quizTimeUpSubmitting => 'Time\'s up! Submitting your answers…';

  @override
  String get translationFailed => 'Translation failed.';

  @override
  String get commonOk => 'OK';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDone => 'Done';

  @override
  String get listeningCompLoadError => 'Could not load this lesson.';

  @override
  String get listeningCompTabTranscript => 'Transcript';

  @override
  String get listeningCompTranslateToggle => 'Translate';

  @override
  String listeningCompQuestionNumber(int n) {
    return 'Question $n';
  }

  @override
  String listeningCompHintSeekSeconds(int seconds) {
    return 'Listen to the segment with the answer (${seconds}s)';
  }

  @override
  String get listeningCompTranscriptLocked => 'Transcript locked';

  @override
  String get listeningCompTranscriptLockedHint =>
      'Submit your answers first to unlock the full audio transcript.';

  @override
  String get listeningCompTranscriptOriginal => 'Original (English)';

  @override
  String get listeningCompTranscriptTranslation => 'Translation (Vietnamese)';

  @override
  String get readingQuizResultTitle => 'Result';

  @override
  String readingQuizResultSummary(int correct, int total, int scorePct) {
    return 'Correct: $correct / $total\nScore: $scorePct%';
  }

  @override
  String get readingTabArticle => 'Article';

  @override
  String readingTabQuestionsCount(int n) {
    return 'Questions ($n)';
  }

  @override
  String get readingSubmitAnswers => 'Submit answers';

  @override
  String get readingNoQuestionsAvailable => 'No questions available.';

  @override
  String get readingFeedbackExplanation => 'Explanation';

  @override
  String readingFeedbackLocationParagraph(int n) {
    return '• Location: Paragraph $n';
  }

  @override
  String readingFeedbackKeySentence(String sentence) {
    return '• Key sentence: \"$sentence\"';
  }

  @override
  String get readingShowTranslation => 'Show translation';

  @override
  String get readingHideTranslation => 'Hide translation';

  @override
  String get readingSubmissionFailed => 'Submission failed';

  @override
  String get readingReviewMode => 'Review mode';

  @override
  String readingReviewingWithScore(int pct) {
    return 'Reviewing (score: $pct%)';
  }

  @override
  String get listeningSkillsPracticeTitle => 'Practice';

  @override
  String get listeningSkillsHeaderTitle => 'Listening task';

  @override
  String get listeningSkillsTabPractice => 'Practice';

  @override
  String get listeningSkillsTabDiscuss => 'Discuss';

  @override
  String get dictationSnackCorrect => 'Correct!';

  @override
  String get dictationSnackTryAgain => 'Try again';

  @override
  String get writingFbErrorTitle => 'Error';

  @override
  String get writingFbNoData => 'No feedback data found.';

  @override
  String get writingFbResultTitle => 'Feedback result';

  @override
  String get writingFbTabOverview => 'Overview';

  @override
  String get writingFbTabDetails => 'Details';

  @override
  String get writingFbTabRewrites => 'Rewrites';

  @override
  String get writingFbTabSamples => 'Samples';

  @override
  String get writingFbTopicRequirement => 'Topic & requirement';

  @override
  String get writingFbNoPromptContent => 'No prompt content available.';

  @override
  String get writingFbOverallBand => 'Overall band score';

  @override
  String get writingFbSubscores => 'Subscores';

  @override
  String get writingFbCriterionTR => 'Task response';

  @override
  String get writingFbCriterionCC => 'Coherence & cohesion';

  @override
  String get writingFbCriterionLR => 'Lexical resource';

  @override
  String get writingFbCriterionGRA => 'Grammar range';

  @override
  String get writingFbCriterionGrammar => 'Grammar';

  @override
  String get writingFbKeyTips => 'Key improvement tips';

  @override
  String get writingFbDetailedCorrection => 'Detailed correction';

  @override
  String get writingFbTapHighlighted =>
      'Tap highlighted text to see an explanation.';

  @override
  String get writingFbNoCorrections => 'No corrections available.';

  @override
  String get writingFbSampleMidTitle => 'Revised version (Band 6.0–7.0)';

  @override
  String get writingFbSampleHighTitle => 'Ideal response (Band 8.0+)';

  @override
  String writingInstructionHowTo(String title) {
    return 'How to write: $title';
  }

  @override
  String get writingInstructionSubtitle => 'Quick guide & structure';

  @override
  String get writingInstructionGotIt => 'Got it, let\'s write!';

  @override
  String get writingInstructionWhatIsIt => 'What is it?';

  @override
  String get writingInstructionSuggestedStructure => 'Suggested structure';

  @override
  String get writingInstructionKeyTipsSection => 'Key tips';

  @override
  String get listeningAutoPlayNext => 'Auto-play next';

  @override
  String get discussionsEmpty => 'No discussions yet';

  @override
  String replyingToUser(String user) {
    return 'Replying to $user';
  }

  @override
  String get commentHintReply => 'Write a reply…';

  @override
  String get commentHintAsk => 'Ask a question…';

  @override
  String get writingSaveDraftTitle => 'Save draft?';

  @override
  String get writingSaveDraftMessage => 'Do you want to save your changes?';

  @override
  String get writingDiscardButton => 'Discard';

  @override
  String get writingResumeTitle => 'Resume writing?';

  @override
  String get writingResumeMessage =>
      'We found an unfinished draft. Continue where you left off?';

  @override
  String get writingStartNewButton => 'Start new';

  @override
  String get writingResumeButton => 'Resume';

  @override
  String get writingInstructionsTooltip => 'Instructions';

  @override
  String get writingPreparingTask => 'Preparing task…';

  @override
  String get writingDraftSavedSnack => 'Draft saved.';

  @override
  String get writingTopicFallback => 'Topic';

  @override
  String get writingPromptTapCollapse => 'Tap to collapse';

  @override
  String get writingPromptTapExpand => 'Tap to expand prompt';

  @override
  String get writingEditorHint => 'Start writing your essay here…';

  @override
  String get writingSubmitEssay => 'Submit essay';

  @override
  String get writingNoTopicsFound => 'No writing topics found';

  @override
  String listeningCueProgress(int done, int total) {
    return '$done / $total completed';
  }

  @override
  String get writingSelectTaskType => 'Select task type';

  @override
  String writingForTopic(String name) {
    return 'For topic: \"$name\"';
  }

  @override
  String get writingSearchTopicsHint => 'Search topics…';

  @override
  String get writingHeaderEssayTitle => 'Essay writing';

  @override
  String get writingHeaderEssaySubtitle =>
      'Practice organizing ideas and building strong arguments.';

  @override
  String get writingAiFeedbackBadge => 'AI feedback';

  @override
  String get writingSearchTopicsTasksHint => 'Search topics, tasks…';

  @override
  String get writingTaskDescOpinion => 'Express your personal view';

  @override
  String get writingTaskDescDiscuss => 'Analyze multiple perspectives';

  @override
  String get writingTaskDescProblemSolution => 'Identify issues and fixes';

  @override
  String get writingTaskDescAdvantages => 'Weigh pros and cons';

  @override
  String get writingTaskDescGeneral => 'General writing practice';

  @override
  String writingSubmissionsCount(int n) {
    return '$n essays';
  }

  @override
  String get writingAiSuggestionTitle => 'AI suggestion';

  @override
  String get writingWhyCorrection => 'Why this correction?';

  @override
  String get writingGotIt => 'Got it';

  @override
  String get wordDetailsNotFound => 'Could not find word details.';

  @override
  String get listeningCompTitle => 'Listening comprehension';

  @override
  String get listeningCompSubtitle =>
      'Listen to the audio and answer multiple choice questions.';

  @override
  String get listeningCompSearchHint => 'Search topics, IDs…';

  @override
  String listeningCompQuestionCount(int n) {
    return '$n questions';
  }

  @override
  String listeningCompHighScore(int pct) {
    return 'High score: $pct%';
  }

  @override
  String get listeningCompNotStarted => 'Not started yet';

  @override
  String get listeningCompReview => 'Review';

  @override
  String get listeningCompRetake => 'Retake';

  @override
  String get listeningCompStart => 'Start';

  @override
  String get listeningCompEmpty => 'No listening lessons found';

  @override
  String get discussionReply => 'Reply';

  @override
  String get discussionReactTooltip => 'React';

  @override
  String get reactionLike => 'Like';

  @override
  String get reactionLove => 'Love';

  @override
  String get reactionHaha => 'Haha';

  @override
  String get reactionWow => 'Wow';

  @override
  String get reactionSad => 'Sad';

  @override
  String get reactionAngry => 'Angry';

  @override
  String get freeSpeakingTitle => 'Free speaking';

  @override
  String get freeSpeakingLoadingConfig => 'Loading setup…';

  @override
  String get freeSpeakingRetry => 'Retry';

  @override
  String get freeSpeakingMicDenied =>
      'Microphone access is required to talk to the AI. Enable it in Settings.';

  @override
  String get freeSpeakingEndCallToChangeVoice =>
      'End the call to change voice.';

  @override
  String get freeSpeakingSelectVoiceTitle => 'Select AI voice';

  @override
  String get freeSpeakingWelcome =>
      'Hello! Choose a voice and tap the microphone to practice English.';

  @override
  String get freeSpeakingConfigErrorShort => 'Could not load calling setup.';

  @override
  String get freeSpeakingStatusConnecting => 'Connecting…';

  @override
  String get freeSpeakingStatusOnline => 'Online';

  @override
  String get freeSpeakingStatusOffline => 'Offline';

  @override
  String get freeSpeakingStatusAiSpeaking => 'AI speaking';

  @override
  String get freeSpeakingHintConnecting => 'Connecting…';

  @override
  String get freeSpeakingHintTypeMessage => 'Type a message…';

  @override
  String get freeSpeakingHintTapMic => 'Tap the mic to connect';

  @override
  String get vapiConfigHintAuth =>
      'Could not load AI calling config (not authenticated).\n\n• Sign in to the app, then open Free Speaking again.\n• If your session expired, sign out and sign back in.';

  @override
  String get vapiConfigHint503 =>
      'Server reports Vapi is not configured (503).\n\n• In backend .env set VAPI_PUBLIC_KEY and VAPI_ASSISTANT_ID (no spaces after =).\n• Save .env and restart the backend.';

  @override
  String vapiConfigHintHttp(int code, String detail) {
    return 'Vapi config API returned an error (HTTP $code).\n\n$detail';
  }

  @override
  String vapiConfigHintNetwork(String detail) {
    return 'Could not load config from the server (network / URL).\n\n• Phone and PC on the same Wi‑Fi.\n• Set the IP in api_config.dart to your machine.\n• Android emulator: use 10.0.2.2.\n\nDetail: $detail';
  }

  @override
  String get vapiConfigHintMissingKeys =>
      'Missing public key or assistant id.\n\n• Backend: add VAPI_PUBLIC_KEY and VAPI_ASSISTANT_ID to .env and restart.\n• Or build with --dart-define=VAPI_PUBLIC_KEY=… --dart-define=VAPI_ASSISTANT_ID=…';

  @override
  String get vocabTutorialSlide1Title => 'Welcome to Vocabulary';

  @override
  String get vocabTutorialSlide1a => 'Build a solid vocabulary using ';

  @override
  String get vocabTutorialSlide1b => 'Spaced Repetition';

  @override
  String get vocabTutorialSlide1c => '.';

  @override
  String get vocabTutorialSlide2Title => 'Search & save';

  @override
  String get vocabTutorialSlide2a => 'Look up words quickly. Tap ';

  @override
  String get vocabTutorialSlide2SaveLabel => 'Save';

  @override
  String get vocabTutorialSlide2b => ' to bookmark, or tap ';

  @override
  String get vocabTutorialSlide2LearnLabel => 'Learn';

  @override
  String get vocabTutorialSlide2c => ' to start studying.';

  @override
  String get vocabTutorialSlide3Title => 'Smart scheduling';

  @override
  String get vocabTutorialSlide3a => 'Based on your study history, the ';

  @override
  String get vocabTutorialSlide3b => 'server';

  @override
  String get vocabTutorialSlide3c => ' automatically calculates your ';

  @override
  String get vocabTutorialSlide3d => 'forgetting curve';

  @override
  String get vocabTutorialSlide3e =>
      ' so you\'re reminded right before you\'re about to forget.';

  @override
  String get vocabTutorialSlide4Title => 'Review every day';

  @override
  String get vocabTutorialSlide4a => 'When a word is due, tap ';

  @override
  String get vocabTutorialSlide4c =>
      '. Rate recall (Hard / Good / Easy) to optimize your schedule.';

  @override
  String get vocabTutorialLetsGo => 'Let\'s go';

  @override
  String get updateAvailableTitle => 'Update available';

  @override
  String get forceUpdateTitle => 'Update required';

  @override
  String get updateAvailableBody =>
      'A new app version is available. Please update for the best experience.';

  @override
  String get updateNowButton => 'Update now';

  @override
  String get updateLaterButton => 'Later';

  @override
  String updateDialogVersionLine(String name, int code) {
    return '$name (+$code)';
  }

  @override
  String get updateDialogWhatsNewTitle => 'What is new';

  @override
  String get updateLinkOpenFailed => 'Could not open the update link.';

  @override
  String get appVersionLabel => 'App version';

  @override
  String get profileTeacherSectionTitle => 'Classes & teaching';

  @override
  String get profileStudentClassesTitle => 'My classes';

  @override
  String get profileStudentClassesSubtitle =>
      'Join a class with an invite code';

  @override
  String get profileTeacherHubTitle => 'Teacher hub';

  @override
  String get profileTeacherHubSubtitle => 'Classrooms and exams';

  @override
  String get profileApplyTeacherTitle => 'Apply to teach';

  @override
  String get profileApplyTeacherSubtitle =>
      'Submit a request for a teacher account';

  @override
  String get teacherApplyTitle => 'Become a teacher';

  @override
  String get teacherApplySubtitle =>
      'Tell us briefly about your teaching background. An admin will review your request.';

  @override
  String get teacherApplyBioLabel => 'Bio';

  @override
  String get teacherApplyOrgLabel => 'School or organization (optional)';

  @override
  String get teacherApplySubmit => 'Submit application';

  @override
  String get teacherApplySubmitted => 'Application submitted';

  @override
  String get teacherDashboardTitle => 'Teacher hub';

  @override
  String get teacherNavDashboard => 'Dashboard';

  @override
  String get teacherNavExams => 'Exam bank';

  @override
  String get teacherShellAppName => 'Teacher';

  @override
  String get teacherShellNavGroup => 'Workspace';

  @override
  String get teacherShellDesktopTitle => 'Use a desktop browser';

  @override
  String get teacherShellDesktopBody =>
      'The teacher workspace is optimized for screens 768px and wider. Open this page on a laptop or desktop for the best experience.';

  @override
  String get teacherShellCollapseSidebar => 'Collapse sidebar';

  @override
  String get teacherShellExpandSidebar => 'Expand sidebar';

  @override
  String get teacherAccountMenuTitle => 'Account & settings';

  @override
  String get teacherAccountRoleTeacher => 'Teacher';

  @override
  String get teacherAccountSectionAbout => 'About';

  @override
  String get teacherAccountOpenMenu => 'Account menu';

  @override
  String get teacherAccountEditProfileSubtitle =>
      'Update your name, avatar, and contact details.';

  @override
  String get adminAccountRoleAdmin => 'Administrator';

  @override
  String get adminAccountOpenMenu => 'Account menu';

  @override
  String get adminUserRoleStudent => 'Student';

  @override
  String get adminUserRoleTeacher => 'Teacher';

  @override
  String get adminUserRoleAdmin => 'Administrator';

  @override
  String get adminUserStatusOnline => 'Online';

  @override
  String get adminUserStatusOffline => 'Offline';

  @override
  String get adminUserActiveNow => 'Active now';

  @override
  String get adminUserNeverActive => 'Never active';

  @override
  String adminUserLastActive(String when) {
    return 'Last active: $when';
  }

  @override
  String teacherDashboardGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String teacherDashboardTodayMeta(String time) {
    return 'Today · $time';
  }

  @override
  String get teacherDashboardActionNewExam => 'New exam';

  @override
  String get teacherClassFab => 'New class';

  @override
  String get teacherClassCreateTitle => 'Create classroom';

  @override
  String get teacherClassNameLabel => 'Class name';

  @override
  String get teacherClassCreated => 'Classroom created';

  @override
  String get teacherMyClassrooms => 'My classrooms';

  @override
  String get teacherNoClassrooms =>
      'No classrooms yet. Create one with the + button.';

  @override
  String get teacherInviteCode => 'Invite code';

  @override
  String get teacherClassroomDetailTitle => 'Classroom';

  @override
  String get teacherNoExams =>
      'Create a sample exam from the Teacher hub first.';

  @override
  String get teacherAssignmentCreated => 'Exam assigned to this class';

  @override
  String get teacherAssignFirstExam => 'Assign latest exam to this class';

  @override
  String teacherClassroomMemberCountActive(int count) {
    return '$count students in this class';
  }

  @override
  String teacherClassroomMemberCountPending(int count) {
    return '$count awaiting approval';
  }

  @override
  String get teacherAssignExamToClass => 'Assign exam to this class';

  @override
  String get teacherPickExamToAssign => 'Choose a published exam';

  @override
  String get teacherNoPublishedExams =>
      'No published exams yet. Publish an exam under My exams first.';

  @override
  String get copyInviteCode => 'Copy invite code';

  @override
  String get adminTeacherApplicationsTitle => 'Teacher applications';

  @override
  String get adminTeacherApplicationsSubtitle => 'Review pending requests';

  @override
  String get adminTeacherApplicationsEmpty => 'No applications in this state.';

  @override
  String get adminTeacherApprove => 'Approve';

  @override
  String get adminTeacherReject => 'Reject';

  @override
  String get adminTeacherRejectReason => 'Reason for rejection';

  @override
  String get studentClassesTitle => 'My classes';

  @override
  String get studentClassesSubtitle =>
      'Open a class to see only assignments from that class.';

  @override
  String get studentJoinClassTitle => 'Join with invite code';

  @override
  String get studentJoinClassSubtitle =>
      'Use the code from your teacher. Assignments will appear inside each class.';

  @override
  String get studentInviteCodeLabel => 'Invite code';

  @override
  String get studentJoinClassButton => 'Join';

  @override
  String get studentJoinClassSuccess => 'Joined classroom';

  @override
  String get studentMyClassesTitle => 'Your classrooms';

  @override
  String get studentNoClasses => 'You are not in any class yet.';

  @override
  String get studentClassOpen => 'Open class';

  @override
  String studentClassAssignmentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count assignments',
      one: '1 assignment',
      zero: 'No assignments',
    );
    return '$_temp0';
  }

  @override
  String studentClassLiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count live',
      one: '1 live',
    );
    return '$_temp0';
  }

  @override
  String get studentClassDetailTitle => 'Classroom';

  @override
  String get studentClassDetailAssignmentsTitle => 'Class assignments';

  @override
  String get studentClassDetailAssignmentsSubtitle =>
      'Only assignments from this classroom are shown here.';

  @override
  String get studentClassNoAssignments =>
      'This class does not have any assignments yet.';

  @override
  String get studentClassAssignmentNotYetOpen =>
      'Not open yet — check the schedule from your teacher.';

  @override
  String get studentClassAssignmentClosed =>
      'This assignment window has closed.';

  @override
  String get studentClassInfoTitle => 'Class information';

  @override
  String studentClassMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active students',
      one: '1 active student',
    );
    return '$_temp0';
  }

  @override
  String get studentClassJoinPolicyOpen => 'Open join';

  @override
  String get studentClassJoinPolicyApproval => 'Approval required';

  @override
  String studentClassCreatedAt(String date) {
    return 'Created $date';
  }

  @override
  String studentClassUpdatedAt(String date) {
    return 'Updated $date';
  }

  @override
  String studentClassScheduleDue(String date) {
    return 'Due $date';
  }

  @override
  String studentClassScheduleWindow(String opens, String closes) {
    return '$opens – $closes';
  }

  @override
  String get studentClassPublicJoin => 'Join public exam';

  @override
  String studentClassTeacher(String name) {
    return 'Teacher: $name';
  }

  @override
  String get studentClassNoDescription => 'No description for this class.';

  @override
  String get teacherClassDetailAssignmentsTitle => 'Class assignments';

  @override
  String get teacherClassDetailAssignmentsSubtitle =>
      'Exams assigned to this class — schedule, format, and student progress.';

  @override
  String get teacherClassDetailActiveTitle => 'Active assignments';

  @override
  String get teacherClassDetailActiveSubtitle =>
      'Open sessions and assignments students can still take.';

  @override
  String get teacherClassDetailHistoryTitle => 'Session history';

  @override
  String get teacherClassDetailHistorySubtitle =>
      'Live exams whose latest session has ended.';

  @override
  String get teacherClassHistoryOpenGrading => 'Grade';

  @override
  String teacherClassHistorySessionEnded(String date) {
    return 'Last session ended: $date';
  }

  @override
  String get teacherClassNoAssignments =>
      'No exams assigned to this class yet.';

  @override
  String get teacherClassNoHistory =>
      'No ended live sessions for this class yet.';

  @override
  String get teacherClassTabOverview => 'Overview';

  @override
  String get teacherClassTabAssignments => 'Assignments';

  @override
  String get teacherClassTabMembers => 'Members';

  @override
  String get teacherClassTabSettings => 'Settings';

  @override
  String get teacherClassMembersEmpty => 'No members yet.';

  @override
  String get teacherClassMemberRemove => 'Remove';

  @override
  String get teacherClassMemberRemoveConfirm =>
      'Remove this student from the class?';

  @override
  String get teacherClassMemberStatusPending => 'Pending approval';

  @override
  String get teacherClassSaveSettings => 'Save changes';

  @override
  String get teacherClassSettingsSaved => 'Classroom updated';

  @override
  String get teacherClassRotateInvite => 'Rotate invite code';

  @override
  String get teacherClassRotateInviteConfirm =>
      'Generate a new invite code? The old code will stop working.';

  @override
  String get teacherClassArchive => 'Archive class';

  @override
  String get teacherClassArchiveConfirm =>
      'Archive this class? Students will no longer see new assignments here.';

  @override
  String get teacherClassArchivedMessage => 'Class archived';

  @override
  String get teacherExamArchive => 'Archive exam';

  @override
  String get teacherExamArchiveConfirm =>
      'Archive this exam? You cannot assign archived exams.';

  @override
  String get teacherExamArchived => 'Exam archived';

  @override
  String get teacherExamDelete => 'Delete permanently';

  @override
  String get teacherExamDeleteConfirm =>
      'Delete this exam permanently? All assignments without submitted work will be removed. This cannot be undone.';

  @override
  String get teacherExamDeleted => 'Exam deleted';

  @override
  String get teacherExamRestore => 'Restore exam';

  @override
  String get teacherExamRestoreConfirm => 'Restore this exam from archive?';

  @override
  String get teacherExamRestored => 'Exam restored';

  @override
  String get teacherExamsFilterAll => 'All';

  @override
  String get teacherExamsFilterDraft => 'Draft';

  @override
  String get teacherExamsFilterPublished => 'Published';

  @override
  String get teacherExamsFilterArchived => 'Archived';

  @override
  String get teacherExamsFilterEmpty => 'No exams in this filter.';

  @override
  String get teacherExamPublishConfirm =>
      'Publish this exam so you can assign it to classes?';

  @override
  String get teacherExamMoreActions => 'More actions';

  @override
  String get teacherAssignmentDelete => 'Delete assignment';

  @override
  String get teacherAssignmentDeleteConfirm =>
      'Delete this assignment? Only allowed if no student has submitted yet.';

  @override
  String get teacherAssignmentDeleted => 'Assignment deleted';

  @override
  String get teacherAssignmentClose => 'Close assignment';

  @override
  String get teacherAssignmentCloseConfirm =>
      'Close this assignment? Students can no longer start new attempts.';

  @override
  String get teacherAssignmentClosed => 'Assignment closed';

  @override
  String get teacherAssignmentAudience => 'Audience';

  @override
  String get teacherAssignmentAudienceClassroom => 'Classroom';

  @override
  String get teacherAssignmentAudiencePublic => 'Public link';

  @override
  String get teacherAssignmentPublicMaxUsesHint => 'Max uses (optional)';

  @override
  String get teacherAssignmentPublicExpiresHint => 'Pick expiry (optional)';

  @override
  String get teacherAssignmentPublicTokenTitle => 'Public join token';

  @override
  String get teacherAssignmentPublicTokenBody =>
      'Share this token with students. They paste it in “Join public exam” (or your shared instructions).';

  @override
  String get dashboardPublicCopyToken => 'Copy token';

  @override
  String get dashboardPublicTokenCopied => 'Token copied';

  @override
  String get dashboardPublicRotateLink => 'New link';

  @override
  String get dashboardPublicRotateConfirm =>
      'Generate a new public token? Old links will stop working.';

  @override
  String get dashboardPublicCloseLink => 'Close link';

  @override
  String get dashboardPublicCloseConfirm =>
      'Close this public assignment? New participants cannot start.';

  @override
  String get teacherApplyStatusPending => 'Your application is pending review.';

  @override
  String get teacherApplyStatusApproved =>
      'You are approved as a teacher. Open the teacher hub from your profile.';

  @override
  String get teacherApplyStatusRejected => 'Your application was rejected.';

  @override
  String get teacherApplyStatusWithdrawn =>
      'You withdrew your application. You can submit a new one.';

  @override
  String get teacherApplyStatusNone =>
      'No application yet — tell us about yourself below.';

  @override
  String get teacherApplyRejectReason => 'Note from reviewer';

  @override
  String get teacherApplyWithdraw => 'Withdraw application';

  @override
  String get teacherApplyWithdrawConfirm =>
      'Withdraw your pending application?';

  @override
  String get teacherApplyGoToHub => 'Open teacher hub';

  @override
  String get homeQuickMyClasses => 'Classes';

  @override
  String get homeQuickPublicExam => 'Public exam';

  @override
  String get studentJoinClassByTokenLabel => 'Invite link token';

  @override
  String get studentJoinClassByTokenHint =>
      'Paste the long token from your teacher’s class link';

  @override
  String get studentJoinClassByTokenButton => 'Join with link';

  @override
  String get studentExamsHubTitle => 'Public exam join';

  @override
  String get studentExamsHubSubtitle =>
      'Class assignments stay inside each class. Use this screen only when you have a public exam token from your teacher.';

  @override
  String studentExamTimeRemainingHM(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String studentExamTimeRemainingMS(int minutes, int seconds) {
    return '${minutes}m ${seconds}s';
  }

  @override
  String studentExamTimeRemainingS(int seconds) {
    return '${seconds}s';
  }

  @override
  String get studentExamRunnerLoadFailed => 'Could not load this exam.';

  @override
  String get teacherMobileWorkspaceTitle => 'Teacher hub';

  @override
  String get teacherMobileWorkspaceBody =>
      'Use the tabs below for quick navigation. For complex exam editing, a wider screen is recommended.';

  @override
  String teacherClassOverviewMeta(int students, String policy) {
    return '$students students · $policy';
  }

  @override
  String get teacherClassStatActiveAssignments => 'Active';

  @override
  String get teacherClassStatHistoryAssignments => 'History';

  @override
  String get teacherClassStatStudents => 'Students';

  @override
  String get teacherClassStatPendingMembers => 'Pending join';

  @override
  String get teacherClassCreatedLabel => 'Created';

  @override
  String get teacherClassUpdatedLabel => 'Updated';

  @override
  String get teacherClassInviteCardHint =>
      'Share this code so students can join the class.';

  @override
  String get teacherClassRecentAssignments => 'Recent assignments';

  @override
  String get teacherClassViewAllAssignments => 'View all assignments';

  @override
  String get teacherClassSettingsAbout => 'About this class';

  @override
  String get teacherClassSettingsJoin => 'Join settings';

  @override
  String get teacherClassAssignExamCta => 'Assign an exam';

  @override
  String get examCardFormatClassic => 'Classic exam';

  @override
  String get examCardFormatIntegrated => 'Integrated 4 skills';

  @override
  String get examCardFormatSkills => 'Skills + Grammar';

  @override
  String get examCardScheduleTitle => 'Schedule';

  @override
  String get examCardExamInfoTitle => 'Exam details';

  @override
  String examCardQuestionsCount(int count) {
    return '$count questions';
  }

  @override
  String examCardPointsMax(int points) {
    return 'Max $points pts';
  }

  @override
  String examCardGrammarSkillsCount(int grammar, int skills) {
    return '$grammar grammar · $skills skill parts';
  }

  @override
  String examCardAssignedAt(String date) {
    return 'Assigned $date';
  }

  @override
  String examCardRoomCode(String code) {
    return 'Room code: $code';
  }

  @override
  String examCardOpensAt(String date) {
    return 'Opens $date';
  }

  @override
  String examCardClosesAt(String date) {
    return 'Closes $date';
  }

  @override
  String examCardSessionStarted(String date) {
    return 'Session started $date';
  }

  @override
  String get examCardStatusLobby => 'Lobby open — waiting to go live';

  @override
  String get examCardStatusLive => 'Live now';

  @override
  String get examCardMyAttemptInProgress => 'You have a draft in progress';

  @override
  String get examCardMyAttemptSubmitted => 'Submitted — results pending';

  @override
  String get examCardMyAttemptVoid => 'Attempt voided';

  @override
  String examCardMyAttemptScore(num awarded, num max) {
    return 'Score: $awarded / $max';
  }

  @override
  String get examCardTeacherNoAttempts => 'No student attempts yet';

  @override
  String examCardTeacherAttemptsSummary(
      int submitted, int inProgress, int total) {
    return '$submitted submitted · $inProgress in progress · $total total';
  }

  @override
  String get examCardManageSession => 'Open session';

  @override
  String get studentExamsPageSubtitle =>
      'Assignments from your classes are listed inside each class. Use a public link only when your teacher shared one.';

  @override
  String get studentExamsGoToClasses => 'Go to my classes';

  @override
  String get studentExamsMenu => 'Exams';

  @override
  String get studentExamsTitle => 'Available exams';

  @override
  String get studentNoExams => 'No exams available for your classes.';

  @override
  String get studentExamStart => 'Start';

  @override
  String get studentExamResume => 'Continue';

  @override
  String get studentExamResumeHint => 'In progress — tap to continue';

  @override
  String get examCardAlreadySubmitted => 'Submitted';

  @override
  String get studentExamUnknownTitle => 'Exam';

  @override
  String get studentExamRunnerTitle => 'Exam';

  @override
  String get studentExamSubmit => 'Submit answers';

  @override
  String get studentExamSubmitted => 'Submitted';

  @override
  String get studentExamScore => 'Score';

  @override
  String studentExamQuestionProgress(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get studentExamPrevious => 'Previous';

  @override
  String get studentExamNext => 'Next';

  @override
  String get studentExamItemUnsupported =>
      'This question type cannot be answered in the app yet. Skip or contact your teacher.';

  @override
  String get studentExamEssayPlaceholder => 'Write your answer here…';

  @override
  String studentExamScoreTotals(Object earned, Object max) {
    return 'Score: $earned / $max';
  }

  @override
  String get studentExamNoQuestions =>
      'This exam has no questions you can answer here yet.';

  @override
  String get examModeSelfPaced => 'Self-paced';

  @override
  String get examModeScheduled => 'Scheduled';

  @override
  String get examModeRealtime => 'Live session';

  @override
  String get examOpenLobby => 'Enter lobby';

  @override
  String get examWaitingForTeacher => 'Waiting for the teacher to start';

  @override
  String get examCardLiveSessionEnded =>
      'The teacher has ended this live session.';

  @override
  String examCardLiveSessionEndedAt(String date) {
    return 'Session ended: $date';
  }

  @override
  String get examCardViewMySubmission => 'View my submission';

  @override
  String get examSessionEndedByTeacher =>
      'The teacher ended this live session. Your answers were saved.';

  @override
  String get examJoinByLinkTitle => 'Join with public link';

  @override
  String get examJoinByLinkHint => 'Paste the token from your teacher';

  @override
  String get examJoinPreview => 'Preview';

  @override
  String get examJoinStart => 'Start exam';

  @override
  String get examSessionRoomCode => 'Room code';

  @override
  String get examSessionGo => 'Open exam';

  @override
  String get studentExamLeaveRealtimeTitle => 'Leave this exam?';

  @override
  String get studentExamLeaveRealtimeMessage =>
      'If you leave now, you cannot return to this live exam. Your attempt will be closed.';

  @override
  String get studentExamLeaveRealtimeConfirm => 'Leave exam';

  @override
  String get studentExamLeaveRealtimeCancel => 'Keep working';

  @override
  String get studentExamVoluntaryExitBlocked =>
      'You left this exam and cannot re-enter.';

  @override
  String get studentExamCannotRejoinAfterLeave =>
      'You cannot rejoin this exam after leaving.';

  @override
  String get teacherExamSessionLeavePageHint =>
      'Leaving this page does not end the exam for students. End the session here when you are ready to finish.';

  @override
  String get teacherAssignmentsSection => 'Assignments';

  @override
  String get teacherNoAssignments => 'No assignments yet.';

  @override
  String get teacherDashboardSubtitle =>
      'Classes, exams, and grading in one calm workspace.';

  @override
  String get teacherDashboardOverview => 'Overview';

  @override
  String get teacherDashboardStatClasses => 'Classes';

  @override
  String get teacherDashboardStatAssignments => 'Assignments';

  @override
  String get teacherDashboardStatLiveModes => 'Live mode';

  @override
  String get teacherDashboardStatDraftExams => 'Draft exams';

  @override
  String get teacherDashboardStatPublishedExams => 'Published';

  @override
  String get teacherDashboardStatNeedsAction => 'Needs action';

  @override
  String get teacherDashboardShortcuts => 'Shortcuts';

  @override
  String get teacherDashboardShortcutExamBank => 'Exam bank';

  @override
  String get teacherDashboardShortcutNewSkillsExam => 'New skills exam';

  @override
  String get teacherDashboardShortcutOpen => 'Open';

  @override
  String get teacherDashboardSectionLive => 'Live sessions';

  @override
  String get teacherDashboardLiveEmpty =>
      'No realtime assignments yet. Assign an exam in Live mode to run a session.';

  @override
  String get teacherDashboardLiveWaitingSession =>
      'No active session — open console to start';

  @override
  String get teacherDashboardLiveStatusGrading => 'Ending session';

  @override
  String teacherDashboardLiveSessionStatus(String status) {
    return 'Session: $status';
  }

  @override
  String get teacherDashboardSectionGrading => 'Grading queue';

  @override
  String teacherDashboardViewAllQueue(int count) {
    return 'View all ($count)';
  }

  @override
  String get teacherDashboardViewAllQueueShort => 'View all';

  @override
  String teacherDashboardQueueMoreHidden(int count) {
    return '+$count more in queue';
  }

  @override
  String get teacherDashboardGradingQueueAllTitle => 'Pending grading';

  @override
  String teacherDashboardGradingQueueAllSubtitle(int count) {
    return '$count submissions need your action';
  }

  @override
  String teacherDashboardViewAllLiveQueue(int count) {
    return 'All live rooms ($count)';
  }

  @override
  String get teacherDashboardLiveQueueAllTitle => 'Live sessions';

  @override
  String teacherDashboardLiveQueueAllSubtitle(int count) {
    return '$count realtime assignments in progress';
  }

  @override
  String get teacherDashboardScrollHint => 'Scroll sideways to browse rooms';

  @override
  String get teacherDashboardGradingEmpty =>
      'No submitted attempts need your attention right now.';

  @override
  String get teacherDashboardGradingLoading => 'Loading grading queue…';

  @override
  String get teacherDashboardSectionAssignments => 'Assignments';

  @override
  String get teacherDashboardAssignmentsPerClassHint =>
      'Filter by class — manage history inside each class.';

  @override
  String get teacherDashboardFilterByClass => 'Class';

  @override
  String get teacherDashboardAllClasses => 'All classes';

  @override
  String get teacherDashboardFilterAll => 'All';

  @override
  String get teacherDashboardFilterPublic => 'Public link';

  @override
  String get teacherDashboardSearchHint => 'Search by exam title';

  @override
  String get teacherDashboardAudienceClass => 'Class';

  @override
  String get teacherDashboardAudiencePublic => 'Public link';

  @override
  String teacherDashboardDue(String date) {
    return 'Due $date';
  }

  @override
  String teacherDashboardWindow(String opens, String closes) {
    return '$opens – $closes';
  }

  @override
  String teacherDashboardClassLabel(String name) {
    return 'Class: $name';
  }

  @override
  String get teacherDashboardOpenConsole => 'Open console';

  @override
  String get teacherDashboardOpenGrading => 'Open grading';

  @override
  String get teacherDashboardStudentUnknown => 'Student';

  @override
  String get teacherDashboardGradingChipManual => 'Manual grading';

  @override
  String get teacherDashboardGradingChipAi => 'AI grading';

  @override
  String get teacherDashboardGradingChipRelease => 'Release results';

  @override
  String get teacherExamConsoleTitle => 'Live exam session';

  @override
  String get teacherExamSessionLiveRosterTitle => 'Students in lobby';

  @override
  String get teacherExamSessionLiveRosterTitleLive => 'Students in exam';

  @override
  String get teacherExamSessionLiveRosterHint =>
      'Count and list update in real time when students join the waiting room.';

  @override
  String get teacherExamParticipantNotReady => 'Not ready';

  @override
  String get teacherExamParticipantReady => 'Ready';

  @override
  String get teacherExamParticipantInProgress => 'In progress';

  @override
  String get teacherExamParticipantSubmitted => 'Submitted';

  @override
  String get teacherExamParticipantExpired => 'Time expired';

  @override
  String get teacherExamParticipantVoided => 'Removed';

  @override
  String teacherExamSessionJoinedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students joined',
      one: '1 student joined',
    );
    return '$_temp0';
  }

  @override
  String get teacherExamSessionNoParticipantsYet =>
      'No students in the lobby yet.';

  @override
  String get teacherExamSessionTabControl => 'Session control';

  @override
  String get teacherExamSessionTabLiveMonitor => 'Live monitor';

  @override
  String get teacherExamSessionShowDetails => 'Details';

  @override
  String get teacherExamSessionHideDetails => 'Hide';

  @override
  String teacherLiveMonitorSummaryInProgress(int count) {
    return '$count in progress';
  }

  @override
  String teacherLiveMonitorSummarySubmitted(int count) {
    return '$count submitted';
  }

  @override
  String teacherLiveMonitorSummaryFlagged(int count) {
    return '$count flagged';
  }

  @override
  String teacherLiveMonitorSummaryAvgProgress(double percent) {
    return 'Avg. $percent%';
  }

  @override
  String teacherLiveMonitorSummaryLine(
      int inProgress, int submitted, int flagged, String avg) {
    return '$inProgress in progress · $submitted submitted · $flagged flagged · avg $avg%';
  }

  @override
  String get teacherLiveMonitorFilterAll => 'All';

  @override
  String get teacherLiveMonitorFilterInProgress => 'In progress';

  @override
  String get teacherLiveMonitorFilterSubmitted => 'Submitted';

  @override
  String get teacherLiveMonitorFilterFlagged => 'Flagged';

  @override
  String get teacherLiveMonitorNoStudents => 'No students match this filter.';

  @override
  String teacherLiveMonitorProgressLabel(
      int answered, int total, double percent) {
    return '$answered/$total · $percent%';
  }

  @override
  String get teacherLiveMonitorIntegrityHigh => 'High integrity risk';

  @override
  String get teacherLiveMonitorIntegrityMedium => 'Medium integrity risk';

  @override
  String get teacherLiveMonitorCurrentQuestion => 'Current focus';

  @override
  String get teacherLiveMonitorStatusSubmitted => 'Submitted';

  @override
  String get teacherLiveMonitorIntegrityLabel => 'Integrity';

  @override
  String get teacherLiveMonitorTabSwitches => 'Tab switches';

  @override
  String get teacherLiveMonitorFocusLoss => 'Focus loss';

  @override
  String get teacherLiveMonitorCopyPaste => 'Copy/paste';

  @override
  String get teacherLiveMonitorDetailProgress => 'Progress';

  @override
  String get teacherLiveMonitorDetailSections => 'Skill sections';

  @override
  String get teacherLiveMonitorDetailGrammar => 'Grammar answers';

  @override
  String get teacherLiveMonitorGrammarQuestion => 'Question';

  @override
  String get teacherLiveMonitorGrammarNotAnswered => 'Not answered';

  @override
  String get teacherLiveMonitorGrammarCorrect => 'Correct';

  @override
  String get teacherLiveMonitorGrammarWrong => 'Wrong';

  @override
  String get teacherLiveMonitorWatchScreen => 'Watch live screen';

  @override
  String get teacherLiveMonitorQuestionStripLegend =>
      'Green: correct · Red: wrong · Gray: not answered yet';

  @override
  String teacherLiveMirrorPageTitle(String name, String exam) {
    return '$name — $exam';
  }

  @override
  String teacherLiveMirrorPageTitleSimple(String name) {
    return 'Live view — $name';
  }

  @override
  String get teacherLiveMirrorLiveBadge => 'Live — mirroring student screen';

  @override
  String get teacherLiveMirrorNoContent => 'No exam content to display.';

  @override
  String get teacherLiveMirrorWritingDraft => 'Writing draft (live)';

  @override
  String get teacherLiveMirrorWritingEmpty =>
      'Student has not started writing yet.';

  @override
  String teacherLiveMirrorWordCount(int count) {
    return '$count words';
  }

  @override
  String get teacherLiveMirrorSkillCompleted => 'Skill section marked complete';

  @override
  String teacherLiveMirrorSkillInProgress(String skill) {
    return 'Working on $skill…';
  }

  @override
  String teacherLiveMirrorBrowsingPart(String part) {
    return 'Viewing: $part';
  }

  @override
  String get teacherLiveMirrorFollowStudent => 'Follow student';

  @override
  String get teacherLiveMirrorWritingPrompt => 'Exam prompt';

  @override
  String get teacherLiveMirrorListeningEmpty =>
      'Student has not entered any dictation yet.';

  @override
  String teacherLiveMirrorListeningProgress(int saved, int total) {
    return 'Dictation progress: $saved / $total cues';
  }

  @override
  String teacherLiveMirrorListeningCue(int number) {
    return 'Cue $number';
  }

  @override
  String get teacherLiveMirrorSpeakingInProgress =>
      'Student is doing the speaking exercise.';

  @override
  String get teacherLiveMirrorReadingEmpty =>
      'Student has not answered any reading questions yet.';

  @override
  String teacherLiveMirrorReadingQuestion(int number) {
    return 'Question $number';
  }

  @override
  String get examSessionStatusLobby => 'Waiting room (lobby)';

  @override
  String get examSessionStatusLive => 'Exam in progress';

  @override
  String get examSessionStatusClosed => 'Session ended';

  @override
  String get examSessionStatusCanceled => 'Session canceled';

  @override
  String examSessionCreatedAt(String date) {
    return 'Session created $date';
  }

  @override
  String examSessionScheduledEndAt(String date) {
    return 'Scheduled end: $date';
  }

  @override
  String examSessionTimeLimitOnStart(int minutes) {
    return 'Time limit: $minutes min (timer starts when you start the session)';
  }

  @override
  String get examSessionEndsWhenTeacherEnds =>
      'No time limit — ends when you end the session';

  @override
  String examSessionReadyCount(int ready, int total) {
    return '$ready ready · $total in lobby';
  }

  @override
  String get examSessionStudentReady => 'Ready';

  @override
  String get examSessionStudentNotReady => 'Not ready';

  @override
  String get examSessionMarkReady => 'I\'m ready';

  @override
  String get examSessionMarkNotReady => 'Not ready yet';

  @override
  String get examSessionCancelReady => 'Cancel ready';

  @override
  String get examSessionReadyHint =>
      'Tell your teacher you are ready to start. This updates in real time.';

  @override
  String get examSessionKickStudentTitle => 'Remove student?';

  @override
  String examSessionKickStudentConfirm(String name) {
    return 'Remove $name from this exam room? They will leave the lobby immediately.';
  }

  @override
  String get examSessionKickStudentAction => 'Remove';

  @override
  String get examSessionKickStudentDone => 'Student removed from the room.';

  @override
  String get examSessionKickedByTeacher =>
      'Your teacher removed you from this exam session.';

  @override
  String get examSessionLobbyParticipantsTitle => 'Participants';

  @override
  String get examSessionLobbyParticipantsHint =>
      'Who has joined this waiting room (live).';

  @override
  String get teacherExamCreateSession => 'Create / refresh lobby';

  @override
  String get teacherExamStartSession => 'Start for everyone';

  @override
  String get teacherExamEndSession => 'End and submit all';

  @override
  String get teacherExamGradingTitle => 'Grading';

  @override
  String get teacherExamRunAi => 'AI suggestions';

  @override
  String get teacherExamReleaseResults => 'Release results';

  @override
  String get teacherExamGradingConsole => 'Session';

  @override
  String get teacherExamGradingGrade => 'Grade';

  @override
  String get teacherMyExamsTitle => 'My exams';

  @override
  String get teacherExamNewExam => 'New exam';

  @override
  String get teacherExamsListEmpty =>
      'You have no exams yet. Tap + to create a draft.';

  @override
  String get teacherExamUntitled => 'Untitled exam';

  @override
  String get teacherExamStatusDraft => 'Draft';

  @override
  String get teacherExamStatusPublished => 'Published';

  @override
  String get teacherExamStatusArchived => 'Archived';

  @override
  String get teacherExamEditorTitle => 'Edit exam';

  @override
  String get teacherExamSaveDraft => 'Save';

  @override
  String get teacherExamPublish => 'Publish';

  @override
  String get teacherExamAddMcq => 'MCQ';

  @override
  String get teacherExamAddEssay => 'Essay';

  @override
  String get teacherExamStemLabel => 'Question';

  @override
  String get teacherExamOptionsHint => 'Options';

  @override
  String get teacherExamOptionsPipeHint => 'Separate options with |';

  @override
  String get teacherExamCorrectIndex => 'Correct option index (0-based)';

  @override
  String get teacherExamEssayPrompt => 'Essay prompt';

  @override
  String get teacherExamPoints => 'Points';

  @override
  String get teacherExamItemsTitle => 'Questions';

  @override
  String get teacherExamNoItemsHint =>
      'Add at least one question before publishing.';

  @override
  String get teacherExamPublishNeedItems =>
      'Add at least one question before publishing.';

  @override
  String get teacherExamDraftSaved => 'Draft saved';

  @override
  String get teacherExamPublished => 'Exam published';

  @override
  String get teacherExamOnlyDraftEditable =>
      'Only draft exams can be edited here.';

  @override
  String get teacherExamReadOnlyPublished =>
      'This exam is published. Create a new draft to change content.';

  @override
  String get teacherExamTitleLabel => 'Title';

  @override
  String get teacherExamTitleHint => 'e.g. Midterm — Reading & Listening';

  @override
  String get teacherExamDescriptionLabel => 'Description';

  @override
  String get teacherExamResultsPolicy => 'When students see results';

  @override
  String get teacherExamPolicyAfterSubmit =>
      'Right after submit (if auto-graded)';

  @override
  String get teacherExamPolicyAfterRelease => 'After teacher releases grades';

  @override
  String get teacherExamPolicyNever => 'Never';

  @override
  String get teacherAssignmentWizardTitle => 'Assign exam';

  @override
  String get teacherAssignExamDialogSubtitle =>
      'Choose class, delivery mode, and schedule.';

  @override
  String teacherAssignExamDialogSubtitleExam(String examTitle) {
    return 'Assign “$examTitle” to a class or link.';
  }

  @override
  String get teacherAssignExamModeHintSelfPaced =>
      'Students start anytime before the due date.';

  @override
  String get teacherAssignExamModeHintScheduled =>
      'Fixed open and close times (markers on Schedule).';

  @override
  String get teacherAssignExamModeHintRealtime =>
      'You open a live room from the dashboard — not a calendar slot.';

  @override
  String get teacherAssignExamModeHintPractice =>
      'Practice only — no official grading.';

  @override
  String get teacherAssignExamRealtimeNote =>
      'After assigning, open Live rooms on the dashboard to start the session.';

  @override
  String get teacherAssignExamCalendarNote =>
      'Open, Due, and Close appear on Schedule. “Ongoing” on the calendar means the window is open, not a live room.';

  @override
  String get teacherAssignExamAdvancedRules => 'Attempts & results';

  @override
  String get teacherAssignExamAdvancedRulesHint =>
      'Attempts, when students see scores, partial submit';

  @override
  String get teacherAssignExamRulesShow => 'Customize';

  @override
  String get teacherAssignExamRulesHide => 'Collapse';

  @override
  String get teacherAssignmentClassroom => 'Classroom';

  @override
  String get teacherAssignmentPickClass => 'Select a classroom.';

  @override
  String get teacherAssignmentMode => 'Mode';

  @override
  String get teacherAssignmentDueDate => 'Due date (optional)';

  @override
  String get teacherAssignmentOpensAt => 'Opens at';

  @override
  String get teacherAssignmentClosesAt => 'Closes at';

  @override
  String get teacherAssignmentTimeLimitSec => 'Time limit (seconds, optional)';

  @override
  String get teacherAssignmentTimeLimitMinutes =>
      'Time limit per attempt (minutes)';

  @override
  String get teacherAssignmentTimeLimitMinutesHint => 'e.g. 60';

  @override
  String get teacherAssignmentTimeLimitHelp =>
      'Countdown starts when the student begins (or when you start a live session). Leave empty for no per-attempt timer — only due date / exam window applies.';

  @override
  String teacherAssignmentTimeLimitPresetMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get teacherAssignmentCreate => 'Create assignment';

  @override
  String get teacherAssignmentExamNotPublished =>
      'Publish the exam first, then assign it.';

  @override
  String get teacherAssignmentOptional => 'Optional';

  @override
  String get teacherAssignmentAllowPartialSubmit =>
      'Allow submit before finishing all parts';

  @override
  String get teacherAssignmentAllowPartialSubmitHint =>
      'Students may submit with unfinished sections; those sections score zero.';

  @override
  String get teacherAssignmentSectionAudience => 'Audience';

  @override
  String get teacherAssignmentSectionDelivery => 'Schedule & mode';

  @override
  String get teacherAssignmentSectionRules => 'Attempts & results';

  @override
  String get teacherAssignmentAttemptPolicy => 'Attempts per student';

  @override
  String get teacherAssignmentAttemptSingle => 'Once';

  @override
  String get teacherAssignmentAttemptUnlimited => 'Unlimited';

  @override
  String get teacherAssignmentAttemptLimited => 'Limited';

  @override
  String get teacherAssignmentMaxAttempts => 'Max attempts';

  @override
  String get teacherAssignmentShowResults => 'When students see results';

  @override
  String get examPartialSubmitTitle => 'Submit incomplete exam?';

  @override
  String get examPartialSubmitMessage =>
      'You have not finished every part. Unfinished sections will receive no points.';

  @override
  String get examPartialSubmitIncompleteHeader => 'Still incomplete:';

  @override
  String get examPartialSubmitConfirm => 'Submit anyway';

  @override
  String get teacherGradingHubFilterAll => 'All';

  @override
  String get teacherGradingHubFilterInProgress => 'In progress';

  @override
  String get teacherGradingHubFilterSubmitted => 'Submitted';

  @override
  String get teacherGradingHubFilterPendingManual => 'Needs grading';

  @override
  String get teacherGradingHubFilterFinalized => 'Graded';

  @override
  String get teacherGradingHubFilterReleased => 'Released';

  @override
  String get teacherGradingHubFilterPartial => 'Partial submit';

  @override
  String get teacherGradingHubPartialBadge => 'Partial';

  @override
  String get teacherGradingHubForceEndBadge => 'Session ended';

  @override
  String get teacherGradingHubBatchAi => 'AI grade all submitted';

  @override
  String get teacherGradingHubBatchAiDone =>
      'AI grading finished for submitted attempts';

  @override
  String get teacherGradingHubNotReleased => 'Not released';

  @override
  String teacherGradingHubScoreLine(String awarded, String max) {
    return 'Score: $awarded / $max';
  }

  @override
  String teacherGradingHubSubmittedAt(String date) {
    return 'Submitted $date';
  }

  @override
  String teacherGradingHubStatsLine(
      int submitted, int inProgress, int partial) {
    return '$submitted submitted · $inProgress in progress · $partial partial';
  }

  @override
  String get teacherGradingHubEmpty => 'No attempts for this assignment yet.';

  @override
  String get teacherGradingHubOpenGrade => 'Grade';

  @override
  String get teacherGradingHubBatchRelease => 'Release all graded';

  @override
  String get teacherGradingHubBatchReleaseDone =>
      'Results released for submitted attempts';

  @override
  String get teacherGradingHubBatchFinalize => 'Finalize all submitted';

  @override
  String get teacherGradingHubBatchFinalizeDone =>
      'Submitted attempts finalized';

  @override
  String get teacherGradingHubExportExcel => 'Export scores to Excel';

  @override
  String get teacherGradingHubExportDone => 'Excel file downloaded';

  @override
  String get teacherGradingHubExportEmpty => 'No student attempts to export';

  @override
  String teacherGradingHubExportMobileHint(String filename) {
    return 'Excel export on mobile: open teacher web app or use file: $filename';
  }

  @override
  String get teacherGradingHubExportMobileCopied =>
      'Export is available on web; hint copied';

  @override
  String get teacherExamDuplicate => 'Duplicate';

  @override
  String get teacherExamDuplicated => 'Exam duplicated as draft';

  @override
  String get teacherAssignmentDuplicate => 'Duplicate assignment';

  @override
  String get teacherAssignmentDuplicated => 'Assignment duplicated';

  @override
  String get teacherAssignmentExtendDeadline => 'Extend deadline';

  @override
  String get teacherAssignmentDeadlineSaved => 'Deadline updated';

  @override
  String get teacherMemberApprove => 'Approve';

  @override
  String get teacherMemberReject => 'Reject';

  @override
  String get teacherMemberApproved => 'Student approved';

  @override
  String get teacherMemberRejected => 'Request declined';

  @override
  String get teacherGradebookTitle => 'Gradebook';

  @override
  String get teacherGradebookStudent => 'Student';

  @override
  String get teacherGradebookExport => 'Export CSV';

  @override
  String get teacherGradebookExportCopied =>
      'Gradebook copied to clipboard (paste into Excel)';

  @override
  String get teacherGradebookExportDownloaded => 'Gradebook CSV downloaded';

  @override
  String get teacherGradebookNoAssignments =>
      'No assignments in this class yet.';

  @override
  String get teacherGradebookKpiStudents => 'Students';

  @override
  String get teacherGradebookKpiAssignments => 'Assignments';

  @override
  String get teacherGradebookKpiClassAvg => 'Class average';

  @override
  String get teacherGradebookKpiPending => 'Cells to grade';

  @override
  String get teacherGradebookSearchHint => 'Search student name or email';

  @override
  String get teacherGradebookFilterMode => 'Assignment mode';

  @override
  String get teacherGradebookFilterAllModes => 'All modes';

  @override
  String get teacherGradebookSortLabel => 'Sort';

  @override
  String get teacherGradebookSortName => 'Name A→Z';

  @override
  String get teacherGradebookSortAvg => 'Avg score';

  @override
  String get teacherGradebookHideEmpty => 'Hide students with no submissions';

  @override
  String teacherGradebookShowingCount(int count) {
    return 'Showing $count students';
  }

  @override
  String get teacherGradebookNoStudentsMatch =>
      'No students match your filters.';

  @override
  String get teacherGradebookNoColumnsForFilter =>
      'No assignments for this mode in this class.';

  @override
  String get teacherGradebookColAvg => 'Avg';

  @override
  String get teacherGradebookClassAverage => 'Class average';

  @override
  String get teacherGradebookCellNotStarted => 'Not started';

  @override
  String get teacherGradebookCellPendingGrading => 'Needs grading';

  @override
  String get teacherGradebookTapHint =>
      'Tap a score to open grading; tap an empty cell to open the assignment hub.';

  @override
  String get teacherNavCalendar => 'Schedule';

  @override
  String get teacherCalendarEmpty => 'No scheduled events in this range.';

  @override
  String get teacherCalendarKindDue => 'Due';

  @override
  String get teacherCalendarKindOpens => 'Opens';

  @override
  String get teacherCalendarKindCloses => 'Closes';

  @override
  String get teacherCalendarKindLive => 'Live now';

  @override
  String get teacherCalendarViewMonth => 'Month';

  @override
  String get teacherCalendarViewList => 'List';

  @override
  String get teacherCalendarToday => 'Today';

  @override
  String get teacherCalendarNoDayEvents => 'No events on this day.';

  @override
  String get teacherCalendarGoToAssignment => 'View assignment';

  @override
  String get teacherDashboardActionItems => 'Needs attention';

  @override
  String get teacherDashboardPendingJoins => 'Pending join requests';

  @override
  String get teacherDashboardDueSoon => 'Due soon';

  @override
  String teacherDashboardNeedsGrading(int count) {
    return '$count attempts need grading';
  }

  @override
  String get teacherAssignmentPresetLabel => 'Preset';

  @override
  String get teacherAssignmentPresetSave => 'Save as preset';

  @override
  String get teacherAssignmentPresetSaved => 'Preset saved';

  @override
  String get teacherAssignmentPresetNone => 'No presets yet';

  @override
  String get examModePractice => 'Practice (no grade)';

  @override
  String get teacherAnalyticsTitle => 'Analytics';

  @override
  String get teacherAnalyticsSubmissionsChart => 'Submissions per day';

  @override
  String get teacherAnalyticsScoreChart => 'Score distribution';

  @override
  String get teacherAnalyticsIntegrityChart => 'Integrity flags';

  @override
  String get teacherAnalyticsIntegrityHigh => 'High risk';

  @override
  String get teacherAnalyticsIntegrityMedium => 'Medium';

  @override
  String get teacherAnalyticsIntegrityLow => 'Low';

  @override
  String get teacherAnalyticsNoData => 'Not enough data yet';

  @override
  String get teacherAnalyticsPeriod7d => '7 d';

  @override
  String get teacherAnalyticsPeriod14d => '14 d';

  @override
  String get teacherAnalyticsPeriod30d => '30 d';

  @override
  String get teacherAnalyticsActiveStudents => 'Active students';

  @override
  String get teacherAnalyticsActiveAssignments => 'Active assignments';

  @override
  String get teacherAnalyticsSubmissions => 'Submissions';

  @override
  String get teacherAnalyticsPendingGrading => 'Pending grading';

  @override
  String get teacherAnalyticsAvgScore => 'Avg score';

  @override
  String get teacherAnalyticsSkillBreakdown => 'Per-skill averages';

  @override
  String get teacherAnalyticsSkillListening => 'Listening';

  @override
  String get teacherAnalyticsSkillReading => 'Reading';

  @override
  String get teacherAnalyticsSkillWriting => 'Writing';

  @override
  String get teacherAnalyticsSkillSpeaking => 'Speaking';

  @override
  String get teacherAnalyticsSkillGrammar => 'Grammar';

  @override
  String teacherAnalyticsWeakSkillHint(String skill, String score) {
    return '$skill avg $score/10 — consider scheduling extra practice.';
  }

  @override
  String get teacherAnalyticsModeBreakdown => 'Assignment modes';

  @override
  String get teacherAnalyticsModeHomework => 'Homework';

  @override
  String get teacherAnalyticsModeLive => 'Live';

  @override
  String get teacherAnalyticsModeSelfPaced => 'Self-paced';

  @override
  String get teacherNavAnalytics => 'Analytics';

  @override
  String get teacherClassTabActivity => 'Activity';

  @override
  String get teacherClassActivityEmpty => 'No activity recorded yet.';

  @override
  String get teacherCoTeacherAdd => 'Add co-teacher';

  @override
  String get teacherCoTeacherEmailHint => 'Teacher email';

  @override
  String get teacherCoTeacherAdded => 'Co-teacher added';

  @override
  String get teacherCoTeacherRemoved => 'Co-teacher removed';

  @override
  String get teacherIntegrationsTitle => 'Integrations';

  @override
  String get teacherGoogleClassroomLink => 'Link Google Classroom course';

  @override
  String get teacherGoogleClassroomUnlink => 'Unlink Google Classroom';

  @override
  String get teacherGoogleClassroomCourseId => 'Google course ID';

  @override
  String get teacherRubricTitle => 'Rubric scoring';

  @override
  String get teacherRubricCriterion => 'Criterion';

  @override
  String get teacherAdaptiveEnabled => 'Adaptive difficulty';

  @override
  String get teacherGradingLiveProgress => 'Live progress';

  @override
  String get teacherClassViewStudentAttempts => 'Student work';

  @override
  String get teacherClassTapToViewAttempts =>
      'Tap to view all student submissions';

  @override
  String get teacherClassOpenAttemptsList => 'View submissions';

  @override
  String get teacherGradingStudentAttemptsTitle => 'Student submissions';

  @override
  String get teacherGradingStatusInProgress => 'In progress';

  @override
  String get teacherGradingStatusSubmitted => 'Submitted';

  @override
  String get teacherGradingStatePendingAuto => 'Auto grading';

  @override
  String get teacherGradingStatePendingAi => 'AI review';

  @override
  String get teacherGradingStatePendingManual => 'Needs manual grading';

  @override
  String get teacherGradingStateFinalized => 'Graded';

  @override
  String teacherGradingStartedAt(String date) {
    return 'Started $date';
  }

  @override
  String get teacherGradingFinalize => 'Finalize grading';

  @override
  String get teacherGradingFinalized => 'Grading finalized';

  @override
  String get teacherGradingCompletenessComplete => 'Full submission';

  @override
  String get teacherGradingCompletenessPartial => 'Partial submission';

  @override
  String get teacherGradingCompletenessForceEnd =>
      'Ended by teacher (live session)';

  @override
  String get teacherGradingAiRationale => 'AI feedback';

  @override
  String get teacherGradingIntegratedScores => 'Section scores';

  @override
  String get teacherGradingDetailTitle => 'Grade attempt';

  @override
  String get teacherGradingSaveScores => 'Save scores';

  @override
  String get teacherGradingSaved => 'Scores saved';

  @override
  String get teacherGradingNotesHint => 'Feedback note';

  @override
  String get teacherGradingAwardedPoints => 'Awarded points';

  @override
  String get teacherGradingOnlySubmitted =>
      'Scores can be adjusted after the student submits.';

  @override
  String get teacherAttemptGradeHeaderSubtitle =>
      'Review responses, adjust scores, and release results when ready.';

  @override
  String get teacherAttemptGradeExamLabel => 'Exam';

  @override
  String teacherAttemptGradeStartedLine(String date) {
    return 'Started $date';
  }

  @override
  String teacherAttemptGradeSubmittedLine(String date) {
    return 'Submitted $date';
  }

  @override
  String get teacherAttemptGradeReleasedYes => 'Published to student';

  @override
  String get teacherAttemptGradeReleasedNo => 'Not published yet';

  @override
  String get teacherAttemptGradeTotalScore => 'Skill scores';

  @override
  String integratedSkillScoreLabel(String score) {
    return '$score / 10';
  }

  @override
  String get integratedSkillScorePending => 'Pending';

  @override
  String get integratedSkillFinalAvg => 'Average';

  @override
  String get integratedSkillFinalPartial => 'Partial avg.';

  @override
  String get integratedSkillGrammar => 'Grammar';

  @override
  String get integratedSkillListening => 'Listening';

  @override
  String get integratedSkillReading => 'Reading';

  @override
  String get integratedSkillWriting => 'Writing';

  @override
  String get integratedSkillSpeaking => 'Speaking';

  @override
  String get integratedSkillEnterScore => 'Enter score (0–10)';

  @override
  String get integratedSkillScoreSaved => 'Score saved';

  @override
  String get integratedSkillSaveScore => 'Save score';

  @override
  String get integratedScoresAwaiting =>
      'Scores are being calculated. Refresh in a moment if this persists.';

  @override
  String get integratedGradingAvgFormulaHint =>
      'Final score = arithmetic mean of all skill scores (0–10 each). Pending skills are excluded until graded.';

  @override
  String get integratedGradingColumnSkill => 'Skill';

  @override
  String get integratedGradingColumnScore => 'Score';

  @override
  String get integratedWritingGradingEssayLabel => 'Student essay';

  @override
  String integratedWritingGradingWordCount(String count) {
    return '$count words';
  }

  @override
  String get integratedWritingGradingNoDraft =>
      'No essay text saved for this attempt.';

  @override
  String get integratedWritingGradingRunAi => 'Grade with AI';

  @override
  String get integratedWritingGradingApplyAi => 'Apply AI score';

  @override
  String get integratedWritingGradingManual => 'Manual score';

  @override
  String integratedWritingGradingAiBand(String band) {
    return 'AI band: $band / 9';
  }

  @override
  String integratedWritingGradingAiExamScore(String score) {
    return 'Suggested exam score: $score / 10';
  }

  @override
  String integratedGrammarItemResult(String awarded, String max) {
    return '$awarded / $max correct';
  }

  @override
  String get teacherAttemptGradeSectionBreakdown => 'Questions & scoring';

  @override
  String teacherAttemptGradeItemKind(String kind) {
    return 'Type: $kind';
  }

  @override
  String teacherAttemptGradeMaxPts(int n) {
    return 'Max $n pts';
  }

  @override
  String get teacherAttemptGradeStudentFallback => 'Student';

  @override
  String teacherAttemptGradePointsShort(Object awarded, Object max) {
    return '$awarded / $max pts';
  }

  @override
  String get teacherAttemptGradeAnswerLabel => 'Student answer';

  @override
  String get teacherAttemptGradeWorkAndScores => 'Submission review & scoring';

  @override
  String get teacherAttemptGradeCorrectAnswer => 'Correct answer';

  @override
  String get teacherAttemptGradeSkillLinkedWork => 'Linked exercises';

  @override
  String get teacherAttemptGradeSkillCmsHint =>
      'The student practiced this in the in-app lesson and marked it done here. Detailed attempts stay in the skill activity history, not in this exam payload.';

  @override
  String teacherAttemptGradeQuestionN(int n) {
    return 'Question $n';
  }

  @override
  String get teacherAttemptGradeMarkedComplete => 'Marked complete';

  @override
  String get teacherAttemptGradeNotMarkedComplete => 'Not marked complete';

  @override
  String get teacherAttemptGradeInstructions => 'Instructions';

  @override
  String get teacherAttemptGradeChoicesLabel => 'Answer choices';

  @override
  String get teacherAttemptGradeNoSkillWork =>
      'No work recorded during this exam session.';

  @override
  String get teacherAttemptGradeOnlyMarkedComplete =>
      'The student marked this part complete, but no saved answers were found for the linked exercise.';

  @override
  String get teacherAttemptGradeSkillWorkExamInline =>
      'Answers saved inside this exam attempt (integrated exam).';

  @override
  String get teacherAttemptGradeSkillWorkNearSession =>
      'Showing work from near this exam session (timestamps may fall slightly outside the exact window).';

  @override
  String get teacherAttemptGradeSkillWorkLatestLinked =>
      'Showing the student\'s most recent work on this linked exercise.';

  @override
  String teacherAttemptGradeWordCount(int count) {
    return '$count words';
  }

  @override
  String get teacherAttemptGradeViewSkillWork => 'View student submission';

  @override
  String get teacherAttemptGradeHideSkillWork => 'Hide submission';

  @override
  String get teacherAttemptGradeListeningCue => 'Cue';

  @override
  String teacherAttemptGradeDictationScore(Object correct, Object total) {
    return 'Words correct: $correct / $total';
  }

  @override
  String teacherAttemptGradeSpeakingLine(String id) {
    return 'Sentence $id';
  }

  @override
  String teacherAttemptGradeWritingScore(String score) {
    return 'Score: $score';
  }

  @override
  String get teacherAttemptGradeSkillOther => 'Section';

  @override
  String get teacherExamTimeRemaining => 'Time left';

  @override
  String get teacherExamMcqNeedsStem => 'Each MCQ needs question text.';

  @override
  String get teacherExamEssayNeedsPrompt => 'Each essay needs a prompt.';

  @override
  String get teacherExamIntegratedUntitled => 'Four-skill practice set';

  @override
  String get teacherExamIntegratedNew => 'Four-skill exam';

  @override
  String get teacherExamIntegratedBadge => '4 skills';

  @override
  String get teacherExamIntegratedEditorTitle => 'Four-skill exam';

  @override
  String get teacherExamIntegratedPartsTitle =>
      'Parts (Reading → Listening → Writing → Speaking)';

  @override
  String get teacherExamIntegratedPartsHint =>
      'Pick one published exercise per skill. Students open each activity in the app, then mark it done before submitting.';

  @override
  String get teacherExamIntegratedTapToPick => 'Tap to choose content';

  @override
  String get teacherExamIntegratedPickAll =>
      'Choose all four exercises before publishing.';

  @override
  String get teacherExamIntegratedSkillListening => 'Listening (dictation)';

  @override
  String get teacherExamIntegratedSkillSpeaking => 'Speaking (read aloud)';

  @override
  String get teacherExamIntegratedSkillReading => 'Reading';

  @override
  String get teacherExamIntegratedSkillWriting => 'Writing';

  @override
  String get teacherExamIntegratedChooseExercise => 'Choose exercise';

  @override
  String get teacherExamIntegratedEmptyList => 'No items found.';

  @override
  String get teacherExamSkillsEditorTitle => 'Skills exam';

  @override
  String get teacherExamSkillsPartsTitle =>
      'Skills (choose what this test includes)';

  @override
  String get teacherExamSkillsPartsHint =>
      'Turn off a skill if this test should not cover it. For each included skill, add one or more exercises from the library.';

  @override
  String get teacherExamSkillsIncludeSubtitle => 'Include this skill';

  @override
  String get teacherExamGrammarTitle => 'Grammar';

  @override
  String get teacherExamGrammarIncludeSubtitle => 'Include Grammar section';

  @override
  String teacherExamGrammarQuestionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '1 question',
    );
    return '$_temp0';
  }

  @override
  String get teacherExamGrammarEnabledNoItems =>
      'Grammar is on but has no questions. Add at least one question or turn Grammar off.';

  @override
  String get teacherExamGrammarHint =>
      'Optional. Add cloze, gap fill, matching, sentence order, or multiple choice. All are auto-scored. If the exam includes skills, total Grammar points cannot exceed 100.';

  @override
  String get teacherExamWritingPublishNeedPrompt =>
      'Writing is on: set a writing prompt (AI or manual). A library topic alone is not enough.';

  @override
  String get teacherExamWritingAiPickTaskTypeTitle =>
      'Task type for AI prompts';

  @override
  String get teacherExamWritingAiPickTaskTypeHint =>
      'Optional. Leave as “Any” to get up to 3 different task types.';

  @override
  String get teacherExamWritingAiTaskTypeAny => 'Any (mixed types)';

  @override
  String get teacherExamWritingAiNeedTopicOrTitle =>
      'Select a writing topic, or enter an exam title above, before generating AI prompts.';

  @override
  String get teacherExamGrammarAdd => 'Add question';

  @override
  String get teacherExamGrammarEdit => 'Grammar question';

  @override
  String get teacherExamPublishNeedSelection =>
      'Include at least one skill with an exercise, or add at least one Grammar question.';

  @override
  String get teacherExamPublishPickEachIncludedSkill =>
      'Add at least one exercise for every skill that is turned on.';

  @override
  String get teacherExamSpeakingExerciseRequired =>
      'Speaking is on but no exercise is linked. Tap \"Add exercise\" and pick a Speaking set.';

  @override
  String get teacherExamWritingPromptSectionTitle => 'Writing Prompt';

  @override
  String get teacherExamWritingPromptEmptyHint =>
      'All students will receive the same writing prompt. Choose one AI-generated option or write your own.';

  @override
  String get teacherExamWritingGenerateWithAI => 'Generate with AI';

  @override
  String get teacherExamWritingWriteManually => 'Write manually';

  @override
  String get teacherExamWritingPromptNeedTopic =>
      'Select a writing topic first to generate AI prompts.';

  @override
  String get teacherExamWritingPickPromptTitle => 'Choose a writing prompt';

  @override
  String get teacherExamWritingPickPromptSubtitle =>
      'Select one of the AI-generated prompts below. All students will receive this same prompt.';

  @override
  String get teacherExamWritingSelectThisPrompt => 'Select';

  @override
  String get teacherExamWritingManualPromptTitle => 'Write your own prompt';

  @override
  String get teacherExamWritingPromptTitleLabel => 'Prompt title';

  @override
  String get teacherExamWritingPromptTitleHint =>
      'e.g. Technology in Education';

  @override
  String get teacherExamWritingPromptTaskTypeLabel => 'Task type';

  @override
  String get teacherExamWritingPromptTextLabel => 'Writing prompt';

  @override
  String get teacherExamWritingPromptTextHint =>
      'Write the full exam question here. Include context and specific instructions for students...';

  @override
  String get teacherExamWritingPromptTextRequired =>
      'Enter the writing prompt text before saving.';

  @override
  String get teacherExamWritingPromptRequired =>
      'Please set a writing prompt before publishing.';

  @override
  String get teacherExamWritingPromptNotSet =>
      'No writing prompt set. Students will not be able to complete this section.';

  @override
  String get teacherExamWritingCustomPrompt => 'Custom prompt';

  @override
  String get teacherExamGrammarPointsCap100 =>
      'Total Grammar points cannot exceed 100 while skills are included.';

  @override
  String get teacherExamSkillsBadge => 'Skills exam';

  @override
  String get integratedExamGrammarSectionTitle => 'Grammar';

  @override
  String get integratedExamSubmitBlockedAll =>
      'Finish every skill part and every Grammar question before submitting.';

  @override
  String get teacherExamSkillsWebSubtitle =>
      'Lay out like an exam paper: Grammar first, then Reading, Listening, Writing, and Speaking. Add one or more library exercises per skill you include.';

  @override
  String get teacherExamSkillsBrowseContent => 'Browse library';

  @override
  String get teacherExamSkillsNoGrammarYet =>
      'No Grammar questions yet. Use Add question to open the editor.';

  @override
  String get teacherExamSkillsAddExercise => 'Add exercise';

  @override
  String get teacherExamSkillsCreateNew => 'Create new exercise';

  @override
  String get teacherExamSkillsExercisesSelected => 'exercise(s) selected';

  @override
  String get teacherExamSkillsAllAdded =>
      'All available exercises are already added.';

  @override
  String get teacherExamCreateMenuLabel => 'New exam';

  @override
  String get teacherExamIntegratedCreateClassicHint =>
      'MCQ & essay in one editor';

  @override
  String get teacherExamIntegratedCreateFourHint =>
      'Four parts linked to existing lessons';

  @override
  String get integratedExamRunnerTitle => 'Practice set';

  @override
  String get integratedExamMetaClass => 'Class';

  @override
  String get integratedExamMetaSubject => 'Subject';

  @override
  String get integratedExamMetaTeacher => 'Teacher';

  @override
  String get integratedExamMetaStudent => 'Student';

  @override
  String get integratedExamMetaDelivery => 'How you take this';

  @override
  String get integratedExamMetaModeHomework => 'Take-home assignment';

  @override
  String get integratedExamMetaModeScheduled => 'Scheduled exam';

  @override
  String get integratedExamMetaModeLive => 'Live session';

  @override
  String get integratedExamMetaPublic => 'Open link';

  @override
  String get integratedExamMetaTimeLimit => 'Time limit';

  @override
  String integratedExamMetaTimeLimitMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get integratedExamMetaNoTimeLimit => 'No fixed time limit';

  @override
  String get integratedExamMetaDeadline => 'Closes in';

  @override
  String get integratedExamMetaDue => 'Submit by';

  @override
  String get integratedExamMetaWindow => 'Open until';

  @override
  String get integratedExamMetaOpens => 'Opens at';

  @override
  String get integratedExamMetaStarted => 'Started at';

  @override
  String get integratedExamSubjectDefault => 'English';

  @override
  String get integratedExamNoClassName => '—';

  @override
  String get integratedExamGrammarNavHint =>
      'Bold border = in progress; green = answered.';

  @override
  String integratedExamGrammarQuestionLabel(int n, int total) {
    return 'Question $n of $total';
  }

  @override
  String get integratedExamTimeUpShort => 'Time up';

  @override
  String get integratedExamGrammarPrevious => 'Previous grammar question';

  @override
  String get integratedExamGrammarNext => 'Next grammar question';

  @override
  String get integratedExamOpenExercise => 'Open';

  @override
  String get integratedExamMarkDone => 'Mark done';

  @override
  String get integratedExamUndoPart => 'Undo';

  @override
  String get integratedExamSubmit => 'Submit all parts';

  @override
  String get integratedExamSubmitShort => 'Submit';

  @override
  String get integratedExamSubmitBlocked =>
      'Mark every part as done before submitting.';

  @override
  String integratedExamProgress(int done, int total) {
    return '$done of $total parts ready';
  }

  @override
  String integratedExamScoreSummary(Object earned) {
    return 'Avg. score: $earned / 10';
  }

  @override
  String get integratedExamSkillsSectionTitle => 'Skills';

  @override
  String get integratedExamDetailsTitle => 'Exam details';

  @override
  String get integratedExamSelectPartHint =>
      'Choose a part below. Work on one section at a time.';

  @override
  String get integratedExamPartDone => 'Done';

  @override
  String get integratedExamPartNotStarted => 'Not started';

  @override
  String get integratedExamEmbeddedHint =>
      'Complete the exercise below. Only the exam timer applies.';

  @override
  String get integratedExamEmbeddedLocked =>
      'This part is locked after you submitted the exam.';

  @override
  String get integratedExamEmbeddedNoResource =>
      'No exercise linked for this part.';

  @override
  String get integratedExamEmbeddedNoSpeakingResource =>
      'No speaking exercise linked. Ask your teacher to add a Speaking set in the exam editor, then start a new session.';

  @override
  String get integratedExamGrammarUnsupported =>
      'This question type is not supported in the app yet.';

  @override
  String get integratedExamMatchPick => 'Match';

  @override
  String get integratedExamMatchHint =>
      'Tap an item on the left, then tap on the right to connect — or long-press and drag to the matching answer. Lines show your pairs.';

  @override
  String get integratedExamMatchHintCompact =>
      'Tap a phrase on the left, then tap an answer chip below — or drag a chip into the dashed slot. Each pair has its own color.';

  @override
  String get integratedExamMatchAnswersPool => 'Answers';

  @override
  String get integratedExamMatchTapAnswer => 'Tap an answer below';

  @override
  String get integratedExamMatchDropHere => 'Drop answer here';

  @override
  String get integratedExamReorderHint =>
      'Drag the lines into the correct order.';

  @override
  String get teacherExamGrammarKindMcqSingle => 'Multiple choice (one answer)';

  @override
  String get teacherExamGrammarKindMcqMulti =>
      'Multiple choice (several answers)';

  @override
  String get teacherExamGrammarKindCloze => 'Cloze — fill blanks in a passage';

  @override
  String get teacherExamGrammarKindGap => 'Gap — one missing word';

  @override
  String get teacherExamGrammarKindMatching => 'Match pairs';

  @override
  String get teacherExamGrammarKindReorder => 'Put fragments in order';

  @override
  String get teacherExamGrammarQuestionType => 'Question type';

  @override
  String get teacherExamGrammarPassageLabel =>
      'Passage (mark blanks with double curly braces around numbers, e.g. 0 and 1)';

  @override
  String get teacherExamGrammarTextBefore => 'Text before gap';

  @override
  String get teacherExamGrammarTextAfter => 'Text after gap';

  @override
  String get teacherExamGrammarAcceptedAnswers =>
      'Accepted answers (comma-separated)';

  @override
  String get teacherExamGrammarBlankId => 'Blank id';

  @override
  String get teacherExamGrammarLeftColumn => 'Left column';

  @override
  String get teacherExamGrammarRightColumn => 'Right column';

  @override
  String teacherExamGrammarPairCorrect(int row) {
    return 'Correct match for row $row';
  }

  @override
  String get teacherExamGrammarFragments =>
      'Sentence fragments (one per line in correct reading order)';

  @override
  String get teacherExamGrammarReorderInstruction =>
      'Drag the chips below to set the correct sentence order students should produce.';

  @override
  String get teacherExamGrammarSaveItem => 'Save question';

  @override
  String get teacherExamGrammarNewItem => 'New question';

  @override
  String get teacherExamGrammarPanelTitle => 'Grammar editor';

  @override
  String get teacherExamGrammarCloseEditor => 'Close';

  @override
  String get teacherExamGrammarImport => 'Import questions';

  @override
  String teacherExamGrammarImportSuccess(int count) {
    return 'Imported $count question(s) successfully.';
  }

  @override
  String get teacherExamGrammarImportError =>
      'Failed to parse file. Check the format and try again.';

  @override
  String get teacherExamGrammarImportEmpty =>
      'No valid questions found in the file.';

  @override
  String get teacherExamGrammarImportFormatTitle => 'Import format (JSON)';

  @override
  String get teacherExamGrammarImportFormatHint =>
      'Create a .json file containing an array of question objects. Each object must have a \"kind\" field. Supported kinds:';

  @override
  String get teacherExamGrammarDownloadSample => 'Copy sample to clipboard';

  @override
  String get teacherExamGrammarImportPickFile => 'Pick .json file';

  @override
  String get teacherExamGrammarAddOption => 'Add option';

  @override
  String get teacherExamGrammarCorrectOptions => 'Correct options';

  @override
  String get studentExamExpired => 'Time is up';

  @override
  String get teacherAssignmentEditTitle => 'Edit Assignment';

  @override
  String get teacherAssignmentEditSubtitle =>
      'Adjust schedule, time limits and rules';

  @override
  String get teacherAssignmentEditSaved => 'Assignment updated';

  @override
  String get teacherAssignmentEditScheduleSection => 'Schedule';

  @override
  String get teacherAssignmentEditRulesSection => 'Attempts & Results';

  @override
  String get teacherAssignmentEditTooltip => 'Edit assignment';

  @override
  String get teacherAssignmentModeFixed =>
      'Mode is set and cannot be changed after creation.';

  @override
  String get teacherAssignmentRealtimeLobbyOpens => 'Lobby opens at';

  @override
  String get teacherAssignmentRealtimeScheduledStart => 'Scheduled start';

  @override
  String get teacherAssignmentRealtimeHardEnd => 'Hard end';

  @override
  String get teacherAssignmentEditPracticeNote =>
      'Practice mode has no schedule — students can access this assignment at any time.';
}
