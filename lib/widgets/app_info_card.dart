import 'package:flutter/material.dart';
import '../core/theme/app_spacing.dart';

/// Card with a title and a list of key-value rows. Use for sample info, master LSU, etc.
class AppInfoCard extends StatelessWidget {
  const AppInfoCard({
    super.key,
    required this.title,
    required this.rows,
    this.child,
  });

  final String title;
  final List<AppKeyValueRow> rows;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            if (rows.isNotEmpty) ...[
              AppSpacing.gapMd,
              ...rows.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _KeyValueRowWidget(
                    label: r.label,
                    value: r.value,
                    valueColor: r.valueColor,
                  ),
                ),
              ),
            ],
            if (child != null) ...[
              if (rows.isNotEmpty) AppSpacing.gapSm,
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Single key-value row for use in AppInfoCard or standalone.
class AppKeyValueRow {
  const AppKeyValueRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;
}

class _KeyValueRowWidget extends StatelessWidget {
  const _KeyValueRowWidget({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor ?? colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
