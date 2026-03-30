import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:helpi_app/app/theme.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/l10n/locale_notifier.dart';
import 'package:helpi_app/core/network/api_client.dart';
import 'package:helpi_app/core/network/api_endpoints.dart';
import 'package:helpi_app/core/network/token_storage.dart';
import 'package:helpi_app/core/services/app_api_service.dart';
import 'package:helpi_app/core/services/auth_service.dart';
import 'package:helpi_app/features/schedule/data/availability_model.dart';
import 'package:helpi_app/shared/models/faculty.dart';
import 'package:helpi_app/features/schedule/utils/availability_helpers.dart';
import 'package:helpi_app/features/schedule/utils/formatters.dart';
import 'package:helpi_app/features/schedule/widgets/availability_day_row.dart';
import 'package:helpi_app/features/schedule/widgets/faculty_picker.dart';

/// Profile screen - credentials, availability, language, terms, logout.
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
  // -- Access credentials --
  final _emailCtrl = TextEditingController();

  // -- Student personal data --
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  Faculty? _selectedFaculty;
  String _gender = 'F';
  DateTime _dob = DateTime(2002, 1, 1);

  // -- Other --
  late String _selectedLang = AppStrings.currentLocale.toUpperCase();
  bool _isEditing = false;
  bool _agreedToTerms = true;
  bool _isLoading = true;
  List<Faculty> _faculties = [];
  // Contact ID for saving
  int? _contactId;
  int? _studentUserId;
  // -- Availability - reads/writes from shared notifier --
  List<DayAvailability> get _availability => widget.availabilityNotifier.value;
  final _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = await TokenStorage().getUserId();
    _studentUserId = userId;
    await Future.wait([
      _loadFaculties(),
      if (userId != null) _loadStudentData(userId),
    ]);
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _loadStudentData(int userId) async {
    final api = AppApiService();
    final result = await api.getStudentProfile(userId);
    if (!mounted) return;

    if (result.success && result.data != null) {
      final data = result.data!;
      final contact = data['contact'] as Map<String, dynamic>? ?? {};

      // Store contact ID for saving
      _contactId = (contact['id'] as num?)?.toInt();

      _emailCtrl.text = contact['email'] as String? ?? '';
      final fullName = contact['fullName'] as String? ?? '';
      final nameParts = fullName.split(' ');
      _firstNameCtrl.text = nameParts.isNotEmpty ? nameParts.first : '';
      _lastNameCtrl.text = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';
      _phoneCtrl.text = contact['phone'] as String? ?? '';
      _addressCtrl.text = contact['fullAddress'] as String? ?? '';
      final genderVal = contact['gender'];
      _gender = (genderVal == 0 || genderVal == 'Male') ? 'M' : 'F';
      final dobStr = contact['dateOfBirth'] as String?;
      if (dobStr != null) {
        _dob = DateTime.tryParse(dobStr) ?? _dob;
      }

      final facultyId = (data['facultyId'] as num?)?.toInt();
      if (facultyId != null && _faculties.isNotEmpty) {
        final match = _faculties.where((f) => f.id == facultyId);
        if (match.isNotEmpty) {
          _selectedFaculty = match.first;
        }
      }
    }
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

  /// Save availability to backend.
  Future<void> _saveAvailability() async {
    final storage = TokenStorage();
    final userId = await storage.getUserId();
    if (userId == null) return;

    final api = AppApiService();
    final payload = widget.availabilityNotifier.toBackendPayload(userId);
    final result = await api.updateStudentAvailability(payload);

    if (!mounted) return;

    if (result.success) {
      debugPrint('[ProfileScreen] availability saved: ${payload.length} slots');
    } else {
      debugPrint('[ProfileScreen] availability save failed: ${result.error}');
      // Optional: prikaži grešku
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Failed to save availability')),
      );
    }
  }

  /// Save personal data to backend.
  Future<void> _savePersonalData() async {
    if (_contactId == null) return;

    final api = AppApiService();

    // Format date helper
    String fmtDate(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final fullName =
        '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}';
    final result = await api.updateContactInfo(
      contactId: _contactId!,
      fullName: fullName,
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      fullAddress: _addressCtrl.text.trim(),
      gender: _gender == 'M' ? 0 : 1,
      dateOfBirth: fmtDate(_dob),
    );

    if (!mounted) return;

    if (result.success) {
      // Also update student-specific fields (faculty, student number)
      if (_studentUserId != null) {
        await api.updateStudent(
          studentId: _studentUserId!,
          facultyId: _selectedFaculty?.id,
        );
      }
      if (!mounted) return;
      debugPrint('[ProfileScreen] personal data saved');
    } else {
      debugPrint('[ProfileScreen] personal data save failed: ${result.error}');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.error ?? AppStrings.error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.profile)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // -- ACCESS CREDENTIALS --
                _sectionHeader(AppStrings.accessData),
                const SizedBox(height: 12),
                _buildField(
                  AppStrings.email,
                  _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) =>
                          _ChangePasswordDialog(authService: AuthService()),
                    );
                  },
                  icon: const Icon(Icons.lock_outline, size: 20),
                  label: Text(AppStrings.changePassword),
                ),
                const SizedBox(height: 32),

                // -- PERSONAL DATA --
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
                const SizedBox(height: 32),

                // -- AVAILABILITY --
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
                                await Future.wait([
                                  _saveAvailability(),
                                  _savePersonalData(),
                                ]);
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

                // -- LOGOUT --
                OutlinedButton.icon(
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout),
                  label: Text(AppStrings.logout),
                  style: HelpiTheme.coralOutlinedStyle,
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
                _selectedFaculty!.abbreviation.isNotEmpty
                    ? '${_selectedFaculty!.abbreviation} — ${_selectedFaculty!.name}'
                    : _selectedFaculty!.name,
                style: TextStyle(
                  color: _isEditing
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withAlpha(153),
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : Text(
                AppStrings.facultyHint,
                style: TextStyle(color: HelpiTheme.textSecondary, fontSize: 16),
              ),
      ),
    );
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
              backgroundColor: HelpiTheme.teal,
              foregroundColor: Colors.white,
            ),
            child: Text(AppStrings.save),
          ),
      ],
    );
  }
}
