import 'dart:io';
import 'package:image/image.dart' as img;
import '../constants/app_constants.dart';

class ImageUtils {
  static Future<String?> compressImage(String imagePath) async {
    return compressImageToFile(imagePath, '${imagePath}_compressed.jpg');
  }

  /// Compresses image at [sourcePath] and writes to [targetPath].
  /// Uses [AppConstants] for quality, dimensions, and max size. Returns [targetPath] on success.
  static Future<String?> compressImageToFile(
    String sourcePath,
    String targetPath,
  ) async {
    try {
      final file = File(sourcePath);
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

      // Ensure output directory exists
      final outFile = File(targetPath);
      final parent = outFile.parent;
      if (!await parent.exists()) {
        await parent.create(recursive: true);
      }

      // Compress
      final compressedBytes = await recursiveCompressImage(resized);

      if (compressedBytes == null) {
        throw Exception('Compression failed');
      }

      await outFile.writeAsBytes(compressedBytes);
      return targetPath;
    } catch (e) {
      return null;
    }
  }

  static Future<List<int>?> recursiveCompressImage(
    img.Image image, {
    int? quality,
    int? maxWidth,
  }) async {
    try {
      final currentQuality = quality ?? AppConstants.imageCompressQuality;

      final compressedBytes = img.encodeJpg(image, quality: currentQuality);

      if (compressedBytes.length > AppConstants.maxImageSizeBytes) {
        return recursiveCompressImage(
          image,
          quality: (currentQuality * 0.7).round().clamp(10, 100),
        );
      }

      return compressedBytes;
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
