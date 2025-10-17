import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class ApiClient {
  static const String baseUrl = 'https://api.studyplannerapp.io.vn';
  
  late final Dio _dio;
  final Logger _logger = Logger();

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptors for logging and error handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.d('REQUEST[${options.method}] => PATH: ${options.path}');
          _logger.d('DATA: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.i(
            'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
          );
          _logger.d('RESPONSE DATA: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.e(
            'ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}',
          );
          _logger.e('ERROR DATA: ${error.response?.data}');
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // Generic GET request
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Generic POST request
  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Generic PUT request
  Future<Map<String, dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Generic DELETE request
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Map<String, dynamic> _handleResponse(Response response) {
    _logger.d('Response type: ${response.data.runtimeType}');
    
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    
    // Nếu API trả về array trực tiếp, wrap nó vào object
    if (response.data is List) {
      return {
        'success': true,
        'data': response.data,
      };
    }
    
    return {'data': response.data};
  }

  Exception _handleError(DioException error) {
    String errorMessage = 'Đã xảy ra lỗi không xác định';
    
    if (error.response?.data != null) {
      final data = error.response!.data;
      if (data is Map<String, dynamic>) {
        errorMessage = data['message'] ?? errorMessage;
        if (data['errors'] != null && data['errors'] is List) {
          final errors = (data['errors'] as List).join(', ');
          errorMessage = '$errorMessage: $errors';
        }
      }
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Hết thời gian kết nối. Vui lòng thử lại.';
    } else if (error.type == DioExceptionType.connectionError) {
      errorMessage = 'Không thể kết nối đến server. Kiểm tra kết nối mạng.';
    }

    return Exception(errorMessage);
  }
}
