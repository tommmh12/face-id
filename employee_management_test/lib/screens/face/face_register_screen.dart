import 'dart:io'; // ✅ For SocketException
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../models/employee.dart';
import '../../models/dto/employee_dtos.dart';
import '../../services/employee_api_service.dart';
import '../../services/face_api_service.dart';
import '../../utils/camera_helper.dart';
import '../../utils/app_logger.dart'; // ✅ App-wide logging

class FaceRegisterScreen extends StatefulWidget {
  const FaceRegisterScreen({super.key});

  @override
  State<FaceRegisterScreen> createState() => _FaceRegisterScreenState();
}

class _FaceRegisterScreenState extends State<FaceRegisterScreen> {
  final EmployeeApiService _employeeService = EmployeeApiService();
  final FaceApiService _faceService = FaceApiService();

  List<Employee> _employees = [];
  Employee? _selectedEmployee;
  bool _isLoading = true;
  bool _isRegistering = false;
  bool _isReRegister = false; // ✅ Flag for re-registration flow
  bool _isCameraInitialized = false; // ✅ Track camera state
  String? _error;
  String? _capturedBase64Image; // ✅ Store captured image for re-registration

  @override
  void initState() {
    super.initState();

    // ✅ Initialize camera first
    _initializeCamera();

    // Check if employee was passed as argument
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        final employee = args['employee'] as Employee?;
        final isReRegister = args['isReRegister'] as bool? ?? false;

        if (employee != null) {
          setState(() {
            _selectedEmployee = employee;
            _isReRegister = isReRegister;
            // Add the selected employee to the list to avoid dropdown error
            if (!_employees.contains(employee)) {
              _employees.add(employee);
            }
          });
        }
      }

