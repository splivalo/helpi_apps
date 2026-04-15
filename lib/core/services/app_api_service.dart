import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/network/api_client.dart';
import 'package:helpi_app/core/network/api_endpoints.dart';
import 'package:helpi_app/features/booking/data/order_model.dart'
    hide JobStatus;
import 'package:helpi_app/features/schedule/data/job_model.dart';
import 'package:helpi_app/features/schedule/data/review_model.dart'
    as schedule_review;

/// Wrapper for API result - success or error.
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

  /// Pretvara iznimku u user-friendly poruku greške.
  static String friendlyError(Object e) {
    if (e is DioException) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 403) return AppStrings.suspendedMessage;
      if (statusCode == 404) return AppStrings.error;
      if (statusCode != null && statusCode >= 500) {
        return AppStrings.serverError;
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return AppStrings.networkError;
      }
    }
    return AppStrings.error;
  }

  // --
  // SENIOR: Orders
  // --

  /// Fetch orders for senior by [seniorId].
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
      return ApiResult.failure(friendlyError(e));
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
      return ApiResult.failure(friendlyError(e));
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
      return ApiResult.failure(friendlyError(e));
    }
  }

  /// Fetch single order by [orderId].
  Future<ApiResult<OrderModel>> getOrderById(int orderId) async {
    try {
      final response = await _client.get(ApiEndpoints.orderById(orderId));
      final order = _mapOrder(response.data as Map<String, dynamic>);
      return ApiResult.success(order);
    } catch (e) {
      debugPrint('[AppApiService] getOrderById error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  /// Otkaži pojedinu sesiju (job instance) - student cancel.
  Future<ApiResult<bool>> cancelSession(int sessionId) async {
    try {
      await _client.post(ApiEndpoints.sessionCancel(sessionId));
      return ApiResult.success(true);
    } catch (e) {
      debugPrint('[AppApiService] cancelSession error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  // SPONSORS

  /// Fetch first active sponsor from backend.
  Future<ApiResult<Map<String, dynamic>?>> getActiveSponsor() async {
    try {
      final response = await _client.get(ApiEndpoints.sponsorsActive);
      final list = response.data as List<dynamic>;
      if (list.isEmpty) return ApiResult.success(null);
      return ApiResult.success(list.first as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[AppApiService] getActiveSponsor error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  // PRICING CONFIGURATION

  /// Fetch pricing configuration from backend.
  Future<ApiResult<Map<String, dynamic>>> fetchPricingConfig() async {
    try {
      final response = await _client.get(ApiEndpoints.pricingConfig);
      return ApiResult.success(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[AppApiService] fetchPricingConfig error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  // PROMO CODES

  /// Validate promo code - returns validation result from backend.
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
      return ApiResult.failure(friendlyError(e));
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
      return ApiResult.failure(friendlyError(e));
    }
  }

  // PROFILE

  /// Fetch customer profile (Customer) - contains Contact + Seniors[].
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
      return ApiResult.failure(friendlyError(e));
    } catch (e) {
      debugPrint('[AppApiService] getCustomerProfile error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  /// Fetch student profile.
  Future<ApiResult<Map<String, dynamic>>> getStudentProfile(
    int studentId,
  ) async {
    try {
      final response = await _client.get(ApiEndpoints.studentById(studentId));
      return ApiResult.success(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[AppApiService] getStudentProfile error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  // STUDENT: Sessions / Jobs

  /// Fetch sessions for a specific order (used in senior order detail).
  /// Returns raw JSON maps so caller can extract student name etc.
  Future<ApiResult<List<Map<String, dynamic>>>> getSessionsByOrder(
    int orderId,
  ) async {
    try {
      final response = await _client.get(ApiEndpoints.sessionsByOrder(orderId));
      final list = response.data as List<dynamic>;
      return ApiResult.success(
        list.map((e) => e as Map<String, dynamic>).toList(),
      );
    } catch (e) {
      debugPrint('[AppApiService] getSessionsByOrder error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  /// Fetch all sessions for student.
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
      return ApiResult.failure(friendlyError(e));
    }
  }

  /// Fetch upcoming sessions for student.
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
      return ApiResult.failure(friendlyError(e));
    }
  }

  // REVIEWS

  /// Fetch reviews for senior.
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
      return ApiResult.failure(friendlyError(e));
    }
  }

  /// Fetch pending reviews for senior.
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
      return ApiResult.failure(friendlyError(e));
    }
  }

  /// Fetch pending reviews for student (student must rate senior).
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
      return ApiResult.failure(friendlyError(e));
    }
  }

  /// Submit review (senior rates student).
  Future<ApiResult<bool>> submitReview(Map<String, dynamic> reviewData) async {
    try {
      await _client.put(ApiEndpoints.reviews, data: reviewData);
      return ApiResult.success(true);
    } catch (e) {
      debugPrint('[AppApiService] submitReview error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  /// Ensure session is completed (triggers backend completion if time passed).
  Future<ApiResult<bool>> ensureSessionCompleted(int sessionId) async {
    try {
      await _client.post(ApiEndpoints.sessionEnsureCompleted(sessionId));
      return ApiResult.success(true);
    } catch (e) {
      debugPrint('[AppApiService] ensureSessionCompleted error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  // PAYMENT METHODS

  /// Fetch cards (payment methods) for user.
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
      return ApiResult.failure(friendlyError(e));
    }
  }

  /// Create payment method without forcing Stripe flow in the app layer.
  Future<ApiResult<Map<String, dynamic>>> createPaymentMethod(
    Map<String, dynamic> paymentMethodData,
  ) async {
    try {
      final response = await _client.post(
        ApiEndpoints.paymentMethodsCreate,
        data: paymentMethodData,
      );
      return ApiResult.success(response.data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[AppApiService] createPaymentMethod error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  /// Delete payment method by its local backend ID.
  Future<ApiResult<bool>> deletePaymentMethod(int paymentMethodId) async {
    try {
      await _client.delete(ApiEndpoints.paymentMethodDelete(paymentMethodId));
      return ApiResult.success(true);
    } catch (e) {
      debugPrint('[AppApiService] deletePaymentMethod error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  // NOTIFICATIONS

  /// Fetch all notifications for user.
  Future<ApiResult<List<Map<String, dynamic>>>> getNotificationsByUser(
    int userId, {
    String languageCode = 'hr',
  }) async {
    try {
      final response = await _client.get(
        ApiEndpoints.notificationsByUser(userId),
        queryParameters: {'languageCode': languageCode},
      );
      final list = response.data as List<dynamic>;
      final notifications = list.map((e) => e as Map<String, dynamic>).toList();
      return ApiResult.success(notifications);
    } catch (e) {
      debugPrint('[AppApiService] getNotificationsByUser error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  /// Fetch unread notifications for user.
  Future<ApiResult<List<Map<String, dynamic>>>> getUnreadNotificationsByUser(
    int userId, {
    String languageCode = 'hr',
  }) async {
    try {
      final response = await _client.get(
        ApiEndpoints.notificationsUnread(userId),
        queryParameters: {'languageCode': languageCode},
      );
      final list = response.data as List<dynamic>;
      final notifications = list.map((e) => e as Map<String, dynamic>).toList();
      return ApiResult.success(notifications);
    } catch (e) {
      debugPrint('[AppApiService] getUnreadNotificationsByUser error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  /// Fetch unread notification count for user.
  Future<ApiResult<int>> getUnreadNotificationCount(int userId) async {
    try {
      final response = await _client.get(
        ApiEndpoints.notificationsUnreadCount(userId),
      );
      final count = (response.data as num?)?.toInt() ?? 0;
      return ApiResult.success(count);
    } catch (e) {
      debugPrint('[AppApiService] getUnreadNotificationCount error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  /// Mark notification as read.
  Future<ApiResult<bool>> markNotificationAsRead(int notificationId) async {
    try {
      await _client.put('/api/HNotifications/$notificationId/mark-read');
      return ApiResult.success(true);
    } catch (e) {
      debugPrint('[AppApiService] markNotificationAsRead error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  /// Mark all user notifications as read.
  Future<ApiResult<bool>> markAllNotificationsAsRead(int userId) async {
    try {
      await _client.put('/api/HNotifications/user/$userId/mark-all-read');
      return ApiResult.success(true);
    } catch (e) {
      debugPrint('[AppApiService] markAllNotificationsAsRead error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  // LOOKUPS

  /// Fetch all cities.
  Future<ApiResult<List<Map<String, dynamic>>>> getCities() async {
    try {
      final response = await _client.get(ApiEndpoints.cities);
      final list = response.data as List<dynamic>;
      final cities = list.map((e) => e as Map<String, dynamic>).toList();
      return ApiResult.success(cities);
    } catch (e) {
      debugPrint('[AppApiService] getCities error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  /// Fetch all service categories.
  Future<ApiResult<List<Map<String, dynamic>>>> getServiceCategories() async {
    try {
      final response = await _client.get(ApiEndpoints.services);
      final list = response.data as List<dynamic>;
      final categories = list.map((e) => e as Map<String, dynamic>).toList();
      return ApiResult.success(categories);
    } catch (e) {
      debugPrint('[AppApiService] getServiceCategories error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  // DASHBOARD

  /// Fetch senior dashboard tiles.
  Future<ApiResult<List<Map<String, dynamic>>>> getSeniorDashboard(
    int seniorId,
  ) async {
    try {
      final response = await _client.get(
        ApiEndpoints.dashboardSenior(seniorId),
      );
      final list = response.data as List<dynamic>;
      final tiles = list.map((e) => e as Map<String, dynamic>).toList();
      return ApiResult.success(tiles);
    } catch (e) {
      debugPrint('[AppApiService] getSeniorDashboard error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  /// Fetch student dashboard tiles.
  Future<ApiResult<List<Map<String, dynamic>>>> getStudentDashboard(
    int studentId,
  ) async {
    try {
      final response = await _client.get(
        ApiEndpoints.dashboardStudent(studentId),
      );
      final list = response.data as List<dynamic>;
      final tiles = list.map((e) => e as Map<String, dynamic>).toList();
      return ApiResult.success(tiles);
    } catch (e) {
      debugPrint('[AppApiService] getStudentDashboard error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  /// Fetch completed sessions for student.
  Future<ApiResult<List<Job>>> getCompletedSessionsByStudent(
    int studentId,
  ) async {
    try {
      final response = await _client.get(
        ApiEndpoints.sessionsCompletedByStudent(studentId),
      );
      final list = response.data as List<dynamic>;
      final jobs = list.map((e) => _mapJob(e as Map<String, dynamic>)).toList();
      return ApiResult.success(jobs);
    } catch (e) {
      debugPrint('[AppApiService] getCompletedSessionsByStudent error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  /// Fetch completed sessions for senior.
  Future<ApiResult<List<Job>>> getCompletedSessionsBySenior(
    int seniorId,
  ) async {
    try {
      final response = await _client.get(
        ApiEndpoints.sessionsCompletedBySenior(seniorId),
      );
      final list = response.data as List<dynamic>;
      final jobs = list.map((e) => _mapJob(e as Map<String, dynamic>)).toList();
      return ApiResult.success(jobs);
    } catch (e) {
      debugPrint('[AppApiService] getCompletedSessionsBySenior error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  // STUDENT AVAILABILITY

  /// Fetch availability for student.
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
      return ApiResult.failure(friendlyError(e));
    }
  }

  /// Save student availability (bulk update).
  Future<ApiResult<bool>> updateStudentAvailability(
    List<Map<String, dynamic>> slots,
  ) async {
    try {
      await _client.put(ApiEndpoints.availabilityBulkUpdate, data: slots);
      return ApiResult.success(true);
    } catch (e) {
      debugPrint('[AppApiService] updateStudentAvailability error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  // CONTACT INFO

  /// Update contact info (profile data: name, phone, address, etc.)
  Future<ApiResult<bool>> updateContactInfo({
    required int contactId,
    required String fullName,
    required String email,
    required String phone,
    required String fullAddress,
    required int gender,
    required String dateOfBirth,
    String googlePlaceId = 'app-manual-entry',
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
          'googlePlaceId': googlePlaceId,
          'languageCode': 'hr',
          'country': 'Croatia',
          'cityId': cityId,
        },
      );
      return ApiResult.success(true);
    } catch (e) {
      debugPrint('[AppApiService] updateContactInfo error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  /// Update student-specific fields (facultyId).
  Future<ApiResult<bool>> updateStudent({
    required int studentId,
    int? facultyId,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (facultyId != null) data['facultyId'] = facultyId;
      if (data.isEmpty) return ApiResult.success(true);
      await _client.put(ApiEndpoints.studentById(studentId), data: data);
      return ApiResult.success(true);
    } catch (e) {
      debugPrint('[AppApiService] updateStudent error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  // MAPPERS

  /// Backend OrderDto â†’ App OrderModel.
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

    // Mapping schedule to dayEntries
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
      frequency = 'Ponavljajuce';
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
      orderNumber: (json['orderNumber'] as num?)?.toInt() ?? 0,
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

  /// Backend SessionDto â†’ App Job.
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

    // Service types from order (via backend Services list)
    final serviceTypes = <ServiceType>[];
    final servicesJson = json['services'] as List<dynamic>?;
    if (servicesJson != null) {
      for (final svc in servicesJson) {
        final svcMap = svc as Map<String, dynamic>;
        final id = (svcMap['id'] as num?)?.toInt();
        final mapped = _mapServiceId(id);
        if (mapped != null) serviceTypes.add(mapped);
      }
    }

    // Review iz nested data — student's review of senior (studentReview)
    schedule_review.ReviewModel? review;
    final reviewData = json['studentReview'] as Map<String, dynamic>?;
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
      canCancel: json['canCancel'] as bool?,
    );
  }

  /// Backend ReviewDto â†’ App ReviewModel.
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

  // ENUM MAPPERS

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

  /// Maps backend service ID to ServiceType enum.
  /// IDs: 1=Companionship, 4=Walking, 11=Shopping, 21=HouseHelp, 31=Escort, 41=Other
  ServiceType? _mapServiceId(int? id) {
    switch (id) {
      case 1:
        return ServiceType.companionship;
      case 4:
        return ServiceType.walking;
      case 11:
        return ServiceType.shopping;
      case 21:
        return ServiceType.houseHelp;
      case 31:
        return ServiceType.escort;
      case 41:
        return ServiceType.other;
      default:
        return null;
    }
  }

  // --
  // HELPERS
  // --

  /// Parse "HH:mm:ss" or "HH:mm" â†’ TimeOfDay.
  TimeOfDay _parseTimeOnly(dynamic value) {
    if (value == null) return const TimeOfDay(hour: 0, minute: 0);
    final parts = value.toString().split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  /// Parse date string (ISO or DateOnly "yyyy-MM-dd") â†’ DateTime.
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
      'Cetvrtak',
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

  // --
  // PROFILE IMAGE
  // --

  /// Upload profile image for a contact. Returns the URL on success.
  Future<ApiResult<String>> uploadProfileImage({
    required int contactId,
    required String filePath,
  }) async {
    try {
      final fileName = filePath.split('/').last.split('\\').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final response = await _client.dio.post(
        '${ApiEndpoints.contactInfoById(contactId)}/profile-image',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final url =
          (response.data as Map<String, dynamic>)['profileImageUrl'] as String;
      return ApiResult.success(url);
    } catch (e) {
      debugPrint('[AppApiService] uploadProfileImage error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }

  /// Delete profile image for a contact.
  Future<ApiResult<bool>> deleteProfileImage({required int contactId}) async {
    try {
      await _client.delete(
        '${ApiEndpoints.contactInfoById(contactId)}/profile-image',
      );
      return ApiResult.success(true);
    } catch (e) {
      debugPrint('[AppApiService] deleteProfileImage error: $e');
      return ApiResult.failure(friendlyError(e));
    }
  }
}
