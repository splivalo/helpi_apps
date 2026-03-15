import 'package:dio/dio.dart';
import '../l10n/app_strings.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/token_storage.dart';

/// Maps backend UserType enum int to string.
String _userTypeFromInt(int value) {
  switch (value) {
    case 0:
      return 'Admin';
    case 1:
      return 'Student';
    case 2:
      return 'Customer';
    default:
      return 'Unknown';
  }
}

class AuthResult {
  final bool success;
  final String? message;
  final int? userId;
  final String? userType;

  const AuthResult({
    required this.success,
    this.message,
    this.userId,
    this.userType,
  });
}

class AuthService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage(),
      _apiClient = apiClient ?? ApiClient();

  /// Returns `true` if a user with [email] already exists on the backend.
  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.checkEmail,
        queryParameters: {'email': email},
      );
      final data = response.data as Map<String, dynamic>;
      return data['exists'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      final body = response.data as Map<String, dynamic>;
      final token = body['token'] as String;
      final userId = body['userId'] as int;
      final rawUserType = body['userType'];
      final userType = rawUserType is int
          ? _userTypeFromInt(rawUserType)
          : '$rawUserType';

      await _tokenStorage.saveToken(token);
      await _tokenStorage.saveUserId(userId);
      await _tokenStorage.saveUserType(userType);

      return AuthResult(
        success: true,
        message: body['message'] as String?,
        userId: userId,
        userType: userType,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return AuthResult(
          success: false,
          message: AppStrings.invalidCredentials,
        );
      }
      return AuthResult(success: false, message: AppStrings.loginError);
    } catch (_) {
      return AuthResult(success: false, message: AppStrings.loginError);
    }
  }

  /// Register a new Customer (Senior) user.
  Future<AuthResult> registerCustomer({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String gender,
    required DateTime dateOfBirth,
    required String fullAddress,
    required int cityId,
    required String googlePlaceId,
    required double lat,
    required double lng,
    bool orderingForOther = false,
    String? seniorFullName,
    String? seniorPhone,
    String? seniorGender,
    DateTime? seniorDob,
    String? seniorAddress,
  }) async {
    try {
      final contactInfo = {
        'fullName': fullName,
        'phone': phone,
        'gender': gender == 'M' ? 0 : 1,
        'dateOfBirth':
            '${dateOfBirth.year}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}',
        'fullAddress': fullAddress,
        'cityId': cityId,
        'googlePlaceId': googlePlaceId,
        'latitude': lat,
        'longitude': lng,
        'country': 'Croatia',
      };

      final body = <String, dynamic>{
        'email': email,
        'password': password,
        'userType': 2,
        'relationship': orderingForOther ? 4 : 0,
        'preferredNotificationMethod': 0,
        'contactInfo': contactInfo,
      };

      if (orderingForOther &&
          seniorFullName != null &&
          seniorPhone != null &&
          seniorDob != null) {
        body['seniorContactInfo'] = {
          'fullName': seniorFullName,
          'phone': seniorPhone,
          'gender': (seniorGender ?? 'F') == 'M' ? 0 : 1,
          'dateOfBirth':
              '${seniorDob.year}-${seniorDob.month.toString().padLeft(2, '0')}-${seniorDob.day.toString().padLeft(2, '0')}',
          'fullAddress': seniorAddress ?? fullAddress,
          'cityId': cityId,
          'googlePlaceId': googlePlaceId,
          'latitude': lat,
          'longitude': lng,
          'country': 'Croatia',
        };
      }

      await _apiClient.post(ApiEndpoints.registerCustomer, data: body);

      return const AuthResult(success: true, message: 'Registracija uspješna!');
    } on DioException catch (e) {
      return AuthResult(
        success: false,
        message: _extractErrorMessage(e) ?? AppStrings.registrationError,
      );
    } catch (_) {
      return AuthResult(success: false, message: AppStrings.registrationError);
    }
  }

  /// Register a new Student user.
  Future<AuthResult> registerStudent({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String gender,
    required DateTime dateOfBirth,
    required String fullAddress,
    required int cityId,
    required String googlePlaceId,
    required double lat,
    required double lng,
    String? studentNumber,
    int? facultyId,
  }) async {
    try {
      final contactInfo = {
        'fullName': fullName,
        'phone': phone,
        'gender': gender == 'M' ? 0 : 1,
        'dateOfBirth':
            '${dateOfBirth.year}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}',
        'fullAddress': fullAddress,
        'cityId': cityId,
        'googlePlaceId': googlePlaceId,
        'latitude': lat,
        'longitude': lng,
        'country': 'Croatia',
      };

      final body = <String, dynamic>{
        'email': email,
        'password': password,
        'userType': 1,
        'contactInfo': contactInfo,
      };

      if (studentNumber != null && studentNumber.isNotEmpty) {
        body['studentNumber'] = studentNumber;
      }
      if (facultyId != null) {
        body['facultyId'] = facultyId;
      }

      await _apiClient.post(ApiEndpoints.registerStudent, data: body);

      return const AuthResult(success: true, message: 'Registracija uspješna!');
    } on DioException catch (e) {
      return AuthResult(
        success: false,
        message: _extractErrorMessage(e) ?? AppStrings.registrationError,
      );
    } catch (_) {
      return AuthResult(success: false, message: AppStrings.registrationError);
    }
  }

  Future<AuthResult> deleteAccount() async {
    try {
      final userId = await _tokenStorage.getUserId();
      final userType = await _tokenStorage.getUserType();
      if (userId == null || userType == null) {
        return AuthResult(
          success: false,
          message: AppStrings.deleteAccountError,
        );
      }

      final endpoint = userType == 'Student'
          ? ApiEndpoints.studentById(userId)
          : ApiEndpoints.customerById(userId);

      await _apiClient.delete(endpoint);
      await _tokenStorage.clearAll();
      return AuthResult(
        success: true,
        message: AppStrings.deleteAccountSuccess,
      );
    } on DioException catch (_) {
      return AuthResult(success: false, message: AppStrings.deleteAccountError);
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clearAll();
  }

  Future<bool> isLoggedIn() async {
    return _tokenStorage.hasToken();
  }

  Future<int?> getCurrentUserId() async {
    return _tokenStorage.getUserId();
  }

  Future<String?> getCurrentUserType() async {
    return _tokenStorage.getUserType();
  }

  Future<AuthResult> changePassword(
    String currentPassword,
    String newPassword,
    String confirmNewPassword,
  ) async {
    try {
      await _apiClient.post(
        ApiEndpoints.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmNewPassword': confirmNewPassword,
        },
      );
      return AuthResult(
        success: true,
        message: AppStrings.resetPasswordSuccess,
      );
    } on DioException catch (_) {
      return AuthResult(success: false, message: AppStrings.loginError);
    }
  }

  Future<AuthResult> forgotPassword(String email) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
      final body = response.data as Map<String, dynamic>;
      return AuthResult(
        success: body['success'] as bool? ?? true,
        message: body['message'] as String?,
      );
    } on DioException catch (e) {
      final msg = (e.response?.data is Map<String, dynamic>)
          ? (e.response!.data as Map<String, dynamic>)['message'] as String?
          : null;
      return AuthResult(success: false, message: msg ?? AppStrings.loginError);
    }
  }

  Future<AuthResult> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.resetPassword,
        data: {'email': email, 'code': code, 'newPassword': newPassword},
      );
      final body = response.data as Map<String, dynamic>;
      return AuthResult(
        success: body['success'] as bool? ?? true,
        message: body['message'] as String?,
      );
    } on DioException catch (_) {
      return AuthResult(success: false, message: AppStrings.loginError);
    }
  }

  /// Extracts a human-readable error message from a Dio error response.
  /// Handles both `{ "message": "..." }` and ASP.NET validation errors
  /// `{ "title": "...", "errors": { "field": ["msg"] } }`.
  String? _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is String && data.isNotEmpty) return data;
    if (data is Map<String, dynamic>) {
      // Standard: { "message": "..." }
      final msg = data['message'] as String?;
      if (msg != null && msg.isNotEmpty) return msg;

      // ASP.NET validation: { "title": "...", "errors": { ... } }
      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        final msgs = <String>[];
        for (final entry in errors.values) {
          if (entry is List) {
            for (final e in entry) {
              msgs.add('$e');
            }
          }
        }
        if (msgs.isNotEmpty) return msgs.join('; ');
      }

      final title = data['title'] as String?;
      if (title != null && title.isNotEmpty) return title;
    }
    return null;
  }
}
