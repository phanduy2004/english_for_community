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
  String get labelPassword => 'Password';

  @override
  String get hintEmail => 'name@example.com';

  @override
  String get hintPassword => 'Enter password...';

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
}
