import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

void showSettingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final isDark = state.isDarkMode;
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
      child: SafeArea(
        top: false,
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
            Text(
              l.settings,
              style: TextStyle(
                color: textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),

            // ── Apariencia ────────────────────────────────────────────────
            _SectionLabel(text: l.appearance.toUpperCase(), color: textSecondary),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bg(isDark),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border(isDark)),
              ),
              child: SwitchListTile(
                value: isDark,
                onChanged: (_) => context.read<AppState>().toggleTheme(),
                activeThumbColor: AppColors.primary,
                title: Text(
                  l.darkMode,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                secondary: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Idioma ────────────────────────────────────────────────────
            _SectionLabel(text: l.language.toUpperCase(), color: textSecondary),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bg(isDark),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border(isDark)),
              ),
              child: Column(
                children: [
                  _LangTile(
                    label: l.systemDefault,
                    mode: 'system',
                    selected: state.localeMode == 'system',
                    isDark: isDark,
                  ),
                  _Divider(isDark: isDark),
                  _LangTile(
                    label: l.languageEnglish,
                    mode: 'en',
                    selected: state.localeMode == 'en',
                    isDark: isDark,
                  ),
                  _Divider(isDark: isDark),
                  _LangTile(
                    label: l.languageSpanish,
                    mode: 'es',
                    selected: state.localeMode == 'es',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Cerrar sesión ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<AppState>().logout();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: Text(
                  l.logout,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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

/// Diálogo reutilizable para elegir minutos personalizados.
/// Devuelve los minutos elegidos, o null si se cancela.
Future<int?> showCustomMinutesDialog(BuildContext context, int initial) {
  return showDialog<int>(
    context: context,
    builder: (_) => _CustomDurationDialog(initial: initial),
  );
}

/// Selector de duración de enfoque ligado a un valor en minutos (no al ajuste
/// global). Se usa al crear un proyecto. Muestra los 3 presets + personalizado.
class FocusDurationField extends StatelessWidget {
  final int minutes;
  final ValueChanged<int> onChanged;
  final bool isDark;

  const FocusDurationField({
    super.key,
    required this.minutes,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final presets = AppState.focusPresets;
    final isPreset = presets.values.contains(minutes);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Column(
        children: [
          _FocusTile(
            emoji: '🌱',
            label: l.focusBeginner,
            minutes: presets['beginner']!,
            selected: minutes == presets['beginner'],
            isDark: isDark,
            onTap: () => onChanged(presets['beginner']!),
          ),
          _Divider(isDark: isDark),
          _FocusTile(
            emoji: '🚀',
            label: l.focusFocused,
            minutes: presets['focused']!,
            selected: minutes == presets['focused'],
            isDark: isDark,
            onTap: () => onChanged(presets['focused']!),
          ),
          _Divider(isDark: isDark),
          _FocusTile(
            emoji: '🎯',
            label: l.focusClassic,
            minutes: presets['classic']!,
            selected: minutes == presets['classic'],
            isDark: isDark,
            onTap: () => onChanged(presets['classic']!),
          ),
          _Divider(isDark: isDark),
          _FocusTile(
            emoji: '⚙️',
            label: l.focusCustom,
            minutes: minutes,
            selected: !isPreset,
            isDark: isDark,
            onTap: () async {
              final mins = await showCustomMinutesDialog(context, minutes);
              if (mins != null) onChanged(mins);
            },
          ),
        ],
      ),
    );
  }
}

class _FocusTile extends StatelessWidget {
  final String emoji;
  final String label;
  final int minutes;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _FocusTile({
    required this.emoji,
    required this.label,
    required this.minutes,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListTile(
      onTap: onTap,
      leading: Text(emoji, style: const TextStyle(fontSize: 22)),
      title: Text(
        label,
        style: TextStyle(
          color: AppColors.textPrimary(isDark),
          fontSize: 15,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.minutesValue(minutes),
            style: TextStyle(
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary(isDark),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.check_rounded,
            size: 20,
            color: selected ? AppColors.primary : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _CustomDurationDialog extends StatefulWidget {
  final int initial;
  const _CustomDurationDialog({required this.initial});

  @override
  State<_CustomDurationDialog> createState() => _CustomDurationDialogState();
}

class _CustomDurationDialogState extends State<_CustomDurationDialog> {
  late double _minutes = widget.initial.toDouble();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = context.read<AppState>().isDarkMode;
    final textPrimary = AppColors.textPrimary(isDark);

    return AlertDialog(
      backgroundColor: AppColors.card(isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(l.customDurationTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.minutesValue(_minutes.round()),
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _minutes,
            min: AppState.minCustomMinutes.toDouble(),
            max: AppState.maxCustomMinutes.toDouble(),
            divisions: AppState.maxCustomMinutes - AppState.minCustomMinutes,
            activeColor: AppColors.primary,
            label: '${_minutes.round()}',
            onChanged: (v) => setState(() => _minutes = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel, style: TextStyle(color: textPrimary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () => Navigator.pop(context, _minutes.round()),
          child: Text(l.save),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: AppColors.border(isDark));
}

class _LangTile extends StatelessWidget {
  final String label;
  final String mode;
  final bool selected;
  final bool isDark;

  const _LangTile({
    required this.label,
    required this.mode,
    required this.selected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.read<AppState>().setLocaleMode(mode),
      title: Text(
        label,
        style: TextStyle(
          color: AppColors.textPrimary(isDark),
          fontSize: 15,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: AppColors.primary)
          : null,
    );
  }
}
