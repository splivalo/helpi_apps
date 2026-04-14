import 'package:dio/dio.dart';
import 'api_endpoints.dart';
import 'token_storage.dart';

/// Callback for suspension - called from interceptor.
typedef SuspensionCallback = void Function(String? reason);

/// Dio HTTP klijent s automatskim JWT umetanjem.
class ApiClient {
  late final Dio _dio;
  final TokenStorage _tokenStorage;

  /// Postavlja se jednom iz App widgeta.
  static SuspensionCallback? onSuspended;

  ApiClient({TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _tokenStorage.clearAll();
          } else if (error.response?.statusCode == 403) {
            final data = error.response?.data;
            if (data is Map<String, dynamic> &&
                data['error'] == 'AccountSuspended') {
              final reason = data['reason'] as String?;
              onSuspended?.call(reason);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) => _dio.get(path, queryParameters: queryParameters);

  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) => _dio.post(path, data: data, queryParameters: queryParameters);

  Future<Response<dynamic>> put(String path, {Object? data}) =>
      _dio.put(path, data: data);

  Future<Response<dynamic>> delete(String path) => _dio.delete(path);

  Future<Response<dynamic>> patch(String path, {Object? data}) =>
      _dio.patch(path, data: data);

  /// Raw Dio instance for multipart uploads etc.
  Dio get dio => _dio;
}
