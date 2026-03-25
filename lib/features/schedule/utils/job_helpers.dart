import 'package:flutter/material.dart';

import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/features/schedule/data/job_model.dart';

/// Centralized helpers for Job status/service labels and colors.
class JobHelpers {
  JobHelpers._();

  // -- Status --

  static String statusLabel(JobStatus status) {
    switch (status) {
      case JobStatus.scheduled:
        return AppStrings.jobStatusScheduled;
      case JobStatus.completed:
        return AppStrings.jobStatusCompleted;
      case JobStatus.cancelled:
        return AppStrings.jobStatusCancelled;
    }
  }

  static Color statusColor(JobStatus status) {
    switch (status) {
      case JobStatus.scheduled:
        return const Color(0xFF4CAF50);
      case JobStatus.completed:
        return const Color(0xFF757575);
      case JobStatus.cancelled:
        return const Color(0xFFEF5B5B);
    }
  }

  static Color statusBgColor(JobStatus status) {
    switch (status) {
      case JobStatus.scheduled:
        return const Color(0xFFE8F5E9);
      case JobStatus.completed:
        return const Color(0xFFF0F0F0);
      case JobStatus.cancelled:
        return const Color(0xFFFFEBEE);
    }
  }

  // -- Service type --

  static String serviceLabel(ServiceType type) {
    switch (type) {
      case ServiceType.shopping:
        return AppStrings.serviceShopping2;
      case ServiceType.houseHelp:
        return AppStrings.serviceHouseHelp2;
      case ServiceType.companionship:
        return AppStrings.serviceCompanionship2;
      case ServiceType.walking:
        return AppStrings.serviceWalking2;
      case ServiceType.escort:
        return AppStrings.serviceEscort2;
      case ServiceType.other:
        return AppStrings.serviceOther2;
    }
  }

  // -- Day name mapping --

  static String dayName(String key) {
    switch (key) {
      case 'dayMonFull':
        return AppStrings.dayMonFull;
      case 'dayTueFull':
        return AppStrings.dayTueFull;
      case 'dayWedFull':
        return AppStrings.dayWedFull;
      case 'dayThuFull':
        return AppStrings.dayThuFull;
      case 'dayFriFull':
        return AppStrings.dayFriFull;
      case 'daySatFull':
        return AppStrings.daySatFull;
      case 'daySunFull':
        return AppStrings.daySunFull;
      default:
        return key;
    }
  }
}
