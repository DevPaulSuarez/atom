class MicroTask {
  final String id;
  final String title;
  bool isCompleted;
  int pomodorosCount;

  MicroTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.pomodorosCount = 0,
  });

  // Desde respuesta del backend (snake_case)
  factory MicroTask.fromApi(Map<String, dynamic> json) => MicroTask(
        id: json['id'] as String,
        title: json['title'] as String,
        isCompleted: json['is_completed'] as bool? ?? false,
      );

  // Persistencia local
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'pomodorosCount': pomodorosCount,
      };

  factory MicroTask.fromJson(Map<String, dynamic> json) => MicroTask(
        id: json['id'] as String,
        title: json['title'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
        pomodorosCount: json['pomodorosCount'] as int? ?? 0,
      );
}
