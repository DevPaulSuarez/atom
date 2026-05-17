import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/projects_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const AtomApp(),
    ),
  );
}

class AtomApp extends StatelessWidget {
  const AtomApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      title: 'Atom',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _resolveHome(state),
    );
  }

  Widget _resolveHome(AppState state) {
    if (!state.authLoaded) return const _SplashScreen();
    if (!state.hasSeenOnboarding) return const OnboardingScreen();
    if (!state.isLoggedIn) return const AuthScreen();
    return const ProjectsScreen();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_rounded, color: AppColors.primary, size: 52),
            SizedBox(height: 16),
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
