import 'package:flutter/material.dart';

import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/network/token_storage.dart';
import 'package:helpi_app/core/services/app_api_service.dart';
import 'package:helpi_app/features/schedule/data/availability_model.dart';
import 'package:helpi_app/features/schedule/utils/availability_helpers.dart';
import 'package:helpi_app/features/schedule/widgets/availability_day_row.dart';

/// Sub-screen: student weekly availability grid with edit/save.
class ProfileAvailabilityScreen extends StatefulWidget {
  const ProfileAvailabilityScreen({
    super.key,
    required this.availabilityNotifier,
    this.studentUserId,
  });

  final AvailabilityNotifier availabilityNotifier;
  final int? studentUserId;

  @override
  State<ProfileAvailabilityScreen> createState() =>
      _ProfileAvailabilityScreenState();
}

class _ProfileAvailabilityScreenState extends State<ProfileAvailabilityScreen> {
  bool _isEditing = false;
  bool _isSaving = false;

  List<DayAvailability> get _availability => widget.availabilityNotifier.value;

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

  Future<void> _save() async {
    final userId = widget.studentUserId ?? await TokenStorage().getUserId();
    if (userId == null) return;

    setState(() => _isSaving = true);

    final api = AppApiService();
    final payload = widget.availabilityNotifier.toBackendPayload(userId);
    final result = await api.updateStudentAvailability(payload);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      if (result.success) _isEditing = false;
    });

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? AppStrings.error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.availabilitySection),
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            AppStrings.availabilityDescription,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 24),

          if (_isEditing) ...[
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
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _isEditing = false),
              child: Text(AppStrings.cancel),
            ),
          ],
        ],
      ),
    );
  }
}
