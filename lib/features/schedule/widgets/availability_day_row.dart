import 'package:flutter/material.dart';

import 'package:helpi_app/app/theme.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/features/schedule/data/availability_model.dart';
import 'package:helpi_app/features/schedule/utils/formatters.dart';
import 'package:helpi_app/features/schedule/utils/job_helpers.dart';

/// Availability row for one day - checkbox + name + from/to chips.
/// Used in onboarding_screen and profile_screen.
class AvailabilityDayRow extends StatelessWidget {
  const AvailabilityDayRow({
    super.key,
    required this.day,
    required this.onEnabledChanged,
    required this.onPickFrom,
    required this.onPickTo,
    this.enabled = true,
  });

  final DayAvailability day;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;

  /// If false, checkbox is disabled (profile when not in edit mode).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: HelpiTheme.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Checkbox(
                value: day.enabled,
                onChanged: enabled ? (v) => onEnabledChanged(v ?? false) : null,
                activeColor: theme.colorScheme.secondary,
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                JobHelpers.dayName(day.dayKey),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: day.enabled ? FontWeight.w600 : FontWeight.w400,
                  color: day.enabled
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withAlpha(120),
                ),
              ),
            ),
            const Spacer(),
            if (day.enabled) ...[
              _TimeChip(
                label: AppStrings.fromTime,
                time: day.from,
                onTap: enabled ? onPickFrom : null,
              ),
              const SizedBox(width: 8),
              _TimeChip(
                label: AppStrings.toTime,
                time: day.to,
                onTap: enabled ? onPickTo : null,
              ),
            ] else
              Text(
                AppStrings.notSet,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(100),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.time, this.onTap});

  final String label;
  final TimeOfDay time;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$label ${Formatters.formatTime(time)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}
