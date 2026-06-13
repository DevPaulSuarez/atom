import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/micro_task.dart';
import '../models/progress_stats.dart';
import '../models/project.dart';
import '../services/api_service.dart';

export '../services/api_service.dart' show ApiException;

enum PomodoroPhase { idle, working, paused, shortBreak, longBreak, askComplete, breakDone }

class AppState extends ChangeNotifier {
  final _api = ApiService();

  List<Project> _projects = [];
  Project? _activeProject;
  PomodoroPhase _phase = PomodoroPhase.idle;
  int _remainingSeconds = _kDefaultWorkMinutes * 60;
  int _completedPomodoros = 0;
  Timer? _timer;
  bool _isDarkMode = true; // oscuro por defecto
  String _localeMode = 'system'; // 'system' | 'en' | 'es'
  bool _hasSeenOnboarding = false;
  final _ringtone = FlutterRingtonePlayer();

  bool _authLoaded = false;
  bool _projectsLoading = false;
  String? _projectsError;
  int _incompleteCount = 0;
  bool _isSplitting = false;
  bool _showMotivation = false;
  String _coachMessage = '';
  int _splitCount = 0;

  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _sessionStart; // inicio de la fase actual, para el historial

  static const _kShortBreak = 5 * 60;
  static const _kLongBreak = 20 * 60;
  static const _kCycleLength = 4;
  static const _storageKey = 'atom_projects_cache_v2';
  static const _kDarkMode = 'atom_dark_mode';
  static const _kOnboarding = 'atom_onboarding_done';
  static const _kLocale = 'atom_locale';

  // Duración del enfoque: por proyecto (no global). Estos son los presets que
  // se ofrecen al crear/editar un proyecto.
  static const _kDefaultWorkMinutes = 25;
  static const minCustomMinutes = 1;
  static const maxCustomMinutes = 90;
  static const focusPresets = {'beginner': 10, 'focused': 18, 'classic': 25};

  // ── Getters ────────────────────────────────────────────────────────────────

  List<Project> get projects => _projects;
  Project? get activeProject => _activeProject;
  PomodoroPhase get phase => _phase;
  int get remainingSeconds => _remainingSeconds;
  bool get isDarkMode => _isDarkMode;

  /// Duración por defecto al crear un proyecto nuevo (Pomodoro clásico).
  int get focusMinutes => _kDefaultWorkMinutes;

  /// Segundos de trabajo de la sesión actual: usa la duración del proyecto activo.
  int get _workSeconds =>
      (_activeProject?.focusMinutes ?? _kDefaultWorkMinutes) * 60;

  /// 'system' | 'en' | 'es'
  String get localeMode => _localeMode;

  /// Locale forzado para MaterialApp, o null para seguir el idioma del sistema.
  Locale? get locale => _localeMode == 'system' ? null : Locale(_localeMode);

  /// Locale efectivo (resuelve 'system' al idioma del dispositivo).
  Locale get _effectiveLocale {
    if (_localeMode != 'system') return Locale(_localeMode);
    final device = PlatformDispatcher.instance.locale;
    return device.languageCode == 'es' ? const Locale('es') : const Locale('en');
  }

  /// Cadenas localizadas para mensajes generados fuera del árbol de widgets.
  AppLocalizations get _l10n => lookupAppLocalizations(_effectiveLocale);
  bool get isRunning => _phase == PomodoroPhase.working;
  bool get isBreak =>
      _phase == PomodoroPhase.shortBreak || _phase == PomodoroPhase.longBreak;
  bool get isLongBreak => _phase == PomodoroPhase.longBreak;
  int get completedInCycle => _completedPomodoros % _kCycleLength;
  int get sessionNumber => completedInCycle + 1;
  bool get isLoggedIn => _api.hasSession;
  bool get authLoaded => _authLoaded;
  bool get projectsLoading => _projectsLoading;
  String? get projectsError => _projectsError;
  String get userName => _api.userName;
  bool get isTester => _api.isTester;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get isSplitting => _isSplitting;
  bool get showMotivation => _showMotivation;
  String get coachMessage => _coachMessage;
  int get splitCount => _splitCount;
  int get incompleteCount => _incompleteCount;
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;

