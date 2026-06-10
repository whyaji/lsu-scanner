import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/completed_sample.dart';
import '../../../core/database/models/master_lsu.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import 'full_screen_image_preview_screen.dart';

class CompletedSampleDetailScreen extends StatefulWidget {
  final int sampleId;

  const CompletedSampleDetailScreen({super.key, required this.sampleId});

  @override
  State<CompletedSampleDetailScreen> createState() =>
      _CompletedSampleDetailScreenState();
}

class _CompletedSampleDetailScreenState
    extends State<CompletedSampleDetailScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  CompletedSample? _sample;
  MasterLsu? _masterLsu;
  bool _loading = true;

  Future<void> _load() async {
    final sample = await _dbHelper.getCompletedSampleById(widget.sampleId);
    MasterLsu? master;
    if (sample != null) {
      master = await _dbHelper.getMasterLsuById(sample.masterLsuId);
    }
    if (mounted) {
      setState(() {
        _sample = sample;
        _masterLsu = master;
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Color _statusColor(String status) {
    switch (status) {
      case AppConstants.statusUploaded:
        return AppColors.success;
      case AppConstants.statusError:
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case AppConstants.statusUploaded:
        return 'Terunggah';
      case AppConstants.statusError:
        return 'Gagal';
      default:
        return 'Menunggu';
    }
  }

  bool _canDelete(String status) {
    return status == AppConstants.statusNotUploaded ||
        status == AppConstants.statusUploaded ||
        status == AppConstants.statusError;
  }

  Future<void> _confirmAndDelete(CompletedSample s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus sampel'),
        content: const Text(
          'Yakin ingin menghapus sampel selesai ini? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (s.id == null) return;
    await _dbHelper.deleteCompletedSample(s.id!);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detail'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final s = _sample;
    if (s == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detail'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Sampel tidak ditemukan')),
      );
    }

    final m = _masterLsu;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail sampel selesai'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_canDelete(s.status))
            IconButton(
              icon: const Icon(Icons.delete),
              color: AppColors.error,
              onPressed: () => _confirmAndDelete(s),
              tooltip: 'Hapus',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                child: InkWell(
                  onTap: File(s.fotoPath).existsSync()
                      ? () {
                          final details = <String, String>{
                            'Kode': s.kode,
                            'Tanggal selesai':
                                app_date_utils
                                    .DateUtils.formatStoredDateForDisplay(
                                  s.tanggalSelesai,
                                ),
                            'Waktu selesai': s.waktuSelesai,
                            'Status': _statusLabel(s.status),
                            if (m != null && m.estate != null)
                              'Estate': m.estate!,
                            if (m != null && m.afdeling != null)
                              'Afdeling': m.afdeling!,
                            if (m != null && m.blok != null) 'Blok': m.blok!,
                          };
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  FullScreenImagePreviewScreen(
                                    imagePath: s.fotoPath,
                                    title: 'Sampel selesai',
                                    details: details,
                                  ),
                            ),
                          );
                        }
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: File(s.fotoPath).existsSync()
                        ? Image.file(
                            File(s.fotoPath),
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            height: 220,
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
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
                        'Informasi penyelesaian',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Kode', s.kode),
                      _buildInfoRow(
                        'Tanggal selesai',
                        app_date_utils.DateUtils.formatStoredDateForDisplay(
                          s.tanggalSelesai,
                        ),
                      ),
                      _buildInfoRow('Waktu selesai', s.waktuSelesai),
                      _buildInfoRow(
                        'Status',
                        _statusLabel(s.status),
                        valueColor: _statusColor(s.status),
                      ),
                      if (s.errorMessage != null && s.errorMessage!.isNotEmpty)
                        _buildInfoRow(
                          'Kesalahan',
                          s.errorMessage!,
                          valueColor: AppColors.error,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (m != null)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Master LSU',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (m.pt != null) _buildInfoRow('PT', m.pt!),
                        if (m.estate != null)
                          _buildInfoRow('Estate', m.estate!),
                        if (m.wilayah != null)
                          _buildInfoRow('Wilayah', m.wilayah.toString()),
                        if (m.afdeling != null)
                          _buildInfoRow('Afdeling', m.afdeling!),
                        if (m.blok != null) _buildInfoRow('Blok', m.blok!),
                        if (m.groupBlok != null)
                          _buildInfoRow('Group Blok', m.groupBlok!),
                        if (m.tahunTanam != null)
                          _buildInfoRow('Tahun Tanam', m.tahunTanam.toString()),
                        if (m.varietas != null)
                          _buildInfoRow('Varietas', m.varietas!),
                        if (m.jenisTanah != null)
                          _buildInfoRow('Jenis Tanah', m.jenisTanah!),
                        if (m.topografi != null)
                          _buildInfoRow('Topografi', m.topografi!),
                        if (m.luasHa != null)
                          _buildInfoRow('Luas Ha', m.luasHa!),
                        if (m.jmlPokok != null)
                          _buildInfoRow('Jumlah Pokok', m.jmlPokok.toString()),
                        if (m.jmlPokokProduktif != null)
                          _buildInfoRow(
                            'Jumlah Pokok Produktif',
                            m.jmlPokokProduktif.toString(),
                          ),
                        if (m.sph != null)
                          _buildInfoRow('SPH', m.sph!.toString()),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor ?? colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
