import 'package:flutter/material.dart';

import 'package:helpi_app/app/senior_shell.dart';
import 'package:helpi_app/app/student_shell.dart';
import 'package:helpi_app/app/theme.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/l10n/locale_notifier.dart';
import 'package:helpi_app/core/services/auth_service.dart';
import 'package:helpi_app/features/auth/presentation/login_screen.dart';
import 'package:helpi_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:helpi_app/features/onboarding/presentation/registration_data_screen.dart';
import 'package:helpi_app/features/schedule/data/availability_model.dart';

/// Root widget — role-based routing između Customer i Student shella.
class HelpiApp extends StatefulWidget {
  const HelpiApp({super.key});

  @override
  State<HelpiApp> createState() => _HelpiAppState();
}

class _HelpiAppState extends State<HelpiApp> {
  final _localeNotifier = LocaleNotifier();
  final _authService = AuthService();
  final _availabilityNotifier = AvailabilityNotifier();

  bool _isLoggedIn = false;
  String? _userType;

  // Student-only flow state:
  bool _needsRegistrationData = false;
  bool _needsOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final loggedIn = await _authService.isLoggedIn();
    if (!loggedIn) return;

    final userType = await _authService.getCurrentUserType();
    if (!mounted) return;

    setState(() {
      _isLoggedIn = true;
      _userType = userType;
    });
  }

  // ── Login: API pozvan, token + userType spremljeni ──
  Future<void> _handleLoginSuccess() async {
    final userType = await _authService.getCurrentUserType();
    if (!mounted) return;

    setState(() {
      _isLoggedIn = true;
      _userType = userType;
    });
  }

  // ── Register: profil dovršen u LoginScreen (Customer flow) ──
  void _handleRegisterSuccess() {
    setState(() {
      _isLoggedIn = true;
      _userType = 'Customer';
    });
  }

  // ── Register: Student odabrao ulogu, ide na RegistrationData ──
  void _handleStudentRegisterSuccess() {
    setState(() {
      _isLoggedIn = true;
      _userType = 'Student';
      _needsRegistrationData = true;
    });
  }

  // ── Logout ──
  Future<void> _handleLogout() async {
    await _authService.logout();
    _availabilityNotifier.reset();
    if (!mounted) return;

    setState(() {
      _isLoggedIn = false;
      _userType = null;
      _needsRegistrationData = false;
      _needsOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: _localeNotifier,
      builder: (context, locale, _) {
        AppStrings.setLocale(locale.languageCode);

        return MaterialApp(
          title: 'Helpi',
          debugShowCheckedModeBanner: false,
          theme: HelpiTheme.light,
          home: _buildHome(),
        );
      },
    );
  }

  Widget _buildHome() {
    // 1. Nije logiran → LoginScreen
    if (!_isLoggedIn) {
      return LoginScreen(
        localeNotifier: _localeNotifier,
        onLoginSuccess: _handleLoginSuccess,
        onRegisterSuccess: _handleRegisterSuccess,
        onStudentRegisterSuccess: _handleStudentRegisterSuccess,
      );
    }

    // 2. Student: registracija → RegistrationData → Onboarding → Shell
    if (_userType == 'Student') {
      if (_needsRegistrationData) {
        return RegistrationDataScreen(
          onComplete: () {
            setState(() {
              _needsRegistrationData = false;
              _needsOnboarding = true;
            });
          },
          onBack: () {
            setState(() {
              _isLoggedIn = false;
              _userType = null;
              _needsRegistrationData = false;
            });
          },
        );
      }

      if (_needsOnboarding) {
        return OnboardingScreen(
          availabilityNotifier: _availabilityNotifier,
          onComplete: () {
            setState(() => _needsOnboarding = false);
          },
          onBack: () {
            setState(() => _needsRegistrationData = true);
          },
        );
      }

      return StudentShell(
        localeNotifier: _localeNotifier,
        availabilityNotifier: _availabilityNotifier,
        onLogout: _handleLogout,
      );
    }

    // 3. Customer (Senior) → SeniorShell
    return SeniorShell(
      localeNotifier: _localeNotifier,
      onLogout: _handleLogout,
    );
  }
}
