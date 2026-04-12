import 'dart:io' show Platform;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Android emulator koristi 10.0.2.2 za pristup host localhost-u
  // Za fizički uređaj: postavi API_BASE_URL u .env na svoju LAN IP
  static final String baseUrl =
      dotenv.env['API_BASE_URL'] ??
      (Platform.isAndroid ? 'http://10.0.2.2:5142' : 'http://localhost:5142');

  // Auth
  static const String login = '/api/auth/login';
  static const String registerCustomer = '/api/auth/register/customer';
  static const String registerStudent = '/api/auth/register/student';
  static const String checkEmail = '/api/auth/check-email';
  static const String changePassword = '/api/auth/change-password';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password-code';

  // Orders
  static const String orders = '/api/orders';
  static String ordersBySenior(int seniorId) => '/api/orders/senior/$seniorId';
  static String orderById(int id) => '/api/orders/$id';
  static String orderCancel(int id) => '/api/orders/$id/cancel';

  // Sessions (formerly job-instances)
  static const String sessions = '/api/sessions';
  static String sessionsByStudent(int studentId) =>
      '/api/sessions/student/$studentId';
  static String sessionsUpcomingByStudent(int studentId) =>
      '/api/sessions/upcoming/student/$studentId';
  static String sessionsCompletedByStudent(int studentId) =>
      '/api/sessions/completed/student/$studentId';
  static String sessionsCompletedBySenior(int seniorId) =>
      '/api/sessions/completed/senior/$seniorId';
  static String sessionCancel(int id) => '/api/sessions/$id/cancel';

  // Legacy alias
  static const String jobInstances = '/api/sessions';

  // Customers
  static const String customers = '/api/customers';
  static String customerById(int id) => '/api/customers/$id';

  // Students
  static const String students = '/api/students';
  static String studentById(int id) => '/api/students/$id';

  // Reviews
  static const String reviews = '/api/reviews';
  static String reviewsByStudent(int studentId) =>
      '/api/reviews/student/$studentId';
  static String reviewsBySenior(int seniorId) =>
      '/api/reviews/senior/$seniorId';
  static String pendingReviewsBySenior(int seniorId) =>
      '/api/reviews/senior/$seniorId/pending';
  static String pendingReviewsByStudent(int studentId) =>
      '/api/reviews/student/$studentId/pending';

  // Notifications
  static String notificationsByUser(int userId) =>
      '/api/HNotifications/user/$userId';
  static String notificationsUnread(int userId) =>
      '/api/HNotifications/user/$userId/unread';
  static String notificationsUnreadCount(int userId) =>
      '/api/HNotifications/user/$userId/unread-count';

  // Payment Methods
  static String paymentMethodsByUser(int userId) =>
      '/api/payment-methods/user/$userId';
  static const String paymentMethodsCreate = '/api/payment-methods';
  static String paymentMethodDelete(int id) => '/api/payment-methods/$id';

  // Cities
  static const String cities = '/api/cities';

  // Services
  static const String services = '/api/service-categories';

  // Chat
  static const String chatRooms = '/api/chat/rooms';
  static String chatMessages(int roomId) => '/api/chat/rooms/$roomId/messages';
  static String chatMarkRead(int roomId) => '/api/chat/rooms/$roomId/read';
  static const String chatUnreadCount = '/api/chat/unread-count';

  // Faculties
  static const String faculties = '/api/faculties';

  // Student Availability
  static String availabilityByStudent(int studentId) =>
      '/api/student-availability-slots/student/$studentId';
  static const String availabilityBulkUpdate =
      '/api/student-availability-slots/bulk';

  // Dashboard
  static String dashboardSenior(int seniorId) =>
      '/api/dashboard/senior/$seniorId';
  static String dashboardStudent(int studentId) =>
      '/api/dashboard/student/$studentId';

  // Contact Infos
  static const String contactInfos = '/api/contact-infos';
  static String contactInfoById(int id) => '/api/contact-infos/$id';

  // Promo Codes
  static const String promoCodeValidate = '/api/promo-codes/validate';
  static const String promoCodeApply = '/api/promo-codes/apply';

  // Pricing Configuration
  static const String pricingConfig = '/api/PricingConfiguration/1';
}
