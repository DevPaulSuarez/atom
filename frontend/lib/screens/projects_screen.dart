import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/project.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'progress_screen.dart';
import 'project_detail_screen.dart';
import 'settings_sheet.dart';

enum _Filter { all, low, mid, high, done }

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  _Filter _filter = _Filter.low;

  // Vista de completados (100%): paginación y filtro por fecha.
  static const _donePageSize = 5;
  int _doneLimit = _donePageSize;
  DateTime? _doneDate;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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
    _Filter.done => _completedSorted(all),
  };

  /// Completados ordenados por fecha (últimos primero), filtrados por la fecha
  /// elegida si la hay.
  List<Project> _completedSorted(List<Project> all) {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    var done = all.where((p) => p.isCompleted).toList()
      ..sort((a, b) =>
          (b.completedAt ?? epoch).compareTo(a.completedAt ?? epoch));
    final d = _doneDate;
    if (d != null) {
      done = done
          .where((p) => p.completedAt != null && _sameDay(p.completedAt!, d))
          .toList();
    }
    return done;
  }

  Future<void> _pickDoneDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _doneDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _doneDate = picked;
        _doneLimit = _donePageSize;
      });
    }
  }

  void _clearDoneDate() => setState(() {
    _doneDate = null;
    _doneLimit = _donePageSize;
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.isDarkMode;
    final filtered = _apply(state.projects);

    final isDone = _filter == _Filter.done;
    // En completados se muestran de a 5 (los últimos); el resto, completo.
    final visible = isDone ? filtered.take(_doneLimit).toList() : filtered;
    final hasMore = isDone && filtered.length > _doneLimit;

    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      body: CustomScrollView(
        slivers: [
          _AppBar(state: state, isDark: isDark),
          SliverToBoxAdapter(
            child: _FilterBar(
              selected: _filter,
              isDark: isDark,
              onSelect: (f) => setState(() {
                _filter = f;
                _doneLimit = _donePageSize;
              }),
            ),
          ),
          // Filtro por fecha, solo en la vista de completados.
          if (isDone)
            SliverToBoxAdapter(
              child: _DoneDateBar(
                date: _doneDate,
                isDark: isDark,
                onPick: _pickDoneDate,
                onClear: _clearDoneDate,
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
          else ...[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, hasMore ? 8 : 120),
              sliver: SliverList.separated(
                itemCount: visible.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final project = visible[i];
                  final originalIndex = state.projects.indexOf(project);
                  return _ProjectCard(
                    project: project,
                    isDark: isDark,
                    index: originalIndex,
                  );
                },
              ),
            ),
            if (hasMore)
              SliverToBoxAdapter(
                child: _SeeMoreButton(
                  isDark: isDark,
                  remaining: filtered.length - _doneLimit,
                  onTap: () =>
                      setState(() => _doneLimit += _donePageSize),
                ),
              ),
          ],
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
    final l = AppLocalizations.of(context);
    final completedCount = state.projects.where((p) => p.isCompleted).length;

    return SliverAppBar(
      backgroundColor: AppColors.bg(isDark),
      floating: true,
      pinned: false,
      automaticallyImplyLeading: false,
      leadingWidth: 116,
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
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (state.currentStreak > 0) ...[
              const SizedBox(width: 12),
              const Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFFFF8C42),
                size: 22,
              ),
              const SizedBox(width: 4),
              Text(
                '${state.currentStreak}',
                style: TextStyle(
                  color: AppColors.textPrimary(isDark),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
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
              l.greeting(state.userName),
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
            Icons.insights_rounded,
            color: AppColors.textSecondary(isDark),
            size: 22,
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProgressScreen()),
          ),
          tooltip: l.progressTitle,
        ),
        IconButton(
          icon: Icon(
            Icons.settings_rounded,
            color: AppColors.textSecondary(isDark),
            size: 22,
          ),
          onPressed: () => showSettingsSheet(context),
          tooltip: l.settings,
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
    final l = AppLocalizations.of(context);
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
        label: Text(
          l.newProject,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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

// ── Barra de filtro por fecha (vista de completados) ──────────────────────────

class _DoneDateBar extends StatelessWidget {
  final DateTime? date;
  final bool isDark;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _DoneDateBar({
    required this.date,
    required this.isDark,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hasDate = date != null;
    final label =
        hasDate ? DateFormat.yMMMd(l.localeName).format(date!) : l.filterByDate;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onPick,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: hasDate ? AppColors.primary : AppColors.card(isDark),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: hasDate ? AppColors.primary : AppColors.border(isDark),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 14,
                      color: hasDate
                          ? Colors.white
                          : AppColors.textSecondary(isDark)),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: hasDate
                          ? Colors.white
                          : AppColors.textSecondary(isDark),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasDate) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textSecondary(isDark)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Botón "Ver más" (paginación de completados) ───────────────────────────────

class _SeeMoreButton extends StatelessWidget {
  final bool isDark;
  final int remaining;
  final VoidCallback onTap;

  const _SeeMoreButton({
    required this.isDark,
    required this.remaining,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border(isDark)),
          ),
          child: Text(
            '${l.seeMore} ($remaining)',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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

  void _open(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, _) => ProjectDetailScreen(projectId: project.id),
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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

    // Proyecto completado: tarjeta elegante con acento de éxito y fecha.
    if (isComplete) {
      final completedOn = project.completedAt != null
          ? DateFormat.yMMMd(l.localeName).format(project.completedAt!)
          : null;
      return GestureDetector(
        onTap: () => _open(context),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.success.withValues(alpha: isDark ? 0.30 : 0.22),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Franja de acento de éxito a la izquierda.
                  Container(width: 4, color: AppColors.success),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.success
                                  .withValues(alpha: isDark ? 0.18 : 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded,
                                size: 22, color: AppColors.success),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  project.name,
                                  style: TextStyle(
                                    color: AppColors.textPrimary(isDark),
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(Icons.event_available_rounded,
                                        size: 12,
                                        color: AppColors.textSecondary(isDark)),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        completedOn != null
                                            ? l.completedOn(completedOn)
                                            : l.completedLabel,
                                        style: TextStyle(
                                          color:
                                              AppColors.textSecondary(isDark),
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.success
                                  .withValues(alpha: isDark ? 0.18 : 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '100%',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _open(context),
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
                        PomodoroPhase.shortBreak => l.statusBreak(state.formattedTime),
                        PomodoroPhase.longBreak  => l.statusLongBreak(state.formattedTime),
                        PomodoroPhase.paused     => l.statusPaused(state.formattedTime),
                        _                        => l.statusInProgress(state.formattedTime),
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
                        ? l.completedLabel
                        : l.tasksCount(project.completedCount, project.totalCount),
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
    final l = AppLocalizations.of(context);
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
              l.emptyTitle,
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l.emptyBody,
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
  late int _focusMinutes;

  // Modo manual: el usuario escribe sus propias tareas (sin IA).
  bool _manualMode = false;
  final List<_ManualTaskRow> _manualTasks = [];

  @override
  void initState() {
    super.initState();
    // Pre-selecciona la duración por defecto del ajuste global.
    _focusMinutes = context.read<AppState>().focusMinutes;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _motivationCtrl.dispose();
    for (final t in _manualTasks) {
      t.dispose();
    }
    super.dispose();
  }

  void _setManualMode(bool manual) {
    setState(() {
      _manualMode = manual;
      _error = null;
      // Al entrar a manual por primera vez, arranca con una fila vacía.
      if (manual && _manualTasks.isEmpty) _manualTasks.add(_ManualTaskRow());
    });
  }

  void _addManualTask() {
    setState(() => _manualTasks.add(_ManualTaskRow()));
  }

  void _removeManualTask(int i) {
    setState(() {
      _manualTasks[i].dispose();
      _manualTasks.removeAt(i);
    });
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    List<Map<String, dynamic>>? tasks;
    if (_manualMode) {
      tasks = _manualTasks
          .where((t) => t.controller.text.trim().isNotEmpty)
          .map((t) => <String, dynamic>{
                'title': t.controller.text.trim(),
                'pomodoros': t.pomodoros,
              })
          .toList();
      if (tasks.isEmpty) {
        setState(() => _error = AppLocalizations.of(context).manualNoTasks);
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await context.read<AppState>().addProject(
      name,
      _descCtrl.text.trim(),
      _motivationCtrl.text.trim(),
      focusMinutes: _focusMinutes,
      tasks: tasks,
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
    final l = AppLocalizations.of(context);
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
                      l.newProject,
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      _manualMode
                          ? l.newProjectSubtitleManual
                          : l.newProjectSubtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary(isDark),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Toggle: tareas con IA o escritas a mano.
            _ModeToggle(
              manualMode: _manualMode,
              isDark: isDark,
              aiLabel: l.modeWithAI,
              manualLabel: l.modeManual,
              onChanged: _setManualMode,
            ),
            const SizedBox(height: 20),
            _Field(
              controller: _nameCtrl,
              label: l.fieldProjectName,
              hint: l.hintProjectName,
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            _Field(
              controller: _descCtrl,
              label: l.fieldDescription,
              hint: l.hintDescription,
              isDark: isDark,
              maxLines: 3,
            ),
            const SizedBox(height: 14),
            _Field(
              controller: _motivationCtrl,
              label: l.fieldMotivation,
              hint: l.hintMotivation,
              isDark: isDark,
            ),
            if (_manualMode) ...[
              const SizedBox(height: 18),
              Text(
                l.yourTasks.toUpperCase(),
                style: TextStyle(
                  color: AppColors.textSecondary(isDark),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              ..._manualTasks.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ManualTaskTile(
                      row: e.value,
                      isDark: isDark,
                      hint: l.taskTitleHint,
                      canRemove: _manualTasks.length > 1,
                      onChanged: () => setState(() {}),
                      onRemove: () => _removeManualTask(e.key),
                    ),
                  )),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addManualTask,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l.addTask),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              l.focusDuration.toUpperCase(),
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            FocusDurationField(
              minutes: _focusMinutes,
              isDark: isDark,
              onChanged: (m) => setState(() => _focusMinutes = m),
            ),
            const SizedBox(height: 20),
            if (_loading && !_manualMode)
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
                      l.generatingTasks,
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
                    : Text(
                        l.createProject,
                        style: const TextStyle(
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
          // Evita que el autocorrector reemplace palabras (nombres, términos
          // poco comunes, etc.). Mantiene mayúscula al inicio de cada frase.
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.sentences,
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

/// Selector entre "tareas con IA" y "tareas a mano".
class _ModeToggle extends StatelessWidget {
  final bool manualMode;
  final bool isDark;
  final String aiLabel;
  final String manualLabel;
  final ValueChanged<bool> onChanged;

  const _ModeToggle({
    required this.manualMode,
    required this.isDark,
    required this.aiLabel,
    required this.manualLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bg(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Row(
        children: [
          _seg(aiLabel, !manualMode, () => onChanged(false),
              Icons.auto_awesome_rounded),
          _seg(manualLabel, manualMode, () => onChanged(true),
              Icons.edit_rounded),
        ],
      ),
    );
  }

  Widget _seg(String label, bool active, VoidCallback onTap, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color:
                      active ? Colors.white : AppColors.textSecondary(isDark)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color:
                      active ? Colors.white : AppColors.textSecondary(isDark),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Estado de una tarea manual: título + pomodoros estimados.
class _ManualTaskRow {
  final TextEditingController controller = TextEditingController();
  int pomodoros = 2;
  void dispose() => controller.dispose();
}

/// Fila editable: campo de título + selector de pomodoros (1–4) + quitar.
class _ManualTaskTile extends StatelessWidget {
  final _ManualTaskRow row;
  final bool isDark;
  final String hint;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _ManualTaskTile({
    required this.row,
    required this.isDark,
    required this.hint,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.bg(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: row.controller,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                      color: AppColors.textPrimary(isDark), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                        color: AppColors.textSecondary(isDark), fontSize: 14),
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              if (canRemove)
                GestureDetector(
                  onTap: onRemove,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textSecondary(isDark)),
                  ),
                ),
            ],
          ),
          Row(
            children: [
              const Text('🍅', style: TextStyle(fontSize: 13)),
              const Spacer(),
              _stepBtn(Icons.remove_rounded, () {
                if (row.pomodoros > 1) {
                  row.pomodoros--;
                  onChanged();
                }
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  '${row.pomodoros}',
                  style: TextStyle(
                    color: AppColors.textPrimary(isDark),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _stepBtn(Icons.add_rounded, () {
                if (row.pomodoros < 4) {
                  row.pomodoros++;
                  onChanged();
                }
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 17, color: AppColors.primary),
      ),
    );
  }
}
