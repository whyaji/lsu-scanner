import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class CustomProgressIndicator extends StatelessWidget {
  final int current;
  final int total;
  final String? currentItem;

  const CustomProgressIndicator({
    super.key,
    required this.current,
    required this.total,
    this.currentItem,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (current / total * 100).round();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Uploading',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$current / $total ($percentage%)',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            if (currentItem != null) ...[
              const SizedBox(height: 8),
              Text(
                'Current: $currentItem',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
