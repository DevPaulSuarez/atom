import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('es'),
  ];

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'Productivity with the Pomodoro method'**
  String get authTagline;

  /// No description provided for @tabRegister.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get tabRegister;

  /// No description provided for @tabLogin.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get tabLogin;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @hintName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get hintName;

  /// No description provided for @hintEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get hintEmail;

  /// No description provided for @hintPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get hintPassword;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Fill in all fields'**
  String get fillAllFields;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @connectionErrorServer.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Is the server running?'**
  String get connectionErrorServer;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get offline;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @onbTitle1.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Atom'**
  String get onbTitle1;

  /// No description provided for @onbBody1.
  ///
  /// In en, this message translates to:
  /// **'Your productivity companion based on the Pomodoro method. Work in cycles of focus and rest to perform at your best.'**
  String get onbBody1;

  /// No description provided for @onbTitle2.
  ///
  /// In en, this message translates to:
  /// **'AI builds your plan'**
  String get onbTitle2;

  /// No description provided for @onbBody2.
  ///
  /// In en, this message translates to:
  /// **'Describe your project and artificial intelligence breaks it down into concrete, actionable micro-tasks, ready to execute.'**
  String get onbBody2;

  /// No description provided for @onbTitle3.
  ///
  /// In en, this message translates to:
  /// **'One task at a time'**
  String get onbTitle3;

  /// No description provided for @onbBody3.
  ///
  /// In en, this message translates to:
  /// **'Focus on a single micro-task per session. When you finish, move on to the next one automatically and keep the rhythm.'**
  String get onbBody3;

  /// No description provided for @onbTitle4.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro cycles'**
  String get onbTitle4;

  /// No description provided for @onbBody4.
  ///
  /// In en, this message translates to:
  /// **'25 min of work · 5 min break · every 4 cycles a long break. The alarm lets you know, you decide when to continue.'**
  String get onbBody4;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name} 👋'**
  String greeting(Object name);

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @newProject.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get newProject;

  /// No description provided for @seeMore.
  ///
  /// In en, this message translates to:
  /// **'See more'**
  String get seeMore;

  /// No description provided for @filterByDate.
  ///
  /// In en, this message translates to:
  /// **'Filter by date'**
  String get filterByDate;

  /// No description provided for @completedOn.
  ///
  /// In en, this message translates to:
  /// **'Completed {date}'**
  String completedOn(String date);

  /// No description provided for @newProjectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI will generate the tasks automatically'**
  String get newProjectSubtitle;

  /// No description provided for @newProjectSubtitleManual.
  ///
  /// In en, this message translates to:
  /// **'Write your own tasks'**
  String get newProjectSubtitleManual;

  /// No description provided for @modeWithAI.
  ///
  /// In en, this message translates to:
  /// **'With AI'**
  String get modeWithAI;

  /// No description provided for @modeManual.
  ///
  /// In en, this message translates to:
  /// **'My tasks'**
  String get modeManual;

  /// No description provided for @yourTasks.
  ///
  /// In en, this message translates to:
  /// **'Your tasks'**
  String get yourTasks;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get addTask;

  /// No description provided for @taskTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Read chapter 1'**
  String get taskTitleHint;

  /// No description provided for @manualNoTasks.
  ///
  /// In en, this message translates to:
  /// **'Add at least one task'**
  String get manualNoTasks;

  /// No description provided for @fieldProjectName.
  ///
  /// In en, this message translates to:
  /// **'What do you want to achieve?'**
  String get fieldProjectName;

  /// No description provided for @hintProjectName.
  ///
  /// In en, this message translates to:
  /// **'e.g. Study for the history exam'**
  String get hintProjectName;

  /// No description provided for @fieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Tell us the details (optional)'**
  String get fieldDescription;

  /// No description provided for @hintDescription.
  ///
  /// In en, this message translates to:
  /// **'e.g. Read 3 chapters and write a summary of each'**
  String get hintDescription;

  /// No description provided for @fieldMotivation.
  ///
  /// In en, this message translates to:
  /// **'Why is it important to you? (optional)'**
  String get fieldMotivation;

  /// No description provided for @hintMotivation.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pass the exam and raise my grade'**
  String get hintMotivation;

  /// No description provided for @generatingTasks.
  ///
  /// In en, this message translates to:
  /// **'Generating tasks with AI...'**
  String get generatingTasks;

  /// No description provided for @createProject.
  ///
  /// In en, this message translates to:
  /// **'Create project'**
  String get createProject;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create your first project and AI\nwill generate the tasks automatically.'**
  String get emptyBody;

  /// No description provided for @completedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedLabel;

  /// No description provided for @tasksCount.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} tasks'**
  String tasksCount(Object completed, Object total);

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress · {time}'**
  String statusInProgress(Object time);

  /// No description provided for @statusBreak.
  ///
  /// In en, this message translates to:
  /// **'Break · {time}'**
  String statusBreak(Object time);

  /// No description provided for @statusLongBreak.
  ///
  /// In en, this message translates to:
  /// **'Long break · {time}'**
  String statusLongBreak(Object time);

  /// No description provided for @statusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused · {time}'**
  String statusPaused(Object time);

  /// No description provided for @pomodoro.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro'**
  String get pomodoro;

  /// No description provided for @minutesLower.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutesLower;

  /// No description provided for @restLower.
  ///
  /// In en, this message translates to:
  /// **'rest'**
  String get restLower;

  /// No description provided for @longBreakLower.
  ///
  /// In en, this message translates to:
  /// **'long break'**
  String get longBreakLower;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @skipPhase.
  ///
  /// In en, this message translates to:
  /// **'Skip phase'**
  String get skipPhase;

  /// No description provided for @skipBreak.
  ///
  /// In en, this message translates to:
  /// **'Skip break'**
  String get skipBreak;

  /// No description provided for @skipLongBreak.
  ///
  /// In en, this message translates to:
  /// **'Skip long break'**
  String get skipLongBreak;

  /// No description provided for @breakOngoing.
  ///
  /// In en, this message translates to:
  /// **'Resting...'**
  String get breakOngoing;

  /// No description provided for @longBreakOngoing.
  ///
  /// In en, this message translates to:
  /// **'Long break...'**
  String get longBreakOngoing;

  /// No description provided for @projectCompletedExclaim.
  ///
  /// In en, this message translates to:
  /// **'Project completed!'**
  String get projectCompletedExclaim;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @pomodoroOngoing.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro in progress...'**
  String get pomodoroOngoing;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @phaseWorking.
  ///
  /// In en, this message translates to:
  /// **'WORKING'**
  String get phaseWorking;

  /// No description provided for @phasePaused.
  ///
  /// In en, this message translates to:
  /// **'PAUSED'**
  String get phasePaused;

  /// No description provided for @phaseShortBreak.
  ///
  /// In en, this message translates to:
  /// **'SHORT BREAK'**
  String get phaseShortBreak;

  /// No description provided for @phaseLongBreak.
  ///
  /// In en, this message translates to:
  /// **'LONG BREAK'**
  String get phaseLongBreak;

  /// No description provided for @phaseSessionComplete.
  ///
  /// In en, this message translates to:
  /// **'SESSION COMPLETE'**
  String get phaseSessionComplete;

  /// No description provided for @phaseBreakDone.
  ///
  /// In en, this message translates to:
  /// **'BREAK DONE'**
  String get phaseBreakDone;

  /// No description provided for @phaseReady.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get phaseReady;

  /// No description provided for @cycleComplete.
  ///
  /// In en, this message translates to:
  /// **'Cycle complete! A well-deserved break'**
  String get cycleComplete;

  /// No description provided for @sessionCompletedOf.
  ///
  /// In en, this message translates to:
  /// **'Session {n} of 4 completed'**
  String sessionCompletedOf(Object n);

  /// No description provided for @sessionOf.
  ///
  /// In en, this message translates to:
  /// **'Session {n} of 4'**
  String sessionOf(Object n);

  /// No description provided for @analyzingTask.
  ///
  /// In en, this message translates to:
  /// **'AI is analyzing the task...'**
  String get analyzingTask;

  /// No description provided for @blockMomentTitle.
  ///
  /// In en, this message translates to:
  /// **'A moment of being stuck'**
  String get blockMomentTitle;

  /// No description provided for @splitIntoSteps.
  ///
  /// In en, this message translates to:
  /// **'I split the task into {n} smaller steps.'**
  String splitIntoSteps(Object n);

  /// No description provided for @whyStarted.
  ///
  /// In en, this message translates to:
  /// **'WHY YOU STARTED'**
  String get whyStarted;

  /// No description provided for @yourCoach.
  ///
  /// In en, this message translates to:
  /// **'Your coach'**
  String get yourCoach;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @breakOverTitle.
  ///
  /// In en, this message translates to:
  /// **'Break over!'**
  String get breakOverTitle;

  /// No description provided for @breakOverBody.
  ///
  /// In en, this message translates to:
  /// **'Time to refocus. Ready for the next Pomodoro?'**
  String get breakOverBody;

  /// No description provided for @letsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go!'**
  String get letsGo;

  /// No description provided for @didYouComplete.
  ///
  /// In en, this message translates to:
  /// **'Did you complete the task?'**
  String get didYouComplete;

  /// No description provided for @yesCompleted.
  ///
  /// In en, this message translates to:
  /// **'Yes, I completed it'**
  String get yesCompleted;

  /// No description provided for @notYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYet;

  /// No description provided for @overallProgress.
  ///
  /// In en, this message translates to:
  /// **'Overall progress'**
  String get overallProgress;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @currentTaskLabel.
  ///
  /// In en, this message translates to:
  /// **'CURRENT TASK'**
  String get currentTaskLabel;

  /// No description provided for @taskNofM.
  ///
  /// In en, this message translates to:
  /// **'Task {n} of {total}'**
  String taskNofM(Object n, Object total);

  /// No description provided for @pomodorosCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{# pomodoro} other{# pomodoros}}'**
  String pomodorosCount(num count);

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @startPomodoro.
  ///
  /// In en, this message translates to:
  /// **'Start Pomodoro'**
  String get startPomodoro;

  /// No description provided for @pomodoroInProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro in progress'**
  String get pomodoroInProgressTitle;

  /// No description provided for @pomodoroCompleted.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro completed'**
  String get pomodoroCompleted;

  /// No description provided for @alreadyActivePomodoro.
  ///
  /// In en, this message translates to:
  /// **'You already have an active Pomodoro in:'**
  String get alreadyActivePomodoro;

  /// No description provided for @timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'{time} remaining'**
  String timeRemaining(Object time);

  /// No description provided for @finishBeforeNew.
  ///
  /// In en, this message translates to:
  /// **'Finish or pause that Pomodoro before starting a new one.'**
  String get finishBeforeNew;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @goToActivePomodoro.
  ///
  /// In en, this message translates to:
  /// **'Go to active Pomodoro'**
  String get goToActivePomodoro;

  /// No description provided for @deleteProject.
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get deleteProject;

  /// No description provided for @deleteProjectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this project? This action cannot be undone.'**
  String get deleteProjectConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @projectCompleted.
  ///
  /// In en, this message translates to:
  /// **'Project completed'**
  String get projectCompleted;

  /// No description provided for @allTasksCompleted.
  ///
  /// In en, this message translates to:
  /// **'All tasks completed'**
  String get allTasksCompleted;

  /// No description provided for @projectSummary.
  ///
  /// In en, this message translates to:
  /// **'PROJECT SUMMARY'**
  String get projectSummary;

  /// No description provided for @pomodoroLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{pomodoro} other{pomodoros}}'**
  String pomodoroLabel(num count);

  /// No description provided for @totalTime.
  ///
  /// In en, this message translates to:
  /// **'total time'**
  String get totalTime;

  /// No description provided for @taskLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{task} other{tasks}}'**
  String taskLabel(num count);

  /// No description provided for @completedTasks.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED TASKS'**
  String get completedTasks;

  /// No description provided for @allTasks.
  ///
  /// In en, this message translates to:
  /// **'All tasks'**
  String get allTasks;

  /// No description provided for @completedPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{completed} completed · {pending} pending'**
  String completedPendingCount(Object completed, Object pending);

  /// No description provided for @inProgressBadge.
  ///
  /// In en, this message translates to:
  /// **'IN PROGRESS'**
  String get inProgressBadge;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @alarmWorkTitle.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro complete!'**
  String get alarmWorkTitle;

  /// No description provided for @alarmWorkBody.
  ///
  /// In en, this message translates to:
  /// **'Take a break 🎉'**
  String get alarmWorkBody;

  /// No description provided for @alarmBreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Break over'**
  String get alarmBreakTitle;

  /// No description provided for @alarmBreakBody.
  ///
  /// In en, this message translates to:
  /// **'Ready to focus again 💪'**
  String get alarmBreakBody;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemDefault;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @focusDuration.
  ///
  /// In en, this message translates to:
  /// **'Focus duration'**
  String get focusDuration;

  /// No description provided for @focusBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get focusBeginner;

  /// No description provided for @focusFocused.
  ///
  /// In en, this message translates to:
  /// **'Focused'**
  String get focusFocused;

  /// No description provided for @focusClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic Pomodoro'**
  String get focusClassic;

  /// No description provided for @focusCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get focusCustom;

  /// No description provided for @minutesValue.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String minutesValue(Object n);

  /// No description provided for @customDurationTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom duration'**
  String get customDurationTitle;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @pomodoroProgress.
  ///
  /// In en, this message translates to:
  /// **'{done}/{estimate} 🍅'**
  String pomodoroProgress(Object done, Object estimate);

  /// No description provided for @pomodoroEstimate.
  ///
  /// In en, this message translates to:
  /// **'{n} 🍅'**
  String pomodoroEstimate(Object n);

  /// No description provided for @estimatedTotalPomodoros.
  ///
  /// In en, this message translates to:
  /// **'≈ {n} 🍅 estimated'**
  String estimatedTotalPomodoros(Object n);

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @streakCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get streakCurrent;

  /// No description provided for @streakBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get streakBest;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{n} day} other{{n} days}}'**
  String daysCount(int n);

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @statToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statToday;

  /// No description provided for @statThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get statThisWeek;

  /// No description provided for @statTotalPomodoros.
  ///
  /// In en, this message translates to:
  /// **'Total pomodoros'**
  String get statTotalPomodoros;

  /// No description provided for @statFocusTime.
  ///
  /// In en, this message translates to:
  /// **'Focus time'**
  String get statFocusTime;

  /// No description provided for @statTasksCompleted.
  ///
  /// In en, this message translates to:
  /// **'Tasks completed'**
  String get statTasksCompleted;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @noStatsYet.
  ///
  /// In en, this message translates to:
  /// **'Complete your first pomodoro to see your stats here.'**
  String get noStatsYet;

  /// No description provided for @pomodoroOfEstimate.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro {done} of {total}'**
  String pomodoroOfEstimate(Object done, Object total);

  /// No description provided for @overEstimateTitle.
  ///
  /// In en, this message translates to:
  /// **'You hit your estimate'**
  String get overEstimateTitle;

  /// No description provided for @overEstimateBody.
  ///
  /// In en, this message translates to:
  /// **'This task is taking longer than planned. What do you want to do?'**
  String get overEstimateBody;

  /// No description provided for @oneMorePomodoro.
  ///
  /// In en, this message translates to:
  /// **'One more pomodoro'**
  String get oneMorePomodoro;

  /// No description provided for @splitTaskAction.
  ///
  /// In en, this message translates to:
  /// **'Split the task'**
  String get splitTaskAction;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'A new version of Atom is available. Please update to keep using the app.'**
  String get updateRequiredBody;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
