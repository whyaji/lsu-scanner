import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/database/models/master_lsu.dart';
import '../../../core/database/models/received_sample.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/constants/app_constants.dart';
import 'photo_capture_screen.dart';
import 'full_screen_image_preview_screen.dart';

class SampleDetailScreen extends StatefulWidget {
  final int dataLsuId;
  final int masterLsuId;
  final String kode;
  final MasterLsu masterLsu;

  const SampleDetailScreen({
    super.key,
    required this.dataLsuId,
    required this.masterLsuId,
    required this.kode,
    required this.masterLsu,
  });

  @override
  State<SampleDetailScreen> createState() => _SampleDetailScreenState();
}

class _SampleDetailScreenState extends State<SampleDetailScreen> {
  static final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  ReceivedSample? _existingReceived;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingReceived();
  }

  Future<void> _loadExistingReceived() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Sampel'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
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

                    // When already received: show existing data (image + date/time), hide Take Photo
                    if (_existingReceived != null) ...[
                      _buildAlreadyReceivedCard(),
                    ] else ...[
                      // Take Photo Button — only when not yet received
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PhotoCaptureScreen(
                                dataLsuId: widget.dataLsuId,
                                masterLsuId: widget.masterLsuId,
                                kode: widget.kode,
                                masterLsu: widget.masterLsu,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text(
                          'Ambil Foto',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
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
                Icon(Icons.check_circle, color: AppColors.success, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Sudah diterima',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
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
                          'Tanggal diterima': s.tanggalTerima,
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
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Foto tidak ditemukan',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            const SizedBox(height: 16),
            _buildInfoRow('Tanggal diterima', s.tanggalTerima),
            _buildInfoRow('Waktu diterima', s.waktuTerima),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
            child: Text(value, style: TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
