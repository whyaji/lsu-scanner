import 'package:flutter/material.dart';
import '../core/database/models/received_sample.dart';
import '../core/constants/app_constants.dart';

class SampleCard extends StatelessWidget {
  final ReceivedSample sample;
  final VoidCallback? onTap;

  const SampleCard({super.key, required this.sample, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    Color statusColor;
    IconData statusIcon;

    switch (sample.status) {
      case AppConstants.statusUploaded:
        statusColor = colorScheme.primary;
        statusIcon = Icons.cloud_done;
        break;
      case AppConstants.statusError:
        statusColor = colorScheme.error;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = colorScheme.tertiary;
        statusIcon = Icons.pending;
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.2),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          sample.kode,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: ${sample.tanggalTerima} ${sample.waktuTerima}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (sample.errorMessage != null)
              Text(
                'Error: ${sample.errorMessage}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
          ],
        ),
        trailing: Text(
          sample.status.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
