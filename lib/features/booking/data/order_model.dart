import 'package:flutter/foundation.dart';

/// Status narudžbe (canonical: processing → active → completed | cancelled | archived).
enum OrderStatus { processing, active, completed, cancelled, archived }

/// Status pojedinog posla/termina (canonical: scheduled → completed | cancelled).
enum JobStatus { completed, scheduled, cancelled }

/// Strukturirani zapis jednog dana u ponavljajućoj narudžbi.
class OrderDayEntry {
  const OrderDayEntry({
    required this.dayName,
    required this.time,
    required this.duration,
    this.weekday = 1,
    this.durationHours = 0,
  });

  final String dayName;
  final String time;
  final String duration;
  final int weekday; // 1=Mon … 7=Sun
  final int durationHours;
}

/// Jedan konkretan termin (posao) unutar narudžbe.
class JobModel {
  JobModel({
    required this.date,
    required this.weekday,
    required this.time,
    required this.durationHours,
    required this.studentName,
    this.orderId = '',
    this.studentId = '',
    this.status = JobStatus.scheduled,
    this.review,
  });

  final DateTime date;
  final int weekday; // 1=Mon … 7=Sun
  final String time;
  final int durationHours;
  final String studentName;
  final String orderId;
  final String studentId;

  JobStatus status;
  ReviewModel? review;
}

/// Recenzija studenta od strane seniora.
class ReviewModel {
  ReviewModel({required this.rating, this.comment = '', required this.date});

  final int rating; // 1-5
  final String comment;
  final DateTime date;
}

/// Student dodijeljen narudžbi.
class StudentAssignment {
  StudentAssignment({
    required this.name,
    required this.fromDate,
    this.studentId = '',
    this.toDate,
  });

  final String name;
  final String studentId;
  final DateTime fromDate;
  final DateTime? toDate;
  final List<ReviewModel> reviews = [];
}

/// Pojednostavljen model narudžbe (mock — bez bacenda).
class OrderModel {
  OrderModel({
    required this.id,
    required this.services,
    required this.date,
    required this.frequency,
    this.seniorId = '',
    this.status = OrderStatus.processing,
    this.notes = '',
    this.serviceNote = '',
    this.promoCode = '',
    this.paymentMethodId = '',
    this.isOneTime = true,
    this.time = '',
    this.duration = '',
    this.dayEntries = const [],
    this.endDate,
    this.weekday = 1,
    this.durationHours = 0,
    List<StudentAssignment>? students,
    List<JobModel>? jobs,
  }) : students = students ?? [],
       jobs = jobs ?? [];

  final int id;
  final String seniorId;
  final List<String> services;
  final DateTime date;
  final String frequency;
  final String notes;
  final String serviceNote;
  final String promoCode;
  final String paymentMethodId;
  OrderStatus status;

  final bool isOneTime;
  final String time;
  final String duration;

  final List<OrderDayEntry> dayEntries;
  final DateTime? endDate;
  final int weekday;
  final int durationHours;

  final List<StudentAssignment> students;
  final List<JobModel> jobs;
}

/// Mock imena studenata za prototype.
const _mockStudentNames = ['Ana M.', 'Marko K.', 'Ivana P.', 'Luka S.'];
int _mockNameIndex = 0;

/// In-memory spremnik narudžbi.
class OrdersNotifier extends ChangeNotifier {
  OrdersNotifier() {
    _seedMockData();
  }

  final List<OrderModel> _orders = [];

