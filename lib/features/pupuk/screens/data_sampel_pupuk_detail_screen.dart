import 'package:flutter/material.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/database/models/data_sampel_pupuk.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/models/api_response.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../widgets/app_loading_state.dart';
import '../constants/data_sampel_pupuk_progress.dart';
import '../widgets/detail_field_grid.dart';
import '../widgets/detail_photo_gallery.dart';

class DataSampelPupukDetailScreen extends StatefulWidget {
  const DataSampelPupukDetailScreen({
    super.key,
    required this.id,
    this.preferOnline = false,
  });

  final int id;
  final bool preferOnline;

  @override
  State<DataSampelPupukDetailScreen> createState() =>
      _DataSampelPupukDetailScreenState();
}

class _DataSampelPupukDetailScreenState
    extends State<DataSampelPupukDetailScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService = ApiService(ApiClient().dio);
  DataSampelPupuk? _data;
  bool _loading = true;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _isNetworkFailure<T>(ApiResponse<T> response) {
    return !response.success &&
        (response.error?.code == 'NETWORK_ERROR' ||
            response.error?.message.toLowerCase().contains('network') == true);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    DataSampelPupuk? row;
    var isOnline = false;

    if (widget.preferOnline) {
      final response = await _apiService.getDataSampelPupukById(widget.id);
      if (!_isNetworkFailure(response) &&
          response.success &&
          response.data != null) {
        row = DataSampelPupuk.fromApiJson(response.data!.toJson());
        isOnline = true;
      }
    }

    row ??= await _dbHelper.getDataSampelPupukById(widget.id);

    if (!mounted) return;
    setState(() {
      _data = row;
      _isOnline = isOnline;
      _loading = false;
    });
  }

  String? _formatDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return app_date_utils.DateUtils.formatDateTimeFromIso(value);
  }

  String? _formatKg(int? value) {
    if (value == null) return null;
    return '$value kg';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final data = _data;

    return Scaffold(
      appBar: AppBar(
        title: Text(data?.kodeSampel ?? 'Detail Sampel'),
        actions: [
          if (!_loading)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Center(
                child: Icon(
                  _isOnline
                      ? Icons.cloud_done_outlined
                      : Icons.storage_outlined,
                  size: 20,
                  color: _isOnline ? Colors.green.shade700 : null,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const AppLoadingState(itemCount: 6)
          : data == null
          ? Center(
              child: Text(
                'Data tidak ditemukan',
                style: theme.textTheme.titleMedium,
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: AppSpacing.paddingScreen,
                children: [
                  _HeaderCard(data: data),
                  AppSpacing.gapMd,
                  DetailSectionCard(
                    badge: 'A',
                    title: 'Nama dan Jenis Pupuk',
                    fields: [
                      DetailField(label: 'ID', value: '${data.id}'),
                      DetailField(
                        label: 'No Registrasi Sampel',
                        value: data.kodeSampel,
                      ),
                      DetailField(
                        label: 'Jenis Pupuk Full',
                        value: data.jenisPupukFull,
                        fullWidth: true,
                      ),
                      DetailField(label: 'Jenis Pupuk', value: data.jenisPupuk),
                      DetailField(label: 'Merek', value: data.merek),
                      DetailField(
                        label: 'No. Kode Sampel (BA)',
                        value: data.noKodeSampel?.toString(),
                      ),
                      DetailField(
                        label: 'Jumlah Sampel (Zak)',
                        value: data.jumlahSampelZak?.toString(),
                      ),
                      DetailField(label: 'No Segel', value: data.noSegel),
                      DetailField(
                        label: 'No BA Sampel Pupuk',
                        value: data.noBaSampelPupuk,
                        fullWidth: true,
                      ),
                    ],
                  ),
                  AppSpacing.gapSm,
                  DetailSectionCard(
                    badge: 'B',
                    title: 'Data Asal Pupuk',
                    fields: [
                      DetailField(label: 'Supplier', value: data.supplier),
                      DetailField(
                        label: 'Regional',
                        value: data.regional?.toString(),
                      ),
                      DetailField(
                        label: 'Wilayah',
                        value: data.wilayah?.toString(),
                      ),
                      DetailField(label: 'Estate', value: data.estate),
                      DetailField(label: 'PT', value: data.pt),
                      DetailField(label: 'No PO', value: data.noPo),
                      DetailField(label: 'No BPB / GRN', value: data.noBpb),
                      DetailField(
                        label: 'Qty Partai Pengiriman',
                        value: _formatKg(data.qtyPartaiPengiriman),
                      ),
                      DetailField(
                        label: 'Qty Terima',
                        value: _formatKg(data.qtyTerima),
                      ),
                    ],
                  ),
                  AppSpacing.gapSm,
                  DetailSectionCard(
                    badge: 'C',
                    title: 'Angkutan Pupuk',
                    fields: [
                      DetailField(
                        label: 'Jenis Kendaraan',
                        value: data.jenisKendaraan,
                      ),
                      DetailField(
                        label: 'Tanggal Pengambilan Sampel',
                        value: _formatDate(data.tanggalPengambilanSampel),
                        fullWidth: true,
                      ),
                    ],
                  ),
                  AppSpacing.gapSm,
                  DetailSectionCard(
                    badge: 'D',
                    title: 'Hasil Pemeriksaan Fisik',
                    fields: [
                      DetailField(
                        label: 'Logo Perusahaan',
                        value: data.checkLogoPerusahaan,
                      ),
                      DetailField(
                        label: 'Kondisi Karung',
                        value: data.checkKondisiKarung,
                      ),
                      DetailField(
                        label: 'Jahitan Karung',
                        value: data.checkJahitanKarung,
                      ),
                      DetailField(
                        label: 'Kontaminan',
                        value: data.checkKontaminan,
                      ),
                      DetailField(
                        label: 'Jenis Kontaminan',
                        value: data.checkJenisKontaminan,
                      ),
                      DetailField(
                        label: 'Persentase Kontaminan',
                        value: data.checkPersentaseKontaminan,
                      ),
                      DetailField(
                        label: 'Bekas Gancu',
                        value: data.checkBekasGancu,
                      ),
                    ],
                  ),
                  AppSpacing.gapSm,
                  DetailSectionCard(
                    badge: 'E',
                    title: 'Penerimaan Sampel Pupuk',
                    fields: [
                      DetailField(
                        label: 'Diperiksa Estate Manager',
                        value: data.diperiksaEstateManagerNama,
                      ),
                      DetailField(
                        label: 'Diperiksa KTU',
                        value: data.diperiksaKtuNama,
                      ),
                      DetailField(
                        label: 'Disaksikan Supplier',
                        value: data.disaksikanSupplierNama,
                      ),
                      DetailField(
                        label: 'Diambil Kepala Gudang',
                        value: data.diambilKepalaGudang,
                        fullWidth: true,
                      ),
                    ],
                  ),
                  AppSpacing.gapSm,
                  DetailSectionCard(
                    title: 'Progress Sampel',
                    fields: [
                      DetailField(
                        label: 'Kirim dari Estate',
                        value: _formatDate(data.tanggalKirimDariEstate),
                      ),
                      DetailField(
                        label: 'Kirim Lab',
                        value: _formatDate(data.tanggalKirimLab),
                      ),
                      DetailField(
                        label: 'Registrasi Lab',
                        value: _formatDate(data.tanggalRegistrasiLab),
                      ),
                      DetailField(label: 'No Surat', value: data.noSurat),
                      DetailField(
                        label: 'Nama Pengirim',
                        value: data.namaPengirim,
                      ),
                      DetailField(
                        label: 'Tanggal Estimasi KUPA',
                        value: _formatDate(data.tanggalEstimasiKupa),
                      ),
                      DetailField(
                        label: 'No Sertifikat',
                        value: data.noSertifikat,
                      ),
                      DetailField(
                        label: 'Tanggal Kirim Sertifikat Estate',
                        value: _formatDate(data.tanggalKirimSertifikatEstate),
                        fullWidth: true,
                      ),
                      DetailField(
                        label: 'Rekomendasi',
                        value: data.rekomendasi,
                        fullWidth: true,
                      ),
                      DetailField(
                        label: 'Kode Tracking',
                        value: data.kodeTracking,
                      ),
                    ],
                  ),
                  AppSpacing.gapSm,
                  DetailPhotoGallery(
                    fotoKirimDariEstate: data.fotoKirimDariEstate,
                    fotoKirimLab: data.fotoKirimLab,
                    fotoRegistrasiLab: data.fotoRegistrasiLab,
                  ),
                  AppSpacing.gapSm,
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.info_outline,
                        color: colorScheme.primary,
                      ),
                      title: const Text('Metadata'),
                      subtitle: Text(
                        'Dibuat: ${_formatDate(data.createdAt) ?? '–'}\n'
                        'Diperbarui: ${_formatDate(data.updatedAt) ?? '–'}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.data});

  final DataSampelPupuk data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = resolveDataSampelPupukProgress(data);
    final tab = tabForProgress(progress);

    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tab.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(tab.icon, color: tab.color, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.kodeSampel ?? '–',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labelForProgress(progress),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tab.color.darken(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (data.estate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${data.estate}${data.pt != null ? ' • ${data.pt}' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Color {
  Color darken([double amount = 0.12]) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}
