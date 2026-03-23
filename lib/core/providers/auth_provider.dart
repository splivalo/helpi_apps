import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:helpi_app/core/network/api_client.dart';
import 'package:helpi_app/core/services/auth_service.dart';
import 'package:helpi_app/core/services/data_loader.dart';
import 'package:helpi_app/features/booking/data/order_model.dart';
import 'package:helpi_app/features/schedule/data/availability_model.dart';

/// Auth stanje — drži login status, user type i suspension info.
class AuthState {
  const AuthState({
    this.isLoggedIn = false,
    this.userType,
    this.isSuspended = false,
    this.suspendReason,
    this.isServerUnavailable = false,
    this.needsRegistrationData = false,
    this.needsOnboarding = false,
    this.pendingStudentEmail,
    this.pendingStudentPassword,
  });

  final bool isLoggedIn;
  final String? userType;
  final bool isSuspended;
  final String? suspendReason;
  final bool isServerUnavailable;

  // Student-only flow:
  final bool needsRegistrationData;
  final bool needsOnboarding;
  final String? pendingStudentEmail;
  final String? pendingStudentPassword;

  AuthState copyWith({
    bool? isLoggedIn,
    String? userType,
    bool? isSuspended,
    String? suspendReason,
    bool? isServerUnavailable,
    bool? needsRegistrationData,
    bool? needsOnboarding,
    String? pendingStudentEmail,
    String? pendingStudentPassword,
    bool clearUserType = false,
    bool clearSuspendReason = false,
    bool clearPendingEmail = false,
    bool clearPendingPassword = false,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userType: clearUserType ? null : (userType ?? this.userType),
      isSuspended: isSuspended ?? this.isSuspended,
      suspendReason: clearSuspendReason
          ? null
          : (suspendReason ?? this.suspendReason),
      isServerUnavailable: isServerUnavailable ?? this.isServerUnavailable,
      needsRegistrationData:
          needsRegistrationData ?? this.needsRegistrationData,
      needsOnboarding: needsOnboarding ?? this.needsOnboarding,
      pendingStudentEmail: clearPendingEmail
          ? null
          : (pendingStudentEmail ?? this.pendingStudentEmail),
      pendingStudentPassword: clearPendingPassword
          ? null
          : (pendingStudentPassword ?? this.pendingStudentPassword),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authService) : super(const AuthState()) {
    ApiClient.onSuspended = _handleSuspension;
    _checkExistingSession();
  }

  final AuthService _authService;
  final OrdersNotifier ordersNotifier = OrdersNotifier();
  final AvailabilityNotifier availabilityNotifier = AvailabilityNotifier();

  void _handleSuspension(String? reason) {
    state = state.copyWith(isSuspended: true, suspendReason: reason);
  }

  Future<void> _checkExistingSession() async {
    try {
      final loggedIn = await _authService.isLoggedIn();
      if (!loggedIn) return;

      final userType = await _authService.getCurrentUserType();
      state = state.copyWith(isLoggedIn: true, userType: userType);

      _loadDataForUser(userType);
    } catch (e) {
      debugPrint('[AuthNotifier] checkExistingSession error: $e');
    }
  }

  void _loadDataForUser(String? userType) {
    DataLoader.loadAll(
      ordersNotifier: userType == 'Customer' ? ordersNotifier : null,
      availabilityNotifier: userType == 'Student' ? availabilityNotifier : null,
    ).then((ok) {
      if (!ok) {
        state = state.copyWith(isServerUnavailable: true);
      }
    });
  }

  /// Poziva se nakon uspješnog logina.
  Future<void> handleLoginSuccess() async {
    final userType = await _authService.getCurrentUserType();
    state = state.copyWith(isLoggedIn: true, userType: userType);
    _loadDataForUser(userType);
  }

  /// Register Customer (Senior) — profil dovršen u LoginScreen.
  void handleRegisterSuccess() {
    state = state.copyWith(isLoggedIn: true, userType: 'Customer');
  }

  /// Register Student — ide na RegistrationData flow.
  void handleStudentRegisterSuccess(String email, String password) {
    state = state.copyWith(
      isLoggedIn: true,
      userType: 'Student',
      needsRegistrationData: true,
      pendingStudentEmail: email,
      pendingStudentPassword: password,
    );
  }

  /// Student RegistrationData završen → ide na Onboarding.
  void completeRegistrationData() {
    state = state.copyWith(
      needsRegistrationData: false,
      needsOnboarding: true,
      clearPendingEmail: true,
      clearPendingPassword: true,
    );
  }

  /// Back iz RegistrationData → nazad na login.
  void backFromRegistrationData() {
    state = state.copyWith(
      isLoggedIn: false,
      clearUserType: true,
      needsRegistrationData: false,
      clearPendingEmail: true,
      clearPendingPassword: true,
    );
  }

  /// Onboarding završen.
  void completeOnboarding() {
    state = state.copyWith(needsOnboarding: false);
  }

  /// Back iz Onboarding → nazad na RegistrationData.
  void backFromOnboarding() {
    state = state.copyWith(needsRegistrationData: true);
  }

  /// Poziva se kad health check sa ServerUnavailableScreen uspije.
  void handleServerBack() {
    state = state.copyWith(isServerUnavailable: false);
    _loadDataForUser(state.userType);
  }

  /// Logout — reset svega.
  Future<void> handleLogout() async {
    await _authService.logout();
    availabilityNotifier.reset();
    DataLoader.reset();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(AuthService());
});
