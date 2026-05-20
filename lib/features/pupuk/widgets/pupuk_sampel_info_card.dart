import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../models/pupuk_sampel_entry.dart';

/// Sample detail card (QR / synced data) used in confirmation screens.
class PupukSampelInfoCard extends StatelessWidget {
  const PupukSampelInfoCard({super.key, required this.entry, this.trailing});

  final PupukSampelEntry entry;
  final Widget? trailing;

  String get _supplierDisplay {
    final s = entry.dataSampelPupuk?.supplier;
    if (s != null && s.isNotEmpty) return s;
    return entry.qrPupukData.supplier.isEmpty
        ? '-'
        : entry.qrPupukData.supplier;
  }

  @override
  Widget build(BuildContext context) {
    final data = entry.dataSampelPupuk;
    final qr = entry.qrPupukData;
    final kode = entry.displayKodeSampel;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    entry.fromSync ? 'Data Sampel Pupuk' : 'Data dari QR',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (!entry.fromSync) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.warningColor(context),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Data dari QR. Mungkin belum disinkronkan.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if ((data?.estate ?? '').isNotEmpty)
              _row(context, 'Estate', data!.estate!)
            else
              _row(
                context,
                'Estate',
                kode.isEmpty ? '-' : kode.split('/').first,
              ),
            _row(context, 'Nama Supplier', _supplierDisplay),
            if ((data?.noPo ?? '').isNotEmpty)
              _row(context, 'No. PO', data!.noPo!),
            _row(
              context,
              'Jenis Pupuk',
              data?.jenisPupukFull ??
                  (qr.jenisPupukFull.isEmpty ? '-' : qr.jenisPupukFull),
            ),
            if ((data?.noBpb ?? '').isNotEmpty)
              _row(context, 'No. BPB / GRN', data!.noBpb!),
            _row(context, 'No. Registrasi Sample', kode.isEmpty ? '-' : kode),
            if (data?.tanggalTerimaDariGudang != null &&
                data!.tanggalTerimaDariGudang!.isNotEmpty)
              _row(
                context,
                'Tgl. Penerimaan Pupuk',
                app_date_utils.DateUtils.formatPupukDetailTanggal(
                  data.tanggalTerimaDariGudang,
                ),
              ),
            if (data?.tanggalKirimDariEstate != null &&
                data!.tanggalKirimDariEstate!.isNotEmpty)
              _row(
                context,
                'Tgl. Pengambilan Sample',
                app_date_utils.DateUtils.formatPupukDetailTanggal(
                  data.tanggalKirimDariEstate,
                ),
              ),
            if (data?.qtyTerima != null)
              _row(context, 'Jumlah Pengiriman Pupuk', '${data!.qtyTerima} Kg')
            else if (qr.qtyTerima != null)
              _row(context, 'Jumlah Pengiriman Pupuk', '${qr.qtyTerima} Kg'),
            if ((data?.noSegel ?? '').isNotEmpty)
              _row(context, 'Nomor Segel', data!.noSegel!),
          ],
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
