import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/progress_stats.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Future<ProgressStats?> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AppState>().loadStats();
  }

  String _formatTime(int minutes) {
    if (minutes <= 0) return '0min';
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final isDark = state.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.bg(isDark),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l.progressTitle),
      ),
      body: FutureBuilder<ProgressStats?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final stats = snapshot.data;
          if (stats == null || stats.totalPomodoros == 0) {
            return _EmptyStats(isDark: isDark, message: l.noStatsYet);
          }
          return _StatsBody(
            stats: stats,
            isDark: isDark,
            l: l,
            currentStreak: state.currentStreak,
            longestStreak: state.longestStreak,
            formatTime: _formatTime,
          );
        },
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  final ProgressStats stats;
  final bool isDark;
  final AppLocalizations l;
  final int currentStreak;
  final int longestStreak;
  final String Function(int) formatTime;

  const _StatsBody({
    required this.stats,
    required this.isDark,
    required this.l,
    required this.currentStreak,
    required this.longestStreak,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Racha
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFFF8C42),
                  value: l.daysCount(currentStreak),
                  label: '${l.streak} · ${l.streakCurrent}',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.emoji_events_rounded,
                  iconColor: Colors.amber,
                  value: l.daysCount(longestStreak),
                  label: '${l.streak} · ${l.streakBest}',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.today_rounded,
                  iconColor: AppColors.primary,
                  value: '${stats.todayPomodoros} 🍅',
                  label: l.statToday,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.date_range_rounded,
                  iconColor: AppColors.longBreakColor,
                  value: '${stats.weekPomodoros} 🍅',
                  label: l.statThisWeek,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.timer_rounded,
                  iconColor: AppColors.breakColor,
                  value: formatTime(stats.totalMinutes),
                  label: l.statFocusTime,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.task_alt_rounded,
                  iconColor: AppColors.success,
                  value: '${stats.tasksCompleted}',
                  label: l.statTasksCompleted,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Gráfico 7 días
          Text(
            l.last7Days.toUpperCase(),
            style: TextStyle(
              color: AppColors.textSecondary(isDark),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          _WeekChart(
            days: stats.last7Days(),
            isDark: isDark,
            localeName: l.localeName,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary(isDark),
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  final List<DailyStat> days;
  final bool isDark;
  final String localeName;

  const _WeekChart({
    required this.days,
    required this.isDark,
    required this.localeName,
  });

  @override
  Widget build(BuildContext context) {
    final maxPom = days.fold<int>(1, (m, d) => d.pomodoros > m ? d.pomodoros : m);
    final dayFmt = DateFormat.E(localeName);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: SizedBox(
        height: 160,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: days.map((d) {
            final ratio = d.pomodoros / maxPom;
            final isToday = _isToday(d.date);
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (d.pomodoros > 0)
                    Text(
                      '${d.pomodoros}',
                      style: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    height: 8 + ratio * 96,
                    decoration: BoxDecoration(
                      color: d.pomodoros == 0
                          ? AppColors.border(isDark)
                          : isToday
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dayFmt.format(d.date),
                    style: TextStyle(
                      color: isToday
                          ? AppColors.primary
                          : AppColors.textSecondary(isDark),
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

class _EmptyStats extends StatelessWidget {
  final bool isDark;
  final String message;

  const _EmptyStats({required this.isDark, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.insights_rounded,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
