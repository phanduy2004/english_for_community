import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @profileAndSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile & Settings'**
  String get profileAndSettings;

  /// No description provided for @learningPreferences.
  ///
  /// In en, this message translates to:
  /// **'LEARNING PREFERENCES'**
  String get learningPreferences;

  /// No description provided for @dailyTimeGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Time Goal'**
  String get dailyTimeGoal;

  /// No description provided for @dailyLessonGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Lesson Goal'**
  String get dailyLessonGoal;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get dailyReminder;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{mins} mins'**
  String minutesShort(int mins);

  /// No description provided for @lessonsShort.
  ///
  /// In en, this message translates to:
  /// **'{n} lessons'**
  String lessonsShort(int n);

  /// No description provided for @setDailyTimeGoal.
  ///
  /// In en, this message translates to:
  /// **'Set Daily Time Goal'**
  String get setDailyTimeGoal;

  /// No description provided for @minutesPerDayOption.
  ///
  /// In en, this message translates to:
  /// **'{mins} minutes / day'**
  String minutesPerDayOption(int mins);

  /// No description provided for @setDailyLessonGoal.
  ///
  /// In en, this message translates to:
  /// **'Set Daily Lesson Goal'**
  String get setDailyLessonGoal;

  /// No description provided for @lessonsPerDayOption.
  ///
  /// In en, this message translates to:
  /// **'{n} lessons / day'**
  String lessonsPerDayOption(int n);

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'PROGRESS'**
  String get progress;

  /// No description provided for @exerciseHistory.
  ///
  /// In en, this message translates to:
  /// **'Exercise history'**
  String get exerciseHistory;

  /// No description provided for @exerciseHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Past attempts by skill'**
  String get exerciseHistorySubtitle;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'GENERAL SETTINGS'**
  String get generalSettings;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @timezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get timezone;

  /// No description provided for @accountAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT & SECURITY'**
  String get accountAndSecurity;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @exportDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download learning history'**
  String get exportDataSubtitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All data will be deleted.'**
  String get deleteAccountBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deletePermanently;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @selectAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose app language'**
  String get selectAppLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get languageVietnamese;

  /// No description provided for @appLanguageFootnote.
  ///
  /// In en, this message translates to:
  /// **'Interface language (saved on this device)'**
  String get appLanguageFootnote;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get navProgress;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get loginWelcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your details to continue.'**
  String get loginSubtitle;

  /// No description provided for @labelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get labelEmail;

  /// No description provided for @labelPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get labelPassword;

  /// No description provided for @hintEmail.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get hintEmail;

  /// No description provided for @hintPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password...'**
  String get hintPassword;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLink;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orDivider;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @noAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get noAccountPrompt;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @dictionary.
  ///
  /// In en, this message translates to:
  /// **'Dictionary'**
  String get dictionary;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @missingInfo.
  ///
  /// In en, this message translates to:
  /// **'Missing Info'**
  String get missingInfo;

  /// No description provided for @enterEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter email and password.'**
  String get enterEmailPassword;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login Failed'**
  String get loginFailed;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// No description provided for @fillRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields (*).'**
  String get fillRequiredFields;

  /// No description provided for @passwordErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Error'**
  String get passwordErrorTitle;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Confirmation password does not match.'**
  String get passwordMismatch;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @otpVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get otpVerifyTitle;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @practiceFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practiceFallbackTitle;

  /// No description provided for @barrierDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get barrierDismiss;

  /// No description provided for @weeklyActivity.
  ///
  /// In en, this message translates to:
  /// **'Weekly activity'**
  String get weeklyActivity;

  /// No description provided for @sameChartBadge.
  ///
  /// In en, this message translates to:
  /// **'same chart as Progress'**
  String get sameChartBadge;

  /// No description provided for @couldNotLoadStudyChart.
  ///
  /// In en, this message translates to:
  /// **'Could not load study chart'**
  String get couldNotLoadStudyChart;

  /// No description provided for @weeklySummaryLine.
  ///
  /// In en, this message translates to:
  /// **'{minutes} this week · {done} / {goal} lessons today'**
  String weeklySummaryLine(String minutes, int done, int goal);

  /// No description provided for @viewProgress.
  ///
  /// In en, this message translates to:
  /// **'View progress'**
  String get viewProgress;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'Personalized Learning Path'**
  String get onboardingSlide1Title;

  /// No description provided for @onboardingSlide1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'A plan tailored to your goals, CEFR level, and schedule.'**
  String get onboardingSlide1Subtitle;

  /// No description provided for @onboardingSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'AI Tutor for Speaking & Writing'**
  String get onboardingSlide2Title;

  /// No description provided for @onboardingSlide2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Realtime pronunciation feedback & rubric-based review.'**
  String get onboardingSlide2Subtitle;

  /// No description provided for @onboardingSlide3Title.
  ///
  /// In en, this message translates to:
  /// **'Stay Motivated with Rewards'**
  String get onboardingSlide3Title;

  /// No description provided for @onboardingSlide3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Streaks, XP, and badges keep you engaged daily.'**
  String get onboardingSlide3Subtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @signInAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInAction;

  /// No description provided for @readingPracticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading Practice'**
  String get readingPracticeTitle;

  /// No description provided for @speakingModeReadAloud.
  ///
  /// In en, this message translates to:
  /// **'Read Aloud'**
  String get speakingModeReadAloud;

  /// No description provided for @speakingModeShadowing.
  ///
  /// In en, this message translates to:
  /// **'Shadowing'**
  String get speakingModeShadowing;

  /// No description provided for @speakingModePronunciation.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation'**
  String get speakingModePronunciation;

  /// No description provided for @speakingModeFreeSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Free Speaking'**
  String get speakingModeFreeSpeaking;

  /// No description provided for @difficultyBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get difficultyBeginner;

  /// No description provided for @difficultyIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get difficultyIntermediate;

  /// No description provided for @difficultyAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get difficultyAdvanced;

  /// No description provided for @sentenceIndex.
  ///
  /// In en, this message translates to:
  /// **'Sentence {current} / {total}'**
  String sentenceIndex(int current, int total);

  /// No description provided for @finishPractice.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishPractice;

  /// No description provided for @nextSentence.
  ///
  /// In en, this message translates to:
  /// **'Next sentence'**
  String get nextSentence;

  /// No description provided for @microNotReady.
  ///
  /// In en, this message translates to:
  /// **'Microphone / speech recognition is not ready. Grant permission and try again.'**
  String get microNotReady;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @microInfoBanner.
  ///
  /// In en, this message translates to:
  /// **'Micro / speech recognition is not ready. Grant permission and try again.'**
  String get microInfoBanner;

  /// No description provided for @sampleListen.
  ///
  /// In en, this message translates to:
  /// **'Sample'**
  String get sampleListen;

  /// No description provided for @sampleListenSub.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get sampleListenSub;

  /// No description provided for @yourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get yourTurn;

  /// No description provided for @yourTurnSub.
  ///
  /// In en, this message translates to:
  /// **'Your speech'**
  String get yourTurnSub;

  /// No description provided for @listeningForSpeech.
  ///
  /// In en, this message translates to:
  /// **'Listening… Tap the red button to stop and score.'**
  String get listeningForSpeech;

  /// No description provided for @submittingAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Sending and analyzing…'**
  String get submittingAnalysis;

  /// No description provided for @tapMicToRecord.
  ///
  /// In en, this message translates to:
  /// **'Tap the mic, read the sentence aloud, then tap again to stop.'**
  String get tapMicToRecord;

  /// No description provided for @yourSpeechSection.
  ///
  /// In en, this message translates to:
  /// **'YOUR SPEECH'**
  String get yourSpeechSection;

  /// No description provided for @transcriptPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Will appear here when you speak…'**
  String get transcriptPlaceholder;

  /// No description provided for @accuracyLabel.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracyLabel;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get levelLabel;

  /// No description provided for @speakingPracticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Speaking practice'**
  String get speakingPracticeTitle;

  /// No description provided for @socketSessionEnded.
  ///
  /// In en, this message translates to:
  /// **'Session ended. Please sign in again.'**
  String get socketSessionEnded;

  /// No description provided for @socketKicked.
  ///
  /// In en, this message translates to:
  /// **'You were signed out from another device.'**
  String get socketKicked;

  /// No description provided for @adminRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get adminRetry;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin dashboard'**
  String get adminDashboard;

  /// No description provided for @filterEasy.
  ///
  /// In en, this message translates to:
  /// **'easy'**
  String get filterEasy;

  /// No description provided for @filterMedium.
  ///
  /// In en, this message translates to:
  /// **'medium'**
  String get filterMedium;

  /// No description provided for @filterHard.
  ///
  /// In en, this message translates to:
  /// **'hard'**
  String get filterHard;

  /// No description provided for @vocabularyTitle.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get vocabularyTitle;

  /// No description provided for @listeningTitle.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get listeningTitle;

  /// No description provided for @writingTitle.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get writingTitle;

  /// No description provided for @progressReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressReportTitle;

  /// No description provided for @exerciseHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise history'**
  String get exerciseHistoryTitle;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @aiAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistantTitle;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @accountSuspended.
  ///
  /// In en, this message translates to:
  /// **'Account Suspended'**
  String get accountSuspended;

  /// No description provided for @sessionTerminated.
  ///
  /// In en, this message translates to:
  /// **'Your session has been terminated.'**
  String get sessionTerminated;

  /// No description provided for @reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason:'**
  String get reasonLabel;

  /// No description provided for @adminConsoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Console'**
  String get adminConsoleTitle;

  /// No description provided for @superAdminRole.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get superAdminRole;

  /// No description provided for @managementSection.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get managementSection;

  /// No description provided for @contentManagerTile.
  ///
  /// In en, this message translates to:
  /// **'Content Manager'**
  String get contentManagerTile;

  /// No description provided for @contentManagerSub.
  ///
  /// In en, this message translates to:
  /// **'Tasks, Reading & Listening editor'**
  String get contentManagerSub;

  /// No description provided for @reportsMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsMenuTitle;

  /// No description provided for @reportsMenuSub.
  ///
  /// In en, this message translates to:
  /// **'Issue feedback'**
  String get reportsMenuSub;

  /// No description provided for @usersMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get usersMenuTitle;

  /// No description provided for @usersMenuSub.
  ///
  /// In en, this message translates to:
  /// **'User list'**
  String get usersMenuSub;

  /// No description provided for @submissionsMetric.
  ///
  /// In en, this message translates to:
  /// **'Submissions'**
  String get submissionsMetric;

  /// No description provided for @aiCostMetric.
  ///
  /// In en, this message translates to:
  /// **'AI Cost (Est)'**
  String get aiCostMetric;

  /// No description provided for @reportsMetric.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsMetric;

  /// No description provided for @activeUsersMetric.
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get activeUsersMetric;

  /// No description provided for @activityChart.
  ///
  /// In en, this message translates to:
  /// **'Activity Chart'**
  String get activityChart;

  /// No description provided for @swipeToView.
  ///
  /// In en, this message translates to:
  /// **'Swipe to view'**
  String get swipeToView;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Master English with AI-powered learning'**
  String get appTagline;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @appNameBrand.
  ///
  /// In en, this message translates to:
  /// **'LearnLingo'**
  String get appNameBrand;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{n} day streak'**
  String streakDays(int n);

  /// No description provided for @fullProgressStats.
  ///
  /// In en, this message translates to:
  /// **'Full progress & stats'**
  String get fullProgressStats;

  /// No description provided for @noStudyWeek.
  ///
  /// In en, this message translates to:
  /// **'No study minutes this week yet — start a lesson!'**
  String get noStudyWeek;

  /// No description provided for @speakingDescReadAloud.
  ///
  /// In en, this message translates to:
  /// **'Read text passages clearly.'**
  String get speakingDescReadAloud;

  /// No description provided for @speakingDescShadowing.
  ///
  /// In en, this message translates to:
  /// **'Listen and repeat instantly.'**
  String get speakingDescShadowing;

  /// No description provided for @speakingDescPronunciation.
  ///
  /// In en, this message translates to:
  /// **'Practice syllable precision.'**
  String get speakingDescPronunciation;

  /// No description provided for @speakingDescFreeSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Chat freely about any topic.'**
  String get speakingDescFreeSpeaking;

  /// No description provided for @speakingSelectModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Practice Mode'**
  String get speakingSelectModeTitle;

  /// No description provided for @speakingSelectModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a method to start your speaking journey.'**
  String get speakingSelectModeSubtitle;

  /// No description provided for @speakingMasteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Speaking Mastery'**
  String get speakingMasteryTitle;

  /// No description provided for @speakingMasterySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Practice pronunciation and fluency with AI feedback.'**
  String get speakingMasterySubtitle;

  /// No description provided for @aiPoweredBadge.
  ///
  /// In en, this message translates to:
  /// **'AI Powered'**
  String get aiPoweredBadge;

  /// No description provided for @searchTopicHint.
  ///
  /// In en, this message translates to:
  /// **'Search topic, ID…'**
  String get searchTopicHint;

  /// No description provided for @loadDataFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data'**
  String get loadDataFailed;

  /// No description provided for @noSpeakingLessonsFound.
  ///
  /// In en, this message translates to:
  /// **'No speaking lessons found'**
  String get noSpeakingLessonsFound;

  /// No description provided for @bestScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Best Score'**
  String get bestScoreLabel;

  /// No description provided for @noAttemptsYet.
  ///
  /// In en, this message translates to:
  /// **'No attempts'**
  String get noAttemptsYet;

  /// No description provided for @reviewAction.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewAction;

  /// No description provided for @retakeAction.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retakeAction;

  /// No description provided for @resumeAction.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeAction;

  /// No description provided for @startAction.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startAction;

  /// No description provided for @percentDone.
  ///
  /// In en, this message translates to:
  /// **'{pct}% done'**
  String percentDone(int pct);

  /// No description provided for @lessonMetaLine.
  ///
  /// In en, this message translates to:
  /// **'{n} sentences · Topic: {topic}'**
  String lessonMetaLine(int n, String topic);

  /// No description provided for @topicDailyLife.
  ///
  /// In en, this message translates to:
  /// **'Daily Life'**
  String get topicDailyLife;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @speechNotAvailableSnack.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition is not available. Grant microphone permission and (on iOS) Speech Recognition.'**
  String get speechNotAvailableSnack;

  /// No description provided for @micOpenFailedSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not open the microphone. On Android you need Google\'s recognition service; try installing or updating the Google app and English language.'**
  String get micOpenFailedSnack;

  /// No description provided for @micStartError.
  ///
  /// In en, this message translates to:
  /// **'Error starting microphone: {error}'**
  String micStartError(String error);

  /// No description provided for @listeningPracticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Listening Practice'**
  String get listeningPracticeTitle;

  /// No description provided for @listeningHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Dictation Master'**
  String get listeningHeaderTitle;

  /// No description provided for @listeningHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Improve listening and spelling skills with short daily exercises.'**
  String get listeningHeaderSubtitle;

  /// No description provided for @listeningPremiumBadge.
  ///
  /// In en, this message translates to:
  /// **'Premium Content'**
  String get listeningPremiumBadge;

  /// No description provided for @listeningSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search lessons, topics, or ID…'**
  String get listeningSearchHint;

  /// No description provided for @listeningDictation.
  ///
  /// In en, this message translates to:
  /// **'Dictation'**
  String get listeningDictation;

  /// No description provided for @noReadingArticlesFound.
  ///
  /// In en, this message translates to:
  /// **'No reading articles found'**
  String get noReadingArticlesFound;

  /// No description provided for @noListeningLessonsFound.
  ///
  /// In en, this message translates to:
  /// **'No listening lessons found'**
  String get noListeningLessonsFound;

  /// No description provided for @questionsCount.
  ///
  /// In en, this message translates to:
  /// **'{n} questions'**
  String questionsCount(int n);

  /// No description provided for @progressPercentLabel.
  ///
  /// In en, this message translates to:
  /// **'Progress: {pct}%'**
  String progressPercentLabel(int pct);

  /// No description provided for @completedBadge.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedBadge;

  /// No description provided for @readingSkillsHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading Skills'**
  String get readingSkillsHeaderTitle;

  /// No description provided for @readingSkillsHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Improve comprehension and vocabulary with curated articles.'**
  String get readingSkillsHeaderSubtitle;

  /// No description provided for @readingDailyArticlesBadge.
  ///
  /// In en, this message translates to:
  /// **'Daily Articles'**
  String get readingDailyArticlesBadge;

  /// No description provided for @couldNotLoadExerciseHistory.
  ///
  /// In en, this message translates to:
  /// **'Could not load exercise history'**
  String get couldNotLoadExerciseHistory;

  /// No description provided for @skillTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get skillTabAll;

  /// No description provided for @skillTabReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get skillTabReading;

  /// No description provided for @skillTabListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get skillTabListening;

  /// No description provided for @skillTabSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get skillTabSpeaking;

  /// No description provided for @skillTabWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get skillTabWriting;

  /// No description provided for @historyEmptyRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'No exercises in this range'**
  String get historyEmptyRangeTitle;

  /// No description provided for @historyEmptyRangeHint.
  ///
  /// In en, this message translates to:
  /// **'Try another date range or skill tab'**
  String get historyEmptyRangeHint;

  /// No description provided for @dateRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateRangeLabel;

  /// No description provided for @readingScorePercent.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}%'**
  String readingScorePercent(String score);

  /// No description provided for @readingMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String readingMinutesShort(int n);

  /// No description provided for @readingQuizCount.
  ///
  /// In en, this message translates to:
  /// **'{n} quiz'**
  String readingQuizCount(int n);

  /// No description provided for @unknownLevel.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownLevel;

  /// No description provided for @registerHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Your Account'**
  String get registerHeroTitle;

  /// No description provided for @registerHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill in the details to start your journey.'**
  String get registerHeroSubtitle;

  /// No description provided for @labelFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name *'**
  String get labelFullName;

  /// No description provided for @hintFullName.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get hintFullName;

  /// No description provided for @labelUsername.
  ///
  /// In en, this message translates to:
  /// **'Username *'**
  String get labelUsername;

  /// No description provided for @hintUsername.
  ///
  /// In en, this message translates to:
  /// **'username123'**
  String get hintUsername;

  /// No description provided for @labelPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get labelPhone;

  /// No description provided for @hintPhoneShort.
  ///
  /// In en, this message translates to:
  /// **'0912…'**
  String get hintPhoneShort;

  /// No description provided for @labelDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get labelDateOfBirth;

  /// No description provided for @hintDatePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'DD/MM/YYYY'**
  String get hintDatePlaceholder;

  /// No description provided for @labelConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password *'**
  String get labelConfirmPassword;

  /// No description provided for @hintPasswordMask.
  ///
  /// In en, this message translates to:
  /// **'••••••'**
  String get hintPasswordMask;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @registrationFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration Failed'**
  String get registrationFailedTitle;

  /// No description provided for @enterEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email.'**
  String get enterEmailRequired;

  /// No description provided for @otpSixDigitsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit code.'**
  String get otpSixDigitsRequired;

  /// No description provided for @forgotHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Your Password'**
  String get forgotHeroTitle;

  /// No description provided for @forgotHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a verification code.'**
  String get forgotHeroSubtitle;

  /// No description provided for @sendButton.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendButton;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get enterVerificationCode;

  /// No description provided for @otpSentPrefix.
  ///
  /// In en, this message translates to:
  /// **'A 6-digit code has been sent to\n'**
  String get otpSentPrefix;

  /// No description provided for @otpSentSuffix.
  ///
  /// In en, this message translates to:
  /// **'. Please check your inbox.'**
  String get otpSentSuffix;

  /// No description provided for @resendCooldown.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds} s'**
  String resendCooldown(int seconds);

  /// No description provided for @verifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyButton;

  /// No description provided for @verificationFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification Failed'**
  String get verificationFailedTitle;

  /// No description provided for @resendingCodeSnack.
  ///
  /// In en, this message translates to:
  /// **'Resending code…'**
  String get resendingCodeSnack;

  /// No description provided for @otpSentEmailSnack.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to your email.'**
  String get otpSentEmailSnack;

  /// No description provided for @didNotReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code? '**
  String get didNotReceiveCode;

  /// No description provided for @resendAction.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resendAction;

  /// No description provided for @setNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get setNewPasswordTitle;

  /// No description provided for @setNewPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a new password for your account.'**
  String get setNewPasswordSubtitle;

  /// No description provided for @labelNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get labelNewPassword;

  /// No description provided for @hintEnterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter new password…'**
  String get hintEnterNewPassword;

  /// No description provided for @labelConfirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get labelConfirmNewPassword;

  /// No description provided for @hintConfirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password…'**
  String get hintConfirmNewPassword;

  /// No description provided for @resetPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordButton;

  /// No description provided for @resetFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Failed'**
  String get resetFailedTitle;

  /// No description provided for @enterBothPasswords.
  ///
  /// In en, this message translates to:
  /// **'Please enter both passwords.'**
  String get enterBothPasswords;

  /// No description provided for @passwordsDoNotMatchShort.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatchShort;

  /// No description provided for @passwordMinSixChars.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get passwordMinSixChars;

  /// No description provided for @homeNoData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get homeNoData;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name} 👋'**
  String homeGreeting(String name);

  /// No description provided for @homeReadySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to continue learning?'**
  String get homeReadySubtitle;

  /// No description provided for @homeDailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Goal'**
  String get homeDailyGoal;

  /// No description provided for @homeDailyLessonsLine.
  ///
  /// In en, this message translates to:
  /// **'{done} / {goal} lessons completed'**
  String homeDailyLessonsLine(int done, int goal);

  /// No description provided for @homeTodaysLessons.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Lessons'**
  String get homeTodaysLessons;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get homeShowLess;

  /// No description provided for @homeLessonListeningTitle.
  ///
  /// In en, this message translates to:
  /// **'Listening Practice'**
  String get homeLessonListeningTitle;

  /// No description provided for @homeLessonListeningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily conversations • 15 min'**
  String get homeLessonListeningSubtitle;

  /// No description provided for @homeLessonReadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading Comprehension'**
  String get homeLessonReadingTitle;

  /// No description provided for @homeLessonReadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Short stories • 20 min'**
  String get homeLessonReadingSubtitle;

  /// No description provided for @homeLessonVocabTitle.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary Builder'**
  String get homeLessonVocabTitle;

  /// No description provided for @homeLessonVocabSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New words • 10 min'**
  String get homeLessonVocabSubtitle;

  /// No description provided for @homeLessonSpeakingTitle.
  ///
  /// In en, this message translates to:
  /// **'Speaking Practice'**
  String get homeLessonSpeakingTitle;

  /// No description provided for @homeLessonSpeakingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation • 25 min'**
  String get homeLessonSpeakingSubtitle;

  /// No description provided for @homeLessonWritingTitle.
  ///
  /// In en, this message translates to:
  /// **'Writing Practice'**
  String get homeLessonWritingTitle;

  /// No description provided for @homeLessonWritingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select a topic • 15 min'**
  String get homeLessonWritingSubtitle;

  /// No description provided for @homeQuickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get homeQuickAccess;

  /// No description provided for @homeQuickFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get homeQuickFavorites;

  /// No description provided for @homeQuickFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Flashcards'**
  String get homeQuickFlashcards;

  /// No description provided for @homeQuickStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get homeQuickStats;

  /// No description provided for @statStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get statStreak;

  /// No description provided for @statPoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get statPoints;

  /// No description provided for @statLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get statLevelLabel;

  /// No description provided for @homeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load data'**
  String get homeLoadFailed;

  /// No description provided for @homePleaseSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please sign in'**
  String get homePleaseSignIn;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}m ago'**
  String timeMinutesAgo(int n);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}h ago'**
  String timeHoursAgo(int n);

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'You will receive notifications here.'**
  String get notificationsEmptyBody;

  /// No description provided for @aiAssistantEmptyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything about your learning progress.'**
  String get aiAssistantEmptyPrompt;

  /// No description provided for @aiChatPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type a question…'**
  String get aiChatPlaceholder;

  /// No description provided for @listeningChooseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to train your ear today.'**
  String get listeningChooseSubtitle;

  /// No description provided for @listeningModeComprehensionTitle.
  ///
  /// In en, this message translates to:
  /// **'Comprehension'**
  String get listeningModeComprehensionTitle;

  /// No description provided for @listeningModeDictationTileDesc.
  ///
  /// In en, this message translates to:
  /// **'Listen and type exactly what you hear.'**
  String get listeningModeDictationTileDesc;

  /// No description provided for @listeningModeComprehensionDesc.
  ///
  /// In en, this message translates to:
  /// **'Listen to audio and answer multiple choice questions.'**
  String get listeningModeComprehensionDesc;

  /// No description provided for @vocabReviewSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Session'**
  String get vocabReviewSessionTitle;

  /// No description provided for @tapToSeeMeaning.
  ///
  /// In en, this message translates to:
  /// **'Tap to see meaning'**
  String get tapToSeeMeaning;

  /// No description provided for @showAnswerButton.
  ///
  /// In en, this message translates to:
  /// **'Show Answer'**
  String get showAnswerButton;

  /// No description provided for @srsHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get srsHard;

  /// No description provided for @srsGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get srsGood;

  /// No description provided for @srsEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get srsEasy;

  /// No description provided for @vocabSessionCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Session complete!'**
  String get vocabSessionCompleteTitle;

  /// No description provided for @vocabSessionCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reviewed all words for now.'**
  String get vocabSessionCompleteBody;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @genericLoadError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get genericLoadError;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your password to keep your account secure.'**
  String get changePasswordSubtitle;

  /// No description provided for @labelCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get labelCurrentPassword;

  /// No description provided for @hintCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get hintCurrentPassword;

  /// No description provided for @hintReenterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter new password'**
  String get hintReenterNewPassword;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get fillAllFields;

  /// No description provided for @newPasswordMismatchToast.
  ///
  /// In en, this message translates to:
  /// **'New passwords do not match'**
  String get newPasswordMismatchToast;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @learningProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning Progress'**
  String get learningProgressTitle;

  /// No description provided for @reportIssueTooltip.
  ///
  /// In en, this message translates to:
  /// **'Report issue'**
  String get reportIssueTooltip;

  /// No description provided for @failedToLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load user profile.'**
  String get failedToLoadProfile;

  /// No description provided for @failedToLoadData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data'**
  String get failedToLoadData;

  /// No description provided for @pleaseTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again later'**
  String get pleaseTryAgainLater;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @progressOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get progressOverview;

  /// No description provided for @progressPerformanceMetrics.
  ///
  /// In en, this message translates to:
  /// **'Performance metrics'**
  String get progressPerformanceMetrics;

  /// No description provided for @progressFilterDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get progressFilterDay;

  /// No description provided for @progressFilterWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get progressFilterWeek;

  /// No description provided for @progressFilterMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get progressFilterMonth;

  /// No description provided for @progressPeriodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get progressPeriodToday;

  /// No description provided for @progressPeriodThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get progressPeriodThisWeek;

  /// No description provided for @progressPeriodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get progressPeriodThisMonth;

  /// No description provided for @progressDurationHm.
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}m'**
  String progressDurationHm(int h, int m);

  /// No description provided for @progressGoalLine.
  ///
  /// In en, this message translates to:
  /// **'Goal: {time}'**
  String progressGoalLine(String time);

  /// No description provided for @progressPercentCompleted.
  ///
  /// In en, this message translates to:
  /// **'{pct}% completed'**
  String progressPercentCompleted(int pct);

  /// No description provided for @progressDetailedStats.
  ///
  /// In en, this message translates to:
  /// **'Detailed stats'**
  String get progressDetailedStats;

  /// No description provided for @progressStatVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get progressStatVocabulary;

  /// No description provided for @progressStatReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get progressStatReading;

  /// No description provided for @progressStatListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get progressStatListening;

  /// No description provided for @progressStatLessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get progressStatLessons;

  /// No description provided for @progressStatWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get progressStatWriting;

  /// No description provided for @progressStatSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get progressStatSpeaking;

  /// No description provided for @progressLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get progressLeaderboard;

  /// No description provided for @progressActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get progressActivity;

  /// No description provided for @leaderboardLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot load leaderboard'**
  String get leaderboardLoadFailed;

  /// No description provided for @leaderboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'No leaderboard data available'**
  String get leaderboardEmpty;

  /// No description provided for @statDetailVocab.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary detail'**
  String get statDetailVocab;

  /// No description provided for @statDetailReading.
  ///
  /// In en, this message translates to:
  /// **'Reading attempts detail'**
  String get statDetailReading;

  /// No description provided for @statDetailDictation.
  ///
  /// In en, this message translates to:
  /// **'Listening / dictation detail'**
  String get statDetailDictation;

  /// No description provided for @statDetailSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking practice detail'**
  String get statDetailSpeaking;

  /// No description provided for @statDetailWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing submissions detail'**
  String get statDetailWriting;

  /// No description provided for @statDetailLessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons completed detail'**
  String get statDetailLessons;

  /// No description provided for @statDetailGeneric.
  ///
  /// In en, this message translates to:
  /// **'Progress detail'**
  String get statDetailGeneric;

  /// No description provided for @statDetailPeriodLog.
  ///
  /// In en, this message translates to:
  /// **'Showing {period} log.'**
  String statDetailPeriodLog(String period);

  /// No description provided for @statDetailReadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accuracy: {score}% · {date}'**
  String statDetailReadingSubtitle(String score, String date);

  /// No description provided for @statDetailScoreDateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}% · {date}'**
  String statDetailScoreDateSubtitle(String score, String date);

  /// No description provided for @statDetailWritingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Band score: {score} · {date}'**
  String statDetailWritingSubtitle(String score, String date);

  /// No description provided for @statDetailDateOnly.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String statDetailDateOnly(Object date);

  /// No description provided for @statDetailDateLine.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String statDetailDateLine(String date);

  /// No description provided for @statDetailLessonsGroupOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get statDetailLessonsGroupOther;

  /// No description provided for @statDetailNoData.
  ///
  /// In en, this message translates to:
  /// **'No data found.'**
  String get statDetailNoData;

  /// No description provided for @reportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback & support'**
  String get reportDialogTitle;

  /// No description provided for @reportDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let us know about an issue or suggestion.'**
  String get reportDialogSubtitle;

  /// No description provided for @reportTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Report type'**
  String get reportTypeLabel;

  /// No description provided for @reportTypeBug.
  ///
  /// In en, this message translates to:
  /// **'Bug report'**
  String get reportTypeBug;

  /// No description provided for @reportTypeFeature.
  ///
  /// In en, this message translates to:
  /// **'Feature request'**
  String get reportTypeFeature;

  /// No description provided for @reportTypeImprovement.
  ///
  /// In en, this message translates to:
  /// **'Improvement'**
  String get reportTypeImprovement;

  /// No description provided for @reportTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportTypeOther;

  /// No description provided for @reportTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get reportTitleLabel;

  /// No description provided for @reportTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Brief summary of the issue'**
  String get reportTitleHint;

  /// No description provided for @reportDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get reportDescriptionLabel;

  /// No description provided for @reportDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Please describe the details…'**
  String get reportDescriptionHint;

  /// No description provided for @reportAttachmentsOptional.
  ///
  /// In en, this message translates to:
  /// **'Attachments (optional)'**
  String get reportAttachmentsOptional;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get submitReport;

  /// No description provided for @reportFillTitleDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title and description.'**
  String get reportFillTitleDescription;

  /// No description provided for @reportSubmissionFailed.
  ///
  /// In en, this message translates to:
  /// **'Submission failed'**
  String get reportSubmissionFailed;

  /// No description provided for @reportThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get reportThankYou;

  /// No description provided for @reportReceivedBody.
  ///
  /// In en, this message translates to:
  /// **'We have received your report and will look into it shortly.'**
  String get reportReceivedBody;

  /// No description provided for @reportUploadScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload screenshots'**
  String get reportUploadScreenshots;

  /// No description provided for @reportSupportedFormats.
  ///
  /// In en, this message translates to:
  /// **'Supported formats: JPEG, PNG'**
  String get reportSupportedFormats;

  /// No description provided for @vocabularyScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get vocabularyScreenTitle;

  /// No description provided for @vocabTutorialTooltip.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get vocabTutorialTooltip;

  /// No description provided for @vocabSearchDictionaryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search dictionary'**
  String get vocabSearchDictionaryTooltip;

  /// No description provided for @vocabTabRecently.
  ///
  /// In en, this message translates to:
  /// **'Recently'**
  String get vocabTabRecently;

  /// No description provided for @vocabTabLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get vocabTabLearning;

  /// No description provided for @vocabTabSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get vocabTabSaved;

  /// No description provided for @vocabReviewNowFab.
  ///
  /// In en, this message translates to:
  /// **'Review now'**
  String get vocabReviewNowFab;

  /// No description provided for @vocabNoRecentWords.
  ///
  /// In en, this message translates to:
  /// **'No words looked up recently.'**
  String get vocabNoRecentWords;

  /// No description provided for @vocabLearningEmpty.
  ///
  /// In en, this message translates to:
  /// **'Start learning to build your deck.'**
  String get vocabLearningEmpty;

  /// No description provided for @vocabSavedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Bookmark words to verify later.'**
  String get vocabSavedEmpty;

  /// No description provided for @vocabErrorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String vocabErrorWithMessage(String message);

  /// No description provided for @vocabNoDetailsForWord.
  ///
  /// In en, this message translates to:
  /// **'No details found for \"{word}\"'**
  String vocabNoDetailsForWord(String word);

  /// No description provided for @vocabUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get vocabUnknownError;

  /// No description provided for @vocabReviewNowBadge.
  ///
  /// In en, this message translates to:
  /// **'Review now'**
  String get vocabReviewNowBadge;

  /// No description provided for @vocabReviewOnDate.
  ///
  /// In en, this message translates to:
  /// **'Review: {date}'**
  String vocabReviewOnDate(String date);

  /// No description provided for @vocabLevelShort.
  ///
  /// In en, this message translates to:
  /// **'Lv.{level}'**
  String vocabLevelShort(int level);

  /// No description provided for @wordNoDefinition.
  ///
  /// In en, this message translates to:
  /// **'No definition'**
  String get wordNoDefinition;

  /// No description provided for @wordUnknownType.
  ///
  /// In en, this message translates to:
  /// **'Unknown type'**
  String get wordUnknownType;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccess;

  /// No description provided for @sectionPublicInfo.
  ///
  /// In en, this message translates to:
  /// **'Public info'**
  String get sectionPublicInfo;

  /// No description provided for @sectionPrivateDetails.
  ///
  /// In en, this message translates to:
  /// **'Private details'**
  String get sectionPrivateDetails;

  /// No description provided for @sectionSystemInfo.
  ///
  /// In en, this message translates to:
  /// **'System info'**
  String get sectionSystemInfo;

  /// No description provided for @labelBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get labelBio;

  /// No description provided for @hintBio.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself…'**
  String get hintBio;

  /// No description provided for @labelGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get labelGender;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @labelBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get labelBirthday;

  /// No description provided for @hintSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get hintSelectDate;

  /// No description provided for @labelRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get labelRole;

  /// No description provided for @labelUserId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get labelUserId;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copiedToClipboard;

  /// No description provided for @selectPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectPlaceholder;

  /// No description provided for @dictQuickSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick search'**
  String get dictQuickSearchTitle;

  /// No description provided for @dictDictionaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Dictionary'**
  String get dictDictionaryTitle;

  /// No description provided for @dictSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search words (e.g. serendipity)…'**
  String get dictSearchHint;

  /// No description provided for @dictStartTyping.
  ///
  /// In en, this message translates to:
  /// **'Start typing to search'**
  String get dictStartTyping;

  /// No description provided for @dictNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get dictNoResults;

  /// No description provided for @dictDefinitions.
  ///
  /// In en, this message translates to:
  /// **'Definitions'**
  String get dictDefinitions;

  /// No description provided for @dictSeeAlso.
  ///
  /// In en, this message translates to:
  /// **'See also'**
  String get dictSeeAlso;

  /// No description provided for @dictTooltipStartLearning.
  ///
  /// In en, this message translates to:
  /// **'Start learning'**
  String get dictTooltipStartLearning;

  /// No description provided for @dictTooltipSaveWord.
  ///
  /// In en, this message translates to:
  /// **'Save word'**
  String get dictTooltipSaveWord;

  /// No description provided for @wordSavedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Saved \"{word}\"'**
  String wordSavedSnackbar(String word);

  /// No description provided for @wordAddedToLearningQueue.
  ///
  /// In en, this message translates to:
  /// **'Added \"{word}\" to your learning queue!'**
  String wordAddedToLearningQueue(String word);

  /// No description provided for @dictNoDefinitionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No definition available'**
  String get dictNoDefinitionAvailable;

  /// No description provided for @accountSuspendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account suspended'**
  String get accountSuspendedTitle;

  /// No description provided for @accountSessionTerminated.
  ///
  /// In en, this message translates to:
  /// **'Your session has been terminated.'**
  String get accountSessionTerminated;

  /// No description provided for @suspensionReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason:'**
  String get suspensionReasonLabel;

  /// No description provided for @agreeAndLogout.
  ///
  /// In en, this message translates to:
  /// **'Agree & sign out'**
  String get agreeAndLogout;

  /// No description provided for @submissionHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Submission history'**
  String get submissionHistoryTitle;

  /// No description provided for @writingHistoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load history'**
  String get writingHistoryLoadFailed;

  /// No description provided for @writingNoHistoryForTopic.
  ///
  /// In en, this message translates to:
  /// **'No submissions for this topic yet.'**
  String get writingNoHistoryForTopic;

  /// No description provided for @dateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown date'**
  String get dateUnknown;

  /// No description provided for @writingTaskDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Writing task'**
  String get writingTaskDefaultTitle;

  /// No description provided for @wordCountN.
  ///
  /// In en, this message translates to:
  /// **'{n} words'**
  String wordCountN(int n);

  /// No description provided for @listeningSentenceNumber.
  ///
  /// In en, this message translates to:
  /// **'Sentence {n}'**
  String listeningSentenceNumber(int n);

  /// No description provided for @dictationCheckButton.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get dictationCheckButton;

  /// No description provided for @dictationNextButton.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get dictationNextButton;

  /// No description provided for @dictationFinishButton.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get dictationFinishButton;

  /// No description provided for @dictationTypeWhatYouHearHint.
  ///
  /// In en, this message translates to:
  /// **'Type what you hear…'**
  String get dictationTypeWhatYouHearHint;

  /// No description provided for @meaningLabel.
  ///
  /// In en, this message translates to:
  /// **'Meaning:'**
  String get meaningLabel;

  /// No description provided for @quizTimeUpSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up! Submitting your answers…'**
  String get quizTimeUpSubmitting;

  /// No description provided for @translationFailed.
  ///
  /// In en, this message translates to:
  /// **'Translation failed.'**
  String get translationFailed;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonError;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @listeningCompLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this lesson.'**
  String get listeningCompLoadError;

  /// No description provided for @listeningCompTabTranscript.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get listeningCompTabTranscript;

  /// No description provided for @listeningCompTranslateToggle.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get listeningCompTranslateToggle;

  /// No description provided for @listeningCompQuestionNumber.
  ///
  /// In en, this message translates to:
  /// **'Question {n}'**
  String listeningCompQuestionNumber(int n);

  /// No description provided for @listeningCompHintSeekSeconds.
  ///
  /// In en, this message translates to:
  /// **'Listen to the segment with the answer ({seconds}s)'**
  String listeningCompHintSeekSeconds(int seconds);

  /// No description provided for @listeningCompTranscriptLocked.
  ///
  /// In en, this message translates to:
  /// **'Transcript locked'**
  String get listeningCompTranscriptLocked;

  /// No description provided for @listeningCompTranscriptLockedHint.
  ///
  /// In en, this message translates to:
  /// **'Submit your answers first to unlock the full audio transcript.'**
  String get listeningCompTranscriptLockedHint;

  /// No description provided for @listeningCompTranscriptOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original (English)'**
  String get listeningCompTranscriptOriginal;

  /// No description provided for @listeningCompTranscriptTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation (Vietnamese)'**
  String get listeningCompTranscriptTranslation;

  /// No description provided for @readingQuizResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get readingQuizResultTitle;

  /// No description provided for @readingQuizResultSummary.
  ///
  /// In en, this message translates to:
  /// **'Correct: {correct} / {total}\nScore: {scorePct}%'**
  String readingQuizResultSummary(int correct, int total, int scorePct);

  /// No description provided for @readingTabArticle.
  ///
  /// In en, this message translates to:
  /// **'Article'**
  String get readingTabArticle;

  /// No description provided for @readingTabQuestionsCount.
  ///
  /// In en, this message translates to:
  /// **'Questions ({n})'**
  String readingTabQuestionsCount(int n);

  /// No description provided for @readingSubmitAnswers.
  ///
  /// In en, this message translates to:
  /// **'Submit answers'**
  String get readingSubmitAnswers;

  /// No description provided for @readingNoQuestionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No questions available.'**
  String get readingNoQuestionsAvailable;

  /// No description provided for @readingFeedbackExplanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get readingFeedbackExplanation;

  /// No description provided for @readingFeedbackLocationParagraph.
  ///
  /// In en, this message translates to:
  /// **'• Location: Paragraph {n}'**
  String readingFeedbackLocationParagraph(int n);

  /// No description provided for @readingFeedbackKeySentence.
  ///
  /// In en, this message translates to:
  /// **'• Key sentence: \"{sentence}\"'**
  String readingFeedbackKeySentence(String sentence);

  /// No description provided for @readingShowTranslation.
  ///
  /// In en, this message translates to:
  /// **'Show translation'**
  String get readingShowTranslation;

  /// No description provided for @readingHideTranslation.
  ///
  /// In en, this message translates to:
  /// **'Hide translation'**
  String get readingHideTranslation;

  /// No description provided for @readingSubmissionFailed.
  ///
  /// In en, this message translates to:
  /// **'Submission failed'**
  String get readingSubmissionFailed;

  /// No description provided for @readingReviewMode.
  ///
  /// In en, this message translates to:
  /// **'Review mode'**
  String get readingReviewMode;

  /// No description provided for @readingReviewingWithScore.
  ///
  /// In en, this message translates to:
  /// **'Reviewing (score: {pct}%)'**
  String readingReviewingWithScore(int pct);

  /// No description provided for @listeningSkillsPracticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get listeningSkillsPracticeTitle;

  /// No description provided for @listeningSkillsHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Listening task'**
  String get listeningSkillsHeaderTitle;

  /// No description provided for @listeningSkillsTabPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get listeningSkillsTabPractice;

  /// No description provided for @listeningSkillsTabDiscuss.
  ///
  /// In en, this message translates to:
  /// **'Discuss'**
  String get listeningSkillsTabDiscuss;

  /// No description provided for @dictationSnackCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get dictationSnackCorrect;

  /// No description provided for @dictationSnackTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get dictationSnackTryAgain;

  /// No description provided for @writingFbErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get writingFbErrorTitle;

  /// No description provided for @writingFbNoData.
  ///
  /// In en, this message translates to:
  /// **'No feedback data found.'**
  String get writingFbNoData;

  /// No description provided for @writingFbResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback result'**
  String get writingFbResultTitle;

  /// No description provided for @writingFbTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get writingFbTabOverview;

  /// No description provided for @writingFbTabDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get writingFbTabDetails;

  /// No description provided for @writingFbTabRewrites.
  ///
  /// In en, this message translates to:
  /// **'Rewrites'**
  String get writingFbTabRewrites;

  /// No description provided for @writingFbTabSamples.
  ///
  /// In en, this message translates to:
  /// **'Samples'**
  String get writingFbTabSamples;

  /// No description provided for @writingFbTopicRequirement.
  ///
  /// In en, this message translates to:
  /// **'Topic & requirement'**
  String get writingFbTopicRequirement;

  /// No description provided for @writingFbNoPromptContent.
  ///
  /// In en, this message translates to:
  /// **'No prompt content available.'**
  String get writingFbNoPromptContent;

  /// No description provided for @writingFbOverallBand.
  ///
  /// In en, this message translates to:
  /// **'Overall band score'**
  String get writingFbOverallBand;

  /// No description provided for @writingFbSubscores.
  ///
  /// In en, this message translates to:
  /// **'Subscores'**
  String get writingFbSubscores;

  /// No description provided for @writingFbCriterionTR.
  ///
  /// In en, this message translates to:
  /// **'Task response'**
  String get writingFbCriterionTR;

  /// No description provided for @writingFbCriterionCC.
  ///
  /// In en, this message translates to:
  /// **'Coherence & cohesion'**
  String get writingFbCriterionCC;

  /// No description provided for @writingFbCriterionLR.
  ///
  /// In en, this message translates to:
  /// **'Lexical resource'**
  String get writingFbCriterionLR;

  /// No description provided for @writingFbCriterionGRA.
  ///
  /// In en, this message translates to:
  /// **'Grammar range'**
  String get writingFbCriterionGRA;

  /// No description provided for @writingFbCriterionGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get writingFbCriterionGrammar;

  /// No description provided for @writingFbKeyTips.
  ///
  /// In en, this message translates to:
  /// **'Key improvement tips'**
  String get writingFbKeyTips;

  /// No description provided for @writingFbDetailedCorrection.
  ///
  /// In en, this message translates to:
  /// **'Detailed correction'**
  String get writingFbDetailedCorrection;

  /// No description provided for @writingFbTapHighlighted.
  ///
  /// In en, this message translates to:
  /// **'Tap highlighted text to see an explanation.'**
  String get writingFbTapHighlighted;

  /// No description provided for @writingFbNoCorrections.
  ///
  /// In en, this message translates to:
  /// **'No corrections available.'**
  String get writingFbNoCorrections;

  /// No description provided for @writingFbSampleMidTitle.
  ///
  /// In en, this message translates to:
  /// **'Revised version (Band 6.0–7.0)'**
  String get writingFbSampleMidTitle;

  /// No description provided for @writingFbSampleHighTitle.
  ///
  /// In en, this message translates to:
  /// **'Ideal response (Band 8.0+)'**
  String get writingFbSampleHighTitle;

  /// No description provided for @writingInstructionHowTo.
  ///
  /// In en, this message translates to:
  /// **'How to write: {title}'**
  String writingInstructionHowTo(String title);

  /// No description provided for @writingInstructionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick guide & structure'**
  String get writingInstructionSubtitle;

  /// No description provided for @writingInstructionGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it, let\'s write!'**
  String get writingInstructionGotIt;

  /// No description provided for @writingInstructionWhatIsIt.
  ///
  /// In en, this message translates to:
  /// **'What is it?'**
  String get writingInstructionWhatIsIt;

  /// No description provided for @writingInstructionSuggestedStructure.
  ///
  /// In en, this message translates to:
  /// **'Suggested structure'**
  String get writingInstructionSuggestedStructure;

  /// No description provided for @writingInstructionKeyTipsSection.
  ///
  /// In en, this message translates to:
  /// **'Key tips'**
  String get writingInstructionKeyTipsSection;

  /// No description provided for @listeningAutoPlayNext.
  ///
  /// In en, this message translates to:
  /// **'Auto-play next'**
  String get listeningAutoPlayNext;

  /// No description provided for @discussionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No discussions yet'**
  String get discussionsEmpty;

  /// No description provided for @replyingToUser.
  ///
  /// In en, this message translates to:
  /// **'Replying to {user}'**
  String replyingToUser(String user);

  /// No description provided for @commentHintReply.
  ///
  /// In en, this message translates to:
  /// **'Write a reply…'**
  String get commentHintReply;

  /// No description provided for @commentHintAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask a question…'**
  String get commentHintAsk;

  /// No description provided for @writingSaveDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Save draft?'**
  String get writingSaveDraftTitle;

  /// No description provided for @writingSaveDraftMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to save your changes?'**
  String get writingSaveDraftMessage;

  /// No description provided for @writingDiscardButton.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get writingDiscardButton;

  /// No description provided for @writingResumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Resume writing?'**
  String get writingResumeTitle;

  /// No description provided for @writingResumeMessage.
  ///
  /// In en, this message translates to:
  /// **'We found an unfinished draft. Continue where you left off?'**
  String get writingResumeMessage;

  /// No description provided for @writingStartNewButton.
  ///
  /// In en, this message translates to:
  /// **'Start new'**
  String get writingStartNewButton;

  /// No description provided for @writingResumeButton.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get writingResumeButton;

  /// No description provided for @writingInstructionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get writingInstructionsTooltip;

  /// No description provided for @writingPreparingTask.
  ///
  /// In en, this message translates to:
  /// **'Preparing task…'**
  String get writingPreparingTask;

  /// No description provided for @writingDraftSavedSnack.
  ///
  /// In en, this message translates to:
  /// **'Draft saved.'**
  String get writingDraftSavedSnack;

  /// No description provided for @writingTopicFallback.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get writingTopicFallback;

  /// No description provided for @writingPromptTapCollapse.
  ///
  /// In en, this message translates to:
  /// **'Tap to collapse'**
  String get writingPromptTapCollapse;

  /// No description provided for @writingPromptTapExpand.
  ///
  /// In en, this message translates to:
  /// **'Tap to expand prompt'**
  String get writingPromptTapExpand;

  /// No description provided for @writingEditorHint.
  ///
  /// In en, this message translates to:
  /// **'Start writing your essay here…'**
  String get writingEditorHint;

  /// No description provided for @writingSubmitEssay.
  ///
  /// In en, this message translates to:
  /// **'Submit essay'**
  String get writingSubmitEssay;

  /// No description provided for @writingNoTopicsFound.
  ///
  /// In en, this message translates to:
  /// **'No writing topics found'**
  String get writingNoTopicsFound;

  /// No description provided for @listeningCueProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} completed'**
  String listeningCueProgress(int done, int total);

  /// No description provided for @writingSelectTaskType.
  ///
  /// In en, this message translates to:
  /// **'Select task type'**
  String get writingSelectTaskType;

  /// No description provided for @writingForTopic.
  ///
  /// In en, this message translates to:
  /// **'For topic: \"{name}\"'**
  String writingForTopic(String name);

  /// No description provided for @writingSearchTopicsHint.
  ///
  /// In en, this message translates to:
  /// **'Search topics…'**
  String get writingSearchTopicsHint;

  /// No description provided for @writingHeaderEssayTitle.
  ///
  /// In en, this message translates to:
  /// **'Essay writing'**
  String get writingHeaderEssayTitle;

  /// No description provided for @writingHeaderEssaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Practice organizing ideas and building strong arguments.'**
  String get writingHeaderEssaySubtitle;

  /// No description provided for @writingAiFeedbackBadge.
  ///
  /// In en, this message translates to:
  /// **'AI feedback'**
  String get writingAiFeedbackBadge;

  /// No description provided for @writingSearchTopicsTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Search topics, tasks…'**
  String get writingSearchTopicsTasksHint;

  /// No description provided for @writingTaskDescOpinion.
  ///
  /// In en, this message translates to:
  /// **'Express your personal view'**
  String get writingTaskDescOpinion;

  /// No description provided for @writingTaskDescDiscuss.
  ///
  /// In en, this message translates to:
  /// **'Analyze multiple perspectives'**
  String get writingTaskDescDiscuss;

  /// No description provided for @writingTaskDescProblemSolution.
  ///
  /// In en, this message translates to:
  /// **'Identify issues and fixes'**
  String get writingTaskDescProblemSolution;

  /// No description provided for @writingTaskDescAdvantages.
  ///
  /// In en, this message translates to:
  /// **'Weigh pros and cons'**
  String get writingTaskDescAdvantages;

  /// No description provided for @writingTaskDescGeneral.
  ///
  /// In en, this message translates to:
  /// **'General writing practice'**
  String get writingTaskDescGeneral;

  /// No description provided for @writingSubmissionsCount.
  ///
  /// In en, this message translates to:
  /// **'{n} essays'**
  String writingSubmissionsCount(int n);

  /// No description provided for @writingAiSuggestionTitle.
  ///
  /// In en, this message translates to:
  /// **'AI suggestion'**
  String get writingAiSuggestionTitle;

  /// No description provided for @writingWhyCorrection.
  ///
  /// In en, this message translates to:
  /// **'Why this correction?'**
  String get writingWhyCorrection;

  /// No description provided for @writingGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get writingGotIt;

  /// No description provided for @wordDetailsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not find word details.'**
  String get wordDetailsNotFound;

  /// No description provided for @listeningCompTitle.
  ///
  /// In en, this message translates to:
  /// **'Listening comprehension'**
  String get listeningCompTitle;

  /// No description provided for @listeningCompSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Listen to the audio and answer multiple choice questions.'**
  String get listeningCompSubtitle;

  /// No description provided for @listeningCompSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search topics, IDs…'**
  String get listeningCompSearchHint;

  /// No description provided for @listeningCompQuestionCount.
  ///
  /// In en, this message translates to:
  /// **'{n} questions'**
  String listeningCompQuestionCount(int n);

  /// No description provided for @listeningCompHighScore.
  ///
  /// In en, this message translates to:
  /// **'High score: {pct}%'**
  String listeningCompHighScore(int pct);

  /// No description provided for @listeningCompNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started yet'**
  String get listeningCompNotStarted;

  /// No description provided for @listeningCompReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get listeningCompReview;

  /// No description provided for @listeningCompRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get listeningCompRetake;

  /// No description provided for @listeningCompStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get listeningCompStart;

  /// No description provided for @listeningCompEmpty.
  ///
  /// In en, this message translates to:
  /// **'No listening lessons found'**
  String get listeningCompEmpty;

  /// No description provided for @discussionReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get discussionReply;

  /// No description provided for @discussionReactTooltip.
  ///
  /// In en, this message translates to:
  /// **'React'**
  String get discussionReactTooltip;

  /// No description provided for @reactionLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get reactionLike;

  /// No description provided for @reactionLove.
  ///
  /// In en, this message translates to:
  /// **'Love'**
  String get reactionLove;

  /// No description provided for @reactionHaha.
  ///
  /// In en, this message translates to:
  /// **'Haha'**
  String get reactionHaha;

  /// No description provided for @reactionWow.
  ///
  /// In en, this message translates to:
  /// **'Wow'**
  String get reactionWow;

  /// No description provided for @reactionSad.
  ///
  /// In en, this message translates to:
  /// **'Sad'**
  String get reactionSad;

  /// No description provided for @reactionAngry.
  ///
  /// In en, this message translates to:
  /// **'Angry'**
  String get reactionAngry;

  /// No description provided for @freeSpeakingTitle.
  ///
  /// In en, this message translates to:
  /// **'Free speaking'**
  String get freeSpeakingTitle;

  /// No description provided for @freeSpeakingLoadingConfig.
  ///
  /// In en, this message translates to:
  /// **'Loading setup…'**
  String get freeSpeakingLoadingConfig;

  /// No description provided for @freeSpeakingRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get freeSpeakingRetry;

  /// No description provided for @freeSpeakingMicDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is required to talk to the AI. Enable it in Settings.'**
  String get freeSpeakingMicDenied;

  /// No description provided for @freeSpeakingEndCallToChangeVoice.
  ///
  /// In en, this message translates to:
  /// **'End the call to change voice.'**
  String get freeSpeakingEndCallToChangeVoice;

  /// No description provided for @freeSpeakingSelectVoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Select AI voice'**
  String get freeSpeakingSelectVoiceTitle;

  /// No description provided for @freeSpeakingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Hello! Choose a voice and tap the microphone to practice English.'**
  String get freeSpeakingWelcome;

  /// No description provided for @freeSpeakingConfigErrorShort.
  ///
  /// In en, this message translates to:
  /// **'Could not load calling setup.'**
  String get freeSpeakingConfigErrorShort;

  /// No description provided for @freeSpeakingStatusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get freeSpeakingStatusConnecting;

  /// No description provided for @freeSpeakingStatusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get freeSpeakingStatusOnline;

  /// No description provided for @freeSpeakingStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get freeSpeakingStatusOffline;

  /// No description provided for @freeSpeakingStatusAiSpeaking.
  ///
  /// In en, this message translates to:
  /// **'AI speaking'**
  String get freeSpeakingStatusAiSpeaking;

  /// No description provided for @freeSpeakingHintConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get freeSpeakingHintConnecting;

  /// No description provided for @freeSpeakingHintTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get freeSpeakingHintTypeMessage;

  /// No description provided for @freeSpeakingHintTapMic.
  ///
  /// In en, this message translates to:
  /// **'Tap the mic to connect'**
  String get freeSpeakingHintTapMic;

  /// No description provided for @vapiConfigHintAuth.
  ///
  /// In en, this message translates to:
  /// **'Could not load AI calling config (not authenticated).\n\n• Sign in to the app, then open Free Speaking again.\n• If your session expired, sign out and sign back in.'**
  String get vapiConfigHintAuth;

  /// No description provided for @vapiConfigHint503.
  ///
  /// In en, this message translates to:
  /// **'Server reports Vapi is not configured (503).\n\n• In backend .env set VAPI_PUBLIC_KEY and VAPI_ASSISTANT_ID (no spaces after =).\n• Save .env and restart the backend.'**
  String get vapiConfigHint503;

  /// No description provided for @vapiConfigHintHttp.
  ///
  /// In en, this message translates to:
  /// **'Vapi config API returned an error (HTTP {code}).\n\n{detail}'**
  String vapiConfigHintHttp(int code, String detail);

  /// No description provided for @vapiConfigHintNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not load config from the server (network / URL).\n\n• Phone and PC on the same Wi‑Fi.\n• Set the IP in api_config.dart to your machine.\n• Android emulator: use 10.0.2.2.\n\nDetail: {detail}'**
  String vapiConfigHintNetwork(String detail);

  /// No description provided for @vapiConfigHintMissingKeys.
  ///
  /// In en, this message translates to:
  /// **'Missing public key or assistant id.\n\n• Backend: add VAPI_PUBLIC_KEY and VAPI_ASSISTANT_ID to .env and restart.\n• Or build with --dart-define=VAPI_PUBLIC_KEY=… --dart-define=VAPI_ASSISTANT_ID=…'**
  String get vapiConfigHintMissingKeys;

  /// No description provided for @vocabTutorialSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Vocabulary'**
  String get vocabTutorialSlide1Title;

  /// No description provided for @vocabTutorialSlide1a.
  ///
  /// In en, this message translates to:
  /// **'Build a solid vocabulary using '**
  String get vocabTutorialSlide1a;

  /// No description provided for @vocabTutorialSlide1b.
  ///
  /// In en, this message translates to:
  /// **'Spaced Repetition'**
  String get vocabTutorialSlide1b;

  /// No description provided for @vocabTutorialSlide1c.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get vocabTutorialSlide1c;

  /// No description provided for @vocabTutorialSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Search & save'**
  String get vocabTutorialSlide2Title;

  /// No description provided for @vocabTutorialSlide2a.
  ///
  /// In en, this message translates to:
  /// **'Look up words quickly. Tap '**
  String get vocabTutorialSlide2a;

  /// No description provided for @vocabTutorialSlide2SaveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get vocabTutorialSlide2SaveLabel;

  /// No description provided for @vocabTutorialSlide2b.
  ///
  /// In en, this message translates to:
  /// **' to bookmark, or tap '**
  String get vocabTutorialSlide2b;

  /// No description provided for @vocabTutorialSlide2LearnLabel.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get vocabTutorialSlide2LearnLabel;

  /// No description provided for @vocabTutorialSlide2c.
  ///
  /// In en, this message translates to:
  /// **' to start studying.'**
  String get vocabTutorialSlide2c;

  /// No description provided for @vocabTutorialSlide3Title.
  ///
  /// In en, this message translates to:
  /// **'Smart scheduling'**
  String get vocabTutorialSlide3Title;

  /// No description provided for @vocabTutorialSlide3a.
  ///
  /// In en, this message translates to:
  /// **'Based on your study history, the '**
  String get vocabTutorialSlide3a;

  /// No description provided for @vocabTutorialSlide3b.
  ///
  /// In en, this message translates to:
  /// **'server'**
  String get vocabTutorialSlide3b;

  /// No description provided for @vocabTutorialSlide3c.
  ///
  /// In en, this message translates to:
  /// **' automatically calculates your '**
  String get vocabTutorialSlide3c;

  /// No description provided for @vocabTutorialSlide3d.
  ///
  /// In en, this message translates to:
  /// **'forgetting curve'**
  String get vocabTutorialSlide3d;

  /// No description provided for @vocabTutorialSlide3e.
  ///
  /// In en, this message translates to:
  /// **' so you\'re reminded right before you\'re about to forget.'**
  String get vocabTutorialSlide3e;

  /// No description provided for @vocabTutorialSlide4Title.
  ///
  /// In en, this message translates to:
  /// **'Review every day'**
  String get vocabTutorialSlide4Title;

  /// No description provided for @vocabTutorialSlide4a.
  ///
  /// In en, this message translates to:
  /// **'When a word is due, tap '**
  String get vocabTutorialSlide4a;

  /// No description provided for @vocabTutorialSlide4c.
  ///
  /// In en, this message translates to:
  /// **'. Rate recall (Hard / Good / Easy) to optimize your schedule.'**
  String get vocabTutorialSlide4c;

  /// No description provided for @vocabTutorialLetsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go'**
  String get vocabTutorialLetsGo;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
