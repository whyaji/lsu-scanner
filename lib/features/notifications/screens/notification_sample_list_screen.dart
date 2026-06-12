import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../pupuk/screens/data_sampel_pupuk_detail_screen.dart';
import '../constants/notification_type_ui.dart';
import '../utils/notification_navigation.dart';

class NotificationSampleListScreen extends StatelessWidget {
  const NotificationSampleListScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.notificationType,
    required this.samples,
    this.noSurat,
    this.estate,
  });

  final String title;
  final String subtitle;
  final String notificationType;
  final List<NotificationSampleTarget> samples;
  final String? noSurat;
  final String? estate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeUi = notificationTypeUiFor(notificationType);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Sampel',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: AppSpacing.paddingScreen,
        children: [
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: typeUi.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: typeUi.color.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeUi.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeUi.icon, color: typeUi.color),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                      ),
                      if ((noSurat ?? '').isNotEmpty ||
                          (estate ?? '').isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if ((noSurat ?? '').isNotEmpty)
                              _MetaChip(
                                icon: Icons.description_outlined,
                                label: 'No. Surat: $noSurat',
                              ),
                            if ((estate ?? '').isNotEmpty)
                              _MetaChip(
                                icon: Icons.location_on_outlined,
                                label: estate!,
                              ),
                            _MetaChip(
                              icon: Icons.inventory_2_outlined,
                              label: '${samples.length} sampel',
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Ketuk sampel untuk melihat detail',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...samples.map(
            (sample) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DataSampelPupukDetailScreen(
                          id: sample.id,
                          preferOnline: true,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: AppSpacing.paddingMd,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: typeUi.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            typeUi.icon,
                            color: typeUi.color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sample.kodeSampel,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                typeUi.label,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
