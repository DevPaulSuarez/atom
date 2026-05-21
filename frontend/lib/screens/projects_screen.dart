import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'project_detail_screen.dart';

enum _Filter { all, low, mid, high, done }

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  _Filter _filter = _Filter.low;

  List<Project> _apply(List<Project> all) => switch (_filter) {
    _Filter.all => all,
    _Filter.low =>
      all.where((p) => !p.isCompleted && p.progress <= 0.25).toList(),
    _Filter.mid =>
      all
          .where(
            (p) => !p.isCompleted && p.progress > 0.25 && p.progress <= 0.50,
          )
          .toList(),
    _Filter.high =>
      all
          .where((p) => !p.isCompleted && p.progress > 0.50 && p.progress < 1.0)
          .toList(),
    _Filter.done => all.where((p) => p.isCompleted).toList(),
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.isDarkMode;
    final filtered = _apply(state.projects);

    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      body: CustomScrollView(
        slivers: [
          _AppBar(state: state, isDark: isDark),
          SliverToBoxAdapter(
            child: _FilterBar(
              selected: _filter,
              isDark: isDark,
              onSelect: (f) => setState(() => _filter = f),
            ),
          ),
          if (state.projectsLoading && state.projects.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (filtered.isEmpty)
            SliverFillRemaining(child: _EmptyState(isDark: isDark))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              sliver: SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final project = filtered[i];
                  final originalIndex = state.projects.indexOf(project);
                  return _ProjectCard(
                    project: project,
                    isDark: isDark,
                    index: originalIndex,
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: _Fab(isDark: isDark),
    );
  }
}

// ── App bar con SliverAppBar ──────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final AppState state;
  final bool isDark;

  const _AppBar({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final completedCount = state.projects.where((p) => p.isCompleted).length;

    return SliverAppBar(
      backgroundColor: AppColors.bg(isDark),
      floating: true,
      pinned: false,
      automaticallyImplyLeading: false,
      leadingWidth: 72,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: Colors.amber,
              size: 22,
            ),
            const SizedBox(width: 4),
            Text(
              '$completedCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Atom',
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          if (state.userName.isNotEmpty)
            Text(
              'Hola, ${state.userName} 👋',
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: AppColors.textSecondary(isDark),
            size: 22,
          ),
          onPressed: () => context.read<AppState>().toggleTheme(),
        ),
        IconButton(
          icon: Icon(
            Icons.logout_rounded,
            color: AppColors.textSecondary(isDark),
            size: 22,
          ),
          onPressed: () => context.read<AppState>().logout(),
          tooltip: 'Cerrar sesión',
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ── FAB ───────────────────────────────────────────────────────────────────────

class _Fab extends StatelessWidget {
  final bool isDark;
  const _Fab({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _showNewProjectSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Nuevo proyecto',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }

  void _showNewProjectSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewProjectSheet(),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final _Filter selected;
  final bool isDark;
  final ValueChanged<_Filter> onSelect;

  const _FilterBar({
    required this.selected,
    required this.isDark,
    required this.onSelect,
  });

  static const _labels = {
    _Filter.low: '0–25%',
    _Filter.mid: '26–50%',
    _Filter.high: '51–99%',
    _Filter.done: '100%',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: _Filter.values.where((f) => f != _Filter.all).map((f) {
          final active = f == selected;
          return GestureDetector(
            onTap: () => onSelect(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.card(isDark),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.border(isDark),
                ),
              ),
              child: Text(
                _labels[f]!,
                style: TextStyle(
                  color: active
                      ? Colors.white
                      : AppColors.textSecondary(isDark),
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Project card (lista vertical con colores) ─────────────────────────────────

class _ProjectCard extends StatelessWidget {
  final Project project;
  final bool isDark;
  final int index;

  const _ProjectCard({
    required this.project,
    required this.isDark,
    required this.index,
  });

  Color get _accent {
    const colors = [
      AppColors.primary,
      AppColors.breakColor,
      AppColors.longBreakColor,
      AppColors.success,
      AppColors.warning,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pct = (project.progress * 100).round();
    final isComplete = project.isCompleted;
    final accentColor = isComplete ? AppColors.success : _accent;
    final trackColor = isDark ? AppColors.trackDark : AppColors.trackLight;

    final isActiveProject = state.activeProject?.id == project.id;
    final phase = state.phase;
    final pomodoroActive = isActiveProject && phase != PomodoroPhase.idle;
    final phaseColor = switch (phase) {
      PomodoroPhase.shortBreak => AppColors.breakColor,
      PomodoroPhase.longBreak  => AppColors.longBreakColor,
      _                        => AppColors.primary,
    };

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, anim, _) =>
                ProjectDetailScreen(projectId: project.id),
            transitionsBuilder: (_, anim, _, child) => SlideTransition(
              position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                  .animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  ),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 320),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: pomodoroActive
                ? phaseColor.withValues(alpha: 0.5)
                : AppColors.border(isDark),
            width: pomodoroActive ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar con inicial y color
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(
                    child: Text(
                      project.name.isNotEmpty
                          ? project.name[0].toUpperCase()
                          : 'P',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Título
                Expanded(
                  child: Text(
                    project.name,
                    style: TextStyle(
                      color: AppColors.textPrimary(isDark),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Porcentaje
                Text(
                  '$pct%',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: project.progress,
                backgroundColor: trackColor,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 10),
            // Conteo de tareas / Pomodoro en curso
            if (pomodoroActive) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: phaseColor.withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_rounded, size: 13, color: phaseColor),
                    const SizedBox(width: 5),
                    Text(
                      switch (phase) {
                        PomodoroPhase.shortBreak => 'Descanso · ${state.formattedTime}',
                        PomodoroPhase.longBreak  => 'Descanso largo · ${state.formattedTime}',
                        PomodoroPhase.paused     => 'Pausado · ${state.formattedTime}',
                        _                        => 'En curso · ${state.formattedTime}',
                      },
                      style: TextStyle(
                        color: phaseColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              Row(
                children: [
                  Icon(
                    isComplete ? Icons.check_circle_rounded : Icons.list_rounded,
                    size: 13,
                    color: isComplete
                        ? AppColors.success
                        : AppColors.textSecondary(isDark),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isComplete
                        ? 'Completado'
                        : '${project.completedCount} de ${project.totalCount} tareas',
                    style: TextStyle(
                      color: isComplete
                          ? AppColors.success
                          : AppColors.textSecondary(isDark),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

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
                color: AppColors.primary.withValues(
                  alpha: isDark ? 0.15 : 0.08,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Sin proyectos aún',
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Crea tu primer proyecto y la IA\ngenerará las tareas automáticamente.',
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                fontSize: 15,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── New project sheet ─────────────────────────────────────────────────────────

class _NewProjectSheet extends StatefulWidget {
  const _NewProjectSheet();

  @override
  State<_NewProjectSheet> createState() => _NewProjectSheetState();
}

class _NewProjectSheetState extends State<_NewProjectSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _motivationCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _motivationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await context.read<AppState>().addProject(
      name,
      _descCtrl.text.trim(),
      _motivationCtrl.text.trim(),
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _loading = false;
        _error = error;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card(isDark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(isDark),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nuevo proyecto',
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'La IA generará las tareas automáticamente',
                      style: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _Field(
              controller: _nameCtrl,
              label: 'Nombre del proyecto',
              hint: 'ej. Aprender Flutter',
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            _Field(
              controller: _descCtrl,
              label: 'Descripción (opcional)',
              hint: 'ej. Crear apps móviles con Dart y Flutter desde cero',
              isDark: isDark,
              maxLines: 3,
            ),
            const SizedBox(height: 14),
            _Field(
              controller: _motivationCtrl,
              label: '¿Por qué quieres terminar esto? (opcional)',
              hint: 'ej. Conseguir trabajo como desarrollador',
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            if (_loading)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Generando tareas con IA...',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Crear proyecto',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isDark;
  final int maxLines;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.isDark,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary(isDark),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: AppColors.textPrimary(isDark), fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textSecondary(isDark),
              fontSize: 15,
            ),
            filled: true,
            fillColor: AppColors.bg(isDark),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border(isDark)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border(isDark)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
