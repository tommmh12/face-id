import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/face_service.dart';
import '../services/notification_service.dart';
import '../services/user_guidance_service.dart';
import '../widgets/app_button.dart';
import '../widgets/result_card.dart';

extension AttendanceActionX on AttendanceAction {
  String get endpoint => this == AttendanceAction.checkIn ? 'checkin' : 'checkout';
  String get buttonLabel => this == AttendanceAction.checkIn ? 'Check In' : 'Check Out';
  IconData get icon => this == AttendanceAction.checkIn ? Icons.login : Icons.logout;
  String get captureTitle => this == AttendanceAction.checkIn ? 'Chụp ảnh vào ca' : 'Chụp ảnh ra ca';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FaceService _faceService = FaceService();
  AttendanceResult? _lastResult;
  bool _isUploading = false;
  int _todayCheckIns = 12;
  int _todayCheckOuts = 8;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _loadTodayStats();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _loadTodayStats() {
    // Simulate loading today's stats from API
    setState(() {
      _todayCheckIns = 12;
      _todayCheckOuts = 8;
    });
  }

  void _updateStats(AttendanceAction action) {
    setState(() {
      if (action == AttendanceAction.checkIn) {
        _todayCheckIns++;
      } else {
        _todayCheckOuts++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Hệ thống Chấm công'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: () => UserGuidanceService.showTips(context),
            icon: const Icon(Icons.help_outline),
            tooltip: 'Hướng dẫn sử dụng',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Header Card
            Card(
              elevation: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withOpacity(0.1),
                      colorScheme.primary.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.business,
                            color: colorScheme.onPrimary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Công ty TNHH ABC',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Hệ thống chấm công thông minh',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Live Clock
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                      child: StreamBuilder<DateTime>(
                        stream: Stream.periodic(
                          const Duration(seconds: 1),
                          (_) => DateTime.now(),
                        ),
                        builder: (context, snapshot) {
                          final now = snapshot.data ?? DateTime.now();
                          return Column(
                            children: [
                              Text(
                                DateFormat('HH:mm:ss').format(now),
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  fontSize: 36,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat('EEEE, dd/MM/yyyy').format(now),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Statistics Card
            Card(
              elevation: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Thống kê hôm nay',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Vào ca',
                            _todayCheckIns.toString(),
                            Icons.login,
                            const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Ra ca',
                            _todayCheckOuts.toString(),
                            Icons.logout,
                            const Color(0xFFEF6C00),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons Card
            Card(
              elevation: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.touch_app,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Chấm công',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildActionButton(
                      context,
                      'Chấm công vào ca',
                      Icons.login,
                      const Color(0xFF2E7D32),
                      () => _handleAction(AttendanceAction.checkIn),
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      context,
                      'Chấm công ra ca',
                      Icons.logout,
                      const Color(0xFFEF6C00),
                      () => _handleAction(AttendanceAction.checkOut),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Last Result
            if (_lastResult != null) 
              Card(
                elevation: 3,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  child: ResultCard(
                    result: _lastResult!,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => UserGuidanceService.showFirstTimeHelp(context),
        backgroundColor: colorScheme.primary,
        child: Icon(
          Icons.info_outline,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isUploading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
        ),
        icon: _isUploading 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 24),
        label: Text(
          _isUploading ? 'Đang xử lý...' : title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(AttendanceAction action) async {
    if (_isUploading) return;

    // Show welcome message for first time users
    if (_todayCheckIns == 0 && _todayCheckOuts == 0) {
      UserGuidanceService.showFirstTimeHelp(context);
      return;
    }

    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      NotificationService.showError(
        context,
        'Cần quyền truy cập camera',
        subtitle: 'Vui lòng cấp quyền camera để sử dụng tính năng chấm công',
      );
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        NotificationService.showError(
          context,
          'Không tìm thấy camera',
          subtitle: 'Thiết bị không có camera khả dụng',
        );
        return;
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      if (!mounted) return;

      final base64Image = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => _CameraCaptureScreen(
            camera: camera,
            action: action,
          ),
          fullscreenDialog: true,
        ),
      );

      if (!mounted || base64Image == null) {
        return;
      }

      setState(() => _isUploading = true);

      // Show notification while processing
      NotificationService.showInfo(
        context,
        'Đang xử lý...',
        subtitle: 'Vui lòng chờ hệ thống xác thực khuôn mặt',
      );

      try {
        final verificationResult = await _faceService.verify(action.endpoint, base64Image);
        
        final AttendanceResult result = AttendanceResult(
          actionLabel: action.buttonLabel,
          success: verificationResult.success,
          status: verificationResult.success ? 'Thành công' : 'Thất bại',
          message: verificationResult.detailedMessage,
          employeeName: verificationResult.employeeName,
          confidence: null,
          timestamp: verificationResult.timestamp,
        );

        if (!mounted) return;

        // Show result notification
        if (result.success) {
          NotificationService.showSuccess(
            context,
            '${action.buttonLabel} thành công!',
            subtitle: result.employeeName != null 
              ? 'Chào mừng ${result.employeeName}!' 
              : 'Chấm công đã được ghi nhận',
          );
          
          HapticFeedback.lightImpact();
          _updateStats(action);
        } else {
          NotificationService.showError(
            context,
            '${action.buttonLabel} thất bại',
            subtitle: result.message,
          );
          
          HapticFeedback.heavyImpact();
        }

        setState(() {
          _lastResult = result;
        });

      } catch (error) {
        if (mounted) {
          NotificationService.showError(
            context,
            'Lỗi hệ thống',
            subtitle: 'Không thể kết nối đến máy chủ. Vui lòng thử lại.',
          );
        }
      }
    } catch (error) {
      if (mounted) {
        NotificationService.showError(
          context,
          'Lỗi camera',
          subtitle: 'Không thể khởi động camera. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }


}

// Camera Capture Screen remains the same...
class _CameraCaptureScreen extends StatefulWidget {
  final CameraDescription camera;
  final AttendanceAction action;

  const _CameraCaptureScreen({
    required this.camera,
    required this.action,
  });

  @override
  State<_CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<_CameraCaptureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      if (mounted) {
        Navigator.pop(context, base64Image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Text(widget.action.captureTitle),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // Camera Preview
                CameraPreview(_controller),

                // Face Guide Overlay
                CustomPaint(
                  size: Size.infinite,
                  painter: _FaceFramePainter(),
                ),

                // Instructions
                Positioned(
                  top: 50,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.face_retouching_natural,
                          color: colorScheme.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Đặt khuôn mặt vào khung hướng dẫn',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Giữ thẳng và nhìn vào camera',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Capture Button
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _CaptureButton(
                      onTap: _takePicture,
                      isBusy: _isCapturing,
                      actionType: widget.action,
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.onTap, 
    required this.isBusy,
    this.actionType,
  });

  final VoidCallback onTap;
  final bool isBusy;
  final AttendanceAction? actionType;

  @override
  Widget build(BuildContext context) {
    final buttonColor = actionType == AttendanceAction.checkIn 
        ? const Color(0xFF2E7D32)
        : (actionType == AttendanceAction.checkOut ? const Color(0xFFEF6C00) : Colors.white);
    
    return GestureDetector(
      onTap: isBusy ? null : onTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 4),
          boxShadow: [
            BoxShadow(
              color: buttonColor.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isBusy ? Colors.white.withOpacity(0.3) : buttonColor,
          ),
          child: isBusy
              ? const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3, 
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 32,
                ),
        ),
      ),
    );
  }
}

class _FaceFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw corner brackets
    final cornerLength = 30.0;
    final cornerRadius = 10.0;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLength)
        ..lineTo(0, cornerRadius)
        ..arcToPoint(
          Offset(cornerRadius, 0),
          radius: Radius.circular(cornerRadius),
        )
        ..lineTo(cornerLength, 0),
      paint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width - cornerRadius, 0)
        ..arcToPoint(
          Offset(size.width, cornerRadius),
          radius: Radius.circular(cornerRadius),
        )
        ..lineTo(size.width, cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLength)
        ..lineTo(0, size.height - cornerRadius)
        ..arcToPoint(
          Offset(cornerRadius, size.height),
          radius: Radius.circular(cornerRadius),
        )
        ..lineTo(cornerLength, size.height),
      paint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, size.height)
        ..lineTo(size.width - cornerRadius, size.height)
        ..arcToPoint(
          Offset(size.width, size.height - cornerRadius),
          radius: Radius.circular(cornerRadius),
        )
        ..lineTo(size.width, size.height - cornerLength),
      paint,
    );

    // Draw center guidelines
    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Horizontal center line
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.5),
      Offset(size.width * 0.7, size.height * 0.5),
      centerPaint,
    );

    // Vertical center line
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.7),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}