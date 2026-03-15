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
}
