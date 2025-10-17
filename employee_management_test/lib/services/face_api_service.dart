import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dto/employee_dtos.dart';
import 'api_service.dart';

class FaceApiService extends BaseApiService {
  static const String _endpoint = '/face';

  // ==================== FACE RECOGNITION ENDPOINTS ====================

  /// POST /api/face/register
  /// Register employee face with AWS Rekognition Collections
  /// 
  /// Flow:
  /// 1. Decode base64 to bytes
  /// 2. Upload to S3 → faces/{employeeId}.jpg
  /// 3. Call IndexFacesAsync(CollectionId="face-collection-hoang", Image=S3Object, ExternalImageId=employeeId)
  /// 4. Return success message + FaceId
  Future<ApiResponse<RegisterEmployeeFaceResponse>> register(RegisterEmployeeFaceRequest request) async {
    final httpRequest = http.post(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint/register'),
      headers: ApiConfig.headers,
      body: json.encode(request.toJson()),
    );

    return handleRequest(httpRequest, (json) => RegisterEmployeeFaceResponse.fromJson(json));
  }

  /// POST /api/face/checkin
  /// Check-in using face verification (AWS Collections)
  /// 
  /// Flow:
  /// 1. Decode base64 to bytes
  /// 2. Call SearchFacesByImage(CollectionId="face-collection-hoang")
  /// 3. If similarity >= 85% → Match found
  /// 4. Upload image to S3 → checkin/{timestamp}.jpg
  /// 5. Save attendance log with CheckType="IN"
  /// 6. Return matched employee info
  Future<ApiResponse<VerifyEmployeeFaceResponse>> checkIn(VerifyFaceRequest request) async {
    final httpRequest = http.post(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint/checkin'),
      headers: ApiConfig.headers,
      body: json.encode(request.toJson()),
    );

    return handleRequest(httpRequest, (json) => VerifyEmployeeFaceResponse.fromJson(json));
  }

  /// POST /api/face/checkout
  /// Check-out using face verification (AWS Collections)
  /// 
  /// Flow:
  /// 1. Decode base64 to bytes
  /// 2. Call SearchFacesByImage(CollectionId="face-collection-hoang")
  /// 3. If similarity >= 85% → Match found
  /// 4. Check if employee checked in today
  /// 5. Upload image to S3 → checkout/{timestamp}.jpg
  /// 6. Save attendance log with CheckType="OUT"
  /// 7. Return matched employee info
  Future<ApiResponse<VerifyEmployeeFaceResponse>> checkOut(VerifyFaceRequest request) async {
    final httpRequest = http.post(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint/checkout'),
      headers: ApiConfig.headers,
      body: json.encode(request.toJson()),
    );

    return handleRequest(httpRequest, (json) => VerifyEmployeeFaceResponse.fromJson(json));
  }

  // ==================== UTILITIES ====================

  /// GET /api/face/health
  /// Health check endpoint - Kiểm tra trạng thái API và AWS Rekognition Collection
  Future<ApiResponse<Map<String, dynamic>>> healthCheck() async {
    final request = http.get(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint/health'),
      headers: ApiConfig.headers,
    );

    return handleRequest(request, (json) => json);
  }
}