import 'package:flutter/material.dart';
import '../core/theme/app_spacing.dart';

class CustomProgressIndicator extends StatelessWidget {
  final int current;
  final int total;
  final String? currentItem;

  const CustomProgressIndicator({
    super.key,
    required this.current,
    required this.total,
    this.currentItem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percentage = (current / total * 100).round();

    return Card(
      margin: AppSpacing.paddingScreen,
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mengunggah',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            AppSpacing.gapMd,
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
            AppSpacing.gapSm,
            Text(
              '$current / $total ($percentage%)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (currentItem != null) ...[
              AppSpacing.gapSm,
              Text(
                'Saat ini: $currentItem',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
