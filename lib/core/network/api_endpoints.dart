import 'dart:io' show Platform;

class ApiEndpoints {
  ApiEndpoints._();

  // Base — Android emulator maps 10.0.2.2 to host machine's localhost
  static final String baseUrl = Platform.isAndroid
      ? 'http://10.0.2.2:5142'
      : 'http://localhost:5142';

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

  // Job Instances (sessions)
  static const String jobInstances = '/api/job-instances';

  // Customers
  static const String customers = '/api/customers';
  static String customerById(int id) => '/api/customers/$id';

  // Students
  static const String students = '/api/students';
  static String studentById(int id) => '/api/students/$id';

  // Reviews
  static const String reviews = '/api/reviews';

  // Notifications
  static const String notifications = '/api/notifications';

  // Payment Methods
  static const String paymentMethods = '/api/payment-methods';

  // Cities
  static const String cities = '/api/cities';

  // Services
  static const String services = '/api/service-categories';

  // Chat
  static const String chat = '/api/chat';

  // Faculties
  static const String faculties = '/api/faculties';

  // Dashboard
  static const String dashboard = '/api/dashboard';
}
