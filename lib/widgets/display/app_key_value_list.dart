import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

@immutable
class AppKeyValue {
  const AppKeyValue({required this.label, this.value, this.valueWidget});

  final String label;
  final String? value;
  final Widget? valueWidget;
}

/// Detail rows with the label above the value, so long values wrap instead of squeezing a second column.
/// Missing values show a dash.
class AppKeyValueList extends StatelessWidget {
  const AppKeyValueList({super.key, required this.items, this.selectable = true});

  final List<AppKeyValue> items;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            Divider(height: AppSpacing.md * 2, color: scheme.outlineVariant),
          _row(context, items[i]),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, AppKeyValue item) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = (item.value == null || item.value!.isEmpty) ? '-' : item.value!;
    final label = Text(
      item.label,
      style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label,
        const SizedBox(height: AppSpacing.xs),
        item.valueWidget ??
            (selectable
                ? SelectableText(text, style: theme.textTheme.bodyLarge)
                : Text(text, style: theme.textTheme.bodyLarge)),
      ],
    );
    if (item.valueWidget != null) return body;
    return Semantics(
      container: true,
      label: item.label,
      value: text == '-' ? 'belum diisi' : text,
      excludeSemantics: true,
      child: body,
    );
  }
}
