import 'package:flutter/material.dart';

/// Red s label (lijevo, sivi) i value (desno, bold).
class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    this.bold = false,
  }) : assert(value != null || valueWidget != null);

  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          label,
          style: bold
              ? theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                )
              : theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
        ),
        const Spacer(),
        if (valueWidget != null)
          valueWidget!
        else
          Text(
            value!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