      // Only load employees list if no specific employee was passed
      if (_selectedEmployee == null) {
        _loadEmployees();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  /// ✅ Initialize camera with proper error handling
  Future<void> _initializeCamera() async {
    try {
      AppLogger.camera('Initializing camera...');
      await CameraHelper.initializeCamera();

      if (mounted) {
        setState(() {
          _isCameraInitialized = CameraHelper.isInitialized;
        });
        AppLogger.success(
          'Camera initialized successfully',
          tag: 'FaceRegister',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Camera initialization failed',
        error: e,
        stackTrace: stackTrace,
        tag: 'FaceRegister',
      );
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _error = 'Không thể khởi tạo camera: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _loadEmployees() async {
    AppLogger.data('Loading employees list...', tag: 'FaceRegister');

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _employeeService.getAllEmployees();
      if (response.success && response.data != null) {
        final eligibleEmployees = response.data!
            .where((emp) => !emp.isFaceRegistered && emp.isActive)
            .toList();

        AppLogger.success(
          'Loaded ${eligibleEmployees.length} eligible employees (not registered & active)',
          tag: 'FaceRegister',
        );

        setState(() {
          _employees = eligibleEmployees;
        });
      } else {
        AppLogger.warning(
          'Failed to load employees: ${response.message}',
          tag: 'FaceRegister',
        );
        setState(() {
          _error = response.message ?? 'Lỗi tải danh sách nhân viên';
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error loading employees',
        error: e,
        stackTrace: stackTrace,
        tag: 'FaceRegister',
      );
      setState(() {
        _error = 'Lỗi kết nối: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// ✅ Show guidelines before capturing face
  Future<bool> _showCaptureGuidelines() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    (_isReRegister ? Colors.orange : Colors.blue).shade50,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          (_isReRegister
                                  ? Colors.orange
                                  : const Color(0xFF1E88E5))
                              .withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: _isReRegister
                          ? Colors.orange.shade700
                          : const Color(0xFF1E88E5),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    _isReRegister ? 'Hướng Dẫn Chụp Lại' : 'Hướng Dẫn Chụp Ảnh',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isReRegister
                        ? 'Đăng ký lại Face ID'
                        : 'Đăng ký Face ID lần đầu',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Guidelines
                  _buildGuidelineItem('✅', 'Nhìn thẳng vào camera', true),
                  _buildGuidelineItem(
                    '✅',
                    'Không đeo khẩu trang hoặc kính râm',
                    true,
                  ),
                  _buildGuidelineItem('✅', 'Đủ ánh sáng, nền sáng', true),
                  _buildGuidelineItem(
                    '✅',
                    'Chỉ có 1 người trong khung hình',
                    true,
                  ),
                  _buildGuidelineItem(
                    '✅',
                    'Giữ điện thoại thẳng và ổn định',
                    true,
                  ),
                  const SizedBox(height: 20),
                  // Warning
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isReRegister
                          ? Colors.orange.shade50
                          : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isReRegister
                            ? Colors.orange.shade200
                            : const Color(0xFF1E88E5).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: _isReRegister
                              ? Colors.orange.shade700
                              : const Color(0xFF1E88E5),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isReRegister
                                ? 'Ảnh cũ sẽ bị xóa và thay bằng ảnh mới'
                                : 'Ảnh phải là JPG/PNG, dung lượng < 2MB',
                            style: TextStyle(
                              fontSize: 13,
                              color: _isReRegister
                                  ? Colors.orange.shade900
                                  : const Color(0xFF1565C0),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Hủy',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isReRegister
                                ? Colors.orange.shade600
                                : const Color(0xFF1E88E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _isReRegister ? 'Bắt Đầu Chụp Lại' : 'Bắt Đầu Chụp',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  Widget _buildGuidelineItem(
    String icon,
    String text, [
    bool inDialog = false,
  ]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(inDialog ? 12 : 6),
      decoration: inDialog
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            )
          : null,
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: inDialog ? 20 : 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: inDialog ? 14 : 14,
                color: inDialog ? const Color(0xFF1A1A1A) : null,
                fontWeight: inDialog ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ MAIN REGISTRATION LOGIC
  Future<void> _registerFace() async {
    AppLogger.startOperation(
      _isReRegister ? 'Face Re-Registration' : 'Face Registration',
    );

    // ✅ Validation Step 1: Check employee selected
    if (_selectedEmployee == null) {
      AppLogger.warning('No employee selected', tag: 'FaceRegister');
      _showErrorSnackBar('❌ Vui lòng chọn nhân viên trước khi đăng ký');
      return;
    }

    AppLogger.info(
      'Employee: ${_selectedEmployee!.fullName} (ID: ${_selectedEmployee!.id})',
      tag: 'FaceRegister',
    );

    // ✅ Validation Step 2: Check camera initialized
    if (!CameraHelper.isInitialized || CameraHelper.controller == null) {
      AppLogger.warning('Camera not initialized', tag: 'FaceRegister');
      _showErrorSnackBar(
        '❌ Camera chưa sẵn sàng. Vui lòng đợi hoặc khởi động lại ứng dụng.',
      );
      return;
    }

    // ✅ Validation Step 3: Check camera value
    if (!CameraHelper.controller!.value.isInitialized) {
      AppLogger.warning('Camera controller not ready', tag: 'FaceRegister');
      _showErrorSnackBar('❌ Camera đang khởi động. Vui lòng đợi giây lát.');
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    final stopwatch = Stopwatch()..start();

    try {
      // ✅ Step 1: Capture image (or reuse if re-registering)
      String base64Image;

      if (_isReRegister && _capturedBase64Image != null) {
        AppLogger.data(
          'Reusing captured image for re-registration',
          tag: 'FaceRegister',
        );
        base64Image = _capturedBase64Image!;
      } else {
        AppLogger.separator(title: 'STEP 1/4: Capture Image');

        base64Image = await CameraHelper.captureImageAsBase64();

        if (base64Image.isEmpty) {
          AppLogger.error('Captured image is empty', tag: 'FaceRegister');
          _showErrorSnackBar('❌ Không thể chụp ảnh. Vui lòng thử lại.');
          return;
        }

        // Store for potential re-registration
        _capturedBase64Image = base64Image;

        AppLogger.success(
          'Image captured: ${base64Image.length} chars (${(base64Image.length / 1024).toStringAsFixed(1)} KB encoded)',
          tag: 'FaceRegister',
        );
      }

      // ✅ Step 2: Validate face
      AppLogger.separator(title: 'STEP 2/4: Validate Face');
      final hasValidFace = await FaceDetectionHelper.validateFace(base64Image);
      if (!hasValidFace) {
        AppLogger.warning('Face validation failed', tag: 'FaceRegister');
        _showErrorSnackBar(
          '❌ Không phát hiện khuôn mặt hợp lệ. Vui lòng thử lại.',
        );
        return;
      }

      AppLogger.success('Face validated successfully', tag: 'FaceRegister');

      // ✅ Step 3: Prepare request
      AppLogger.separator(title: 'STEP 3/4: Prepare Request');
      final request = RegisterEmployeeFaceRequest(
        employeeId: _selectedEmployee!.id,
        imageBase64: base64Image,
      );
      AppLogger.data(
        'Request prepared (EmployeeId: ${_selectedEmployee!.id})',
        tag: 'FaceRegister',
      );

      // ✅ Step 4: Call appropriate API (register or re-register)
      AppLogger.separator(title: 'STEP 4/4: Call API');
      final endpoint = _isReRegister
          ? '/api/face/re-register'
          : '/api/face/register';

      AppLogger.apiRequest(endpoint, method: 'POST', data: request.toJson());

      final response = _isReRegister
          ? await _faceService.reRegister(request)
          : await _faceService.register(request);

      AppLogger.apiResponse(
        endpoint,
        success: response.success,
        message: response.message,
        data: response.data != null ? 'FaceId: ${response.data!.faceId}' : null,
      );

      if (response.success && response.data != null) {
        stopwatch.stop();
        AppLogger.performance('Face registration', stopwatch.elapsed);

        // ✅ SUCCESS - Registration/Re-registration completed
        AppLogger.success(
          'Face ${_isReRegister ? "re-registration" : "registration"} successful! FaceId: ${response.data!.faceId}',
          tag: 'FaceRegister',
        );

        if (response.data!.s3ImageUrl != null) {
          AppLogger.data(
            'S3 URL: ${response.data!.s3ImageUrl}',
            tag: 'FaceRegister',
          );
        }

        // Clear captured image after success
        _capturedBase64Image = null;
        _isReRegister = false;

        AppLogger.endOperation('Face Registration', success: true);
        _showSuccessDialog(response.data!);
      } else {
        // ✅ FAILURE - Check if face already exists
        final errorMsg =
            response.message ??
            '❌ Không thể kết nối máy chủ. Vui lòng thử lại sau.';
        AppLogger.warning(
          'Face registration failed: $errorMsg',
          tag: 'FaceRegister',
        );

        // ✅ CRITICAL: Detect if face already exists
        if (!_isReRegister && _isFaceAlreadyRegisteredError(errorMsg)) {
          AppLogger.business(
            'Face already registered detected! Triggering re-registration flow...',
            tag: 'FaceRegister',
          );
          _showReRegistrationDialog(errorMsg);
        } else {
          AppLogger.endOperation('Face Registration', success: false);
          _showErrorSnackBar(errorMsg);
        }
      }
    } on ArgumentError catch (e, stackTrace) {
      AppLogger.error(
        'DTO Validation error',
        error: e,
        stackTrace: stackTrace,
        tag: 'FaceRegister',
      );
      _showErrorSnackBar('❌ Dữ liệu không hợp lệ: ${e.message}');
      AppLogger.endOperation('Face Registration', success: false);
    } on SocketException catch (e, stackTrace) {
      AppLogger.error(
        'Network connection error',
        error: e,
        stackTrace: stackTrace,
        tag: 'FaceRegister',
      );
      _showErrorSnackBar(
        '❌ Không có kết nối internet. Vui lòng kiểm tra mạng.',
      );
      AppLogger.endOperation('Face Registration', success: false);
    } on FormatException catch (e, stackTrace) {
      AppLogger.error(
        'JSON Format error',
        error: e,
        stackTrace: stackTrace,
        tag: 'FaceRegister',
      );
      _showErrorSnackBar('❌ Lỗi định dạng dữ liệu từ máy chủ.');
      AppLogger.endOperation('Face Registration', success: false);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Unexpected error during face registration',
        error: e,
        stackTrace: stackTrace,
        tag: 'FaceRegister',
      );

      final errorMessage = e.toString();

      if (errorMessage.contains('imageBase64')) {
        _showErrorSnackBar('❌ Ảnh không hợp lệ. Vui lòng thử lại.');
      } else if (errorMessage.contains('Camera') ||
          errorMessage.contains('camera')) {
        _showErrorSnackBar('❌ Lỗi camera. Vui lòng kiểm tra quyền truy cập.');
      } else if (errorMessage.contains('Permission') ||
          errorMessage.contains('permission')) {
        _showErrorSnackBar(
          '❌ Ứng dụng cần quyền truy cập camera. Vui lòng cấp quyền trong cài đặt.',
        );
      } else if (errorMessage.contains('timeout') ||
          errorMessage.contains('Timeout')) {
        _showErrorSnackBar('❌ Kết nối quá chậm. Vui lòng thử lại.');
      } else if (errorMessage.contains('Failed host lookup')) {
        _showErrorSnackBar('❌ Không tìm thấy máy chủ. Kiểm tra kết nối mạng.');
      } else {
        _showErrorSnackBar('❌ Lỗi không xác định: $errorMessage');
      }
      AppLogger.endOperation('Face Registration', success: false);
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  /// ✅ Detect if error message indicates face already registered
  bool _isFaceAlreadyRegisteredError(String errorMessage) {
    final lowerMsg = errorMessage.toLowerCase();
    return lowerMsg.contains('đã được đăng ký') ||
        lowerMsg.contains('đã tồn tại') ||
        lowerMsg.contains('already registered') ||
        lowerMsg.contains('already exists') ||
        lowerMsg.contains('duplicate face') ||
        lowerMsg.contains('face id đã có');
  }

  /// ✅ Show dialog asking user if they want to re-register
  void _showReRegistrationDialog(String originalErrorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
          size: 48,
        ),
        title: const Text('⚠️ Khuôn Mặt Đã Tồn Tại!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(originalErrorMessage, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Bạn có muốn đăng ký lại?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Ảnh cũ sẽ bị xóa khỏi hệ thống\n• Ảnh mới sẽ thay thế hoàn toàn\n• Không thể hoàn tác',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Cancel - clear captured image
              _capturedBase64Image = null;
              Navigator.pop(context);
            },
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Set re-register flag and call again
              setState(() {
                _isReRegister = true;
              });
              AppLogger.business(
                'User confirmed re-registration, calling API again',
                tag: 'FaceRegister',
              );
              _registerFace();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng Ký Lại'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(RegisterEmployeeFaceResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                (_isReRegister ? Colors.orange : const Color(0xFF43A047))
                    .withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Animation Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isReRegister
                      ? Colors.orange.shade50
                      : const Color(0xFFE8F5E9),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_isReRegister
                                  ? Colors.orange
                                  : const Color(0xFF43A047))
                              .withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: _isReRegister
                      ? Colors.orange.shade600
                      : const Color(0xFF43A047),
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                _isReRegister ? 'Cập Nhật Thành Công!' : 'Đăng Ký Thành Công!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Message
              Text(
                _isReRegister
                    ? 'Face ID đã được cập nhật thành công'
                    : 'Face ID đã được đăng ký thành công',
                style: const TextStyle(fontSize: 15, color: Color(0xFF666666)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Employee Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.face_retouching_natural,
                        color: Color(0xFF43A047),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Name
                    Text(
                      _selectedEmployee!.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Color(0xFF1A1A1A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    // Employee Code
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedEmployee!.employeeCode,
                        style: const TextStyle(
                          color: Color(0xFF1E88E5),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Re-registration info
              if (_isReRegister) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Ảnh cũ đã bị xóa và thay bằng ảnh mới',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFE65100),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // OK Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isReRegister
                        ? Colors.orange.shade600
                        : const Color(0xFF43A047),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Hoàn Tất',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 15)),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Đóng',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _isReRegister
                    ? const Color(0xFFFFF3E0)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.face_retouching_natural,
                color: _isReRegister
                    ? const Color(0xFFFB8C00)
                    : const Color(0xFF43A047),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _isReRegister ? 'Đăng Ký Lại Face ID' : 'Đăng Ký Face ID',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadEmployees,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Employee Selection
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.person_search_rounded,
                              color: Color(0xFF1E88E5),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Chọn Nhân Viên',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_employees.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFB8C00).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFFFB8C00),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Không có nhân viên nào chưa đăng ký Face ID',
                                  style: TextStyle(
                                    color: Color(0xFFE65100),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE0E0E0),
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: DropdownButtonFormField<Employee>(
                            value: _employees.contains(_selectedEmployee)
                                ? _selectedEmployee
                                : null,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Chọn nhân viên',
                              labelStyle: TextStyle(fontSize: 13),
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                size: 20,
                              ),
                            ),
                            items: _employees.map((employee) {
                              return DropdownMenuItem<Employee>(
                                value: employee,
                                child: Text(
                                  '${employee.employeeCode} - ${employee.fullName}',
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (employee) {
                              setState(() {
                                _selectedEmployee = employee;
                              });
                            },
                            hint: const Text(
                              'Vui lòng chọn',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Camera Preview
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF1E88E5),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E88E5).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child:
                          _isCameraInitialized &&
                              CameraHelper.isInitialized &&
                              CameraHelper.controller?.value.isInitialized ==
                                  true
                          ? Stack(
                              children: [
                                CameraPreview(CameraHelper.controller!),

                                // Face detection overlay
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: FaceOverlayPainter(),
                                  ),
                                ),

                                // Instructions overlay
                                Positioned(
                                  top: 20,
                                  left: 20,
                                  right: 20,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withOpacity(0.7),
                                          Colors.black.withOpacity(0.5),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Đặt khuôn mặt vào trong khung\nGiữ điện thoại thẳng và ổn định',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              height: 1.4,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (!_isCameraInitialized) ...[
                                    // ✅ Camera is initializing
                                    const CircularProgressIndicator(),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Đang khởi động camera...',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ] else ...[
                                    // ✅ Camera failed to initialize
                                    const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 64,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Camera không khả dụng',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: _initializeCamera,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Thử lại'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                    ),
                  ),
                ),

                // Controls
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        if (CameraHelper.hasMultipleCameras)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Material(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: _isRegistering
                                    ? null
                                    : () async {
                                        try {
                                          await CameraHelper.switchCamera();
                                          setState(() {});
                                        } catch (e) {
                                          _showErrorSnackBar(
                                            'Lỗi chuyển camera: ${e.toString()}',
                                          );
                                        }
                                      },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.flip_camera_ios_rounded,
                                        color: Color(0xFF1E88E5),
                                        size: 22,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Đổi Camera',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E88E5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                (_selectedEmployee != null &&
                                    CameraHelper.isInitialized &&
                                    !_isRegistering)
                                ? () async {
                                    final proceed =
                                        await _showCaptureGuidelines();
                                    if (proceed) {
                                      _registerFace();
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              backgroundColor: const Color(0xFF43A047),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFE0E0E0),
                              disabledForegroundColor: const Color(0xFF999999),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: _isRegistering ? 0 : 2,
                            ),
                            child: _isRegistering
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _isReRegister
                                            ? 'Đang đăng ký lại...'
                                            : 'Đang đăng ký...',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.face_retouching_natural,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _isReRegister
                                            ? 'Đăng Ký Lại Face ID'
                                            : 'Đăng Ký Face ID',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    AppLogger.info('Disposing FaceRegisterScreen', tag: 'Lifecycle');

    // ✅ Dispose camera when leaving screen
    CameraHelper.dispose()
        .then((_) {
          AppLogger.success('Camera disposed successfully', tag: 'Camera');
        })
        .catchError((e) {
          AppLogger.warning('Camera dispose error: $e', tag: 'Camera');
        });

    super.dispose();
  }
}

// Custom painter for face detection overlay
class FaceOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Draw face detection frame
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;

    canvas.drawCircle(center, radius, paint);

    // Draw corner guides
    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    // Top-left corner
    canvas.drawLine(
      Offset(center.dx - radius, center.dy - radius),
      Offset(center.dx - radius + cornerLength, center.dy - radius),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy - radius),
      Offset(center.dx - radius, center.dy - radius + cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(center.dx + radius, center.dy - radius),
      Offset(center.dx + radius - cornerLength, center.dy - radius),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius, center.dy - radius),
      Offset(center.dx + radius, center.dy - radius + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(center.dx - radius, center.dy + radius),
      Offset(center.dx - radius + cornerLength, center.dy + radius),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy + radius),
      Offset(center.dx - radius, center.dy + radius - cornerLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(center.dx + radius, center.dy + radius),
      Offset(center.dx + radius - cornerLength, center.dy + radius),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius, center.dy + radius),
      Offset(center.dx + radius, center.dy + radius - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
