import 'package:flutter/material.dart';

import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/services/app_api_service.dart';
import 'package:helpi_app/shared/widgets/helpi_form_fields.dart';

/// Sub-screen: senior (korisnik) personal data with auto-save.
class ProfileSeniorScreen extends StatefulWidget {
  const ProfileSeniorScreen({super.key, this.profileData});

  final Map<String, dynamic>? profileData;

  @override
  State<ProfileSeniorScreen> createState() => _ProfileSeniorScreenState();
}

class _ProfileSeniorScreenState extends State<ProfileSeniorScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _gender = 'F';
  DateTime _dob = DateTime(1950, 1, 1);

  int? _contactId;
  String _email = '';
  String _googlePlaceId = 'app-manual-entry';
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final seniors = widget.profileData?['seniors'] as List<dynamic>? ?? [];
    // Customer email for the save call
    final customerContact =
        widget.profileData?['contact'] as Map<String, dynamic>? ?? {};
    _email = customerContact['email'] as String? ?? '';

    if (seniors.isNotEmpty) {
      final senior = seniors[0] as Map<String, dynamic>;
      final contact = senior['contact'] as Map<String, dynamic>? ?? {};
      _contactId = (contact['id'] as num?)?.toInt();
      _googlePlaceId =
          contact['googlePlaceId'] as String? ?? 'app-manual-entry';

      final fullName = contact['fullName'] as String? ?? '';
      final parts = fullName.split(' ');
      _firstNameCtrl.text = parts.isNotEmpty ? parts.first : '';
      _lastNameCtrl.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      _phoneCtrl.text = contact['phone'] as String? ?? '';
      _addressCtrl.text = contact['fullAddress'] as String? ?? '';

      final genderVal = contact['gender'];
      _gender = (genderVal == 0 || genderVal == 'Male') ? 'M' : 'F';

      final dobStr = contact['dateOfBirth'] as String?;
      if (dobStr != null) {
        _dob = DateTime.tryParse(dobStr) ?? _dob;
      }
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

    final fullName =
        '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}';
    final fmtDate =
        '${_dob.year}-${_dob.month.toString().padLeft(2, '0')}-${_dob.day.toString().padLeft(2, '0')}';

    final result = await AppApiService().updateContactInfo(
      contactId: _contactId!,
      fullName: fullName,
      email: _email,
      phone: _phoneCtrl.text.trim(),
      fullAddress: _addressCtrl.text.trim().isEmpty
          ? '-'
          : _addressCtrl.text.trim(),
      gender: _gender == 'M' ? 0 : 1,
      dateOfBirth: fmtDate,
      googlePlaceId: _googlePlaceId,
    );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      if (result.success) _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? AppStrings.profileSaved
              : AppStrings.profileSaveError,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.seniorData),
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined),
              tooltip: AppStrings.editProfile,
            ),
        ],
      ),
      body: Column(
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
                  label: AppStrings.address,
                  controller: _addressCtrl,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 16),
                HelpiTextField(
                  label: AppStrings.phone,
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  enabled: _isEditing,
                ),
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
                              child: CircularProgressIndicator(strokeWidth: 2),
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
}
