import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  final _registerNameCtrl = TextEditingController();
  final _registerEmailCtrl = TextEditingController();
  final _registerPassCtrl = TextEditingController();
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _registerNameCtrl.dispose();
    _registerEmailCtrl.dispose();
    _registerPassCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final l = AppLocalizations.of(context);
    final name = _registerNameCtrl.text.trim();
    final email = _registerEmailCtrl.text.trim();
    final pass = _registerPassCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => _error = l.fillAllFields);
      return;
    }
    if (!email.contains('@')) {
      setState(() => _error = l.invalidEmail);
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = l.passwordTooShort);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final error = await context.read<AppState>().register(name, email, pass);
    if (mounted) {
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  Future<void> _login() async {
    final l = AppLocalizations.of(context);
    final email = _loginEmailCtrl.text.trim();
    final pass = _loginPassCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = l.fillAllFields);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final error = await context.read<AppState>().login(email, pass);
    if (mounted) {
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = context.watch<AppState>().isDarkMode;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final card = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 56),
              // Logo
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.timer_rounded,
                    color: Colors.white, size: 38),
              ),
              const SizedBox(height: 16),
              Text(
                'Atom',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.authTagline,
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 40),

              // Card contenedor
              Container(
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: [
                    // Tabs
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.bgDark
                              : AppColors.bgLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          controller: _tabs,
                          indicator: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: textSecondary,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          tabs: [
                            Tab(text: l.tabRegister),
                            Tab(text: l.tabLogin),
                          ],
                        ),
                      ),
                    ),

                    // Forms
                    SizedBox(
                      height: _tabs.index == 0 ? 320 : 260,
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _RegisterForm(
                            nameCtrl: _registerNameCtrl,
                            emailCtrl: _registerEmailCtrl,
                            passCtrl: _registerPassCtrl,
                            obscure: _obscure,
                            onToggleObscure: () =>
                                setState(() => _obscure = !_obscure),
                            border: border,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                          ),
                          _LoginForm(
                            emailCtrl: _loginEmailCtrl,
                            passCtrl: _loginPassCtrl,
                            obscure: _obscure,
                            onToggleObscure: () =>
                                setState(() => _obscure = !_obscure),
                            border: border,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    // Error
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.redAccent, size: 15),
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

                    // Botón
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  if (_tabs.index == 0) {
                                    _register();
                                  } else {
                                    _login();
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
                                  _tabs.index == 0
                                      ? l.createAccount
                                      : l.signIn,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          _Field(
            ctrl: nameCtrl,
            hint: l.hintName,
            icon: Icons.person_outline_rounded,
            border: border,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _Field(
            ctrl: emailCtrl,
            hint: l.hintEmail,
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            border: border,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _Field(
            ctrl: passCtrl,
            hint: l.hintPassword,
            icon: Icons.lock_outline_rounded,
            obscure: obscure,
            onToggleObscure: onToggleObscure,
            border: border,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          _Field(
            ctrl: emailCtrl,
            hint: l.hintEmail,
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            border: border,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _Field(
            ctrl: passCtrl,
            hint: l.hintPassword,
            icon: Icons.lock_outline_rounded,
            obscure: obscure,
            onToggleObscure: onToggleObscure,
            border: border,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.ctrl,
    required this.hint,
    required this.icon,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType,
  });

  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      // Sin autocorrector: evita que dañe el email, el nombre o la contraseña.
      autocorrect: false,
      enableSuggestions: false,
      style: TextStyle(color: textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: textSecondary, fontSize: 15),
        prefixIcon: Icon(icon, color: textSecondary, size: 20),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: textSecondary,
                  size: 20,
                ),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: isDark
            ? AppColors.bgDark
            : AppColors.bgLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
