import 'package:flutter/material.dart';

import 'package:helpi_app/core/constants/colors.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/features/booking/data/order_model.dart';

/// Badge displaying job/session status (completed / scheduled / cancelled).
class JobStatusBadge extends StatelessWidget {
  const JobStatusBadge({super.key, required this.status});

  final JobStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg;
    final Color fg;
    final String label;

    switch (status) {
      case JobStatus.completed:
        bg = isDark ? AppColors.success.withAlpha(30) : AppColors.statusGreenBg;
        fg = isDark ? const Color(0xFF81C784) : AppColors.success;
        label = AppStrings.jobCompleted;
      case JobStatus.scheduled:
        bg = isDark ? AppColors.info.withAlpha(30) : AppColors.statusBlueBg;
        fg = isDark ? const Color(0xFF64B5F6) : AppColors.info;
        label = AppStrings.jobUpcoming;
      case JobStatus.cancelled:
        bg = isDark ? AppColors.coral.withAlpha(30) : AppColors.statusRedBg;
        fg = isDark ? const Color(0xFFEF9A9A) : AppColors.coral;
        label = AppStrings.jobCancelled;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
