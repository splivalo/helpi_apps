import 'package:flutter/material.dart';

import 'package:helpi_app/core/constants/colors.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/features/booking/data/order_model.dart';

/// Chip displaying order status (processing / active / completed).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color bg;
    final Color fg;
    final String label;

    switch (status) {
      case OrderStatus.processing:
        bg = isDark ? AppColors.info.withAlpha(30) : AppColors.statusBlueBg;
        fg = isDark ? const Color(0xFF64B5F6) : AppColors.info;
        label = AppStrings.orderProcessing;
      case OrderStatus.active:
        bg = isDark ? AppColors.success.withAlpha(30) : AppColors.statusGreenBg;
        fg = AppColors.success;
        label = AppStrings.orderActive;
      case OrderStatus.completed:
        bg = isDark ? AppColors.success.withAlpha(30) : AppColors.statusGreenBg;
        fg = AppColors.success;
        label = AppStrings.orderCompleted;
      case OrderStatus.cancelled:
        bg = isDark ? AppColors.coral.withAlpha(30) : AppColors.statusRedBg;
        fg = AppColors.coral;
        label = AppStrings.orderCancelled;
      case OrderStatus.archived:
        bg = theme.colorScheme.surfaceContainerHighest;
        fg = theme.colorScheme.onSurfaceVariant;
        label = AppStrings.orderArchived;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: fg.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
