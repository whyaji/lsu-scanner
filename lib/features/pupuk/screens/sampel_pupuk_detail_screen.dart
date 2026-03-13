import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/models/data_sampel_pupuk.dart';
import '../../auth/providers/auth_provider.dart';
import '../../scanner/utils/qr_parser.dart';
import '../constants/pupuk_activity_types.dart';
import 'sampel_pupuk_activity_form_screen.dart';

class SampelPupukDetailScreen extends ConsumerWidget {
  final DataSampelPupuk? dataSampelPupuk;
  final QRPupukData qrPupukData;
  final bool fromSync;

  const SampelPupukDetailScreen({
    super.key,
    this.dataSampelPupuk,
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
    final allowedTypes = allowedPupukActivityTypes(access);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Sampel Pupuk'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!fromSync)
                Card(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.warning),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Data dari QR. Rekaman ini mungkin belum disinkronkan. Anda tetap dapat mengisi formulir dan mengambil foto.',
                            style: TextStyle(fontSize: 13),
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
                      _row('ID', dataSampelPupukId.toString()),
                      _row(
                        'Kode Sampel',
                        kodeSampel.isEmpty ? '-' : kodeSampel,
                      ),
                      _row('Supplier', _supplierDisplay),
                      _row(
                        'Jenis Pupuk',
                        dataSampelPupuk?.jenisPupukFull ??
                            (qrPupukData.jenisPupukFull.isEmpty
                                ? '-'
                                : qrPupukData.jenisPupukFull),
                      ),
                      if (dataSampelPupuk != null) ...[
                        if (dataSampelPupuk!.regional != null)
                          _row(
                            'Regional',
                            dataSampelPupuk!.regional.toString(),
                          ),
                        if (dataSampelPupuk!.wilayah != null)
                          _row('Wilayah', dataSampelPupuk!.wilayah.toString()),
                        if (dataSampelPupuk!.estate != null &&
                            dataSampelPupuk!.estate!.isNotEmpty)
                          _row('Estate', dataSampelPupuk!.estate!),
                        if (dataSampelPupuk!.qtyPartaiPengiriman != null)
                          _row(
                            'Qty Partai Pengiriman',
                            dataSampelPupuk!.qtyPartaiPengiriman.toString(),
                          ),
                      ] else if (qrPupukData.qtyPartaiPengiriman != null)
                        _row(
                          'Qty Partai Pengiriman',
                          qrPupukData.qtyPartaiPengiriman.toString(),
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
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else ...[
                const Text(
                  'Pilih jenis aktivitas:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...allowedTypes.map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ElevatedButton(
                      onPressed: () {
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.centerLeft,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add_circle_outline),
                          const SizedBox(width: 12),
                          Text(labelForPupukActivityType(type)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
