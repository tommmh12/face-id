import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import '../../models/dto/employee_dtos.dart';
import '../../services/face_api_service.dart';
import '../../utils/camera_helper.dart';
import '../../config/app_theme.dart';

class FaceCheckinScreen extends StatefulWidget {
  const FaceCheckinScreen({super.key});

  @override
  State<FaceCheckinScreen> createState() => _FaceCheckinScreenState();
}

class _FaceCheckinScreenState extends State<FaceCheckinScreen> {
  final FaceApiService _faceApiService = FaceApiService();

  bool _isProcessing = false;
  String _currentMode = 'checkin'; // 'checkin' or 'checkout'
  VerifyEmployeeFaceResponse? _lastResult;

  @override
  Widget build(BuildContext context) {
    final modeColor = _currentMode == 'checkin'
        ? AppColors.successColor
        : AppColors.errorColor;

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: Text(
          _currentMode == 'checkin' ? 'Chấm Công Vào' : 'Chấm Công Ra',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: modeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _currentMode = _currentMode == 'checkin'
                      ? 'checkout'
                      : 'checkin';
                  _lastResult = null;
                });
              },
              icon: Icon(
                _currentMode == 'checkin' ? Icons.logout : Icons.login,
                color: Colors.white,
              ),
              label: Text(
                _currentMode == 'checkin' ? 'Chuyển Ra' : 'Chuyển Vào',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white24,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode Indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _currentMode == 'checkin'
                ? Colors.green[50]
                : Colors.red[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _currentMode == 'checkin' ? Icons.login : Icons.logout,
                  color: _currentMode == 'checkin' ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _currentMode == 'checkin' ? 'CHẤM CÔNG VÀO' : 'CHẤM CÔNG RA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _currentMode == 'checkin'
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // Current Time
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    return Text(
                      DateFormat('HH:mm:ss').format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    );
                  },
                ),
                Text(
                  DateFormat('EEEE, dd/MM/yyyy', 'vi').format(DateTime.now()),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Camera Preview
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                border: Border.all(color: modeColor, width: 4),
                borderRadius: BorderRadius.circular(AppBorderRadius.large),
                boxShadow: AppShadows.large,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                child: CameraHelper.isInitialized
                    ? Stack(
                        children: [
                          CameraPreview(CameraHelper.controller!),

                          // Face detection overlay
                          Positioned.fill(
                            child: CustomPaint(
                              painter: FaceOverlayPainter(
                                color: _currentMode == 'checkin'
                                    ? Colors.green
                                    : Colors.red,
                              ),
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
                              child: Text(
                                _currentMode == 'checkin'
                                    ? '🌅 Chấm công vào làm\nĐặt khuôn mặt vào khung và nhấn nút bên dưới'
                                    : '🌇 Chấm công tan làm\nĐặt khuôn mặt vào khung và nhấn nút bên dưới',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),

                          // Processing overlay
                          if (_isProcessing)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black54,
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Đang xử lý...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
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

          // Last Result Display
          if (_lastResult != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: _lastResult!.success
                      ? AppColors.successColor
                      : AppColors.errorColor,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.large),
                boxShadow: AppShadows.medium,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _lastResult!.success ? Icons.check_circle : Icons.error,
                        color: _lastResult!.success ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _lastResult!.message,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _lastResult!.success
                                ? Colors.green[800]
                                : Colors.red[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_lastResult!.success &&
                      _lastResult!.matchedEmployee != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${_lastResult!.matchedEmployee!.employeeCode} - ${_lastResult!.matchedEmployee!.fullName}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    if (_lastResult!.attendanceInfo != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat(
                              'HH:mm:ss dd/MM/yyyy',
                            ).format(_lastResult!.attendanceInfo!.checkTime),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ],
                  if (_lastResult!.confidence > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Độ tin cậy: ${(_lastResult!.confidence * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

          // Action Button
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                if (CameraHelper.hasMultipleCameras)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing
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
                      icon: const Icon(Icons.flip_camera_ios),
                      label: const Text('Chuyển Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.medium,
                          ),
                        ),
                      ),
                    ),
                  ),

                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _currentMode == 'checkin'
                          ? [AppColors.successColor, Colors.greenAccent]
                          : [AppColors.errorColor, Colors.redAccent],
                    ),
                    borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                    boxShadow: AppShadows.large,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (CameraHelper.isInitialized && !_isProcessing)
                          ? _performFaceRecognition
                          : null,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(
                              _currentMode == 'checkin'
                                  ? Icons.login
                                  : Icons.logout,
                            ),
                      label: Text(
                        _isProcessing
                            ? 'Đang xử lý...'
                            : _currentMode == 'checkin'
                            ? 'CHẤM CÔNG VÀO'
                            : 'CHẤM CÔNG RA',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.medium,
                          ),
                        ),
                      ),
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

  Future<void> _performFaceRecognition() async {
    if (!CameraHelper.isInitialized) {
      _showErrorSnackBar('Camera chưa được khởi tạo');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Capture image
      final base64Image = await CameraHelper.captureImageAsBase64();

      // Create request
      final request = VerifyFaceRequest(imageBase64: base64Image);

      // Call appropriate API endpoint
      final response = _currentMode == 'checkin'
          ? await _faceApiService.checkIn(request)
          : await _faceApiService.checkOut(request);

      if (response.success && response.data != null) {
        setState(() {
          _lastResult = response.data!;
        });

        // Show success feedback
        if (response.data!.success) {
          _showSuccessDialog(response.data!);
        } else {
          _showErrorSnackBar(response.data!.message);
        }
      } else {
        _showErrorSnackBar(response.message ?? 'Lỗi kết nối API');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSuccessDialog(VerifyEmployeeFaceResponse result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          _currentMode == 'checkin' ? Icons.login : Icons.logout,
          color: _currentMode == 'checkin' ? Colors.green : Colors.red,
          size: 48,
        ),
        title: Text(
          _currentMode == 'checkin'
              ? 'Check In Thành Công'
              : 'Check Out Thành Công',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (result.matchedEmployee != null) ...[
              Text(
                'Nhân viên: ${result.matchedEmployee!.fullName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Mã NV: ${result.matchedEmployee!.employeeCode}'),
              if (result.matchedEmployee!.position != null)
                Text('Chức vụ: ${result.matchedEmployee!.position}'),
            ],
            const SizedBox(height: 8),
            if (result.attendanceInfo != null)
              Text(
                'Thời gian: ${DateFormat('HH:mm:ss dd/MM/yyyy').format(result.attendanceInfo!.checkTime)}',
              ),
            if (result.confidence > 0)
              Text(
                'Độ tin cậy: ${(result.confidence * 100).toStringAsFixed(1)}%',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Custom painter for face detection overlay
class FaceOverlayPainter extends CustomPainter {
  final Color color;

  FaceOverlayPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Draw face detection frame
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;

    canvas.drawCircle(center, radius, paint);

    // Draw corner guides
    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = color
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
