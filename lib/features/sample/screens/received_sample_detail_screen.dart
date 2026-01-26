import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/received_sample.dart';
import '../../../core/database/models/master_lsu.dart';
import 'full_screen_image_preview_screen.dart';

class ReceivedSampleDetailScreen extends StatefulWidget {
  final int sampleId;

  const ReceivedSampleDetailScreen({super.key, required this.sampleId});

  @override
  State<ReceivedSampleDetailScreen> createState() =>
      _ReceivedSampleDetailScreenState();
}

class _ReceivedSampleDetailScreenState
    extends State<ReceivedSampleDetailScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  ReceivedSample? _sample;
  MasterLsu? _masterLsu;
  bool _loading = true;

  Future<void> _load() async {
    final sample = await _dbHelper.getReceivedSampleById(widget.sampleId);
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
        return 'Uploaded';
      case AppConstants.statusError:
        return 'Error';
      default:
        return 'Pending';
    }
  }

  bool _canDelete(String status) {
    return status == AppConstants.statusNotUploaded ||
        status == AppConstants.statusUploaded ||
        status == AppConstants.statusError;
  }

  Future<void> _confirmAndDelete(ReceivedSample s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete sample'),
        content: const Text(
          'Are you sure you want to delete this received sample? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (s.id == null) return;
    await _dbHelper.deleteReceivedSample(s.id!);
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
        body: const Center(child: Text('Sample not found')),
      );
    }

    final m = _masterLsu;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Received sample detail'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_canDelete(s.status))
            IconButton(
              icon: const Icon(Icons.delete),
              color: AppColors.error,
              onPressed: () => _confirmAndDelete(s),
              tooltip: 'Delete',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo — tap for full screen with details
              Card(
                elevation: 2,
                child: InkWell(
                  onTap: File(s.fotoPath).existsSync()
                      ? () {
                          final details = <String, String>{
                            'Kode': s.kode,
                            'Date received': s.tanggalTerima,
                            'Time received': s.waktuTerima,
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
                                    title: 'Received sample',
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
                            color: AppColors.background,
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Received info
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Received information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Kode', s.kode),
                      _buildInfoRow('Date received', s.tanggalTerima),
                      _buildInfoRow('Time received', s.waktuTerima),
                      _buildInfoRow(
                        'Status',
                        _statusLabel(s.status),
                        valueColor: _statusColor(s.status),
                      ),
                      if (s.errorMessage != null && s.errorMessage!.isNotEmpty)
                        _buildInfoRow(
                          'Error',
                          s.errorMessage!,
                          valueColor: AppColors.error,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Master LSU
              if (m != null) ...[
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
                            color: AppColors.textPrimary,
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
            ],
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
            width: 120,
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
}
