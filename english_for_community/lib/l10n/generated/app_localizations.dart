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

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

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

  /// No description provided for @studentChatHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Classroom group chats'**
  String get studentChatHubSubtitle;

  /// No description provided for @studentChatHubSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search classes…'**
  String get studentChatHubSearchHint;

  /// No description provided for @studentChatHubFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get studentChatHubFilterAll;

  /// No description provided for @studentChatHubFilterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get studentChatHubFilterUnread;

  /// No description provided for @studentChatHubOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay connected'**
  String get studentChatHubOverviewTitle;

  /// No description provided for @studentChatHubOverviewBody.
  ///
  /// In en, this message translates to:
  /// **'Chat with your classmates and teachers in each class group.'**
  String get studentChatHubOverviewBody;

  /// No description provided for @studentChatHubSectionConversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get studentChatHubSectionConversations;

  /// No description provided for @studentChatHubUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String studentChatHubUnreadCount(int count);

  /// No description provided for @studentChatHubClassCount.
  ///
  /// In en, this message translates to:
  /// **'{count} classes'**
  String studentChatHubClassCount(int count);

  /// No description provided for @studentChatHubEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get studentChatHubEmptyTitle;

  /// No description provided for @studentChatHubEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Classrooms you join will appear here.'**
  String get studentChatHubEmptyBody;

  /// No description provided for @studentChatHubSearchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get studentChatHubSearchEmptyTitle;

  /// No description provided for @studentChatHubSearchEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Try another keyword or clear the search.'**
  String get studentChatHubSearchEmptyBody;

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

  /// No description provided for @loginEmailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Email or username'**
  String get loginEmailOrUsername;

  /// No description provided for @hintLoginEmailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or username'**
  String get hintLoginEmailOrUsername;

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
  /// **'Enter your password'**
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

  /// No description provided for @adminShellAppName.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminShellAppName;

  /// No description provided for @adminShellNavGroup.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get adminShellNavGroup;

  /// No description provided for @adminShellOpsGroup.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get adminShellOpsGroup;

  /// No description provided for @adminShellContentGroup.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get adminShellContentGroup;

  /// No description provided for @adminShellDesktopTitle.
  ///
  /// In en, this message translates to:
  /// **'Use a desktop browser'**
  String get adminShellDesktopTitle;

  /// No description provided for @adminShellDesktopBody.
  ///
  /// In en, this message translates to:
  /// **'The admin console is optimized for screens 768px and wider. Open this page on a laptop or desktop for the best experience.'**
  String get adminShellDesktopBody;

  /// No description provided for @adminShellCollapseSidebar.
  ///
  /// In en, this message translates to:
  /// **'Collapse sidebar'**
  String get adminShellCollapseSidebar;

  /// No description provided for @adminShellExpandSidebar.
  ///
  /// In en, this message translates to:
  /// **'Expand sidebar'**
  String get adminShellExpandSidebar;

  /// No description provided for @adminNavSubmissions.
  ///
  /// In en, this message translates to:
  /// **'Submissions'**
  String get adminNavSubmissions;

  /// No description provided for @adminNavOps.
  ///
  /// In en, this message translates to:
  /// **'Ops center'**
  String get adminNavOps;

  /// No description provided for @adminNavOpsSub.
  ///
  /// In en, this message translates to:
  /// **'Moderation, export, permissions'**
  String get adminNavOpsSub;

  /// No description provided for @adminNavReleases.
  ///
  /// In en, this message translates to:
  /// **'Releases'**
  String get adminNavReleases;

  /// No description provided for @adminNavReleasesSub.
  ///
  /// In en, this message translates to:
  /// **'Approve, schedule, publish'**
  String get adminNavReleasesSub;

  /// No description provided for @adminContentItemCount.
  ///
  /// In en, this message translates to:
  /// **'topics'**
  String get adminContentItemCount;

  /// No description provided for @adminListeningDictation.
  ///
  /// In en, this message translates to:
  /// **'Dictation'**
  String get adminListeningDictation;

  /// No description provided for @adminListeningDictationSub.
  ///
  /// In en, this message translates to:
  /// **'Listen and type (cues)'**
  String get adminListeningDictationSub;

  /// No description provided for @adminListeningComprehension.
  ///
  /// In en, this message translates to:
  /// **'Comprehension'**
  String get adminListeningComprehension;

  /// No description provided for @adminListeningComprehensionSub.
  ///
  /// In en, this message translates to:
  /// **'Multiple-choice listening quiz'**
  String get adminListeningComprehensionSub;

  /// No description provided for @adminOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get adminOverviewTitle;

  /// No description provided for @adminUserManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'User management'**
  String get adminUserManagementTitle;

  /// No description provided for @adminReportManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Report management'**
  String get adminReportManagementTitle;

  /// No description provided for @adminActivityHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Submission history'**
  String get adminActivityHistoryTitle;

  /// No description provided for @adminSearchUsersHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email…'**
  String get adminSearchUsersHint;

  /// No description provided for @adminSearchReportsHint.
  ///
  /// In en, this message translates to:
  /// **'Search by title or sender…'**
  String get adminSearchReportsHint;

  /// No description provided for @adminNoUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get adminNoUsersFound;

  /// No description provided for @adminNoReportsFound.
  ///
  /// In en, this message translates to:
  /// **'No reports in this status'**
  String get adminNoReportsFound;

  /// No description provided for @adminUsersTrash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get adminUsersTrash;

  /// No description provided for @adminUserRestored.
  ///
  /// In en, this message translates to:
  /// **'Restored {name}'**
  String adminUserRestored(String name);

  /// No description provided for @adminReportStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Status updated successfully'**
  String get adminReportStatusUpdated;

  /// No description provided for @adminActionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Action completed successfully'**
  String get adminActionSuccess;

  /// No description provided for @adminReleaseConfirmCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Confirmation code is incorrect'**
  String get adminReleaseConfirmCodeInvalid;

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
  /// **'E4C'**
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

  /// No description provided for @registerAccountTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get registerAccountTypeLabel;

  /// No description provided for @registerAccountTypeStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get registerAccountTypeStudent;

  /// No description provided for @registerAccountTypeTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get registerAccountTypeTeacher;

  /// No description provided for @registerAccountTypeTeacherHint.
  ///
  /// In en, this message translates to:
  /// **'You can create classes and manage exams right after signing up.'**
  String get registerAccountTypeTeacherHint;

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

  /// No description provided for @notificationAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get notificationAccept;

  /// No description provided for @notificationDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get notificationDecline;

  /// No description provided for @notificationInviteAccepted.
  ///
  /// In en, this message translates to:
  /// **'Invite accepted'**
  String get notificationInviteAccepted;

  /// No description provided for @notificationInviteDeclined.
  ///
  /// In en, this message translates to:
  /// **'Invite declined'**
  String get notificationInviteDeclined;

  /// No description provided for @notificationJoinApproved.
  ///
  /// In en, this message translates to:
  /// **'Join request approved'**
  String get notificationJoinApproved;

  /// No description provided for @notificationJoinDeclined.
  ///
  /// In en, this message translates to:
  /// **'Join request declined'**
  String get notificationJoinDeclined;

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

  /// No description provided for @changePhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to change photo'**
  String get changePhotoHint;

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

  /// No description provided for @dictationSaveContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & continue'**
  String get dictationSaveContinue;

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

  /// No description provided for @listeningCompPlayedOnce.
  ///
  /// In en, this message translates to:
  /// **'Played (1x only)'**
  String get listeningCompPlayedOnce;

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

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailableTitle;

  /// No description provided for @forceUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get forceUpdateTitle;

  /// No description provided for @updateAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'A new app version is available. Please update for the best experience.'**
  String get updateAvailableBody;

  /// No description provided for @updateNowButton.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNowButton;

  /// No description provided for @updateLaterButton.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLaterButton;

  /// No description provided for @updateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading... {progress}%'**
  String updateDownloading(int progress);

  /// No description provided for @updatePreparingInstall.
  ///
  /// In en, this message translates to:
  /// **'Preparing to install...'**
  String get updatePreparingInstall;

  /// No description provided for @updateDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed. Please try again.'**
  String get updateDownloadFailed;

  /// No description provided for @updateOpenInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get updateOpenInBrowser;

  /// No description provided for @updateRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get updateRetry;

  /// No description provided for @updateCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get updateCancel;

  /// No description provided for @updateDialogVersionLine.
  ///
  /// In en, this message translates to:
  /// **'{name} (+{code})'**
  String updateDialogVersionLine(String name, int code);

  /// No description provided for @updateDialogWhatsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'What is new'**
  String get updateDialogWhatsNewTitle;

  /// No description provided for @updateLinkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the update link.'**
  String get updateLinkOpenFailed;

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersionLabel;

  /// No description provided for @profileTeacherSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Classes & teaching'**
  String get profileTeacherSectionTitle;

  /// No description provided for @profileStudentClassesTitle.
  ///
  /// In en, this message translates to:
  /// **'My classes'**
  String get profileStudentClassesTitle;

  /// No description provided for @profileStudentClassesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join a class with an invite code'**
  String get profileStudentClassesSubtitle;

  /// No description provided for @profileTeacherHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher hub'**
  String get profileTeacherHubTitle;

  /// No description provided for @profileTeacherHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Classrooms and exams'**
  String get profileTeacherHubSubtitle;

  /// No description provided for @profileApplyTeacherTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply to teach'**
  String get profileApplyTeacherTitle;

  /// No description provided for @profileApplyTeacherSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Submit a request for a teacher account'**
  String get profileApplyTeacherSubtitle;

  /// No description provided for @teacherApplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Become a teacher'**
  String get teacherApplyTitle;

  /// No description provided for @teacherApplySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us briefly about your teaching background. An admin will review your request.'**
  String get teacherApplySubtitle;

  /// No description provided for @teacherApplyBioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get teacherApplyBioLabel;

  /// No description provided for @teacherApplyOrgLabel.
  ///
  /// In en, this message translates to:
  /// **'School or organization (optional)'**
  String get teacherApplyOrgLabel;

  /// No description provided for @teacherApplySubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit application'**
  String get teacherApplySubmit;

  /// No description provided for @teacherApplySubmitted.
  ///
  /// In en, this message translates to:
  /// **'Application submitted'**
  String get teacherApplySubmitted;

  /// No description provided for @teacherDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher hub'**
  String get teacherDashboardTitle;

  /// No description provided for @teacherNavDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get teacherNavDashboard;

  /// No description provided for @teacherNavExams.
  ///
  /// In en, this message translates to:
  /// **'Exam bank'**
  String get teacherNavExams;

  /// No description provided for @teacherShellAppName.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacherShellAppName;

  /// No description provided for @teacherShellNavGroup.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get teacherShellNavGroup;

  /// No description provided for @teacherShellDesktopTitle.
  ///
  /// In en, this message translates to:
  /// **'Use a desktop browser'**
  String get teacherShellDesktopTitle;

  /// No description provided for @teacherShellDesktopBody.
  ///
  /// In en, this message translates to:
  /// **'The teacher workspace is optimized for screens 768px and wider. Open this page on a laptop or desktop for the best experience.'**
  String get teacherShellDesktopBody;

  /// No description provided for @teacherShellCollapseSidebar.
  ///
  /// In en, this message translates to:
  /// **'Collapse sidebar'**
  String get teacherShellCollapseSidebar;

  /// No description provided for @teacherShellExpandSidebar.
  ///
  /// In en, this message translates to:
  /// **'Expand sidebar'**
  String get teacherShellExpandSidebar;

  /// No description provided for @teacherAccountMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Account & settings'**
  String get teacherAccountMenuTitle;

  /// No description provided for @teacherAccountRoleTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacherAccountRoleTeacher;

  /// No description provided for @teacherAccountSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get teacherAccountSectionAbout;

  /// No description provided for @teacherAccountOpenMenu.
  ///
  /// In en, this message translates to:
  /// **'Account menu'**
  String get teacherAccountOpenMenu;

  /// No description provided for @teacherAccountEditProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your name, avatar, and contact details.'**
  String get teacherAccountEditProfileSubtitle;

  /// No description provided for @adminAccountRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get adminAccountRoleAdmin;

  /// No description provided for @adminAccountOpenMenu.
  ///
  /// In en, this message translates to:
  /// **'Account menu'**
  String get adminAccountOpenMenu;

  /// No description provided for @adminUserRoleStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get adminUserRoleStudent;

  /// No description provided for @adminUserRoleTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get adminUserRoleTeacher;

  /// No description provided for @adminUserRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get adminUserRoleAdmin;

  /// No description provided for @adminUserStatusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get adminUserStatusOnline;

  /// No description provided for @adminUserStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get adminUserStatusOffline;

  /// No description provided for @adminUserActiveNow.
  ///
  /// In en, this message translates to:
  /// **'Active now'**
  String get adminUserActiveNow;

  /// No description provided for @adminUserNeverActive.
  ///
  /// In en, this message translates to:
  /// **'Never active'**
  String get adminUserNeverActive;

  /// No description provided for @adminUserLastActive.
  ///
  /// In en, this message translates to:
  /// **'Last active: {when}'**
  String adminUserLastActive(String when);

  /// No description provided for @teacherDashboardGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String teacherDashboardGreeting(String name);

  /// No description provided for @teacherDashboardTodayMeta.
  ///
  /// In en, this message translates to:
  /// **'Today · {time}'**
  String teacherDashboardTodayMeta(String time);

  /// No description provided for @teacherDashboardActionNewExam.
  ///
  /// In en, this message translates to:
  /// **'New exam'**
  String get teacherDashboardActionNewExam;

  /// No description provided for @teacherClassFab.
  ///
  /// In en, this message translates to:
  /// **'New class'**
  String get teacherClassFab;

  /// No description provided for @teacherClassCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create classroom'**
  String get teacherClassCreateTitle;

  /// No description provided for @teacherClassNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Class name'**
  String get teacherClassNameLabel;

  /// No description provided for @teacherClassCreated.
  ///
  /// In en, this message translates to:
  /// **'Classroom created'**
  String get teacherClassCreated;

  /// No description provided for @teacherMyClassrooms.
  ///
  /// In en, this message translates to:
  /// **'My classrooms'**
  String get teacherMyClassrooms;

  /// No description provided for @teacherNoClassrooms.
  ///
  /// In en, this message translates to:
  /// **'No classrooms yet. Create one with the + button.'**
  String get teacherNoClassrooms;

  /// No description provided for @teacherInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get teacherInviteCode;

  /// No description provided for @teacherClassroomDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Classroom'**
  String get teacherClassroomDetailTitle;

  /// No description provided for @teacherNoExams.
  ///
  /// In en, this message translates to:
  /// **'Create a sample exam from the Teacher hub first.'**
  String get teacherNoExams;

  /// No description provided for @teacherAssignmentCreated.
  ///
  /// In en, this message translates to:
  /// **'Exam assigned to this class'**
  String get teacherAssignmentCreated;

  /// No description provided for @teacherAssignFirstExam.
  ///
  /// In en, this message translates to:
  /// **'Assign latest exam to this class'**
  String get teacherAssignFirstExam;

  /// No description provided for @teacherClassroomMemberCountActive.
  ///
  /// In en, this message translates to:
  /// **'{count} students in this class'**
  String teacherClassroomMemberCountActive(int count);

  /// No description provided for @teacherClassroomMemberCountPending.
  ///
  /// In en, this message translates to:
  /// **'{count} awaiting approval'**
  String teacherClassroomMemberCountPending(int count);

  /// No description provided for @teacherAssignExamToClass.
  ///
  /// In en, this message translates to:
  /// **'Assign exam to this class'**
  String get teacherAssignExamToClass;

  /// No description provided for @teacherPickExamToAssign.
  ///
  /// In en, this message translates to:
  /// **'Choose a published exam'**
  String get teacherPickExamToAssign;

  /// No description provided for @teacherNoPublishedExams.
  ///
  /// In en, this message translates to:
  /// **'No published exams yet. Publish an exam under My exams first.'**
  String get teacherNoPublishedExams;

  /// No description provided for @copyInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Copy invite code'**
  String get copyInviteCode;

  /// No description provided for @teacherExamSessionShareTitle.
  ///
  /// In en, this message translates to:
  /// **'What to send students'**
  String get teacherExamSessionShareTitle;

  /// No description provided for @teacherExamSessionShareClassroom.
  ///
  /// In en, this message translates to:
  /// **'Students open their class, tap this assignment, then Enter waiting room. They do not paste any code here.'**
  String get teacherExamSessionShareClassroom;

  /// No description provided for @teacherExamSessionSharePublic.
  ///
  /// In en, this message translates to:
  /// **'Students open Public exam join and paste the join code below (not the room label or session link).'**
  String get teacherExamSessionSharePublic;

  /// No description provided for @teacherExamSessionSharePublicCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy public join code'**
  String get teacherExamSessionSharePublicCopy;

  /// No description provided for @teacherExamSessionRoomCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Room label (shown in lobby only — not used to join)'**
  String get teacherExamSessionRoomCodeHint;

  /// No description provided for @adminTeacherApplicationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher applications'**
  String get adminTeacherApplicationsTitle;

  /// No description provided for @adminTeacherApplicationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review pending requests'**
  String get adminTeacherApplicationsSubtitle;

  /// No description provided for @adminTeacherApplicationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No applications in this state.'**
  String get adminTeacherApplicationsEmpty;

  /// No description provided for @adminTeacherApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminTeacherApprove;

  /// No description provided for @adminTeacherReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adminTeacherReject;

  /// No description provided for @adminTeacherRejectReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection'**
  String get adminTeacherRejectReason;

  /// No description provided for @studentClassesTitle.
  ///
  /// In en, this message translates to:
  /// **'My classes'**
  String get studentClassesTitle;

  /// No description provided for @studentClassesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open a class to see only assignments from that class.'**
  String get studentClassesSubtitle;

  /// No description provided for @studentJoinClassTitle.
  ///
  /// In en, this message translates to:
  /// **'Join with invite code'**
  String get studentJoinClassTitle;

  /// No description provided for @studentUnifiedJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get studentUnifiedJoinTitle;

  /// No description provided for @studentUnifiedJoinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste any code or link — the app detects the type and opens the right place.'**
  String get studentUnifiedJoinSubtitle;

  /// No description provided for @studentUnifiedJoinHint.
  ///
  /// In en, this message translates to:
  /// **'Class code · class link · public exam · live session link…'**
  String get studentUnifiedJoinHint;

  /// No description provided for @studentUnifiedJoinCompactHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a code or link to join another class.'**
  String get studentUnifiedJoinCompactHint;

  /// No description provided for @studentUnifiedJoinButton.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get studentUnifiedJoinButton;

  /// No description provided for @studentJoinInputInvalid.
  ///
  /// In en, this message translates to:
  /// **'Could not recognize that code. Check with your teacher and try again.'**
  String get studentJoinInputInvalid;

  /// No description provided for @studentJoinDetectedClass.
  ///
  /// In en, this message translates to:
  /// **'Class invite detected — joining…'**
  String get studentJoinDetectedClass;

  /// No description provided for @studentJoinDetectedSession.
  ///
  /// In en, this message translates to:
  /// **'Live session detected — opening waiting room…'**
  String get studentJoinDetectedSession;

  /// No description provided for @studentJoinDetectedPublicExam.
  ///
  /// In en, this message translates to:
  /// **'Public exam detected — opening…'**
  String get studentJoinDetectedPublicExam;

  /// No description provided for @studentJoinClassSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the code from your teacher. Assignments will appear inside each class.'**
  String get studentJoinClassSubtitle;

  /// No description provided for @studentInviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get studentInviteCodeLabel;

  /// No description provided for @studentJoinClassButton.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get studentJoinClassButton;

  /// No description provided for @studentJoinClassSuccess.
  ///
  /// In en, this message translates to:
  /// **'Joined classroom'**
  String get studentJoinClassSuccess;

  /// No description provided for @studentMyClassesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your classrooms'**
  String get studentMyClassesTitle;

  /// No description provided for @studentClassesHubListHint.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 class — tap to open assignments and chat} other{{count} classes — tap to open assignments and chat}}'**
  String studentClassesHubListHint(int count);

  /// No description provided for @studentNoClasses.
  ///
  /// In en, this message translates to:
  /// **'You are not in any class yet.'**
  String get studentNoClasses;

  /// No description provided for @studentClassOpen.
  ///
  /// In en, this message translates to:
  /// **'Open class'**
  String get studentClassOpen;

  /// No description provided for @studentClassAssignmentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No assignments} one{1 assignment} other{{count} assignments}}'**
  String studentClassAssignmentsCount(int count);

  /// No description provided for @studentClassLiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 live} other{{count} live}}'**
  String studentClassLiveCount(int count);

  /// No description provided for @studentClassDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Classroom'**
  String get studentClassDetailTitle;

  /// No description provided for @studentClassDetailAssignmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Class assignments'**
  String get studentClassDetailAssignmentsTitle;

  /// No description provided for @studentClassDetailAssignmentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only assignments from this classroom are shown here.'**
  String get studentClassDetailAssignmentsSubtitle;

  /// No description provided for @studentClassNoAssignments.
  ///
  /// In en, this message translates to:
  /// **'This class does not have any assignments yet.'**
  String get studentClassNoAssignments;

  /// No description provided for @studentClassAssignmentNotYetOpen.
  ///
  /// In en, this message translates to:
  /// **'Not open yet — check the schedule from your teacher.'**
  String get studentClassAssignmentNotYetOpen;

  /// No description provided for @studentClassAssignmentClosed.
  ///
  /// In en, this message translates to:
  /// **'This assignment window has closed.'**
  String get studentClassAssignmentClosed;

  /// No description provided for @studentClassInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Class information'**
  String get studentClassInfoTitle;

  /// No description provided for @studentClassMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 active student} other{{count} active students}}'**
  String studentClassMemberCount(int count);

  /// No description provided for @studentClassJoinPolicyOpen.
  ///
  /// In en, this message translates to:
  /// **'Open join'**
  String get studentClassJoinPolicyOpen;

  /// No description provided for @studentClassJoinPolicyApproval.
  ///
  /// In en, this message translates to:
  /// **'Approval required'**
  String get studentClassJoinPolicyApproval;

  /// No description provided for @studentClassCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String studentClassCreatedAt(String date);

  /// No description provided for @studentClassUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String studentClassUpdatedAt(String date);

  /// No description provided for @studentClassScheduleDue.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String studentClassScheduleDue(String date);

  /// No description provided for @studentClassScheduleWindow.
  ///
  /// In en, this message translates to:
  /// **'{opens} – {closes}'**
  String studentClassScheduleWindow(String opens, String closes);

  /// No description provided for @studentClassPublicJoin.
  ///
  /// In en, this message translates to:
  /// **'Join public exam'**
  String get studentClassPublicJoin;

  /// No description provided for @studentClassTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher: {name}'**
  String studentClassTeacher(String name);

  /// No description provided for @studentClassNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description for this class.'**
  String get studentClassNoDescription;

  /// No description provided for @studentClassTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get studentClassTabOverview;

  /// No description provided for @studentClassTabAssignments.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get studentClassTabAssignments;

  /// No description provided for @studentClassTabMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get studentClassTabMembers;

  /// No description provided for @studentClassOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Class chat'**
  String get studentClassOpenChat;

  /// No description provided for @studentClassQuickActionChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get studentClassQuickActionChat;

  /// No description provided for @studentClassQuickActionAssignments.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get studentClassQuickActionAssignments;

  /// No description provided for @studentClassQuickActionMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get studentClassQuickActionMembers;

  /// No description provided for @studentClassSegmentOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get studentClassSegmentOpen;

  /// No description provided for @studentClassSegmentSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get studentClassSegmentSubmitted;

  /// No description provided for @studentClassSegmentClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get studentClassSegmentClosed;

  /// No description provided for @studentClassOverviewRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get studentClassOverviewRecentTitle;

  /// No description provided for @studentClassViewAllAssignments.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get studentClassViewAllAssignments;

  /// No description provided for @studentClassMembersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No members yet.'**
  String get studentClassMembersEmpty;

  /// No description provided for @studentClassMemberYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get studentClassMemberYou;

  /// No description provided for @studentClassMemberTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get studentClassMemberTeacher;

  /// No description provided for @studentClassMemberCoTeacher.
  ///
  /// In en, this message translates to:
  /// **'Co-teacher'**
  String get studentClassMemberCoTeacher;

  /// No description provided for @studentClassInviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get studentClassInviteCodeLabel;

  /// No description provided for @studentClassReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get studentClassReadMore;

  /// No description provided for @studentClassChatMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 member in chat} other{{count} members in chat}}'**
  String studentClassChatMemberCount(int count);

  /// No description provided for @studentClassOverviewActionHint.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 assignment needs your attention} other{{count} assignments need your attention}}'**
  String studentClassOverviewActionHint(int count);

  /// No description provided for @studentClassOverviewEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'When your teacher assigns work, it will show up here.'**
  String get studentClassOverviewEmptyBody;

  /// No description provided for @studentClassNoAssignmentsInSegment.
  ///
  /// In en, this message translates to:
  /// **'No assignments in this filter.'**
  String get studentClassNoAssignmentsInSegment;

  /// No description provided for @studentClassAssignmentsFilteredCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 assignment} other{{count} assignments}}'**
  String studentClassAssignmentsFilteredCount(int count);

  /// No description provided for @studentClassSegmentGraded.
  ///
  /// In en, this message translates to:
  /// **'Graded'**
  String get studentClassSegmentGraded;

  /// No description provided for @studentClassLiveBanner.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 live exam in progress — open Assignments} other{{count} live exams in progress — open Assignments}}'**
  String studentClassLiveBanner(int count);

  /// No description provided for @studentClassSortPriority.
  ///
  /// In en, this message translates to:
  /// **'Sort by priority'**
  String get studentClassSortPriority;

  /// No description provided for @studentClassSortDueDate.
  ///
  /// In en, this message translates to:
  /// **'Sort by due date'**
  String get studentClassSortDueDate;

  /// No description provided for @studentClassMembersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search members…'**
  String get studentClassMembersSearchHint;

  /// No description provided for @studentClassMembersNoResults.
  ///
  /// In en, this message translates to:
  /// **'No members match your search.'**
  String get studentClassMembersNoResults;

  /// No description provided for @studentClassMuteNotifications.
  ///
  /// In en, this message translates to:
  /// **'Mute notifications'**
  String get studentClassMuteNotifications;

  /// No description provided for @studentClassMuteNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device only.'**
  String get studentClassMuteNotificationsHint;

  /// No description provided for @studentClassLeaveAction.
  ///
  /// In en, this message translates to:
  /// **'Leave class'**
  String get studentClassLeaveAction;

  /// No description provided for @studentClassLeaveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this class?'**
  String get studentClassLeaveConfirmTitle;

  /// No description provided for @studentClassLeaveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You will lose access to assignments and chat for this class. Your teacher can invite you again.'**
  String get studentClassLeaveConfirmBody;

  /// No description provided for @studentClassLeaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'You left the class.'**
  String get studentClassLeaveSuccess;

  /// No description provided for @teacherClassDetailAssignmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Class assignments'**
  String get teacherClassDetailAssignmentsTitle;

  /// No description provided for @teacherClassDetailAssignmentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Exams assigned to this class — schedule, format, and student progress.'**
  String get teacherClassDetailAssignmentsSubtitle;

  /// No description provided for @teacherClassDetailActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Active assignments'**
  String get teacherClassDetailActiveTitle;

  /// No description provided for @teacherClassDetailActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open sessions and assignments students can still take.'**
  String get teacherClassDetailActiveSubtitle;

  /// No description provided for @teacherClassDetailHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Session history'**
  String get teacherClassDetailHistoryTitle;

  /// No description provided for @teacherClassDetailHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live exams whose latest session has ended.'**
  String get teacherClassDetailHistorySubtitle;

  /// No description provided for @teacherClassHistoryOpenGrading.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get teacherClassHistoryOpenGrading;

  /// No description provided for @teacherClassHistorySessionEnded.
  ///
  /// In en, this message translates to:
  /// **'Last session ended: {date}'**
  String teacherClassHistorySessionEnded(String date);

  /// No description provided for @teacherClassNoAssignments.
  ///
  /// In en, this message translates to:
  /// **'No exams assigned to this class yet.'**
  String get teacherClassNoAssignments;

  /// No description provided for @teacherClassNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No ended live sessions for this class yet.'**
  String get teacherClassNoHistory;

  /// No description provided for @teacherClassTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get teacherClassTabOverview;

  /// No description provided for @teacherClassTabAssignments.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get teacherClassTabAssignments;

  /// No description provided for @teacherClassTabMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get teacherClassTabMembers;

  /// No description provided for @teacherClassTabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get teacherClassTabSettings;

  /// No description provided for @teacherClassMembersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No members yet.'**
  String get teacherClassMembersEmpty;

  /// No description provided for @teacherClassMemberRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get teacherClassMemberRemove;

  /// No description provided for @teacherClassMemberRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this student from the class?'**
  String get teacherClassMemberRemoveConfirm;

  /// No description provided for @teacherClassMemberStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending approval'**
  String get teacherClassMemberStatusPending;

  /// No description provided for @teacherMembersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email…'**
  String get teacherMembersSearchHint;

  /// No description provided for @teacherMembersFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get teacherMembersFilterAll;

  /// No description provided for @teacherMembersFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get teacherMembersFilterActive;

  /// No description provided for @teacherMembersFilterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get teacherMembersFilterPending;

  /// No description provided for @teacherMembersStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get teacherMembersStatusPending;

  /// No description provided for @teacherMembersActiveSection.
  ///
  /// In en, this message translates to:
  /// **'Active members'**
  String get teacherMembersActiveSection;

  /// No description provided for @teacherMembersNoResults.
  ///
  /// In en, this message translates to:
  /// **'No members match your search.'**
  String get teacherMembersNoResults;

  /// No description provided for @teacherMembersEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Share the invite code to add students to this class.'**
  String get teacherMembersEmptyHint;

  /// No description provided for @teacherMembersInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get teacherMembersInvite;

  /// No description provided for @teacherMembersCopyInvite.
  ///
  /// In en, this message translates to:
  /// **'Copy invite code'**
  String get teacherMembersCopyInvite;

  /// No description provided for @teacherClassSaveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get teacherClassSaveSettings;

  /// No description provided for @teacherClassSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Classroom updated'**
  String get teacherClassSettingsSaved;

  /// No description provided for @teacherClassRotateInvite.
  ///
  /// In en, this message translates to:
  /// **'Rotate invite code'**
  String get teacherClassRotateInvite;

  /// No description provided for @teacherClassRotateInviteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Generate a new invite code? The old code will stop working.'**
  String get teacherClassRotateInviteConfirm;

  /// No description provided for @teacherClassArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive class'**
  String get teacherClassArchive;

  /// No description provided for @teacherClassArchiveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Archive this class? Students will no longer see new assignments here.'**
  String get teacherClassArchiveConfirm;

  /// No description provided for @teacherClassArchivedMessage.
  ///
  /// In en, this message translates to:
  /// **'Class archived'**
  String get teacherClassArchivedMessage;

  /// No description provided for @teacherExamArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive exam'**
  String get teacherExamArchive;

  /// No description provided for @teacherExamArchiveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Archive this exam? You cannot assign archived exams.'**
  String get teacherExamArchiveConfirm;

  /// No description provided for @teacherExamArchived.
  ///
  /// In en, this message translates to:
  /// **'Exam archived'**
  String get teacherExamArchived;

  /// No description provided for @teacherExamDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get teacherExamDelete;

  /// No description provided for @teacherExamDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this exam permanently? All assignments without submitted work will be removed. This cannot be undone.'**
  String get teacherExamDeleteConfirm;

  /// No description provided for @teacherExamDeleted.
  ///
  /// In en, this message translates to:
  /// **'Exam deleted'**
  String get teacherExamDeleted;

  /// No description provided for @teacherExamRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore exam'**
  String get teacherExamRestore;

  /// No description provided for @teacherExamRestoreConfirm.
  ///
  /// In en, this message translates to:
  /// **'Restore this exam from archive?'**
  String get teacherExamRestoreConfirm;

  /// No description provided for @teacherExamRestored.
  ///
  /// In en, this message translates to:
  /// **'Exam restored'**
  String get teacherExamRestored;

  /// No description provided for @teacherExamsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get teacherExamsFilterAll;

  /// No description provided for @teacherExamsFilterDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get teacherExamsFilterDraft;

  /// No description provided for @teacherExamsFilterPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get teacherExamsFilterPublished;

  /// No description provided for @teacherExamsFilterArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get teacherExamsFilterArchived;

  /// No description provided for @teacherExamsFilterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No exams in this filter.'**
  String get teacherExamsFilterEmpty;

  /// No description provided for @teacherExamPublishConfirm.
  ///
  /// In en, this message translates to:
  /// **'Publish this exam so you can assign it to classes?'**
  String get teacherExamPublishConfirm;

  /// No description provided for @teacherExamMoreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get teacherExamMoreActions;

  /// No description provided for @teacherAssignmentDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete assignment'**
  String get teacherAssignmentDelete;

  /// No description provided for @teacherAssignmentDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this assignment? Only allowed if no student has submitted yet.'**
  String get teacherAssignmentDeleteConfirm;

  /// No description provided for @teacherAssignmentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Assignment deleted'**
  String get teacherAssignmentDeleted;

  /// No description provided for @teacherAssignmentClose.
  ///
  /// In en, this message translates to:
  /// **'Close assignment'**
  String get teacherAssignmentClose;

  /// No description provided for @teacherAssignmentCloseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Close this assignment? Students can no longer start new attempts.'**
  String get teacherAssignmentCloseConfirm;

  /// No description provided for @teacherAssignmentClosed.
  ///
  /// In en, this message translates to:
  /// **'Assignment closed'**
  String get teacherAssignmentClosed;

  /// No description provided for @teacherAssignmentAudience.
  ///
  /// In en, this message translates to:
  /// **'Audience'**
  String get teacherAssignmentAudience;

  /// No description provided for @teacherAssignmentAudienceClassroom.
  ///
  /// In en, this message translates to:
  /// **'Classroom'**
  String get teacherAssignmentAudienceClassroom;

  /// No description provided for @teacherAssignmentAudienceClassroomHint.
  ///
  /// In en, this message translates to:
  /// **'Assign to a specific class'**
  String get teacherAssignmentAudienceClassroomHint;

  /// No description provided for @teacherAssignmentAudiencePublic.
  ///
  /// In en, this message translates to:
  /// **'Public link'**
  String get teacherAssignmentAudiencePublic;

  /// No description provided for @teacherAssignmentAudiencePublicHint.
  ///
  /// In en, this message translates to:
  /// **'Share a link students can join'**
  String get teacherAssignmentAudiencePublicHint;

  /// No description provided for @teacherAssignmentPublicMaxUsesHint.
  ///
  /// In en, this message translates to:
  /// **'Max uses (optional)'**
  String get teacherAssignmentPublicMaxUsesHint;

  /// No description provided for @teacherAssignmentPublicExpiresHint.
  ///
  /// In en, this message translates to:
  /// **'Pick expiry (optional)'**
  String get teacherAssignmentPublicExpiresHint;

  /// No description provided for @teacherAssignmentPublicTokenTitle.
  ///
  /// In en, this message translates to:
  /// **'Public join token'**
  String get teacherAssignmentPublicTokenTitle;

  /// No description provided for @teacherAssignmentPublicTokenBody.
  ///
  /// In en, this message translates to:
  /// **'Share this token with students. They paste it in “Join public exam” (or your shared instructions).'**
  String get teacherAssignmentPublicTokenBody;

  /// No description provided for @teacherAssignmentPublicRealtimeNextSteps.
  ///
  /// In en, this message translates to:
  /// **'A live waiting room was created automatically. Open the live console to monitor students, then start the exam when everyone is ready.'**
  String get teacherAssignmentPublicRealtimeNextSteps;

  /// No description provided for @teacherAssignmentOpenLiveConsole.
  ///
  /// In en, this message translates to:
  /// **'Open live console'**
  String get teacherAssignmentOpenLiveConsole;

  /// No description provided for @examPublicNoLiveSession.
  ///
  /// In en, this message translates to:
  /// **'The teacher has not opened a live room yet. Try again shortly.'**
  String get examPublicNoLiveSession;

  /// No description provided for @dashboardPublicCopyToken.
  ///
  /// In en, this message translates to:
  /// **'Copy token'**
  String get dashboardPublicCopyToken;

  /// No description provided for @dashboardPublicTokenCopied.
  ///
  /// In en, this message translates to:
  /// **'Token copied'**
  String get dashboardPublicTokenCopied;

  /// No description provided for @dashboardPublicRotateLink.
  ///
  /// In en, this message translates to:
  /// **'New link'**
  String get dashboardPublicRotateLink;

  /// No description provided for @dashboardPublicRotateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Generate a new public token? Old links will stop working.'**
  String get dashboardPublicRotateConfirm;

  /// No description provided for @dashboardPublicCloseLink.
  ///
  /// In en, this message translates to:
  /// **'Close link'**
  String get dashboardPublicCloseLink;

  /// No description provided for @dashboardPublicCloseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Close this public assignment? New participants cannot start.'**
  String get dashboardPublicCloseConfirm;

  /// No description provided for @teacherApplyStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Your application is pending review.'**
  String get teacherApplyStatusPending;

  /// No description provided for @teacherApplyStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'You are approved as a teacher. Open the teacher hub from your profile.'**
  String get teacherApplyStatusApproved;

  /// No description provided for @teacherApplyStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Your application was rejected.'**
  String get teacherApplyStatusRejected;

  /// No description provided for @teacherApplyStatusWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'You withdrew your application. You can submit a new one.'**
  String get teacherApplyStatusWithdrawn;

  /// No description provided for @teacherApplyStatusNone.
  ///
  /// In en, this message translates to:
  /// **'No application yet — tell us about yourself below.'**
  String get teacherApplyStatusNone;

  /// No description provided for @teacherApplyRejectReason.
  ///
  /// In en, this message translates to:
  /// **'Note from reviewer'**
  String get teacherApplyRejectReason;

  /// No description provided for @teacherApplyWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw application'**
  String get teacherApplyWithdraw;

  /// No description provided for @teacherApplyWithdrawConfirm.
  ///
  /// In en, this message translates to:
  /// **'Withdraw your pending application?'**
  String get teacherApplyWithdrawConfirm;

  /// No description provided for @teacherApplyGoToHub.
  ///
  /// In en, this message translates to:
  /// **'Open teacher hub'**
  String get teacherApplyGoToHub;

  /// No description provided for @homeQuickMyClasses.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get homeQuickMyClasses;

  /// No description provided for @homeQuickPublicExam.
  ///
  /// In en, this message translates to:
  /// **'Public exam'**
  String get homeQuickPublicExam;

  /// No description provided for @studentJoinClassByTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite link token'**
  String get studentJoinClassByTokenLabel;

  /// No description provided for @studentJoinClassByTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the long token from your teacher’s class link (not a live exam session link)'**
  String get studentJoinClassByTokenHint;

  /// No description provided for @studentJoinClassByTokenButton.
  ///
  /// In en, this message translates to:
  /// **'Join with link'**
  String get studentJoinClassByTokenButton;

  /// No description provided for @studentJoinClassOpeningExamLobby.
  ///
  /// In en, this message translates to:
  /// **'That is a live exam link — opening the waiting room…'**
  String get studentJoinClassOpeningExamLobby;

  /// No description provided for @studentJoinClassUsePublicExamLink.
  ///
  /// In en, this message translates to:
  /// **'That is a public exam join code. Use «Join via public link» below.'**
  String get studentJoinClassUsePublicExamLink;

  /// No description provided for @studentExamsHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Public exam join'**
  String get studentExamsHubTitle;

  /// No description provided for @studentExamsHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Class assignments stay inside each class. Use this screen only when you have a public exam token from your teacher.'**
  String get studentExamsHubSubtitle;

  /// No description provided for @studentExamTimeRemainingHM.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String studentExamTimeRemainingHM(int hours, int minutes);

  /// No description provided for @studentExamTimeRemainingMS.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m {seconds}s'**
  String studentExamTimeRemainingMS(int minutes, int seconds);

  /// No description provided for @studentExamTimeRemainingS.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String studentExamTimeRemainingS(int seconds);

  /// No description provided for @studentExamRunnerLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this exam.'**
  String get studentExamRunnerLoadFailed;

  /// No description provided for @teacherMobileWorkspaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher hub'**
  String get teacherMobileWorkspaceTitle;

  /// No description provided for @teacherMobileWorkspaceBody.
  ///
  /// In en, this message translates to:
  /// **'Use the tabs below for quick navigation. For complex exam editing, a wider screen is recommended.'**
  String get teacherMobileWorkspaceBody;

  /// No description provided for @teacherClassOverviewMeta.
  ///
  /// In en, this message translates to:
  /// **'{students} students · {policy}'**
  String teacherClassOverviewMeta(int students, String policy);

  /// No description provided for @teacherClassStatActiveAssignments.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get teacherClassStatActiveAssignments;

  /// No description provided for @teacherClassStatHistoryAssignments.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get teacherClassStatHistoryAssignments;

  /// No description provided for @teacherClassStatStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get teacherClassStatStudents;

  /// No description provided for @teacherClassStatPendingMembers.
  ///
  /// In en, this message translates to:
  /// **'Pending join'**
  String get teacherClassStatPendingMembers;

  /// No description provided for @teacherClassCreatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get teacherClassCreatedLabel;

  /// No description provided for @teacherClassUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get teacherClassUpdatedLabel;

  /// No description provided for @teacherClassInviteCardHint.
  ///
  /// In en, this message translates to:
  /// **'Share this code so students can join the class.'**
  String get teacherClassInviteCardHint;

  /// No description provided for @teacherClassRecentAssignments.
  ///
  /// In en, this message translates to:
  /// **'Recent assignments'**
  String get teacherClassRecentAssignments;

  /// No description provided for @teacherClassViewAllAssignments.
  ///
  /// In en, this message translates to:
  /// **'View all assignments'**
  String get teacherClassViewAllAssignments;

  /// No description provided for @teacherClassSettingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About this class'**
  String get teacherClassSettingsAbout;

  /// No description provided for @teacherClassSettingsJoin.
  ///
  /// In en, this message translates to:
  /// **'Join settings'**
  String get teacherClassSettingsJoin;

  /// No description provided for @teacherClassAssignExamCta.
  ///
  /// In en, this message translates to:
  /// **'Assign an exam'**
  String get teacherClassAssignExamCta;

  /// No description provided for @examCardFormatClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic exam'**
  String get examCardFormatClassic;

  /// No description provided for @examCardFormatIntegrated.
  ///
  /// In en, this message translates to:
  /// **'Integrated 4 skills'**
  String get examCardFormatIntegrated;

  /// No description provided for @examCardFormatSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills + Grammar'**
  String get examCardFormatSkills;

  /// No description provided for @examCardScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get examCardScheduleTitle;

  /// No description provided for @examCardExamInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Exam details'**
  String get examCardExamInfoTitle;

  /// No description provided for @examCardQuestionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} questions'**
  String examCardQuestionsCount(int count);

  /// No description provided for @examCardPointsMax.
  ///
  /// In en, this message translates to:
  /// **'Max {points} pts'**
  String examCardPointsMax(int points);

  /// No description provided for @examCardGrammarSkillsCount.
  ///
  /// In en, this message translates to:
  /// **'{grammar} grammar · {skills} skill parts'**
  String examCardGrammarSkillsCount(int grammar, int skills);

  /// No description provided for @examCardAssignedAt.
  ///
  /// In en, this message translates to:
  /// **'Assigned {date}'**
  String examCardAssignedAt(String date);

  /// No description provided for @examCardRoomCode.
  ///
  /// In en, this message translates to:
  /// **'Room code: {code}'**
  String examCardRoomCode(String code);

  /// No description provided for @examCardOpensAt.
  ///
  /// In en, this message translates to:
  /// **'Opens {date}'**
  String examCardOpensAt(String date);

  /// No description provided for @examCardClosesAt.
  ///
  /// In en, this message translates to:
  /// **'Closes {date}'**
  String examCardClosesAt(String date);

  /// No description provided for @examCardSessionStarted.
  ///
  /// In en, this message translates to:
  /// **'Session started {date}'**
  String examCardSessionStarted(String date);

  /// No description provided for @examCardStatusLobby.
  ///
  /// In en, this message translates to:
  /// **'Lobby open — waiting to go live'**
  String get examCardStatusLobby;

  /// No description provided for @examCardStatusLive.
  ///
  /// In en, this message translates to:
  /// **'Live now'**
  String get examCardStatusLive;

  /// No description provided for @examCardMyAttemptInProgress.
  ///
  /// In en, this message translates to:
  /// **'You have a draft in progress'**
  String get examCardMyAttemptInProgress;

  /// No description provided for @examCardMyAttemptSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted — results pending'**
  String get examCardMyAttemptSubmitted;

  /// No description provided for @examCardMyAttemptVoid.
  ///
  /// In en, this message translates to:
  /// **'Attempt voided'**
  String get examCardMyAttemptVoid;

  /// No description provided for @examCardMyAttemptScore.
  ///
  /// In en, this message translates to:
  /// **'Score: {awarded} / {max}'**
  String examCardMyAttemptScore(num awarded, num max);

  /// No description provided for @examCardTeacherNoAttempts.
  ///
  /// In en, this message translates to:
  /// **'No student attempts yet'**
  String get examCardTeacherNoAttempts;

  /// No description provided for @examCardTeacherAttemptsSummary.
  ///
  /// In en, this message translates to:
  /// **'{submitted} submitted · {inProgress} in progress · {total} total'**
  String examCardTeacherAttemptsSummary(
      int submitted, int inProgress, int total);

  /// No description provided for @examCardManageSession.
  ///
  /// In en, this message translates to:
  /// **'Open session'**
  String get examCardManageSession;

  /// No description provided for @studentExamsPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assignments from your classes are listed inside each class. Use a public link only when your teacher shared one.'**
  String get studentExamsPageSubtitle;

  /// No description provided for @studentExamsGoToClasses.
  ///
  /// In en, this message translates to:
  /// **'Go to my classes'**
  String get studentExamsGoToClasses;

  /// No description provided for @studentExamsMenu.
  ///
  /// In en, this message translates to:
  /// **'Exams'**
  String get studentExamsMenu;

  /// No description provided for @studentExamsTitle.
  ///
  /// In en, this message translates to:
  /// **'Available exams'**
  String get studentExamsTitle;

  /// No description provided for @studentNoExams.
  ///
  /// In en, this message translates to:
  /// **'No exams available for your classes.'**
  String get studentNoExams;

  /// No description provided for @studentExamStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get studentExamStart;

  /// No description provided for @studentExamResume.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get studentExamResume;

  /// No description provided for @studentExamResumeHint.
  ///
  /// In en, this message translates to:
  /// **'In progress — tap to continue'**
  String get studentExamResumeHint;

  /// No description provided for @examCardAlreadySubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get examCardAlreadySubmitted;

  /// No description provided for @studentExamUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get studentExamUnknownTitle;

  /// No description provided for @studentExamRunnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get studentExamRunnerTitle;

  /// No description provided for @studentExamSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit answers'**
  String get studentExamSubmit;

  /// No description provided for @studentExamSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get studentExamSubmitted;

  /// No description provided for @studentExamScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get studentExamScore;

  /// No description provided for @studentExamQuestionProgress.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String studentExamQuestionProgress(int current, int total);

  /// No description provided for @studentExamPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get studentExamPrevious;

  /// No description provided for @studentExamNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get studentExamNext;

  /// No description provided for @studentExamItemUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This question type cannot be answered in the app yet. Skip or contact your teacher.'**
  String get studentExamItemUnsupported;

  /// No description provided for @studentExamEssayPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Write your answer here…'**
  String get studentExamEssayPlaceholder;

  /// No description provided for @studentExamScoreTotals.
  ///
  /// In en, this message translates to:
  /// **'Score: {earned} / {max}'**
  String studentExamScoreTotals(Object earned, Object max);

  /// No description provided for @studentExamNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'This exam has no questions you can answer here yet.'**
  String get studentExamNoQuestions;

  /// No description provided for @examModeSelfPaced.
  ///
  /// In en, this message translates to:
  /// **'Self-paced'**
  String get examModeSelfPaced;

  /// No description provided for @examModeScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get examModeScheduled;

  /// No description provided for @examModeRealtime.
  ///
  /// In en, this message translates to:
  /// **'Live session'**
  String get examModeRealtime;

  /// No description provided for @examOpenLobby.
  ///
  /// In en, this message translates to:
  /// **'Enter lobby'**
  String get examOpenLobby;

  /// No description provided for @examWaitingForTeacher.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the teacher to start'**
  String get examWaitingForTeacher;

  /// No description provided for @examCardLiveSessionEnded.
  ///
  /// In en, this message translates to:
  /// **'The teacher has ended this live session.'**
  String get examCardLiveSessionEnded;

  /// No description provided for @examCardLiveSessionEndedAt.
  ///
  /// In en, this message translates to:
  /// **'Session ended: {date}'**
  String examCardLiveSessionEndedAt(String date);

  /// No description provided for @examCardViewMySubmission.
  ///
  /// In en, this message translates to:
  /// **'View my submission'**
  String get examCardViewMySubmission;

  /// No description provided for @examSessionEndedByTeacher.
  ///
  /// In en, this message translates to:
  /// **'The teacher ended this live session. Your answers were saved.'**
  String get examSessionEndedByTeacher;

  /// No description provided for @examJoinByLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Join with public link'**
  String get examJoinByLinkTitle;

  /// No description provided for @examJoinByLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the token from your teacher'**
  String get examJoinByLinkHint;

  /// No description provided for @examJoinByLinkHintDetail.
  ///
  /// In en, this message translates to:
  /// **'Use the long join code from your teacher (about 36 characters). Do not paste a /student/exam-session/ link here.'**
  String get examJoinByLinkHintDetail;

  /// No description provided for @examJoinWrongSessionLink.
  ///
  /// In en, this message translates to:
  /// **'That looks like a live session link, not a public join code. Ask your teacher for the join token shown when the assignment was created.'**
  String get examJoinWrongSessionLink;

  /// No description provided for @examJoinInvalidToken.
  ///
  /// In en, this message translates to:
  /// **'Could not read a join code. Paste only the token from your teacher.'**
  String get examJoinInvalidToken;

  /// No description provided for @examJoinPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get examJoinPreview;

  /// No description provided for @examJoinStart.
  ///
  /// In en, this message translates to:
  /// **'Start exam'**
  String get examJoinStart;

  /// No description provided for @examSessionRoomCode.
  ///
  /// In en, this message translates to:
  /// **'Room code'**
  String get examSessionRoomCode;

  /// No description provided for @examSessionGo.
  ///
  /// In en, this message translates to:
  /// **'Open exam'**
  String get examSessionGo;

  /// No description provided for @studentExamLeaveRealtimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this exam?'**
  String get studentExamLeaveRealtimeTitle;

  /// No description provided for @studentExamLeaveRealtimeMessage.
  ///
  /// In en, this message translates to:
  /// **'If you leave now, you cannot return to this live exam. Your attempt will be closed.'**
  String get studentExamLeaveRealtimeMessage;

  /// No description provided for @studentExamLeaveRealtimeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave exam'**
  String get studentExamLeaveRealtimeConfirm;

  /// No description provided for @studentExamLeaveRealtimeCancel.
  ///
  /// In en, this message translates to:
  /// **'Keep working'**
  String get studentExamLeaveRealtimeCancel;

  /// No description provided for @studentRunnerExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this exercise?'**
  String get studentRunnerExitTitle;

  /// No description provided for @studentRunnerExitMessage.
  ///
  /// In en, this message translates to:
  /// **'Your progress may be lost if you leave now.'**
  String get studentRunnerExitMessage;

  /// No description provided for @studentRunnerExitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get studentRunnerExitConfirm;

  /// No description provided for @studentRunnerExitCancel.
  ///
  /// In en, this message translates to:
  /// **'Keep working'**
  String get studentRunnerExitCancel;

  /// No description provided for @studentAudioPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get studentAudioPlay;

  /// No description provided for @studentAudioPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get studentAudioPause;

  /// No description provided for @studentExamVoluntaryExitBlocked.
  ///
  /// In en, this message translates to:
  /// **'You left this exam and cannot re-enter.'**
  String get studentExamVoluntaryExitBlocked;

  /// No description provided for @studentExamCannotRejoinAfterLeave.
  ///
  /// In en, this message translates to:
  /// **'You cannot rejoin this exam after leaving.'**
  String get studentExamCannotRejoinAfterLeave;

  /// No description provided for @teacherExamSessionLeavePageHint.
  ///
  /// In en, this message translates to:
  /// **'Leaving this page does not end the exam for students. End the session here when you are ready to finish.'**
  String get teacherExamSessionLeavePageHint;

  /// No description provided for @teacherAssignmentsSection.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get teacherAssignmentsSection;

  /// No description provided for @teacherNoAssignments.
  ///
  /// In en, this message translates to:
  /// **'No assignments yet.'**
  String get teacherNoAssignments;

  /// No description provided for @teacherDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Classes, exams, and grading in one calm workspace.'**
  String get teacherDashboardSubtitle;

  /// No description provided for @teacherDashboardOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get teacherDashboardOverview;

  /// No description provided for @teacherDashboardWorkZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s focus'**
  String get teacherDashboardWorkZoneTitle;

  /// No description provided for @teacherDashboardWorkZoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Grading queue and live rooms side by side — tap a KPI above to jump here.'**
  String get teacherDashboardWorkZoneSubtitle;

  /// No description provided for @teacherDashboardQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get teacherDashboardQuickActionsTitle;

  /// No description provided for @teacherDashboardAssignmentHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search, filter, and open assignment hubs.'**
  String get teacherDashboardAssignmentHubSubtitle;

  /// No description provided for @teacherDashboardPendingJoinsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending joins'**
  String teacherDashboardPendingJoinsCount(int count);

  /// No description provided for @teacherDashboardDueSoonCount.
  ///
  /// In en, this message translates to:
  /// **'{count} due soon'**
  String teacherDashboardDueSoonCount(int count);

  /// No description provided for @teacherDashboardStatClasses.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get teacherDashboardStatClasses;

  /// No description provided for @teacherDashboardStatStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get teacherDashboardStatStudents;

  /// No description provided for @teacherDashboardStatAssignments.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get teacherDashboardStatAssignments;

  /// No description provided for @teacherDashboardStatLiveModes.
  ///
  /// In en, this message translates to:
  /// **'Live mode'**
  String get teacherDashboardStatLiveModes;

  /// No description provided for @teacherDashboardStatDraftExams.
  ///
  /// In en, this message translates to:
  /// **'Draft exams'**
  String get teacherDashboardStatDraftExams;

  /// No description provided for @teacherDashboardStatPublishedExams.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get teacherDashboardStatPublishedExams;

  /// No description provided for @teacherDashboardStatNeedsAction.
  ///
  /// In en, this message translates to:
  /// **'Needs action'**
  String get teacherDashboardStatNeedsAction;

  /// No description provided for @teacherDashboardShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get teacherDashboardShortcuts;

  /// No description provided for @teacherDashboardShortcutExamBank.
  ///
  /// In en, this message translates to:
  /// **'Exam bank'**
  String get teacherDashboardShortcutExamBank;

  /// No description provided for @teacherDashboardShortcutNewSkillsExam.
  ///
  /// In en, this message translates to:
  /// **'New skills exam'**
  String get teacherDashboardShortcutNewSkillsExam;

  /// No description provided for @teacherDashboardShortcutOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get teacherDashboardShortcutOpen;

  /// No description provided for @teacherDashboardSectionLive.
  ///
  /// In en, this message translates to:
  /// **'Live sessions'**
  String get teacherDashboardSectionLive;

  /// No description provided for @teacherDashboardLiveEmpty.
  ///
  /// In en, this message translates to:
  /// **'No realtime assignments yet. Assign an exam in Live mode to run a session.'**
  String get teacherDashboardLiveEmpty;

  /// No description provided for @teacherDashboardLiveWaitingSession.
  ///
  /// In en, this message translates to:
  /// **'No active session — open console to start'**
  String get teacherDashboardLiveWaitingSession;

  /// No description provided for @teacherDashboardLiveStatusGrading.
  ///
  /// In en, this message translates to:
  /// **'Ending session'**
  String get teacherDashboardLiveStatusGrading;

  /// No description provided for @teacherDashboardLiveSessionStatus.
  ///
  /// In en, this message translates to:
  /// **'Session: {status}'**
  String teacherDashboardLiveSessionStatus(String status);

  /// No description provided for @teacherDashboardSectionGrading.
  ///
  /// In en, this message translates to:
  /// **'Grading queue'**
  String get teacherDashboardSectionGrading;

  /// No description provided for @teacherDashboardViewAllQueue.
  ///
  /// In en, this message translates to:
  /// **'View all ({count})'**
  String teacherDashboardViewAllQueue(int count);

  /// No description provided for @teacherDashboardViewAllQueueShort.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get teacherDashboardViewAllQueueShort;

  /// No description provided for @teacherDashboardQueueMoreHidden.
  ///
  /// In en, this message translates to:
  /// **'+{count} more in queue'**
  String teacherDashboardQueueMoreHidden(int count);

  /// No description provided for @teacherDashboardGradingQueueAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending grading'**
  String get teacherDashboardGradingQueueAllTitle;

  /// No description provided for @teacherDashboardGradingQueueAllSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} submissions need your action'**
  String teacherDashboardGradingQueueAllSubtitle(int count);

  /// No description provided for @teacherDashboardViewAllLiveQueue.
  ///
  /// In en, this message translates to:
  /// **'All live rooms ({count})'**
  String teacherDashboardViewAllLiveQueue(int count);

  /// No description provided for @teacherDashboardLiveQueueAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Live sessions'**
  String get teacherDashboardLiveQueueAllTitle;

  /// No description provided for @teacherDashboardLiveQueueAllSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} realtime assignments in progress'**
  String teacherDashboardLiveQueueAllSubtitle(int count);

  /// No description provided for @teacherDashboardScrollHint.
  ///
  /// In en, this message translates to:
  /// **'Scroll sideways to browse rooms'**
  String get teacherDashboardScrollHint;

  /// No description provided for @teacherDashboardGradingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No submitted attempts need your attention right now.'**
  String get teacherDashboardGradingEmpty;

  /// No description provided for @teacherDashboardGradingLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading grading queue…'**
  String get teacherDashboardGradingLoading;

  /// No description provided for @teacherDashboardSectionAssignments.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get teacherDashboardSectionAssignments;

  /// No description provided for @teacherDashboardAssignmentsPerClassHint.
  ///
  /// In en, this message translates to:
  /// **'Filter by class — manage history inside each class.'**
  String get teacherDashboardAssignmentsPerClassHint;

  /// No description provided for @teacherDashboardFilterByClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get teacherDashboardFilterByClass;

  /// No description provided for @teacherDashboardAllClasses.
  ///
  /// In en, this message translates to:
  /// **'All classes'**
  String get teacherDashboardAllClasses;

  /// No description provided for @teacherDashboardFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get teacherDashboardFilterAll;

  /// No description provided for @teacherDashboardFilterPublic.
  ///
  /// In en, this message translates to:
  /// **'Public link'**
  String get teacherDashboardFilterPublic;

  /// No description provided for @teacherDashboardSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by exam title'**
  String get teacherDashboardSearchHint;

  /// No description provided for @teacherDashboardAudienceClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get teacherDashboardAudienceClass;

  /// No description provided for @teacherDashboardAudiencePublic.
  ///
  /// In en, this message translates to:
  /// **'Public link'**
  String get teacherDashboardAudiencePublic;

  /// No description provided for @teacherDashboardDue.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String teacherDashboardDue(String date);

  /// No description provided for @teacherDashboardWindow.
  ///
  /// In en, this message translates to:
  /// **'{opens} – {closes}'**
  String teacherDashboardWindow(String opens, String closes);

  /// No description provided for @teacherDashboardClassLabel.
  ///
  /// In en, this message translates to:
  /// **'Class: {name}'**
  String teacherDashboardClassLabel(String name);

  /// No description provided for @teacherInboxPublicAssignment.
  ///
  /// In en, this message translates to:
  /// **'Public assignment'**
  String get teacherInboxPublicAssignment;

  /// No description provided for @teacherInboxItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String teacherInboxItemCount(int count);

  /// No description provided for @teacherDashboardOpenConsole.
  ///
  /// In en, this message translates to:
  /// **'Open console'**
  String get teacherDashboardOpenConsole;

  /// No description provided for @teacherDashboardOpenGrading.
  ///
  /// In en, this message translates to:
  /// **'Open grading'**
  String get teacherDashboardOpenGrading;

  /// No description provided for @teacherDashboardStudentUnknown.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get teacherDashboardStudentUnknown;

  /// No description provided for @teacherDashboardGradingChipManual.
  ///
  /// In en, this message translates to:
  /// **'Manual grading'**
  String get teacherDashboardGradingChipManual;

  /// No description provided for @teacherDashboardGradingChipAi.
  ///
  /// In en, this message translates to:
  /// **'AI grading'**
  String get teacherDashboardGradingChipAi;

  /// No description provided for @teacherDashboardGradingChipRelease.
  ///
  /// In en, this message translates to:
  /// **'Release results'**
  String get teacherDashboardGradingChipRelease;

  /// No description provided for @teacherExamConsoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Live exam session'**
  String get teacherExamConsoleTitle;

  /// No description provided for @teacherExamSessionLiveRosterTitle.
  ///
  /// In en, this message translates to:
  /// **'Students in lobby'**
  String get teacherExamSessionLiveRosterTitle;

  /// No description provided for @teacherExamSessionLiveRosterTitleLive.
  ///
  /// In en, this message translates to:
  /// **'Students in exam'**
  String get teacherExamSessionLiveRosterTitleLive;

  /// No description provided for @teacherExamSessionLiveRosterHint.
  ///
  /// In en, this message translates to:
  /// **'Count and list update in real time when students join the waiting room.'**
  String get teacherExamSessionLiveRosterHint;

  /// No description provided for @teacherExamParticipantNotReady.
  ///
  /// In en, this message translates to:
  /// **'Not ready'**
  String get teacherExamParticipantNotReady;

  /// No description provided for @teacherExamParticipantReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get teacherExamParticipantReady;

  /// No description provided for @teacherExamParticipantInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get teacherExamParticipantInProgress;

  /// No description provided for @teacherExamParticipantSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get teacherExamParticipantSubmitted;

  /// No description provided for @teacherExamParticipantExpired.
  ///
  /// In en, this message translates to:
  /// **'Time expired'**
  String get teacherExamParticipantExpired;

  /// No description provided for @teacherExamParticipantVoided.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get teacherExamParticipantVoided;

  /// No description provided for @teacherExamSessionJoinedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 student joined} other{{count} students joined}}'**
  String teacherExamSessionJoinedCount(int count);

  /// No description provided for @teacherExamSessionNoParticipantsYet.
  ///
  /// In en, this message translates to:
  /// **'No students in the lobby yet.'**
  String get teacherExamSessionNoParticipantsYet;

  /// No description provided for @teacherExamSessionTabControl.
  ///
  /// In en, this message translates to:
  /// **'Session control'**
  String get teacherExamSessionTabControl;

  /// No description provided for @teacherExamSessionTabLiveMonitor.
  ///
  /// In en, this message translates to:
  /// **'Live monitor'**
  String get teacherExamSessionTabLiveMonitor;

  /// No description provided for @teacherExamSessionShowDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get teacherExamSessionShowDetails;

  /// No description provided for @teacherExamSessionHideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get teacherExamSessionHideDetails;

  /// No description provided for @teacherLiveMonitorSummaryInProgress.
  ///
  /// In en, this message translates to:
  /// **'{count} in progress'**
  String teacherLiveMonitorSummaryInProgress(int count);

  /// No description provided for @teacherLiveMonitorSummarySubmitted.
  ///
  /// In en, this message translates to:
  /// **'{count} submitted'**
  String teacherLiveMonitorSummarySubmitted(int count);

  /// No description provided for @teacherLiveMonitorSummaryFlagged.
  ///
  /// In en, this message translates to:
  /// **'{count} flagged'**
  String teacherLiveMonitorSummaryFlagged(int count);

  /// No description provided for @teacherLiveMonitorSummaryAvgProgress.
  ///
  /// In en, this message translates to:
  /// **'Avg. {percent}%'**
  String teacherLiveMonitorSummaryAvgProgress(double percent);

  /// No description provided for @teacherLiveMonitorSummaryLine.
  ///
  /// In en, this message translates to:
  /// **'{inProgress} in progress · {submitted} submitted · {flagged} flagged · avg {avg}%'**
  String teacherLiveMonitorSummaryLine(
      int inProgress, int submitted, int flagged, String avg);

  /// No description provided for @teacherLiveMonitorFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get teacherLiveMonitorFilterAll;

  /// No description provided for @teacherLiveMonitorFilterInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get teacherLiveMonitorFilterInProgress;

  /// No description provided for @teacherLiveMonitorFilterSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get teacherLiveMonitorFilterSubmitted;

  /// No description provided for @teacherLiveMonitorFilterFlagged.
  ///
  /// In en, this message translates to:
  /// **'Flagged'**
  String get teacherLiveMonitorFilterFlagged;

  /// No description provided for @teacherLiveMonitorNoStudents.
  ///
  /// In en, this message translates to:
  /// **'No students match this filter.'**
  String get teacherLiveMonitorNoStudents;

  /// No description provided for @teacherLiveMonitorProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'{answered}/{total} · {percent}%'**
  String teacherLiveMonitorProgressLabel(
      int answered, int total, double percent);

  /// No description provided for @teacherLiveMonitorIntegrityHigh.
  ///
  /// In en, this message translates to:
  /// **'High integrity risk'**
  String get teacherLiveMonitorIntegrityHigh;

  /// No description provided for @teacherLiveMonitorIntegrityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium integrity risk'**
  String get teacherLiveMonitorIntegrityMedium;

  /// No description provided for @teacherLiveMonitorCurrentQuestion.
  ///
  /// In en, this message translates to:
  /// **'Current focus'**
  String get teacherLiveMonitorCurrentQuestion;

  /// No description provided for @teacherLiveMonitorStatusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get teacherLiveMonitorStatusSubmitted;

  /// No description provided for @teacherLiveMonitorIntegrityLabel.
  ///
  /// In en, this message translates to:
  /// **'Integrity'**
  String get teacherLiveMonitorIntegrityLabel;

  /// No description provided for @teacherLiveMonitorTabSwitches.
  ///
  /// In en, this message translates to:
  /// **'Tab switches'**
  String get teacherLiveMonitorTabSwitches;

  /// No description provided for @teacherLiveMonitorFocusLoss.
  ///
  /// In en, this message translates to:
  /// **'Focus loss'**
  String get teacherLiveMonitorFocusLoss;

  /// No description provided for @teacherLiveMonitorCopyPaste.
  ///
  /// In en, this message translates to:
  /// **'Copy/paste'**
  String get teacherLiveMonitorCopyPaste;

  /// No description provided for @teacherLiveMonitorDetailProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get teacherLiveMonitorDetailProgress;

  /// No description provided for @teacherLiveMonitorDetailSections.
  ///
  /// In en, this message translates to:
  /// **'Skill sections'**
  String get teacherLiveMonitorDetailSections;

  /// No description provided for @teacherLiveMonitorDetailGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar answers'**
  String get teacherLiveMonitorDetailGrammar;

  /// No description provided for @teacherLiveMonitorGrammarQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get teacherLiveMonitorGrammarQuestion;

  /// No description provided for @teacherLiveMonitorGrammarNotAnswered.
  ///
  /// In en, this message translates to:
  /// **'Not answered'**
  String get teacherLiveMonitorGrammarNotAnswered;

  /// No description provided for @teacherLiveMonitorGrammarCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get teacherLiveMonitorGrammarCorrect;

  /// No description provided for @teacherLiveMonitorGrammarWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong'**
  String get teacherLiveMonitorGrammarWrong;

  /// No description provided for @teacherLiveMonitorWatchScreen.
  ///
  /// In en, this message translates to:
  /// **'Watch live screen'**
  String get teacherLiveMonitorWatchScreen;

  /// No description provided for @teacherLiveMonitorQuestionStripLegend.
  ///
  /// In en, this message translates to:
  /// **'Green: correct · Red: wrong · Gray: not answered yet'**
  String get teacherLiveMonitorQuestionStripLegend;

  /// No description provided for @teacherLiveMirrorPageTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} — {exam}'**
  String teacherLiveMirrorPageTitle(String name, String exam);

  /// No description provided for @teacherLiveMirrorPageTitleSimple.
  ///
  /// In en, this message translates to:
  /// **'Live view — {name}'**
  String teacherLiveMirrorPageTitleSimple(String name);

  /// No description provided for @teacherLiveMirrorLiveBadge.
  ///
  /// In en, this message translates to:
  /// **'Live — mirroring student screen'**
  String get teacherLiveMirrorLiveBadge;

  /// No description provided for @teacherLiveMirrorNoContent.
  ///
  /// In en, this message translates to:
  /// **'No exam content to display.'**
  String get teacherLiveMirrorNoContent;

  /// No description provided for @teacherLiveMirrorWritingDraft.
  ///
  /// In en, this message translates to:
  /// **'Writing draft (live)'**
  String get teacherLiveMirrorWritingDraft;

  /// No description provided for @teacherLiveMirrorWritingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Student has not started writing yet.'**
  String get teacherLiveMirrorWritingEmpty;

  /// No description provided for @teacherLiveMirrorWordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} words'**
  String teacherLiveMirrorWordCount(int count);

  /// No description provided for @teacherLiveMirrorSkillCompleted.
  ///
  /// In en, this message translates to:
  /// **'Skill section marked complete'**
  String get teacherLiveMirrorSkillCompleted;

  /// No description provided for @teacherLiveMirrorSkillInProgress.
  ///
  /// In en, this message translates to:
  /// **'Working on {skill}…'**
  String teacherLiveMirrorSkillInProgress(String skill);

  /// No description provided for @teacherLiveMirrorBrowsingPart.
  ///
  /// In en, this message translates to:
  /// **'Viewing: {part}'**
  String teacherLiveMirrorBrowsingPart(String part);

  /// No description provided for @teacherLiveMirrorFollowStudent.
  ///
  /// In en, this message translates to:
  /// **'Follow student'**
  String get teacherLiveMirrorFollowStudent;

  /// No description provided for @teacherLiveMirrorQuestionMap.
  ///
  /// In en, this message translates to:
  /// **'Question map'**
  String get teacherLiveMirrorQuestionMap;

  /// No description provided for @teacherLiveMirrorWritingPrompt.
  ///
  /// In en, this message translates to:
  /// **'Exam prompt'**
  String get teacherLiveMirrorWritingPrompt;

  /// No description provided for @teacherLiveMirrorListeningEmpty.
  ///
  /// In en, this message translates to:
  /// **'Student has not entered any dictation yet.'**
  String get teacherLiveMirrorListeningEmpty;

  /// No description provided for @teacherLiveMirrorListeningProgress.
  ///
  /// In en, this message translates to:
  /// **'Dictation progress: {saved} / {total} cues'**
  String teacherLiveMirrorListeningProgress(int saved, int total);

  /// No description provided for @teacherLiveMirrorListeningCue.
  ///
  /// In en, this message translates to:
  /// **'Cue {number}'**
  String teacherLiveMirrorListeningCue(int number);

  /// No description provided for @teacherLiveMirrorSpeakingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Student is doing the speaking exercise.'**
  String get teacherLiveMirrorSpeakingInProgress;

  /// No description provided for @teacherLiveMirrorReadingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Student has not answered any reading questions yet.'**
  String get teacherLiveMirrorReadingEmpty;

  /// No description provided for @teacherLiveMirrorReadingQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question {number}'**
  String teacherLiveMirrorReadingQuestion(int number);

  /// No description provided for @teacherLiveMirrorExerciseLabel.
  ///
  /// In en, this message translates to:
  /// **'Exercise {index}/{total}'**
  String teacherLiveMirrorExerciseLabel(int index, int total);

  /// No description provided for @examSessionStatusLobby.
  ///
  /// In en, this message translates to:
  /// **'Waiting room (lobby)'**
  String get examSessionStatusLobby;

  /// No description provided for @examSessionStatusLive.
  ///
  /// In en, this message translates to:
  /// **'Exam in progress'**
  String get examSessionStatusLive;

  /// No description provided for @examSessionStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Session ended'**
  String get examSessionStatusClosed;

  /// No description provided for @examSessionStatusCanceled.
  ///
  /// In en, this message translates to:
  /// **'Session canceled'**
  String get examSessionStatusCanceled;

  /// No description provided for @examSessionCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Session created {date}'**
  String examSessionCreatedAt(String date);

  /// No description provided for @examSessionScheduledEndAt.
  ///
  /// In en, this message translates to:
  /// **'Scheduled end: {date}'**
  String examSessionScheduledEndAt(String date);

  /// No description provided for @examSessionTimeLimitOnStart.
  ///
  /// In en, this message translates to:
  /// **'Time limit: {minutes} min (timer starts when you start the session)'**
  String examSessionTimeLimitOnStart(int minutes);

  /// No description provided for @examSessionEndsWhenTeacherEnds.
  ///
  /// In en, this message translates to:
  /// **'No time limit — ends when you end the session'**
  String get examSessionEndsWhenTeacherEnds;

  /// No description provided for @examSessionReadyCount.
  ///
  /// In en, this message translates to:
  /// **'{ready} ready · {total} in lobby'**
  String examSessionReadyCount(int ready, int total);

  /// No description provided for @examSessionStudentReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get examSessionStudentReady;

  /// No description provided for @examSessionStudentNotReady.
  ///
  /// In en, this message translates to:
  /// **'Not ready'**
  String get examSessionStudentNotReady;

  /// No description provided for @examSessionMarkReady.
  ///
  /// In en, this message translates to:
  /// **'I\'m ready'**
  String get examSessionMarkReady;

  /// No description provided for @examSessionMarkNotReady.
  ///
  /// In en, this message translates to:
  /// **'Not ready yet'**
  String get examSessionMarkNotReady;

  /// No description provided for @examSessionCancelReady.
  ///
  /// In en, this message translates to:
  /// **'Cancel ready'**
  String get examSessionCancelReady;

  /// No description provided for @examSessionReadyHint.
  ///
  /// In en, this message translates to:
  /// **'Tell your teacher you are ready to start. This updates in real time.'**
  String get examSessionReadyHint;

  /// No description provided for @examSessionKickStudentTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove student?'**
  String get examSessionKickStudentTitle;

  /// No description provided for @examSessionKickStudentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this exam room? They will leave the lobby immediately.'**
  String examSessionKickStudentConfirm(String name);

  /// No description provided for @examSessionKickStudentAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get examSessionKickStudentAction;

  /// No description provided for @examSessionKickStudentDone.
  ///
  /// In en, this message translates to:
  /// **'Student removed from the room.'**
  String get examSessionKickStudentDone;

  /// No description provided for @examSessionKickedByTeacher.
  ///
  /// In en, this message translates to:
  /// **'Your teacher removed you from this exam session.'**
  String get examSessionKickedByTeacher;

  /// No description provided for @examSessionLobbyParticipantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get examSessionLobbyParticipantsTitle;

  /// No description provided for @examSessionLobbyParticipantsHint.
  ///
  /// In en, this message translates to:
  /// **'Who has joined this waiting room (live).'**
  String get examSessionLobbyParticipantsHint;

  /// No description provided for @teacherExamCreateSession.
  ///
  /// In en, this message translates to:
  /// **'Create / refresh lobby'**
  String get teacherExamCreateSession;

  /// No description provided for @teacherExamStartSession.
  ///
  /// In en, this message translates to:
  /// **'Start for everyone'**
  String get teacherExamStartSession;

  /// No description provided for @teacherExamEndSession.
  ///
  /// In en, this message translates to:
  /// **'End and submit all'**
  String get teacherExamEndSession;

  /// No description provided for @teacherExamEndSessionConfirm.
  ///
  /// In en, this message translates to:
  /// **'This ends the session and force-submits every student\'s attempt — including those still in progress. This can\'t be undone.'**
  String get teacherExamEndSessionConfirm;

  /// No description provided for @teacherExamEndSessionTypePrompt.
  ///
  /// In en, this message translates to:
  /// **'Type {count} to confirm force-submit for all students in this session.'**
  String teacherExamEndSessionTypePrompt(int count);

  /// No description provided for @teacherEmptyInboxCta.
  ///
  /// In en, this message translates to:
  /// **'View classes'**
  String get teacherEmptyInboxCta;

  /// No description provided for @teacherEmptyCalendarCta.
  ///
  /// In en, this message translates to:
  /// **'Create new exam'**
  String get teacherEmptyCalendarCta;

  /// No description provided for @teacherEmptyGradebookCta.
  ///
  /// In en, this message translates to:
  /// **'Open classroom'**
  String get teacherEmptyGradebookCta;

  /// No description provided for @teacherSaveStateSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get teacherSaveStateSaving;

  /// No description provided for @teacherSaveStateSavedAt.
  ///
  /// In en, this message translates to:
  /// **'Saved {time}'**
  String teacherSaveStateSavedAt(String time);

  /// No description provided for @teacherSaveStateError.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get teacherSaveStateError;

  /// No description provided for @teacherSaveStateRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get teacherSaveStateRetry;

  /// No description provided for @teacherExamValidationBanner.
  ///
  /// In en, this message translates to:
  /// **'Fix the errors below before publishing.'**
  String get teacherExamValidationBanner;

  /// No description provided for @teacherExamGradingTitle.
  ///
  /// In en, this message translates to:
  /// **'Grading'**
  String get teacherExamGradingTitle;

  /// No description provided for @teacherExamRunAi.
  ///
  /// In en, this message translates to:
  /// **'AI suggestions'**
  String get teacherExamRunAi;

  /// No description provided for @teacherExamReleaseResults.
  ///
  /// In en, this message translates to:
  /// **'Release results'**
  String get teacherExamReleaseResults;

  /// No description provided for @teacherExamGradingConsole.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get teacherExamGradingConsole;

  /// No description provided for @teacherExamGradingGrade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get teacherExamGradingGrade;

  /// No description provided for @teacherMyExamsTitle.
  ///
  /// In en, this message translates to:
  /// **'My exams'**
  String get teacherMyExamsTitle;

  /// No description provided for @teacherExamNewExam.
  ///
  /// In en, this message translates to:
  /// **'New exam'**
  String get teacherExamNewExam;

  /// No description provided for @teacherExamsListEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have no exams yet. Tap + to create a draft.'**
  String get teacherExamsListEmpty;

  /// No description provided for @teacherExamUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled exam'**
  String get teacherExamUntitled;

  /// No description provided for @teacherExamStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get teacherExamStatusDraft;

  /// No description provided for @teacherExamStatusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get teacherExamStatusPublished;

  /// No description provided for @teacherExamStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get teacherExamStatusArchived;

  /// No description provided for @teacherExamEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit exam'**
  String get teacherExamEditorTitle;

  /// No description provided for @teacherExamSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get teacherExamSaveDraft;

  /// No description provided for @teacherExamPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get teacherExamPublish;

  /// No description provided for @teacherExamAddMcq.
  ///
  /// In en, this message translates to:
  /// **'MCQ'**
  String get teacherExamAddMcq;

  /// No description provided for @teacherExamAddEssay.
  ///
  /// In en, this message translates to:
  /// **'Essay'**
  String get teacherExamAddEssay;

  /// No description provided for @teacherExamStemLabel.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get teacherExamStemLabel;

  /// No description provided for @teacherExamOptionsHint.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get teacherExamOptionsHint;

  /// No description provided for @teacherExamOptionsPipeHint.
  ///
  /// In en, this message translates to:
  /// **'Separate options with |'**
  String get teacherExamOptionsPipeHint;

  /// No description provided for @teacherExamCorrectIndex.
  ///
  /// In en, this message translates to:
  /// **'Correct option index (0-based)'**
  String get teacherExamCorrectIndex;

  /// No description provided for @teacherExamEssayPrompt.
  ///
  /// In en, this message translates to:
  /// **'Essay prompt'**
  String get teacherExamEssayPrompt;

  /// No description provided for @teacherExamPoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get teacherExamPoints;

  /// No description provided for @teacherExamItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get teacherExamItemsTitle;

  /// No description provided for @teacherExamNoItemsHint.
  ///
  /// In en, this message translates to:
  /// **'Add at least one question before publishing.'**
  String get teacherExamNoItemsHint;

  /// No description provided for @teacherExamPublishNeedItems.
  ///
  /// In en, this message translates to:
  /// **'Add at least one question before publishing.'**
  String get teacherExamPublishNeedItems;

  /// No description provided for @teacherExamDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get teacherExamDraftSaved;

  /// No description provided for @teacherExamPublished.
  ///
  /// In en, this message translates to:
  /// **'Exam published'**
  String get teacherExamPublished;

  /// No description provided for @teacherExamOnlyDraftEditable.
  ///
  /// In en, this message translates to:
  /// **'Only draft exams can be edited here.'**
  String get teacherExamOnlyDraftEditable;

  /// No description provided for @teacherExamReadOnlyPublished.
  ///
  /// In en, this message translates to:
  /// **'This exam is published. Create a new draft to change content.'**
  String get teacherExamReadOnlyPublished;

  /// No description provided for @teacherExamTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get teacherExamTitleLabel;

  /// No description provided for @teacherExamTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Midterm — Reading & Listening'**
  String get teacherExamTitleHint;

  /// No description provided for @teacherExamDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get teacherExamDescriptionLabel;

  /// No description provided for @teacherExamResultsPolicy.
  ///
  /// In en, this message translates to:
  /// **'When students see results'**
  String get teacherExamResultsPolicy;

  /// No description provided for @teacherExamPolicyAfterSubmit.
  ///
  /// In en, this message translates to:
  /// **'Right after submit (if auto-graded)'**
  String get teacherExamPolicyAfterSubmit;

  /// No description provided for @teacherExamPolicyAfterRelease.
  ///
  /// In en, this message translates to:
  /// **'After teacher releases grades'**
  String get teacherExamPolicyAfterRelease;

  /// No description provided for @teacherExamPolicyNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get teacherExamPolicyNever;

  /// No description provided for @teacherAssignmentWizardTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign exam'**
  String get teacherAssignmentWizardTitle;

  /// No description provided for @teacherAssignExamDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose class, delivery mode, and schedule.'**
  String get teacherAssignExamDialogSubtitle;

  /// No description provided for @teacherAssignExamDialogSubtitleExam.
  ///
  /// In en, this message translates to:
  /// **'Assign “{examTitle}” to a class or link.'**
  String teacherAssignExamDialogSubtitleExam(String examTitle);

  /// No description provided for @teacherAssignExamModeHintSelfPaced.
  ///
  /// In en, this message translates to:
  /// **'Students start anytime before the due date.'**
  String get teacherAssignExamModeHintSelfPaced;

  /// No description provided for @teacherAssignExamModeHintScheduled.
  ///
  /// In en, this message translates to:
  /// **'Fixed open and close times (markers on Schedule).'**
  String get teacherAssignExamModeHintScheduled;

  /// No description provided for @teacherAssignExamModeHintRealtime.
  ///
  /// In en, this message translates to:
  /// **'Live session: open a room in class, or set a time so students know when to join.'**
  String get teacherAssignExamModeHintRealtime;

  /// No description provided for @teacherAssignExamModeHintPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice only — no official grading.'**
  String get teacherAssignExamModeHintPractice;

  /// No description provided for @teacherAssignExamRealtimeNote.
  ///
  /// In en, this message translates to:
  /// **'Open the live room from the dashboard when you are ready. The per-attempt timer starts when you press Start; students are auto-submitted when time runs out.'**
  String get teacherAssignExamRealtimeNote;

  /// No description provided for @teacherAssignExamCalendarNote.
  ///
  /// In en, this message translates to:
  /// **'Open, Due, and Close appear on Schedule. “Ongoing” on the calendar means the window is open, not a live room.'**
  String get teacherAssignExamCalendarNote;

  /// No description provided for @teacherAssignExamAdvancedRules.
  ///
  /// In en, this message translates to:
  /// **'Attempts & results'**
  String get teacherAssignExamAdvancedRules;

  /// No description provided for @teacherAssignExamAdvancedRulesHint.
  ///
  /// In en, this message translates to:
  /// **'Attempts, when students see scores, partial submit'**
  String get teacherAssignExamAdvancedRulesHint;

  /// No description provided for @teacherAssignExamRulesShow.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get teacherAssignExamRulesShow;

  /// No description provided for @teacherAssignExamRulesHide.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get teacherAssignExamRulesHide;

  /// No description provided for @teacherAssignmentClassroom.
  ///
  /// In en, this message translates to:
  /// **'Classroom'**
  String get teacherAssignmentClassroom;

  /// No description provided for @teacherAssignmentPickClass.
  ///
  /// In en, this message translates to:
  /// **'Select a classroom.'**
  String get teacherAssignmentPickClass;

  /// No description provided for @teacherAssignmentMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get teacherAssignmentMode;

  /// No description provided for @teacherAssignmentDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date (optional)'**
  String get teacherAssignmentDueDate;

  /// No description provided for @teacherAssignmentOpensAt.
  ///
  /// In en, this message translates to:
  /// **'Opens at'**
  String get teacherAssignmentOpensAt;

  /// No description provided for @teacherAssignmentClosesAt.
  ///
  /// In en, this message translates to:
  /// **'Closes at'**
  String get teacherAssignmentClosesAt;

  /// No description provided for @teacherAssignmentTimeLimitSec.
  ///
  /// In en, this message translates to:
  /// **'Time limit (seconds, optional)'**
  String get teacherAssignmentTimeLimitSec;

  /// No description provided for @teacherAssignmentTimeLimitMinutes.
  ///
  /// In en, this message translates to:
  /// **'Time limit per attempt (minutes)'**
  String get teacherAssignmentTimeLimitMinutes;

  /// No description provided for @teacherAssignmentTimeLimitMinutesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 60'**
  String get teacherAssignmentTimeLimitMinutesHint;

  /// No description provided for @teacherAssignmentTimeLimitHelp.
  ///
  /// In en, this message translates to:
  /// **'Countdown starts when the student begins (or when you start a live session). Leave empty for no per-attempt timer — only due date / exam window applies.'**
  String get teacherAssignmentTimeLimitHelp;

  /// No description provided for @teacherAssignmentTimeLimitPresetMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String teacherAssignmentTimeLimitPresetMinutes(int minutes);

  /// No description provided for @teacherAssignmentCreate.
  ///
  /// In en, this message translates to:
  /// **'Create assignment'**
  String get teacherAssignmentCreate;

  /// No description provided for @teacherAssignmentExamNotPublished.
  ///
  /// In en, this message translates to:
  /// **'Publish the exam first, then assign it.'**
  String get teacherAssignmentExamNotPublished;

  /// No description provided for @teacherAssignmentOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get teacherAssignmentOptional;

  /// No description provided for @teacherAssignmentAllowPartialSubmit.
  ///
  /// In en, this message translates to:
  /// **'Allow submit before finishing all parts'**
  String get teacherAssignmentAllowPartialSubmit;

  /// No description provided for @teacherAssignmentAllowPartialSubmitHint.
  ///
  /// In en, this message translates to:
  /// **'Students may submit with unfinished sections; those sections score zero.'**
  String get teacherAssignmentAllowPartialSubmitHint;

  /// No description provided for @teacherAssignmentSectionAudience.
  ///
  /// In en, this message translates to:
  /// **'Audience'**
  String get teacherAssignmentSectionAudience;

  /// No description provided for @teacherAssignmentSectionDelivery.
  ///
  /// In en, this message translates to:
  /// **'Schedule & mode'**
  String get teacherAssignmentSectionDelivery;

  /// No description provided for @teacherAssignmentSectionRules.
  ///
  /// In en, this message translates to:
  /// **'Attempts & results'**
  String get teacherAssignmentSectionRules;

  /// No description provided for @teacherAssignmentAttemptPolicy.
  ///
  /// In en, this message translates to:
  /// **'Attempts per student'**
  String get teacherAssignmentAttemptPolicy;

  /// No description provided for @teacherAssignmentAttemptSingle.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get teacherAssignmentAttemptSingle;

  /// No description provided for @teacherAssignmentAttemptUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get teacherAssignmentAttemptUnlimited;

  /// No description provided for @teacherAssignmentAttemptLimited.
  ///
  /// In en, this message translates to:
  /// **'Limited'**
  String get teacherAssignmentAttemptLimited;

  /// No description provided for @teacherAssignmentMaxAttempts.
  ///
  /// In en, this message translates to:
  /// **'Max attempts'**
  String get teacherAssignmentMaxAttempts;

  /// No description provided for @teacherAssignmentShowResults.
  ///
  /// In en, this message translates to:
  /// **'When students see results'**
  String get teacherAssignmentShowResults;

  /// No description provided for @examPartialSubmitTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit incomplete exam?'**
  String get examPartialSubmitTitle;

  /// No description provided for @examPartialSubmitMessage.
  ///
  /// In en, this message translates to:
  /// **'You have not finished every part. Unfinished sections will receive no points.'**
  String get examPartialSubmitMessage;

  /// No description provided for @examPartialSubmitIncompleteHeader.
  ///
  /// In en, this message translates to:
  /// **'Still incomplete:'**
  String get examPartialSubmitIncompleteHeader;

  /// No description provided for @examPartialSubmitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Submit anyway'**
  String get examPartialSubmitConfirm;

  /// No description provided for @teacherGradingHubFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get teacherGradingHubFilterAll;

  /// No description provided for @teacherGradingHubFilterInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get teacherGradingHubFilterInProgress;

  /// No description provided for @teacherGradingHubFilterSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get teacherGradingHubFilterSubmitted;

  /// No description provided for @teacherGradingHubFilterPendingManual.
  ///
  /// In en, this message translates to:
  /// **'Needs grading'**
  String get teacherGradingHubFilterPendingManual;

  /// No description provided for @teacherGradingHubFilterFinalized.
  ///
  /// In en, this message translates to:
  /// **'Graded'**
  String get teacherGradingHubFilterFinalized;

  /// No description provided for @teacherGradingHubFilterReleased.
  ///
  /// In en, this message translates to:
  /// **'Released'**
  String get teacherGradingHubFilterReleased;

  /// No description provided for @teacherGradingHubFilterPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial submit'**
  String get teacherGradingHubFilterPartial;

  /// No description provided for @teacherGradingHubPartialBadge.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get teacherGradingHubPartialBadge;

  /// No description provided for @teacherGradingHubForceEndBadge.
  ///
  /// In en, this message translates to:
  /// **'Session ended'**
  String get teacherGradingHubForceEndBadge;

  /// No description provided for @teacherGradingHubBatchAi.
  ///
  /// In en, this message translates to:
  /// **'AI grade all submitted'**
  String get teacherGradingHubBatchAi;

  /// No description provided for @teacherGradingHubBatchAiDone.
  ///
  /// In en, this message translates to:
  /// **'AI grading finished for submitted attempts'**
  String get teacherGradingHubBatchAiDone;

  /// No description provided for @teacherGradingHubNotReleased.
  ///
  /// In en, this message translates to:
  /// **'Not released'**
  String get teacherGradingHubNotReleased;

  /// No description provided for @teacherGradingHubScoreLine.
  ///
  /// In en, this message translates to:
  /// **'Score: {awarded} / {max}'**
  String teacherGradingHubScoreLine(String awarded, String max);

  /// No description provided for @teacherGradingHubSubmittedAt.
  ///
  /// In en, this message translates to:
  /// **'Submitted {date}'**
  String teacherGradingHubSubmittedAt(String date);

  /// No description provided for @teacherGradingHubStatsLine.
  ///
  /// In en, this message translates to:
  /// **'{submitted} submitted · {inProgress} in progress · {partial} partial'**
  String teacherGradingHubStatsLine(int submitted, int inProgress, int partial);

  /// No description provided for @teacherGradingHubEmpty.
  ///
  /// In en, this message translates to:
  /// **'No attempts for this assignment yet.'**
  String get teacherGradingHubEmpty;

  /// No description provided for @teacherGradingHubOpenGrade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get teacherGradingHubOpenGrade;

  /// No description provided for @teacherGradingHubBatchRelease.
  ///
  /// In en, this message translates to:
  /// **'Release all graded'**
  String get teacherGradingHubBatchRelease;

  /// No description provided for @teacherGradingHubBatchReleaseDone.
  ///
  /// In en, this message translates to:
  /// **'Results released for submitted attempts'**
  String get teacherGradingHubBatchReleaseDone;

  /// No description provided for @teacherGradingHubBatchFinalize.
  ///
  /// In en, this message translates to:
  /// **'Finalize all submitted'**
  String get teacherGradingHubBatchFinalize;

  /// No description provided for @teacherGradingHubBatchFinalizeDone.
  ///
  /// In en, this message translates to:
  /// **'Submitted attempts finalized'**
  String get teacherGradingHubBatchFinalizeDone;

  /// No description provided for @teacherGradingHubExportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export scores to Excel'**
  String get teacherGradingHubExportExcel;

  /// No description provided for @teacherGradingHubExportDone.
  ///
  /// In en, this message translates to:
  /// **'Excel file downloaded'**
  String get teacherGradingHubExportDone;

  /// No description provided for @teacherGradingHubExportEmpty.
  ///
  /// In en, this message translates to:
  /// **'No student attempts to export'**
  String get teacherGradingHubExportEmpty;

  /// No description provided for @teacherGradingHubExportMobileHint.
  ///
  /// In en, this message translates to:
  /// **'Excel export on mobile: open teacher web app or use file: {filename}'**
  String teacherGradingHubExportMobileHint(String filename);

  /// No description provided for @teacherGradingHubExportMobileCopied.
  ///
  /// In en, this message translates to:
  /// **'Export is available on web; hint copied'**
  String get teacherGradingHubExportMobileCopied;

  /// No description provided for @teacherExamDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get teacherExamDuplicate;

  /// No description provided for @teacherExamDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Exam duplicated as draft'**
  String get teacherExamDuplicated;

  /// No description provided for @teacherAssignmentDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate assignment'**
  String get teacherAssignmentDuplicate;

  /// No description provided for @teacherAssignmentDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Assignment duplicated'**
  String get teacherAssignmentDuplicated;

  /// No description provided for @teacherAssignmentExtendDeadline.
  ///
  /// In en, this message translates to:
  /// **'Extend deadline'**
  String get teacherAssignmentExtendDeadline;

  /// No description provided for @teacherAssignmentDeadlineSaved.
  ///
  /// In en, this message translates to:
  /// **'Deadline updated'**
  String get teacherAssignmentDeadlineSaved;

  /// No description provided for @teacherMemberApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get teacherMemberApprove;

  /// No description provided for @teacherMemberReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get teacherMemberReject;

  /// No description provided for @teacherMemberApproved.
  ///
  /// In en, this message translates to:
  /// **'Student approved'**
  String get teacherMemberApproved;

  /// No description provided for @teacherMemberRejected.
  ///
  /// In en, this message translates to:
  /// **'Request declined'**
  String get teacherMemberRejected;

  /// No description provided for @teacherGradebookTitle.
  ///
  /// In en, this message translates to:
  /// **'Gradebook'**
  String get teacherGradebookTitle;

  /// No description provided for @teacherGradebookStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get teacherGradebookStudent;

  /// No description provided for @teacherGradebookExport.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get teacherGradebookExport;

  /// No description provided for @teacherGradebookExportCopied.
  ///
  /// In en, this message translates to:
  /// **'Gradebook copied to clipboard (paste into Excel)'**
  String get teacherGradebookExportCopied;

  /// No description provided for @teacherGradebookExportDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Gradebook CSV downloaded'**
  String get teacherGradebookExportDownloaded;

  /// No description provided for @teacherGradebookNoAssignments.
  ///
  /// In en, this message translates to:
  /// **'No assignments in this class yet.'**
  String get teacherGradebookNoAssignments;

  /// No description provided for @teacherGradebookKpiStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get teacherGradebookKpiStudents;

  /// No description provided for @teacherGradebookKpiAssignments.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get teacherGradebookKpiAssignments;

  /// No description provided for @teacherGradebookKpiClassAvg.
  ///
  /// In en, this message translates to:
  /// **'Class average'**
  String get teacherGradebookKpiClassAvg;

  /// No description provided for @teacherGradebookKpiPending.
  ///
  /// In en, this message translates to:
  /// **'Cells to grade'**
  String get teacherGradebookKpiPending;

  /// No description provided for @teacherGradebookSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search student name or email'**
  String get teacherGradebookSearchHint;

  /// No description provided for @teacherGradebookFilterMode.
  ///
  /// In en, this message translates to:
  /// **'Assignment mode'**
  String get teacherGradebookFilterMode;

  /// No description provided for @teacherGradebookFilterAllModes.
  ///
  /// In en, this message translates to:
  /// **'All modes'**
  String get teacherGradebookFilterAllModes;

  /// No description provided for @teacherGradebookSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get teacherGradebookSortLabel;

  /// No description provided for @teacherGradebookSortName.
  ///
  /// In en, this message translates to:
  /// **'Name A→Z'**
  String get teacherGradebookSortName;

  /// No description provided for @teacherGradebookSortAvg.
  ///
  /// In en, this message translates to:
  /// **'Avg score'**
  String get teacherGradebookSortAvg;

  /// No description provided for @teacherGradebookHideEmpty.
  ///
  /// In en, this message translates to:
  /// **'Hide students with no submissions'**
  String get teacherGradebookHideEmpty;

  /// No description provided for @teacherGradebookShowingCount.
  ///
  /// In en, this message translates to:
  /// **'Showing {count} students'**
  String teacherGradebookShowingCount(int count);

  /// No description provided for @teacherGradebookNoStudentsMatch.
  ///
  /// In en, this message translates to:
  /// **'No students match your filters.'**
  String get teacherGradebookNoStudentsMatch;

  /// No description provided for @teacherGradebookNoColumnsForFilter.
  ///
  /// In en, this message translates to:
  /// **'No assignments for this mode in this class.'**
  String get teacherGradebookNoColumnsForFilter;

  /// No description provided for @teacherGradebookColAvg.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get teacherGradebookColAvg;

  /// No description provided for @teacherGradebookClassAverage.
  ///
  /// In en, this message translates to:
  /// **'Class average'**
  String get teacherGradebookClassAverage;

  /// No description provided for @teacherGradebookCellNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get teacherGradebookCellNotStarted;

  /// No description provided for @teacherGradebookCellPendingGrading.
  ///
  /// In en, this message translates to:
  /// **'Needs grading'**
  String get teacherGradebookCellPendingGrading;

  /// No description provided for @teacherGradebookTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a score to open grading; tap an empty cell to open the assignment hub.'**
  String get teacherGradebookTapHint;

  /// No description provided for @teacherNavCalendar.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get teacherNavCalendar;

  /// No description provided for @teacherCalendarEmpty.
  ///
  /// In en, this message translates to:
  /// **'No scheduled events in this range.'**
  String get teacherCalendarEmpty;

  /// No description provided for @teacherCalendarKindDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get teacherCalendarKindDue;

  /// No description provided for @teacherCalendarKindOpens.
  ///
  /// In en, this message translates to:
  /// **'Opens'**
  String get teacherCalendarKindOpens;

  /// No description provided for @teacherCalendarKindCloses.
  ///
  /// In en, this message translates to:
  /// **'Closes'**
  String get teacherCalendarKindCloses;

  /// No description provided for @teacherCalendarKindLive.
  ///
  /// In en, this message translates to:
  /// **'Live now'**
  String get teacherCalendarKindLive;

  /// No description provided for @teacherCalendarViewMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get teacherCalendarViewMonth;

  /// No description provided for @teacherCalendarViewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get teacherCalendarViewList;

  /// No description provided for @teacherCalendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get teacherCalendarToday;

  /// No description provided for @teacherCalendarNoDayEvents.
  ///
  /// In en, this message translates to:
  /// **'No events on this day.'**
  String get teacherCalendarNoDayEvents;

  /// No description provided for @teacherCalendarGoToAssignment.
  ///
  /// In en, this message translates to:
  /// **'View assignment'**
  String get teacherCalendarGoToAssignment;

  /// No description provided for @teacherCalendarPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deadlines, live sessions, and assignment windows.'**
  String get teacherCalendarPageSubtitle;

  /// No description provided for @teacherCalendarViewWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get teacherCalendarViewWeek;

  /// No description provided for @teacherCalendarKpiDueWeek.
  ///
  /// In en, this message translates to:
  /// **'Due this week'**
  String get teacherCalendarKpiDueWeek;

  /// No description provided for @teacherCalendarKpiOpens.
  ///
  /// In en, this message translates to:
  /// **'Opening'**
  String get teacherCalendarKpiOpens;

  /// No description provided for @teacherCalendarKpiLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get teacherCalendarKpiLive;

  /// No description provided for @teacherCalendarKpiTotal.
  ///
  /// In en, this message translates to:
  /// **'Total events'**
  String get teacherCalendarKpiTotal;

  /// No description provided for @teacherCalendarLegendTitle.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get teacherCalendarLegendTitle;

  /// No description provided for @teacherCalendarSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search assignments…'**
  String get teacherCalendarSearchHint;

  /// No description provided for @teacherCalendarFilterClassroomLabel.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get teacherCalendarFilterClassroomLabel;

  /// No description provided for @teacherCalendarFilterClassroomAll.
  ///
  /// In en, this message translates to:
  /// **'All classes'**
  String get teacherCalendarFilterClassroomAll;

  /// No description provided for @teacherCalendarFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get teacherCalendarFilterAll;

  /// No description provided for @teacherCalendarAgendaTitle.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get teacherCalendarAgendaTitle;

  /// No description provided for @teacherCalendarGroupsOnDay.
  ///
  /// In en, this message translates to:
  /// **'{count} assignment groups'**
  String teacherCalendarGroupsOnDay(int count);

  /// No description provided for @teacherCalendarSectionToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get teacherCalendarSectionToday;

  /// No description provided for @teacherCalendarSectionUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get teacherCalendarSectionUpcoming;

  /// No description provided for @teacherCalendarSectionPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get teacherCalendarSectionPast;

  /// No description provided for @teacherCalendarRelativeNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get teacherCalendarRelativeNow;

  /// No description provided for @teacherCalendarRelativeOverdueDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days overdue'**
  String teacherCalendarRelativeOverdueDays(int count);

  /// No description provided for @teacherCalendarRelativeOverdueHours.
  ///
  /// In en, this message translates to:
  /// **'{count} hours overdue'**
  String teacherCalendarRelativeOverdueHours(int count);

  /// No description provided for @teacherCalendarRelativeOverdueMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min overdue'**
  String teacherCalendarRelativeOverdueMinutes(int count);

  /// No description provided for @teacherCalendarRelativeInDays.
  ///
  /// In en, this message translates to:
  /// **'In {count} days'**
  String teacherCalendarRelativeInDays(int count);

  /// No description provided for @teacherCalendarRelativeInHours.
  ///
  /// In en, this message translates to:
  /// **'In {count} hours'**
  String teacherCalendarRelativeInHours(int count);

  /// No description provided for @teacherCalendarRelativeInMinutes.
  ///
  /// In en, this message translates to:
  /// **'In {count} min'**
  String teacherCalendarRelativeInMinutes(int count);

  /// No description provided for @teacherDashboardActionItems.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get teacherDashboardActionItems;

  /// No description provided for @teacherDashboardPendingJoins.
  ///
  /// In en, this message translates to:
  /// **'Pending join requests'**
  String get teacherDashboardPendingJoins;

  /// No description provided for @teacherDashboardDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get teacherDashboardDueSoon;

  /// No description provided for @teacherDashboardNeedsGrading.
  ///
  /// In en, this message translates to:
  /// **'{count} attempts need grading'**
  String teacherDashboardNeedsGrading(int count);

  /// No description provided for @teacherAssignmentPresetLabel.
  ///
  /// In en, this message translates to:
  /// **'Preset'**
  String get teacherAssignmentPresetLabel;

  /// No description provided for @teacherAssignmentPresetSave.
  ///
  /// In en, this message translates to:
  /// **'Save as preset'**
  String get teacherAssignmentPresetSave;

  /// No description provided for @teacherAssignmentPresetSaved.
  ///
  /// In en, this message translates to:
  /// **'Preset saved'**
  String get teacherAssignmentPresetSaved;

  /// No description provided for @teacherAssignmentPresetNone.
  ///
  /// In en, this message translates to:
  /// **'No presets yet'**
  String get teacherAssignmentPresetNone;

  /// No description provided for @examModePractice.
  ///
  /// In en, this message translates to:
  /// **'Practice (no grade)'**
  String get examModePractice;

  /// No description provided for @teacherAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get teacherAnalyticsTitle;

  /// No description provided for @teacherAnalyticsSubmissionsChart.
  ///
  /// In en, this message translates to:
  /// **'Submissions per day'**
  String get teacherAnalyticsSubmissionsChart;

  /// No description provided for @teacherAnalyticsScoreChart.
  ///
  /// In en, this message translates to:
  /// **'Score distribution'**
  String get teacherAnalyticsScoreChart;

  /// No description provided for @teacherAnalyticsIntegrityChart.
  ///
  /// In en, this message translates to:
  /// **'Integrity flags'**
  String get teacherAnalyticsIntegrityChart;

  /// No description provided for @teacherAnalyticsIntegrityHigh.
  ///
  /// In en, this message translates to:
  /// **'High risk'**
  String get teacherAnalyticsIntegrityHigh;

  /// No description provided for @teacherAnalyticsIntegrityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get teacherAnalyticsIntegrityMedium;

  /// No description provided for @teacherAnalyticsIntegrityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get teacherAnalyticsIntegrityLow;

  /// No description provided for @teacherAnalyticsNoData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data yet'**
  String get teacherAnalyticsNoData;

  /// No description provided for @teacherAnalyticsPeriod7d.
  ///
  /// In en, this message translates to:
  /// **'7 d'**
  String get teacherAnalyticsPeriod7d;

  /// No description provided for @teacherAnalyticsPeriod14d.
  ///
  /// In en, this message translates to:
  /// **'14 d'**
  String get teacherAnalyticsPeriod14d;

  /// No description provided for @teacherAnalyticsPeriod30d.
  ///
  /// In en, this message translates to:
  /// **'30 d'**
  String get teacherAnalyticsPeriod30d;

  /// No description provided for @teacherAnalyticsActiveStudents.
  ///
  /// In en, this message translates to:
  /// **'Active students'**
  String get teacherAnalyticsActiveStudents;

  /// No description provided for @teacherAnalyticsActiveAssignments.
  ///
  /// In en, this message translates to:
  /// **'Active assignments'**
  String get teacherAnalyticsActiveAssignments;

  /// No description provided for @teacherAnalyticsSubmissions.
  ///
  /// In en, this message translates to:
  /// **'Submissions'**
  String get teacherAnalyticsSubmissions;

  /// No description provided for @teacherAnalyticsPendingGrading.
  ///
  /// In en, this message translates to:
  /// **'Pending grading'**
  String get teacherAnalyticsPendingGrading;

  /// No description provided for @teacherAnalyticsAvgScore.
  ///
  /// In en, this message translates to:
  /// **'Avg score'**
  String get teacherAnalyticsAvgScore;

  /// No description provided for @teacherAnalyticsSkillBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Per-skill averages'**
  String get teacherAnalyticsSkillBreakdown;

  /// No description provided for @teacherAnalyticsSkillListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get teacherAnalyticsSkillListening;

  /// No description provided for @teacherAnalyticsSkillReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get teacherAnalyticsSkillReading;

  /// No description provided for @teacherAnalyticsSkillWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get teacherAnalyticsSkillWriting;

  /// No description provided for @teacherAnalyticsSkillSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get teacherAnalyticsSkillSpeaking;

  /// No description provided for @teacherAnalyticsSkillGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get teacherAnalyticsSkillGrammar;

  /// No description provided for @teacherAnalyticsWeakSkillHint.
  ///
  /// In en, this message translates to:
  /// **'{skill} avg {score}/10 — consider scheduling extra practice.'**
  String teacherAnalyticsWeakSkillHint(String skill, String score);

  /// No description provided for @teacherAnalyticsModeBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Assignment modes'**
  String get teacherAnalyticsModeBreakdown;

  /// No description provided for @teacherAnalyticsModeHomework.
  ///
  /// In en, this message translates to:
  /// **'Homework'**
  String get teacherAnalyticsModeHomework;

  /// No description provided for @teacherAnalyticsModeLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get teacherAnalyticsModeLive;

  /// No description provided for @teacherAnalyticsModeSelfPaced.
  ///
  /// In en, this message translates to:
  /// **'Self-paced'**
  String get teacherAnalyticsModeSelfPaced;

  /// No description provided for @teacherNavAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get teacherNavAnalytics;

  /// No description provided for @teacherClassTabActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get teacherClassTabActivity;

  /// No description provided for @teacherClassActivityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No activity recorded yet.'**
  String get teacherClassActivityEmpty;

  /// No description provided for @teacherCoTeacherAdd.
  ///
  /// In en, this message translates to:
  /// **'Add co-teacher'**
  String get teacherCoTeacherAdd;

  /// No description provided for @teacherCoTeacherEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Teacher email'**
  String get teacherCoTeacherEmailHint;

  /// No description provided for @teacherCoTeacherUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Search by username'**
  String get teacherCoTeacherUsernameHint;

  /// No description provided for @teacherCoTeacherSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type username to search…'**
  String get teacherCoTeacherSearchPlaceholder;

  /// No description provided for @teacherCoTeacherSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No teachers found'**
  String get teacherCoTeacherSearchEmpty;

  /// No description provided for @teacherCoTeacherPrimaryTeacher.
  ///
  /// In en, this message translates to:
  /// **'Primary teacher'**
  String get teacherCoTeacherPrimaryTeacher;

  /// No description provided for @teacherCoTeacherListTitle.
  ///
  /// In en, this message translates to:
  /// **'Co-teachers'**
  String get teacherCoTeacherListTitle;

  /// No description provided for @teacherCoTeacherNone.
  ///
  /// In en, this message translates to:
  /// **'No co-teachers yet'**
  String get teacherCoTeacherNone;

  /// No description provided for @teacherCoTeacherRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get teacherCoTeacherRemove;

  /// No description provided for @teacherCoTeacherRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this co-teacher from the class?'**
  String get teacherCoTeacherRemoveConfirm;

  /// No description provided for @teacherClassSettingsTeam.
  ///
  /// In en, this message translates to:
  /// **'Teaching team'**
  String get teacherClassSettingsTeam;

  /// No description provided for @teacherClassSettingsInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite & join'**
  String get teacherClassSettingsInvite;

  /// No description provided for @teacherClassSettingsStats.
  ///
  /// In en, this message translates to:
  /// **'Class summary'**
  String get teacherClassSettingsStats;

  /// No description provided for @teacherClassSettingsDanger.
  ///
  /// In en, this message translates to:
  /// **'Advanced actions'**
  String get teacherClassSettingsDanger;

  /// No description provided for @teacherInviteToken.
  ///
  /// In en, this message translates to:
  /// **'Invite link token'**
  String get teacherInviteToken;

  /// No description provided for @teacherInviteTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Share this token for students to join via invite link'**
  String get teacherInviteTokenHint;

  /// No description provided for @copyInviteToken.
  ///
  /// In en, this message translates to:
  /// **'Copy invite token'**
  String get copyInviteToken;

  /// No description provided for @teacherCoTeacherAdded.
  ///
  /// In en, this message translates to:
  /// **'Co-teacher added'**
  String get teacherCoTeacherAdded;

  /// No description provided for @teacherCoTeacherInviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent'**
  String get teacherCoTeacherInviteSent;

  /// No description provided for @teacherCoTeacherPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get teacherCoTeacherPending;

  /// No description provided for @teacherCoTeacherRemoved.
  ///
  /// In en, this message translates to:
  /// **'Co-teacher removed'**
  String get teacherCoTeacherRemoved;

  /// No description provided for @teacherIntegrationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get teacherIntegrationsTitle;

  /// No description provided for @teacherGoogleClassroomLink.
  ///
  /// In en, this message translates to:
  /// **'Link Google Classroom course'**
  String get teacherGoogleClassroomLink;

  /// No description provided for @teacherGoogleClassroomUnlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink Google Classroom'**
  String get teacherGoogleClassroomUnlink;

  /// No description provided for @teacherGoogleClassroomCourseId.
  ///
  /// In en, this message translates to:
  /// **'Google course ID'**
  String get teacherGoogleClassroomCourseId;

  /// No description provided for @teacherRubricTitle.
  ///
  /// In en, this message translates to:
  /// **'Rubric scoring'**
  String get teacherRubricTitle;

  /// No description provided for @teacherRubricCriterion.
  ///
  /// In en, this message translates to:
  /// **'Criterion'**
  String get teacherRubricCriterion;

  /// No description provided for @teacherAdaptiveEnabled.
  ///
  /// In en, this message translates to:
  /// **'Adaptive difficulty'**
  String get teacherAdaptiveEnabled;

  /// No description provided for @teacherGradingLiveProgress.
  ///
  /// In en, this message translates to:
  /// **'Live progress'**
  String get teacherGradingLiveProgress;

  /// No description provided for @teacherClassViewStudentAttempts.
  ///
  /// In en, this message translates to:
  /// **'Student work'**
  String get teacherClassViewStudentAttempts;

  /// No description provided for @teacherClassTapToViewAttempts.
  ///
  /// In en, this message translates to:
  /// **'Tap to view all student submissions'**
  String get teacherClassTapToViewAttempts;

  /// No description provided for @teacherClassOpenAttemptsList.
  ///
  /// In en, this message translates to:
  /// **'View submissions'**
  String get teacherClassOpenAttemptsList;

  /// No description provided for @teacherGradingStudentAttemptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Student submissions'**
  String get teacherGradingStudentAttemptsTitle;

  /// No description provided for @teacherGradingStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get teacherGradingStatusInProgress;

  /// No description provided for @teacherGradingStatusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get teacherGradingStatusSubmitted;

  /// No description provided for @teacherGradingStatePendingAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto grading'**
  String get teacherGradingStatePendingAuto;

  /// No description provided for @teacherGradingStatePendingAi.
  ///
  /// In en, this message translates to:
  /// **'AI review'**
  String get teacherGradingStatePendingAi;

  /// No description provided for @teacherGradingStatePendingManual.
  ///
  /// In en, this message translates to:
  /// **'Needs manual grading'**
  String get teacherGradingStatePendingManual;

  /// No description provided for @teacherGradingStateFinalized.
  ///
  /// In en, this message translates to:
  /// **'Graded'**
  String get teacherGradingStateFinalized;

  /// No description provided for @teacherGradingStartedAt.
  ///
  /// In en, this message translates to:
  /// **'Started {date}'**
  String teacherGradingStartedAt(String date);

  /// No description provided for @teacherGradingFinalize.
  ///
  /// In en, this message translates to:
  /// **'Finalize grading'**
  String get teacherGradingFinalize;

  /// No description provided for @teacherGradingFinalized.
  ///
  /// In en, this message translates to:
  /// **'Grading finalized'**
  String get teacherGradingFinalized;

  /// No description provided for @teacherGradingCompletenessComplete.
  ///
  /// In en, this message translates to:
  /// **'Full submission'**
  String get teacherGradingCompletenessComplete;

  /// No description provided for @teacherGradingCompletenessPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial submission'**
  String get teacherGradingCompletenessPartial;

  /// No description provided for @teacherGradingCompletenessForceEnd.
  ///
  /// In en, this message translates to:
  /// **'Ended by teacher (live session)'**
  String get teacherGradingCompletenessForceEnd;

  /// No description provided for @teacherGradingAiRationale.
  ///
  /// In en, this message translates to:
  /// **'AI feedback'**
  String get teacherGradingAiRationale;

  /// No description provided for @teacherGradingIntegratedScores.
  ///
  /// In en, this message translates to:
  /// **'Section scores'**
  String get teacherGradingIntegratedScores;

  /// No description provided for @teacherGradingDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Grade attempt'**
  String get teacherGradingDetailTitle;

  /// No description provided for @teacherGradingSaveScores.
  ///
  /// In en, this message translates to:
  /// **'Save scores'**
  String get teacherGradingSaveScores;

  /// No description provided for @teacherGradingSaved.
  ///
  /// In en, this message translates to:
  /// **'Scores saved'**
  String get teacherGradingSaved;

  /// No description provided for @teacherGradingNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Feedback note'**
  String get teacherGradingNotesHint;

  /// No description provided for @teacherGradingAwardedPoints.
  ///
  /// In en, this message translates to:
  /// **'Awarded points'**
  String get teacherGradingAwardedPoints;

  /// No description provided for @teacherGradingOnlySubmitted.
  ///
  /// In en, this message translates to:
  /// **'Scores can be adjusted after the student submits.'**
  String get teacherGradingOnlySubmitted;

  /// No description provided for @teacherAttemptGradeHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review responses, adjust scores, and release results when ready.'**
  String get teacherAttemptGradeHeaderSubtitle;

  /// No description provided for @teacherAttemptGradeExamLabel.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get teacherAttemptGradeExamLabel;

  /// No description provided for @teacherAttemptGradeStartedLine.
  ///
  /// In en, this message translates to:
  /// **'Started {date}'**
  String teacherAttemptGradeStartedLine(String date);

  /// No description provided for @teacherAttemptGradeSubmittedLine.
  ///
  /// In en, this message translates to:
  /// **'Submitted {date}'**
  String teacherAttemptGradeSubmittedLine(String date);

  /// No description provided for @teacherAttemptGradeReleasedYes.
  ///
  /// In en, this message translates to:
  /// **'Published to student'**
  String get teacherAttemptGradeReleasedYes;

  /// No description provided for @teacherAttemptGradeReleasedNo.
  ///
  /// In en, this message translates to:
  /// **'Not published yet'**
  String get teacherAttemptGradeReleasedNo;

  /// No description provided for @teacherAttemptGradeTotalScore.
  ///
  /// In en, this message translates to:
  /// **'Skill scores'**
  String get teacherAttemptGradeTotalScore;

  /// No description provided for @integratedSkillScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'{score} / 10'**
  String integratedSkillScoreLabel(String score);

  /// No description provided for @integratedSkillScorePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get integratedSkillScorePending;

  /// No description provided for @integratedSkillNoSubmission.
  ///
  /// In en, this message translates to:
  /// **'No submission'**
  String get integratedSkillNoSubmission;

  /// No description provided for @integratedSkillFinalAvg.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get integratedSkillFinalAvg;

  /// No description provided for @integratedSkillFinalPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial avg.'**
  String get integratedSkillFinalPartial;

  /// No description provided for @integratedSkillGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get integratedSkillGrammar;

  /// No description provided for @integratedSkillListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get integratedSkillListening;

  /// No description provided for @integratedSkillReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get integratedSkillReading;

  /// No description provided for @integratedSkillWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get integratedSkillWriting;

  /// No description provided for @integratedSkillSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get integratedSkillSpeaking;

  /// No description provided for @integratedSkillEnterScore.
  ///
  /// In en, this message translates to:
  /// **'Enter score (0–10)'**
  String get integratedSkillEnterScore;

  /// No description provided for @integratedSkillScoreSaved.
  ///
  /// In en, this message translates to:
  /// **'Score saved'**
  String get integratedSkillScoreSaved;

  /// No description provided for @integratedSkillSaveScore.
  ///
  /// In en, this message translates to:
  /// **'Save score'**
  String get integratedSkillSaveScore;

  /// No description provided for @integratedScoresAwaiting.
  ///
  /// In en, this message translates to:
  /// **'Scores are being calculated. Refresh in a moment if this persists.'**
  String get integratedScoresAwaiting;

  /// No description provided for @integratedGradingAvgFormulaHint.
  ///
  /// In en, this message translates to:
  /// **'Final score = arithmetic mean of scored skills (0–10 each). Skills with no submission are excluded from the average.'**
  String get integratedGradingAvgFormulaHint;

  /// No description provided for @integratedGradingColumnSkill.
  ///
  /// In en, this message translates to:
  /// **'Skill'**
  String get integratedGradingColumnSkill;

  /// No description provided for @integratedGradingColumnScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get integratedGradingColumnScore;

  /// No description provided for @integratedWritingGradingEssayLabel.
  ///
  /// In en, this message translates to:
  /// **'Student essay'**
  String get integratedWritingGradingEssayLabel;

  /// No description provided for @integratedWritingGradingWordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} words'**
  String integratedWritingGradingWordCount(String count);

  /// No description provided for @integratedWritingGradingNoDraft.
  ///
  /// In en, this message translates to:
  /// **'No essay text saved for this attempt.'**
  String get integratedWritingGradingNoDraft;

  /// No description provided for @integratedWritingGradingRunAi.
  ///
  /// In en, this message translates to:
  /// **'Grade with AI'**
  String get integratedWritingGradingRunAi;

  /// No description provided for @integratedWritingGradingApplyAi.
  ///
  /// In en, this message translates to:
  /// **'Apply AI score'**
  String get integratedWritingGradingApplyAi;

  /// No description provided for @integratedWritingGradingManual.
  ///
  /// In en, this message translates to:
  /// **'Manual score'**
  String get integratedWritingGradingManual;

  /// No description provided for @integratedWritingGradingAiBand.
  ///
  /// In en, this message translates to:
  /// **'AI band: {band} / 9'**
  String integratedWritingGradingAiBand(String band);

  /// No description provided for @integratedWritingGradingAiExamScore.
  ///
  /// In en, this message translates to:
  /// **'Suggested exam score: {score} / 10'**
  String integratedWritingGradingAiExamScore(String score);

  /// No description provided for @integratedGrammarItemResult.
  ///
  /// In en, this message translates to:
  /// **'{awarded} / {max} correct'**
  String integratedGrammarItemResult(String awarded, String max);

  /// No description provided for @teacherAttemptGradeSectionBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Questions & scoring'**
  String get teacherAttemptGradeSectionBreakdown;

  /// No description provided for @teacherAttemptGradeItemKind.
  ///
  /// In en, this message translates to:
  /// **'Type: {kind}'**
  String teacherAttemptGradeItemKind(String kind);

  /// No description provided for @teacherAttemptGradeMaxPts.
  ///
  /// In en, this message translates to:
  /// **'Max {n} pts'**
  String teacherAttemptGradeMaxPts(int n);

  /// No description provided for @teacherAttemptGradeStudentFallback.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get teacherAttemptGradeStudentFallback;

  /// No description provided for @teacherAttemptGradePointsShort.
  ///
  /// In en, this message translates to:
  /// **'{awarded} / {max} pts'**
  String teacherAttemptGradePointsShort(Object awarded, Object max);

  /// No description provided for @teacherAttemptGradeAnswerLabel.
  ///
  /// In en, this message translates to:
  /// **'Student answer'**
  String get teacherAttemptGradeAnswerLabel;

  /// No description provided for @teacherAttemptGradeWorkAndScores.
  ///
  /// In en, this message translates to:
  /// **'Submission review & scoring'**
  String get teacherAttemptGradeWorkAndScores;

  /// No description provided for @teacherAttemptGradeCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct answer'**
  String get teacherAttemptGradeCorrectAnswer;

  /// No description provided for @teacherAttemptGradeSkillLinkedWork.
  ///
  /// In en, this message translates to:
  /// **'Linked exercises'**
  String get teacherAttemptGradeSkillLinkedWork;

  /// No description provided for @teacherAttemptGradeSkillCmsHint.
  ///
  /// In en, this message translates to:
  /// **'The student practiced this in the in-app lesson and marked it done here. Detailed attempts stay in the skill activity history, not in this exam payload.'**
  String get teacherAttemptGradeSkillCmsHint;

  /// No description provided for @teacherAttemptGradeQuestionN.
  ///
  /// In en, this message translates to:
  /// **'Question {n}'**
  String teacherAttemptGradeQuestionN(int n);

  /// No description provided for @teacherAttemptGradeInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get teacherAttemptGradeInstructions;

  /// No description provided for @teacherAttemptGradeChoicesLabel.
  ///
  /// In en, this message translates to:
  /// **'Answer choices'**
  String get teacherAttemptGradeChoicesLabel;

  /// No description provided for @teacherAttemptGradeNoSkillWork.
  ///
  /// In en, this message translates to:
  /// **'No work recorded during this exam session.'**
  String get teacherAttemptGradeNoSkillWork;

  /// No description provided for @teacherAttemptGradeNoEssayText.
  ///
  /// In en, this message translates to:
  /// **'No essay text saved for this attempt.'**
  String get teacherAttemptGradeNoEssayText;

  /// No description provided for @teacherAttemptGradeWritingPromptLabel.
  ///
  /// In en, this message translates to:
  /// **'WRITING PROMPT'**
  String get teacherAttemptGradeWritingPromptLabel;

  /// No description provided for @teacherAttemptGradeSkillWorkExamInline.
  ///
  /// In en, this message translates to:
  /// **'Answers saved inside this exam attempt (integrated exam).'**
  String get teacherAttemptGradeSkillWorkExamInline;

  /// No description provided for @teacherAttemptGradeSkillWorkNearSession.
  ///
  /// In en, this message translates to:
  /// **'Showing work from near this exam session (timestamps may fall slightly outside the exact window).'**
  String get teacherAttemptGradeSkillWorkNearSession;

  /// No description provided for @teacherAttemptGradeSkillWorkLatestLinked.
  ///
  /// In en, this message translates to:
  /// **'Showing the student\'s most recent work on this linked exercise.'**
  String get teacherAttemptGradeSkillWorkLatestLinked;

  /// No description provided for @teacherAttemptGradeWordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} words'**
  String teacherAttemptGradeWordCount(int count);

  /// No description provided for @teacherAttemptGradeViewSkillWork.
  ///
  /// In en, this message translates to:
  /// **'View student submission'**
  String get teacherAttemptGradeViewSkillWork;

  /// No description provided for @teacherAttemptGradeHideSkillWork.
  ///
  /// In en, this message translates to:
  /// **'Hide submission'**
  String get teacherAttemptGradeHideSkillWork;

  /// No description provided for @teacherAttemptGradeListeningCue.
  ///
  /// In en, this message translates to:
  /// **'Cue'**
  String get teacherAttemptGradeListeningCue;

  /// No description provided for @teacherAttemptGradeDictationScore.
  ///
  /// In en, this message translates to:
  /// **'Words correct: {correct} / {total}'**
  String teacherAttemptGradeDictationScore(Object correct, Object total);

  /// No description provided for @teacherAttemptGradeSpeakingLine.
  ///
  /// In en, this message translates to:
  /// **'Sentence {id}'**
  String teacherAttemptGradeSpeakingLine(String id);

  /// No description provided for @teacherAttemptGradeWritingScore.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String teacherAttemptGradeWritingScore(String score);

  /// No description provided for @teacherAttemptGradeSkillOther.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get teacherAttemptGradeSkillOther;

  /// No description provided for @teacherExamTimeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time left'**
  String get teacherExamTimeRemaining;

  /// No description provided for @teacherExamMcqNeedsStem.
  ///
  /// In en, this message translates to:
  /// **'Each MCQ needs question text.'**
  String get teacherExamMcqNeedsStem;

  /// No description provided for @teacherExamEssayNeedsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Each essay needs a prompt.'**
  String get teacherExamEssayNeedsPrompt;

  /// No description provided for @teacherExamIntegratedUntitled.
  ///
  /// In en, this message translates to:
  /// **'Four-skill practice set'**
  String get teacherExamIntegratedUntitled;

  /// No description provided for @teacherExamIntegratedNew.
  ///
  /// In en, this message translates to:
  /// **'Four-skill exam'**
  String get teacherExamIntegratedNew;

  /// No description provided for @teacherExamIntegratedBadge.
  ///
  /// In en, this message translates to:
  /// **'4 skills'**
  String get teacherExamIntegratedBadge;

  /// No description provided for @teacherExamIntegratedEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Four-skill exam'**
  String get teacherExamIntegratedEditorTitle;

  /// No description provided for @teacherExamIntegratedPartsTitle.
  ///
  /// In en, this message translates to:
  /// **'Parts (Reading → Listening → Writing → Speaking)'**
  String get teacherExamIntegratedPartsTitle;

  /// No description provided for @teacherExamIntegratedPartsHint.
  ///
  /// In en, this message translates to:
  /// **'Pick one published exercise per skill. Students open each activity in the app, then mark it done before submitting.'**
  String get teacherExamIntegratedPartsHint;

  /// No description provided for @teacherExamIntegratedTapToPick.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose content'**
  String get teacherExamIntegratedTapToPick;

  /// No description provided for @teacherExamIntegratedPickAll.
  ///
  /// In en, this message translates to:
  /// **'Choose all four exercises before publishing.'**
  String get teacherExamIntegratedPickAll;

  /// No description provided for @teacherExamIntegratedSkillListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get teacherExamIntegratedSkillListening;

  /// No description provided for @teacherExamIntegratedSkillSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get teacherExamIntegratedSkillSpeaking;

  /// No description provided for @teacherExamIntegratedSkillReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get teacherExamIntegratedSkillReading;

  /// No description provided for @teacherExamIntegratedSkillWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get teacherExamIntegratedSkillWriting;

  /// No description provided for @teacherExamIntegratedChooseExercise.
  ///
  /// In en, this message translates to:
  /// **'Choose exercise'**
  String get teacherExamIntegratedChooseExercise;

  /// No description provided for @teacherExamIntegratedEmptyList.
  ///
  /// In en, this message translates to:
  /// **'No items found.'**
  String get teacherExamIntegratedEmptyList;

  /// No description provided for @teacherExamSkillsEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Skills exam'**
  String get teacherExamSkillsEditorTitle;

  /// No description provided for @teacherExamSkillsPartsTitle.
  ///
  /// In en, this message translates to:
  /// **'Skills (choose what this test includes)'**
  String get teacherExamSkillsPartsTitle;

  /// No description provided for @teacherExamSkillsPartsHint.
  ///
  /// In en, this message translates to:
  /// **'Turn off a skill if this test should not cover it. For each included skill, add one or more exercises from the library.'**
  String get teacherExamSkillsPartsHint;

  /// No description provided for @teacherExamSkillsIncludeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Include this skill'**
  String get teacherExamSkillsIncludeSubtitle;

  /// No description provided for @teacherExamGrammarTitle.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get teacherExamGrammarTitle;

  /// No description provided for @teacherExamGrammarIncludeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Include Grammar section'**
  String get teacherExamGrammarIncludeSubtitle;

  /// No description provided for @teacherExamGrammarQuestionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question} other{{count} questions}}'**
  String teacherExamGrammarQuestionCount(int count);

  /// No description provided for @teacherExamGrammarEnabledNoItems.
  ///
  /// In en, this message translates to:
  /// **'Grammar is on but has no questions. Add at least one question or turn Grammar off.'**
  String get teacherExamGrammarEnabledNoItems;

  /// No description provided for @teacherExamGrammarHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. Add cloze, gap fill, matching, sentence order, or multiple choice. All are auto-scored. If the exam includes skills, total Grammar points cannot exceed 100.'**
  String get teacherExamGrammarHint;

  /// No description provided for @teacherExamWritingPublishNeedPrompt.
  ///
  /// In en, this message translates to:
  /// **'Writing is on: set a writing prompt (AI or manual). A library topic alone is not enough.'**
  String get teacherExamWritingPublishNeedPrompt;

  /// No description provided for @teacherExamWritingAiPickTaskTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Task type for AI prompts'**
  String get teacherExamWritingAiPickTaskTypeTitle;

  /// No description provided for @teacherExamWritingAiPickTaskTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. Leave as “Any” to get up to 3 different task types.'**
  String get teacherExamWritingAiPickTaskTypeHint;

  /// No description provided for @teacherExamWritingAiTaskTypeAny.
  ///
  /// In en, this message translates to:
  /// **'Any (mixed types)'**
  String get teacherExamWritingAiTaskTypeAny;

  /// No description provided for @teacherExamWritingAiNeedTopicOrTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a writing topic, or enter an exam title above, before generating AI prompts.'**
  String get teacherExamWritingAiNeedTopicOrTitle;

  /// No description provided for @teacherExamGrammarAdd.
  ///
  /// In en, this message translates to:
  /// **'Add question'**
  String get teacherExamGrammarAdd;

  /// No description provided for @teacherExamGrammarEdit.
  ///
  /// In en, this message translates to:
  /// **'Grammar question'**
  String get teacherExamGrammarEdit;

  /// No description provided for @teacherExamPublishNeedSelection.
  ///
  /// In en, this message translates to:
  /// **'Include at least one skill with an exercise, or add at least one Grammar question.'**
  String get teacherExamPublishNeedSelection;

  /// No description provided for @teacherExamListeningTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Exercise Type'**
  String get teacherExamListeningTypeLabel;

  /// No description provided for @teacherExamListeningTypeDictation.
  ///
  /// In en, this message translates to:
  /// **'Dictation'**
  String get teacherExamListeningTypeDictation;

  /// No description provided for @teacherExamListeningTypeComprehension.
  ///
  /// In en, this message translates to:
  /// **'Comprehension'**
  String get teacherExamListeningTypeComprehension;

  /// No description provided for @teacherExamListeningTypeDictationHint.
  ///
  /// In en, this message translates to:
  /// **'Fill-in-the-blank based on audio cues'**
  String get teacherExamListeningTypeDictationHint;

  /// No description provided for @teacherExamListeningTypeComprehensionHint.
  ///
  /// In en, this message translates to:
  /// **'MCQ questions based on a listening passage'**
  String get teacherExamListeningTypeComprehensionHint;

  /// No description provided for @teacherExamPublishPickEachIncludedSkill.
  ///
  /// In en, this message translates to:
  /// **'Add at least one exercise for every skill that is turned on.'**
  String get teacherExamPublishPickEachIncludedSkill;

  /// No description provided for @teacherExamSpeakingExerciseRequired.
  ///
  /// In en, this message translates to:
  /// **'Speaking is on but no exercise is linked. Tap \"Add exercise\" and pick a Speaking set.'**
  String get teacherExamSpeakingExerciseRequired;

  /// No description provided for @teacherExamWritingPromptSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Writing Prompt'**
  String get teacherExamWritingPromptSectionTitle;

  /// No description provided for @teacherExamWritingPromptEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'All students will receive the same writing prompt. Choose one AI-generated option or write your own.'**
  String get teacherExamWritingPromptEmptyHint;

  /// No description provided for @teacherExamWritingGenerateWithAI.
  ///
  /// In en, this message translates to:
  /// **'Generate with AI'**
  String get teacherExamWritingGenerateWithAI;

  /// No description provided for @teacherExamWritingWriteManually.
  ///
  /// In en, this message translates to:
  /// **'Write manually'**
  String get teacherExamWritingWriteManually;

  /// No description provided for @teacherExamWritingPromptNeedTopic.
  ///
  /// In en, this message translates to:
  /// **'Select a writing topic first to generate AI prompts.'**
  String get teacherExamWritingPromptNeedTopic;

  /// No description provided for @teacherExamWritingPickPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a writing prompt'**
  String get teacherExamWritingPickPromptTitle;

  /// No description provided for @teacherExamWritingPickPromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select one of the AI-generated prompts below. All students will receive this same prompt.'**
  String get teacherExamWritingPickPromptSubtitle;

  /// No description provided for @teacherExamWritingSelectThisPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get teacherExamWritingSelectThisPrompt;

  /// No description provided for @teacherExamWritingManualPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Write your own prompt'**
  String get teacherExamWritingManualPromptTitle;

  /// No description provided for @teacherExamWritingPromptTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Prompt title'**
  String get teacherExamWritingPromptTitleLabel;

  /// No description provided for @teacherExamWritingPromptTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Technology in Education'**
  String get teacherExamWritingPromptTitleHint;

  /// No description provided for @teacherExamWritingPromptTaskTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Task type'**
  String get teacherExamWritingPromptTaskTypeLabel;

  /// No description provided for @teacherExamWritingPromptTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Writing prompt'**
  String get teacherExamWritingPromptTextLabel;

  /// No description provided for @teacherExamWritingPromptTextHint.
  ///
  /// In en, this message translates to:
  /// **'Write the full exam question here. Include context and specific instructions for students...'**
  String get teacherExamWritingPromptTextHint;

  /// No description provided for @teacherExamWritingPromptTextRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the writing prompt text before saving.'**
  String get teacherExamWritingPromptTextRequired;

  /// No description provided for @teacherExamWritingPromptRequired.
  ///
  /// In en, this message translates to:
  /// **'Please set a writing prompt before publishing.'**
  String get teacherExamWritingPromptRequired;

  /// No description provided for @teacherExamWritingPromptNotSet.
  ///
  /// In en, this message translates to:
  /// **'No writing prompt set. Students will not be able to complete this section.'**
  String get teacherExamWritingPromptNotSet;

  /// No description provided for @teacherExamWritingCustomPrompt.
  ///
  /// In en, this message translates to:
  /// **'Custom prompt'**
  String get teacherExamWritingCustomPrompt;

  /// No description provided for @teacherExamGrammarPointsCap100.
  ///
  /// In en, this message translates to:
  /// **'Total Grammar points cannot exceed 100 while skills are included.'**
  String get teacherExamGrammarPointsCap100;

  /// No description provided for @teacherExamSkillsBadge.
  ///
  /// In en, this message translates to:
  /// **'Skills exam'**
  String get teacherExamSkillsBadge;

  /// No description provided for @integratedExamGrammarSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get integratedExamGrammarSectionTitle;

  /// No description provided for @integratedExamSubmitBlockedAll.
  ///
  /// In en, this message translates to:
  /// **'Finish every skill part and every Grammar question before submitting.'**
  String get integratedExamSubmitBlockedAll;

  /// No description provided for @teacherExamSkillsWebSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lay out like an exam paper: Grammar first, then Reading, Listening, Writing, and Speaking. Add one or more library exercises per skill you include.'**
  String get teacherExamSkillsWebSubtitle;

  /// No description provided for @teacherExamSkillsBrowseContent.
  ///
  /// In en, this message translates to:
  /// **'Browse library'**
  String get teacherExamSkillsBrowseContent;

  /// No description provided for @teacherExamSkillsNoGrammarYet.
  ///
  /// In en, this message translates to:
  /// **'No Grammar questions yet. Use Add question to open the editor.'**
  String get teacherExamSkillsNoGrammarYet;

  /// No description provided for @teacherExamSkillsAddExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get teacherExamSkillsAddExercise;

  /// No description provided for @teacherExamSkillsCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create new exercise'**
  String get teacherExamSkillsCreateNew;

  /// No description provided for @teacherExamSkillsExercisesSelected.
  ///
  /// In en, this message translates to:
  /// **'exercise(s) selected'**
  String get teacherExamSkillsExercisesSelected;

  /// No description provided for @teacherExamSkillsAllAdded.
  ///
  /// In en, this message translates to:
  /// **'All available exercises are already added.'**
  String get teacherExamSkillsAllAdded;

  /// No description provided for @teacherExamPickerAddSelected.
  ///
  /// In en, this message translates to:
  /// **'Add {count} selected'**
  String teacherExamPickerAddSelected(int count);

  /// No description provided for @teacherExamCreateMenuLabel.
  ///
  /// In en, this message translates to:
  /// **'New exam'**
  String get teacherExamCreateMenuLabel;

  /// No description provided for @teacherExamIntegratedCreateClassicHint.
  ///
  /// In en, this message translates to:
  /// **'MCQ & essay in one editor'**
  String get teacherExamIntegratedCreateClassicHint;

  /// No description provided for @teacherExamIntegratedCreateFourHint.
  ///
  /// In en, this message translates to:
  /// **'Four parts linked to existing lessons'**
  String get teacherExamIntegratedCreateFourHint;

  /// No description provided for @integratedExamRunnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice set'**
  String get integratedExamRunnerTitle;

  /// No description provided for @integratedExamMetaClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get integratedExamMetaClass;

  /// No description provided for @integratedExamMetaSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get integratedExamMetaSubject;

  /// No description provided for @integratedExamMetaTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get integratedExamMetaTeacher;

  /// No description provided for @integratedExamMetaStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get integratedExamMetaStudent;

  /// No description provided for @integratedExamMetaDelivery.
  ///
  /// In en, this message translates to:
  /// **'How you take this'**
  String get integratedExamMetaDelivery;

  /// No description provided for @integratedExamMetaModeHomework.
  ///
  /// In en, this message translates to:
  /// **'Take-home assignment'**
  String get integratedExamMetaModeHomework;

  /// No description provided for @integratedExamMetaModeScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled exam'**
  String get integratedExamMetaModeScheduled;

  /// No description provided for @integratedExamMetaModeLive.
  ///
  /// In en, this message translates to:
  /// **'Live session'**
  String get integratedExamMetaModeLive;

  /// No description provided for @integratedExamMetaPublic.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get integratedExamMetaPublic;

  /// No description provided for @integratedExamMetaTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'Time limit'**
  String get integratedExamMetaTimeLimit;

  /// No description provided for @integratedExamMetaTimeLimitMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String integratedExamMetaTimeLimitMinutes(int minutes);

  /// No description provided for @integratedExamMetaNoTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'No fixed time limit'**
  String get integratedExamMetaNoTimeLimit;

  /// No description provided for @integratedExamMetaDeadline.
  ///
  /// In en, this message translates to:
  /// **'Closes in'**
  String get integratedExamMetaDeadline;

  /// No description provided for @integratedExamMetaDue.
  ///
  /// In en, this message translates to:
  /// **'Submit by'**
  String get integratedExamMetaDue;

  /// No description provided for @integratedExamMetaWindow.
  ///
  /// In en, this message translates to:
  /// **'Open until'**
  String get integratedExamMetaWindow;

  /// No description provided for @integratedExamMetaOpens.
  ///
  /// In en, this message translates to:
  /// **'Opens at'**
  String get integratedExamMetaOpens;

  /// No description provided for @integratedExamMetaStarted.
  ///
  /// In en, this message translates to:
  /// **'Started at'**
  String get integratedExamMetaStarted;

  /// No description provided for @integratedExamSubjectDefault.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get integratedExamSubjectDefault;

  /// No description provided for @integratedExamNoClassName.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get integratedExamNoClassName;

  /// No description provided for @integratedExamGrammarNavHint.
  ///
  /// In en, this message translates to:
  /// **'Bold border = in progress; green = answered.'**
  String get integratedExamGrammarNavHint;

  /// No description provided for @integratedExamGrammarQuestionLabel.
  ///
  /// In en, this message translates to:
  /// **'Question {n} of {total}'**
  String integratedExamGrammarQuestionLabel(int n, int total);

  /// No description provided for @integratedExamTimeUpShort.
  ///
  /// In en, this message translates to:
  /// **'Time up'**
  String get integratedExamTimeUpShort;

  /// No description provided for @integratedExamGrammarPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous grammar question'**
  String get integratedExamGrammarPrevious;

  /// No description provided for @integratedExamGrammarNext.
  ///
  /// In en, this message translates to:
  /// **'Next grammar question'**
  String get integratedExamGrammarNext;

  /// No description provided for @integratedExamOpenExercise.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get integratedExamOpenExercise;

  /// No description provided for @integratedExamMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get integratedExamMarkDone;

  /// No description provided for @integratedExamUndoPart.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get integratedExamUndoPart;

  /// No description provided for @integratedExamSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit all parts'**
  String get integratedExamSubmit;

  /// No description provided for @integratedExamSubmitShort.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get integratedExamSubmitShort;

  /// No description provided for @integratedExamSubmitBlocked.
  ///
  /// In en, this message translates to:
  /// **'Mark every part as done before submitting.'**
  String get integratedExamSubmitBlocked;

  /// No description provided for @integratedExamProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} parts ready'**
  String integratedExamProgress(int done, int total);

  /// No description provided for @integratedExamListeningSubNavTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercises in Listening'**
  String get integratedExamListeningSubNavTitle;

  /// No description provided for @integratedExamListeningSubNavHint.
  ///
  /// In en, this message translates to:
  /// **'Choose dictation or comprehension below'**
  String get integratedExamListeningSubNavHint;

  /// No description provided for @integratedExamScoreSummary.
  ///
  /// In en, this message translates to:
  /// **'Avg. score: {earned} / 10'**
  String integratedExamScoreSummary(Object earned);

  /// No description provided for @integratedExamSkillsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get integratedExamSkillsSectionTitle;

  /// No description provided for @integratedExamDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Exam details'**
  String get integratedExamDetailsTitle;

  /// No description provided for @integratedExamSelectPartHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a part below. Work on one section at a time.'**
  String get integratedExamSelectPartHint;

  /// No description provided for @integratedExamPartDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get integratedExamPartDone;

  /// No description provided for @integratedExamPartNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get integratedExamPartNotStarted;

  /// No description provided for @integratedExamEmbeddedHint.
  ///
  /// In en, this message translates to:
  /// **'Complete the exercise below. Only the exam timer applies.'**
  String get integratedExamEmbeddedHint;

  /// No description provided for @integratedExamEmbeddedLocked.
  ///
  /// In en, this message translates to:
  /// **'This part is locked after you submitted the exam.'**
  String get integratedExamEmbeddedLocked;

  /// No description provided for @integratedExamResultsAwaitingRelease.
  ///
  /// In en, this message translates to:
  /// **'Your teacher has not released detailed results yet. You will see correct and incorrect answers here once grades are published.'**
  String get integratedExamResultsAwaitingRelease;

  /// No description provided for @integratedExamResultsNeverShown.
  ///
  /// In en, this message translates to:
  /// **'Detailed answers are not shown for this assignment.'**
  String get integratedExamResultsNeverShown;

  /// No description provided for @integratedExamResultsScoreOnly.
  ///
  /// In en, this message translates to:
  /// **'Your teacher published scores only. Detailed answers and feedback are not shown for this assignment. You can ask your teacher to enable full review later.'**
  String get integratedExamResultsScoreOnly;

  /// No description provided for @integratedExamReviewYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get integratedExamReviewYourAnswer;

  /// No description provided for @integratedExamReviewCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct answer'**
  String get integratedExamReviewCorrectAnswer;

  /// No description provided for @integratedExamReviewNotAnswered.
  ///
  /// In en, this message translates to:
  /// **'Not answered'**
  String get integratedExamReviewNotAnswered;

  /// No description provided for @integratedExamReviewTeacherFeedback.
  ///
  /// In en, this message translates to:
  /// **'Teacher feedback'**
  String get integratedExamReviewTeacherFeedback;

  /// No description provided for @teacherAssignmentResultsDetailLabel.
  ///
  /// In en, this message translates to:
  /// **'What students can review'**
  String get teacherAssignmentResultsDetailLabel;

  /// No description provided for @teacherResultsDetailScoreOnly.
  ///
  /// In en, this message translates to:
  /// **'Scores only'**
  String get teacherResultsDetailScoreOnly;

  /// No description provided for @teacherResultsDetailScoreOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Students see total and skill scores — not answers, work, or feedback.'**
  String get teacherResultsDetailScoreOnlyHint;

  /// No description provided for @teacherResultsDetailFull.
  ///
  /// In en, this message translates to:
  /// **'Full graded review'**
  String get teacherResultsDetailFull;

  /// No description provided for @teacherResultsDetailFullHint.
  ///
  /// In en, this message translates to:
  /// **'Students see their work, correct/wrong answers, and your feedback.'**
  String get teacherResultsDetailFullHint;

  /// No description provided for @teacherReleaseResultsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Publish results'**
  String get teacherReleaseResultsDialogTitle;

  /// No description provided for @teacherReleaseResultsDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what students may see after you release grades. You can change this later in assignment settings.'**
  String get teacherReleaseResultsDialogSubtitle;

  /// No description provided for @integratedExamEmbeddedNoResource.
  ///
  /// In en, this message translates to:
  /// **'No exercise linked for this part.'**
  String get integratedExamEmbeddedNoResource;

  /// No description provided for @integratedExamEmbeddedNoSpeakingResource.
  ///
  /// In en, this message translates to:
  /// **'No speaking exercise linked. Ask your teacher to add a Speaking set in the exam editor, then start a new session.'**
  String get integratedExamEmbeddedNoSpeakingResource;

  /// No description provided for @integratedExamGrammarUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This question type is not supported in the app yet.'**
  String get integratedExamGrammarUnsupported;

  /// No description provided for @integratedExamMatchPick.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get integratedExamMatchPick;

  /// No description provided for @integratedExamMatchHint.
  ///
  /// In en, this message translates to:
  /// **'Tap an item on the left, then tap on the right to connect — or long-press and drag to the matching answer. Lines show your pairs.'**
  String get integratedExamMatchHint;

  /// No description provided for @integratedExamMatchHintCompact.
  ///
  /// In en, this message translates to:
  /// **'Tap a phrase on the left, then tap an answer chip below — or drag a chip into the dashed slot. Each pair has its own color.'**
  String get integratedExamMatchHintCompact;

  /// No description provided for @integratedExamMatchAnswersPool.
  ///
  /// In en, this message translates to:
  /// **'Answers'**
  String get integratedExamMatchAnswersPool;

  /// No description provided for @integratedExamMatchTapAnswer.
  ///
  /// In en, this message translates to:
  /// **'Tap an answer below'**
  String get integratedExamMatchTapAnswer;

  /// No description provided for @integratedExamMatchDropHere.
  ///
  /// In en, this message translates to:
  /// **'Drop answer here'**
  String get integratedExamMatchDropHere;

  /// No description provided for @integratedExamReorderHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the lines into the correct order.'**
  String get integratedExamReorderHint;

  /// No description provided for @teacherExamGrammarKindMcqSingle.
  ///
  /// In en, this message translates to:
  /// **'Multiple choice (one answer)'**
  String get teacherExamGrammarKindMcqSingle;

  /// No description provided for @teacherExamGrammarKindMcqMulti.
  ///
  /// In en, this message translates to:
  /// **'Multiple choice (several answers)'**
  String get teacherExamGrammarKindMcqMulti;

  /// No description provided for @teacherExamGrammarKindCloze.
  ///
  /// In en, this message translates to:
  /// **'Cloze — fill blanks in a passage'**
  String get teacherExamGrammarKindCloze;

  /// No description provided for @teacherExamGrammarKindGap.
  ///
  /// In en, this message translates to:
  /// **'Gap — one missing word'**
  String get teacherExamGrammarKindGap;

  /// No description provided for @teacherExamGrammarKindMatching.
  ///
  /// In en, this message translates to:
  /// **'Match pairs'**
  String get teacherExamGrammarKindMatching;

  /// No description provided for @teacherExamGrammarKindReorder.
  ///
  /// In en, this message translates to:
  /// **'Put fragments in order'**
  String get teacherExamGrammarKindReorder;

  /// No description provided for @teacherExamGrammarQuestionType.
  ///
  /// In en, this message translates to:
  /// **'Question type'**
  String get teacherExamGrammarQuestionType;

  /// No description provided for @teacherExamGrammarPassageLabel.
  ///
  /// In en, this message translates to:
  /// **'Passage (mark blanks with double curly braces around numbers, e.g. 0 and 1)'**
  String get teacherExamGrammarPassageLabel;

  /// No description provided for @teacherExamGrammarTextBefore.
  ///
  /// In en, this message translates to:
  /// **'Text before gap'**
  String get teacherExamGrammarTextBefore;

  /// No description provided for @teacherExamGrammarTextAfter.
  ///
  /// In en, this message translates to:
  /// **'Text after gap'**
  String get teacherExamGrammarTextAfter;

  /// No description provided for @teacherExamGrammarAcceptedAnswers.
  ///
  /// In en, this message translates to:
  /// **'Accepted answers (comma-separated)'**
  String get teacherExamGrammarAcceptedAnswers;

  /// No description provided for @teacherExamGrammarBlankId.
  ///
  /// In en, this message translates to:
  /// **'Blank id'**
  String get teacherExamGrammarBlankId;

  /// No description provided for @teacherExamGrammarLeftColumn.
  ///
  /// In en, this message translates to:
  /// **'Left column'**
  String get teacherExamGrammarLeftColumn;

  /// No description provided for @teacherExamGrammarRightColumn.
  ///
  /// In en, this message translates to:
  /// **'Right column'**
  String get teacherExamGrammarRightColumn;

  /// No description provided for @teacherExamGrammarPairCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct match for row {row}'**
  String teacherExamGrammarPairCorrect(int row);

  /// No description provided for @teacherExamGrammarFragments.
  ///
  /// In en, this message translates to:
  /// **'Sentence fragments (one per line in correct reading order)'**
  String get teacherExamGrammarFragments;

  /// No description provided for @teacherExamGrammarReorderInstruction.
  ///
  /// In en, this message translates to:
  /// **'Drag the chips below to set the correct sentence order students should produce.'**
  String get teacherExamGrammarReorderInstruction;

  /// No description provided for @teacherExamGrammarSaveItem.
  ///
  /// In en, this message translates to:
  /// **'Save question'**
  String get teacherExamGrammarSaveItem;

  /// No description provided for @teacherExamGrammarNewItem.
  ///
  /// In en, this message translates to:
  /// **'New question'**
  String get teacherExamGrammarNewItem;

  /// No description provided for @teacherExamGrammarPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Grammar editor'**
  String get teacherExamGrammarPanelTitle;

  /// No description provided for @teacherExamGrammarCloseEditor.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get teacherExamGrammarCloseEditor;

  /// No description provided for @teacherExamGrammarImport.
  ///
  /// In en, this message translates to:
  /// **'Import questions'**
  String get teacherExamGrammarImport;

  /// No description provided for @teacherExamGrammarImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} question(s) successfully.'**
  String teacherExamGrammarImportSuccess(int count);

  /// No description provided for @teacherExamGrammarImportError.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse file. Check the format and try again.'**
  String get teacherExamGrammarImportError;

  /// No description provided for @teacherExamGrammarImportEmpty.
  ///
  /// In en, this message translates to:
  /// **'No valid questions found in the file.'**
  String get teacherExamGrammarImportEmpty;

  /// No description provided for @teacherExamGrammarImportFormatTitle.
  ///
  /// In en, this message translates to:
  /// **'Import format (JSON)'**
  String get teacherExamGrammarImportFormatTitle;

  /// No description provided for @teacherExamGrammarImportFormatHint.
  ///
  /// In en, this message translates to:
  /// **'Create a .json file containing an array of question objects. Each object must have a \"kind\" field. Supported kinds:'**
  String get teacherExamGrammarImportFormatHint;

  /// No description provided for @teacherExamGrammarDownloadSample.
  ///
  /// In en, this message translates to:
  /// **'Copy sample to clipboard'**
  String get teacherExamGrammarDownloadSample;

  /// No description provided for @teacherExamGrammarImportPickFile.
  ///
  /// In en, this message translates to:
  /// **'Pick .json file'**
  String get teacherExamGrammarImportPickFile;

  /// No description provided for @teacherExamGrammarAddOption.
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get teacherExamGrammarAddOption;

  /// No description provided for @teacherExamGrammarCorrectOptions.
  ///
  /// In en, this message translates to:
  /// **'Correct options'**
  String get teacherExamGrammarCorrectOptions;

  /// No description provided for @studentExamExpired.
  ///
  /// In en, this message translates to:
  /// **'Time is up'**
  String get studentExamExpired;

  /// No description provided for @teacherAssignmentEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Assignment'**
  String get teacherAssignmentEditTitle;

  /// No description provided for @teacherAssignmentEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust schedule, time limits and rules'**
  String get teacherAssignmentEditSubtitle;

  /// No description provided for @teacherAssignmentEditSaved.
  ///
  /// In en, this message translates to:
  /// **'Assignment updated'**
  String get teacherAssignmentEditSaved;

  /// No description provided for @teacherAssignmentEditScheduleSection.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get teacherAssignmentEditScheduleSection;

  /// No description provided for @teacherAssignmentEditRulesSection.
  ///
  /// In en, this message translates to:
  /// **'Attempts & Results'**
  String get teacherAssignmentEditRulesSection;

  /// No description provided for @teacherAssignmentEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit assignment'**
  String get teacherAssignmentEditTooltip;

  /// No description provided for @teacherAssignmentModeFixed.
  ///
  /// In en, this message translates to:
  /// **'Mode is set and cannot be changed after creation.'**
  String get teacherAssignmentModeFixed;

  /// No description provided for @teacherAssignmentRealtimeLobbyOpens.
  ///
  /// In en, this message translates to:
  /// **'Lobby opens (optional)'**
  String get teacherAssignmentRealtimeLobbyOpens;

  /// No description provided for @teacherAssignmentRealtimeLobbyOpensHint.
  ///
  /// In en, this message translates to:
  /// **'Earlier than start time if students may wait in the lobby. Defaults to the start time if empty.'**
  String get teacherAssignmentRealtimeLobbyOpensHint;

  /// No description provided for @teacherAssignmentRealtimeScheduledStart.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get teacherAssignmentRealtimeScheduledStart;

  /// No description provided for @teacherAssignmentRealtimeScheduledStartRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a start time for a scheduled session.'**
  String get teacherAssignmentRealtimeScheduledStartRequired;

  /// No description provided for @teacherAssignmentRealtimeHardEnd.
  ///
  /// In en, this message translates to:
  /// **'Hard end'**
  String get teacherAssignmentRealtimeHardEnd;

  /// No description provided for @teacherAssignmentRealtimeScheduleModeLabel.
  ///
  /// In en, this message translates to:
  /// **'When students join'**
  String get teacherAssignmentRealtimeScheduleModeLabel;

  /// No description provided for @teacherAssignmentRealtimeScheduleManual.
  ///
  /// In en, this message translates to:
  /// **'In class'**
  String get teacherAssignmentRealtimeScheduleManual;

  /// No description provided for @teacherAssignmentRealtimeScheduleScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get teacherAssignmentRealtimeScheduleScheduled;

  /// No description provided for @teacherAssignmentRealtimeScheduleManualHint.
  ///
  /// In en, this message translates to:
  /// **'No fixed time — open the live room in class; students enter when you press Start.'**
  String get teacherAssignmentRealtimeScheduleManualHint;

  /// No description provided for @teacherAssignmentRealtimeScheduleScheduledHint.
  ///
  /// In en, this message translates to:
  /// **'Students see the start time on their assignment. They can enter the lobby from the open time; the exam begins when you press Start.'**
  String get teacherAssignmentRealtimeScheduleScheduledHint;

  /// No description provided for @examCardRealtimeScheduledStart.
  ///
  /// In en, this message translates to:
  /// **'Live exam starts {date}'**
  String examCardRealtimeScheduledStart(String date);

  /// No description provided for @examCardRealtimeLobbyOpens.
  ///
  /// In en, this message translates to:
  /// **'Lobby opens {date}'**
  String examCardRealtimeLobbyOpens(String date);

  /// No description provided for @teacherAssignmentEditPracticeNote.
  ///
  /// In en, this message translates to:
  /// **'Practice mode has no schedule — students can access this assignment at any time.'**
  String get teacherAssignmentEditPracticeNote;

  /// No description provided for @chatMediaDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading file…'**
  String get chatMediaDownloading;

  /// No description provided for @chatMediaDownloadDone.
  ///
  /// In en, this message translates to:
  /// **'File downloaded'**
  String get chatMediaDownloadDone;

  /// No description provided for @chatMediaDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not download file'**
  String get chatMediaDownloadFailed;

  /// No description provided for @chatMediaVideoLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load video'**
  String get chatMediaVideoLoadFailed;

  /// No description provided for @speakingFbTitle.
  ///
  /// In en, this message translates to:
  /// **'Speaking feedback'**
  String get speakingFbTitle;

  /// No description provided for @speakingFbTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get speakingFbTabOverview;

  /// No description provided for @speakingFbTabDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get speakingFbTabDetails;

  /// No description provided for @speakingFbTabCorrections.
  ///
  /// In en, this message translates to:
  /// **'Fixes'**
  String get speakingFbTabCorrections;

  /// No description provided for @speakingFbTabSamples.
  ///
  /// In en, this message translates to:
  /// **'Samples'**
  String get speakingFbTabSamples;

  /// No description provided for @speakingFbOverall.
  ///
  /// In en, this message translates to:
  /// **'Overall band {score}'**
  String speakingFbOverall(String score);

  /// No description provided for @speakingFbCefr.
  ///
  /// In en, this message translates to:
  /// **'CEFR level'**
  String get speakingFbCefr;

  /// No description provided for @speakingFbStrengths.
  ///
  /// In en, this message translates to:
  /// **'Strengths'**
  String get speakingFbStrengths;

  /// No description provided for @speakingFbImprovements.
  ///
  /// In en, this message translates to:
  /// **'Needs improvement'**
  String get speakingFbImprovements;

  /// No description provided for @speakingFbCorrections.
  ///
  /// In en, this message translates to:
  /// **'Specific corrections'**
  String get speakingFbCorrections;

  /// No description provided for @speakingFbVocabUpgrades.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary upgrades'**
  String get speakingFbVocabUpgrades;

  /// No description provided for @speakingFbSaveWord.
  ///
  /// In en, this message translates to:
  /// **'Save to vocabulary'**
  String get speakingFbSaveWord;

  /// No description provided for @speakingFbSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get speakingFbSaved;

  /// No description provided for @speakingFbModelAnswers.
  ///
  /// In en, this message translates to:
  /// **'Model answers'**
  String get speakingFbModelAnswers;

  /// No description provided for @speakingFbSamplesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No sample answers'**
  String get speakingFbSamplesEmptyTitle;

  /// No description provided for @speakingFbSamplesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'This conversation has no sample answers to show.'**
  String get speakingFbSamplesEmptyBody;

  /// No description provided for @speakingFbNextSteps.
  ///
  /// In en, this message translates to:
  /// **'Next steps'**
  String get speakingFbNextSteps;

  /// No description provided for @speakingFbAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your conversation...'**
  String get speakingFbAnalyzing;

  /// No description provided for @speakingFbTooShort.
  ///
  /// In en, this message translates to:
  /// **'Talk a little longer to receive feedback.'**
  String get speakingFbTooShort;

  /// No description provided for @speakingErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get speakingErrorTitle;

  /// No description provided for @speakingErrorBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this right now. Please try again.'**
  String get speakingErrorBody;

  /// No description provided for @speakingFbErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create feedback'**
  String get speakingFbErrorTitle;

  /// No description provided for @speakingFbErrorBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t evaluate this conversation. Please try again.'**
  String get speakingFbErrorBody;

  /// No description provided for @speakingFbSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the word. Please try again.'**
  String get speakingFbSaveError;

  /// No description provided for @speakingFbRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get speakingFbRetry;

  /// No description provided for @speakingFbStatWords.
  ///
  /// In en, this message translates to:
  /// **'{count} words'**
  String speakingFbStatWords(int count);

  /// No description provided for @speakingFbStatWpm.
  ///
  /// In en, this message translates to:
  /// **'{value} WPM'**
  String speakingFbStatWpm(String value);

  /// No description provided for @speakingFbStatDuration.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String speakingFbStatDuration(int seconds);

  /// No description provided for @speakingFbStatFiller.
  ///
  /// In en, this message translates to:
  /// **'{count} fillers'**
  String speakingFbStatFiller(int count);

  /// No description provided for @speakingFbStatQuestions.
  ///
  /// In en, this message translates to:
  /// **'{count} questions'**
  String speakingFbStatQuestions(int count);

  /// No description provided for @speakingFbEndAndEvaluate.
  ///
  /// In en, this message translates to:
  /// **'End & get feedback'**
  String get speakingFbEndAndEvaluate;

  /// No description provided for @speakingFbSpeakMore.
  ///
  /// In en, this message translates to:
  /// **'Speak again'**
  String get speakingFbSpeakMore;

  /// No description provided for @speakingFbBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get speakingFbBack;

  /// No description provided for @speakingFbPronunciationSoon.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation: coming soon (requires an audio recording).'**
  String get speakingFbPronunciationSoon;

  /// No description provided for @speakingFbCriterionFc.
  ///
  /// In en, this message translates to:
  /// **'Fluency & coherence'**
  String get speakingFbCriterionFc;

  /// No description provided for @speakingFbCriterionLr.
  ///
  /// In en, this message translates to:
  /// **'Lexical resource'**
  String get speakingFbCriterionLr;

  /// No description provided for @speakingFbCriterionGra.
  ///
  /// In en, this message translates to:
  /// **'Grammar range & accuracy'**
  String get speakingFbCriterionGra;

  /// No description provided for @speakingFbCriterionIa.
  ///
  /// In en, this message translates to:
  /// **'Interaction & task'**
  String get speakingFbCriterionIa;

  /// No description provided for @speakingFbYourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get speakingFbYourTurn;

  /// No description provided for @speakingFbModelTurn.
  ///
  /// In en, this message translates to:
  /// **'Native-like version'**
  String get speakingFbModelTurn;

  /// No description provided for @speakingFbHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Speaking history'**
  String get speakingFbHistoryTitle;

  /// No description provided for @speakingFbHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No speaking sessions yet'**
  String get speakingFbHistoryEmptyTitle;

  /// No description provided for @speakingFbHistoryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Finish a free speaking conversation to see feedback here.'**
  String get speakingFbHistoryEmptyBody;

  /// No description provided for @speakingFbHistoryMeta.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s · {turns} turns · {cefr}'**
  String speakingFbHistoryMeta(int seconds, int turns, String cefr);

  /// No description provided for @speakingFbTaskAchievement.
  ///
  /// In en, this message translates to:
  /// **'Task achievement'**
  String get speakingFbTaskAchievement;

  /// No description provided for @speakingScenarioTitle.
  ///
  /// In en, this message translates to:
  /// **'Speaking scenarios'**
  String get speakingScenarioTitle;

  /// No description provided for @speakingScenarioFreeChat.
  ///
  /// In en, this message translates to:
  /// **'Free chat'**
  String get speakingScenarioFreeChat;

  /// No description provided for @speakingScenarioFreeChatBody.
  ///
  /// In en, this message translates to:
  /// **'Talk freely with the AI assistant.'**
  String get speakingScenarioFreeChatBody;

  /// No description provided for @speakingScenarioEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No scenarios yet'**
  String get speakingScenarioEmptyTitle;

  /// No description provided for @speakingScenarioEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Free chat is still available.'**
  String get speakingScenarioEmptyBody;

  /// No description provided for @speakingDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Speaking progress'**
  String get speakingDashboardTitle;

  /// No description provided for @speakingDashboardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No progress yet'**
  String get speakingDashboardEmptyTitle;

  /// No description provided for @speakingDashboardEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Finish at least two free speaking sessions to see a clearer trend.'**
  String get speakingDashboardEmptyBody;

  /// No description provided for @speakingDashboardSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get speakingDashboardSessions;

  /// No description provided for @speakingDashboardMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get speakingDashboardMinutes;

  /// No description provided for @speakingDashboardAvgBand.
  ///
  /// In en, this message translates to:
  /// **'Avg band'**
  String get speakingDashboardAvgBand;

  /// No description provided for @speakingDashboardStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get speakingDashboardStreak;

  /// No description provided for @speakingDashboardRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent sessions'**
  String get speakingDashboardRecent;

  /// No description provided for @speakingNotebookTitle.
  ///
  /// In en, this message translates to:
  /// **'Improvement notebook'**
  String get speakingNotebookTitle;

  /// No description provided for @speakingNotebookRepeated.
  ///
  /// In en, this message translates to:
  /// **'Repeated'**
  String get speakingNotebookRepeated;

  /// No description provided for @speakingNotebookEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get speakingNotebookEmptyTitle;

  /// No description provided for @speakingNotebookEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Your repeated errors and vocabulary upgrades will appear here after feedback.'**
  String get speakingNotebookEmptyBody;

  /// No description provided for @speakingNotebookNoItems.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get speakingNotebookNoItems;

  /// No description provided for @speakingNotebookReviewVocab.
  ///
  /// In en, this message translates to:
  /// **'Review vocabulary'**
  String get speakingNotebookReviewVocab;
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
