import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

/// Callback signature when an unauthenticated / expired token response is received.
typedef OnUnauthorizedCallback = void Function();

/// Dio Interceptor that automatically injects `Authorization: Bearer <JWT>`
/// and clears the stored token upon receiving an HTTP 401 response.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.secureStorage,
    this.onUnauthorized,
  });

  final SecureStorageService secureStorage;
  final OnUnauthorizedCallback? onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Avoid sending token for login or register endpoints
    final isAuthEndpoint = options.path.contains('/api/auth/login') ||
        options.path.contains('/api/auth/register');

    if (!isAuthEndpoint) {
      final token = await secureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Clear token from secure storage
      await secureStorage.deleteToken();
      // Notify listeners to redirect user to login
      onUnauthorized?.call();
    }

    return handler.next(err);
  }
}
