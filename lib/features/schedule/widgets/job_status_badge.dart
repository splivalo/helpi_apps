import 'package:flutter/material.dart';

import 'package:helpi_app/features/schedule/data/job_model.dart';
import 'package:helpi_app/features/schedule/utils/job_helpers.dart';

/// Status chip za Job - colored capsule with label.
class JobStatusBadge extends StatelessWidget {
  const JobStatusBadge({super.key, required this.status});

  final JobStatus status;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: JobHelpers.statusBgColor(status, brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        JobHelpers.statusLabel(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: JobHelpers.statusColor(status, brightness),
        ),
      ),
    );
  }
}
