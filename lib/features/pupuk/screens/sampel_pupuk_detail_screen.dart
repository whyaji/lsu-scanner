import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../constants/pupuk_activity_types.dart';

import '../models/pupuk_sampel_entry.dart';
import '../widgets/pupuk_sampel_info_card.dart';
import 'sampel_pupuk_activity_form_screen.dart';

/// Konfirmasi keluar dari detail — user dapat memindai QR ulang.

Future<bool> _showDetailBackDialog(
  BuildContext context, {
  required bool isActivityConfirmation,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return AlertDialog(
        icon: Icon(Icons.qr_code_scanner_rounded, size: 40, color: cs.primary),
        iconColor: cs.primary,
        title: Text(
          isActivityConfirmation
              ? 'Batalkan konfirmasi?'
              : 'Kembali dan pindai ulang?',
        ),
        content: Text(
          isActivityConfirmation
              ? 'Apakah Anda yakin ingin kembali?\n\n'
                    'Data sampel belum dikonfirmasi. Anda dapat memindai QR ulang atau memilih aktivitas lain.'
              : 'Apakah Anda yakin ingin kembali?\n\n'
                    'Anda akan meninggalkan halaman ini dan dapat memindai kode QR ulang atau memilih alur lain.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),

            child: const Text('Tetap di sini'),
          ),

          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),

            child: const Text('Ya, pindai ulang'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

class SampelPupukDetailScreen extends StatelessWidget {
  final PupukSampelEntry entry;
  final String? selectedActivityType;
  const SampelPupukDetailScreen({
    super.key,
    required this.entry,
    this.selectedActivityType,
  });
  bool get _isActivityConfirmation => selectedActivityType != null;
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        final ok = await _showDetailBackDialog(
          context,

          isActivityConfirmation: _isActivityConfirmation,
        );

        if (!context.mounted || !ok) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isActivityConfirmation
                ? 'Konfirmasi Sampel Pupuk'
                : 'Detail Sampel Pupuk',
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Kembali',
            onPressed: () async {
              final ok = await _showDetailBackDialog(
                context,
                isActivityConfirmation: _isActivityConfirmation,
              );
              if (!context.mounted || !ok) return;
              Navigator.of(context).pop();
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PupukSampelInfoCard(entry: entry),
                if (_isActivityConfirmation) ...[
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Aktivitas dipilih',

                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          AppSpacing.gapSm,
                          _row(
                            context,
                            'Jenis aktivitas',
                            labelForPupukActivityType(selectedActivityType!),
                          ),
                          AppSpacing.gapMd,
                          Text(
                            'Periksa data sampel di atas. Jika sudah benar, lanjutkan ke formulir aktivitas.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SampelPupukActivityFormScreen(
                            activityType: selectedActivityType!,
                            samples: [entry],
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Lanjutkan ke Formulir'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
