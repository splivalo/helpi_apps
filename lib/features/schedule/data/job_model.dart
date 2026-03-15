import 'package:flutter/material.dart';

import 'package:helpi_app/features/schedule/data/review_model.dart';

/// Tip usluge koju student obavlja.
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

  /// Može li student otkazati ovaj posao (>24h do početka i status scheduled)?
  bool get canDecline {
    if (status != JobStatus.scheduled) return false;
    final jobStart = DateTime(
      date.year,
      date.month,
      date.day,
      from.hour,
      from.minute,
    );
    return jobStart.difference(DateTime.now()).inHours > 24;
  }
}

/// Mock podaci za raspored.
class MockJobs {
  MockJobs._();

  static final List<Job> all = _generateMockJobs();

  static List<Job> _generateMockJobs() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      Job(
        id: 'ses_mock01',
        orderId: 'ord_mock01',
        sessionId: 'ses_mock01',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock01',
        date: today,
        from: const TimeOfDay(hour: 9, minute: 0),
        to: const TimeOfDay(hour: 11, minute: 0),
        serviceTypes: [ServiceType.shopping],
        seniorName: 'Marija Horvat',
        address: 'Ilica 42, Zagreb',
        status: JobStatus.completed,
        notes:
            'Kupiti lijekove u ljekarni Zdravlje na uglu, zatim namirnice po popisu.',
      ),
      Job(
        id: 'ses_mock02',
        orderId: 'ord_mock02',
        sessionId: 'ses_mock02',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock02',
        date: today,
        from: const TimeOfDay(hour: 12, minute: 0),
        to: const TimeOfDay(hour: 13, minute: 30),
        serviceTypes: [
          ServiceType.companionship,
          ServiceType.shopping,
          ServiceType.walking,
          ServiceType.houseHelp,
          ServiceType.escort,
          ServiceType.other,
        ],
        seniorName: 'Ivan Kovačević',
        address: 'Vukovarska 78, Zagreb',
        status: JobStatus.scheduled,
      ),
      Job(
        id: 'ses_mock02b',
        orderId: 'ord_mock03',
        sessionId: 'ses_mock02b',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock03',
        date: today,
        from: const TimeOfDay(hour: 14, minute: 0),
        to: const TimeOfDay(hour: 15, minute: 0),
        serviceTypes: [ServiceType.escort],
        seniorName: 'Stjepan Novak',
        address: 'Vlaška 90, Zagreb',
        status: JobStatus.cancelled,
        notes: 'Otkazano zbog bolesti.',
      ),
      Job(
        id: 'ses_mock02c',
        orderId: 'ord_mock04',
        sessionId: 'ses_mock02c',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock04',
        date: today,
        from: const TimeOfDay(hour: 16, minute: 0),
        to: const TimeOfDay(hour: 18, minute: 0),
        serviceTypes: [ServiceType.walking],
        seniorName: 'Dragica Perić',
        address: 'Trg bana Jelačića 5, Zagreb',
        status: JobStatus.scheduled,
      ),
      Job(
        id: 'ses_mock02d',
        orderId: 'ord_mock05',
        sessionId: 'ses_mock02d',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock05',
        date: today,
        from: const TimeOfDay(hour: 18, minute: 30),
        to: const TimeOfDay(hour: 20, minute: 0),
        serviceTypes: [ServiceType.houseHelp],
        seniorName: 'Božena Šimunić',
        address: 'Ozaljska 22, Zagreb',
        status: JobStatus.scheduled,
        notes: 'Usisati stan, oprati suđe.',
      ),
      Job(
        id: 'ses_mock02e',
        orderId: 'ord_mock06',
        sessionId: 'ses_mock02e',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock06',
        date: today,
        from: const TimeOfDay(hour: 20, minute: 30),
        to: const TimeOfDay(hour: 21, minute: 30),
        serviceTypes: [ServiceType.other],
        seniorName: 'Franjo Kolar',
        address: 'Dubrava 150, Zagreb',
        status: JobStatus.scheduled,
        notes: 'Pomoć s instalacijom TV aplikacija.',
      ),
      Job(
        id: 'ses_mock03',
        orderId: 'ord_mock07',
        sessionId: 'ses_mock03',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock07',
        date: today.add(const Duration(days: 1)),
        from: const TimeOfDay(hour: 10, minute: 0),
        to: const TimeOfDay(hour: 12, minute: 0),
        serviceTypes: [ServiceType.escort],
        seniorName: 'Ana Babić',
        address: 'Heinzelova 15, Zagreb',
        status: JobStatus.scheduled,
        notes: 'Pratnja do liječnika i natrag.',
      ),
      Job(
        id: 'ses_mock04',
        orderId: 'ord_mock08',
        sessionId: 'ses_mock04',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock08',
        date: today.add(const Duration(days: 2)),
        from: const TimeOfDay(hour: 8, minute: 0),
        to: const TimeOfDay(hour: 10, minute: 0),
        serviceTypes: [ServiceType.houseHelp],
        seniorName: 'Josip Matić',
        address: 'Savska 101, Zagreb',
        status: JobStatus.scheduled,
      ),
      Job(
        id: 'ses_mock05',
        orderId: 'ord_mock09',
        sessionId: 'ses_mock05',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock09',
        date: today.add(const Duration(days: 4)),
        from: const TimeOfDay(hour: 15, minute: 0),
        to: const TimeOfDay(hour: 17, minute: 0),
        serviceTypes: [ServiceType.walking],
        seniorName: 'Kata Jurić',
        address: 'Maksimirska 33, Zagreb',
        status: JobStatus.scheduled,
        notes: 'Šetnja do parka i natrag.',
      ),
      Job(
        id: 'ses_mock06',
        orderId: 'ord_mock10',
        sessionId: 'ses_mock06',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock10',
        date: today.add(const Duration(days: 5)),
        from: const TimeOfDay(hour: 11, minute: 0),
        to: const TimeOfDay(hour: 13, minute: 0),
        serviceTypes: [ServiceType.other],
        seniorName: 'Mirko Tomić',
        address: 'Držićeva 12, Zagreb',
        status: JobStatus.scheduled,
        notes: 'Pomoć s preslagivanjem stvari u ormaru.',
      ),
      // Past jobs with reviews
      Job(
        id: 'ses_mock07',
        orderId: 'ord_mock11',
        sessionId: 'ses_mock07',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock11',
        date: today.subtract(const Duration(days: 2)),
        from: const TimeOfDay(hour: 9, minute: 0),
        to: const TimeOfDay(hour: 11, minute: 0),
        serviceTypes: [ServiceType.shopping],
        seniorName: 'Ivka Mandić',
        address: 'Savska 55, Zagreb',
        status: JobStatus.completed,
        review: ReviewModel(
          rating: 5,
          comment: 'Vrlo ljubazan i točan.',
          date: '27.02.2026.',
        ),
      ),
      Job(
        id: 'ses_mock08',
        orderId: 'ord_mock12',
        sessionId: 'ses_mock08',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock12',
        date: today.subtract(const Duration(days: 3)),
        from: const TimeOfDay(hour: 14, minute: 0),
        to: const TimeOfDay(hour: 16, minute: 30),
        serviceTypes: [ServiceType.walking, ServiceType.companionship],
        seniorName: 'Slavko Barić',
        address: 'Šubićeva 10, Zagreb',
        status: JobStatus.completed,
        review: ReviewModel(
          rating: 4,
          comment: 'Ugodna šetnja.',
          date: '26.02.2026.',
        ),
      ),
      Job(
        id: 'ses_mock09',
        orderId: 'ord_mock13',
        sessionId: 'ses_mock09',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock13',
        date: today.subtract(const Duration(days: 5)),
        from: const TimeOfDay(hour: 10, minute: 0),
        to: const TimeOfDay(hour: 12, minute: 0),
        serviceTypes: [ServiceType.houseHelp],
        seniorName: 'Barica Špoljar',
        address: 'Klaićeva 3, Zagreb',
        status: JobStatus.completed,
        review: ReviewModel(
          rating: 5,
          comment: 'Odlično pospremljeno!',
          date: '24.02.2026.',
        ),
      ),
      Job(
        id: 'ses_mock10',
        orderId: 'ord_mock01',
        sessionId: 'ses_mock10',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock01',
        date: today.subtract(const Duration(days: 7)),
        from: const TimeOfDay(hour: 8, minute: 0),
        to: const TimeOfDay(hour: 10, minute: 0),
        serviceTypes: [ServiceType.escort],
        seniorName: 'Marija Horvat',
        address: 'Ilica 42, Zagreb',
        status: JobStatus.completed,
        review: ReviewModel(
          rating: 5,
          comment: 'Strpljiv i pažljiv.',
          date: '22.02.2026.',
        ),
      ),
      Job(
        id: 'ses_mock11',
        orderId: 'ord_mock14',
        sessionId: 'ses_mock11',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock14',
        date: today.subtract(const Duration(days: 10)),
        from: const TimeOfDay(hour: 15, minute: 0),
        to: const TimeOfDay(hour: 17, minute: 0),
        serviceTypes: [ServiceType.companionship],
        seniorName: 'Anka Vuković',
        address: 'Palmotićeva 18, Zagreb',
        status: JobStatus.completed,
        review: ReviewModel(
          rating: 4,
          comment: 'Lijepo smo popričali.',
          date: '19.02.2026.',
        ),
      ),
      Job(
        id: 'ses_mock12',
        orderId: 'ord_mock08',
        sessionId: 'ses_mock12',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock08',
        date: today.subtract(const Duration(days: 14)),
        from: const TimeOfDay(hour: 9, minute: 0),
        to: const TimeOfDay(hour: 11, minute: 30),
        serviceTypes: [ServiceType.shopping, ServiceType.houseHelp],
        seniorName: 'Josip Matić',
        address: 'Savska 101, Zagreb',
        status: JobStatus.completed,
      ),
      Job(
        id: 'ses_mock13',
        orderId: 'ord_mock09',
        sessionId: 'ses_mock13',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock09',
        date: today.subtract(const Duration(days: 8)),
        from: const TimeOfDay(hour: 10, minute: 0),
        to: const TimeOfDay(hour: 12, minute: 0),
        serviceTypes: [ServiceType.walking],
        seniorName: 'Kata Jurić',
        address: 'Maksimirska 33, Zagreb',
        status: JobStatus.completed,
      ),
      Job(
        id: 'ses_mock14',
        orderId: 'ord_mock14',
        sessionId: 'ses_mock14',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock14',
        date: today.subtract(const Duration(days: 9)),
        from: const TimeOfDay(hour: 14, minute: 0),
        to: const TimeOfDay(hour: 16, minute: 0),
        serviceTypes: [ServiceType.companionship],
        seniorName: 'Anka Vuković',
        address: 'Palmotićeva 18, Zagreb',
        status: JobStatus.completed,
      ),
      Job(
        id: 'ses_mock15',
        orderId: 'ord_mock13',
        sessionId: 'ses_mock15',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock13',
        date: today.subtract(const Duration(days: 11)),
        from: const TimeOfDay(hour: 8, minute: 0),
        to: const TimeOfDay(hour: 11, minute: 0),
        serviceTypes: [ServiceType.houseHelp],
        seniorName: 'Barica Špoljar',
        address: 'Klaićeva 3, Zagreb',
        status: JobStatus.completed,
      ),
      Job(
        id: 'ses_mock16',
        orderId: 'ord_mock11',
        sessionId: 'ses_mock16',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock11',
        date: today.subtract(const Duration(days: 17)),
        from: const TimeOfDay(hour: 9, minute: 0),
        to: const TimeOfDay(hour: 12, minute: 0),
        serviceTypes: [ServiceType.shopping],
        seniorName: 'Ivka Mandić',
        address: 'Savska 55, Zagreb',
        status: JobStatus.completed,
      ),
      Job(
        id: 'ses_mock17',
        orderId: 'ord_mock07',
        sessionId: 'ses_mock17',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock07',
        date: today.subtract(const Duration(days: 19)),
        from: const TimeOfDay(hour: 13, minute: 0),
        to: const TimeOfDay(hour: 15, minute: 0),
        serviceTypes: [ServiceType.escort],
        seniorName: 'Ana Babić',
        address: 'Heinzelova 15, Zagreb',
        status: JobStatus.completed,
      ),
      Job(
        id: 'ses_mock18',
        orderId: 'ord_mock01',
        sessionId: 'ses_mock18',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock01',
        date: today.subtract(const Duration(days: 25)),
        from: const TimeOfDay(hour: 10, minute: 0),
        to: const TimeOfDay(hour: 13, minute: 0),
        serviceTypes: [ServiceType.houseHelp, ServiceType.shopping],
        seniorName: 'Marija Horvat',
        address: 'Ilica 42, Zagreb',
        status: JobStatus.completed,
      ),
      Job(
        id: 'ses_mock19',
        orderId: 'ord_mock04',
        sessionId: 'ses_mock19',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock04',
        date: today.subtract(const Duration(days: 35)),
        from: const TimeOfDay(hour: 9, minute: 0),
        to: const TimeOfDay(hour: 11, minute: 0),
        serviceTypes: [ServiceType.walking],
        seniorName: 'Dragica Perić',
        address: 'Trg bana Jelačića 5, Zagreb',
        status: JobStatus.completed,
      ),
      Job(
        id: 'ses_mock20',
        orderId: 'ord_mock12',
        sessionId: 'ses_mock20',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock12',
        date: today.subtract(const Duration(days: 40)),
        from: const TimeOfDay(hour: 14, minute: 0),
        to: const TimeOfDay(hour: 17, minute: 0),
        serviceTypes: [ServiceType.companionship],
        seniorName: 'Slavko Barić',
        address: 'Šubićeva 10, Zagreb',
        status: JobStatus.completed,
      ),
      Job(
        id: 'ses_mock21',
        orderId: 'ord_mock03',
        sessionId: 'ses_mock21',
        studentId: 'stu_mock01',
        seniorId: 'sen_mock03',
        date: today.subtract(const Duration(days: 45)),
        from: const TimeOfDay(hour: 8, minute: 0),
        to: const TimeOfDay(hour: 10, minute: 30),
        serviceTypes: [ServiceType.escort],
        seniorName: 'Stjepan Novak',
        address: 'Vlaška 90, Zagreb',
        status: JobStatus.completed,
      ),
    ];
  }

  /// Vrati poslove za određeni datum.
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

  /// Datumi koji imaju barem 1 posao.
  static Set<DateTime> get datesWithJobs {
    return all
        .map((j) => DateTime(j.date.year, j.date.month, j.date.day))
        .toSet();
  }
}
