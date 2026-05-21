import 'micro_task.dart';

class Project {
  final String id;
  final String name;
  final String description;
  final String motivation;
  String status;
  DateTime? completedAt;
  List<MicroTask> tasks; // solo top-level (parent_id == null)

  final int _totalCount;
  final int _completedCount;

  Project({
    required this.id,
    required this.name,
    required this.description,
    this.motivation = '',
    this.status = 'active',
    this.completedAt,
    List<MicroTask>? tasks,
    int totalCount = 0,
    int completedCount = 0,
  })  : tasks = tasks ?? [],
        _totalCount = totalCount,
        _completedCount = completedCount;

  // Agrupa lista plana de tareas en jerarquía top-level → subtareas
  static List<MicroTask> buildHierarchy(List<MicroTask> flat) {
    final topLevel = flat.where((t) => t.parentId == null).toList();
    final byParent = <String, List<MicroTask>>{};
    for (final t in flat.where((t) => t.parentId != null)) {
      (byParent[t.parentId!] ??= []).add(t);
    }
    for (final t in topLevel) {
      t.subtasks = byParent[t.id] ?? [];
    }
    return topLevel;
  }

  bool get tasksLoaded => tasks.isNotEmpty || _totalCount == 0;

  int get completedCount =>
      tasks.isNotEmpty ? tasks.where((t) => t.isCompleted).length : _completedCount;

  int get totalCount =>
      tasks.isNotEmpty ? tasks.length : _totalCount;

  double get progress =>
      totalCount == 0 ? 0.0 : (completedCount / totalCount).clamp(0.0, 1.0);

  bool get isCompleted =>
      status == 'completed' ||
      (totalCount > 0 && completedCount >= totalCount);

  // Tarea top-level actualmente en progreso
  MicroTask? get currentTask {
    for (final task in tasks) {
      if (!task.isCompleted) return task;
    }
    return null;
  }

  // La unidad real de trabajo: subtarea si existe, si no la tarea directamente
  MicroTask? get activeWorkTask {
    for (final task in tasks) {
      if (task.isCompleted) continue;
      if (task.hasSubtasks) {
        final sub = task.activeSubtask;
        if (sub != null) return sub;
        continue;
      }
      return task;
    }
    return null;
  }

  int get currentTaskIndex {
    for (var i = 0; i < tasks.length; i++) {
      if (!tasks[i].isCompleted) return i;
    }
    return tasks.length;
  }

  factory Project.fromApiList(Map<String, dynamic> json) => Project.fromApi(json);

  factory Project.fromApi(Map<String, dynamic> json) {
    final flat = (json['tasks'] as List? ?? [])
        .map((t) => MicroTask.fromApi(t as Map<String, dynamic>))
        .toList();
    final rawDate = json['completed_at'];
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      motivation: json['motivation'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      completedAt: rawDate != null ? DateTime.tryParse(rawDate.toString()) : null,
      tasks: buildHierarchy(flat),
    );
  }

  Project withTasks(List<MicroTask> loadedTasks) => Project(
        id: id,
        name: name,
        description: description,
        motivation: motivation,
        status: status,
        completedAt: completedAt,
        tasks: buildHierarchy(loadedTasks),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'motivation': motivation,
        'status': status,
        'completed_at': completedAt?.toIso8601String(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'totalCount': _totalCount,
        'completedCount': _completedCount,
      };

  factory Project.fromJson(Map<String, dynamic> json) {
    final flat = (json['tasks'] as List? ?? [])
        .map((t) => MicroTask.fromJson(t as Map<String, dynamic>))
        .toList();
    final rawDate = json['completed_at'];
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      motivation: json['motivation'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      completedAt: rawDate != null ? DateTime.tryParse(rawDate.toString()) : null,
      tasks: buildHierarchy(flat),
      totalCount: json['totalCount'] as int? ?? 0,
      completedCount: json['completedCount'] as int? ?? 0,
    );
  }
}
