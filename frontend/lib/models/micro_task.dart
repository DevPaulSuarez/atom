class MicroTask {
  final String id;
  final String? parentId;
  final String title;
  bool isCompleted;
  int pomodorosCount;
  List<MicroTask> subtasks;

  MicroTask({
    required this.id,
    this.parentId,
    required this.title,
    this.isCompleted = false,
    this.pomodorosCount = 0,
    List<MicroTask>? subtasks,
  }) : subtasks = subtasks ?? [];

  bool get hasSubtasks => subtasks.isNotEmpty;
  bool get allSubtasksDone => hasSubtasks && subtasks.every((s) => s.isCompleted);

  int get totalPomodorosWithSubs =>
      pomodorosCount + subtasks.fold(0, (sum, s) => sum + s.pomodorosCount);

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
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'parentId': parentId,
        'title': title,
        'isCompleted': isCompleted,
        'pomodorosCount': pomodorosCount,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
      };

  factory MicroTask.fromJson(Map<String, dynamic> json) => MicroTask(
        id: json['id'] as String,
        parentId: json['parentId'] as String?,
        title: json['title'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
        pomodorosCount: json['pomodorosCount'] as int? ?? 0,
        subtasks: (json['subtasks'] as List? ?? [])
            .map((s) => MicroTask.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}
