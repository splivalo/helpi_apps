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
    final Color bg;
    final Color fg;
    final String label;

    switch (status) {
      case OrderStatus.processing:
        bg = AppColors.statusBlueBg;
        fg = AppColors.info;
        label = AppStrings.orderProcessing;
      case OrderStatus.active:
        bg = AppColors.statusGreenBg;
        fg = AppColors.success;
        label = AppStrings.orderActive;
      case OrderStatus.completed:
        bg = AppColors.statusGreenBg;
        fg = AppColors.success;
        label = AppStrings.orderCompleted;
      case OrderStatus.cancelled:
        bg = AppColors.statusRedBg;
        fg = AppColors.coral;
        label = AppStrings.orderCancelled;
      case OrderStatus.archived:
        bg = const Color(0xFFF5F5F5);
        fg = AppColors.textSecondary;
        label = AppStrings.orderArchived;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
