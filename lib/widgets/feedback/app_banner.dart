import 'package:flutter/material.dart';

import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_spacing.dart';
import '../buttons/app_button.dart';
import '../buttons/app_icon_button.dart';
import 'app_notice_type.dart';

/// Inline notice for a screen or form level problem. Announced to screen readers when it appears.
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.type,
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction go together',
       );

  final AppNoticeType type;
  final String message;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = type.resolve(context);

    return Semantics(
      container: true,
      liveRegion: true,
      label: type.spokenLabel,
      child: Material(
        color: style.container,
        borderRadius: AppSizes.borderCard,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm + AppSpacing.xs,
            onDismiss == null ? AppSpacing.md : AppSpacing.xs,
            AppSpacing.sm + AppSpacing.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: ExcludeSemantics(
                  child: Icon(
                    style.icon,
                    color: style.accent,
                    size: AppSizes.iconMd,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: style.onContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.only(
                        top: title != null ? AppSpacing.xs : 2,
                      ),
                      child: Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: style.onContainer,
                        ),
                      ),
                    ),
                    if (actionLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: AppButton(
                          label: actionLabel!,
                          onPressed: onAction,
                          variant: AppButtonVariant.secondary,
                          size: AppButtonSize.compact,
                        ),
                      ),
                  ],
                ),
              ),
              if (onDismiss != null)
                AppIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Tutup pemberitahuan',
                  onPressed: onDismiss,
                  color: style.onContainer,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
