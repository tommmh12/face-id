import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/face_service.dart';
import '../utils/image_utils.dart';
import '../widgets/app_button.dart';
import '../widgets/result_card.dart';

extension AttendanceActionX on AttendanceAction {
  String get endpoint => this == AttendanceAction.checkIn ? 'checkin' : 'checkout';
  String get buttonLabel => this == AttendanceAction.checkIn ? 'Check In' : 'Check Out';
  IconData get icon => this == AttendanceAction.checkIn ? Icons.camera_alt_outlined : Icons.logout_rounded;
  String get captureTitle => this == AttendanceAction.checkIn ? 'Check In Photo' : 'Check Out Photo';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.face_retouching_natural,
                            color: colorScheme.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Face Recognition',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Attendance System',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Time Display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          StreamBuilder<DateTime>(
                            stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
                            builder: (context, snapshot) {
                              final now = snapshot.data ?? DateTime.now();
                              return Column(
                                children: [
                                  Text(
                                    '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
                                    style: theme.textTheme.headlineLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  Text(
                                    '${now.day}/${now.month}/${now.year}',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Quick Actions Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
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
                                  'Quick Actions',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            AppButton(
                              label: 'Check In',
                              icon: AttendanceAction.checkIn.icon,
                              onPressed: () => _handleAction(AttendanceAction.checkIn),
                              enabled: !_isUploading,
                              type: AttendanceAction.checkIn,
                            ),
                            const SizedBox(height: 16),
                            AppButton(
                              label: 'Check Out',
                              icon: AttendanceAction.checkOut.icon,
                              onPressed: () => _handleAction(AttendanceAction.checkOut),
                              enabled: !_isUploading,
                              type: AttendanceAction.checkOut,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Results Section
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.history,
                                      color: colorScheme.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Latest Result',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                  child: _lastResult == null
                                      ? _EmptyResultPlaceholder()
                                      : SingleChildScrollView(
                                          child: ResultCard(result: _lastResult!),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _isUploading ? null : FloatingActionButton(
        onPressed: () {
          // Quick camera action
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => _QuickActionSheet(
              onCheckIn: () => _handleAction(AttendanceAction.checkIn),
              onCheckOut: () => _handleAction(AttendanceAction.checkOut),
            ),
          );
        },
        backgroundColor: colorScheme.primary,
        child: Icon(
          Icons.camera_alt,
          color: colorScheme.onPrimary,
        ),
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

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const _LoadingDialog(),
    );

    try {
      final data = await _faceService.verify(action.endpoint, base64Image);
      final bool success = data['success'] == true;
      final num? confidenceValue = data['confidence'] as num?;
      final Map<String, dynamic>? matchedEmployee =
          data['matchedEmployee'] is Map<String, dynamic> ? data['matchedEmployee'] as Map<String, dynamic> : null;

      final AttendanceResult result = AttendanceResult(
        actionLabel: action.buttonLabel,
        success: success,
        status: (data['status'] as String?) ?? '',
        message: (data['message'] as String?) ?? (success ? 'Verification completed.' : 'Verification failed.'),
        employeeName: matchedEmployee?['fullName'] as String?,
        confidence: confidenceValue?.toDouble(),
        timestamp: DateTime.now(),
      );

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Show result dialog
      await showDialog(
        context: context,
        builder: (BuildContext context) => _ResultDialog(result: result),
      );

      setState(() {
        _lastResult = result;
      });

    } on DioException catch (_) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorDialog('⚠️ Server unreachable, please retry');
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorDialog('An error occurred, please try again.');
      }
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
        color: colors.surfaceContainerHighest.withOpacity(0.1),
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

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Processing Face Recognition',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we verify your identity...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({required this.result});

  final AttendanceResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tone = result.success ? Colors.green : Colors.red;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: tone.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tone.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      result.success 
                          ? Icons.check_circle_outline 
                          : Icons.error_outline,
                      color: tone,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    result.success ? 'Success!' : 'Failed',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: tone,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.actionLabel,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (result.employeeName != null && result.employeeName!.isNotEmpty) ...[
                    _DialogInfoRow(
                      icon: Icons.person,
                      label: 'Employee',
                      value: result.employeeName!,
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  if (result.confidence != null) ...[
                    _DialogInfoRow(
                      icon: Icons.analytics,
                      label: 'Confidence',
                      value: '${result.confidence!.toStringAsFixed(1)}%',
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  _DialogInfoRow(
                    icon: Icons.message,
                    label: 'Message',
                    value: result.message,
                  ),
                ],
              ),
            ),
            
            // Actions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogInfoRow extends StatelessWidget {
  const _DialogInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionSheet extends StatelessWidget {
  const _QuickActionSheet({
    required this.onCheckIn,
    required this.onCheckOut,
  });

  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Quick Attendance',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.login,
                      label: 'Check In',
                      color: Colors.green,
                      onPressed: () {
                        Navigator.of(context).pop();
                        onCheckIn();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.logout,
                      label: 'Check Out',
                      color: Colors.orange,
                      onPressed: () {
                        Navigator.of(context).pop();
                        onCheckOut();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
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
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Icon(
              widget.action == AttendanceAction.checkIn 
                  ? Icons.login 
                  : Icons.logout,
              color: widget.action == AttendanceAction.checkIn 
                  ? Colors.green 
                  : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(widget.action.captureTitle),
          ],
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<void>(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                // Camera Preview
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.previewSize?.height ?? 1,
                      height: _controller.value.previewSize?.width ?? 1,
                      child: CameraPreview(_controller),
                    ),
                  ),
                ),
                
                // Face Frame Overlay
                Center(
                  child: Container(
                    width: 280,
                    height: 350,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CustomPaint(
                      painter: _FaceFramePainter(),
                    ),
                  ),
                ),
                
                // Dark overlay with cutout
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Container(
                      width: 280,
                      height: 350,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 0,
                            spreadRadius: 1000,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Instructions and Controls
                Positioned(
                  top: 100,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.face,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Position your face within the frame',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Make sure your face is clearly visible and well-lit',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Controls
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      // Status indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: widget.action == AttendanceAction.checkIn 
                              ? Colors.green.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.action == AttendanceAction.checkIn 
                                ? Colors.green 
                                : Colors.orange,
                          ),
                        ),
                        child: Text(
                          widget.action.buttonLabel.toUpperCase(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: widget.action == AttendanceAction.checkIn 
                                ? Colors.green 
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Capture Button
                      _CaptureButton(
                        onTap: _takePicture,
                        isBusy: _isCapturing,
                        actionType: widget.action,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          if (snapshot.hasError) {
            return Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white54,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Camera failed to start',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check camera permissions',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Container(
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Initializing camera...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          );
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
        ? Colors.green 
        : (actionType == AttendanceAction.checkOut ? Colors.orange : Colors.white);
    
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
              : Icon(
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
