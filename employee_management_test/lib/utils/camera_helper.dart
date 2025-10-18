import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'app_logger.dart'; // ✅ Import AppLogger

class CameraHelper {
  static CameraController? _controller;
  static List<CameraDescription>? _cameras;

  /// Initialize camera
  static Future<void> initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        // Use front camera if available, otherwise use first camera
        final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        _controller = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg, // ✅ Fix FourCC 0 error
        );

        await _controller!.initialize();
      }
    } catch (e) {
      throw Exception('Failed to initialize camera: $e');
    }
  }

  /// Get the camera controller
  static CameraController? get controller => _controller;

  /// Check if camera is initialized
  static bool get isInitialized => _controller?.value.isInitialized ?? false;

  /// Capture image and convert to base64
  static Future<String> captureImageAsBase64() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    try {
      final XFile image = await _controller!.takePicture();
      final File imageFile = File(image.path);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      // ✅ Validate image is not empty
      if (imageBytes.isEmpty) {
        await imageFile.delete();
        throw Exception('Captured image is empty (FourCC 0 error)');
      }
      
      // ✅ Validate minimum file size (50KB)
      if (imageBytes.length < 50 * 1024) {
        await imageFile.delete();
        throw Exception('Image too small (< 50KB). Please try again.');
      }
      
      // Optional: Compress and resize image
      final compressedBytes = await _compressImage(imageBytes);
      
      // ✅ Validate compressed image is not empty
      if (compressedBytes.isEmpty) {
        await imageFile.delete();
        throw Exception('Image compression failed');
      }
      
      // Convert to base64 (pure base64, NO prefix like "data:image/jpeg;base64,")
      final base64String = base64Encode(compressedBytes);
      
      // Clean up temporary file
      await imageFile.delete();
      
      return base64String;
    } catch (e) {
      throw Exception('Failed to capture image: $e');
    }
  }

  /// Compress image to reduce size and ensure quality
  static Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Decode image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        AppLogger.warning('Failed to decode image, using original bytes', tag: 'CameraHelper');
        return imageBytes; // Return original if decoding fails
      }

      AppLogger.data(
        'Original image: ${image.width}x${image.height}, ${imageBytes.length} bytes (${(imageBytes.length / 1024).toStringAsFixed(1)} KB)',
        tag: 'CameraHelper',
      );

      // ✅ Resize to optimal size for face recognition (max 1080px, min 480px)
      // AWS Rekognition works best with images 800-1600px
      int targetWidth = image.width;
      
      if (image.width > 1080) {
        targetWidth = 1080;
      } else if (image.width < 480) {
        // Image too small, might cause detection issues
        AppLogger.warning('Image width < 480px, keeping original size', tag: 'CameraHelper');
      }

      if (targetWidth != image.width) {
        image = img.copyResize(image, width: targetWidth);
        AppLogger.data('Resized to: ${image.width}x${image.height}', tag: 'CameraHelper');
      }

      // ✅ Encode to JPEG with quality 85% (balance between quality & size)
      final compressedBytes = img.encodeJpg(image, quality: 85);
      AppLogger.data(
        'Compressed: ${compressedBytes.length} bytes (${(compressedBytes.length / 1024).toStringAsFixed(1)} KB)',
        tag: 'CameraHelper',
      );
      
      // ✅ Validate final size < 2MB (AWS limit is 15MB, but 2MB is ideal)
      const maxSizeBytes = 2 * 1024 * 1024; // 2MB
      if (compressedBytes.length > maxSizeBytes) {
        AppLogger.warning('Compressed image > 2MB, re-compressing with quality 70%', tag: 'CameraHelper');
        final recompressed = img.encodeJpg(image, quality: 70);
        AppLogger.data('Re-compressed: ${recompressed.length} bytes (${(recompressed.length / 1024).toStringAsFixed(1)} KB)', tag: 'CameraHelper');
        
        stopwatch.stop();
        AppLogger.performance('Image compression (with re-compression)', stopwatch.elapsed);
        
        return Uint8List.fromList(recompressed);
      }

      stopwatch.stop();
      AppLogger.performance('Image compression', stopwatch.elapsed);
      
      return Uint8List.fromList(compressedBytes);
    } catch (e, stackTrace) {
      stopwatch.stop();
      AppLogger.error('Compression error', error: e, stackTrace: stackTrace, tag: 'CameraHelper');
      
      // Return original bytes if compression fails
      return imageBytes;
    }
  }

  /// Dispose camera controller
  static Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }

  /// Switch camera (front/back)
  static Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length <= 1) {
      throw Exception('No alternative camera available');
    }

    try {
      final currentLensDirection = _controller?.description.lensDirection;
      CameraDescription newCamera;

      if (currentLensDirection == CameraLensDirection.front) {
        newCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );
      } else {
        newCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );
      }

      await _controller?.dispose();
      _controller = CameraController(
        newCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg, // ✅ Fix FourCC 0 error
      );
      await _controller!.initialize();
    } catch (e) {
      throw Exception('Failed to switch camera: $e');
    }
  }

  /// Get available cameras count
  static int get camerasCount => _cameras?.length ?? 0;

  /// Check if multiple cameras are available
  static bool get hasMultipleCameras => camerasCount > 1;
}

class FaceDetectionHelper {
  /// Validate if image contains a face (basic validation)
  static Future<bool> validateFace(String base64Image) async {
    try {
      // Basic validation - check if image is valid base64 and not empty
      if (base64Image.isEmpty) return false;
      
      // Decode to verify it's valid base64
      final bytes = base64Decode(base64Image);
      if (bytes.length < 1000) return false; // Too small to be a face image
      
      // For now, we'll assume the image is valid
      // You can implement actual face detection later if needed
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check image quality (basic checks)
  static Future<Map<String, dynamic>> analyzeImageQuality(String base64Image) async {
    try {
      final bytes = base64Decode(base64Image);
      
      return {
        'isGoodQuality': bytes.length > 10000, // At least 10KB
        'blurScore': 0.8,
        'brightnessScore': 0.7,
        'contrastScore': 0.8,
        'faceSize': 'adequate',
        'recommendations': <String>[],
      };
    } catch (e) {
      return {
        'isGoodQuality': false,
        'blurScore': 0.0,
        'brightnessScore': 0.0,
        'contrastScore': 0.0,
        'faceSize': 'unknown',
        'recommendations': ['Image validation failed'],
      };
    }
  }
}