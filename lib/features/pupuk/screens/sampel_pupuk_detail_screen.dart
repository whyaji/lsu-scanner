import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sampletrack/core/database/models/aktivitas_sampel_pupuk.dart';
import '../../../core/database/models/data_sampel_pupuk.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/providers/auth_provider.dart';
import '../../scanner/utils/qr_parser.dart';
import '../constants/pupuk_activity_types.dart';
import 'sampel_pupuk_activity_form_screen.dart';

/// Konfirmasi keluar dari detail — user dapat memindai QR ulang.
Future<bool> _showDetailBackRescanDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return AlertDialog(
        icon: Icon(Icons.qr_code_scanner_rounded, size: 40, color: cs.primary),
        iconColor: cs.primary,
        title: const Text('Kembali dan pindai ulang?'),
        content: const Text(
          'Apakah Anda yakin ingin kembali?\n\n'
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

class SampelPupukDetailScreen extends ConsumerWidget {
  final DataSampelPupuk? dataSampelPupuk;
  final AktivitasSampelPupuk? aktivitasSampelPupuk;
  final QRPupukData qrPupukData;
  final bool fromSync;

  const SampelPupukDetailScreen({
    super.key,
    this.dataSampelPupuk,
    this.aktivitasSampelPupuk,
    required this.qrPupukData,
    required this.fromSync,
  });

  int get dataSampelPupukId => dataSampelPupuk?.id ?? qrPupukData.id;
  String get kodeSampel =>
      dataSampelPupuk?.kodeSampel ?? qrPupukData.kodeSampel;

  String get _supplierDisplay {
    final s = dataSampelPupuk?.supplier;
    if (s != null && s.isNotEmpty) return s;
    return qrPupukData.supplier.isEmpty ? '-' : qrPupukData.supplier;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final access = authState.user?.access;
    final allowedTypes = allowedPupukActivityTypes(
      access,
      aktivitasSampelPupuk,
      dataSampelPupukFallback: dataSampelPupuk,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final ok = await _showDetailBackRescanDialog(context);
        if (!context.mounted || !ok) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detail Sampel Pupuk'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Kembali',
            onPressed: () async {
              final ok = await _showDetailBackRescanDialog(context);
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
                if (!fromSync)
                  Card(
                    color: AppTheme.warningColor(
                      context,
                    ).withValues(alpha: 0.15),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.warningColor(context),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Data dari QR. Rekaman ini mungkin belum disinkronkan. Anda tetap dapat mengisi formulir dan mengambil foto.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fromSync ? 'Data Sampel Pupuk' : 'Data dari QR',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _row(context, 'ID', dataSampelPupukId.toString()),
                        _row(
                          context,
                          'Kode Sampel',
                          kodeSampel.isEmpty ? '-' : kodeSampel,
                        ),
                        _row(context, 'Supplier', _supplierDisplay),
                        _row(
                          context,
                          'Jenis Pupuk',
                          dataSampelPupuk?.jenisPupukFull ??
                              (qrPupukData.jenisPupukFull.isEmpty
                                  ? '-'
                                  : qrPupukData.jenisPupukFull),
                        ),
                        if (dataSampelPupuk != null) ...[
                          if (dataSampelPupuk!.regional != null)
                            _row(
                              context,
                              'Regional',
                              dataSampelPupuk!.regional.toString(),
                            ),
                          if (dataSampelPupuk!.wilayah != null)
                            _row(
                              context,
                              'Wilayah',
                              dataSampelPupuk!.wilayah.toString(),
                            ),
                          if (dataSampelPupuk!.estate != null &&
                              dataSampelPupuk!.estate!.isNotEmpty)
                            _row(context, 'Estate', dataSampelPupuk!.estate!),
                          if (dataSampelPupuk!.qtyPartaiPengiriman != null)
                            _row(
                              context,
                              'Qty Partai Pengiriman',
                              '${dataSampelPupuk!.qtyPartaiPengiriman} Kg',
                            ),
                        ] else if (qrPupukData.qtyPartaiPengiriman != null)
                          _row(
                            context,
                            'Qty Partai Pengiriman',
                            '${qrPupukData.qtyPartaiPengiriman} Kg',
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (allowedTypes.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Anda tidak memiliki akses untuk mencatat aktivitas Sampel Pupuk. Hubungi admin.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      'Pilih jenis aktivitas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  ...allowedTypes.map(
                    (type) => _ActivityTypeTile(
                      label: labelForPupukActivityType(type),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SampelPupukActivityFormScreen(
                              activityType: type,
                              dataSampelPupukId: dataSampelPupukId,
                              kodeSampel: kodeSampel.isEmpty
                                  ? qrPupukData.kodeSampel
                                  : kodeSampel,
                              dataSampelPupuk: dataSampelPupuk,
                              qrPupukData: qrPupukData,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (allowedTypes.isEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Tidak ada aktivitas yang dapat dicatat.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
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

/// Card-style tile for one activity type. Uses theme colors.
class _ActivityTypeTile extends StatelessWidget {
  const _ActivityTypeTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md + 4,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.add_circle_outline,
                    size: 22,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
