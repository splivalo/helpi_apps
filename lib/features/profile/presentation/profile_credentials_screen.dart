import 'package:flutter/material.dart';

import 'package:helpi_app/core/constants/colors.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/services/auth_service.dart';
import 'package:helpi_app/shared/widgets/helpi_form_fields.dart';

/// Sub-screen: email (read-only) + change password.
class ProfileCredentialsScreen extends StatefulWidget {
  const ProfileCredentialsScreen({super.key, this.profileData});

  final Map<String, dynamic>? profileData;

  @override
  State<ProfileCredentialsScreen> createState() =>
      _ProfileCredentialsScreenState();
}

class _ProfileCredentialsScreenState extends State<ProfileCredentialsScreen> {
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final contact =
        widget.profileData?['contact'] as Map<String, dynamic>? ?? {};
    _emailCtrl.text = contact['email'] as String? ?? '';
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _ChangePasswordDialog(authService: AuthService()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.accessData)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          HelpiTextField(
            label: AppStrings.email,
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            enabled: false,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _showChangePasswordDialog,
            icon: const Icon(Icons.lock_outline, size: 20),
            label: Text(AppStrings.changePassword),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// Change Password Dialog (moved from old profile)
// ══════════════════════════════════════════════
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.authService});

  final AuthService authService;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentCtrl.text;
    final newPass = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      setState(() {
        _message = AppStrings.fillAllFields;
        _isError = true;
      });
      return;
    }

    if (newPass != confirm) {
      setState(() {
        _message = AppStrings.passwordsMismatch;
        _isError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final result = await widget.authService.changePassword(
      current,
      newPass,
      confirm,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.success) {
        _message = AppStrings.resetPasswordSuccess;
        _isError = false;
      } else {
        _message = result.message ?? AppStrings.error;
        _isError = true;
      }
    });

    if (result.success) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.changePassword),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: AppStrings.currentPassword,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newCtrl,
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
              controller: _confirmCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: AppStrings.confirmNewPassword,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(
                _message!,
                style: TextStyle(
                  color: _isError ? Colors.red : Colors.green,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.cancel),
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
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
            ),
            child: Text(AppStrings.save),
          ),
      ],
    );
  }
}
