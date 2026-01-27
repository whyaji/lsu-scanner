import 'package:flutter/material.dart' hide DateUtils;
import 'dart:io';
import '../../../core/database/models/master_lsu.dart';
import '../../../core/database/models/received_sample.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_counts_refresh_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'full_screen_image_preview_screen.dart';

class ConfirmationScreen extends ConsumerStatefulWidget {
  final int dataLsuId;
  final int masterLsuId;
  final String kode;
  final MasterLsu masterLsu;
  final String photoPath;

  const ConfirmationScreen({
    super.key,
    required this.dataLsuId,
    required this.masterLsuId,
    required this.kode,
    required this.masterLsu,
    required this.photoPath,
  });

  @override
  ConsumerState<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends ConsumerState<ConfirmationScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isSaving = false;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
  }

  Future<void> _saveSample() async {
    final existing = await _dbHelper.getReceivedSampleByDataLsuId(
      widget.dataLsuId,
    );
    if (existing != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sampel ini sudah diterima'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authState = ref.read(authProvider);
      final userId = authState.user?.id;

      final sample = ReceivedSample(
        dataLsuId: widget.dataLsuId,
        masterLsuId: widget.masterLsuId,
        kode: widget.kode,
        tanggalTerima: DateUtils.formatDate(_selectedDate),
        waktuTerima: DateUtils.formatTime(
          DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _selectedTime.hour,
            _selectedTime.minute,
          ),
        ),
        fotoPath: widget.photoPath,
        status: AppConstants.statusNotUploaded,
        userId: userId,
        createdAt: DateTime.now().toIso8601String(),
        masterLsu: widget.masterLsu,
      );

      await _dbHelper.insertReceivedSample(sample);

      if (mounted) {
        ref.read(homeCountsRefreshProvider.notifier).state++;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sampel berhasil disimpan'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan sampel: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Preview — tap for full screen with details
              Card(
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FullScreenImagePreviewScreen(
                          imagePath: widget.photoPath,
                          title: 'Pratinjau Foto',
                          details: {
                            'Kode': widget.kode,
                            'Estate': widget.masterLsu.estate ?? '-',
                            'Afdeling': widget.masterLsu.afdeling ?? '-',
                            'Blok': widget.masterLsu.blok ?? '-',
                            'Tanggal Diterima': DateUtils.formatDate(
                              _selectedDate,
                            ),
                            'Waktu Diterima':
                                '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                          },
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(widget.photoPath),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sample Info
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi Sampel',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Kode', widget.kode),
                      _buildInfoRow('Estate', widget.masterLsu.estate ?? '-'),
                      _buildInfoRow(
                        'Afdeling',
                        widget.masterLsu.afdeling ?? '-',
                      ),
                      _buildInfoRow('Blok', widget.masterLsu.blok ?? '-'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date & Time Selection
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tanggal & Waktu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Tanggal Diterima',
                        DateUtils.formatDate(_selectedDate),
                      ),
                      _buildInfoRow(
                        'Waktu Diterima',
                        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveSample,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Simpan Sampel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
