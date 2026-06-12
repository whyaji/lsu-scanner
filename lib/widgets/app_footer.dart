import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_spacing.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key, this.color, this.logoHeight = 32});

  final Color? color;
  final double logoHeight;

  static const _logoAsset = 'assets/images/srs-logo.png';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor =
        color ?? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(_logoAsset, height: logoHeight, fit: BoxFit.contain),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${AppConstants.appName} v${AppConstants.appVersion}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Powered by Digital Architect SRS',
          style: theme.textTheme.labelSmall?.copyWith(
            color: textColor.withValues(alpha: 0.8),
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
