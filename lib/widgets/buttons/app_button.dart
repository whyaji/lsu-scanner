import 'package:flutter/material.dart';

import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, tonal, text, destructive }

enum AppButtonSize { regular, compact }

/// The one button for the app. Use a single primary per screen; loading keeps the resting width.
/// With fullWidth: true place it in a bounded-width parent (Column, Expanded), not a bare Row.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.icon,
    this.loading = false,
    this.fullWidth = false,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = size == AppButtonSize.regular
        ? AppSizes.buttonHeight
        : AppSizes.buttonHeightCompact;
    final enabled = onPressed != null && !loading;
    final callback = enabled ? onPressed : null;

    final (Color bg, Color fg, BorderSide? side) = switch (variant) {
      AppButtonVariant.primary => (scheme.primary, scheme.onPrimary, null),
      AppButtonVariant.destructive => (scheme.error, scheme.onError, null),
      AppButtonVariant.tonal => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        null,
      ),
      AppButtonVariant.secondary => (
        Colors.transparent,
        scheme.primary,
        BorderSide(color: scheme.outline),
      ),
      AppButtonVariant.text => (Colors.transparent, scheme.primary, null),
    };

    final disabledFg = scheme.onSurface.withValues(alpha: 0.38);
    final disabledBg =
        variant == AppButtonVariant.text ||
            variant == AppButtonVariant.secondary
        ? Colors.transparent
        : scheme.onSurface.withValues(alpha: 0.12);

    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(fullWidth ? double.infinity : 88, height),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
      ),
      tapTargetSize: MaterialTapTargetSize.padded,
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: AppSizes.borderButton),
      ),
      elevation: const WidgetStatePropertyAll(0),
      textStyle: WidgetStatePropertyAll(
        Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.disabled) && !loading ? disabledBg : bg,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.disabled) && !loading ? disabledFg : fg,
      ),
      side: side == null
          ? null
          : WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled) && !loading
                  ? BorderSide(color: scheme.onSurface.withValues(alpha: 0.12))
                  : side,
            ),
    );

    final content = _Content(label: label, icon: icon);
    final child = loading
        ? Stack(
            alignment: Alignment.center,
            children: [
              Opacity(opacity: 0, child: ExcludeSemantics(child: content)),
              SizedBox(
                width: AppSizes.iconSm,
                height: AppSizes.iconSm,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
              ),
            ],
          )
        : content;

    final button = switch (variant) {
      AppButtonVariant.text => TextButton(
        onPressed: callback,
        autofocus: autofocus,
        style: style,
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: callback,
        autofocus: autofocus,
        style: style,
        child: child,
      ),
      _ => FilledButton(
        onPressed: callback,
        autofocus: autofocus,
        style: style,
        child: child,
      ),
    };

    final wrapped = fullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
    if (!loading) return wrapped;
    return Semantics(
      button: true,
      enabled: false,
      label: '$label, sedang diproses',
      excludeSemantics: true,
      child: wrapped,
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.label, required this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (icon == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconSm),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: text),
      ],
    );
  }
}
