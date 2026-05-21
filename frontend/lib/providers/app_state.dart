import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/micro_task.dart';
import '../models/project.dart';
import '../services/api_service.dart';

export '../services/api_service.dart' show ApiException;

enum PomodoroPhase { idle, working, paused, shortBreak, longBreak, askComplete }

class AppState extends ChangeNotifier {
  final _api = ApiService();

  List<Project> _projects = [];
  Project? _activeProject;
  PomodoroPhase _phase = PomodoroPhase.idle;
  int _remainingSeconds = _kWork;
  int _completedPomodoros = 0;
  Timer? _timer;
  bool _isDarkMode = true; // oscuro por defecto
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

  static const _kWork = 25 * 60;
  static const _kShortBreak = 5 * 60;
  static const _kLongBreak = 20 * 60;
  static const _kCycleLength = 4;
  static const _storageKey = 'atom_projects_cache_v2';
  static const _kDarkMode = 'atom_dark_mode';
  static const _kOnboarding = 'atom_onboarding_done';

  // ── Getters ────────────────────────────────────────────────────────────────

  List<Project> get projects => _projects;
  Project? get activeProject => _activeProject;
  PomodoroPhase get phase => _phase;
  int get remainingSeconds => _remainingSeconds;
  bool get isDarkMode => _isDarkMode;
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

  String get formattedTime {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get timerProgress {
    final total = switch (_phase) {
      PomodoroPhase.shortBreak => _kShortBreak,
      PomodoroPhase.longBreak => _kLongBreak,
      _ => _kWork,
    };
    return 1.0 - (_remainingSeconds / total).clamp(0.0, 1.0);
  }

  AppState() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_kDarkMode) ?? true; // oscuro por defecto
    _hasSeenOnboarding = prefs.getBool(_kOnboarding) ?? false;
    await _api.loadSession();
    _authLoaded = true;
    if (_api.hasSession) await _loadProjects();
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
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Error de conexión. ¿Está el servidor corriendo?';
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
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Error de conexión. ¿Está el servidor corriendo?';
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
      _projectsError = 'Sin conexión';
      _projects = _loadCachedProjects();
    } finally {
      _projectsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProjects() => _loadProjects();

  void setActiveProject(Project project) {
    if (_activeProject?.id != project.id) {
      _stopTimer();
      stopAlarm();
      _phase = PomodoroPhase.idle;
      _remainingSeconds = _kWork;
      _completedPomodoros = 0;
      _incompleteCount = 0;
    }
    _activeProject = project;
    notifyListeners();
  }

  Future<String?> addProject(String name, String description, String motivation) async {
    try {
      final data = await _api.post('/projects', {
        'name': name,
        'description': description,
        'motivation': motivation,
      }) as Map<String, dynamic>;

      final project = Project.fromApi(data);
      _projects.insert(0, project);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Error de conexión';
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
    _remainingSeconds = _kWork;
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

  Future<void> continueCurrentTask() async {
    _incompleteCount++;
    stopAlarm();
    final workTask = _activeProject?.activeWorkTask;
    // No dividir subtareas (máximo 2 niveles)
    if (_incompleteCount >= 2 && workTask?.parentId == null) {
      await _splitCurrentTask();
    } else {
      _startBreak();
    }
  }

  Future<void> _splitCurrentTask() async {
    final task = _activeProject?.activeWorkTask;
    if (task == null || _activeProject == null) {
      _incompleteCount = 0;
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
      _remainingSeconds = _kWork;
      _showMotivation = true;
    } catch (_) {
      _incompleteCount = 0;
      _isSplitting = false;
      _phase = PomodoroPhase.idle;
      _remainingSeconds = _kWork;
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
    _startTimer();
    notifyListeners();
  }

  void skipPhase() {
    _stopTimer();
    _remainingSeconds = 0;
    _onPhaseEnd();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkMode, _isDarkMode);
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

  void _onPhaseEnd() {
    if (_phase == PomodoroPhase.working) {
      _activeProject?.activeWorkTask?.pomodorosCount++;
      _completedPomodoros++;
      _phase = PomodoroPhase.askComplete;
      _persistPomodoroCount();
    } else if (_phase == PomodoroPhase.shortBreak ||
        _phase == PomodoroPhase.longBreak) {
      _phase = PomodoroPhase.idle;
      _remainingSeconds = _kWork;
    }
    _playAlarm();
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
