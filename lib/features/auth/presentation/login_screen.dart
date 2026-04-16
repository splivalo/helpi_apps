import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:helpi_app/core/constants/colors.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/l10n/locale_notifier.dart';
import 'package:helpi_app/core/services/auth_service.dart';
import 'package:helpi_app/shared/models/selected_address_info.dart';
import 'package:helpi_app/shared/widgets/helpi_form_fields.dart';
import 'package:helpi_app/shared/widgets/helpi_switch.dart';
import 'package:helpi_app/shared/widgets/mc_address_field.dart';

/// Login / Register screen - UI prototype, without real authentication.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.onRegisterSuccess,
    required this.onStudentRegisterSuccess,
    required this.localeNotifier,
  });

  /// Callback when user successfully clicks Login (API called, token saved).
  final VoidCallback onLoginSuccess;

  /// Callback when Customer completes registration (profile filled).
  final VoidCallback onRegisterSuccess;

  /// Callback kad Student odabere ulogu i upiše email/pass.
  final void Function(String email, String password) onStudentRegisterSuccess;

  final LocaleNotifier localeNotifier;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authService = AuthService();
  late String _selectedLang = AppStrings.currentLocale.toUpperCase();
  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isServerError = false;

  // -- Registration step 2: role picker, step 3: profile data --
  int _registerStep =
      0; // 0 = email/pass, 1 = role picker, 2 = profile (Customer only)

  // Customer
  final _ordFirstNameCtrl = TextEditingController();
  final _ordLastNameCtrl = TextEditingController();
  final _ordPhoneCtrl = TextEditingController();
  String _ordGender = 'M';
  DateTime? _ordDob;

  // Senior
  final _senFirstNameCtrl = TextEditingController();
  final _senLastNameCtrl = TextEditingController();
  final _senPhoneCtrl = TextEditingController();
  final _senAddressCtrl = TextEditingController();
  String _senGender = 'F';
  DateTime? _senDob;

  bool _orderingForOther = false;
  SelectedAddressInfo? _selectedAddress;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _ordFirstNameCtrl.dispose();
    _ordLastNameCtrl.dispose();
    _ordPhoneCtrl.dispose();
    _senFirstNameCtrl.dispose();
    _senLastNameCtrl.dispose();
    _senPhoneCtrl.dispose();
    _senAddressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isRoleStep = _isRegisterMode && _registerStep == 1;
            final isProfileStep = _isRegisterMode && _registerStep == 2;
            return SingleChildScrollView(
              padding: (isProfileStep || isRoleStep)
                  ? const EdgeInsets.all(16)
                  : const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: isProfileStep
                    ? _buildProfileStep(theme)
                    : isRoleStep
                    ? _buildRolePickerStep(theme)
                    : _buildLoginRegisterStep(theme),
              ),
            );
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // ERROR BANNER (shared by login + register)
  // ══════════════════════════════════════════════
  Widget _buildErrorBanner(BuildContext context) {
    final theme = Theme.of(context);
    final fg = _isServerError
        ? theme.colorScheme.tertiary
        : theme.colorScheme.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (_isServerError)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.cloud_off_outlined, color: fg, size: 20),
            ),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: fg, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // STEP 0: Login / Register (email + password)
  // ══════════════════════════════════════════════
  Widget _buildLoginRegisterStep(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 24),

        // -- Logo / Branding --
        Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            color: AppColors.coral,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/images/h_logo.svg',
              width: 50,
              height: 50,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // -- Title --
        Text(
          AppStrings.loginTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.loginSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 40),

        // -- Email field --
        AutofillGroup(
          child: Column(
            children: [
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [
                  AutofillHints.email,
                  AutofillHints.username,
                ],
                decoration: InputDecoration(
                  labelText: AppStrings.loginEmail,
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: AppColors.teal,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
              ),
              const SizedBox(height: 16),

              // -- Password field --
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                autofillHints: const [AutofillHints.password],
                onEditingComplete: TextInput.finishAutofillContext,
                decoration: InputDecoration(
                  labelText: AppStrings.loginPassword,
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.teal,
                  ),
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    child: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // -- Forgot password --
        if (!_isRegisterMode)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showForgotPasswordDialog(context),
              style: TextButton.styleFrom(foregroundColor: AppColors.teal),
              child: Text(
                AppStrings.forgotPassword,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        const SizedBox(height: 20),

        // -- Error message --
        if (_errorMessage != null) ...[
          _buildErrorBanner(context),
          const SizedBox(height: 16),
        ],

        // -- Main CTA button --
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : (_isRegisterMode ? _handleRegisterNext : _handleLogin),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _isRegisterMode ? AppStrings.next : AppStrings.loginButton,
                  ),
          ),
        ),
        const SizedBox(height: 24),

        // -- Toggle login / register --
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isRegisterMode ? AppStrings.hasAccount : AppStrings.noAccount,
              style: theme.textTheme.bodyMedium,
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isRegisterMode = !_isRegisterMode;
                  _registerStep = 0;
                  _errorMessage = null;
                });
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.coral),
              child: Text(
                _isRegisterMode
                    ? AppStrings.loginButton
                    : AppStrings.registerButton,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // -- Language picker --
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.language, color: AppColors.teal, size: 20),
            const SizedBox(width: 8),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLang,
                isDense: true,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 15,
                ),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedLang = v);
                    widget.localeNotifier.setLocale(v);
                  }
                },
                items: [
                  DropdownMenuItem(value: 'HR', child: Text(AppStrings.langHr)),
                  DropdownMenuItem(value: 'EN', child: Text(AppStrings.langEn)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ══════════════════════════════════════════════
  // STEP 1: Role picker (Customer ili Student)
  // ══════════════════════════════════════════════
  Widget _buildRolePickerStep(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 16),

        // -- Back arrow --
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => setState(() => _registerStep = 0),
            child: const Icon(Icons.arrow_back, size: 28),
          ),
        ),
        const SizedBox(height: 24),

        // -- Title --
        Text(
          AppStrings.chooseRoleTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.chooseRoleSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        // -- Customer card --
        _RoleCard(
          icon: Icons.favorite_outline,
          iconColor: AppColors.coral,
          title: AppStrings.roleCustomerTitle,
          description: AppStrings.roleCustomerDesc,
          onTap: () => setState(() => _registerStep = 2),
        ),
        const SizedBox(height: 16),

        // -- Student card --
        _RoleCard(
          icon: Icons.school_outlined,
          iconColor: AppColors.teal,
          title: AppStrings.roleStudentTitle,
          description: AppStrings.roleStudentDesc,
          onTap: () => widget.onStudentRegisterSuccess(
            _emailCtrl.text.trim(),
            _passwordCtrl.text,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ══════════════════════════════════════════════
  // STEP 2: Profile completion (Customer registration)
  // ══════════════════════════════════════════════
  Widget _buildProfileStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // -- Back arrow --
        GestureDetector(
          onTap: () => setState(() => _registerStep = 1),
          child: const Icon(Icons.arrow_back, size: 28),
        ),
        const SizedBox(height: 16),

        // -- Title --
        Center(
          child: Text(
            AppStrings.regProfileTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            AppStrings.regProfileSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // -- CUSTOMER DATA --
        HelpiSectionHeader(title: AppStrings.ordererData),
        const SizedBox(height: 12),
        HelpiTextField(
          label: AppStrings.firstName,
          controller: _ordFirstNameCtrl,
        ),
        const SizedBox(height: 12),
        HelpiTextField(
          label: AppStrings.lastName,
          controller: _ordLastNameCtrl,
        ),
        const SizedBox(height: 12),
        HelpiGenderPicker(
          value: _ordGender,
          onChanged: (v) => setState(() => _ordGender = v),
        ),
        const SizedBox(height: 12),
        HelpiDatePicker(
          label: AppStrings.dateOfBirth,
          date: _ordDob,
          onChanged: (d) => setState(() => _ordDob = d),
        ),
        const SizedBox(height: 12),
        HelpiTextField(
          label: AppStrings.phone,
          controller: _ordPhoneCtrl,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        McAddressField(
          controller: _senAddressCtrl,
          onAddressSelected: (info) {
            setState(() => _selectedAddress = info);
          },
        ),
        const SizedBox(height: 16),

        // -- "Ordering for someone else" toggle --
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.orderingForOther,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            HelpiSwitch(
              value: _orderingForOther,
              onChanged: (v) => setState(() => _orderingForOther = v),
            ),
          ],
        ),

        // -- USER DATA (SENIOR) --
        // Shown only when ordering for someone else
        if (_orderingForOther) ...[
          const SizedBox(height: 24),
          HelpiSectionHeader(title: AppStrings.seniorData),
          const SizedBox(height: 12),
          HelpiTextField(
            label: AppStrings.firstName,
            controller: _senFirstNameCtrl,
          ),
          const SizedBox(height: 12),
          HelpiTextField(
            label: AppStrings.lastName,
            controller: _senLastNameCtrl,
          ),
          const SizedBox(height: 12),
          HelpiGenderPicker(
            value: _senGender,
            onChanged: (v) => setState(() => _senGender = v),
          ),
          const SizedBox(height: 12),
          HelpiDatePicker(
            label: AppStrings.dateOfBirth,
            date: _senDob,
            onChanged: (d) => setState(() => _senDob = d),
          ),
          const SizedBox(height: 12),
          HelpiTextField(
            label: AppStrings.address,
            controller: _senAddressCtrl,
          ),
          const SizedBox(height: 12),
          HelpiTextField(
            label: AppStrings.phone,
            controller: _senPhoneCtrl,
            keyboardType: TextInputType.phone,
          ),
        ],
        const SizedBox(height: 32),

        // -- Error message --
        if (_errorMessage != null) ...[
          _buildErrorBanner(context),
          const SizedBox(height: 16),
        ],

        // -- CTA: Complete registration --
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleCustomerRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(AppStrings.completeRegistration),
          ),
        ),
        const SizedBox(height: 12),

        // -- Terms (text below button) --
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              children: [
                TextSpan(text: AppStrings.byClickingRegister),
                TextSpan(
                  text: AppStrings.termsOfUseLink,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.teal,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      launchUrl(
                        Uri.parse('https://helpi.social/pravila-privatnosti/'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ══════════════════════════════════════════════
  // HELPERS (matching profile_screen.dart style)
  // ══════════════════════════════════════════════

  Future<void> _handleRegisterNext() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = AppStrings.fillAllFields);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isServerError = false;
    });

    final exists = await _authService.checkEmailExists(email);

    if (!mounted) return;

    if (exists == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = AppStrings.serverUnavailableTitle;
        _isServerError = true;
      });
      return;
    }

    if (exists) {
      setState(() {
        _isLoading = false;
        _errorMessage = AppStrings.emailAlreadyExists;
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _registerStep = 1;
    });
  }

  Future<void> _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = AppStrings.loginError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isServerError = false;
    });

    final result = await _authService.login(email, password);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success) {
      widget.onLoginSuccess();
    } else {
      setState(() {
        _errorMessage = result.message;
        _isServerError = result.isConnectionError;
      });
    }
  }

  Future<void> _handleCustomerRegister() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final firstName = _ordFirstNameCtrl.text.trim();
    final lastName = _ordLastNameCtrl.text.trim();
    final phone = _ordPhoneCtrl.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        firstName.isEmpty ||
        lastName.isEmpty ||
        phone.isEmpty ||
        _selectedAddress == null ||
        _ordDob == null) {
      setState(() => _errorMessage = AppStrings.fillAllFields);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.registerCustomer(
      email: email,
      password: password,
      fullName: '$firstName $lastName',
      phone: phone,
      gender: _ordGender,
      dateOfBirth: _ordDob!,
      fullAddress: _selectedAddress!.fullAddress,
      cityId: 2,
      googlePlaceId: _selectedAddress!.placeId,
      lat: _selectedAddress!.lat,
      lng: _selectedAddress!.lng,
      orderingForOther: _orderingForOther,
      seniorFullName: _orderingForOther
          ? '${_senFirstNameCtrl.text.trim()} ${_senLastNameCtrl.text.trim()}'
          : null,
      seniorPhone: _orderingForOther ? _senPhoneCtrl.text.trim() : null,
      seniorGender: _orderingForOther ? _senGender : null,
      seniorDob: _orderingForOther ? _senDob : null,
      seniorAddress: _orderingForOther ? _senAddressCtrl.text.trim() : null,
    );

    if (!mounted) return;

    if (result.success) {
      // Auto-login after successful registration
      final loginResult = await _authService.login(email, password);
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (loginResult.success) {
        widget.onRegisterSuccess();
      } else {
        setState(() => _errorMessage = loginResult.message);
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.message;
      });
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const _ForgotPasswordDialog());
  }
}

