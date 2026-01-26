import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../constants/app_constants.dart';

/// Helpers for the camera-only capture flow: Pictures dir, compress, gallery, watermark.
/// Used by [CameraView] and photo capture screens.
class PhotoCaptureHelper {
  PhotoCaptureHelper._();

  /// Returns the app pictures directory: [applicationDocumentsDirectory]/Pictures/[appName].
  /// Creates the directory if it does not exist.
  static Future<String> getAppPicturesDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final appName = AppConstants.appName;
    final dir = p.join(base.path, 'Pictures', appName);
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
  static Future<void> notifyGallery(String filePath) async {
    await MediaScanner.loadMedia(path: filePath);
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

  /// Generates a unique filename for a new capture (e.g. yyyyMMdd_HHmmss.jpg).
  static String newCaptureFileName() {
    final now = DateTime.now();
    final part =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return '$part.jpg';
  }
}
