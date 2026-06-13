class DailyStat {
  final DateTime date;
  final int pomodoros;
  final int minutes;

  DailyStat({required this.date, required this.pomodoros, required this.minutes});

  factory DailyStat.fromApi(Map<String, dynamic> json) => DailyStat(
        date: DateTime.parse(json['date'] as String),
        pomodoros: (json['pomodoros'] as num?)?.toInt() ?? 0,
        minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      );
}

class ProgressStats {
  final int totalPomodoros;
  final int totalMinutes;
  final int todayPomodoros;
  final int weekPomodoros;
  final int tasksCompleted;
  final List<DailyStat> daily;

  ProgressStats({
    required this.totalPomodoros,
    required this.totalMinutes,
    required this.todayPomodoros,
    required this.weekPomodoros,
    required this.tasksCompleted,
    required this.daily,
  });

  factory ProgressStats.fromApi(Map<String, dynamic> json) => ProgressStats(
        totalPomodoros: (json['totalPomodoros'] as num?)?.toInt() ?? 0,
        totalMinutes: (json['totalMinutes'] as num?)?.toInt() ?? 0,
        todayPomodoros: (json['todayPomodoros'] as num?)?.toInt() ?? 0,
        weekPomodoros: (json['weekPomodoros'] as num?)?.toInt() ?? 0,
        tasksCompleted: (json['tasksCompleted'] as num?)?.toInt() ?? 0,
        daily: (json['daily'] as List? ?? [])
            .map((d) => DailyStat.fromApi(d as Map<String, dynamic>))
            .toList(),
      );

  /// Rellena los últimos 7 días (incluido hoy) con 0 donde no haya datos,
  /// para un gráfico consistente. Usa fecha local del dispositivo.
  List<DailyStat> last7Days() {
    final byDate = {for (final d in daily) _key(d.date): d};
    final today = DateTime.now();
    return List.generate(7, (i) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 6 - i));
      return byDate[_key(day)] ??
          DailyStat(date: day, pomodoros: 0, minutes: 0);
    });
  }

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
