import 'dart:io';
import 'package:image/image.dart' as img;
import '../constants/app_constants.dart';

class ImageUtils {
  static Future<String?> compressImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file not found');
      }

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Invalid image');
      }

      // Resize if needed
      img.Image resized = image;
      if (image.width > AppConstants.imageMaxWidth) {
        resized = img.copyResize(
          image,
          width: AppConstants.imageMaxWidth,
          maintainAspect: true,
        );
      }

      // Compress
      final compressedBytes = img.encodeJpg(
        resized,
        quality: AppConstants.imageCompressQuality,
      );

      // Check size
      if (compressedBytes.length > AppConstants.maxImageSizeBytes) {
        // Further compress if still too large
        final quality = (AppConstants.imageCompressQuality * 0.7).round();
        final furtherCompressed = img.encodeJpg(resized, quality: quality);

        if (furtherCompressed.length > AppConstants.maxImageSizeBytes) {
          throw Exception('Image too large even after compression');
        }

        // Save further compressed
        final compressedPath = '${imagePath}_compressed.jpg';
        await File(compressedPath).writeAsBytes(furtherCompressed);
        return compressedPath;
      }

      // Save compressed
      final compressedPath = '${imagePath}_compressed.jpg';
      await File(compressedPath).writeAsBytes(compressedBytes);
      return compressedPath;
    } catch (e) {
      return null;
    }
  }

  static String getFileName(String path) {
    return path.split('/').last;
  }

  static Future<bool> validateImageSize(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return false;

      final size = await file.length();
      return size <= AppConstants.maxImageSizeBytes;
    } catch (e) {
      return false;
    }
  }

  static bool isValidImageFormat(String path) {
    final extension = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png'].contains(extension);
  }
}
