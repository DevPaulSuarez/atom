import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with TickerProviderStateMixin {
  late AppState _appState;
  bool _dialogShown = false;
  bool _breakDialogShown = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  late ConfettiController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _appState = context.read<AppState>();
    _appState.addListener(_onStateChange);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _confettiCtrl = ConfettiController(
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void dispose() {
    _appState.removeListener(_onStateChange);
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _celebrate() {
    _confettiCtrl.play();
    _appState.playCelebration();
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
    if (_appState.phase == PomodoroPhase.breakDone &&
        !_breakDialogShown &&
        mounted) {
      _breakDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _appState.phase == PomodoroPhase.breakDone) {
          _showBreakDoneModal();
        }
      });
    }
  }

  void _showBreakDoneModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BreakDoneDialog(
        onStart: () {
          Navigator.pop(ctx);
          _breakDialogShown = false;
          _appState.dismissBreak();
        },
      ),
    );
  }

  void _showCompletionModal() {
    final workTask = _appState.activeProject?.activeWorkTask;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _TaskCompleteDialog(
        taskTitle: workTask?.title ?? '',
        done: workTask?.pomodorosCount ?? 0,
        estimate: workTask?.estimatedPomodoros ?? 1,
        onComplete: () {
          Navigator.pop(ctx);
          _dialogShown = false;
          _appState.completeCurrentTask();
          _celebrate();
        },
        onContinue: () {
          Navigator.pop(ctx);
          _dialogShown = false;
          if (_appState.atOrOverEstimate) {
            _showOverEstimateChoice();
          } else {
            _appState.continueAfterIncomplete();
          }
        },
      ),
    );
  }

  void _showOverEstimateChoice() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _OverEstimateDialog(
        onMore: () {
          Navigator.pop(ctx);
          _appState.continueAfterIncomplete();
        },
        onSplit: () {
          Navigator.pop(ctx);
          _appState.splitCurrentTask();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final isDark = state.isDarkMode;

    if (state.isSplitting) {
      return _SplittingLoadingScreen(isDark: isDark);
    }

    if (state.showMotivation) {
      return _MotivationScreen(
        motivation: state.activeProject?.motivation ?? '',
        coachMessage: state.coachMessage,
        splitCount: state.splitCount,
        isDark: isDark,
        onRetry: () => state.dismissMotivation(),
      );
    }

    final isBreak = state.isBreak;
    final isLongBreak = state.isLongBreak;
    final isActive = state.isRunning || isBreak;

    final phaseColor = isLongBreak
        ? AppColors.longBreakColor
        : isBreak
            ? AppColors.breakColor
            : AppColors.primary;
    final phaseGlow = isLongBreak
        ? AppColors.longBreakGlow
        : isBreak
            ? AppColors.breakGlow
            : AppColors.primaryGlow;
    final phaseSoft = isLongBreak
        ? AppColors.longBreakSoft
        : isBreak
            ? AppColors.breakSoft
            : AppColors.primarySoft;

    final trackColor = isDark ? AppColors.trackDark : AppColors.trackLight;
    final bgColor = AppColors.bg(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);

    final dotsCompleted = isLongBreak ? 4 : state.completedInCycle;
    final currentTask = state.activeProject?.currentTask;
    final workTask = state.activeProject?.activeWorkTask;

    return Stack(
      children: [
        Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          state.activeProject?.name ?? l.pomodoro,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Phase chip with border + slide-fade transition
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: anim, curve: Curves.easeOut)),
                    child: child,
                  ),
                ),
                child: Container(
                  key: ValueKey(state.phase),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: phaseSoft,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: phaseColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _phaseLabel(l, state.phase),
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

              // Cycle indicator with pill-shaped dots
              _CycleIndicator(
                completed: dotsCompleted,
                sessionNumber: state.sessionNumber,
                phaseColor: phaseColor,
                textSecondary: textSecondary,
                isBreak: isBreak,
                l: l,
              ),

              const SizedBox(height: 24),

              // Timer with animated background glow
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_pulseCtrl, _glowCtrl]),
                    builder: (context, _) {
                      final glowIntensity = isActive ? _glowAnim.value : 0.0;
                      return ScaleTransition(
                        scale: state.isRunning
                            ? _pulseAnim
                            : const AlwaysStoppedAnimation(1.0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Radial background glow
                            if (isActive)
                              CustomPaint(
                                size: const Size(300, 300),
                                painter: _BackgroundGlowPainter(
                                  color: phaseGlow,
                                  intensity: glowIntensity,
                                ),
                              ),
                            // Timer ring
                            Container(
                              width: 260,
                              height: 260,
                              decoration: isActive
                                  ? BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: phaseColor.withValues(
                                              alpha: 0.18 * glowIntensity),
                                          blurRadius: 50,
                                          spreadRadius: 8,
                                        ),
                                      ],
                                    )
                                  : null,
                              child: CustomPaint(
                                painter: _TimerPainter(
                                  progress: state.timerProgress,
                                  color: phaseColor,
                                  glowColor: isActive ? phaseColor : null,
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
                                            ? l.longBreakLower
                                            : isBreak
                                                ? l.restLower
                                                : l.minutesLower,
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Current task chip
              if (workTask != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card(isDark),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border(isDark)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.task_alt_rounded,
                          size: 16, color: phaseColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // "Tarea N de M" + progreso de pomodoros de la tarea
                            if (currentTask != null &&
                                state.activeProject != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: phaseColor.withValues(
                                            alpha: isDark ? 0.25 : 0.15),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        l.taskNofM(
                                          state.activeProject!
                                                  .currentTaskIndex +
                                              1,
                                          state.activeProject!.totalCount,
                                        ),
                                        style: TextStyle(
                                          color: phaseColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l.pomodoroProgress(
                                        currentTask.hasSubtasks
                                            ? currentTask.totalPomodorosWithSubs
                                            : workTask.pomodorosCount,
                                        currentTask.hasSubtasks
                                            ? currentTask.estimatedWithSubs
                                            : workTask.estimatedPomodoros,
                                      ),
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (workTask.parentId != null &&
                                currentTask != null)
                              Text(
                                currentTask.title,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            Text(
                              workTask.title,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Main action button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: _buildActionButton(
                    l, state, phaseColor, isBreak, isLongBreak),
              ),

              // Secondary actions — solo visibles para el usuario tester
              if (state.isTester &&
                  (state.phase == PomodoroPhase.working ||
                      state.phase == PomodoroPhase.paused ||
                      state.isBreak)) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (state.phase == PomodoroPhase.working) ...[
                      _SecondaryBtn(
                        icon: Icons.pause_rounded,
                        label: l.pause,
                        color: textSecondary,
                        onTap: () => state.pausePomodoro(),
                      ),
                      Text(' · ',
                          style:
                              TextStyle(color: textSecondary, fontSize: 13)),
                    ],
                    _SecondaryBtn(
                      icon: Icons.skip_next_rounded,
                      label: isLongBreak
                          ? l.skipLongBreak
                          : isBreak
                              ? l.skipBreak
                              : l.skipPhase,
                      color: textSecondary,
                      onTap: () => state.skipPhase(),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
        ), // Scaffold

        // Confetti overlay — burst desde el centro superior
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiCtrl,
            blastDirection: math.pi / 2, // hacia abajo
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.06,
            numberOfParticles: 18,
            gravity: 0.3,
            maxBlastForce: 20,
            minBlastForce: 8,
            colors: const [
              AppColors.primary,
              AppColors.breakColor,
              AppColors.longBreakColor,
              AppColors.success,
              Color(0xFFFFD700), // dorado
            ],
            shouldLoop: false,
          ),
        ),
      ], // Stack children
    ); // Stack
  }

  Widget _buildActionButton(AppLocalizations l, AppState state,
      Color phaseColor, bool isBreak, bool isLongBreak) {
    if (isBreak) {
      final breakBg = isLongBreak
          ? AppColors.longBreakColor.withValues(alpha: 0.12)
          : AppColors.breakColor.withValues(alpha: 0.15);
      final breakFg =
          isLongBreak ? AppColors.longBreakColor : AppColors.breakColor;
      final breakIcon =
          isLongBreak ? Icons.self_improvement_rounded : Icons.coffee_rounded;
      final breakLabel =
          isLongBreak ? l.longBreakOngoing : l.breakOngoing;

      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: breakBg,
          disabledBackgroundColor: breakBg,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(breakIcon, size: 20, color: breakFg),
            const SizedBox(width: 10),
            Text(
              breakLabel,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: breakFg),
            ),
          ],
        ),
      );
    }

    if (state.activeProject?.isCompleted == true &&
        state.phase == PomodoroPhase.idle) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success.withValues(alpha: 0.12),
          disabledBackgroundColor:
              AppColors.success.withValues(alpha: 0.12),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 20, color: AppColors.success),
            const SizedBox(width: 10),
            Text(
              l.projectCompletedExclaim,
              style: const TextStyle(
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded, size: 26),
            const SizedBox(width: 8),
            Text(l.start,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    if (state.phase == PomodoroPhase.working) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          disabledBackgroundColor:
              AppColors.primary.withValues(alpha: 0.12),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              l.pomodoroOngoing,
              style: const TextStyle(
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.play_arrow_rounded, size: 26),
          const SizedBox(width: 8),
          Text(l.resume,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _phaseLabel(AppLocalizations l, PomodoroPhase phase) =>
      switch (phase) {
        PomodoroPhase.working => l.phaseWorking,
        PomodoroPhase.paused => l.phasePaused,
        PomodoroPhase.shortBreak => l.phaseShortBreak,
        PomodoroPhase.longBreak => l.phaseLongBreak,
        PomodoroPhase.askComplete => l.phaseSessionComplete,
        PomodoroPhase.breakDone => l.phaseBreakDone,
        PomodoroPhase.idle => l.phaseReady,
      };
}

// ── Secondary button ──────────────────────────────────────────────────────────

class _SecondaryBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SecondaryBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 13)),
    );
  }
}

