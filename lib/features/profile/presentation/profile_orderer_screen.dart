import 'package:flutter/material.dart';

import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/services/app_api_service.dart';
import 'package:helpi_app/shared/widgets/helpi_form_fields.dart';

/// Sub-screen: orderer (customer/naručitelj) personal data with auto-save.
class ProfileOrdererScreen extends StatefulWidget {
  const ProfileOrdererScreen({super.key, this.profileData});

  final Map<String, dynamic>? profileData;

  @override
  State<ProfileOrdererScreen> createState() => _ProfileOrdererScreenState();
}

class _ProfileOrdererScreenState extends State<ProfileOrdererScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _gender = 'M';
  DateTime _dob = DateTime(1985, 1, 1);

  int? _contactId;
  String _email = '';
  String _fullAddress = '';
  String _googlePlaceId = 'app-manual-entry';
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final contact =
        widget.profileData?['contact'] as Map<String, dynamic>? ?? {};
    _contactId = (contact['id'] as num?)?.toInt();
    _email = contact['email'] as String? ?? '';
    _fullAddress = contact['fullAddress'] as String? ?? '';
    _googlePlaceId = contact['googlePlaceId'] as String? ?? 'app-manual-entry';
    // If address was never set, use a placeholder so backend validator passes
    if (_fullAddress.isEmpty) _fullAddress = '-';

    final fullName = contact['fullName'] as String? ?? '';
    final parts = fullName.split(' ');
    _firstNameCtrl.text = parts.isNotEmpty ? parts.first : '';
    _lastNameCtrl.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    _phoneCtrl.text = contact['phone'] as String? ?? '';

    final genderVal = contact['gender'];
    _gender = (genderVal == 0 || genderVal == 'Male') ? 'M' : 'F';

    final dobStr = contact['dateOfBirth'] as String?;
    if (dobStr != null) {
      _dob = DateTime.tryParse(dobStr) ?? _dob;
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
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
      fullAddress: _fullAddress,
      gender: _gender == 'M' ? 0 : 1,
      dateOfBirth: fmtDate,
      googlePlaceId: _googlePlaceId,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

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
        title: Text(AppStrings.ordererData),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_isEditing)
            IconButton(
              onPressed: () async {
                await _save();
                if (!mounted) return;
                setState(() => _isEditing = false);
              },
              icon: const Icon(Icons.check),
              tooltip: AppStrings.save,
            )
          else
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined),
              tooltip: AppStrings.editProfile,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
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
        ],
      ),
    );
  }
}
