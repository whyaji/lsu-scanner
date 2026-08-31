import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../features/sample/screens/full_screen_image_preview_screen.dart';

/// Reusable image preview for a file path. Use [onTap] to open custom actions,
/// or leave it null to automatically launch the full screen preview (with zoom, share, download).
class AppImagePreview extends StatelessWidget {
  final String imagePath;
  final double? height;
  final double? width;
  final BoxFit fit;
  final double borderRadius;
  final VoidCallback? onTap;

  const AppImagePreview({
    super.key,
    required this.imagePath,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius = 8,
    this.onTap,
  });

  String _getFileSize(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = file.lengthSync();
        if (bytes <= 0) return '0 B';
        if (bytes < 1024) return '$bytes B';
        if (bytes < 1024 * 1024)
          return '${(bytes / 1024).toStringAsFixed(1)} KB';
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (_) {}
    return '0 B';
  }

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);
    final child = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: file.existsSync()
          ? Image.file(
              file,
              height: height,
              width: width,
              fit: fit,
              errorBuilder: (_, Object err, StackTrace? st) =>
                  _placeholder(context),
            )
          : _placeholder(context),
    );

    return InkWell(
      onTap:
          onTap ??
          () {
            final isLsu = imagePath.contains('LSU');
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => FullScreenImagePreviewScreen(
                  imagePath: imagePath,
                  title: isLsu ? 'LSU Sample' : 'Pupuk Sample',
                  showDetails: true,
                  details: {
                    'Kategori': isLsu ? 'LSU (Sample)' : 'Pupuk (Fertilizer)',
                    'Nama File': p.basename(imagePath),
                    'Ukuran File': _getFileSize(imagePath),
                  },
                ),
              ),
            );
          },
      borderRadius: BorderRadius.circular(borderRadius),
      child: child,
    );
  }

  Widget _placeholder(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      height: height ?? 200,
      width: width,
      color: colorScheme.surfaceVariant,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Foto tidak ditemukan',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
