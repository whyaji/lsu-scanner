import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../buttons/app_icon_button.dart';
import '../layout/app_card.dart';

/// Card for one repeated entry (for example one test parameter) with a remove action.
/// Hide the remove action by leaving onRemove null, such as when only one entry may exist.
class AppRepeaterCard extends StatelessWidget {
  const AppRepeaterCard({
    super.key,
    required this.title,
    required this.children,
    this.onRemove,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (onRemove != null)
                AppIconButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Hapus $title',
                  onPressed: onRemove,
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.fieldGap),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
