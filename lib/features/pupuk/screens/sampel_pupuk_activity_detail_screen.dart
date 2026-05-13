import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/kirim_dari_estate.dart';
import '../../../core/database/models/kirim_lab.dart';
import '../../../core/database/models/kirim_sertifikat_estate.dart';
import '../../sample/screens/full_screen_image_preview_screen.dart';
import '../constants/pupuk_activity_types.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;

class SampelPupukActivityDetailScreen extends StatefulWidget {
  final String activityType;
  final int id;

  const SampelPupukActivityDetailScreen({
    super.key,
    required this.activityType,
    required this.id,
  });

  @override
  State<SampelPupukActivityDetailScreen> createState() =>
      _SampelPupukActivityDetailScreenState();
}

class _SampelPupukActivityDetailScreenState
    extends State<SampelPupukActivityDetailScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final PdfViewerController _pdfSertifikatViewerController =
      PdfViewerController();
  bool _loading = true;
  KirimDariEstate? _kirimEstate;
  KirimLab? _kirimLab;
  KirimSertifikatEstate? _kirimSertifikat;

  Future<void> _load() async {
    setState(() => _loading = true);
    switch (widget.activityType) {
      case kKirimDariEstate:
        final row = await _dbHelper.getKirimDariEstateById(widget.id);
        if (mounted) {
          setState(() {
            _kirimEstate = row;
            _loading = false;
          });
        }
        break;
      case kKirimLab:
        final row = await _dbHelper.getKirimLabById(widget.id);
        if (mounted) {
          setState(() {
            _kirimLab = row;
            _loading = false;
          });
        }
        break;
      case kKirimSertifikatEstate:
        final row = await _dbHelper.getKirimSertifikatEstateById(widget.id);
        if (mounted) {
          setState(() {
            _kirimSertifikat = row;
            _loading = false;
          });
        }
        break;
      default:
        if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pdfSertifikatViewerController.dispose();
    super.dispose();
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

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus data'),
        content: const Text(
          'Yakin ingin menghapus data sampel pupuk ini? Tindakan ini tidak dapat dibatalkan.',
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
    switch (widget.activityType) {
      case kKirimDariEstate:
        await _dbHelper.deleteKirimDariEstate(widget.id);
        break;
      case kKirimLab:
        await _dbHelper.deleteKirimLab(widget.id);
        break;
      case kKirimSertifikatEstate:
        await _dbHelper.deleteKirimSertifikatEstate(widget.id);
        break;
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  bool get _hasData =>
      _kirimEstate != null || _kirimLab != null || _kirimSertifikat != null;

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

    if (!_hasData) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detail'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Data tidak ditemukan')),
      );
    }

    final title = labelForPupukActivityType(widget.activityType);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            color: Colors.white,
            onPressed: _confirmAndDelete,
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
              if (_kirimEstate != null) _buildKirimEstateContent(_kirimEstate!),
              if (_kirimLab != null) _buildKirimLabContent(_kirimLab!),
              if (_kirimSertifikat != null)
                _buildKirimSertifikatContent(_kirimSertifikat!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection(String? fotoPath, String subtitle) {
    final colorScheme = Theme.of(context).colorScheme;
    final path = fotoPath != null && fotoPath.isNotEmpty ? fotoPath : null;
    final exists = path != null && File(path).existsSync();
    final pathValue = path; // promote for closure
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: exists && pathValue != null
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FullScreenImagePreviewScreen(
                      imagePath: pathValue,
                      title: subtitle,
                      details: const {},
                    ),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: exists && pathValue != null
              ? Image.file(
                  File(pathValue),
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : Container(
                  height: 200,
                  color: colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 56,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tidak ada foto',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
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
            width: 160,
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

  Widget _buildKirimEstateContent(KirimDariEstate r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPhotoSection(
          r.fotoKirimDariEstate,
          'Kirim dari Estate - ${r.kodeSampel}',
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
                  'Informasi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Kode Sampel', r.kodeSampel),
                _buildInfoRow(
                  'Tanggal Kirim dari Estate',
                  app_date_utils.DateUtils.formatDateTimeFromIso(
                    r.tanggalKirimDariEstate,
                  ),
                ),
                if (r.namaPengirim != null && r.namaPengirim!.isNotEmpty)
                  _buildInfoRow('Nama Pengirim', r.namaPengirim!),
                _buildInfoRow(
                  'Status',
                  _statusLabel(r.status),
                  valueColor: _statusColor(r.status),
                ),
                if (r.errorMessage != null && r.errorMessage!.isNotEmpty)
                  _buildInfoRow(
                    'Kesalahan',
                    r.errorMessage!,
                    valueColor: AppColors.error,
                  ),
                _buildInfoRow(
                  'Dibuat',
                  app_date_utils.DateUtils.formatDateTimeFromIso(r.createdAt),
                ),
                if (r.updatedAt != null)
                  _buildInfoRow(
                    'Diperbarui',
                    app_date_utils.DateUtils.formatDateTimeFromIso(
                      r.updatedAt!,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKirimLabContent(KirimLab r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPhotoSection(r.fotoKirimLab, 'Kirim Lab - ${r.kodeSampel}'),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Kode Sampel', r.kodeSampel),
                if (r.noSurat != null && r.noSurat!.isNotEmpty)
                  _buildInfoRow('No. Surat', r.noSurat!),
                _buildInfoRow(
                  'Tanggal Kirim Lab',
                  app_date_utils.DateUtils.formatDateTimeFromIso(
                    r.tanggalKirimLab,
                  ),
                ),
                if (r.tanggalEstimasiKupa != null &&
                    r.tanggalEstimasiKupa!.trim().isNotEmpty)
                  _buildInfoRow(
                    'Tanggal Estimasi Kupa',
                    app_date_utils.DateUtils.formatDateTimeFromIso(
                      r.tanggalEstimasiKupa,
                    ),
                  ),
                _buildInfoRow(
                  'Status',
                  _statusLabel(r.status),
                  valueColor: _statusColor(r.status),
                ),
                if (r.errorMessage != null && r.errorMessage!.isNotEmpty)
                  _buildInfoRow(
                    'Kesalahan',
                    r.errorMessage!,
                    valueColor: AppColors.error,
                  ),
                _buildInfoRow(
                  'Dibuat',
                  app_date_utils.DateUtils.formatDateTimeFromIso(r.createdAt),
                ),
                if (r.updatedAt != null)
                  _buildInfoRow(
                    'Diperbarui',
                    app_date_utils.DateUtils.formatDateTimeFromIso(
                      r.updatedAt!,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openSertifikatPdfFullScreen(String path) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Preview PDF Sertifikat'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: SfPdfViewer.file(
            File(path),
            canShowPaginationDialog: false,
            canShowScrollHead: true,
            canShowScrollStatus: true,
          ),
        ),
      ),
    );
  }

  Widget _buildKirimSertifikatContent(KirimSertifikatEstate r) {
    final pdfPath = r.fileSertifikat.trim();
    final pdfExists = pdfPath.isNotEmpty && File(pdfPath).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pdfExists) ...[
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview halaman pertama PDF',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _openSertifikatPdfFullScreen(pdfPath),
                      icon: const Icon(Icons.open_in_full),
                      label: const Text('Layar penuh'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 220,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () => _openSertifikatPdfFullScreen(pdfPath),
                        child: SfPdfViewer.file(
                          File(pdfPath),
                          key: ValueKey(pdfPath),
                          controller: _pdfSertifikatViewerController,
                          canShowScrollHead: false,
                          canShowScrollStatus: false,
                          canShowPaginationDialog: false,
                          onDocumentLoaded: (_) {
                            _pdfSertifikatViewerController.jumpToPage(1);
                          },
                          onDocumentLoadFailed: (details) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Preview PDF gagal dimuat: ${details.error}',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ] else if (pdfPath.isNotEmpty) ...[
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'File sertifikat tidak ditemukan di perangkat:\n${p.basename(pdfPath)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Kode Sampel', r.kodeSampel),
                _buildInfoRow(
                  'Tanggal Kirim Sertifikat',
                  app_date_utils.DateUtils.formatDateTimeFromIso(
                    r.tanggalKirimSertifikatEstate,
                  ),
                ),
                _buildInfoRow('Rekomendasi', r.rekomendasi),
                if (pdfPath.isNotEmpty)
                  _buildInfoRow('File Sertifikat', p.basename(pdfPath)),
                _buildInfoRow(
                  'Status',
                  _statusLabel(r.status),
                  valueColor: _statusColor(r.status),
                ),
                if (r.errorMessage != null && r.errorMessage!.isNotEmpty)
                  _buildInfoRow(
                    'Kesalahan',
                    r.errorMessage!,
                    valueColor: AppColors.error,
                  ),
                _buildInfoRow(
                  'Dibuat',
                  app_date_utils.DateUtils.formatDateTimeFromIso(r.createdAt),
                ),
                if (r.updatedAt != null)
                  _buildInfoRow(
                    'Diperbarui',
                    app_date_utils.DateUtils.formatDateTimeFromIso(
                      r.updatedAt!,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