// ══════════════════════════════════════════════
// Forgot Password Dialog (2-step: email -> code + new password)
// ══════════════════════════════════════════════
class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog();

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _authService = AuthService();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final result = await _authService.forgotPassword(email);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.success) {
        _codeSent = true;
        _message = AppStrings.codeSent;
        _isError = false;
      } else {
        _message = result.message;
        _isError = true;
      }
    });
  }

  Future<void> _resetPassword() async {
    final code = _codeCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;

    if (code.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) return;

    if (newPassword != confirmPassword) {
      setState(() {
        _message = AppStrings.loginError;
        _isError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final result = await _authService.resetPassword(
      _emailCtrl.text.trim(),
      code,
      newPassword,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.success) {
        _message = AppStrings.resetPasswordSuccess;
        _isError = false;
      } else {
        _message = result.message;
        _isError = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.forgotPasswordTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_codeSent) ...[
              Text(AppStrings.forgotPasswordSubtitle),
              const SizedBox(height: 16),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: AppStrings.loginEmail,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ] else ...[
              TextField(
                controller: _codeCtrl,
                decoration: InputDecoration(
                  labelText: AppStrings.resetCode,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPasswordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppStrings.newPassword,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppStrings.confirmNewPassword,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return Text(
                    _message!,
                    style: TextStyle(
                      color: _isError
                          ? (isDark ? Colors.red.shade300 : Colors.red.shade700)
                          : (isDark
                                ? Colors.green.shade300
                                : Colors.green.shade700),
                      fontSize: 13,
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.backToLogin),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          ElevatedButton(
            onPressed: _codeSent ? _resetPassword : _sendCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
            ),
            child: Text(
              _codeSent
                  ? AppStrings.resetPasswordButton
                  : AppStrings.sendResetCode,
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════
// Role picker card
// ══════════════════════════════════════════════
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: theme.colorScheme.onSurfaceVariant,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
