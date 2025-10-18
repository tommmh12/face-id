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
  bool _isReRegister = false;  // ✅ Flag for re-registration flow
  bool _isCameraInitialized = false;  // ✅ Track camera state
  String? _error;
  String? _capturedBase64Image; // ✅ Store captured image for re-registration

  @override
  void initState() {
    super.initState();
    
    // ✅ Initialize camera first
    _initializeCamera();
    
    // Check if employee was passed as argument
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        final employee = args['employee'] as Employee?;
        final isReRegister = args['isReRegister'] as bool? ?? false;
        
        if (employee != null) {
          setState(() {
            _selectedEmployee = employee;
            _isReRegister = isReRegister;
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
        AppLogger.success('Camera initialized successfully', tag: 'FaceRegister');
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
        AppLogger.warning('Failed to load employees: ${response.message}', tag: 'FaceRegister');
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
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.camera_alt, color: Colors.blue, size: 48),
        title: Text(_isReRegister ? '📸 Hướng dẫn chụp lại Face ID' : '📸 Hướng dẫn chụp ảnh Face ID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGuidelineItem('✅', 'Nhìn thẳng vào camera'),
            _buildGuidelineItem('✅', 'Không đeo khẩu trang hoặc kính râm'),
            _buildGuidelineItem('✅', 'Đủ ánh sáng, nền sáng'),
            _buildGuidelineItem('✅', 'Chỉ có 1 người trong khung hình'),
            _buildGuidelineItem('✅', 'Giữ điện thoại thẳng và ổn định'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isReRegister ? Colors.orange.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isReRegister ? Colors.orange.shade200 : Colors.blue.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: _isReRegister ? Colors.orange.shade700 : Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isReRegister
                          ? 'Ảnh cũ sẽ bị xóa và thay bằng ảnh mới'
                          : 'Ảnh phải là JPG hoặc PNG, dung lượng < 2MB',
                      style: TextStyle(
                        fontSize: 13,
                        color: _isReRegister ? Colors.orange.shade900 : Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isReRegister ? Colors.orange : Colors.blue,
            ),
            child: Text(_isReRegister ? 'Đã hiểu, chụp lại' : 'Đã hiểu, bắt đầu chụp'),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildGuidelineItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ MAIN REGISTRATION LOGIC
  Future<void> _registerFace() async {
    AppLogger.startOperation(_isReRegister ? 'Face Re-Registration' : 'Face Registration');
    
    // ✅ Validation Step 1: Check employee selected
    if (_selectedEmployee == null) {
      AppLogger.warning('No employee selected', tag: 'FaceRegister');
      _showErrorSnackBar('❌ Vui lòng chọn nhân viên trước khi đăng ký');
      return;
    }

    AppLogger.info('Employee: ${_selectedEmployee!.fullName} (ID: ${_selectedEmployee!.id})', tag: 'FaceRegister');

    // ✅ Validation Step 2: Check camera initialized
    if (!CameraHelper.isInitialized || CameraHelper.controller == null) {
      AppLogger.warning('Camera not initialized', tag: 'FaceRegister');
      _showErrorSnackBar('❌ Camera chưa sẵn sàng. Vui lòng đợi hoặc khởi động lại ứng dụng.');
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
        AppLogger.data('Reusing captured image for re-registration', tag: 'FaceRegister');
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
        _showErrorSnackBar('❌ Không phát hiện khuôn mặt hợp lệ. Vui lòng thử lại.');
        return;
      }
      
      AppLogger.success('Face validated successfully', tag: 'FaceRegister');

      // ✅ Step 3: Prepare request
      AppLogger.separator(title: 'STEP 3/4: Prepare Request');
      final request = RegisterEmployeeFaceRequest(
        employeeId: _selectedEmployee!.id,
        imageBase64: base64Image,
      );
      AppLogger.data('Request prepared (EmployeeId: ${_selectedEmployee!.id})', tag: 'FaceRegister');

      // ✅ Step 4: Call appropriate API (register or re-register)
      AppLogger.separator(title: 'STEP 4/4: Call API');
      final endpoint = _isReRegister ? '/api/face/re-register' : '/api/face/register';
      
      AppLogger.apiRequest(
        endpoint,
        method: 'POST',
        data: request.toJson(),
      );
      
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
          AppLogger.data('S3 URL: ${response.data!.s3ImageUrl}', tag: 'FaceRegister');
        }
        
        // Clear captured image after success
        _capturedBase64Image = null;
        _isReRegister = false;
        
        AppLogger.endOperation('Face Registration', success: true);
        _showSuccessDialog(response.data!);
      } else {
        // ✅ FAILURE - Check if face already exists
        final errorMsg = response.message ?? '❌ Không thể kết nối máy chủ. Vui lòng thử lại sau.';
        AppLogger.warning('Face registration failed: $errorMsg', tag: 'FaceRegister');
        
        // ✅ CRITICAL: Detect if face already exists
        if (!_isReRegister && _isFaceAlreadyRegisteredError(errorMsg)) {
          AppLogger.business('Face already registered detected! Triggering re-registration flow...', tag: 'FaceRegister');
          _showReRegistrationDialog(errorMsg);
        } else {
          AppLogger.endOperation('Face Registration', success: false);
          _showErrorSnackBar(errorMsg);
        }
      }
    } on ArgumentError catch (e, stackTrace) {
      AppLogger.error('DTO Validation error', error: e, stackTrace: stackTrace, tag: 'FaceRegister');
      _showErrorSnackBar('❌ Dữ liệu không hợp lệ: ${e.message}');
      AppLogger.endOperation('Face Registration', success: false);
    } on SocketException catch (e, stackTrace) {
      AppLogger.error('Network connection error', error: e, stackTrace: stackTrace, tag: 'FaceRegister');
      _showErrorSnackBar('❌ Không có kết nối internet. Vui lòng kiểm tra mạng.');
      AppLogger.endOperation('Face Registration', success: false);
    } on FormatException catch (e, stackTrace) {
      AppLogger.error('JSON Format error', error: e, stackTrace: stackTrace, tag: 'FaceRegister');
      _showErrorSnackBar('❌ Lỗi định dạng dữ liệu từ máy chủ.');
      AppLogger.endOperation('Face Registration', success: false);
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error during face registration', error: e, stackTrace: stackTrace, tag: 'FaceRegister');
      
      final errorMessage = e.toString();
      
      if (errorMessage.contains('imageBase64')) {
        _showErrorSnackBar('❌ Ảnh không hợp lệ. Vui lòng thử lại.');
      } else if (errorMessage.contains('Camera') || errorMessage.contains('camera')) {
        _showErrorSnackBar('❌ Lỗi camera. Vui lòng kiểm tra quyền truy cập.');
      } else if (errorMessage.contains('Permission') || errorMessage.contains('permission')) {
        _showErrorSnackBar('❌ Ứng dụng cần quyền truy cập camera. Vui lòng cấp quyền trong cài đặt.');
      } else if (errorMessage.contains('timeout') || errorMessage.contains('Timeout')) {
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
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
        title: const Text('⚠️ Khuôn Mặt Đã Tồn Tại!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              originalErrorMessage,
              style: const TextStyle(fontSize: 14),
            ),
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
                      Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Bạn có muốn đăng ký lại?',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
              AppLogger.business('User confirmed re-registration, calling API again', tag: 'FaceRegister');
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
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: Text(_isReRegister ? '✅ Đăng Ký Lại Thành Công' : '✅ Đăng Ký Thành Công'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isReRegister
                  ? 'Face ID đã được cập nhật thành công cho nhân viên:'
                  : 'Face ID đã được đăng ký thành công cho nhân viên:',
            ),
            const SizedBox(height: 8),
            Text(
              _selectedEmployee!.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Mã NV: ${_selectedEmployee!.employeeCode}',
              style: const TextStyle(color: Colors.grey),
            ),
            if (_isReRegister) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Ảnh cũ đã bị xóa và thay bằng ảnh mới',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to previous screen with success flag
            },
            child: const Text('OK'),
          ),
        ],
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
              child: Text(
                message,
                style: const TextStyle(fontSize: 15),
              ),
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
      appBar: AppBar(
        title: Text(_isReRegister ? 'Đăng Ký Lại Face ID' : 'Đăng Ký Face ID'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chọn nhân viên cần đăng ký Face ID:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_employees.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Không có nhân viên nào chưa đăng ký Face ID',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          else
                            DropdownButtonFormField<Employee>(
                              value: _selectedEmployee,
                              decoration: const InputDecoration(
                                labelText: 'Nhân viên',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              items: _employees.map((employee) {
                                return DropdownMenuItem<Employee>(
                                  value: employee,
                                  child: Text('${employee.employeeCode} - ${employee.fullName}'),
                                );
                              }).toList(),
                              onChanged: (employee) {
                                setState(() {
                                  _selectedEmployee = employee;
                                });
                              },
                              hint: const Text('Chọn nhân viên'),
                            ),
                        ],
                      ),
                    ),

                    // Camera Preview
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _isCameraInitialized && 
                                 CameraHelper.isInitialized && 
                                 CameraHelper.controller?.value.isInitialized == true
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
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Đặt khuôn mặt vào trong khung\nGiữ điện thoại thẳng và ổn định',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
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
                                          style: TextStyle(fontSize: 16, color: Colors.red),
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (CameraHelper.hasMultipleCameras)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: _isRegistering ? null : () async {
                                    try {
                                      await CameraHelper.switchCamera();
                                      setState(() {});
                                    } catch (e) {
                                      _showErrorSnackBar('Lỗi chuyển camera: ${e.toString()}');
                                    }
                                  },
                                  icon: const Icon(Icons.flip_camera_ios),
                                  iconSize: 32,
                                ),
                              ],
                            ),
                          
                          const SizedBox(height: 16),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: (_selectedEmployee != null && 
                                        CameraHelper.isInitialized && 
                                        !_isRegistering)
                                  ? () async {
                                      // ✅ Show guidelines first
                                      final proceed = await _showCaptureGuidelines();
                                      if (proceed) {
                                        _registerFace();
                                      }
                                    }
                                  : null,
                              icon: _isRegistering
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.face_retouching_natural),
                              label: Text(
                                _isRegistering ? 'Đang đăng ký...' : 'Đăng Ký Face ID',
                                style: const TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
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
    CameraHelper.dispose().then((_) {
      AppLogger.success('Camera disposed successfully', tag: 'Camera');
    }).catchError((e) {
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