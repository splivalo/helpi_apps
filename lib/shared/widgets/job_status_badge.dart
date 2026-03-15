import 'package:flutter/material.dart';

import 'package:helpi_app/core/constants/colors.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/features/booking/data/order_model.dart';

/// Badge koji prikazuje status posla/termina (completed / scheduled / cancelled).
class JobStatusBadge extends StatelessWidget {
  const JobStatusBadge({super.key, required this.status});

  final JobStatus status;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;

    switch (status) {
      case JobStatus.completed:
        bg = AppColors.statusGreenBg;
        fg = AppColors.success;
        label = AppStrings.jobCompleted;
      case JobStatus.scheduled:
        bg = AppColors.statusBlueBg;
        fg = AppColors.info;
        label = AppStrings.jobUpcoming;
      case JobStatus.cancelled:
        bg = AppColors.statusRedBg;
        fg = AppColors.coral;
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
