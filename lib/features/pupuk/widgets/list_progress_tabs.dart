import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../constants/data_sampel_pupuk_progress.dart';

class ListProgressTabs extends StatelessWidget {
  const ListProgressTabs({
    super.key,
    required this.tabs,
    required this.value,
    required this.counts,
    required this.onChanged,
    this.isLoading = false,
  });

  final List<DataSampelPupukProgressTab> tabs;
  final DataSampelPupukProgress value;
  final Map<DataSampelPupukProgress, int> counts;
  final ValueChanged<DataSampelPupukProgress> onChanged;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isActive = tab.id == value;
          final count = counts[tab.id] ?? 0;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onChanged(tab.id),
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? tab.color.withValues(alpha: 0.14)
                      : colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.55,
                        ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isActive
                        ? tab.color.withValues(alpha: 0.65)
                        : colorScheme.outline.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 18,
                      color: isActive
                          ? tab.color
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive
                            ? tab.color.darken()
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isLoading)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: tab.color,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? tab.color
                              : colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.12,
                                ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$count',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? Colors.white
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

extension _ColorDarken on Color {
  Color darken([double amount = 0.15]) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}
