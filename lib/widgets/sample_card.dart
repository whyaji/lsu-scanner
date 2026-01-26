import 'package:flutter/material.dart';
import '../core/database/models/received_sample.dart';
import '../core/constants/app_constants.dart';

class SampleCard extends StatelessWidget {
  final ReceivedSample sample;
  final VoidCallback? onTap;

  const SampleCard({super.key, required this.sample, this.onTap});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (sample.status) {
      case AppConstants.statusUploaded:
        statusColor = AppColors.success;
        statusIcon = Icons.cloud_done;
        break;
      case AppConstants.statusError:
        statusColor = AppColors.error;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = AppColors.warning;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.2),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          sample.kode,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: ${sample.tanggalTerima} ${sample.waktuTerima}',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            if (sample.errorMessage != null)
              Text(
                'Error: ${sample.errorMessage}',
                style: TextStyle(color: AppColors.error, fontSize: 12),
              ),
          ],
        ),
        trailing: Text(
          sample.status.toUpperCase(),
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
