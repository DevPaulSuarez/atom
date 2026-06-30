import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/app_state.dart';
import 'screens/auth_screen.dart';
import 'screens/force_update_dialog.dart';
import 'screens/onboarding_screen.dart';
import 'screens/projects_screen.dart';
import 'services/api_service.dart';
import 'services/version_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Carga los datos de fecha de todos los locales (es/en), necesarios para
  // DateFormat (ej. el gráfico de 7 días en Progreso). Sin esto, lanza
  // "Locale data has not been initialized" y rompe la pantalla.
  await initializeDateFormatting();
  debugPrint('🌐 API base: ${ApiService.baseUrl}');
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const AtomApp(),
    ),
  );
}

class AtomApp extends StatefulWidget {
  const AtomApp({super.key});

  @override
  State<AtomApp> createState() => _AtomAppState();
}

class _AtomAppState extends State<AtomApp> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _versionService = VersionService();
  bool _updateDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVersion());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver a primer plano recalculamos el timer (iOS lo congela mientras
    // la app está en segundo plano o la pantalla bloqueada).
    if (state == AppLifecycleState.resumed) {
      context.read<AppState>().onAppResumed();
      _checkVersion();
    }
  }

  /// Pregunta al backend si la versión instalada quedó obsoleta y, de ser así,
  /// muestra un diálogo que obliga a actualizar antes de seguir.
  Future<void> _checkVersion() async {
    if (_updateDialogOpen) return;
    final result = await _versionService.check();
    if (result == null || !result.mustUpdate) return;

    final navContext = _navigatorKey.currentContext;
    if (navContext == null || !navContext.mounted) return;

    _updateDialogOpen = true;
    await showDialog<void>(
      context: navContext,
      barrierDismissible: false,
      builder: (_) => ForceUpdateDialog(storeUrl: result.storeUrl),
    );
    _updateDialogOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      title: 'Atom',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: state.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: _resolveHome(state),
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return _ResponsiveShell(child: child);
      },
    );
  }

  Widget _resolveHome(AppState state) {
    if (!state.authLoaded) return const _SplashScreen();
    if (!state.hasSeenOnboarding) return const OnboardingScreen();
    if (!state.isLoggedIn) return const AuthScreen();
    return const ProjectsScreen();
  }
}

/// En iPad (y pantallas anchas) renderiza la misma interfaz del teléfono pero
/// "escalada" para llenar la pantalla: todo se ve igual que en el celular, solo
/// que proporcionalmente más grande. En el teléfono no cambia nada.
class _ResponsiveShell extends StatelessWidget {
  const _ResponsiveShell({required this.child});

  final Widget child;

  // Ancho lógico de referencia (como el de un teléfono grande).
  static const double _designWidth = 430;
  // Cuánto puede agrandarse como máximo respecto al teléfono.
  static const double _maxScale = 2.0;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    // Factor de zoom según el ancho real de la pantalla, limitado por _maxScale.
    final scale = (size.width / _designWidth).clamp(1.0, _maxScale);
    if (scale <= 1.0) return child; // teléfonos: sin cambios

    // Tamaño lógico que "ve" la app (un teléfono), luego FittedBox lo agranda
    // uniformemente para llenar toda la pantalla.
    final logicalWidth = size.width / scale;
    final logicalHeight = size.height / scale;

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.center,
        child: SizedBox(
          width: logicalWidth,
          height: logicalHeight,
          child: MediaQuery(
            data: mq.copyWith(
              size: Size(logicalWidth, logicalHeight),
              padding: mq.padding / scale,
              viewPadding: mq.viewPadding / scale,
              viewInsets: mq.viewInsets / scale,
            ),
            child: child,
          ),
        ),
      ),
    );
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
