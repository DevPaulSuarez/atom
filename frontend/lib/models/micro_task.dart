class MicroTask {
  final String id;
  final String? parentId;
  final String title;
  bool isCompleted;
  int pomodorosCount;
  final int estimatedPomodoros; // estimado por la IA al crear/dividir
  List<MicroTask> subtasks;

  MicroTask({
    required this.id,
    this.parentId,
    required this.title,
    this.isCompleted = false,
    this.pomodorosCount = 0,
    this.estimatedPomodoros = 1,
    List<MicroTask>? subtasks,
  }) : subtasks = subtasks ?? [];

  bool get hasSubtasks => subtasks.isNotEmpty;
  bool get allSubtasksDone => hasSubtasks && subtasks.every((s) => s.isCompleted);

  int get totalPomodorosWithSubs =>
      pomodorosCount + subtasks.fold(0, (sum, s) => sum + s.pomodorosCount);

  /// Pomodoros estimados incluyendo subtareas (si las hay).
  int get estimatedWithSubs => hasSubtasks
      ? subtasks.fold(0, (sum, s) => sum + s.estimatedPomodoros)
      : estimatedPomodoros;

  MicroTask? get activeSubtask {
    for (final s in subtasks) {
      if (!s.isCompleted) return s;
    }
    return null;
  }

  factory MicroTask.fromApi(Map<String, dynamic> json) => MicroTask(
        id: json['id'] as String,
        parentId: json['parent_id'] as String?,
        title: json['title'] as String,
        isCompleted: json['is_completed'] as bool? ?? false,
        pomodorosCount: (json['pomodoros_count'] as num?)?.toInt() ?? 0,
        estimatedPomodoros: (json['estimated_pomodoros'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'parentId': parentId,
        'title': title,
        'isCompleted': isCompleted,
        'pomodorosCount': pomodorosCount,
        'estimatedPomodoros': estimatedPomodoros,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
      };

  factory MicroTask.fromJson(Map<String, dynamic> json) => MicroTask(
        id: json['id'] as String,
        parentId: json['parentId'] as String?,
        title: json['title'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
        pomodorosCount: json['pomodorosCount'] as int? ?? 0,
        estimatedPomodoros: json['estimatedPomodoros'] as int? ?? 1,
        subtasks: (json['subtasks'] as List? ?? [])
            .map((s) => MicroTask.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}
