import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';

/// Custom application exception wrapping API errors.
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  final String message;
  final int? statusCode;
  final List<dynamic>? errors;

  @override
  String toString() => message;

  factory ApiException.fromDioException(DioException dioException) {
    String errorMessage = 'A network error occurred. Please try again.';
    int? code = dioException.response?.statusCode;
    List<dynamic>? errorsList;

    if (dioException.type == DioExceptionType.connectionTimeout ||
        dioException.type == DioExceptionType.sendTimeout ||
        dioException.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Connection timed out. Please check your network.';
    } else if (dioException.type == DioExceptionType.connectionError) {
      errorMessage = 'Cannot reach the MoneyPilot server. Ensure backend is running.';
    } else if (dioException.response?.data is Map<String, dynamic>) {
      final data = dioException.response!.data as Map<String, dynamic>;
      if (data['message'] != null) {
        errorMessage = data['message'].toString();
      } else if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
        errorsList = data['errors'] as List;
        final firstError = errorsList.first;
        if (firstError is Map && firstError['msg'] != null) {
          errorMessage = firstError['msg'].toString();
        }
      }
    }

    return ApiException(
      message: errorMessage,
      statusCode: code,
      errors: errorsList,
    );
  }
}

/// Centralized API HTTP Client powered by Dio.
class ApiClient {
  ApiClient({
    required this.secureStorage,
    String? baseUrl,
    OnUnauthorizedCallback? onUnauthorized,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      AuthInterceptor(
        secureStorage: secureStorage,
        onUnauthorized: onUnauthorized,
      ),
    );
  }

  final SecureStorageService secureStorage;
  late final Dio _dio;

  Dio get dio => _dio;

  /// Convenience GET request with exception translation
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Convenience POST request with exception translation
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Convenience PUT request with exception translation
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Convenience DELETE request with exception translation
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

/// Riverpod provider for [ApiClient].
final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return ApiClient(secureStorage: secureStorage);
});
