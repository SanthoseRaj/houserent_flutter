import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/session_storage.dart';
import 'api_exception.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(sessionStorageProvider);
  return ApiClient(storage);
});

class ApiClient {
  ApiClient(this._sessionStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final session = await _sessionStorage.loadSession();
          final token = session?.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final SessionStorage _sessionStorage;
  late final Dio _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<dynamic> patch(String path, {dynamic data}) async {
    try {
      final response = await _dio.patch(path, data: data);
      return response.data;
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<dynamic> postForm(String path, FormData data) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  String? _extractValidationMessage(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final details = data['details'];
    if (details is! List) {
      return null;
    }

    final messages = details
        .whereType<Map<String, dynamic>>()
        .map((detail) => detail['msg']?.toString().trim() ?? '')
        .where((message) => message.isNotEmpty)
        .toSet()
        .toList();

    if (messages.isEmpty) {
      return null;
    }

    return messages.first;
  }

  ApiException _mapDioError(DioException error) {
    final data = error.response?.data;
    final isNetworkIssue =
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        (kIsWeb &&
            error.response == null &&
            (error.message?.contains('XMLHttpRequest error') ?? false));

    if (isNetworkIssue) {
      return ApiException(
        'Cannot connect to the backend API. Make sure the server is running at ${AppConfig.apiBaseUrl}.',
      );
    }

    final validationMessage = _extractValidationMessage(data);
    final message =
        data is Map<String, dynamic>
            ? validationMessage == null
                ? (data['message'] as String? ?? 'Unexpected API error')
                : '${data['message'] ?? 'Validation failed'}: $validationMessage'
            : error.message ?? 'Unexpected API error';
    return ApiException(message, statusCode: error.response?.statusCode);
  }
}
