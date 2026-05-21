import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'pomodoro_screen.dart';

class ProjectDetailScreen extends StatelessWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final project = state.projects.firstWhere(
      (p) => p.id == projectId,
      orElse: () => state.projects.first,
    );
    final isDark = state.isDarkMode;
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);
    final cardColor = AppColors.card(isDark);
    final borderColor = AppColors.border(isDark);
    final trackColor = isDark ? AppColors.trackDark : AppColors.trackLight;

    final currentTask = project.currentTask;
    final pct = (project.progress * 100).round();
    final isComplete = project.isCompleted;
    final pomodoroActive =
        state.activeProject?.id == projectId &&
        state.phase != PomodoroPhase.idle;
    final phase = state.phase;
    final phaseColor = switch (phase) {
      PomodoroPhase.shortBreak => AppColors.breakColor,
      PomodoroPhase.longBreak  => AppColors.longBreakColor,
      _                        => AppColors.primary,
    };
    final phaseLabel = switch (phase) {
      PomodoroPhase.shortBreak => 'Descanso · ${state.formattedTime}',
      PomodoroPhase.longBreak  => 'Descanso largo · ${state.formattedTime}',
      PomodoroPhase.paused     => 'Pausado · ${state.formattedTime}',
      PomodoroPhase.askComplete => 'Pomodoro completado',
      _                        => 'En curso · ${state.formattedTime}',
    };
    final phaseIcon = switch (phase) {
      PomodoroPhase.shortBreak => Icons.coffee_rounded,
      PomodoroPhase.longBreak  => Icons.self_improvement_rounded,
      PomodoroPhase.paused     => Icons.pause_rounded,
      _                        => Icons.timer_rounded,
    };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(project.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: textSecondary,
              size: 22,
            ),
            onPressed: () => _confirmDelete(context, state),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: isComplete
          ? _CompletedView(
              project: project,
              isDark: isDark,
            )
          : Column(
              children: [
                // ── Contenido scrollable ────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // Progress card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progreso general',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '$pct%',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: project.progress,
                            backgroundColor: trackColor,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${project.completedCount} de ${project.totalCount} tareas',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            if (project.tasksLoaded &&
                                project.tasks.isNotEmpty)
                              GestureDetector(
                                onTap: () => _showTasksSheet(
                                    context, project, isDark),
                                child: const Row(
                                  children: [
                                    Text(
                                      'Ver todas',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 2),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.primary,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Project description (if any)
                  if (project.description.isNotEmpty) ...[
                    Text(
                      project.description,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Current task label
                  Text(
                    'TAREA ACTUAL',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Task card
                  if (currentTask != null)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(
                              alpha: isDark ? 0.35 : 0.2),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(width: 4, color: AppColors.primary),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Badge "Tarea N de M"
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                              alpha: isDark ? 0.25 : 0.15),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Tarea ${project.currentTaskIndex + 1} de ${project.totalCount}',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        currentTask.title,
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          height: 1.4,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      // Subtareas (si las hay)
                                      if (currentTask.hasSubtasks) ...[
                                        const SizedBox(height: 16),
                                        Divider(color: AppColors.border(isDark), height: 1),
                                        const SizedBox(height: 12),
                                        ...currentTask.subtasks.asMap().entries.map((e) {
                                          final i = e.key;
                                          final sub = e.value;
                                          final isCurrent = !sub.isCompleted &&
                                              currentTask.subtasks
                                                  .take(i)
                                                  .every((s) => s.isCompleted);
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 10),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 22,
                                                  height: 22,
                                                  decoration: BoxDecoration(
                                                    color: sub.isCompleted
                                                        ? AppColors.success
                                                        : isCurrent
                                                            ? AppColors.primary
                                                            : Colors.transparent,
                                                    shape: BoxShape.circle,
                                                    border: sub.isCompleted || isCurrent
                                                        ? null
                                                        : Border.all(
                                                            color: AppColors.border(isDark),
                                                            width: 1.5,
                                                          ),
                                                  ),
                                                  child: Center(
                                                    child: sub.isCompleted
                                                        ? const Icon(Icons.check_rounded,
                                                            size: 13, color: Colors.white)
                                                        : Text(
                                                            '${project.currentTaskIndex + 1}.${i + 1}',
                                                            style: TextStyle(
                                                              color: isCurrent
                                                                  ? Colors.white
                                                                  : textSecondary,
                                                              fontSize: 9,
                                                              fontWeight: FontWeight.w700,
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    sub.title,
                                                    style: TextStyle(
                                                      color: sub.isCompleted
                                                          ? textSecondary
                                                          : isCurrent
                                                              ? textPrimary
                                                              : textSecondary,
                                                      fontSize: 13,
                                                      fontWeight: isCurrent
                                                          ? FontWeight.w600
                                                          : FontWeight.w400,
                                                      decoration: sub.isCompleted
                                                          ? TextDecoration.lineThrough
                                                          : null,
                                                      decorationColor: textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ] else if (currentTask.pomodorosCount > 0) ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            const Icon(Icons.timer_outlined,
                                                size: 14, color: AppColors.primary),
                                            const SizedBox(width: 5),
                                            Text(
                                              '${currentTask.pomodorosCount} pomodoro${currentTask.pomodorosCount > 1 ? 's' : ''}',
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                      ],
                    ),
                  ),
                ),

                // ── Botón fijo en la parte inferior ────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Active pomodoro indicator
                      if (pomodoroActive)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: phaseColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: phaseColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(phaseIcon, size: 16, color: phaseColor),
                              const SizedBox(width: 8),
                              Text(
                                phaseLabel,
                                style: TextStyle(
                                  color: phaseColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // CTA button with glow
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: phaseColor.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () => _goToPomodoro(context, state),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: phaseColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  pomodoroActive
                                      ? Icons.play_arrow_rounded
                                      : Icons.timer_rounded,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  pomodoroActive
                                      ? 'Continuar'
                                      : 'Iniciar Pomodoro',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _showTasksSheet(BuildContext context, project, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TasksSheet(project: project, isDark: isDark),
    );
  }

  void _goToPomodoro(BuildContext context, AppState state) {
    final activeProject = state.activeProject;
    final hasOtherActive = activeProject != null &&
        activeProject.id != projectId &&
        state.phase != PomodoroPhase.idle;

    if (hasOtherActive) {
      final isDark = state.isDarkMode;
      final phaseColor = switch (state.phase) {
        PomodoroPhase.shortBreak => AppColors.breakColor,
        PomodoroPhase.longBreak  => AppColors.longBreakColor,
        _                        => AppColors.primary,
      };
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.card(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.timer_rounded, color: phaseColor, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Pomodoro en curso',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ya tienes un Pomodoro activo en:',
                style: TextStyle(
                  color: AppColors.textSecondary(isDark),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: phaseColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: phaseColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeProject.name,
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.formattedTime} restantes',
                      style: TextStyle(
                        color: phaseColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Termina o pausa ese Pomodoro antes de empezar uno nuevo.',
                style: TextStyle(
                  color: AppColors.textSecondary(isDark),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PomodoroScreen()),
                );
              },
              child: Text(
                'Ir al Pomodoro activo',
                style: TextStyle(color: phaseColor, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
      return;
    }

    state.setActiveProject(
        state.projects.firstWhere((p) => p.id == projectId));
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PomodoroScreen()),
    );
  }

  void _confirmDelete(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar proyecto'),
        content: const Text(
          '¿Seguro que quieres eliminar este proyecto? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              state.deleteProject(projectId);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Completed view ────────────────────────────────────────────────────────────

class _CompletedView extends StatelessWidget {
  final dynamic project;
  final bool isDark;

  const _CompletedView({
    required this.project,
    required this.isDark,
  });

  String _formatFocusTime(int totalMinutes) {
    if (totalMinutes == 0) return '—';
    if (totalMinutes < 60) return '${totalMinutes}min';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  String _formatCompletedAt(DateTime dt) {
    final months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun',
                    'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);
    final cardColor = AppColors.card(isDark);
    final borderColor = AppColors.border(isDark);

    final tasks = project.tasks as List;
    final totalPomodoros = tasks.fold<int>(
      0, (sum, t) => sum + (t as dynamic).totalPomodorosWithSubs as int);
    final totalMinutes = totalPomodoros * 25;
    final totalTasks = tasks.length;
    final completedAt = project.completedAt as DateTime?;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Column(
        children: [
          // Icono de éxito
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 44,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Proyecto completado',
            style: TextStyle(
              color: textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          if (completedAt != null)
            Text(
              _formatCompletedAt(completedAt),
              style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600),
            )
          else
            Text(
              'Todas las tareas completadas',
              style: TextStyle(color: textSecondary, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 32),

          // Card de estadísticas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESUMEN DEL PROYECTO',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Pomodoros
                    Expanded(
                      child: _StatItem(
                        icon: Icons.timer_rounded,
                        color: AppColors.primary,
                        value: '$totalPomodoros',
                        label: totalPomodoros == 1
                            ? 'pomodoro'
                            : 'pomodoros',
                        isDark: isDark,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: borderColor,
                    ),
                    // Tiempo total
                    Expanded(
                      child: _StatItem(
                        icon: Icons.schedule_rounded,
                        color: AppColors.breakColor,
                        value: _formatFocusTime(totalMinutes),
                        label: 'tiempo total',
                        isDark: isDark,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: borderColor,
                    ),
                    // Tareas
                    Expanded(
                      child: _StatItem(
                        icon: Icons.task_alt_rounded,
                        color: AppColors.success,
                        value: '$totalTasks',
                        label: totalTasks == 1 ? 'tarea' : 'tareas',
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Lista de tareas completadas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TAREAS COMPLETADAS',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                ...tasks.asMap().entries.expand((entry) {
                  final i = entry.key;
                  final task = entry.value as dynamic;
                  final hasSubtasks = task.hasSubtasks as bool;
                  final pomCount = task.totalPomodorosWithSubs as int;

                  final rows = <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${i + 1}. ${task.title as String}',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: textSecondary,
                                  ),
                                ),
                                if (pomCount > 0) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    '$pomCount 🍅',
                                    style: TextStyle(
                                      color: AppColors.primary.withValues(alpha: 0.7),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ];

                  if (hasSubtasks) {
                    final subtasks = task.subtasks as List;
                    for (var j = 0; j < subtasks.length; j++) {
                      final sub = subtasks[j] as dynamic;
                      final subPom = sub.pomodorosCount as int;
                      rows.add(
                        Padding(
                          padding: const EdgeInsets.only(left: 36, bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 10,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${i + 1}.${j + 1} ${sub.title as String}',
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 13,
                                        height: 1.4,
                                        decoration: TextDecoration.lineThrough,
                                        decorationColor: textSecondary.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    if (subPom > 0) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        '$subPom 🍅',
                                        style: TextStyle(
                                          color: AppColors.primary.withValues(alpha: 0.6),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  }

                  if (i < tasks.length - 1) {
                    rows.add(Divider(color: borderColor, height: 1));
                    rows.add(const SizedBox(height: 12));
                  }

                  return rows;
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final bool isDark;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 8),
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
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ── Tasks bottom sheet ────────────────────────────────────────────────────────

class _TasksSheet extends StatelessWidget {
  final dynamic project;
  final bool isDark;

  const _TasksSheet({required this.project, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.card(isDark);
    final handle = AppColors.border(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);

    final tasks = project.tasks as List;
    final completed = tasks.where((t) => t.isCompleted as bool).length;
    final total = tasks.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: handle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Todas las tareas',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$completed completadas · ${total - completed} pendientes',
                          style:
                              TextStyle(color: textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: total == 0 ? 0 : completed / total,
                          strokeWidth: 4,
                          backgroundColor: handle,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            completed == total && total > 0
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                        Text(
                          '${total == 0 ? 0 : (completed / total * 100).round()}%',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: handle),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                itemCount: total,
                itemBuilder: (_, i) {
                  final task = tasks[i];
                  final isCompleted = task.isCompleted as bool;
                  final isCurrent = !isCompleted &&
                      tasks.take(i).every((t) => t.isCompleted as bool);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 32,
                          child: Column(
                            children: [
                              _TaskIcon(
                                isCompleted: isCompleted,
                                isCurrent: isCurrent,
                                index: i,
                                isDark: isDark,
                              ),
                              if (i < total - 1)
                                Container(
                                  width: 2,
                                  height: 22,
                                  margin: const EdgeInsets.only(top: 4),
                                  color: isCompleted
                                      ? AppColors.success
                                          .withValues(alpha: 0.3)
                                      : handle,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                if (isCurrent)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 5),
                                    child: Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'EN CURSO',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                Text(
                                  task.title as String,
                                  style: TextStyle(
                                    color: isCompleted
                                        ? textSecondary
                                        : textPrimary,
                                    fontSize: 14,
                                    height: 1.45,
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: textSecondary,
                                  ),
                                ),
                                if ((task.pomodorosCount as int) > 0) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.timer_outlined,
                                        size: 11,
                                        color: AppColors.primary
                                            .withValues(alpha: 0.7),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${task.pomodorosCount} pomodoro${(task.pomodorosCount as int) > 1 ? 's' : ''}',
                                        style: TextStyle(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.7),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Task icon ─────────────────────────────────────────────────────────────────

class _TaskIcon extends StatelessWidget {
  final bool isCompleted;
  final bool isCurrent;
  final int index;
  final bool isDark;

  const _TaskIcon({
    required this.isCompleted,
    required this.isCurrent,
    required this.index,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
      );
    }
    if (isCurrent) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.border(isDark),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: AppColors.textSecondary(isDark),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