  String get formattedTime {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get timerProgress {
    final total = switch (_phase) {
      PomodoroPhase.shortBreak => _kShortBreak,
      PomodoroPhase.longBreak => _kLongBreak,
      _ => _workSeconds,
    };
    return 1.0 - (_remainingSeconds / total).clamp(0.0, 1.0);
  }

  AppState() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_kDarkMode) ?? true; // oscuro por defecto
    _localeMode = prefs.getString(_kLocale) ?? 'system';
    _hasSeenOnboarding = prefs.getBool(_kOnboarding) ?? false;
    await _api.loadSession();
    _authLoaded = true;
    if (_api.hasSession) {
      await _loadProjects();
      _loadStreak();
    }
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasSeenOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboarding, true);
    notifyListeners();
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  Future<String?> register(String name, String email, String password) async {
    try {
      final data = await _api.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
      }) as Map<String, dynamic>;

      final user = data['user'] as Map<String, dynamic>;
      await _api.saveSession(
        data['accessToken'] as String,
        data['refreshToken'] as String,
        user['name'] as String,
        isTester: (user['is_tester'] as dynamic) == true || (user['is_tester'] as dynamic) == 1,
      );
      await _loadProjects();
      _loadStreak();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return _l10n.connectionErrorServer;
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final data = await _api.post('/auth/login', {
        'email': email,
        'password': password,
      }) as Map<String, dynamic>;

      final user = data['user'] as Map<String, dynamic>;
      await _api.saveSession(
        data['accessToken'] as String,
        data['refreshToken'] as String,
        user['name'] as String,
        isTester: (user['is_tester'] as dynamic) == true || (user['is_tester'] as dynamic) == 1,
      );
      await _loadProjects();
      _loadStreak();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return _l10n.connectionErrorServer;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final refreshToken = data['refreshToken'] as String?;
        if (refreshToken != null) {
          await _api.post('/auth/logout', {'refreshToken': refreshToken});
        }
      }
    } catch (_) {}
    await _api.clearSession();
    _reset();
    notifyListeners();
  }

  void _reset() {
    _projects = [];
    _activeProject = null;
    _stopTimer();
    stopAlarm();
    _phase = PomodoroPhase.idle;
    _completedPomodoros = 0;
    _incompleteCount = 0;
    _isSplitting = false;
    _showMotivation = false;
    _coachMessage = '';
    _splitCount = 0;
    _currentStreak = 0;
    _longestStreak = 0;
    _sessionStart = null;
  }

  // ── Streaks & historial ──────────────────────────────────────────────────────

  Future<void> _loadStreak() async {
    try {
      final data = await _api.get('/streak') as Map<String, dynamic>;
      _currentStreak = (data['currentStreak'] as num?)?.toInt() ?? 0;
      _longestStreak = (data['longestStreak'] as num?)?.toInt() ?? 0;
      notifyListeners();
    } catch (_) {}
  }

  /// Llamado al completar un pomodoro de trabajo; actualiza la racha.
  Future<void> _pingStreak() async {
    try {
      final data = await _api.patch('/streak/ping', {}) as Map<String, dynamic>;
      _currentStreak = (data['currentStreak'] as num?)?.toInt() ?? _currentStreak;
      _longestStreak = (data['longestStreak'] as num?)?.toInt() ?? _longestStreak;
      notifyListeners();
    } catch (_) {}
  }

  /// Carga las estadísticas de productividad del usuario.
  Future<ProgressStats?> loadStats() async {
    try {
      final data = await _api.get('/sessions/stats') as Map<String, dynamic>;
      return ProgressStats.fromApi(data);
    } catch (_) {
      return null;
    }
  }

  /// Registra una sesión (trabajo o descanso) en el historial del backend.
  Future<void> _recordSession(String type, {bool skipped = false}) async {
    final taskId = _activeProject?.activeWorkTask?.id;
    if (taskId == null) return;
    final end = DateTime.now();
    final start = _sessionStart ?? end;
    try {
      await _api.post('/sessions', {
        'microTaskId': taskId,
        'type': type,
        'startedAt': start.toUtc().toIso8601String(),
        'endedAt': end.toUtc().toIso8601String(),
        'wasSkipped': skipped,
      });
    } catch (_) {}
  }

  // ── Projects ───────────────────────────────────────────────────────────────

  Future<void> _loadProjects() async {
    _projectsLoading = true;
    _projectsError = null;
    notifyListeners();

    try {
      final data = await _api.get('/projects') as List;
      _projects = data
          .map((e) => Project.fromApiList(e as Map<String, dynamic>))
          .toList();
      _projectsError = null;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _api.clearSession();
      }
      _projectsError = e.message;
      _projects = _loadCachedProjects();
    } catch (_) {
      _projectsError = _l10n.offline;
      _projects = _loadCachedProjects();
    } finally {
      _projectsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProjects() => _loadProjects();

  void setActiveProject(Project project) {
    final changed = _activeProject?.id != project.id;
    _activeProject = project;
    if (changed) {
      _stopTimer();
      stopAlarm();
      _phase = PomodoroPhase.idle;
      _remainingSeconds = _workSeconds; // usa la duración del nuevo proyecto
      _completedPomodoros = 0;
      _incompleteCount = 0;
    }
    notifyListeners();
  }

  Future<String?> addProject(String name, String description, String motivation,
      {int? focusMinutes}) async {
    try {
      final data = await _api.post('/projects', {
        'name': name,
        'description': description,
        'motivation': motivation,
        'focusMinutes': focusMinutes ?? this.focusMinutes,
      }) as Map<String, dynamic>;

      final project = Project.fromApi(data);
      _projects.insert(0, project);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return _l10n.connectionError;
    }
  }

  Future<void> deleteProject(String id) async {
    _projects.removeWhere((p) => p.id == id);
    if (_activeProject?.id == id) {
      _stopTimer();
      stopAlarm();
      _activeProject = null;
      _phase = PomodoroPhase.idle;
      _completedPomodoros = 0;
    }
    notifyListeners();
    try {
      await _api.delete('/projects/$id');
    } catch (_) {
      // optimistic — si falla, el próximo refresh lo restaurará
    }
  }

  // ── Pomodoro ───────────────────────────────────────────────────────────────

  void startPomodoro() {
    stopAlarm();
    _phase = PomodoroPhase.working;
    _remainingSeconds = _workSeconds;
    _sessionStart = DateTime.now();
    _startTimer();
    notifyListeners();
  }

  void pausePomodoro() {
    _stopTimer();
    _phase = PomodoroPhase.paused;
    notifyListeners();
  }

  void resumePomodoro() {
    _phase = PomodoroPhase.working;
    _startTimer();
    notifyListeners();
  }

  Future<void> completeCurrentTask() async {
    final workTask = _activeProject?.activeWorkTask;
    if (workTask != null) {
      workTask.isCompleted = true;
      _incompleteCount = 0;

      // Si era una subtarea, verificar si el padre se completa también
      if (workTask.parentId != null) {
        final parent = _activeProject?.currentTask;
        if (parent != null && parent.id == workTask.parentId && parent.allSubtasksDone) {
          parent.isCompleted = true;
        }
      }

      try {
        await _api.patch('/tasks/${workTask.id}', {'isCompleted': true});
        final proj = _activeProject;
        if (proj != null && proj.tasks.every((t) => t.isCompleted)) {
          proj.status = 'completed';
        }
      } catch (_) {}
    }
    stopAlarm();
    _startBreak();
    notifyListeners();
  }

  /// La unidad de trabajo actual: ¿ya alcanzó (o pasó) sus pomodoros estimados?
  /// Solo aplica a tareas top-level (las subtareas no se dividen).
  bool get atOrOverEstimate {
    final w = _activeProject?.activeWorkTask;
    return w != null &&
        w.parentId == null &&
        w.pomodorosCount >= w.estimatedPomodoros;
  }

  /// "Todavía no terminé": toma el descanso y continúa la misma tarea.
  /// (Ya no divide automáticamente; la división es una elección explícita.)
  void continueAfterIncomplete() {
    stopAlarm();
    _startBreak();
  }

  Future<void> splitCurrentTask() async {
    stopAlarm();
    final task = _activeProject?.activeWorkTask;
    if (task == null || _activeProject == null) {
      _startBreak();
      return;
    }
    _phase = PomodoroPhase.idle;
    _isSplitting = true;
    notifyListeners();

    try {
      final data = await _api.post('/tasks/${task.id}/split', {}) as Map<String, dynamic>;
      final flat = (data['tasks'] as List)
          .map((t) => MicroTask.fromApi(t as Map<String, dynamic>))
          .toList();
      _activeProject!.tasks = Project.buildHierarchy(flat);
      _coachMessage = data['coachMessage'] as String? ?? '';
      _splitCount = (data['splitCount'] as num?)?.toInt() ?? 0;
      _incompleteCount = 0;
      _isSplitting = false;
      _phase = PomodoroPhase.idle;
      _remainingSeconds = _workSeconds;
      _showMotivation = true;
    } catch (_) {
      _incompleteCount = 0;
      _isSplitting = false;
      _phase = PomodoroPhase.idle;
      _remainingSeconds = _workSeconds;
    }
    notifyListeners();
  }

  void _startBreak() {
    if (_completedPomodoros % _kCycleLength == 0) {
      _phase = PomodoroPhase.longBreak;
      _remainingSeconds = _kLongBreak;
    } else {
      _phase = PomodoroPhase.shortBreak;
      _remainingSeconds = _kShortBreak;
    }
    _sessionStart = DateTime.now();
    _startTimer();
    notifyListeners();
  }

  void skipPhase() {
    _stopTimer();
    _remainingSeconds = 0;
    _onPhaseEnd(skipped: true);
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkMode, _isDarkMode);
    notifyListeners();
  }

  /// Cambia la duración del enfoque de un proyecto. Si es el proyecto activo y
  /// no hay sesión en curso, refleja el cambio en el reloj de inmediato (sin
  /// interrumpir un Pomodoro activo). Persiste en el backend.
  Future<void> updateProjectFocusMinutes(String projectId, int minutes) async {
    final m = minutes.clamp(minCustomMinutes, maxCustomMinutes);
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx != -1) _projects[idx].focusMinutes = m;
    if (_activeProject?.id == projectId) {
      _activeProject!.focusMinutes = m;
      if (_phase == PomodoroPhase.idle) _remainingSeconds = _workSeconds;
    }
    notifyListeners();
    try {
      await _api.patch('/projects/$projectId', {'focusMinutes': m});
    } catch (_) {
      // optimista — el próximo refresh corrige si falla
    }
  }

  /// mode: 'system' | 'en' | 'es'
  Future<void> setLocaleMode(String mode) async {
    if (_localeMode == mode) return;
    _localeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocale, mode);
    notifyListeners();
  }

  // ── Alarm ──────────────────────────────────────────────────────────────────

  void _playAlarm() {
    if (kIsWeb) return;
    try {
      _ringtone.playAlarm(looping: true, volume: 0.6);
    } catch (_) {}
  }

  void stopAlarm() {
    if (kIsWeb) return;
    try {
      _ringtone.stop();
    } catch (_) {}
  }

  void playCelebration() {
    if (kIsWeb) return;
    try {
      _ringtone.playNotification(volume: 0.5);
    } catch (_) {}
  }

  // ── Timer ──────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    if (_remainingSeconds > 0) {
      _remainingSeconds--;
      notifyListeners();
    } else {
      _stopTimer();
      _onPhaseEnd();
    }
  }

  void _onPhaseEnd({bool skipped = false}) {
    if (_phase == PomodoroPhase.working) {
      _activeProject?.activeWorkTask?.pomodorosCount++;
      _completedPomodoros++;
      _recordSession('work', skipped: skipped);
      if (!skipped) _pingStreak(); // un pomodoro real mantiene la racha
      _phase = PomodoroPhase.askComplete;
      _persistPomodoroCount();
      _playAlarm();
    } else if (_phase == PomodoroPhase.shortBreak ||
        _phase == PomodoroPhase.longBreak) {
      _recordSession(
          _phase == PomodoroPhase.longBreak ? 'long_break' : 'short_break',
          skipped: skipped);
      _phase = PomodoroPhase.breakDone;
      _remainingSeconds = _workSeconds;
      _playAlarm();
    }
    notifyListeners();
  }

  void dismissBreak() {
    stopAlarm();
    _phase = PomodoroPhase.idle;
    notifyListeners();
  }

  void dismissMotivation() {
    _showMotivation = false;
    notifyListeners();
  }

  Future<void> _persistPomodoroCount() async {
    final task = _activeProject?.activeWorkTask;
    if (task == null) return;
    try {
      await _api.patch('/tasks/${task.id}', {'pomodorosCount': task.pomodorosCount});
    } catch (_) {}
  }

  // ── Cache offline ──────────────────────────────────────────────────────────

  List<Project> _loadCachedProjects() {
    return [];
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _timer?.cancel();
    stopAlarm();
    super.dispose();
  }
}
