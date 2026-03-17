import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:helpi_app/core/network/api_client.dart';
import 'package:helpi_app/core/network/api_endpoints.dart';
import 'package:helpi_app/features/booking/data/order_model.dart'
    hide JobStatus;
import 'package:helpi_app/features/schedule/data/job_model.dart';
import 'package:helpi_app/features/schedule/data/review_model.dart'
    as schedule_review;

/// Wrapper za API rezultat — uspjeh ili greška.
class ApiResult<T> {
  ApiResult.success(this.data) : _success = true, error = null;

  ApiResult.failure(this.error) : _success = false, data = null;

  final bool _success;
  bool get success => _success;
  final T? data;
  final String? error;
}

/// Centralni API servis za helpi_app (Senior + Student).
class AppApiService {
  final ApiClient _client = ApiClient();

  // ──────────────────────────────────────────────
  // SENIOR: Orders
  // ──────────────────────────────────────────────

  /// Dohvati narudžbe za seniora po [seniorId].
  Future<ApiResult<List<OrderModel>>> getOrdersBySenior(int seniorId) async {
    try {
      final response = await _client.get(ApiEndpoints.ordersBySenior(seniorId));
      final list = response.data as List<dynamic>;
      final orders = list
          .map((e) => _mapOrder(e as Map<String, dynamic>))
          .toList();
      return ApiResult.success(orders);
    } catch (e) {
      debugPrint('[AppApiService] getOrdersBySenior error: $e');
      return ApiResult.failure(e.toString());
    }
  }

  /// Kreiraj novu narudžbu.
  Future<ApiResult<OrderModel>> createOrder(
    Map<String, dynamic> orderData,
  ) async {
    try {
      final response = await _client.post(ApiEndpoints.orders, data: orderData);
      final order = _mapOrder(response.data as Map<String, dynamic>);
      return ApiResult.success(order);
    } catch (e) {
      debugPrint('[AppApiService] createOrder error: $e');
      return ApiResult.failure(e.toString());
    }
  }

  /// Otkaži narudžbu.
  Future<ApiResult<bool>> cancelOrder(int orderId, {String? reason}) async {
    try {
      await _client.post(
        ApiEndpoints.orderCancel(orderId),
        data: reason != null ? {'reason': reason} : null,
      );
      return ApiResult.success(true);
    } catch (e) {
      debugPrint('[AppApiService] cancelOrder error: $e');
      return ApiResult.failure(e.toString());
    }
  }

  /// Otkaži pojedinu sesiju (job instance) — student cancel.
  Future<ApiResult<bool>> cancelSession(int sessionId) async {
    try {
      await _client.post(ApiEndpoints.sessionCancel(sessionId));
      return ApiResult.success(true);
    } catch (e) {
      debugPrint('[AppApiService] cancelSession error: $e');
      return ApiResult.failure(e.toString());
    }
  }

  // ──────────────────────────────────────────────
  // PROMO CODES
  // ──────────────────────────────────────────────

