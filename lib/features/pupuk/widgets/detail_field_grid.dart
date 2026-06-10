import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

class DetailField {
  const DetailField({
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  final String label;
  final String? value;
  final bool fullWidth;
}

class DetailSectionCard extends StatelessWidget {
  const DetailSectionCard({
    super.key,
    required this.title,
    required this.fields,
    this.badge,
    this.initiallyExpanded = true,
  });

  final String title;
  final String? badge;
  final List<DetailField> fields;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final visibleFields = fields
        .where((f) => f.value != null && f.value!.trim().isNotEmpty)
        .toList();

    if (visibleFields.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.22),
          width: 0.75,
        ),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.md,
          ),
          title: Row(
            children: [
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          children: [DetailFieldGrid(fields: visibleFields)],
        ),
      ),
    );
  }
}

class DetailFieldGrid extends StatelessWidget {
  const DetailFieldGrid({super.key, required this.fields});

  final List<DetailField> fields;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 520;
        if (!useTwoColumns) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                _DetailFieldTile(field: fields[i]),
              ],
            ],
          );
        }

        final rows = <List<DetailField>>[];
        var currentRow = <DetailField>[];

        for (final field in fields) {
          if (field.fullWidth || currentRow.length == 2) {
            if (currentRow.isNotEmpty) {
              rows.add(currentRow);
              currentRow = [];
            }
            if (field.fullWidth) {
              rows.add([field]);
            } else {
              currentRow = [field];
            }
          } else {
            currentRow.add(field);
          }
        }
        if (currentRow.isNotEmpty) rows.add(currentRow);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var j = 0; j < rows[i].length; j++) ...[
                    if (j > 0) const SizedBox(width: AppSpacing.md),
                    Expanded(child: _DetailFieldTile(field: rows[i][j])),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DetailFieldTile extends StatelessWidget {
  const _DetailFieldTile({required this.field});

  final DetailField field;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            field.value ?? '–',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
