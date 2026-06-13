// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get authTagline => 'Productividad con método Pomodoro';

  @override
  String get tabRegister => 'Registrarse';

  @override
  String get tabLogin => 'Iniciar sesión';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get signIn => 'Entrar';

  @override
  String get hintName => 'Tu nombre';

  @override
  String get hintEmail => 'Email';

  @override
  String get hintPassword => 'Contraseña';

  @override
  String get fillAllFields => 'Completa todos los campos';

  @override
  String get invalidEmail => 'Email inválido';

  @override
  String get passwordTooShort =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get connectionErrorServer =>
      'Error de conexión. ¿Está el servidor corriendo?';

  @override
  String get connectionError => 'Error de conexión';

  @override
  String get offline => 'Sin conexión';

  @override
  String get skip => 'Saltar';

  @override
  String get next => 'Siguiente';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get onbTitle1 => 'Bienvenido a Atom';

  @override
  String get onbBody1 =>
      'Tu compañero de productividad basado en el método Pomodoro. Trabaja en ciclos de enfoque y descanso para rendir al máximo.';

  @override
  String get onbTitle2 => 'IA genera tu plan';

  @override
  String get onbBody2 =>
      'Describe tu proyecto y la inteligencia artificial lo divide en microtareas concretas y accionables, listas para ejecutar.';

  @override
  String get onbTitle3 => 'Una tarea a la vez';

  @override
  String get onbBody3 =>
      'Enfócate en una sola microtarea por sesión. Al terminar, avanza a la siguiente de forma automática y mantén el ritmo.';

  @override
  String get onbTitle4 => 'Ciclos Pomodoro';

  @override
  String get onbBody4 =>
      '25 min de trabajo · 5 min de descanso · cada 4 ciclos un descanso largo. La alarma te avisa, tú decides cuándo continuar.';

  @override
  String greeting(Object name) {
    return 'Hola, $name 👋';
  }

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get newProject => 'Nuevo proyecto';

  @override
  String get newProjectSubtitle => 'La IA generará las tareas automáticamente';

  @override
  String get fieldProjectName => 'Nombre del proyecto';

  @override
  String get hintProjectName => 'ej. Aprender Flutter';

  @override
  String get fieldDescription => 'Descripción (opcional)';

  @override
  String get hintDescription =>
      'ej. Crear apps móviles con Dart y Flutter desde cero';

  @override
  String get fieldMotivation => '¿Por qué quieres terminar esto? (opcional)';

  @override
  String get hintMotivation => 'ej. Conseguir trabajo como desarrollador';

  @override
  String get generatingTasks => 'Generando tareas con IA...';

  @override
  String get createProject => 'Crear proyecto';

  @override
  String get emptyTitle => 'Sin proyectos aún';

  @override
  String get emptyBody =>
      'Crea tu primer proyecto y la IA\ngenerará las tareas automáticamente.';

  @override
  String get completedLabel => 'Completado';

  @override
  String tasksCount(Object completed, Object total) {
    return '$completed de $total tareas';
  }

  @override
  String statusInProgress(Object time) {
    return 'En curso · $time';
  }

  @override
  String statusBreak(Object time) {
    return 'Descanso · $time';
  }

  @override
  String statusLongBreak(Object time) {
    return 'Descanso largo · $time';
  }

  @override
  String statusPaused(Object time) {
    return 'Pausado · $time';
  }

  @override
  String get pomodoro => 'Pomodoro';

  @override
  String get minutesLower => 'minutos';

  @override
  String get restLower => 'descansa';

  @override
  String get longBreakLower => 'descanso largo';

  @override
  String get pause => 'Pausar';

  @override
  String get skipPhase => 'Saltar fase';

  @override
  String get skipBreak => 'Saltar descanso';

  @override
  String get skipLongBreak => 'Saltar descanso largo';

  @override
  String get breakOngoing => 'Descansando...';

  @override
  String get longBreakOngoing => 'Descanso largo...';

  @override
  String get projectCompletedExclaim => '¡Proyecto completado!';

  @override
  String get start => 'Comenzar';

  @override
  String get pomodoroOngoing => 'Pomodoro en curso...';

  @override
  String get resume => 'Reanudar';

  @override
  String get phaseWorking => 'TRABAJANDO';

  @override
  String get phasePaused => 'EN PAUSA';

  @override
  String get phaseShortBreak => 'DESCANSO CORTO';

  @override
  String get phaseLongBreak => 'DESCANSO LARGO';

  @override
  String get phaseSessionComplete => 'SESIÓN COMPLETA';

  @override
  String get phaseBreakDone => 'DESCANSASTE';

  @override
  String get phaseReady => 'LISTO';

  @override
  String get cycleComplete => '¡Ciclo completo! Bien merecido descanso';

  @override
  String sessionCompletedOf(Object n) {
    return 'Sesión $n de 4 completada';
  }

  @override
  String sessionOf(Object n) {
    return 'Sesión $n de 4';
  }

  @override
  String get analyzingTask => 'La IA está analizando la tarea...';

  @override
  String get blockMomentTitle => 'Un momento de bloqueo';

  @override
  String splitIntoSteps(Object n) {
    return 'Dividí la tarea en $n pasos más pequeños.';
  }

  @override
  String get whyStarted => 'POR QUÉ EMPEZASTE';

  @override
  String get yourCoach => 'Tu coach';

  @override
  String get tryAgain => 'Volver a intentar';

  @override
  String get breakOverTitle => '¡Descanso terminado!';

  @override
  String get breakOverBody =>
      'Es hora de retomar el enfoque. ¿Listo para el siguiente Pomodoro?';

  @override
  String get letsGo => '¡Vamos!';

  @override
  String get didYouComplete => '¿Completaste la tarea?';

  @override
  String get yesCompleted => 'Sí, la completé';

  @override
  String get notYet => 'Todavía no';

  @override
  String get overallProgress => 'Progreso general';

  @override
  String get viewAll => 'Ver todas';

  @override
  String get currentTaskLabel => 'TAREA ACTUAL';

  @override
  String taskNofM(Object n, Object total) {
    return 'Tarea $n de $total';
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
  String get continueLabel => 'Continuar';

  @override
  String get startPomodoro => 'Iniciar Pomodoro';

  @override
  String get pomodoroInProgressTitle => 'Pomodoro en curso';

  @override
  String get pomodoroCompleted => 'Pomodoro completado';

  @override
  String get alreadyActivePomodoro => 'Ya tienes un Pomodoro activo en:';

  @override
  String timeRemaining(Object time) {
    return '$time restantes';
  }

  @override
  String get finishBeforeNew =>
      'Termina o pausa ese Pomodoro antes de empezar uno nuevo.';

  @override
  String get gotIt => 'Entendido';

  @override
  String get goToActivePomodoro => 'Ir al Pomodoro activo';

  @override
  String get deleteProject => 'Eliminar proyecto';

  @override
  String get deleteProjectConfirm =>
      '¿Seguro que quieres eliminar este proyecto? Esta acción no se puede deshacer.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get projectCompleted => 'Proyecto completado';

  @override
  String get allTasksCompleted => 'Todas las tareas completadas';

  @override
  String get projectSummary => 'RESUMEN DEL PROYECTO';

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
  String get totalTime => 'tiempo total';

  @override
  String taskLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tareas',
      one: 'tarea',
    );
    return '$_temp0';
  }

  @override
  String get completedTasks => 'TAREAS COMPLETADAS';

  @override
  String get allTasks => 'Todas las tareas';

  @override
  String completedPendingCount(Object completed, Object pending) {
    return '$completed completadas · $pending pendientes';
  }

  @override
  String get inProgressBadge => 'EN CURSO';

  @override
  String get settings => 'Ajustes';

  @override
  String get appearance => 'Apariencia';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get language => 'Idioma';

  @override
  String get systemDefault => 'Sistema';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get focusDuration => 'Duración del enfoque';

  @override
  String get focusBeginner => 'Principiante';

  @override
  String get focusFocused => 'Enfocado';

  @override
  String get focusClassic => 'Pomodoro clásico';

  @override
  String get focusCustom => 'Personalizado';

  @override
  String minutesValue(Object n) {
    return '$n min';
  }

  @override
  String get customDurationTitle => 'Duración personalizada';

  @override
  String get save => 'Guardar';

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
    return '≈ $n 🍅 estimados';
  }

  @override
  String get streak => 'Racha';

  @override
  String get streakCurrent => 'Actual';

  @override
  String get streakBest => 'Mejor';

  @override
  String daysCount(num n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# días',
      one: '# día',
    );
    return '$_temp0';
  }

  @override
  String get progressTitle => 'Progreso';

  @override
  String get statToday => 'Hoy';

  @override
  String get statThisWeek => 'Esta semana';

  @override
  String get statTotalPomodoros => 'Pomodoros totales';

  @override
  String get statFocusTime => 'Tiempo de enfoque';

  @override
  String get statTasksCompleted => 'Tareas completadas';

  @override
  String get last7Days => 'Últimos 7 días';

  @override
  String get noStatsYet =>
      'Completa tu primer pomodoro para ver tus estadísticas aquí.';

  @override
  String pomodoroOfEstimate(Object done, Object total) {
    return 'Pomodoro $done de $total';
  }

  @override
  String get overEstimateTitle => 'Llegaste a tu estimado';

  @override
  String get overEstimateBody =>
      'Esta tarea está tomando más de lo planeado. ¿Qué quieres hacer?';

  @override
  String get oneMorePomodoro => 'Un pomodoro más';

  @override
  String get splitTaskAction => 'Dividir la tarea';
}
