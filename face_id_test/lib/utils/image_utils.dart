import 'dart:convert' as convert;

import 'package:camera/camera.dart';

class ImageUtils {
  const ImageUtils._();

  static Future<String> xFileToBase64(XFile file) async {
    final bytes = await file.readAsBytes();
    return convert.base64Encode(bytes);
  }
}
