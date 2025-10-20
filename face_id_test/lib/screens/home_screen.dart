import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/app_theme.dart';
import '../services/face_service.dart';
import '../utils/image_utils.dart';
import '../widgets/app_button.dart';
import '../widgets/result_card.dart';

enum AttendanceAction { checkIn, checkOut }

extension AttendanceActionX on AttendanceAction {
  String get endpoint =>
      this == AttendanceAction.checkIn ? 'checkin' : 'checkout';
  String get buttonLabel =>
      this == AttendanceAction.checkIn ? 'Check In' : 'Check Out';
  IconData get icon => this == AttendanceAction.checkIn
      ? Icons.camera_alt_outlined
      : Icons.logout_rounded;
  String get captureTitle =>
      this == AttendanceAction.checkIn ? 'Check In Photo' : 'Check Out Photo';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Recognition Attendance')),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome Banner with Soft Gradient
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.gradientSoftBlue
                            .map((c) => c)
                            .toList(),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.large,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gradientSoftBlue[0].withOpacity(
                            0.25,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.face_retouching_natural,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Face Recognition',
                                    style: AppTextStyles.h5.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Quick attendance check',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Quick Actions',
                    style: AppTextStyles.h6.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: AttendanceAction.checkIn.buttonLabel,
                    icon: AttendanceAction.checkIn.icon,
                    onPressed: () => _handleAction(AttendanceAction.checkIn),
                    enabled: !_isUploading,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: AttendanceAction.checkOut.buttonLabel,
                    icon: AttendanceAction.checkOut.icon,
                    onPressed: () => _handleAction(AttendanceAction.checkOut),
                    enabled: !_isUploading,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Last Result',
                    style: AppTextStyles.h6.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _lastResult == null
                        ? _EmptyResultPlaceholder()
                        : SingleChildScrollView(
                            child: ResultCard(result: _lastResult!),
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (_isUploading) const _UploadingOverlay(),
        ],
      ),
    );
  }

  Future<void> _handleAction(AttendanceAction action) async {
    if (_isUploading) return;

    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      Fluttertoast.showToast(
        msg: permission.isPermanentlyDenied
            ? 'Camera permission permanently denied. Please enable it in Settings.'
            : 'Camera permission denied.',
      );
      if (permission.isPermanentlyDenied) {
        await openAppSettings();
      }
      return;
    }

    late final CameraDescription camera;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        Fluttertoast.showToast(msg: 'No camera available on this device.');
        return;
      }
      camera = _selectCamera(cameras);
    } catch (_) {
      Fluttertoast.showToast(msg: 'Unable to access device camera.');
      return;
    }

    final base64Image = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => _CameraCaptureScreen(camera: camera, action: action),
        fullscreenDialog: true,
      ),
    );

    if (!mounted || base64Image == null) {
      return;
    }

    setState(() => _isUploading = true);

    try {
      final data = await _faceService.verify(action.endpoint, base64Image);
      final bool success = data['success'] == true;
      final num? confidenceValue = data['confidence'] as num?;
      final Map<String, dynamic>? matchedEmployee =
          data['matchedEmployee'] is Map<String, dynamic>
          ? data['matchedEmployee'] as Map<String, dynamic>
          : null;

      final AttendanceResult result = AttendanceResult(
        actionLabel: action.buttonLabel,
        success: success,
        status: (data['status'] as String?) ?? '',
        message:
            (data['message'] as String?) ??
            (success ? 'Verification completed.' : 'Verification failed.'),
        employeeName: matchedEmployee?['fullName'] as String?,
        confidence: confidenceValue?.toDouble(),
      );

      if (!mounted) return;

      setState(() {
        _lastResult = result;
      });

      Fluttertoast.showToast(msg: result.message);
    } on DioException catch (_) {
      Fluttertoast.showToast(msg: '⚠️ Server unreachable, please retry');
    } catch (_) {
      Fluttertoast.showToast(msg: 'Đã xảy ra lỗi, vui lòng thử lại.');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  CameraDescription _selectCamera(List<CameraDescription> cameras) {
    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        return camera;
      }
    }
    return cameras.first;
  }
}

class _EmptyResultPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.4)),
        color: colors.surfaceVariant.withOpacity(0.1),
      ),
      padding: const EdgeInsets.all(24),
      child: Text(
        'No attendance attempts yet. Take a photo to check in or out.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _UploadingOverlay extends StatelessWidget {
  const _UploadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _CameraCaptureScreen extends StatefulWidget {
  const _CameraCaptureScreen({required this.camera, required this.action});

  final CameraDescription camera;
  final AttendanceAction action;

  @override
  State<_CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<_CameraCaptureScreen> {
  late final CameraController _controller;
  late final Future<void> _initialization;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _initialization = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.action.captureTitle),
      ),
      body: FutureBuilder<void>(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Center(child: CameraPreview(_controller)),
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        'Align your face within the frame and tap capture.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      _CaptureButton(onTap: _takePicture, isBusy: _isCapturing),
                    ],
                  ),
                ),
              ],
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Camera failed to start',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Future<void> _takePicture() async {
    if (_isCapturing) return;

    setState(() => _isCapturing = true);
    try {
      final file = await _controller.takePicture();
      final base64 = await ImageUtils.xFileToBase64(file);

      if (!mounted) return;
      Navigator.of(context).pop(base64);
    } catch (_) {
      Fluttertoast.showToast(msg: 'Unable to capture photo. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({required this.onTap, required this.isBusy});

  final VoidCallback onTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isBusy ? null : onTap,
      child: Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white54, width: 4),
        ),
        alignment: Alignment.center,
        child: isBusy
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
