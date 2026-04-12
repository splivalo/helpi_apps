import 'package:flutter/material.dart';

import 'package:helpi_app/app/theme.dart';
import 'package:helpi_app/core/constants/colors.dart';

/// Info card with icon and text (blue background).
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.text,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
  });

  final String text;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultBg = isDark ? const Color(0xFF1A2A3A) : HelpiTheme.cardBlue;
    final defaultIcon = isDark ? const Color(0xFF64B5F6) : AppColors.info;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: iconColor ?? defaultIcon),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor ?? defaultIcon,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
