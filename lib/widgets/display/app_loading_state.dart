import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_spacing.dart';

/// Skeleton rows shaped like AppListItem. Shimmer colors are blended from onSurface so they read in light and dark. Stays still when the system reduces motion.
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    super.key,
    this.itemCount = 5,
    this.semanticLabel = 'Memuat data',
  });

  final int itemCount;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: 0.08),
      scheme.surface,
    );
    final highlight = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: 0.16),
      scheme.surface,
    );
    final still = MediaQuery.disableAnimationsOf(context);

    Widget bar(double? width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(4),
      ),
    );

    return Semantics(
      liveRegion: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          enabled: !still,
          child: ListView.separated(
            padding: AppSpacing.screenPaddingOf(context),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: itemCount,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            itemBuilder: (context, _) => Container(
              constraints: const BoxConstraints(
                minHeight: AppSizes.listItemMinHeight,
              ),
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                borderRadius: AppSizes.borderCard,
                border: Border.all(color: base),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(double.infinity, 16),
                  const SizedBox(height: AppSpacing.sm),
                  bar(160, 12),
                  const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                  bar(double.infinity, 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
