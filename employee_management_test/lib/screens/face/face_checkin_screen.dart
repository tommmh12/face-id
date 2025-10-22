import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // For WriteBuffer
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../models/dto/employee_dtos.dart';
import '../../services/face_api_service.dart';

import '../../utils/vietnam_time_zone.dart';
import '../../config/app_theme.dart';

class FaceCheckinScreen extends StatefulWidget {
  const FaceCheckinScreen({super.key});

  @override
  State<FaceCheckinScreen> createState() => _FaceCheckinScreenState();
}

class _FaceCheckinScreenState extends State<FaceCheckinScreen> with WidgetsBindingObserver {
  final FaceApiService _faceApiService = FaceApiService();

  // Camera and lifecycle variables
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  
  // Face detection variables
  FaceDetector? _faceDetector;
  bool _isDetecting = false;
  Rect? _faceRect;
  Size? _imageSize;
  InputImageRotation? _imageRotation;

  // Processing state
  bool _isProcessing = false;
  String _currentMode = 'checkin'; // 'checkin' or 'checkout'
  VerifyEmployeeFaceResponse? _lastResult;

  // Auto-capture logic
  int _stableCounter = 0;
  bool _isAutoDetectionEnabled = true;
  int _countdownSeconds = 0;
  bool _isCountingDown = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCameraAndDetector();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _stopImageStream();
    _faceDetector?.close();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _stopImageStream();
        _cameraController?.dispose();
        setState(() {
          _isCameraInitialized = false;
        });
        break;
      case AppLifecycleState.resumed:
        _initializeCameraAndDetector();
        break;
      default:
        break;
    }
  }

  Future<void> _initializeCameraAndDetector() async {
    try {
      // Initialize face detector
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableTracking: true,
          enableClassification: false,
          enableLandmarks: false,
          enableContours: false,
        ),
      );

      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Find front camera, fallback to first camera
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // Initialize camera controller
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      
      // Set auto focus mode
      await _cameraController!.setFocusMode(FocusMode.auto);
      
      setState(() {
        _isCameraInitialized = true;
      });

      // Start image stream for face detection
      if (_isAutoDetectionEnabled) {
        _startImageStream();
      }
    } catch (e) {
      debugPrint('Error initializing camera and detector: $e');
    }
  }

  void _startImageStream() {
    if (_cameraController == null || 
        !_cameraController!.value.isInitialized || 
        !_isAutoDetectionEnabled ||
        _isProcessing) return;
    
    try {
      _cameraController!.startImageStream((CameraImage image) {
        if (_isDetecting || _isProcessing) return;
        _detectFace(image);
      });
    } catch (e) {
      debugPrint('Error starting image stream: $e');
    }
  }

  void _stopImageStream() {
    if (_cameraController != null && 
        _cameraController!.value.isInitialized &&
        _cameraController!.value.isStreamingImages) {
      try {
        _cameraController!.stopImageStream();
      } catch (e) {
        debugPrint('Error stopping image stream: $e');
      }
    }
  }

  Future<void> _detectFace(CameraImage cameraImage) async {
    // Thêm kiểm tra: Nếu đang đếm ngược, đừng detect nữa
    if (_isDetecting || _isProcessing || _faceDetector == null || _isCountingDown) {
      _isDetecting = false; // Phải reset cờ
      return;
    }
    
    _isDetecting = true;
    
    try {
      final inputImage = _inputImageFromCameraImage(cameraImage);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }
      
      final List<Face> faces = await _faceDetector!.processImage(inputImage);
      
      _imageSize = inputImage.metadata?.size;
      _imageRotation = inputImage.metadata?.rotation;

      if (faces.isNotEmpty && _imageSize != null && _imageRotation != null) {
        final Face face = faces[0];
        
        final Size previewSize = _getPreviewSize(); 
        final Rect scaledRect = _scaleRect(face.boundingBox, _imageSize!, previewSize, _imageRotation!);

        if (mounted) {
          setState(() {
            _faceRect = face.boundingBox;
          });
        }
        
        if (_isFaceInsideOval(scaledRect, previewSize) && _isFaceStable(face)) {
          _stableCounter++;
          
          if (_stableCounter >= 15 && !_isCountingDown && !_isProcessing) {
             _startCountdown(); // Bắt đầu đếm ngược
          }
        } else {
          // Chỉ reset nếu CHƯA đếm ngược
          if (!_isCountingDown) { // <-- THÊM ĐIỀU KIỆN NÀY
             _stableCounter = 0;
          }
        }
      } else {
         if (mounted) {
          setState(() { _faceRect = null; });
         }
        // Luôn reset nếu không thấy mặt
        _stableCounter = 0; 
        if (_isCountingDown) {
          _cancelCountdown();
        }
      }
    } catch (e) {
      debugPrint('Error detecting face: $e');
    } finally {
      _isDetecting = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) {
      debugPrint("Lỗi: Camera controller chưa khởi tạo.");
      return null;
    }

    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    
    InputImageRotation rotation;
    switch (sensorOrientation) {
      case 0:
        rotation = InputImageRotation.rotation0deg;
        break;
      case 90:
        rotation = InputImageRotation.rotation90deg;
        break;
      case 180:
        rotation = InputImageRotation.rotation180deg;
        break;
      case 270:
        rotation = InputImageRotation.rotation270deg;
        break;
      default:
        rotation = InputImageRotation.rotation0deg;
    }

    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    // Kiểm tra định dạng YUV (phổ biến trên Android)
    if (format != InputImageFormat.yuv_420_888 && format != InputImageFormat.nv21) {
      debugPrint("Định dạng ảnh không được hỗ trợ: ${image.format.group} (Raw: ${image.format.raw})");
      // Thử dùng plane đầu tiên (cho BGRA, v.v.)
       if (image.planes.isNotEmpty) {
           return InputImage.fromBytes(
             bytes: image.planes[0].bytes,
             metadata: InputImageMetadata(
               size: Size(image.width.toDouble(), image.height.toDouble()),
               rotation: rotation,
               format: InputImageFormat.bgra8888, // Giả định BGRA nếu không phải YUV
               bytesPerRow: image.planes[0].bytesPerRow,
             ),
           );
       }
       return null;
    }

    // ✅ SỬA LỖI QUAN TRỌNG: GỘP CÁC PLANE CHO YUV
    // (Lấy từ tài liệu chính thức của google_ml_kit)
    final allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: InputImageFormat.nv21, // Thường là NV21 cho YUV_420_888 trên Android
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  // ✅ HÀM SCALE MỚI (Rất quan trọng)
  // Ánh xạ tọa độ từ `imageSize` (ví dụ: 720x1280) sang `screenSize` (ví dụ: 390x520)
  Rect _scaleRect(Rect rect, Size imageSize, Size screenSize, InputImageRotation rotation) {
    // Kích thước ảnh thực tế sau khi xoay (ví dụ: 720x1280)
    final bool isRotated = rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;
    
    final Size actualImageSize = isRotated
        ? Size(imageSize.height, imageSize.width)
        : imageSize;

    // Tỷ lệ của ảnh và màn hình (Box 3:4)
    final double imageRatio = actualImageSize.width / actualImageSize.height;
    // Tỷ lệ của box 3:4
    final double screenRatio = screenSize.width / screenSize.height;

    double scale;
    double offsetX = 0;
    double offsetY = 0;

    // Tính toán theo BoxFit.cover (CameraPreview đang làm điều này bên trong AspectRatio)
    if (imageRatio > screenRatio) { // Ảnh rộng hơn (ví dụ: 16:9)
      scale = screenSize.height / actualImageSize.height;
      offsetX = (screenSize.width - actualImageSize.width * scale) / 2;
    } else { // Ảnh cao hơn (ví dụ: 9:16)
      scale = screenSize.width / actualImageSize.width;
      offsetY = (screenSize.height - actualImageSize.height * scale) / 2;
    }

    // Ánh xạ tọa độ
    return Rect.fromLTRB(
      (rect.left * scale) + offsetX,
      (rect.top * scale) + offsetY,
      (rect.right * scale) + offsetX,
      (rect.bottom * scale) + offsetY,
    );
  }

  // Hàm mới để lấy kích thước của box 3:4
  Size _getPreviewSize() {
    final size = MediaQuery.of(context).size;
    const double desiredRatio = 3.0 / 4.0;
    double previewWidth = size.width;
    double previewHeight = previewWidth / desiredRatio;

    if (previewHeight > size.height) {
      previewHeight = size.height;
      previewWidth = previewHeight * desiredRatio;
    }
    return Size(previewWidth, previewHeight);
  }

  bool _isFaceInsideOval(Rect scaledFaceRect, Size previewSize) {
    // Vòng tròn mục tiêu (nằm giữa box 3:4)
    final ovalCenter = Offset(previewSize.width / 2, previewSize.height / 2);
    final ovalRadius = previewSize.width * 0.30; // Bán kính vòng tròn

    // Tâm khuôn mặt (đã được scale)
    final faceCenter = scaledFaceRect.center;
    final faceRadius = (scaledFaceRect.width + scaledFaceRect.height) / 4;

    // Kiểm tra tâm mặt có gần tâm vòng tròn không
    final distance = (faceCenter - ovalCenter).distance;
    
    // Kiểm tra mặt có đủ to (đủ gần camera) không
    // Ví dụ: mặt phải chiếm ít nhất 50% bán kính vòng tròn
    final isCloseEnough = faceRadius > (ovalRadius * 0.5); 

    return (distance < (ovalRadius * 0.7)) && isCloseEnough; // Mặt phải gần tâm VÀ đủ to
  }

  bool _isFaceStable(Face face) {
    // Check if head is facing roughly forward
    final headY = face.headEulerAngleY;
    final headZ = face.headEulerAngleZ;
    
    return (headY != null && headY.abs() < 15) && 
           (headZ != null && headZ.abs() < 10);
  }

  void _startCountdown() {
    if (_isCountingDown || _isProcessing) return;
    
    _stopImageStream(); // <<< DỪNG QUÉT KHI BẮT ĐẦU ĐẾM
    
    setState(() {
      _isCountingDown = true;
      _countdownSeconds = 3;
    });
    
    _countdownTimer?.cancel();
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isCountingDown || _isProcessing) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _countdownSeconds--;
      });
      
      if (_countdownSeconds <= 0) {
        timer.cancel();
        _performAutoCapture();
      }
    });
  }

  void _cancelCountdown() {
    if (!_isCountingDown) return;
    
    _countdownTimer?.cancel();
    setState(() {
      _isCountingDown = false;
      _countdownSeconds = 0;
      _stableCounter = 0;
    });
    
    _startImageStream(); // <<< KHỞI ĐỘNG LẠI STREAM ĐỂ QUÉT LẠI
  }

  Future<void> _performAutoCapture() async {
    // _countdownTimer?.cancel(); // Đã cancel ở trên
    setState(() {
      _isCountingDown = false;
      _countdownSeconds = 0;
    });
    
    await _captureAndVerify();
  }

  Future<void> _captureAndVerify() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    _stopImageStream();
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // Capture image
      final XFile imageFile = await _cameraController!.takePicture();
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final request = VerifyFaceRequest(imageBase64: base64Image);

      // Call appropriate API endpoint
      final response = _currentMode == 'checkin'
          ? await _faceApiService.checkIn(request)
          : await _faceApiService.checkOut(request);

      if (response.success && response.data != null) {
        setState(() {
          _lastResult = response.data!;
        });

        if (response.data!.success) {
          _showSuccessDialog(response.data!);
        } else {
          if (response.data!.status == 'not_implemented') {
            _showNotImplementedDialog(response.data!);
          } else {
            _showErrorSnackBar(response.data!.message);
          }
        }
      } else {
        _showErrorSnackBar(response.message ?? 'Lỗi kết nối API');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi: ${e.toString()}');
    } finally {
      // Wait 3 seconds then restart detection
      await Future.delayed(const Duration(seconds: 3));
      setState(() {
        _isProcessing = false;
        _stableCounter = 0;
        _lastResult = null;
      });
      
      if (_isAutoDetectionEnabled && _isCameraInitialized) {
        _startImageStream();
      }
    }
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null || !_isCameraInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // Ép buộc camera hiển thị trong một box tỷ lệ 3:4 (dọc)
    return Center(
      child: AspectRatio(
        aspectRatio: 3.0 / 4.0, // Tỷ lệ 3:4
        child: ClipRect( // Cắt bỏ phần camera thừa (nếu có)
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modeColor = _currentMode == 'checkin'
        ? AppColors.successColor
        : AppColors.errorColor;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          _currentMode == 'checkin' ? 'Chấm Công Vào' : 'Chấm Công Ra',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: modeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Auto detection toggle
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _isAutoDetectionEnabled = !_isAutoDetectionEnabled;
                  if (_isAutoDetectionEnabled && _isCameraInitialized) {
                    _startImageStream();
                  } else {
                    _stopImageStream();
                    _cancelCountdown();
                  }
                });
              },
              icon: Icon(
                _isAutoDetectionEnabled ? Icons.auto_awesome : Icons.touch_app,
                color: Colors.white,
              ),
              tooltip: _isAutoDetectionEnabled ? 'Tắt tự động' : 'Bật tự động',
            ),
          ),
          // Mode switch button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _currentMode = _currentMode == 'checkin'
                      ? 'checkout'
                      : 'checkin';
                  _lastResult = null;
                  _stableCounter = 0;
                  _cancelCountdown();
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
      body: Stack(
        children: [
          // Full-screen camera preview with proper aspect ratio
          Positioned.fill(
            child: _isCameraInitialized && _cameraController != null
                ? _buildCameraPreview()
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Đang khởi tạo camera...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // Face detection overlay
          Positioned.fill(
            child: CustomPaint(
              painter: FaceOverlayPainter(
                color: _isProcessing 
                    ? Colors.grey 
                    : _isCountingDown
                        ? Colors.orange
                        : (_currentMode == 'checkin' ? Colors.green : Colors.red),
                faceRect: _faceRect,
                isStable: _stableCounter > 10,
                imageSize: _imageSize,
                imageRotation: _imageRotation,
              ),
            ),
          ),

          // Enhanced Countdown overlay
          if (_isCountingDown)
            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.orange.withOpacity(0.9),
                      Colors.orange.withOpacity(0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Animated ring
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: (_countdownSeconds / 4.0), // <<< SỬA TỪ 3.0 LÊN 4.0
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    // Countdown number
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _countdownSeconds.toString(),
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                offset: Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'giây',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                offset: Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // UI Overlays
          Column(
            children: [
              // Mode Indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (_currentMode == 'checkin'
                      ? Colors.green
                      : Colors.red).withOpacity(0.8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _currentMode == 'checkin' ? Icons.login : Icons.logout,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currentMode == 'checkin' ? 'CHẤM CÔNG VÀO' : 'CHẤM CÔNG RA',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_isAutoDetectionEnabled) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),

              // Current Time - Vietnam Timezone (UTC+7)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                ),
                child: Column(
                  children: [
                    StreamBuilder(
                      stream: Stream.periodic(const Duration(seconds: 1)),
                      builder: (context, snapshot) {
                        return Text(
                          VietnamTimeZone.formatTime(VietnamTimeZone.now(), useLocal: false),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    Text(
                      VietnamTimeZone.formatDayDate(VietnamTimeZone.now(), useLocal: false),
                      style: const TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    // Vietnam timezone indicator
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'UTC+7 (Việt Nam)',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Instructions overlay
              if (!_isProcessing)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _isCountingDown
                        ? '🎯 Đang xác nhận khuôn mặt...\nGiữ yên trong $_countdownSeconds giây'
                        : _isAutoDetectionEnabled
                            ? (_currentMode == 'checkin'
                                ? '🌅 Chấm công vào làm\n📍 Đặt khuôn mặt vào khung và giữ yên' // Bỏ số giây cho đỡ nhầm
                                : '🌇 Chấm công tan làm\n📍 Đặt khuôn mặt vào khung và giữ yên')
                            : (_currentMode == 'checkin'
                                ? '🌅 Chấm công vào làm\n👆 Bật chế độ tự động để nhận diện'
                                : '🌇 Chấm công tan làm\n👆 Bật chế độ tự động để nhận diện'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: _isCountingDown ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Face detection status
              if (_isAutoDetectionEnabled && !_isProcessing && !_isCountingDown)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _faceRect != null
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _faceRect != null
                          ? Colors.green.withOpacity(0.5)
                          : Colors.red.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _faceRect != null ? Icons.face : Icons.face_retouching_off,
                        color: _faceRect != null ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _faceRect != null
                            ? (_stableCounter > 5 
                                ? '✅ Phát hiện khuôn mặt ổn định'
                                : '👁️ Đang phát hiện khuôn mặt...')
                            : '🔍 Không phát hiện khuôn mặt',
                        style: TextStyle(
                          color: _faceRect != null ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // Last Result Display
              if (_lastResult != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _lastResult!.success ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _lastResult!.success ? Icons.check_circle : Icons.error,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _lastResult!.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

            ],
          ),


        ],
      ),
    );
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

  void _showNotImplementedDialog(VerifyEmployeeFaceResponse result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.construction,
          color: Colors.orange,
          size: 48,
        ),
        title: const Text(
          'Tính năng đang phát triển',
          style: TextStyle(color: Colors.orange),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.message,
              style: const TextStyle(fontSize: 16),
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
                      const Text(
                        'Thông tin:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('• Hệ thống nhận diện khuôn mặt AWS Rekognition'),
                  const Text('• Chấm công tự động qua camera'),
                  const Text('• Tính năng sẽ được hoàn thiện trong thời gian tới'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đã hiểu'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Có thể navigate đến màn hình chấm công manual hoặc thông báo khác
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
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
}

// Custom painter for face detection overlay
class FaceOverlayPainter extends CustomPainter {
  final Color color;
  final Rect? faceRect;
  final bool isStable;
  final Size? imageSize; // Kích thước ảnh gốc (ví dụ: 1280x720)
  final InputImageRotation? imageRotation;

  FaceOverlayPainter({
    required this.color,
    this.faceRect,
    this.isStable = false,
    this.imageSize,
    this.imageRotation,
  });

  // Hàm scale (giống hệt hàm trong _State)
  Rect _scaleRect(Rect rect, Size imageSize, Size screenSize, InputImageRotation rotation) {
    final bool isRotated = rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;
    
    final Size actualImageSize = isRotated
        ? Size(imageSize.height, imageSize.width)
        : imageSize;

    final double imageRatio = actualImageSize.width / actualImageSize.height;
    final double screenRatio = screenSize.width / screenSize.height;

    double scale;
    double offsetX = 0;
    double offsetY = 0;

    if (imageRatio > screenRatio) {
      scale = screenSize.height / actualImageSize.height;
      offsetX = (screenSize.width - actualImageSize.width * scale) / 2;
    } else {
      scale = screenSize.width / actualImageSize.width;
      offsetY = (screenSize.height - actualImageSize.height * scale) / 2;
    }

    return Rect.fromLTRB(
      (rect.left * scale) + offsetX,
      (rect.top * scale) + offsetY,
      (rect.right * scale) + offsetX,
      (rect.bottom * scale) + offsetY,
    );
  }

  @override
  void paint(Canvas canvas, Size size) { // 'size' là kích thước của CustomPaint (box 3:4)
    
    // 1. Vẽ khung tròn cố định
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.30; 
    final framePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, framePaint);
    _drawCornerGuides(canvas, center, radius, color, 32.0, 5.0);

    // 2. Vẽ khung di động nếu phát hiện được khuôn mặt
    if (faceRect != null && imageSize != null && imageRotation != null) {
      final faceColor = isStable ? Colors.green : Colors.orange;
      final focusBoxPaint = Paint()
        ..color = faceColor
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      // ✅ Dùng hàm scale
      final scaledRect = _scaleRect(faceRect!, imageSize!, size, imageRotation!);

      final focusPath = Path();
      focusPath.addRRect(RRect.fromRectAndRadius(scaledRect, const Radius.circular(12.0)));
      canvas.drawPath(focusPath, focusBoxPaint);

      // Draw corner guides for face box
      _drawCornerGuides(canvas, scaledRect.center, scaledRect.width / 2, faceColor, 24.0, 4.0);

      // Draw center crosshair
      final crosshairPaint = Paint()
        ..color = faceColor.withOpacity(0.8)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final crosshairSize = 8.0;
      // Horizontal line
      canvas.drawLine(
        Offset(scaledRect.center.dx - crosshairSize, scaledRect.center.dy),
        Offset(scaledRect.center.dx + crosshairSize, scaledRect.center.dy),
        crosshairPaint,
      );
      // Vertical line
      canvas.drawLine(
        Offset(scaledRect.center.dx, scaledRect.center.dy - crosshairSize),
        Offset(scaledRect.center.dx, scaledRect.center.dy + crosshairSize),
        crosshairPaint,
      );

      // Draw stability indicator
      if (isStable) {
        // Draw stable indicator circle
        canvas.drawCircle(
          Offset(scaledRect.right - 15, scaledRect.top + 15),
          12,
          Paint()..color = Colors.green.withOpacity(0.9),
        );

        // Draw checkmark
        final checkPath = Path();
        checkPath.moveTo(scaledRect.right - 20, scaledRect.top + 15);
        checkPath.lineTo(scaledRect.right - 15, scaledRect.top + 20);
        checkPath.lineTo(scaledRect.right - 10, scaledRect.top + 10);

        canvas.drawPath(
          checkPath,
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2.0
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  void _drawCornerGuides(Canvas canvas, Offset center, double radius, Color color, double cornerLength, double strokeWidth) {
    final cornerPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

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
  bool shouldRepaint(covariant FaceOverlayPainter oldDelegate) {
    return oldDelegate.color != color ||
           oldDelegate.faceRect != faceRect ||
           oldDelegate.isStable != isStable ||
           oldDelegate.imageSize != imageSize ||
           oldDelegate.imageRotation != imageRotation;
  }
}
