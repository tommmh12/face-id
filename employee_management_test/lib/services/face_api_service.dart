import 'dart:convert';
import '../models/dto/employee_dtos.dart';
import '../utils/http_client.dart';
import '../utils/app_logger.dart'; // ✅ Import AppLogger
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
    AppLogger.apiRequest('$_endpoint/register', method: 'POST', data: request.toJson());
    
    final response = await handleRequest(
      () => CustomHttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/register'),
        headers: ApiConfig.headers,
        body: json.encode(request.toJson()),
      ),
      (json) => RegisterEmployeeFaceResponse.fromJson(json),
    );
    
    AppLogger.apiResponse(
      '$_endpoint/register',
      success: response.success,
      message: response.message,
      data: response.data != null ? 'FaceId: ${response.data!.faceId}' : null,
    );
    
    return response;
  }

  /// POST /api/face/re-register
  /// Re-register employee face - Delete old face & image, register new one
  /// 
  /// Flow:
  /// 1. Kiểm tra nhân viên đã đăng ký face chưa
  /// 2. Xóa FaceId cũ khỏi AWS Rekognition Collection
  /// 3. Xóa ảnh cũ khỏi S3
  /// 4. Decode base64 to bytes (ảnh mới)
  /// 5. Upload ảnh mới to S3 → faces/{employeeId}-{timestamp}.jpg
  /// 6. Index face mới vào AWS Collection
  /// 7. Update database với S3 URL mới và FaceId mới
  /// 8. Return success message
  /// 
  /// Use case: Khi nhân viên muốn cập nhật ảnh khuôn mặt (thay đổi ngoại hình, ảnh rõ hơn...)
  Future<ApiResponse<RegisterEmployeeFaceResponse>> reRegister(RegisterEmployeeFaceRequest request) async {
    AppLogger.apiRequest('$_endpoint/re-register', method: 'POST', data: request.toJson());
    
    final response = await handleRequest(
      () => CustomHttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/re-register'),
        headers: ApiConfig.headers,
        body: json.encode(request.toJson()),
      ),
      (json) => RegisterEmployeeFaceResponse.fromJson(json),
    );
    
    AppLogger.apiResponse(
      '$_endpoint/re-register',
      success: response.success,
      message: response.message,
      data: response.data != null ? 'FaceId: ${response.data!.faceId}' : null,
    );
    
    return response;
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
    AppLogger.apiRequest('$_endpoint/checkin', method: 'POST', data: request.toJson());
    
    final response = await handleRequest(
      () => CustomHttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/checkin'),
        headers: ApiConfig.headers,
        body: json.encode(request.toJson()),
      ),
      (json) => VerifyEmployeeFaceResponse.fromJson(json),
    );
    
    AppLogger.apiResponse(
      '$_endpoint/checkin',
      success: response.success,
      message: response.message,
      data: response.data != null && response.data!.matchedEmployee != null 
        ? 'Employee: ${response.data!.matchedEmployee!.fullName} (Confidence: ${response.data!.confidence.toStringAsFixed(2)}%)'
        : null,
    );
    
    return response;
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
    AppLogger.apiRequest('$_endpoint/checkout', method: 'POST', data: request.toJson());
    
    final response = await handleRequest(
      () => CustomHttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/checkout'),
        headers: ApiConfig.headers,
        body: json.encode(request.toJson()),
      ),
      (json) => VerifyEmployeeFaceResponse.fromJson(json),
    );
    
    AppLogger.apiResponse(
      '$_endpoint/checkout',
      success: response.success,
      message: response.message,
      data: response.data != null && response.data!.matchedEmployee != null 
        ? 'Employee: ${response.data!.matchedEmployee!.fullName} (Confidence: ${response.data!.confidence.toStringAsFixed(2)}%)'
        : null,
    );
    
    return response;
  }

  // ==================== UTILITIES ====================

  /// GET /api/face/health
  /// Health check endpoint - Kiểm tra trạng thái API và AWS Rekognition Collection
  Future<ApiResponse<Map<String, dynamic>>> healthCheck() async {
    return handleRequest(
      () => CustomHttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/health'),
        headers: ApiConfig.headers,
      ),
      (json) => json,
    );
  }
}