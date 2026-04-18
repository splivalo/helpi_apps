import 'package:flutter/foundation.dart';

/// Status narudžbe (canonical: processing -> active -> completed | cancelled | archived).
enum OrderStatus { processing, active, completed, cancelled, archived }

/// Status pojedinog posla/termina (canonical: scheduled -> completed | cancelled).
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
    this.id,
    this.pendingReviewId,
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

  /// Backend job instance ID.
  final int? id;

  /// Pending review ID (ako senior treba ocijeniti).
  int? pendingReviewId;

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

/// Student review by senior.
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

/// Simplified order model (maps backend DTO to UI).
class OrderModel {
  OrderModel({
    required this.id,
    this.orderNumber = 0,
    required this.services,
    required this.date,
    required this.frequency,
    this.seniorId = '',
    this.serviceIds = const [],
    this.status = OrderStatus.processing,
    this.notes = '',
    this.serviceNote = '',
    this.couponCode = '',
    this.paymentMethodId = '',
    this.isOneTime = true,
    this.time = '',
    this.duration = '',
    this.dayEntries = const [],
    this.endDate,
    this.weekday = 1,
    this.durationHours = 0,
    this.fromHour,
    this.fromMinute,
    List<StudentAssignment>? students,
    List<JobModel>? jobs,
  }) : students = students ?? [],
       jobs = jobs ?? [];

  final int id;
  final int orderNumber;
  final String seniorId;
  final List<String> services;
  final List<int> serviceIds;
  final DateTime date;
  final String frequency;
  final String notes;
  final String serviceNote;
  final String couponCode;
  final String paymentMethodId;
  OrderStatus status;

  final bool isOneTime;
  final String time;
  final String duration;

  final List<OrderDayEntry> dayEntries;
  final DateTime? endDate;
  final int weekday;
  final int durationHours;
  final int? fromHour;
  final int? fromMinute;

  final List<StudentAssignment> students;
  final List<JobModel> jobs;
}

/// In-memory spremnik narudžbi.
class OrdersNotifier extends ChangeNotifier {
  OrdersNotifier();

  final List<OrderModel> _orders = [];

  List<OrderModel> get orders => List.unmodifiable(_orders);

  List<OrderModel> get processing =>
      _orders.where((o) => o.status == OrderStatus.processing).toList()
        ..sort((a, b) => b.id.compareTo(a.id));

  List<OrderModel> get active =>
      _orders.where((o) => o.status == OrderStatus.active).toList()
        ..sort((a, b) => b.id.compareTo(a.id));

  List<OrderModel> get completed =>
      _orders.where((o) => o.status == OrderStatus.completed).toList()
        ..sort((a, b) => b.id.compareTo(a.id));

  List<OrderModel> get cancelled =>
      _orders.where((o) => o.status == OrderStatus.cancelled).toList()
        ..sort((a, b) => b.id.compareTo(a.id));

  List<OrderModel> get inactive =>
      _orders
          .where(
            (o) =>
                o.status == OrderStatus.completed ||
                o.status == OrderStatus.cancelled,
          )
          .toList()
        ..sort((a, b) => b.id.compareTo(a.id));

  List<OrderModel> get archived =>
      _orders.where((o) => o.status == OrderStatus.archived).toList()
        ..sort((a, b) => b.id.compareTo(a.id));

  int _nextId = 1;

  /// Replace all orders with API data (DataLoader calls this).
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
    final studentName = order.students.isNotEmpty
        ? order.students.first.name
        : 'Student';
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
