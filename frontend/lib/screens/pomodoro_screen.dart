import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with SingleTickerProviderStateMixin {
  late AppState _appState;
  bool _dialogShown = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _appState = context.read<AppState>();
    _appState.addListener(_onStateChange);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _appState.removeListener(_onStateChange);
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onStateChange() {
    if (_appState.phase == PomodoroPhase.askComplete &&
        !_dialogShown &&
        mounted) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _appState.phase == PomodoroPhase.askComplete) {
          _showCompletionModal();
        }
      });
    }
  }

  void _showCompletionModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _TaskCompleteDialog(
        taskTitle: _appState.activeProject?.currentTask?.title ?? '',
        onComplete: () {
          Navigator.pop(ctx);
          _dialogShown = false;
          _appState.completeCurrentTask(); // marca tarea e inicia descanso
        },
        onContinue: () {
          Navigator.pop(ctx);
          _dialogShown = false;
          _appState.continueCurrentTask(); // misma tarea, inicia descanso
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.isDarkMode;
    final isBreak = state.isBreak;
    final isLongBreak = state.isLongBreak;

    // Color del arco según la fase
    final phaseColor = isLongBreak
        ? AppColors.longBreakColor
        : isBreak
            ? AppColors.breakColor
            : AppColors.primary;
    final phaseSoft = isLongBreak
        ? AppColors.longBreakSoft
        : isBreak
            ? AppColors.breakSoft
            : AppColors.primarySoft;

    final trackColor = isDark ? AppColors.trackDark : AppColors.trackLight;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    // Cuántos dots mostrar llenos: 4 al inicio de un descanso largo
    final dotsCompleted =
        isLongBreak ? 4 : state.completedInCycle;

    final currentTask = state.activeProject?.currentTask;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (state.isRunning) state.pausePomodoro();
            state.stopAlarm();
            Navigator.pop(context);
          },
        ),
        title: Text(
          state.activeProject?.name ?? 'Pomodoro',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Chip de fase
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Container(
                  key: ValueKey(state.phase),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: phaseSoft,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    _phaseLabel(state.phase),
                    style: TextStyle(
                      color: phaseColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Indicador de ciclo: 4 puntos + etiqueta de sesión
              _CycleIndicator(
                completed: dotsCompleted,
                sessionNumber: state.sessionNumber,
                phaseColor: phaseColor,
                textSecondary: textSecondary,
                isBreak: isBreak,
              ),

              const SizedBox(height: 24),

              // Timer circular
              Expanded(
                child: Center(
                  child: ScaleTransition(
                    scale: state.isRunning
                        ? _pulseAnim
                        : const AlwaysStoppedAnimation(1.0),
                    child: SizedBox(
                      width: 260,
                      height: 260,
                      child: CustomPaint(
                        painter: _TimerPainter(
                          progress: state.timerProgress,
                          color: phaseColor,
                          trackColor: trackColor,
                          strokeWidth: 12,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.formattedTime,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 58,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: -2,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isLongBreak
                                    ? 'descanso largo'
                                    : isBreak
                                        ? 'descansa'
                                        : 'minutos',
                                style: TextStyle(
                                    color: textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Chip de tarea actual
              if (currentTask != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.task_alt_rounded,
                          size: 16, color: phaseColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          currentTask.title,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Botón principal de acción
              SizedBox(
                width: double.infinity,
                height: 60,
                child: _buildActionButton(state, phaseColor, isBreak, isLongBreak),
              ),

              // Fila de acciones secundarias
              if (state.phase == PomodoroPhase.working ||
                  state.phase == PomodoroPhase.paused ||
                  state.isBreak) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pausar solo cuando está corriendo
                    if (state.phase == PomodoroPhase.working) ...[
                      TextButton.icon(
                        onPressed: () => state.pausePomodoro(),
                        icon: Icon(Icons.pause_rounded,
                            size: 16, color: textSecondary),
                        label: Text('Pausar',
                            style:
                                TextStyle(color: textSecondary, fontSize: 13)),
                      ),
                      Text(' · ',
                          style:
                              TextStyle(color: textSecondary, fontSize: 13)),
                    ],
                    TextButton.icon(
                      onPressed: () => state.skipPhase(),
                      icon: Icon(Icons.skip_next_rounded,
                          size: 16, color: textSecondary),
                      label: Text(
                        isLongBreak
                            ? 'Saltar descanso largo'
                            : isBreak
                                ? 'Saltar descanso'
                                : 'Saltar fase',
                        style: TextStyle(color: textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      AppState state, Color phaseColor, bool isBreak, bool isLongBreak) {
    if (isBreak) {
      final breakBg = isLongBreak
          ? AppColors.longBreakColor.withValues(alpha: 0.12)
          : AppColors.breakColor.withValues(alpha: 0.15);
      final breakFg =
          isLongBreak ? AppColors.longBreakColor : AppColors.breakColor;
      final breakIcon =
          isLongBreak ? Icons.self_improvement_rounded : Icons.coffee_rounded;
      final breakLabel =
          isLongBreak ? 'Descanso largo...' : 'Descansando...';

      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: breakBg,
          disabledBackgroundColor: breakBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(breakIcon, size: 20, color: breakFg),
            const SizedBox(width: 10),
            Text(
              breakLabel,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600, color: breakFg),
            ),
          ],
        ),
      );
    }

    // Proyecto 100% completo — no permitir más pomodoros
    if (state.activeProject?.isCompleted == true &&
        state.phase == PomodoroPhase.idle) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success.withValues(alpha: 0.12),
          disabledBackgroundColor: AppColors.success.withValues(alpha: 0.12),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded,
                size: 20, color: AppColors.success),
            SizedBox(width: 10),
            Text(
              '¡Proyecto completado!',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success),
            ),
          ],
        ),
      );
    }

    if (state.phase == PomodoroPhase.idle) {
      return ElevatedButton(
        onPressed: () => state.startPomodoro(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded, size: 26),
            SizedBox(width: 8),
            Text('Comenzar',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    if (state.phase == PomodoroPhase.working) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.12),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_rounded, size: 20, color: AppColors.primary),
            SizedBox(width: 10),
            Text(
              'Pomodoro en curso...',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    // paused
    return ElevatedButton(
      onPressed: () => state.resumePomodoro(),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_arrow_rounded, size: 26),
          SizedBox(width: 8),
          Text('Reanudar',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _phaseLabel(PomodoroPhase phase) => switch (phase) {
        PomodoroPhase.working => 'TRABAJANDO',
        PomodoroPhase.paused => 'EN PAUSA',
        PomodoroPhase.shortBreak => 'DESCANSO CORTO',
        PomodoroPhase.longBreak => 'DESCANSO LARGO',
        PomodoroPhase.askComplete => 'SESIÓN COMPLETA',
        PomodoroPhase.idle => 'LISTO',
      };
}

// ── Indicador de ciclo ────────────────────────────────────────────────────────

class _CycleIndicator extends StatelessWidget {
  final int completed; // 0–4
  final int sessionNumber; // 1–4 (solo relevante al trabajar)
  final Color phaseColor;
  final Color textSecondary;
  final bool isBreak;

  const _CycleIndicator({
    required this.completed,
    required this.sessionNumber,
    required this.phaseColor,
    required this.textSecondary,
    required this.isBreak,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i < completed;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: filled ? 10 : 8,
              height: filled ? 10 : 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? phaseColor
                    : phaseColor.withValues(alpha: 0.2),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          isBreak
              ? completed == 4
                  ? '¡Ciclo completo! Bien merecido descanso'
                  : 'Sesión $completed de 4 completada'
              : 'Sesión $sessionNumber de 4',
          style: TextStyle(
            color: textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Pintor del arco circular ──────────────────────────────────────────────────

class _TimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _TimerPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - strokeWidth / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_TimerPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Modal de confirmación de tarea ───────────────────────────────────────────

class _TaskCompleteDialog extends StatelessWidget {
  final String taskTitle;
  final VoidCallback onComplete;
  final VoidCallback onContinue;

  const _TaskCompleteDialog({
    required this.taskTitle,
    required this.onComplete,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;
    final bg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.timer_off_rounded,
                  size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              '¿Completaste la tarea?',
              style: TextStyle(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            if (taskTitle.isNotEmpty)
              Text(
                taskTitle,
                style:
                    TextStyle(color: textSecondary, fontSize: 14, height: 1.4),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Sí, la completé',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: onContinue,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Todavía no',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
