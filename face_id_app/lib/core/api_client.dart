import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    final baseUrl = dotenv.env['BASE_URL'] ?? 'https://api.studyplannerapp.io.vn';
    final timeout = int.parse(dotenv.env['API_TIMEOUT'] ?? '20000');

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(milliseconds: timeout),
        receiveTimeout: Duration(milliseconds: timeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for logging
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: true,
        responseHeader: false,
      ),
    );
  }

  Dio get client => dio;
}
