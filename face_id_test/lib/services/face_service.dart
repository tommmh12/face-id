import 'package:dio/dio.dart';

const String _defaultApiRoot = 'https://api.studyplannerapp.io.vn/api/';

String _resolveFaceApiBaseUrl() {
  const raw = String.fromEnvironment('FACE_API_BASE', defaultValue: _defaultApiRoot);
  final normalizedRoot = raw.endsWith('/') ? raw : '$raw/';
  if (normalizedRoot.toLowerCase().endsWith('face/')) {
    return normalizedRoot;
  }
  return '${normalizedRoot}face/';
}

class FaceService {
  FaceService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _resolveFaceApiBaseUrl(),
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                contentType: Headers.jsonContentType,
                responseType: ResponseType.json,
              ),
            );

  final Dio _dio;

  Future<Map<String, dynamic>> verify(String endpoint, String base64Image) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        endpoint,
        data: {'imageBase64': base64Image},
        options: Options(validateStatus: (_) => true),
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (e) {
      final dynamic data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      rethrow;
    }
  }
}
