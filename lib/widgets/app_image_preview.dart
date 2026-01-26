import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

/// Reusable image preview for a file path. Use [onTap] to open full screen or other actions.
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
              errorBuilder: (_, Object err, StackTrace? st) => _placeholder(),
            )
          : _placeholder(),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      );
    }
    return child;
  }

  Widget _placeholder() {
    return Container(
      height: height ?? 200,
      width: width,
      color: AppColors.background,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            'Photo not found',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
