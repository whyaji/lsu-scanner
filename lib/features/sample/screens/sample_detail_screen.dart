import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/database/models/master_lsu.dart';
import '../../../core/database/models/received_sample.dart';
import '../../../core/database/models/completed_sample.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import 'photo_capture_screen.dart';
import 'full_screen_image_preview_screen.dart';

class SampleDetailScreen extends StatefulWidget {
  final int dataLsuId;
  final int masterLsuId;
  final String kode;
  final MasterLsu masterLsu;
  final bool isCompleteSample;

  const SampleDetailScreen({
    super.key,
    required this.dataLsuId,
    required this.masterLsuId,
    required this.kode,
    required this.masterLsu,
    this.isCompleteSample = false,
  });

  @override
  State<SampleDetailScreen> createState() => _SampleDetailScreenState();
}

class _SampleDetailScreenState extends State<SampleDetailScreen> {
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  ReceivedSample? _existingReceived;
  CompletedSample? _existingCompleted;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      if (widget.isCompleteSample) {
        final existing = await _dbHelper.getCompletedSampleByDataLsuId(
          widget.dataLsuId,
        );
        if (mounted) {
          setState(() {
            _existingCompleted = existing;
            _loading = false;
          });
        }
      } else {
        final existing = await _dbHelper.getReceivedSampleByDataLsuId(
          widget.dataLsuId,
        );
        if (mounted) {
          setState(() {
            _existingReceived = existing;
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _existingCompleted = null;
          _existingReceived = null;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isCompleteSample ? 'Detail Sampel Selesai' : 'Detail Sampel',
        ),
      ),
      body: SafeArea(
        child: _loading
            ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sample Info Card
                    _buildSampleInfoCard(),
                    const SizedBox(height: 16),

                    // Master LSU Info Card
                    _buildMasterLsuCard(),
                    const SizedBox(height: 24),

                    // When already received/completed: show existing data, hide Take Photo
                    if (widget.isCompleteSample &&
                        _existingCompleted != null) ...[
                      _buildAlreadyCompletedCard(),
                    ] else if (!widget.isCompleteSample &&
                        _existingReceived != null) ...[
                      _buildAlreadyReceivedCard(),
                    ] else ...[
                      // Take Photo Button — only when not yet received/completed
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PhotoCaptureScreen(
                                dataLsuId: widget.dataLsuId,
                                masterLsuId: widget.masterLsuId,
                                kode: widget.kode,
                                masterLsu: widget.masterLsu,
                                isCompleteSample: widget.isCompleteSample,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: Text(
                          widget.isCompleteSample
                              ? 'Ambil Foto Selesai'
                              : 'Ambil Foto',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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

  Widget _buildSampleInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Sampel',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Kode', widget.kode),
            _buildInfoRow('ID Data LSU', widget.dataLsuId.toString()),
            _buildInfoRow('ID Master LSU', widget.masterLsuId.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterLsuCard() {
    final m = widget.masterLsu;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Master LSU',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            if (m.pt != null) _buildInfoRow('PT', m.pt!),
            if (m.estate != null) _buildInfoRow('Estate', m.estate!),
            if (m.wilayah != null)
              _buildInfoRow('Wilayah', m.wilayah.toString()),
            if (m.afdeling != null) _buildInfoRow('Afdeling', m.afdeling!),
            if (m.blok != null) _buildInfoRow('Blok', m.blok!),
            if (m.groupBlok != null) _buildInfoRow('Group Blok', m.groupBlok!),
            if (m.tahunTanam != null)
              _buildInfoRow('Tahun Tanam', m.tahunTanam.toString()),
            if (m.varietas != null) _buildInfoRow('Varietas', m.varietas!),
            if (m.jenisTanah != null)
              _buildInfoRow('Jenis Tanah', m.jenisTanah!),
            if (m.topografi != null) _buildInfoRow('Topografi', m.topografi!),
            if (m.luasHa != null) _buildInfoRow('Luas Ha', m.luasHa!),
            if (m.jmlPokok != null)
              _buildInfoRow('Jumlah Pokok', m.jmlPokok.toString()),
            if (m.jmlPokokProduktif != null)
              _buildInfoRow(
                'Jumlah Pokok Produktif',
                m.jmlPokokProduktif.toString(),
              ),
            if (m.sph != null) _buildInfoRow('SPH', m.sph!.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildAlreadyCompletedCard() {
    final s = _existingCompleted!;
    final photoFile = File(s.fotoPath);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor(context),
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sudah selesai',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (photoFile.existsSync())
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FullScreenImagePreviewScreen(
                        imagePath: s.fotoPath,
                        title: 'Sudah selesai',
                        details: {
                          'Tanggal selesai':
                              app_date_utils
                                  .DateUtils.formatStoredDateForDisplay(
                                s.tanggalSelesai,
                              ),
                          'Waktu selesai': s.waktuSelesai,
                          'Kode': s.kode,
                        },
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    photoFile,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Foto tidak ditemukan',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Tanggal selesai',
              app_date_utils.DateUtils.formatStoredDateForDisplay(
                s.tanggalSelesai,
              ),
            ),
            _buildInfoRow('Waktu selesai', s.waktuSelesai),
          ],
        ),
      ),
    );
  }

  Widget _buildAlreadyReceivedCard() {
    final s = _existingReceived!;
    final photoFile = File(s.fotoPath);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor(context),
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sudah diterima',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (photoFile.existsSync())
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FullScreenImagePreviewScreen(
                        imagePath: s.fotoPath,
                        title: 'Sudah diterima',
                        details: {
                          'Tanggal diterima':
                              app_date_utils
                                  .DateUtils.formatStoredDateForDisplay(
                                s.tanggalTerima,
                              ),
                          'Waktu diterima': s.waktuTerima,
                          'Kode': s.kode,
                        },
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    photoFile,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Foto tidak ditemukan',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Tanggal diterima',
              app_date_utils.DateUtils.formatStoredDateForDisplay(
                s.tanggalTerima,
              ),
            ),
            _buildInfoRow('Waktu diterima', s.waktuTerima),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final baseStyle =
        theme.textTheme.bodyMedium ??
        TextStyle(fontSize: 14, color: colorScheme.onSurface);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: baseStyle.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: baseStyle.copyWith(color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
