import 'package:flutter/material.dart';

import 'package:helpi_app/app/theme.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/shared/models/faculty.dart';
import 'package:helpi_app/features/schedule/utils/formatters.dart';
import 'package:helpi_app/features/schedule/widgets/faculty_picker.dart';

/// Registracija — student upisuje osobne podatke prije postavljanja dostupnosti.
/// Gumb "Dalje" je disabled dok sva obavezna polja nisu popunjena.
class RegistrationDataScreen extends StatefulWidget {
  const RegistrationDataScreen({
    super.key,
    required this.onComplete,
    this.onBack,
  });

  final VoidCallback onComplete;
  final VoidCallback? onBack;

  @override
  State<RegistrationDataScreen> createState() => _RegistrationDataScreenState();
}

class _RegistrationDataScreenState extends State<RegistrationDataScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _studentIdCardCtrl = TextEditingController();

  String _gender = 'M';
  DateTime? _dob;
  Faculty? _selectedFaculty;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl.addListener(_onFieldChanged);
    _lastNameCtrl.addListener(_onFieldChanged);
    _phoneCtrl.addListener(_onFieldChanged);
    _addressCtrl.addListener(_onFieldChanged);
    _studentIdCardCtrl.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _studentIdCardCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed =>
      _firstNameCtrl.text.trim().isNotEmpty &&
      _lastNameCtrl.text.trim().isNotEmpty &&
      _phoneCtrl.text.trim().isNotEmpty &&
      _addressCtrl.text.trim().isNotEmpty &&
      _selectedFaculty != null &&
      _studentIdCardCtrl.text.trim().isNotEmpty &&
      _dob != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: HelpiTheme.offWhite,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // ── Back arrow ──
                    if (widget.onBack != null)
                      GestureDetector(
                        onTap: widget.onBack,
                        child: const Icon(Icons.arrow_back, size: 28),
                      ),
                    const SizedBox(height: 24),

                    // ── Title ──
                    Text(
                      AppStrings.registrationDataTitle,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.registrationDataSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: HelpiTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Ime ──
                    _buildField(
                      label: AppStrings.firstName,
                      controller: _firstNameCtrl,
                      theme: theme,
                    ),
                    const SizedBox(height: 12),

                    // ── Prezime ──
                    _buildField(
                      label: AppStrings.lastName,
                      controller: _lastNameCtrl,
                      theme: theme,
                    ),
                    const SizedBox(height: 12),

                    // ── Spol ──
                    _buildGenderPicker(theme),
                    const SizedBox(height: 12),

                    // ── Datum rođenja ──
                    _buildDatePicker(theme),
                    const SizedBox(height: 12),

                    // ── Telefon ──
                    _buildField(
                      label: AppStrings.phone,
                      controller: _phoneCtrl,
                      theme: theme,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),

                    // ── Adresa ──
                    _buildField(
                      label: AppStrings.address,
                      controller: _addressCtrl,
                      theme: theme,
                    ),
                    const SizedBox(height: 12),

                    // ── Fakultet ──
                    _buildFacultyPicker(theme),
                    const SizedBox(height: 12),

                    // ── Broj studentske iskaznice ──
                    _buildField(
                      label: AppStrings.studentIdCard,
                      controller: _studentIdCardCtrl,
                      theme: theme,
                      hint: AppStrings.studentIdCardHint,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),

                    // ── CTA button ──
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _canProceed ? widget.onComplete : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HelpiTheme.coral,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: HelpiTheme.border,
                          disabledForegroundColor: HelpiTheme.textSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(AppStrings.registrationDataNext),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required ThemeData theme,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: theme.colorScheme.onSurface.withAlpha(180),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildGenderPicker(ThemeData theme) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: AppStrings.gender,
        labelStyle: TextStyle(
          color: theme.colorScheme.onSurface.withAlpha(180),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender,
          isDense: true,
          isExpanded: true,
          onChanged: (v) {
            if (v != null) setState(() => _gender = v);
          },
          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
          items: [
            DropdownMenuItem(value: 'M', child: Text(AppStrings.genderMale)),
            DropdownMenuItem(value: 'F', child: Text(AppStrings.genderFemale)),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(ThemeData theme) {
    final formatted = _dob != null
        ? Formatters.formatDateFull(_dob!)
        : 'DD.MM.GGGG';
    final hasDate = _dob != null;

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dob ?? DateTime(2002, 1, 1),
          firstDate: DateTime(1920),
          lastDate: DateTime.now(),
        );
        if (picked != null && context.mounted) {
          setState(() => _dob = picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: AppStrings.dateOfBirth,
          labelStyle: TextStyle(
            color: theme.colorScheme.onSurface.withAlpha(180),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: Icon(
            Icons.calendar_today,
            size: 20,
            color: theme.colorScheme.secondary,
          ),
        ),
        child: Text(
          formatted,
          style: TextStyle(
            color: hasDate
                ? theme.colorScheme.onSurface
                : HelpiTheme.textSecondary,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildFacultyPicker(ThemeData theme) {
    final hasFaculty = _selectedFaculty != null;

    return GestureDetector(
      onTap: () async {
        final picked = await showFacultyPicker(
          context: context,
          current: _selectedFaculty,
        );
        if (picked != null && context.mounted) {
          setState(() => _selectedFaculty = picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: AppStrings.faculty,
          labelStyle: TextStyle(
            color: theme.colorScheme.onSurface.withAlpha(180),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: Icon(
            Icons.arrow_drop_down,
            color: theme.colorScheme.secondary,
          ),
        ),
        child: hasFaculty
            ? Text(
                _selectedFaculty!.acronym,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
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
