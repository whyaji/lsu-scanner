import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../buttons/app_button.dart';
import '../feedback/app_notice_type.dart';

/// A screen section failed to load. Say what failed and offer a retry when retrying can help.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel = 'Coba lagi',
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = AppNoticeType.error.resolve(context);

    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  style.icon,
                  size: 40,
                  color: style.accent,
                  semanticLabel: AppNoticeType.error.spokenLabel,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (onRetry != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: retryLabel,
                    onPressed: onRetry,
                    variant: AppButtonVariant.secondary,
                    icon: Icons.refresh_rounded,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
