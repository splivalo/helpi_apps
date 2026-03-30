import 'package:flutter/material.dart';

import 'package:helpi_app/app/theme.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/network/api_client.dart';
import 'package:helpi_app/core/network/api_endpoints.dart';
import 'package:helpi_app/core/services/auth_service.dart';
import 'package:helpi_app/shared/models/faculty.dart';
import 'package:helpi_app/shared/models/selected_address_info.dart';
import 'package:helpi_app/shared/widgets/mc_address_field.dart';
import 'package:helpi_app/features/schedule/utils/formatters.dart';
import 'package:helpi_app/features/schedule/widgets/faculty_picker.dart';

/// Registration - student enters personal data before setting availability.
/// "Next" button is disabled until all required fields are filled.
class RegistrationDataScreen extends StatefulWidget {
  const RegistrationDataScreen({
    super.key,
    required this.email,
    required this.password,
    required this.onComplete,
    this.onBack,
  });

  final String email;
  final String password;
  final VoidCallback onComplete;
  final VoidCallback? onBack;

  @override
  State<RegistrationDataScreen> createState() => _RegistrationDataScreenState();
}

class _RegistrationDataScreenState extends State<RegistrationDataScreen> {
  final _authService = AuthService();
  final _apiClient = ApiClient();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String _gender = 'M';
  DateTime? _dob;
  Faculty? _selectedFaculty;
  SelectedAddressInfo? _selectedAddress;
  bool _isLoading = false;
  String? _errorMessage;
  List<Faculty> _faculties = [];

  @override
  void initState() {
    super.initState();
    _firstNameCtrl.addListener(_onFieldChanged);
    _lastNameCtrl.addListener(_onFieldChanged);
    _phoneCtrl.addListener(_onFieldChanged);
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
      // Faculties will remain empty - picker shows nothing
    }
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed =>
      _firstNameCtrl.text.trim().isNotEmpty &&
      _lastNameCtrl.text.trim().isNotEmpty &&
      _phoneCtrl.text.trim().isNotEmpty &&
      _selectedAddress != null &&
      _selectedFaculty != null &&
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

                    // -- Back arrow --
                    if (widget.onBack != null)
                      GestureDetector(
                        onTap: widget.onBack,
                        child: const Icon(Icons.arrow_back, size: 28),
                      ),
                    const SizedBox(height: 24),

                    // -- Title --
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

                    // -- First name --
                    _buildField(
                      label: AppStrings.firstName,
                      controller: _firstNameCtrl,
                      theme: theme,
                    ),
                    const SizedBox(height: 12),

                    // -- Last name --
                    _buildField(
                      label: AppStrings.lastName,
                      controller: _lastNameCtrl,
                      theme: theme,
                    ),
                    const SizedBox(height: 12),

                    // -- Gender --
                    _buildGenderPicker(theme),
                    const SizedBox(height: 12),

                    // -- Date of birth --
                    _buildDatePicker(theme),
                    const SizedBox(height: 12),

                    // -- Phone --
                    _buildField(
                      label: AppStrings.phone,
                      controller: _phoneCtrl,
                      theme: theme,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),

                    // -- Address --
                    McAddressField(
                      controller: _addressCtrl,
                      onAddressSelected: (info) {
                        setState(() => _selectedAddress = info);
                      },
                    ),
                    const SizedBox(height: 12),

                    // -- Faculty --
                    _buildFacultyPicker(theme),
                    const SizedBox(height: 32),

                    // -- Error message --
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // -- CTA button --
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_canProceed && !_isLoading)
                            ? _handleRegister
                            : null,
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
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(AppStrings.registrationDataNext),
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

  // -- Registration logic --

  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final fullName =
        '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}';

    final result = await _authService.registerStudent(
      email: widget.email,
      password: widget.password,
      fullName: fullName,
      phone: _phoneCtrl.text.trim(),
      gender: _gender,
      dateOfBirth: _dob!,
      fullAddress: _selectedAddress!.fullAddress,
      cityId: 2,
      googlePlaceId: _selectedAddress!.placeId,
      lat: _selectedAddress!.lat,
      lng: _selectedAddress!.lng,
      facultyId: _selectedFaculty!.id,
    );

    if (!context.mounted) return;

    if (!result.success) {
      setState(() {
        _isLoading = false;
        _errorMessage = result.message;
      });
      return;
    }

    // Auto-login after successful registration
    final loginResult = await _authService.login(widget.email, widget.password);

    if (!context.mounted) return;

    setState(() => _isLoading = false);

    if (loginResult.success) {
      widget.onComplete();
    } else {
      setState(() => _errorMessage = loginResult.message);
    }
  }

  // -- Helpers --

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
          faculties: _faculties,
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
                _selectedFaculty!.abbreviation.isNotEmpty
                    ? '${_selectedFaculty!.abbreviation} — ${_selectedFaculty!.name}'
                    : _selectedFaculty!.name,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
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
