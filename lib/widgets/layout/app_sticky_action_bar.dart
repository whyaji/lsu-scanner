import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../buttons/app_button.dart';

/// Bottom bar with the screen's one primary action and an optional secondary one.
/// Sits above the keyboard when used as AppPage.bottomBar and keeps clear of the gesture bar.
class AppStickyActionBar extends StatelessWidget {
  const AppStickyActionBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryIcon,
    this.primaryLoading = false,
    this.secondaryLabel,
    this.onSecondary,
    this.horizontal = false,
  }) : assert(
         (secondaryLabel == null) == (onSecondary == null),
         'secondaryLabel and onSecondary go together',
       );

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final IconData? primaryIcon;
  final bool primaryLoading;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Keeps both actions on one row. Otherwise they stack on a narrow phone or at large text.
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = AppButton(
      label: primaryLabel,
      onPressed: onPrimary,
      icon: primaryIcon,
      loading: primaryLoading,
      fullWidth: true,
    );

    return Material(
      color: scheme.surface,
      shape: Border(top: BorderSide(color: scheme.outlineVariant)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: secondaryLabel == null
              ? primary
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final secondary = AppButton(
                      label: secondaryLabel!,
                      onPressed: onSecondary,
                      variant: AppButtonVariant.secondary,
                      fullWidth: true,
                    );
                    final scale = MediaQuery.textScalerOf(context).scale(1);
                    final stack =
                        !horizontal &&
                        (constraints.maxWidth < 360 || scale > 1.15);
                    if (stack) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          primary,
                          const SizedBox(height: AppSpacing.sm),
                          secondary,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: secondary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(flex: 2, child: primary),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}
