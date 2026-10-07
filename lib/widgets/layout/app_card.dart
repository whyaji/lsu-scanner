import 'package:flutter/material.dart';

import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_spacing.dart';

/// Same surface as the home screen cards: themed [Card] elevation, no outline.
/// With onTap it gets ink feedback, button semantics and a 48dp minimum height.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = AppSpacing.paddingMd,
    this.semanticLabel,
    this.selected = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cardTheme = Theme.of(context).cardTheme;
    final baseShape =
        cardTheme.shape ??
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        );
    final shape = selected
        ? RoundedRectangleBorder(
            borderRadius: baseShape is RoundedRectangleBorder
                ? baseShape.borderRadius
                : AppSizes.borderCard,
            side: BorderSide(color: scheme.primary, width: 2),
          )
        : baseShape;

    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.tapTarget),
        child: InkWell(onTap: onTap, customBorder: shape, child: content),
      );
    }

    final card = Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.none,
      semanticContainer: false,
      shape: shape,
      child: content,
    );

    if (onTap == null && semanticLabel == null) return card;
    return Semantics(
      container: true,
      button: onTap != null,
      selected: selected,
      label: semanticLabel,
      child: card,
    );
  }
}
