import 'package:flutter/material.dart';

import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_spacing.dart';
import '../buttons/app_button.dart';
import 'app_dismiss_on_escape.dart';
import 'app_notice_type.dart';

/// One dialog button. List the primary action first: it renders on top when stacked.
@immutable
class AppDialogAction {
  const AppDialogAction({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback onPressed;
  final AppButtonVariant variant;
  final bool autofocus;
}

/// Layout of every dialog: tone icon, title, message, actions. Stacks buttons on narrow widths.
class AppDialogShell extends StatelessWidget {
  const AppDialogShell({
    super.key,
    required this.title,
    this.type,
    this.message,
    this.content,
    this.actions = const [],
    this.dismissible = true,
  });

  final String title;
  final AppNoticeType? type;
  final String? message;
  final Widget? content;
  final List<AppDialogAction> actions;
  final bool dismissible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = type?.resolve(context);

    return PopScope(
      canPop: dismissible,
      child: AppDismissOnEscape(
        enabled: dismissible,
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: title,
          child: Dialog(
            backgroundColor: theme.colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 6,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            shape: RoundedRectangleBorder(borderRadius: AppSizes.borderDialog),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSizes.dialogMaxWidth),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (style != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              style.icon,
                              color: style.accent,
                              size: AppSizes.iconMd,
                              semanticLabel: type!.spokenLabel,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                        ],
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (message != null || content != null)
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (message != null)
                                Text(
                                  message!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              if (content != null) content!,
                            ],
                          ),
                        ),
                      ),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _Actions(actions: actions),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.actions});

  final List<AppDialogAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            actions.length > 2 ||
            constraints.maxWidth < AppSizes.dialogStackBreakpoint;

        Widget button(AppDialogAction a) => AppButton(
          label: a.label,
          onPressed: a.onPressed,
          variant: a.variant,
          size: AppButtonSize.compact,
          autofocus: a.autofocus,
          fullWidth: true,
        );

        if (stacked) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                button(actions[i]),
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var i = actions.length - 1; i >= 0; i--) ...[
              if (i < actions.length - 1) const SizedBox(width: AppSpacing.sm),
              Expanded(child: button(actions[i])),
            ],
          ],
        );
      },
    );
  }
}
