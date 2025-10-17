import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageConverter {
  /// Convert image bytes to Base64 string
  /// Optionally resize to reduce payload size
  static String toBase64(Uint8List imageBytes, {int? maxWidth}) {
    if (maxWidth != null) {
      // Decode image
      img.Image? image = img.decodeImage(imageBytes);
      
      if (image != null && image.width > maxWidth) {
        // Resize image maintaining aspect ratio
        image = img.copyResize(image, width: maxWidth);
        
        // Encode back to JPEG
        final resizedBytes = img.encodeJpg(image, quality: 85);
        return base64Encode(resizedBytes);
      }
    }
    
    // Return original if no resize needed
    return base64Encode(imageBytes);
  }

  /// Convert Base64 string back to bytes (for preview)
  static Uint8List fromBase64(String base64String) {
    return base64Decode(base64String);
  }
}
