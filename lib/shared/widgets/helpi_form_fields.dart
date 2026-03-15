import 'package:flutter/material.dart';

import 'package:helpi_app/core/constants/colors.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/utils/formatters.dart';

/// Naslov sekcije (bold, titleMedium).
class HelpiSectionHeader extends StatelessWidget {
  const HelpiSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

/// Standardno tekstualno polje s labelom.
class HelpiTextField extends StatelessWidget {
  const HelpiTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      style: TextStyle(
        color: enabled
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withAlpha(153),
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: theme.colorScheme.onSurface.withAlpha(enabled ? 180 : 153),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

/// Gender picker (M/F dropdown).
class HelpiGenderPicker extends StatelessWidget {
  const HelpiGenderPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: AppStrings.gender,
        labelStyle: TextStyle(
          color: theme.colorScheme.onSurface.withAlpha(enabled ? 180 : 153),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabled: enabled,
        filled: true,
        fillColor: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          isExpanded: true,
          onChanged: enabled
              ? (v) {
                  if (v != null) onChanged(v);
                }
              : null,
          style: TextStyle(
            color: enabled
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
}

/// Date picker polje za datum rođenja.
class HelpiDatePicker extends StatelessWidget {
  const HelpiDatePicker({
    super.key,
    required this.label,
    required this.date,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatted = date != null ? '${AppFormatters.date(date!)}.' : null;

    return GestureDetector(
      onTap: enabled
          ? () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date ?? DateTime(1960),
                firstDate: DateTime(1920),
                lastDate: DateTime.now(),
                confirmText: AppStrings.confirm,
                cancelText: AppStrings.cancel,
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
            color: theme.colorScheme.onSurface.withAlpha(enabled ? 180 : 153),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: enabled
                  ? theme.colorScheme.onSurface.withAlpha(100)
                  : AppColors.border,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: enabled
              ? Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: theme.colorScheme.secondary,
                )
              : null,
        ),
        child: Text(
          formatted ?? AppStrings.dobPlaceholder,
          style: TextStyle(
            color: enabled
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withAlpha(153),
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