  /// Validate promo code — returns validation result from backend.
  Future<ApiResult<Map<String, dynamic>>> validatePromoCode({
    required String code,
    required int customerId,
    required double orderTotal,
  }) async {
    try {
      final response = await _client.post(
        ApiEndpoints.promoCodeValidate,
        queryParameters: {
          'code': code,
          'customerId': customerId,
          'orderTotal': orderTotal,
        },
      );
      return ApiResult.success(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[AppApiService] validatePromoCode error: $e');
      return ApiResult.failure(e.toString());
    }
  }

  /// Apply promo code to order after creation.
  Future<ApiResult<Map<String, dynamic>>> applyPromoCode({
    required String code,
    required int orderId,
    required int customerId,
    required double orderTotal,
  }) async {
    try {
      final response = await _client.post(
        ApiEndpoints.promoCodeApply,
        queryParameters: {
          'code': code,
          'orderId': orderId,
          'customerId': customerId,
          'orderTotal': orderTotal,
        },
      );
      return ApiResult.success(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[AppApiService] applyPromoCode error: $e');
      return ApiResult.failure(e.toString());
    }
  }

  // ──────────────────────────────────────────────
  // PROFILE
  // ──────────────────────────────────────────────

  /// Dohvati profil kupca (Customer) — sadrži Contact + Seniors[].
  Future<ApiResult<Map<String, dynamic>>> getCustomerProfile(
    int customerId,
  ) async {
    try {
      final response = await _client.get(ApiEndpoints.customerById(customerId));
      return ApiResult.success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint(
        '[AppApiService] getCustomerProfile error: '
        'status=${e.response?.statusCode}',
      );
      return ApiResult.failure('HTTP ${e.response?.statusCode}: ${e.message}');
    } catch (e) {
      debugPrint('[AppApiService] getCustomerProfile error: $e');
      return ApiResult.failure(e.toString());
    }
  }

  /// Dohvati profil studenta.
  Future<ApiResult<Map<String, dynamic>>> getStudentProfile(
    int studentId,
  ) async {
    try {
      final response = await _client.get(ApiEndpoints.studentById(studentId));
      return ApiResult.success(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[AppApiService] getStudentProfile error: $e');
      return ApiResult.failure(e.toString());
    }
  }

  // ──────────────────────────────────────────────
  // STUDENT: Sessions / Jobs
  // ──────────────────────────────────────────────

  /// Dohvati sve sesije za studenta.
  Future<ApiResult<List<Job>>> getSessionsByStudent(int studentId) async {
    try {
      final response = await _client.get(
        ApiEndpoints.sessionsByStudent(studentId),
      );
      final list = response.data as List<dynamic>;
      final jobs = list.map((e) => _mapJob(e as Map<String, dynamic>)).toList();
      return ApiResult.success(jobs);
    } catch (e) {
      debugPrint('[AppApiService] getSessionsByStudent error: $e');
      return ApiResult.failure(e.toString());
    }
  }

  /// Dohvati nadolazeće sesije za studenta.
  Future<ApiResult<List<Job>>> getUpcomingSessionsByStudent(
    int studentId,
  ) async {
    try {
      final response = await _client.get(
        ApiEndpoints.sessionsUpcomingByStudent(studentId),
      );
      final list = response.data as List<dynamic>;
      final jobs = list.map((e) => _mapJob(e as Map<String, dynamic>)).toList();
      return ApiResult.success(jobs);
    } catch (e) {
      debugPrint('[AppApiService] getUpcomingSessionsByStudent error: $e');
      return ApiResult.failure(e.toString());
    }
  }

  // ──────────────────────────────────────────────
  // REVIEWS
  // ──────────────────────────────────────────────

  /// Dohvati recenzije za seniora.
  Future<ApiResult<List<schedule_review.ReviewModel>>> getReviewsBySenior(
    int seniorId,
  ) async {
    try {
      final response = await _client.get(
        ApiEndpoints.reviewsBySenior(seniorId),
      );
      final list = response.data as List<dynamic>;
      final reviews = list
          .map((e) => _mapReview(e as Map<String, dynamic>))
          .toList();
      return ApiResult.success(reviews);
    } catch (e) {
      debugPrint('[AppApiService] getReviewsBySenior error: $e');
      return ApiResult.failure(e.toString());
    }
  }

  /// Dohvati pending recenzije za seniora.
  Future<ApiResult<List<schedule_review.ReviewModel>>>
  getPendingReviewsBySenior(int seniorId) async {
    try {
      final response = await _client.get(
        ApiEndpoints.pendingReviewsBySenior(seniorId),
      );
      final list = response.data as List<dynamic>;
      final reviews = list
          .map((e) => _mapReview(e as Map<String, dynamic>))
          .toList();
      return ApiResult.success(reviews);
    } catch (e) {
      debugPrint('[AppApiService] getPendingReviewsBySenior error: $e');
      return ApiResult.failure(e.toString());
    }
  }

  /// Dohvati pending recenzije za studenta (student mora ocijeniti seniora).
  Future<ApiResult<List<schedule_review.ReviewModel>>>
  getPendingReviewsByStudent(int studentId) async {
    try {
      final response = await _client.get(
        ApiEndpoints.pendingReviewsByStudent(studentId),
      );
      final list = response.data as List<dynamic>;
      final reviews = list
          .map((e) => _mapReview(e as Map<String, dynamic>))
          .toList();
      return ApiResult.success(reviews);
    } catch (e) {
      debugPrint('[AppApiService] getPendingReviewsByStudent error: $e');
      return ApiResult.failure(e.toString());
    }
  }

  /// Pošalji recenziju (senior ocjenjuje studenta).
  Future<ApiResult<bool>> submitReview(Map<String, dynamic> reviewData) async {
    try {
      await _client.put(ApiEndpoints.reviews, data: reviewData);
      return ApiResult.success(true);
    } catch (e) {
      debugPrint('[AppApiService] submitReview error: $e');
      return ApiResult.failure(e.toString());
    }
  }

  // ──────────────────────────────────────────────
  // PAYMENT METHODS
  // ──────────────────────────────────────────────

  /// Dohvati kartice (payment methods) za korisnika.
  Future<ApiResult<List<Map<String, dynamic>>>> getPaymentMethods(
    int userId,
  ) async {
    try {
      final response = await _client.get(
        ApiEndpoints.paymentMethodsByUser(userId),
      );
      final list = response.data as List<dynamic>;
      final methods = list.map((e) => e as Map<String, dynamic>).toList();
      return ApiResult.success(methods);
    } catch (e) {
      debugPrint('[AppApiService] getPaymentMethods error: $e');
      return ApiResult.failure(e.toString());
    }
  }

  // ──────────────────────────────────────────────
  // STUDENT AVAILABILITY
  // ──────────────────────────────────────────────

  /// Dohvati dostupnost za studenta.
  Future<ApiResult<List<Map<String, dynamic>>>> getStudentAvailability(
    int studentId,
  ) async {
    try {
      final response = await _client.get(
        ApiEndpoints.availabilityByStudent(studentId),
      );
      final list = response.data as List<dynamic>;
      final slots = list.map((e) => e as Map<String, dynamic>).toList();
      return ApiResult.success(slots);
    } catch (e) {
      debugPrint('[AppApiService] getStudentAvailability error: $e');
      return ApiResult.failure(e.toString());
    }
  }

  /// Spremi dostupnost studenta (bulk update).
  Future<ApiResult<bool>> updateStudentAvailability(
    List<Map<String, dynamic>> slots,
  ) async {
    try {
      await _client.put(ApiEndpoints.availabilityBulkUpdate, data: slots);
      return ApiResult.success(true);
    } catch (e) {
      debugPrint('[AppApiService] updateStudentAvailability error: $e');
      return ApiResult.failure(e.toString());
    }
  }

  // ──────────────────────────────────────────────
  // CONTACT INFO
  // ──────────────────────────────────────────────

  /// Update contact info (profile data: name, phone, address, etc.)
  Future<ApiResult<bool>> updateContactInfo({
    required int contactId,
    required String fullName,
    required String email,
    required String phone,
    required String fullAddress,
    required int gender,
    required String dateOfBirth,
    int cityId = 1,
  }) async {
    try {
      await _client.put(
        ApiEndpoints.contactInfoById(contactId),
        data: {
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'fullAddress': fullAddress,
          'gender': gender,
          'dateOfBirth': dateOfBirth,
          'googlePlaceId': 'app-manual-entry',
          'languageCode': 'hr',
          'country': 'Croatia',
          'cityId': cityId,
        },
      );
      return ApiResult.success(true);
    } catch (e) {
      debugPrint('[AppApiService] updateContactInfo error: $e');
      return ApiResult.failure(e.toString());
    }
  }

  /// Update student-specific fields (facultyId, studentNumber).
  Future<ApiResult<bool>> updateStudent({
    required int studentId,
    int? facultyId,
    String? studentNumber,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (facultyId != null) data['facultyId'] = facultyId;
      if (studentNumber != null) data['studentNumber'] = studentNumber;
      if (data.isEmpty) return ApiResult.success(true);
      await _client.put(ApiEndpoints.studentById(studentId), data: data);
      return ApiResult.success(true);
    } catch (e) {
      debugPrint('[AppApiService] updateStudent error: $e');
      return ApiResult.failure(e.toString());
    }
  }

  // ──────────────────────────────────────────────
  // MAPPERS
  // ──────────────────────────────────────────────

  /// Backend OrderDto → App OrderModel.
  OrderModel _mapOrder(Map<String, dynamic> json) {
    final schedules = json['schedules'] as List<dynamic>? ?? [];
    final services = json['services'] as List<dynamic>? ?? [];

    // Izvuci imena servisa iz translations
    final serviceNames = services.map((s) {
      final translations = s['translations'] as Map<String, dynamic>? ?? {};
      final hr = translations['hr'] as Map<String, dynamic>?;
      return (hr?['name'] as String?) ?? 'Usluga';
    }).toList();

    // Extract service IDs for repeat order
    final serviceIds = services
        .map((s) => (s['id'] as num?)?.toInt())
        .where((id) => id != null)
        .cast<int>()
        .toList();

    // Mapiranje rasporeda u dayEntries
    final dayEntries = schedules.map((s) {
      final sch = s as Map<String, dynamic>;
      final dayOfWeek = (sch['dayOfWeek'] as num?)?.toInt() ?? 1;
      final startTime = _parseTimeOnly(sch['startTime']);
      final endTime = _parseTimeOnly(sch['endTime']);
      final durHours = _durationHours(startTime, endTime);
      return OrderDayEntry(
        dayName: _dayName(dayOfWeek),
        time: _formatTime(startTime),
        duration: '$durHours ${durHours == 1 ? "sat" : "sata"}',
        weekday: dayOfWeek,
        durationHours: durHours,
      );
    }).toList();

    final isRecurring = json['isRecurring'] as bool? ?? false;
    final startDate = _parseDate(json['startDate']);
    final endDate = json['endDate'] != null
        ? _parseDate(json['endDate'])
        : null;

    // Frequency string
    String frequency;
    if (!isRecurring) {
      frequency = 'Jednom';
    } else if (endDate != null) {
      frequency =
          'Do ${endDate.day.toString().padLeft(2, '0')}.${endDate.month.toString().padLeft(2, '0')}.${endDate.year}';
    } else {
      frequency = 'Ponavljajuće';
    }

    // First schedule za time/weekday/duration
    final firstSchedule = schedules.isNotEmpty
        ? schedules[0] as Map<String, dynamic>
        : null;
    final firstStart = firstSchedule != null
        ? _parseTimeOnly(firstSchedule['startTime'])
        : const TimeOfDay(hour: 0, minute: 0);
    final firstEnd = firstSchedule != null
        ? _parseTimeOnly(firstSchedule['endTime'])
        : const TimeOfDay(hour: 0, minute: 0);
    final firstWeekday = (firstSchedule?['dayOfWeek'] as num?)?.toInt() ?? 1;
    final firstDurHours = _durationHours(firstStart, firstEnd);

    return OrderModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      seniorId: (json['seniorId'] as num?)?.toInt().toString() ?? '',
      services: serviceNames,
      serviceIds: serviceIds,
      date: startDate,
      frequency: frequency,
      status: _mapOrderStatus(json['status']),
      notes: json['notes'] as String? ?? '',
      isOneTime: !isRecurring,
      time: _formatTime(firstStart),
      duration: '$firstDurHours ${firstDurHours == 1 ? "sat" : "sata"}',
      dayEntries: dayEntries,
      endDate: endDate,
      weekday: firstWeekday,
      durationHours: firstDurHours,
      fromHour: firstStart.hour,
      fromMinute: firstStart.minute,
    );
  }

  /// Backend SessionDto → App Job.
  Job _mapJob(Map<String, dynamic> json) {
    final date = _parseDate(json['scheduledDate']);
    final startTime = _parseTimeOnly(json['startTime']);
    final endTime = _parseTimeOnly(json['endTime']);

    // Senior name iz nested senior objekt
    String seniorName = '';
    String seniorId = '';
    final senior = json['senior'] as Map<String, dynamic>?;
    if (senior != null) {
      final contact = senior['contact'] as Map<String, dynamic>?;
      seniorName = contact?['fullName'] as String? ?? '';
      seniorId = (senior['id'] as num?)?.toInt().toString() ?? '';
    }

    // Address iz senior kontakta
    String address = '';
    if (senior != null) {
      final contact = senior['contact'] as Map<String, dynamic>?;
      address = contact?['fullAddress'] as String? ?? '';
    }

    // Service types iz order (if available) — fallback to empty
    final serviceTypes = <ServiceType>[];

    // Review iz nested data (if available)
    schedule_review.ReviewModel? review;
    final reviewData = json['review'] as Map<String, dynamic>?;
    if (reviewData != null) {
      review = _mapReview(reviewData);
    }

    return Job(
      id: (json['id'] as num?)?.toInt().toString() ?? '',
      orderId: (json['orderId'] as num?)?.toInt().toString(),
      sessionId: (json['id'] as num?)?.toInt().toString(),
      studentId: _extractStudentId(json),
      seniorId: seniorId,
      date: date,
      from: startTime,
      to: endTime,
      serviceTypes: serviceTypes,
      seniorName: seniorName,
      address: address,
      status: _mapJobStatus(json['status']),
      notes: json['notes'] as String?,
      review: review,
    );
  }

  /// Backend ReviewDto → App ReviewModel.
  schedule_review.ReviewModel _mapReview(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] as String? ?? '';
    String dateStr = '';
    if (createdAt.isNotEmpty) {
      final dt = DateTime.tryParse(createdAt);
      if (dt != null) {
        dateStr =
            '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}.';
      }
    }
    return schedule_review.ReviewModel(
      id: (json['id'] as num?)?.toInt(),
      jobInstanceId: (json['jobInstanceId'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      date: dateStr,
    );
  }

  // ──────────────────────────────────────────────
  // ENUM MAPPERS
  // ──────────────────────────────────────────────

  OrderStatus _mapOrderStatus(dynamic status) {
    if (status is int) {
      switch (status) {
        case 0: // InActive
        case 1: // Pending
          return OrderStatus.processing;
        case 2: // FullAssigned
          return OrderStatus.active;
        case 3: // Completed
          return OrderStatus.completed;
        case 4: // Cancelled
          return OrderStatus.cancelled;
        default:
          return OrderStatus.processing;
      }
    }
    final s = status?.toString().toLowerCase() ?? '';
    if (s.contains('inactive') || s.contains('pending')) {
      return OrderStatus.processing;
    }
    if (s.contains('fullassigned')) return OrderStatus.active;
    if (s.contains('completed')) return OrderStatus.completed;
    if (s.contains('cancelled')) return OrderStatus.cancelled;
    return OrderStatus.processing;
  }

  JobStatus _mapJobStatus(dynamic status) {
    if (status is int) {
      switch (status) {
        case 0: // Upcoming
        case 1: // InProgress
          return JobStatus.scheduled;
        case 2: // Completed
          return JobStatus.completed;
        case 3: // Cancelled
        case 4: // Rescheduled
          return JobStatus.cancelled;
        default:
          return JobStatus.scheduled;
      }
    }
    final s = status?.toString().toLowerCase() ?? '';
    if (s.contains('completed')) return JobStatus.completed;
    if (s.contains('cancelled') || s.contains('rescheduled')) {
      return JobStatus.cancelled;
    }
    return JobStatus.scheduled;
  }

  // ──────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────

  /// Parse "HH:mm:ss" or "HH:mm" → TimeOfDay.
  TimeOfDay _parseTimeOnly(dynamic value) {
    if (value == null) return const TimeOfDay(hour: 0, minute: 0);
    final parts = value.toString().split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  /// Parse date string (ISO or DateOnly "yyyy-MM-dd") → DateTime.
  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int _durationHours(TimeOfDay start, TimeOfDay end) {
    final startMin = start.hour * 60 + start.minute;
    final endMin = end.hour * 60 + end.minute;
    final diff = endMin - startMin;
    return diff > 0 ? (diff / 60).round() : 0;
  }

  String _dayName(int weekday) {
    const names = [
      '',
      'Ponedjeljak',
      'Utorak',
      'Srijeda',
      'Četvrtak',
      'Petak',
      'Subota',
      'Nedjelja',
    ];
    return weekday >= 1 && weekday <= 7 ? names[weekday] : '';
  }

  String _extractStudentId(Map<String, dynamic> json) {
    final assignment = json['scheduleAssignment'] as Map<String, dynamic>?;
    if (assignment == null) return '';
    final student = assignment['student'] as Map<String, dynamic>?;
    if (student == null) return '';
    return student['userId']?.toString() ?? '';
  }
}
