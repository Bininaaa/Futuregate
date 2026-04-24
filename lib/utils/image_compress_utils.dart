import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressUtils {
  static const int _maxDimension = 1080;
  static const int _quality = 85;

  /// Compresses image bytes to JPEG, capping the longest edge at 1080 px.
  /// Returns the original bytes unchanged on web or on error.
  static Future<Uint8List> compress(Uint8List bytes) async {
    if (kIsWeb) return bytes;
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: _maxDimension,
        minHeight: _maxDimension,
        quality: _quality,
        format: CompressFormat.jpeg,
      );
      if (result.length < bytes.length) return result;
      return bytes;
    } catch (_) {
      return bytes;
    }
  }

  static bool isImage(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    return const {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'}.contains(ext);
  }
}
