import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Helpers for the camera-only capture flow: Pictures dir, compress, gallery, watermark.
/// Used by [CameraView] and photo capture screens.
class PhotoCaptureHelper {
  PhotoCaptureHelper._();

  /// Returns the app pictures directory.
  /// Stored securely inside the application's documents directory.
  /// If [feature] is provided, it returns the folder under that feature subdirectory (e.g. LSU or Pupuk).
  /// Creates the directory if it does not exist.
  static Future<String> getAppPicturesDirectory({String? feature}) async {
    const subDir = 'SampleTrack';
    final base = await getApplicationDocumentsDirectory();
    String dir = p.join(base.path, 'Pictures', subDir);
    if (feature != null && feature.isNotEmpty) {
      dir = p.join(dir, feature);
    }
    await Directory(dir).create(recursive: true);
    return dir;
  }

  /// Compresses [sourcePath] and writes to [outputDir] with optional [outputFileName].
  /// Uses [AppConstants] for quality and dimensions. Returns the saved file path or null.
  static Future<String?> compressAndSave({
    required String sourcePath,
    required String outputDir,
    String? outputFileName,
  }) async {
    final name = outputFileName ?? p.basename(sourcePath);
    final targetPath = p.join(outputDir, name);
    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      targetPath,
      quality: AppConstants.imageCompressQuality,
      minWidth: AppConstants.imageMaxWidth,
      minHeight: AppConstants.imageMaxHeight,
    );
    return result?.path;
  }

  /// Notifies the system so the saved image appears in the user gallery.
  /// Note: Only attempts to scan if it's stored in public/external storage.
  static Future<void> notifyGallery(String filePath) async {
    try {
      // Private internal storage files cannot/should not be scanned by system media scanner.
      if (filePath.contains('app_flutter') || filePath.contains('data/user')) {
        return;
      }
      await MediaScanner.loadMedia(path: filePath);
    } catch (_) {
      // Fail silently for internal/private paths
    }
  }

  /// Applies a three-line text watermark at bottom-right using [image] package.
  /// Each line has a tight background (width = text width, height = text height + padding), right-aligned, text centered in box, small gap between lines.
  static Future<String?> applyWatermark({
    required String sourcePath,
    required String watermarkText,
    int imageWidth = 1080,
    int imageHeight = 810,
  }) async {
    final bytes = await File(sourcePath).readAsBytes();
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final w = decoded.width;
    final h = decoded.height;

    final lines = watermarkText
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (lines.isEmpty) return sourcePath;

    const edgeMargin = 12;
    const paddingH = 8;
    const paddingV = 8;
    const lineGap = 1;
    final font = img.arial48;
    final fontColor = img.ColorRgba8(255, 255, 0, 255);
    final bgColor = img.ColorRgba8(0, 0, 0, 120);

    int measureWidth(img.BitmapFont f, String s) {
      int sw = 0;
      for (final c in s.codeUnits) {
        final ch = f.characters[c];
        if (ch != null) {
          sw += ch.xAdvance;
        } else {
          sw += f.base ~/ 2;
        }
      }
      return sw;
    }

    int measureHeight(img.BitmapFont f, String s) {
      int sh = 0;
      for (final c in s.codeUnits) {
        final ch = f.characters[c];
        if (ch != null && ch.height + ch.yOffset > sh) {
          sh = ch.height + ch.yOffset;
        }
      }
      return sh > 0 ? sh : f.lineHeight;
    }

    final lineHeights = <int>[];
    for (final line in lines) {
      lineHeights.add(measureHeight(font, line));
    }
    int currentY = h - edgeMargin;
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      final tw = measureWidth(font, line);
      final th = lineHeights[i];
      final boxW = tw + paddingH * 2;
      final boxH = th + paddingV * 2;
      currentY -= boxH;
      final boxLeft = (w - edgeMargin - boxW).clamp(0, w - 1);
      final boxTop = currentY.clamp(0, h - 1);
      final boxRight = (boxLeft + boxW).clamp(0, w);
      final boxBottom = (boxTop + boxH).clamp(0, h);
      img.fillRect(
        decoded,
        x1: boxLeft,
        y1: boxTop,
        x2: boxRight,
        y2: boxBottom,
        color: bgColor,
        alphaBlend: true,
      );
      final textRight = w - edgeMargin - paddingH;
      final textTop = boxTop + paddingV;
      img.drawString(
        decoded,
        line,
        font: font,
        x: textRight,
        y: textTop,
        color: fontColor,
        rightJustify: true,
      );
      currentY -= lineGap;
    }

    final outBytes = img.encodeJpg(
      decoded,
      quality: AppConstants.imageCompressQuality,
    );
    await File(sourcePath).writeAsBytes(outBytes);
    return sourcePath;
  }

  /// Sanitizes a string for use in a filename: replaces spaces with '_',
  /// removes characters that are invalid in typical filesystems.
  static String _sanitizeForFileName(String? value) {
    if (value == null || value.isEmpty) return '';
    return value
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^\w\-.]'), '');
  }

  /// Generates a unique filename for a new capture.
  /// Optional [userId], [dataId], [sampelKode], [blok] are sanitized (spaces → '_')
  /// and included as a prefix, e.g. userId_dataId_sampelKode_blok_yyyyMMdd_HHmmss.jpg.
  static String newCaptureFileName({
    String? userId,
    String? dataId,
    String? sampelKode,
    String? blok,
  }) {
    final parts = [
      _sanitizeForFileName(userId),
      _sanitizeForFileName(dataId),
      _sanitizeForFileName(sampelKode),
      _sanitizeForFileName(blok),
    ].where((e) => e.isNotEmpty);
    final sufix = parts.isEmpty ? '' : '_${parts.join('_')}';

    final now = DateTime.now();
    final part =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return '$part$sufix.jpg';
  }

  /// Exports a saved image file to the public storage/Downloads directory.
  /// On Android: `/storage/emulated/0/Download/SampleTrack/[feature]`.
  /// On iOS/other: application documents directory under `SampleTrack/[feature]`.
  static Future<String?> exportToDownloads(
    String sourcePath, {
    required String feature,
  }) async {
    try {
      final file = File(sourcePath);
      if (!await file.exists()) return null;

      String targetDir;
      if (Platform.isAndroid) {
        targetDir = '/storage/emulated/0/Download/SampleTrack/$feature';
      } else {
        final base = await getApplicationDocumentsDirectory();
        targetDir = p.join(base.path, 'SampleTrack', feature);
      }

      await Directory(targetDir).create(recursive: true);
      final fileName = p.basename(sourcePath);
      final targetPath = p.join(targetDir, fileName);

      await file.copy(targetPath);

      // Call media scanner on the public exported file so it is visible in the Gallery.
      if (Platform.isAndroid) {
        await notifyGallery(targetPath);
      }
      return targetPath;
    } catch (e) {
      debugPrint('Failed to export photo: $e');
      return null;
    }
  }

  /// Checks if auto-download is enabled and automatically exports the photo.
  static Future<void> handleAutoDownload(
    String savedPath, {
    required String feature,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('auto_download_enabled') ?? false;
      if (isEnabled) {
        await exportToDownloads(savedPath, feature: feature);
      }
    } catch (_) {}
  }
}
