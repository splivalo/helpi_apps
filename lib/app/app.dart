import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:helpi_app/app/senior_shell.dart';
import 'package:helpi_app/app/student_shell.dart';
import 'package:helpi_app/app/theme.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/l10n/locale_notifier.dart';
import 'package:helpi_app/core/l10n/theme_notifier.dart';
import 'package:helpi_app/core/providers/auth_provider.dart';
import 'package:helpi_app/core/providers/realtime_sync_provider.dart';
import 'package:helpi_app/core/providers/signalr_provider.dart';
import 'package:helpi_app/features/auth/presentation/login_screen.dart';
import 'package:helpi_app/features/auth/presentation/server_unavailable_screen.dart';
import 'package:helpi_app/features/auth/presentation/suspended_screen.dart';
import 'package:helpi_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:helpi_app/features/onboarding/presentation/registration_data_screen.dart';

/// Root widget - role-based routing between Customer and Student shell.
class HelpiApp extends ConsumerStatefulWidget {
  const HelpiApp({super.key});

  @override
  ConsumerState<HelpiApp> createState() => _HelpiAppState();
}

class _HelpiAppState extends ConsumerState<HelpiApp>
    with WidgetsBindingObserver {
  final _localeNotifier = LocaleNotifier();
  final _themeNotifier = ThemeNotifier();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final auth = ref.read(authProvider);
      if (auth.isLoggedIn) {
        // Re-fetch data - if user was suspended, 403 interceptor will handle it.
        // If user was activated, data refreshes and suspension clears.
        ref.read(authProvider.notifier).refreshAfterResume();

        // Reconnect SignalR if WebSocket dropped while in background.
        final signalR = ref.read(signalRProvider);
        if (!signalR.isConnected) {
          signalR.start();
        }
      }
    }
  }

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

        return ValueListenableBuilder<ThemeMode>(
          valueListenable: _themeNotifier,
          builder: (context, themeMode, _) {
            return MaterialApp(
              title: 'Helpi',
              debugShowCheckedModeBanner: false,
              theme: HelpiTheme.light,
              darkTheme: HelpiTheme.dark,
              themeMode: themeMode,
              locale: locale,
              supportedLocales: const [Locale('hr'), Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              // Offstage SVGs force flutter_svg to parse + cache on first
              // frame, eliminating the pop-in delay on actual screens.
              builder: (context, child) => Stack(
                children: [
                  child!,
                  Offstage(
                    child: Row(
                      children: [
                        SvgPicture.asset('assets/images/illustration.svg'),
                        SvgPicture.asset('assets/images/h_logo.svg'),
                      ],
                    ),
                  ),
                ],
              ),
              home: _buildHome(auth),
            );
          },
        );
      },
    );
  }

  Widget _buildHome(AuthState auth) {
    final authNotifier = ref.read(authProvider.notifier);

    // -1. Provjera sessiona u tijeku -> splash/loading
    if (auth.isCheckingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 0. Suspendiran -> SuspendedScreen
    if (auth.isSuspended) {
      return SuspendedScreen(
        reason: auth.suspendReason,
        onLogout: authNotifier.handleLogout,
      );
    }

    // 0.5 Server unavailable -> ServerUnavailableScreen
    if (auth.isServerUnavailable) {
      return ServerUnavailableScreen(
        onServerBack: authNotifier.handleServerBack,
      );
    }

    // 1. Nije logiran -> LoginScreen
    if (!auth.isLoggedIn) {
      return LoginScreen(
        localeNotifier: _localeNotifier,
        onLoginSuccess: authNotifier.handleLoginSuccess,
        onRegisterSuccess: authNotifier.handleRegisterSuccess,
        onStudentRegisterSuccess: authNotifier.handleStudentRegisterSuccess,
      );
    }

    // 2. Student: registration -> RegistrationData -> Onboarding -> Shell
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
        themeNotifier: _themeNotifier,
        availabilityNotifier: authNotifier.availabilityNotifier,
        onLogout: authNotifier.handleLogout,
      );
    }

    // 3. Customer (Senior) -> SeniorShell
    return SeniorShell(
      localeNotifier: _localeNotifier,
      themeNotifier: _themeNotifier,
      onLogout: authNotifier.handleLogout,
      ordersNotifier: authNotifier.ordersNotifier,
    );
  }
}
