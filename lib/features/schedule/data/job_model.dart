import 'package:flutter/material.dart';

import 'package:helpi_app/features/schedule/data/review_model.dart';

/// Service type that student performs.
enum ServiceType { shopping, houseHelp, companionship, walking, escort, other }

/// Status dodijeljenog posla.
/// `scheduled` = planirano, još nije izvršeno/otkazano.
enum JobStatus { scheduled, completed, cancelled }

/// Model jednog dodijeljenog posla za studenta.
class Job {
  const Job({
    required this.id,
    required this.date,
    required this.from,
    required this.to,
    required this.serviceTypes,
    required this.seniorName,
    required this.address,
    this.orderId,
    this.sessionId,
    this.studentId,
    this.seniorId,
    this.status = JobStatus.scheduled,
    this.notes,
    this.review,
  });

  final String id;
  final DateTime date;
  final TimeOfDay from;
  final TimeOfDay to;
  final List<ServiceType> serviceTypes;
  final String seniorName;
  final String address;

  final String? orderId;
  final String? sessionId;
  final String? studentId;
  final String? seniorId;

  final JobStatus status;
  final String? notes;
  final ReviewModel? review;

  /// Može li student otkazati ovaj posao (>6h do početka i status scheduled)?
  bool get canDecline {
    if (status != JobStatus.scheduled) return false;
    final jobStart = DateTime(
      date.year,
      date.month,
      date.day,
      from.hour,
      from.minute,
    );
    return jobStart.difference(DateTime.now()).inHours > 6;
  }
}

/// Spremnik studenskih poslova. DataLoader puni listu iz API-ja.
class MockJobs {
  MockJobs._();

  static final List<Job> all = [];

  /// Return jobs for specific date.
  static List<Job> forDate(DateTime date) {
    return all
        .where(
          (j) =>
              j.date.year == date.year &&
              j.date.month == date.month &&
              j.date.day == date.day,
        )
        .toList()
      ..sort(
        (a, b) => (a.from.hour * 60 + a.from.minute).compareTo(
          b.from.hour * 60 + b.from.minute,
        ),
      );
  }

  /// Dates that have at least 1 job.
  static Set<DateTime> get datesWithJobs {
    return all
        .map((j) => DateTime(j.date.year, j.date.month, j.date.day))
        .toSet();
  }
}
