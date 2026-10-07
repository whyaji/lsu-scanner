import 'package:flutter/material.dart';

import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_spacing.dart';

/// Square photo preview. Pass FileImage, NetworkImage or any ImageProvider.
/// With onRemove it carries a 48dp remove target in the top right corner.
class AppPhotoThumb extends StatelessWidget {
  const AppPhotoThumb({
    super.key,
    required this.image,
    required this.semanticLabel,
    this.size = 88,
    this.onTap,
    this.onRemove,
  });

  final ImageProvider image;
  final String semanticLabel;
  final double size;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  static const double _removeOverhang = 16;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final picture = Semantics(
      image: true,
      button: onTap != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: AppSizes.borderChip,
        child: SizedBox(
          width: size,
          height: size,
          child: Material(
            color: scheme.surfaceContainerHighest,
            child: Ink.image(
              image: image,
              fit: BoxFit.cover,
              onImageError: (_, _) {},
              child: InkWell(onTap: onTap),
            ),
          ),
        ),
      ),
    );

    if (onRemove == null) return picture;

    return SizedBox(
      width: size + _removeOverhang,
      height: size + _removeOverhang,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: picture,
          ),
          Positioned(
            top: 0,
            right: 0,
            child: SizedBox(
              width: AppSizes.tapTarget,
              height: AppSizes.tapTarget,
              child: Tooltip(
                message: 'Hapus foto',
                child: Semantics(
                  button: true,
                  label: 'Hapus $semanticLabel',
                  excludeSemantics: true,
                  child: InkResponse(
                    onTap: onRemove,
                    radius: AppSizes.tapTarget / 2,
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.outline),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
