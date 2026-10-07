import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Label rendered above a control, with an explicit "wajib" marker instead of a bare asterisk.
class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel({super.key, required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.labelGap),
      child: Text.rich(
        TextSpan(
          text: label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          children: [
            if (required)
              TextSpan(
                text: ' (wajib)',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