// ── Cycle indicator with pill dots ────────────────────────────────────────────

class _CycleIndicator extends StatelessWidget {
  final int completed;
  final int sessionNumber;
  final Color phaseColor;
  final Color textSecondary;
  final bool isBreak;
  final AppLocalizations l;

  const _CycleIndicator({
    required this.completed,
    required this.sessionNumber,
    required this.phaseColor,
    required this.textSecondary,
    required this.isBreak,
    required this.l,
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
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: filled ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
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
                  ? l.cycleComplete
                  : l.sessionCompletedOf(completed)
              : l.sessionOf(sessionNumber),
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

// ── Background radial glow ────────────────────────────────────────────────────

class _BackgroundGlowPainter extends CustomPainter {
  final Color color;
  final double intensity;

  const _BackgroundGlowPainter({
    required this.color,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.28 * intensity),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(
          Rect.fromCircle(center: center, radius: size.width * 0.5));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_BackgroundGlowPainter old) =>
      old.intensity != intensity || old.color != color;
}

// ── Timer arc painter with optional glow ─────────────────────────────────────

class _TimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color? glowColor;
  final Color trackColor;
  final double strokeWidth;

  const _TimerPainter({
    required this.progress,
    required this.color,
    this.glowColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        (math.min(size.width, size.height) / 2) - strokeWidth / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );

    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress;

      // Glow layer
      if (glowColor != null) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -math.pi / 2,
          sweepAngle,
          false,
          Paint()
            ..color = glowColor!.withValues(alpha: 0.45)
            ..strokeWidth = strokeWidth + 8
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..maskFilter =
                const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }

      // Main arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
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
      old.progress != progress ||
      old.color != color ||
      old.glowColor != glowColor;
}

// ── Splitting loading screen ──────────────────────────────────────────────────

class _SplittingLoadingScreen extends StatelessWidget {
  final bool isDark;
  const _SplittingLoadingScreen({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).analyzingTask,
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Motivation / coach screen ─────────────────────────────────────────────────

class _MotivationScreen extends StatelessWidget {
  final String motivation;
  final String coachMessage;
  final int splitCount;
  final bool isDark;
  final VoidCallback onRetry;

  const _MotivationScreen({
    required this.motivation,
    required this.coachMessage,
    required this.splitCount,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final textPrimary = AppColors.textPrimary(isDark);
    final cardColor = AppColors.card(isDark);
    final borderColor = AppColors.border(isDark);

    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 48, 28, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Título
              Text(
                l.blockMomentTitle,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1.2,
                ),
              ),
              if (splitCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  l.splitIntoSteps(splitCount),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Motivación del proyecto
              if (motivation.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.flag_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l.whyStarted,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        motivation,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Mensaje del coach
              if (coachMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.breakColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.record_voice_over_rounded,
                              size: 15,
                              color: AppColors.breakColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l.yourCoach,
                            style: TextStyle(
                              color: AppColors.breakColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        coachMessage,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 40),

              // Botón volver a intentar
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow_rounded, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          l.tryAgain,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
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
    );
  }
}

// ── Task complete dialog ──────────────────────────────────────────────────────

class _BreakDoneDialog extends StatelessWidget {
  final VoidCallback onStart;

  const _BreakDoneDialog({required this.onStart});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = context.watch<AppState>().isDarkMode;
    final bg = AppColors.card(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);

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
                color: AppColors.breakSoft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.coffee_rounded,
                  size: 34, color: AppColors.breakColor),
            ),
            const SizedBox(height: 20),
            Text(
              l.breakOverTitle,
              style: TextStyle(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              l.breakOverBody,
              style: TextStyle(color: textSecondary, fontSize: 14, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(l.letsGo,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCompleteDialog extends StatelessWidget {
  final String taskTitle;
  final int done;
  final int estimate;
  final VoidCallback onComplete;
  final VoidCallback onContinue;

  const _TaskCompleteDialog({
    required this.taskTitle,
    required this.done,
    required this.estimate,
    required this.onComplete,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = context.watch<AppState>().isDarkMode;
    final bg = AppColors.card(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);

    return Dialog(
      backgroundColor: bg,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
              l.didYouComplete,
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
                style: TextStyle(
                    color: textSecondary, fontSize: 14, height: 1.4),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l.pomodoroOfEstimate(done, estimate),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 24),
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
                child: Text(l.yesCompleted,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
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
                  side: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(l.notYet,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Over-estimate choice: +1 pomodoro o dividir ───────────────────────────────

class _OverEstimateDialog extends StatelessWidget {
  final VoidCallback onMore;
  final VoidCallback onSplit;

  const _OverEstimateDialog({required this.onMore, required this.onSplit});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = context.watch<AppState>().isDarkMode;
    final bg = AppColors.card(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);

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
                color: AppColors.breakSoft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.hourglass_bottom_rounded,
                  size: 34, color: AppColors.breakColor),
            ),
            const SizedBox(height: 20),
            Text(
              l.overEstimateTitle,
              style: TextStyle(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              l.overEstimateBody,
              style: TextStyle(color: textSecondary, fontSize: 14, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onMore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(l.oneMorePomodoro,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: onSplit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(l.splitTaskAction,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
