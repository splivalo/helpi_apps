import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:helpi_app/core/constants/colors.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/l10n/locale_notifier.dart';
import 'package:helpi_app/core/services/auth_service.dart';
import 'package:helpi_app/shared/widgets/helpi_form_fields.dart';

/// Profil ekran — pristupni podaci, naručitelj, senior, kartice, uvjeti.
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
  // ── Pristupni podaci ──────────────────────────
  final _emailCtrl = TextEditingController(text: 'marija.novak@email.com');

  // ── Naručitelj ────────────────────────────────
  final _ordFirstNameCtrl = TextEditingController(text: 'Ivan');
  final _ordLastNameCtrl = TextEditingController(text: 'Novak');
  final _ordPhoneCtrl = TextEditingController(text: '+385 91 234 5678');
  String _ordGender = 'M';
  DateTime _ordDob = DateTime(1985, 3, 15);

  // ── Senior / korisnik ─────────────────────────
  final _senFirstNameCtrl = TextEditingController(text: 'Marija');
  final _senLastNameCtrl = TextEditingController(text: 'Novak');
  final _senPhoneCtrl = TextEditingController(text: '+385 91 987 6543');
  final _senAddressCtrl = TextEditingController(text: 'Ilica 42, Zagreb');
  String _senGender = 'F';
  DateTime _senDob = DateTime(1948, 7, 22);

  // ── Ostalo ────────────────────────────────────
  late String _selectedLang = AppStrings.currentLocale.toUpperCase();
  bool _isEditing = false;
  bool _agreedToTerms = true;

  // Mock kartice
  final List<String> _cards = ['**** 4821', '**** 9037'];

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.profile)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── PRISTUPNI PODACI ────────────────────────
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
            onPressed: () {},
            icon: const Icon(Icons.lock_outline, size: 20),
            label: Text(AppStrings.changePassword),
          ),
          const SizedBox(height: 32),

          // ── PODACI O NARUČITELJU ────────────────────
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

          // ── PODACI O KORISNIKU (SENIOR) ─────────────
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

          // ── KREDITNE KARTICE ────────────────────────
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
            ..._cards.map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.border),
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
                            onTap: () {
                              setState(() => _cards.remove(card));
                            },
                            child: Icon(
                              Icons.delete_outline,
                              color: theme.colorScheme.error,
                              size: 22,
                            ),
                          )
                        : null,
                  ),
                  child: Text(
                    card,
                    style: TextStyle(
                      color: _isEditing
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withAlpha(153),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          if (_isEditing) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 20),
              label: Text(AppStrings.addCard),
            ),
          ],
          const SizedBox(height: 8),

          // ── UVJETI ──────────────────────────────────
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
                      Uri.parse('https://helpi.social/pravila-privatnosti/'),
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

          // ── UREDI / SPREMI ──────────────────────────
          SizedBox(
            width: double.infinity,
            child: _isEditing
                ? Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => setState(() => _isEditing = false),
                        child: Text(AppStrings.save),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() => _isEditing = false),
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

          // ── JEZIK ───────────────────────────────────
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
                  DropdownMenuItem(value: 'HR', child: Text(AppStrings.langHr)),
                  DropdownMenuItem(value: 'EN', child: Text(AppStrings.langEn)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── ODJAVA ──────────────────────────────────
          OutlinedButton.icon(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
            label: Text(AppStrings.logout),
            style: AppColors.coralOutlinedStyle,
          ),
          const SizedBox(height: 16),

          // ── IZBRIŠI RAČUN ───────────────────────────
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

          // ── Verzija ─────────────────────────────────
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
