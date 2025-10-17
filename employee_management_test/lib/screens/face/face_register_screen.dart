import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../models/employee.dart';
import '../../models/dto/employee_dtos.dart';
import '../../services/employee_api_service.dart';
import '../../utils/camera_helper.dart';

class FaceRegisterScreen extends StatefulWidget {
  const FaceRegisterScreen({super.key});

  @override
  State<FaceRegisterScreen> createState() => _FaceRegisterScreenState();
}

class _FaceRegisterScreenState extends State<FaceRegisterScreen> {
  final EmployeeApiService _employeeService = EmployeeApiService();
  
  List<Employee> _employees = [];
  Employee? _selectedEmployee;
  bool _isLoading = true;
  bool _isRegistering = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    
    // Check if employee was passed as argument
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final employee = ModalRoute.of(context)?.settings.arguments as Employee?;
      if (employee != null) {
        setState(() {
          _selectedEmployee = employee;
        });
      }
    });
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _employeeService.getAllEmployees();
      if (response.success && response.data != null) {
        setState(() {
          _employees = response.data!
              .where((emp) => !emp.isFaceRegistered && emp.isActive)
              .toList();
        });
      } else {
        setState(() {
          _error = response.message ?? 'Lỗi tải danh sách nhân viên';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi kết nối: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _registerFace() async {
    if (_selectedEmployee == null) {
      _showErrorSnackBar('Vui lòng chọn nhân viên');
      return;
    }

    if (!CameraHelper.isInitialized) {
      _showErrorSnackBar('Camera chưa được khởi tạo');
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      // Capture image
      final base64Image = await CameraHelper.captureImageAsBase64();
      
      // Validate face (optional)
      final hasValidFace = await FaceDetectionHelper.validateFace(base64Image);
      if (!hasValidFace) {
        _showErrorSnackBar('Không phát hiện khuôn mặt. Vui lòng thử lại.');
        return;
      }

      // Register face
      final request = RegisterEmployeeFaceRequest(
        employeeId: _selectedEmployee!.id,
        imageBase64: base64Image,
      );

      final response = await _employeeService.registerFace(request);

      if (response.success && response.data != null) {
        _showSuccessDialog(response.data!);
      } else {
        _showErrorSnackBar(response.message ?? 'Lỗi đăng ký Face ID');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi: ${e.toString()}');
    } finally {
      setState(() {
        _isRegistering = false;
      });
    }
  }

  void _showSuccessDialog(RegisterEmployeeFaceResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Đăng Ký Thành Công'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Face ID đã được đăng ký thành công cho nhân viên:'),
            const SizedBox(height: 8),
            Text(
              _selectedEmployee!.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (response.faceId != null) ...[
              const SizedBox(height: 8),
              Text('Face ID: ${response.faceId}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back
            },
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _resetForm(); // Reset for next registration
            },
            child: const Text('Đăng ký tiếp'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedEmployee = null;
    });
    _loadEmployees(); // Refresh list
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Ký Face ID'),
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
                          DropdownButtonFormField<Employee>(
                            initialValue: _selectedEmployee,
                            decoration: const InputDecoration(
                              labelText: 'Nhân viên',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            items: _employees.map((employee) => DropdownMenuItem<Employee>(
                              value: employee,
                              child: Text('${employee.employeeCode} - ${employee.fullName}'),
                            )).toList(),
                            onChanged: (employee) {
                              setState(() {
                                _selectedEmployee = employee;
                              });
                            },
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
                          child: CameraHelper.isInitialized
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
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt_outlined,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Camera không khả dụng',
                                        style: TextStyle(fontSize: 16),
                                      ),
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
                                  ? _registerFace
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
    _employeeService.dispose();
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