import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:helpi_app/core/constants/colors.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/l10n/locale_notifier.dart';
import 'package:helpi_app/core/services/app_api_service.dart';
import 'package:helpi_app/core/services/auth_service.dart';
import 'package:helpi_app/core/network/token_storage.dart';
import 'package:helpi_app/features/notifications/presentation/notifications_screen.dart';
import 'package:helpi_app/shared/widgets/helpi_form_fields.dart';

/// Profile screen - credentials, customer, senior, cards, terms.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.localeNotifier,
    required this.onLogout,
  });

  final LocaleNotifier localeNotifier;
  final VoidCallback onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _dummyCardBrands = ['Visa', 'Mastercard', 'Maestro'];

  // -- Access credentials --
  final _emailCtrl = TextEditingController();

  // -- Customer --
  final _ordFirstNameCtrl = TextEditingController();
  final _ordLastNameCtrl = TextEditingController();
  final _ordPhoneCtrl = TextEditingController();
  String _ordGender = 'M';
  DateTime _ordDob = DateTime(1985, 1, 1);

  // -- Senior / user --
  final _senFirstNameCtrl = TextEditingController();
  final _senLastNameCtrl = TextEditingController();
  final _senPhoneCtrl = TextEditingController();
  final _senAddressCtrl = TextEditingController();
  String _senGender = 'F';
  DateTime _senDob = DateTime(1950, 1, 1);

  // -- Other --
  late String _selectedLang = AppStrings.currentLocale.toUpperCase();
  bool _isEditing = false;
  bool _agreedToTerms = true;
  bool _isLoading = true;
  bool _isSavingCard = false;

  // Cards from API
  List<Map<String, dynamic>> _cards = [];

  // Contact IDs for saving
  int? _customerContactId;
  int? _seniorContactId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = await TokenStorage().getUserId();
    if (userId == null || !mounted) return;

    final api = AppApiService();
    final result = await api.getCustomerProfile(userId);
    if (!mounted) return;

    if (result.success && result.data != null) {
      final data = result.data!;
      final contact = data['contact'] as Map<String, dynamic>? ?? {};
      final seniors = data['seniors'] as List<dynamic>? ?? [];

      // Store contact ID for saving
      _customerContactId = (contact['id'] as num?)?.toInt();

      // Customer (customer contact)
      _emailCtrl.text = contact['email'] as String? ?? '';
      final fullName = contact['fullName'] as String? ?? '';
      final nameParts = fullName.split(' ');
      _ordFirstNameCtrl.text = nameParts.isNotEmpty ? nameParts.first : '';
      _ordLastNameCtrl.text = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';
      _ordPhoneCtrl.text = contact['phone'] as String? ?? '';
      final genderVal = contact['gender'];
      _ordGender = (genderVal == 0 || genderVal == 'Male') ? 'M' : 'F';
      final dobStr = contact['dateOfBirth'] as String?;
      if (dobStr != null) {
        _ordDob = DateTime.tryParse(dobStr) ?? _ordDob;
      }

      // Senior (prvi iz liste)
      if (seniors.isNotEmpty) {
        final senior = seniors[0] as Map<String, dynamic>;
        final senContact = senior['contact'] as Map<String, dynamic>? ?? {};

        // Store senior contact ID
        _seniorContactId = (senContact['id'] as num?)?.toInt();

        final senFullName = senContact['fullName'] as String? ?? '';
        final senNameParts = senFullName.split(' ');
        _senFirstNameCtrl.text = senNameParts.isNotEmpty
            ? senNameParts.first
            : '';
        _senLastNameCtrl.text = senNameParts.length > 1
            ? senNameParts.sublist(1).join(' ')
            : '';
        _senPhoneCtrl.text = senContact['phone'] as String? ?? '';
        _senAddressCtrl.text = senContact['fullAddress'] as String? ?? '';
        final senGenderVal = senContact['gender'];
        _senGender = (senGenderVal == 0 || senGenderVal == 'Male') ? 'M' : 'F';
        final senDobStr = senContact['dateOfBirth'] as String?;
        if (senDobStr != null) {
          _senDob = DateTime.tryParse(senDobStr) ?? _senDob;
        }
      }
    }

    // Cards
    final cardsResult = await api.getPaymentMethods(userId);
    if (!mounted) return;
    if (cardsResult.success && cardsResult.data != null) {
      _cards = cardsResult.data!;
    }

    setState(() => _isLoading = false);
  }

  Future<void> _addDummyCard() async {
    final userId = await TokenStorage().getUserId();
    if (userId == null) return;

    final nextIndex = _cards.length;
    final brand = _dummyCardBrands[nextIndex % _dummyCardBrands.length];
    final last4 = (4242 + nextIndex).toString().padLeft(4, '0');

    setState(() => _isSavingCard = true);

    final result = await AppApiService().createPaymentMethod({
      'userId': userId,
      'processor': 0,
      'brand': brand,
      'last4': last4.substring(last4.length - 4),
      'isDefault': _cards.isEmpty,
    });

    if (!mounted) return;

    setState(() {
      _isSavingCard = false;
      if (result.success && result.data != null) {
        _cards = [..._cards, result.data!];
      }
    });

    if (!result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.error ?? AppStrings.error)));
    }
  }

  Future<void> _deleteCard(Map<String, dynamic> card) async {
    final cardId = (card['id'] as num?)?.toInt();
    if (cardId == null) {
      return;
    }

    final result = await AppApiService().deletePaymentMethod(cardId);
    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.error ?? AppStrings.error)));
      return;
    }

    setState(() {
      _cards = _cards.where((item) => item['id'] != card['id']).toList();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _ordFirstNameCtrl.dispose();
    _ordLastNameCtrl.dispose();
    _ordPhoneCtrl.dispose();
    _senFirstNameCtrl.dispose();
    _senLastNameCtrl.dispose();
    _senPhoneCtrl.dispose();
    _senAddressCtrl.dispose();
    super.dispose();
  }

  /// Save profile data to backend.
  Future<void> _saveProfile() async {
    final api = AppApiService();
    bool hasError = false;

    // Format date helper
    String fmtDate(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    // Update Customer contact info
    if (_customerContactId != null) {
      final customerFullName =
          '${_ordFirstNameCtrl.text.trim()} ${_ordLastNameCtrl.text.trim()}';
      final result = await api.updateContactInfo(
        contactId: _customerContactId!,
        fullName: customerFullName,
        email: _emailCtrl.text.trim(),
        phone: _ordPhoneCtrl.text.trim(),
        fullAddress: '', // Customer uses senior's address
        gender: _ordGender == 'M' ? 0 : 1,
        dateOfBirth: fmtDate(_ordDob),
      );
      if (!result.success) hasError = true;
    }

    // Update Senior contact info
    if (_seniorContactId != null) {
      final seniorFullName =
          '${_senFirstNameCtrl.text.trim()} ${_senLastNameCtrl.text.trim()}';
      final result = await api.updateContactInfo(
        contactId: _seniorContactId!,
        fullName: seniorFullName,
        email: _emailCtrl.text.trim(),
        phone: _senPhoneCtrl.text.trim(),
        fullAddress: _senAddressCtrl.text.trim(),
        gender: _senGender == 'M' ? 0 : 1,
        dateOfBirth: fmtDate(_senDob),
      );
      if (!result.success) hasError = true;
    }

    if (!mounted) return;

    if (hasError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.error)));
    }
  }

  /// Prikaži dijalog za promjenu lozinke.
  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _ChangePasswordDialog(authService: AuthService()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.profile),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
            tooltip: AppStrings.notificationsTitle,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // -- ACCESS CREDENTIALS --
                HelpiSectionHeader(title: AppStrings.accessData),
                const SizedBox(height: 12),
                HelpiTextField(
                  label: AppStrings.email,
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 12),
                // Promijeni lozinku
                OutlinedButton.icon(
                  onPressed: _showChangePasswordDialog,
                  icon: const Icon(Icons.lock_outline, size: 20),
                  label: Text(AppStrings.changePassword),
                ),
                const SizedBox(height: 32),

                // -- CUSTOMER DATA --
                HelpiSectionHeader(title: AppStrings.ordererData),
                const SizedBox(height: 12),
                HelpiTextField(
                  label: AppStrings.firstName,
                  controller: _ordFirstNameCtrl,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 12),
                HelpiTextField(
                  label: AppStrings.lastName,
                  controller: _ordLastNameCtrl,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 12),
                HelpiGenderPicker(
                  value: _ordGender,
                  onChanged: (v) => setState(() => _ordGender = v),
                  enabled: _isEditing,
                ),
                const SizedBox(height: 12),
                HelpiDatePicker(
                  label: AppStrings.dateOfBirth,
                  date: _ordDob,
                  onChanged: (d) => setState(() => _ordDob = d),
                  enabled: _isEditing,
                ),
                const SizedBox(height: 12),
                HelpiTextField(
                  label: AppStrings.phone,
                  controller: _ordPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 32),

                // -- USER DATA (SENIOR) --
                HelpiSectionHeader(title: AppStrings.seniorData),
                const SizedBox(height: 12),
                HelpiTextField(
                  label: AppStrings.firstName,
                  controller: _senFirstNameCtrl,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 12),
                HelpiTextField(
                  label: AppStrings.lastName,
                  controller: _senLastNameCtrl,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 12),
                HelpiGenderPicker(
                  value: _senGender,
                  onChanged: (v) => setState(() => _senGender = v),
                  enabled: _isEditing,
                ),
                const SizedBox(height: 12),
                HelpiDatePicker(
                  label: AppStrings.dateOfBirth,
                  date: _senDob,
                  onChanged: (d) => setState(() => _senDob = d),
                  enabled: _isEditing,
                ),
                const SizedBox(height: 12),
                HelpiTextField(
                  label: AppStrings.address,
                  controller: _senAddressCtrl,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 12),
                HelpiTextField(
                  label: AppStrings.phone,
                  controller: _senPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 32),

                // -- CREDIT CARDS --
                HelpiSectionHeader(title: AppStrings.creditCards),
                const SizedBox(height: 12),
                if (_cards.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        AppStrings.noCards,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withAlpha(153),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                else
                  ..._cards.map((card) {
                    final brand = card['brand'] as String? ?? '';
                    final last4 = card['last4'] as String? ?? '****';
                    final display = brand.isNotEmpty
                        ? '$brand **** $last4'
                        : '**** $last4';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabled: _isEditing,
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(
                            Icons.credit_card,
                            color: theme.colorScheme.secondary,
                          ),
                          suffixIcon: _isEditing
                              ? GestureDetector(
                                  onTap: () => _deleteCard(card),
                                  child: Icon(
                                    Icons.delete_outline,
                                    color: theme.colorScheme.error,
                                    size: 22,
                                  ),
                                )
                              : null,
                        ),
                        child: Text(
                          display,
                          style: TextStyle(
                            color: _isEditing
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withAlpha(153),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }),
                if (_isEditing) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _isSavingCard ? null : _addDummyCard,
                    icon: _isSavingCard
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add, size: 20),
                    label: Text(AppStrings.addCard),
                  ),
                ],
                const SizedBox(height: 8),

                // -- TERMS --
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: _isEditing
                          ? (v) => setState(() => _agreedToTerms = v ?? false)
                          : null,
                      activeColor: theme.colorScheme.secondary,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          launchUrl(
                            Uri.parse(
                              'https://helpi.social/pravila-privatnosti/',
                            ),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodyMedium,
                            children: [
                              TextSpan(text: AppStrings.agreeToTerms),
                              TextSpan(
                                text: AppStrings.termsOfUse,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.secondary,
                                  decorationColor: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // -- EDIT / SAVE --
                SizedBox(
                  width: double.infinity,
                  child: _isEditing
                      ? Column(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                await _saveProfile();
                                if (!mounted) return;
                                setState(() => _isEditing = false);
                              },
                              child: Text(AppStrings.save),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _isEditing = false),
                              child: Text(AppStrings.cancel),
                            ),
                          ],
                        )
                      : OutlinedButton.icon(
                          onPressed: () => setState(() => _isEditing = true),
                          icon: const Icon(Icons.edit, size: 20),
                          label: Text(AppStrings.editProfile),
                        ),
                ),
                const SizedBox(height: 32),

                // -- LANGUAGE --
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: AppStrings.language,
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withAlpha(180),
                    ),
                    prefixIcon: Icon(
                      Icons.language,
                      color: theme.colorScheme.secondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLang,
                      isDense: true,
                      isExpanded: true,
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _selectedLang = v);
                          widget.localeNotifier.setLocale(v);
                        }
                      },
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'HR',
                          child: Text(AppStrings.langHr),
                        ),
                        DropdownMenuItem(
                          value: 'EN',
                          child: Text(AppStrings.langEn),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // -- LOGOUT --
                OutlinedButton.icon(
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout),
                  label: Text(AppStrings.logout),
                  style: AppColors.coralOutlinedStyle,
                ),
                const SizedBox(height: 16),

                // -- DELETE ACCOUNT --
                TextButton(
                  onPressed: () => _showDeleteAccountDialog(context),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  child: Text(
                    AppStrings.deleteAccount,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 32),

                // -- Version --
                Center(
                  child: Text(
                    AppStrings.appVersion,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.deleteAccountConfirmTitle),
        content: Text(AppStrings.deleteAccountConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.deleteAccountNo),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(AppStrings.deleteAccountYes),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (confirmed != true) return;

    final result = await AuthService().deleteAccount();
    if (!context.mounted) return;

    if (result.success) {
      widget.onLogout();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? AppStrings.deleteAccountError),
        ),
      );
    }
  }
}

// ══════════════════════════════════════════════
// Change Password Dialog
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

    // Close after success
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
