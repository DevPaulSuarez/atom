// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get authTagline => 'Productivity with the Pomodoro method';

  @override
  String get tabRegister => 'Sign up';

  @override
  String get tabLogin => 'Log in';

  @override
  String get createAccount => 'Create account';

  @override
  String get signIn => 'Sign in';

  @override
  String get hintName => 'Your name';

  @override
  String get hintEmail => 'Email';

  @override
  String get hintPassword => 'Password';

  @override
  String get fillAllFields => 'Fill in all fields';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get connectionErrorServer =>
      'Connection error. Is the server running?';

  @override
  String get connectionError => 'Connection error';

  @override
  String get offline => 'No connection';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get started';

  @override
  String get onbTitle1 => 'Welcome to Atom';

  @override
  String get onbBody1 =>
      'Your productivity companion based on the Pomodoro method. Work in cycles of focus and rest to perform at your best.';

  @override
  String get onbTitle2 => 'AI builds your plan';

  @override
  String get onbBody2 =>
      'Describe your project and artificial intelligence breaks it down into concrete, actionable micro-tasks, ready to execute.';

  @override
  String get onbTitle3 => 'One task at a time';

  @override
  String get onbBody3 =>
      'Focus on a single micro-task per session. When you finish, move on to the next one automatically and keep the rhythm.';

  @override
  String get onbTitle4 => 'Pomodoro cycles';

  @override
  String get onbBody4 =>
      '25 min of work · 5 min break · every 4 cycles a long break. The alarm lets you know, you decide when to continue.';

  @override
  String greeting(Object name) {
    return 'Hi, $name 👋';
  }

  @override
  String get logout => 'Log out';

  @override
  String get newProject => 'New project';

  @override
  String get seeMore => 'See more';

  @override
  String get filterByDate => 'Filter by date';

  @override
  String completedOn(String date) {
    return 'Completed $date';
  }

  @override
  String get newProjectSubtitle => 'AI will generate the tasks automatically';

  @override
  String get newProjectSubtitleManual => 'Write your own tasks';

  @override
  String get modeWithAI => 'With AI';

  @override
  String get modeManual => 'My tasks';

  @override
  String get yourTasks => 'Your tasks';

  @override
  String get addTask => 'Add task';

  @override
  String get taskTitleHint => 'e.g. Read chapter 1';

  @override
  String get manualNoTasks => 'Add at least one task';

  @override
  String get fieldProjectName => 'What do you want to achieve?';

  @override
  String get hintProjectName => 'e.g. Study for the history exam';

  @override
  String get fieldDescription => 'Tell us the details (optional)';

  @override
  String get hintDescription =>
      'e.g. Read 3 chapters and write a summary of each';

  @override
  String get fieldMotivation => 'Why is it important to you? (optional)';

  @override
  String get hintMotivation => 'e.g. Pass the exam and raise my grade';

  @override
  String get generatingTasks => 'Generating tasks with AI...';

  @override
  String get createProject => 'Create project';

  @override
  String get emptyTitle => 'No projects yet';

  @override
  String get emptyBody =>
      'Create your first project and AI\nwill generate the tasks automatically.';

  @override
  String get completedLabel => 'Completed';

  @override
  String tasksCount(Object completed, Object total) {
    return '$completed of $total tasks';
  }

  @override
  String statusInProgress(Object time) {
    return 'In progress · $time';
  }

  @override
  String statusBreak(Object time) {
    return 'Break · $time';
  }

  @override
  String statusLongBreak(Object time) {
    return 'Long break · $time';
  }

  @override
  String statusPaused(Object time) {
    return 'Paused · $time';
  }

  @override
  String get pomodoro => 'Pomodoro';

  @override
  String get minutesLower => 'minutes';

  @override
  String get restLower => 'rest';

  @override
  String get longBreakLower => 'long break';

  @override
  String get pause => 'Pause';

  @override
  String get skipPhase => 'Skip phase';

  @override
  String get skipBreak => 'Skip break';

  @override
  String get skipLongBreak => 'Skip long break';

  @override
  String get breakOngoing => 'Resting...';

  @override
  String get longBreakOngoing => 'Long break...';

  @override
  String get projectCompletedExclaim => 'Project completed!';

  @override
  String get start => 'Start';

  @override
  String get pomodoroOngoing => 'Pomodoro in progress...';

  @override
  String get resume => 'Resume';

  @override
  String get phaseWorking => 'WORKING';

  @override
  String get phasePaused => 'PAUSED';

  @override
  String get phaseShortBreak => 'SHORT BREAK';

  @override
  String get phaseLongBreak => 'LONG BREAK';

  @override
  String get phaseSessionComplete => 'SESSION COMPLETE';

  @override
  String get phaseBreakDone => 'BREAK DONE';

  @override
  String get phaseReady => 'READY';

  @override
  String get cycleComplete => 'Cycle complete! A well-deserved break';

  @override
  String sessionCompletedOf(Object n) {
    return 'Session $n of 4 completed';
  }

  @override
  String sessionOf(Object n) {
    return 'Session $n of 4';
  }

  @override
  String get analyzingTask => 'AI is analyzing the task...';

  @override
  String get blockMomentTitle => 'A moment of being stuck';

  @override
  String splitIntoSteps(Object n) {
    return 'I split the task into $n smaller steps.';
  }

  @override
  String get whyStarted => 'WHY YOU STARTED';

  @override
  String get yourCoach => 'Your coach';

  @override
  String get tryAgain => 'Try again';

  @override
  String get breakOverTitle => 'Break over!';

  @override
  String get breakOverBody => 'Time to refocus. Ready for the next Pomodoro?';

  @override
  String get letsGo => 'Let\'s go!';

  @override
  String get didYouComplete => 'Did you complete the task?';

  @override
  String get yesCompleted => 'Yes, I completed it';

  @override
  String get notYet => 'Not yet';

  @override
  String get overallProgress => 'Overall progress';

  @override
  String get viewAll => 'View all';

  @override
  String get currentTaskLabel => 'CURRENT TASK';

  @override
  String taskNofM(Object n, Object total) {
    return 'Task $n of $total';
  }

  @override
  String pomodorosCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# pomodoros',
      one: '# pomodoro',
    );
    return '$_temp0';
  }

  @override
  String get continueLabel => 'Continue';

  @override
  String get startPomodoro => 'Start Pomodoro';

  @override
  String get pomodoroInProgressTitle => 'Pomodoro in progress';

  @override
  String get pomodoroCompleted => 'Pomodoro completed';

  @override
  String get alreadyActivePomodoro => 'You already have an active Pomodoro in:';

  @override
  String timeRemaining(Object time) {
    return '$time remaining';
  }

  @override
  String get finishBeforeNew =>
      'Finish or pause that Pomodoro before starting a new one.';

  @override
  String get gotIt => 'Got it';

  @override
  String get goToActivePomodoro => 'Go to active Pomodoro';

  @override
  String get deleteProject => 'Delete project';

  @override
  String get deleteProjectConfirm =>
      'Are you sure you want to delete this project? This action cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get projectCompleted => 'Project completed';

  @override
  String get allTasksCompleted => 'All tasks completed';

  @override
  String get projectSummary => 'PROJECT SUMMARY';

  @override
  String pomodoroLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pomodoros',
      one: 'pomodoro',
    );
    return '$_temp0';
  }

  @override
  String get totalTime => 'total time';

  @override
  String taskLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tasks',
      one: 'task',
    );
    return '$_temp0';
  }

  @override
  String get completedTasks => 'COMPLETED TASKS';

  @override
  String get allTasks => 'All tasks';

  @override
  String completedPendingCount(Object completed, Object pending) {
    return '$completed completed · $pending pending';
  }

  @override
  String get inProgressBadge => 'IN PROGRESS';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get alarmWorkTitle => 'Pomodoro complete!';

  @override
  String get alarmWorkBody => 'Take a break 🎉';

  @override
  String get alarmBreakTitle => 'Break over';

  @override
  String get alarmBreakBody => 'Ready to focus again 💪';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get focusDuration => 'Focus duration';

  @override
  String get focusBeginner => 'Beginner';

  @override
  String get focusFocused => 'Focused';

  @override
  String get focusClassic => 'Classic Pomodoro';

  @override
  String get focusCustom => 'Custom';

  @override
  String minutesValue(Object n) {
    return '$n min';
  }

  @override
  String get customDurationTitle => 'Custom duration';

  @override
  String get save => 'Save';

  @override
  String pomodoroProgress(Object done, Object estimate) {
    return '$done/$estimate 🍅';
  }

  @override
  String pomodoroEstimate(Object n) {
    return '$n 🍅';
  }

  @override
  String estimatedTotalPomodoros(Object n) {
    return '≈ $n 🍅 estimated';
  }

  @override
  String get streak => 'Streak';

  @override
  String get streakCurrent => 'Current';

  @override
  String get streakBest => 'Best';

  @override
  String daysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '$n day',
    );
    return '$_temp0';
  }

  @override
  String get progressTitle => 'Progress';

  @override
  String get statToday => 'Today';

  @override
  String get statThisWeek => 'This week';

  @override
  String get statTotalPomodoros => 'Total pomodoros';

  @override
  String get statFocusTime => 'Focus time';

  @override
  String get statTasksCompleted => 'Tasks completed';

  @override
  String get last7Days => 'Last 7 days';

  @override
  String get noStatsYet =>
      'Complete your first pomodoro to see your stats here.';

  @override
  String pomodoroOfEstimate(Object done, Object total) {
    return 'Pomodoro $done of $total';
  }

  @override
  String get overEstimateTitle => 'You hit your estimate';

  @override
  String get overEstimateBody =>
      'This task is taking longer than planned. What do you want to do?';

  @override
  String get oneMorePomodoro => 'One more pomodoro';

  @override
  String get splitTaskAction => 'Split the task';
}
