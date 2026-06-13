import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pageCount = 4;

  List<_PageData> _buildPages(AppLocalizations l) => [
    _PageData(
      icon: Icons.timer_rounded,
      iconColor: AppColors.primary,
      iconBg: const Color(0xFF2A2A4A),
      title: l.onbTitle1,
      subtitle: l.onbBody1,
    ),
    _PageData(
      icon: Icons.auto_awesome_rounded,
      iconColor: AppColors.breakColor,
      iconBg: const Color(0xFF3A2A2A),
      title: l.onbTitle2,
      subtitle: l.onbBody2,
    ),
    _PageData(
      icon: Icons.task_alt_rounded,
      iconColor: AppColors.success,
      iconBg: const Color(0xFF1A3A2A),
      title: l.onbTitle3,
      subtitle: l.onbBody3,
    ),
    _PageData(
      icon: Icons.insights_rounded,
      iconColor: AppColors.longBreakColor,
      iconBg: const Color(0xFF1A2A3A),
      title: l.onbTitle4,
      subtitle: l.onbBody4,
    ),
  ];

  void _next() {
    if (_page < _pageCount - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    context.read<AppState>().completeOnboarding();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pages = _buildPages(l);
    final isLast = _page == pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 24, 0),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    l.skip,
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: pages.length,
                itemBuilder: (_, i) => _PageView(data: pages[i]),
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? AppColors.primary
                              : AppColors.borderDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botón
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLast ? l.getStarted : l.next,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isLast
                                ? Icons.rocket_launch_rounded
                                : Icons.arrow_forward_rounded,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageData {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;

  const _PageData({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });
}

class _PageView extends StatelessWidget {
  final _PageData data;
  const _PageView({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: data.iconBg,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: data.iconColor.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Icon(data.icon, size: 52, color: data.iconColor),
          ),
          const SizedBox(height: 48),

          // Título
          Text(
            data.title,
            style: const TextStyle(
              color: AppColors.textPrimaryDark,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Subtítulo
          Text(
            data.subtitle,
            style: const TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 16,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