  void _seedMockData() {
    final seedOneTime = OrderModel(
      id: _nextId,
      services: ['Čišćenje', 'Kuhanje'],
      date: DateTime(2026, 2, 25),
      frequency: 'Jednom',
      status: OrderStatus.completed,
      isOneTime: true,
      time: '10:00',
      duration: '2 sata',
      weekday: 3,
      durationHours: 2,
      students: [
        StudentAssignment(name: 'Ana M.', fromDate: DateTime(2026, 2, 25)),
      ],
      jobs: [
        JobModel(
          date: DateTime(2026, 2, 25),
          weekday: 3,
          time: '10:00',
          durationHours: 2,
          studentName: 'Ana M.',
          status: JobStatus.completed,
        ),
      ],
    );
    _orders.add(seedOneTime);
    _nextId++;

    final seedRecurring = OrderModel(
      id: _nextId,
      services: ['Čišćenje'],
      date: DateTime(2026, 1, 3),
      frequency: 'Ponavljajuće',
      status: OrderStatus.completed,
      isOneTime: false,
      time: '09:00',
      duration: '3 sata',
      weekday: 1,
      durationHours: 3,
      dayEntries: const [
        OrderDayEntry(
          dayName: 'Ponedjeljak',
          time: '09:00',
          duration: '3 sata',
          weekday: 1,
          durationHours: 3,
        ),
        OrderDayEntry(
          dayName: 'Četvrtak',
          time: '14:00',
          duration: '2 sata',
          weekday: 4,
          durationHours: 2,
        ),
      ],
      students: [
        StudentAssignment(name: 'Marko K.', fromDate: DateTime(2026, 1, 3)),
      ],
      jobs: [
        JobModel(
          date: DateTime(2026, 1, 5),
          weekday: 1,
          time: '09:00',
          durationHours: 3,
          studentName: 'Marko K.',
          status: JobStatus.completed,
        ),
        JobModel(
          date: DateTime(2026, 1, 8),
          weekday: 4,
          time: '14:00',
          durationHours: 2,
          studentName: 'Marko K.',
          status: JobStatus.completed,
        ),
        JobModel(
          date: DateTime(2026, 1, 12),
          weekday: 1,
          time: '09:00',
          durationHours: 3,
          studentName: 'Marko K.',
          status: JobStatus.completed,
        ),
        JobModel(
          date: DateTime(2026, 1, 15),
          weekday: 4,
          time: '14:00',
          durationHours: 2,
          studentName: 'Marko K.',
          status: JobStatus.completed,
        ),
      ],
    );
    _orders.add(seedRecurring);
    _nextId++;

    final seedUntilDate = OrderModel(
      id: _nextId,
      services: ['Kuhanje', 'Šetnja'],
      date: DateTime(2026, 1, 10),
      frequency: 'Do 07.02.2026',
      status: OrderStatus.completed,
      isOneTime: false,
      time: '11:00',
      duration: '2 sata',
      weekday: 6,
      durationHours: 2,
      endDate: DateTime(2026, 2, 7),
      dayEntries: const [
        OrderDayEntry(
          dayName: 'Subota',
          time: '11:00',
          duration: '2 sata',
          weekday: 6,
          durationHours: 2,
        ),
      ],
      students: [
        StudentAssignment(name: 'Ivana P.', fromDate: DateTime(2026, 1, 10)),
      ],
      jobs: [
        JobModel(
          date: DateTime(2026, 1, 10),
          weekday: 6,
          time: '11:00',
          durationHours: 2,
          studentName: 'Ivana P.',
          status: JobStatus.completed,
        ),
        JobModel(
          date: DateTime(2026, 1, 17),
          weekday: 6,
          time: '11:00',
          durationHours: 2,
          studentName: 'Ivana P.',
          status: JobStatus.completed,
        ),
        JobModel(
          date: DateTime(2026, 1, 24),
          weekday: 6,
          time: '11:00',
          durationHours: 2,
          studentName: 'Ivana P.',
          status: JobStatus.completed,
        ),
        JobModel(
          date: DateTime(2026, 1, 31),
          weekday: 6,
          time: '11:00',
          durationHours: 2,
          studentName: 'Ivana P.',
          status: JobStatus.completed,
        ),
        JobModel(
          date: DateTime(2026, 2, 7),
          weekday: 6,
          time: '11:00',
          durationHours: 2,
          studentName: 'Ivana P.',
          status: JobStatus.cancelled,
        ),
      ],
    );
    _orders.add(seedUntilDate);
    _nextId++;
  }

  List<OrderModel> get orders => List.unmodifiable(_orders);

  List<OrderModel> get processing =>
      _orders.where((o) => o.status == OrderStatus.processing).toList();

  List<OrderModel> get active =>
      _orders.where((o) => o.status == OrderStatus.active).toList();

  List<OrderModel> get completed =>
      _orders.where((o) => o.status == OrderStatus.completed).toList();

