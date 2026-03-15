import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:helpi_app/app/theme.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/l10n/locale_notifier.dart';
import 'package:helpi_app/core/network/api_client.dart';
import 'package:helpi_app/core/network/api_endpoints.dart';
import 'package:helpi_app/core/services/auth_service.dart';
import 'package:helpi_app/features/schedule/data/availability_model.dart';
import 'package:helpi_app/shared/models/faculty.dart';
import 'package:helpi_app/features/schedule/utils/availability_helpers.dart';
import 'package:helpi_app/features/schedule/utils/formatters.dart';
import 'package:helpi_app/features/schedule/widgets/availability_day_row.dart';
import 'package:helpi_app/features/schedule/widgets/faculty_picker.dart';

/// Profil ekran â€” pristupni podaci, dostupnost, jezik, uvjeti, odjava.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.localeNotifier,
    required this.onLogout,
    required this.availabilityNotifier,
  });

  final LocaleNotifier localeNotifier;
  final VoidCallback onLogout;
  final AvailabilityNotifier availabilityNotifier;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // â”€â”€ Pristupni podaci â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final _emailCtrl = TextEditingController(text: 'ana.student@email.com');

  // â”€â”€ Osobni podaci studenta â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final _firstNameCtrl = TextEditingController(text: 'Ana');
  final _lastNameCtrl = TextEditingController(text: 'Horvat');
  final _phoneCtrl = TextEditingController(text: '+385 91 555 1234');
  final _addressCtrl = TextEditingController(text: 'Savska 25, Zagreb');
  Faculty? _selectedFaculty;
  final _studentIdCardCtrl = TextEditingController(text: '0036512345');
  String _gender = 'F';
  DateTime _dob = DateTime(2002, 5, 10);

  // â”€â”€ Ostalo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  late String _selectedLang = AppStrings.currentLocale.toUpperCase();
  bool _isEditing = false;
  bool _agreedToTerms = true;
  List<Faculty> _faculties = [];

  // â”€â”€ Dostupnost â€” Äita/piÅ¡e iz dijeljenog notifiera â”€â”€â”€â”€â”€
  List<DayAvailability> get _availability => widget.availabilityNotifier.value;
  final _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _loadFaculties();
  }

  Future<void> _loadFaculties() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.faculties);
      if (!mounted) return;
      final list = response.data as List<dynamic>;
      setState(() {
        _faculties = Faculty.fromJsonList(list, lang: AppStrings.currentLocale);
      });
    } catch (_) {
      // Faculties remain empty
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _studentIdCardCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime({
    required DayAvailability day,
    required bool isFrom,
  }) async {
    final changed = await pickAvailabilityTime(
      context: context,
      day: day,
      isFrom: isFrom,
    );
    if (changed) {
      setState(() {});
      widget.availabilityNotifier.notify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.profile)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // â”€â”€ PRISTUPNI PODACI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _sectionHeader(AppStrings.accessData),
          const SizedBox(height: 12),
          _buildField(
            AppStrings.email,
            _emailCtrl,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.lock_outline, size: 20),
            label: Text(AppStrings.changePassword),
          ),
          const SizedBox(height: 32),

          // â”€â”€ OSOBNI PODACI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _sectionHeader(AppStrings.studentData),
          const SizedBox(height: 12),
          _buildField(AppStrings.firstName, _firstNameCtrl),
          const SizedBox(height: 12),
          _buildField(AppStrings.lastName, _lastNameCtrl),
          const SizedBox(height: 12),
          _buildGenderPicker(_gender, (v) => setState(() => _gender = v)),
          const SizedBox(height: 12),
          _buildDatePicker(
            AppStrings.dateOfBirth,
            _dob,
            (d) => setState(() => _dob = d),
          ),
          const SizedBox(height: 12),
          _buildField(
            AppStrings.phone,
            _phoneCtrl,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _buildField(AppStrings.address, _addressCtrl),
          const SizedBox(height: 12),
          _buildFacultyField(),
          const SizedBox(height: 12),
          _buildField(AppStrings.studentIdCard, _studentIdCardCtrl),
          const SizedBox(height: 32),

          // â”€â”€ DOSTUPNOST â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _sectionHeader(AppStrings.availabilitySection),
          const SizedBox(height: 4),
          Text(
            AppStrings.availabilityDescription,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          ..._availability.map(
            (day) => AvailabilityDayRow(
              day: day,
              enabled: _isEditing,
              onEnabledChanged: (v) {
                setState(() => day.enabled = v);
                widget.availabilityNotifier.notify();
              },
              onPickFrom: () => _pickTime(day: day, isFrom: true),
              onPickTo: () => _pickTime(day: day, isFrom: false),
            ),
          ),
          const SizedBox(height: 8),

          // â”€â”€ UVJETI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

          // â”€â”€ UREDI / SPREMI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

          // â”€â”€ JEZIK â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                    child: Text(AppStrings.langHrvatski),
                  ),
                  DropdownMenuItem(
                    value: 'EN',
                    child: Text(AppStrings.langEnglish),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // â”€â”€ ODJAVA â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          OutlinedButton.icon(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
            label: Text(AppStrings.logout),
            style: HelpiTheme.coralOutlinedStyle,
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

          // â”€â”€ Verzija â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  Widget _sectionHeader(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: _isEditing,
      style: TextStyle(
        color: _isEditing
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withAlpha(153),
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: theme.colorScheme.onSurface.withAlpha(_isEditing ? 180 : 153),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: HelpiTheme.border),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildGenderPicker(String value, ValueChanged<String> onChanged) {
    final theme = Theme.of(context);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: AppStrings.gender,
        labelStyle: TextStyle(
          color: theme.colorScheme.onSurface.withAlpha(_isEditing ? 180 : 153),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: HelpiTheme.border),
        ),
        enabled: _isEditing,
        filled: true,
        fillColor: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          isExpanded: true,
          onChanged: _isEditing
              ? (v) {
                  if (v != null) onChanged(v);
                }
              : null,
          style: TextStyle(
            color: _isEditing
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withAlpha(153),
            fontSize: 16,
          ),
          items: [
            DropdownMenuItem(value: 'M', child: Text(AppStrings.genderMale)),
            DropdownMenuItem(value: 'F', child: Text(AppStrings.genderFemale)),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime date,
    ValueChanged<DateTime> onChanged,
  ) {
    final theme = Theme.of(context);
    final formatted = Formatters.formatDateFull(date);

    return GestureDetector(
      onTap: _isEditing
          ? () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(1920),
                lastDate: DateTime.now(),
              );
              if (picked != null && context.mounted) {
                onChanged(picked);
              }
            }
          : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: theme.colorScheme.onSurface.withAlpha(
              _isEditing ? 180 : 153,
            ),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: _isEditing
                  ? theme.colorScheme.onSurface.withAlpha(100)
                  : HelpiTheme.border,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: _isEditing
              ? Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: theme.colorScheme.secondary,
                )
              : null,
        ),
        child: Text(
          formatted,
          style: TextStyle(
            color: _isEditing
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withAlpha(153),
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildFacultyField() {
    final theme = Theme.of(context);
    final hasFaculty = _selectedFaculty != null;

    return GestureDetector(
      onTap: _isEditing
          ? () async {
              final picked = await showFacultyPicker(
                context: context,
                faculties: _faculties,
                current: _selectedFaculty,
              );
              if (picked != null && context.mounted) {
                setState(() => _selectedFaculty = picked);
              }
            }
          : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: AppStrings.faculty,
          labelStyle: TextStyle(
            color: theme.colorScheme.onSurface.withAlpha(
              _isEditing ? 180 : 153,
            ),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: HelpiTheme.border),
          ),
          enabled: _isEditing,
          filled: true,
          fillColor: Colors.white,
          suffixIcon: _isEditing
              ? Icon(Icons.arrow_drop_down, color: theme.colorScheme.secondary)
              : null,
        ),
        child: hasFaculty
            ? Text(
                _selectedFaculty!.name,
                style: TextStyle(
                  color: _isEditing
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withAlpha(153),
                  fontSize: 16,
                ),
              )
            : Text(
                AppStrings.facultyHint,
                style: TextStyle(color: HelpiTheme.textSecondary, fontSize: 16),
              ),
      ),
    );
  }
}
