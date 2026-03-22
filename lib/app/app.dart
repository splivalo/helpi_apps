import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:helpi_app/app/senior_shell.dart';
import 'package:helpi_app/app/student_shell.dart';
import 'package:helpi_app/app/theme.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/l10n/locale_notifier.dart';
import 'package:helpi_app/core/providers/auth_provider.dart';
import 'package:helpi_app/core/providers/realtime_sync_provider.dart';
import 'package:helpi_app/core/providers/signalr_provider.dart';
import 'package:helpi_app/features/auth/presentation/login_screen.dart';
import 'package:helpi_app/features/auth/presentation/suspended_screen.dart';
import 'package:helpi_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:helpi_app/features/onboarding/presentation/registration_data_screen.dart';

/// Root widget — role-based routing između Customer i Student shella.
class HelpiApp extends ConsumerStatefulWidget {
  const HelpiApp({super.key});

  @override
  ConsumerState<HelpiApp> createState() => _HelpiAppState();
}

class _HelpiAppState extends ConsumerState<HelpiApp> {
  final _localeNotifier = LocaleNotifier();

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    // Eagerly initialize SignalR + real-time sync
    ref.watch(signalRProvider);
    ref.watch(realTimeSyncProvider);

    return ValueListenableBuilder<Locale>(
      valueListenable: _localeNotifier,
      builder: (context, locale, _) {
        AppStrings.setLocale(locale.languageCode);

        return MaterialApp(
          title: 'Helpi',
          debugShowCheckedModeBanner: false,
          theme: HelpiTheme.light,
          locale: locale,
          supportedLocales: const [Locale('hr'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: _buildHome(auth),
        );
      },
    );
  }

  Widget _buildHome(AuthState auth) {
    final authNotifier = ref.read(authProvider.notifier);

    // 0. Suspendiran → SuspendedScreen
    if (auth.isSuspended) {
      return SuspendedScreen(
        reason: auth.suspendReason,
        onLogout: authNotifier.handleLogout,
      );
    }

    // 1. Nije logiran → LoginScreen
    if (!auth.isLoggedIn) {
      return LoginScreen(
        localeNotifier: _localeNotifier,
        onLoginSuccess: authNotifier.handleLoginSuccess,
        onRegisterSuccess: authNotifier.handleRegisterSuccess,
        onStudentRegisterSuccess: authNotifier.handleStudentRegisterSuccess,
      );
    }

    // 2. Student: registracija → RegistrationData → Onboarding → Shell
    if (auth.userType == 'Student') {
      if (auth.needsRegistrationData) {
        return RegistrationDataScreen(
          email: auth.pendingStudentEmail ?? '',
          password: auth.pendingStudentPassword ?? '',
          onComplete: authNotifier.completeRegistrationData,
          onBack: authNotifier.backFromRegistrationData,
        );
      }

      if (auth.needsOnboarding) {
        return OnboardingScreen(
          availabilityNotifier: authNotifier.availabilityNotifier,
          onComplete: authNotifier.completeOnboarding,
          onBack: authNotifier.backFromOnboarding,
        );
      }

      return StudentShell(
        localeNotifier: _localeNotifier,
        availabilityNotifier: authNotifier.availabilityNotifier,
        onLogout: authNotifier.handleLogout,
      );
    }

    // 3. Customer (Senior) → SeniorShell
    return SeniorShell(
      localeNotifier: _localeNotifier,
      onLogout: authNotifier.handleLogout,
      ordersNotifier: authNotifier.ordersNotifier,
    );
  }
}
