import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../core/database/models/terima_dari_gudang.dart';
import '../../../core/database/models/kirim_dari_estate.dart';
import '../../../core/database/models/terima_dari_estate.dart';
import '../../../core/database/models/kirim_lab.dart';
import '../../sample/screens/full_screen_image_preview_screen.dart';
import '../constants/pupuk_activity_types.dart';

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
  bool _loading = true;
  TerimaDariGudang? _terimaGudang;
  KirimDariEstate? _kirimEstate;
  TerimaDariEstate? _terimaEstate;
  KirimLab? _kirimLab;

  Future<void> _load() async {
    setState(() => _loading = true);
    switch (widget.activityType) {
      case kTerimaDariGudang:
        final row = await _dbHelper.getTerimaDariGudangById(widget.id);
        if (mounted)
          setState(() {
            _terimaGudang = row;
            _loading = false;
          });
        break;
      case kKirimDariEstate:
        final row = await _dbHelper.getKirimDariEstateById(widget.id);
        if (mounted)
          setState(() {
            _kirimEstate = row;
            _loading = false;
          });
        break;
      case kTerimaDariEstate:
        final row = await _dbHelper.getTerimaDariEstateById(widget.id);
        if (mounted)
          setState(() {
            _terimaEstate = row;
            _loading = false;
          });
        break;
      case kKirimLab:
        final row = await _dbHelper.getKirimLabById(widget.id);
        if (mounted)
          setState(() {
            _kirimLab = row;
            _loading = false;
          });
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
      case kTerimaDariGudang:
        await _dbHelper.deleteTerimaDariGudang(widget.id);
        break;
      case kKirimDariEstate:
        await _dbHelper.deleteKirimDariEstate(widget.id);
        break;
      case kTerimaDariEstate:
        await _dbHelper.deleteTerimaDariEstate(widget.id);
        break;
      case kKirimLab:
        await _dbHelper.deleteKirimLab(widget.id);
        break;
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  bool get _hasData =>
      _terimaGudang != null ||
      _kirimEstate != null ||
      _terimaEstate != null ||
      _kirimLab != null;

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
              if (_terimaGudang != null)
                _buildTerimaGudangContent(_terimaGudang!),
              if (_kirimEstate != null) _buildKirimEstateContent(_kirimEstate!),
              if (_terimaEstate != null)
                _buildTerimaEstateContent(_terimaEstate!),
              if (_kirimLab != null) _buildKirimLabContent(_kirimLab!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection(String? fotoPath, String subtitle) {
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
                  color: AppColors.background,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 56,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tidak ada foto',
                          style: TextStyle(
                            color: AppColors.textSecondary,
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
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor ?? AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerimaGudangContent(TerimaDariGudang r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPhotoSection(
          r.fotoTerimaDariGudang,
          'Terima dari Gudang - ${r.kodeSampel}',
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
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Kode Sampel', r.kodeSampel),
                _buildInfoRow(
                  'Tanggal Terima dari Gudang',
                  app_date_utils.DateUtils.formatDateTimeFromIso(
                    r.tanggalTerimaDariGudang,
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
                    color: AppColors.textPrimary,
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

  Widget _buildTerimaEstateContent(TerimaDariEstate r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPhotoSection(
          r.fotoTerimaDariEstate,
          'Terima dari Estate - ${r.kodeSampel}',
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
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Kode Sampel', r.kodeSampel),
                if (r.noSurat != null && r.noSurat!.isNotEmpty)
                  _buildInfoRow('No. Surat', r.noSurat!),
                _buildInfoRow(
                  'Tanggal Terima dari Estate',
                  app_date_utils.DateUtils.formatDateTimeFromIso(
                    r.tanggalTerimaDariEstate,
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
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Kode Sampel', r.kodeSampel),
                _buildInfoRow(
                  'Tanggal Kirim Lab',
                  app_date_utils.DateUtils.formatDateTimeFromIso(
                    r.tanggalKirimLab,
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
}
