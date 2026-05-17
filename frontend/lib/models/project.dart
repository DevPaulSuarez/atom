import 'micro_task.dart';

class Project {
  final String id;
  final String name;
  final String description;
  String status; // 'active' | 'completed' | 'archived'
  List<MicroTask> tasks;

  // Conteos del endpoint de lista (cuando tasks aún no está cargado)
  final int _totalCount;
  final int _completedCount;

  Project({
    required this.id,
    required this.name,
    required this.description,
    this.status = 'active',
    List<MicroTask>? tasks,
    int totalCount = 0,
    int completedCount = 0,
  })  : tasks = tasks ?? [],
        _totalCount = totalCount,
        _completedCount = completedCount;

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

  MicroTask? get currentTask {
    for (final task in tasks) {
      if (!task.isCompleted) return task;
    }
    return null;
  }

  int get currentTaskIndex {
    for (var i = 0; i < tasks.length; i++) {
      if (!tasks[i].isCompleted) return i;
    }
    return tasks.length;
  }

  // Desde GET /projects (lista, ya incluye tasks con json_agg)
  factory Project.fromApiList(Map<String, dynamic> json) => Project.fromApi(json);

  // Desde GET /projects/:id o POST /projects (con tasks)
  factory Project.fromApi(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        status: json['status'] as String? ?? 'active',
        tasks: (json['tasks'] as List? ?? [])
            .map((t) => MicroTask.fromApi(t as Map<String, dynamic>))
            .toList(),
      );

  // Copia con tasks cargadas
  Project withTasks(List<MicroTask> loadedTasks) => Project(
        id: id,
        name: name,
        description: description,
        status: status,
        tasks: loadedTasks,
      );

  // Persistencia local (cache offline)
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'status': status,
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'totalCount': _totalCount,
        'completedCount': _completedCount,
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        status: json['status'] as String? ?? 'active',
        tasks: (json['tasks'] as List? ?? [])
            .map((t) => MicroTask.fromJson(t as Map<String, dynamic>))
            .toList(),
        totalCount: json['totalCount'] as int? ?? 0,
        completedCount: json['completedCount'] as int? ?? 0,
      );
}