  List<OrderModel> get cancelled =>
      _orders.where((o) => o.status == OrderStatus.cancelled).toList();

  List<OrderModel> get inactive => _orders
      .where(
        (o) =>
            o.status == OrderStatus.completed ||
            o.status == OrderStatus.cancelled,
      )
      .toList();

  List<OrderModel> get archived =>
      _orders.where((o) => o.status == OrderStatus.archived).toList();

  int _nextId = 1;

  /// Zamijeni sve narudžbe API podacima (DataLoader poziva ovo).
  void replaceAll(List<OrderModel> apiOrders) {
    _orders
      ..clear()
      ..addAll(apiOrders);
    if (apiOrders.isNotEmpty) {
      _nextId = apiOrders.map((o) => o.id).reduce((a, b) => a > b ? a : b) + 1;
    }
    notifyListeners();
  }

  void addProcessingOrder(OrderModel order) {
    order.status = OrderStatus.processing;
    _orders.insert(0, order);
    _nextId++;
    notifyListeners();
  }

  void addOrder(OrderModel order) {
    order.status = OrderStatus.active;
    final studentName =
        _mockStudentNames[_mockNameIndex % _mockStudentNames.length];
    _mockNameIndex++;
    if (order.students.isEmpty) {
      order.students.add(
        StudentAssignment(name: studentName, fromDate: order.date),
      );
    }
    _generateJobs(order, studentName);
    _orders.insert(0, order);
    _nextId++;
    notifyListeners();
  }

  void _generateJobs(OrderModel order, String studentName) {
    if (order.isOneTime) {
      order.jobs.add(
        JobModel(
          date: order.date,
          weekday: order.weekday,
          time: order.time,
          durationHours: order.durationHours,
          studentName: studentName,
          status: JobStatus.scheduled,
        ),
      );
      return;
    }

    final start = order.date;
    final limit = order.endDate ?? start.add(const Duration(days: 60));

    final jobs = <JobModel>[];
    for (final entry in order.dayEntries) {
      var current = _firstOccurrence(entry.weekday, start);
      while (!current.isAfter(limit)) {
        jobs.add(
          JobModel(
            date: current,
            weekday: entry.weekday,
            time: entry.time,
            durationHours: entry.durationHours,
            studentName: studentName,
            status: JobStatus.scheduled,
          ),
        );
        current = current.add(const Duration(days: 7));
      }
    }

    jobs.sort((a, b) => a.date.compareTo(b.date));

    for (var i = 0; i < jobs.length && i < 3; i++) {
      jobs[i].status = JobStatus.completed;
    }

    order.jobs.addAll(jobs);
  }

  static DateTime _firstOccurrence(int weekday, DateTime from) {
    final diff = (weekday - from.weekday + 7) % 7;
    return from.add(Duration(days: diff));
  }

  int get nextId => _nextId;

  void cancelOrder(int id) {
    final idx = _orders.indexWhere((o) => o.id == id);
    if (idx == -1) return;
    _orders[idx].status = OrderStatus.cancelled;
    notifyListeners();
  }

  void completeOrder(int id) {
    final order = _orders.firstWhere((o) => o.id == id);
    order.status = OrderStatus.completed;
    if (order.isOneTime && order.jobs.isNotEmpty) {
      order.jobs.first.status = JobStatus.completed;
    }
    notifyListeners();
  }

  void addReview(int orderId, int studentIndex, ReviewModel review) {
    final order = _orders.firstWhere((o) => o.id == orderId);
    order.students[studentIndex].reviews.add(review);
    notifyListeners();
  }

  void cancelJob(int orderId, int jobIndex) {
    final order = _orders.firstWhere((o) => o.id == orderId);
    if (jobIndex >= 0 && jobIndex < order.jobs.length) {
      order.jobs[jobIndex].status = JobStatus.cancelled;
      notifyListeners();
    }
  }

  void addJobReview(int orderId, int jobIndex, ReviewModel review) {
    final order = _orders.firstWhere((o) => o.id == orderId);
    if (jobIndex >= 0 && jobIndex < order.jobs.length) {
      order.jobs[jobIndex].review = review;
      notifyListeners();
    }
  }
}
