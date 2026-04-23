import 'package:flutter/material.dart';

import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/network/api_client.dart';
import 'package:helpi_app/core/network/api_endpoints.dart';
import 'package:helpi_app/core/services/app_api_service.dart';
import 'package:helpi_app/shared/models/faculty.dart';
import 'package:helpi_app/shared/widgets/helpi_form_fields.dart';
import 'package:helpi_app/features/schedule/widgets/faculty_picker.dart';

/// Sub-screen: student personal data (name, phone, address, gender, DOB, faculty).
class ProfileStudentDataScreen extends StatefulWidget {
  const ProfileStudentDataScreen({
    super.key,
    this.profileData,
    this.studentUserId,
  });

  final Map<String, dynamic>? profileData;
  final int? studentUserId;

  @override
  State<ProfileStudentDataScreen> createState() =>
      _ProfileStudentDataScreenState();
}

class _ProfileStudentDataScreenState extends State<ProfileStudentDataScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  Faculty? _selectedFaculty;
  String _gender = 'F';
  DateTime _dob = DateTime(2002, 1, 1);

  String _email = '';
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isLoading = true;
  int? _contactId;
  List<Faculty> _faculties = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadFaculties();
    _populateFields();
    if (mounted) setState(() => _isLoading = false);
  }

  void _populateFields() {
    final data = widget.profileData;
    if (data == null) return;

    final contact = data['contact'] as Map<String, dynamic>? ?? {};
    _contactId = (contact['id'] as num?)?.toInt();
    _email = contact['email'] as String? ?? '';

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

  Future<void> _loadFaculties() async {
    try {
      final response = await ApiClient().get(ApiEndpoints.faculties);
      if (!mounted) return;
      final list = response.data as List<dynamic>;
      _faculties = Faculty.fromJsonList(list, lang: AppStrings.currentLocale);
    } catch (_) {
      // Faculties remain empty
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_contactId == null) return;
    setState(() => _isSaving = true);

    final api = AppApiService();

    String fmtDate(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final fullName =
        '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}';
    final result = await api.updateContactInfo(
      contactId: _contactId!,
      fullName: fullName,
      email: _email,
      phone: _phoneCtrl.text.trim(),
      fullAddress: _addressCtrl.text.trim(),
      gender: _gender == 'M' ? 0 : 1,
      dateOfBirth: fmtDate(_dob),
    );

    if (!mounted) return;

    if (result.success && widget.studentUserId != null) {
      await api.updateStudent(
        studentId: widget.studentUserId!,
        facultyId: _selectedFaculty?.id,
      );
      if (!mounted) return;
    }

    setState(() {
      _isSaving = false;
      if (result.success) _isEditing = false;
    });

    if (!result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.error ?? AppStrings.error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.studentData),
        actions: [
          if (!_isEditing && !_isLoading)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    children: [
                      HelpiTextField(
                        label: AppStrings.firstName,
                        controller: _firstNameCtrl,
                        enabled: _isEditing,
                      ),
                      const SizedBox(height: 16),
                      HelpiTextField(
                        label: AppStrings.lastName,
                        controller: _lastNameCtrl,
                        enabled: _isEditing,
                      ),
                      const SizedBox(height: 16),
                      HelpiGenderPicker(
                        value: _gender,
                        onChanged: (v) => setState(() => _gender = v),
                        enabled: _isEditing,
                      ),
                      const SizedBox(height: 16),
                      HelpiDatePicker(
                        label: AppStrings.dateOfBirth,
                        date: _dob,
                        onChanged: (d) => setState(() => _dob = d),
                        enabled: _isEditing,
                      ),
                      const SizedBox(height: 16),
                      HelpiTextField(
                        label: AppStrings.phone,
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        enabled: _isEditing,
                      ),
                      const SizedBox(height: 16),
                      HelpiTextField(
                        label: AppStrings.address,
                        controller: _addressCtrl,
                        enabled: _isEditing,
                      ),
                      const SizedBox(height: 16),
                      _buildFacultyField(theme),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                if (_isEditing)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: _isSaving ? null : _save,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(AppStrings.save),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () => setState(() => _isEditing = false),
                            child: Text(AppStrings.cancel),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildFacultyField(ThemeData theme) {
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
          enabled: _isEditing,
          filled: true,
          fillColor: theme.colorScheme.surface,
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
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
