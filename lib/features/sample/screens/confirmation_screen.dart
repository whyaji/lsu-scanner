import 'package:flutter/material.dart' hide DateUtils;
import 'dart:io';
import '../../../core/database/models/master_lsu.dart';
import '../../../core/database/models/received_sample.dart';
import '../../../core/database/models/completed_sample.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
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
  final bool isCompleteSample;

  const ConfirmationScreen({
    super.key,
    required this.dataLsuId,
    required this.masterLsuId,
    required this.kode,
    required this.masterLsu,
    required this.photoPath,
    this.isCompleteSample = false,
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
    try {
      if (widget.isCompleteSample) {
        final existing = await _dbHelper.getCompletedSampleByDataLsuId(
          widget.dataLsuId,
        );
        if (existing != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Sampel ini sudah selesai'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          return;
        }
      } else {
        final existing = await _dbHelper.getReceivedSampleByDataLsuId(
          widget.dataLsuId,
        );
        if (existing != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Sampel ini sudah diterima'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          return;
        }
      }

      if (mounted) setState(() => _isSaving = true);

      final authState = ref.read(authProvider);
      final userId = authState.user?.id;
      final dateStr = DateUtils.formatDate(_selectedDate);
      final timeStr = DateUtils.formatTime(
        DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
      );

      if (widget.isCompleteSample) {
        final sample = CompletedSample(
          dataLsuId: widget.dataLsuId,
          masterLsuId: widget.masterLsuId,
          kode: widget.kode,
          tanggalSelesai: dateStr,
          waktuSelesai: timeStr,
          fotoPath: widget.photoPath,
          status: AppConstants.statusNotUploaded,
          userId: userId,
          createdAt: DateTime.now().toIso8601String(),
          masterLsu: widget.masterLsu,
        );
        await _dbHelper.insertCompletedSample(sample);
      } else {
        final sample = ReceivedSample(
          dataLsuId: widget.dataLsuId,
          masterLsuId: widget.masterLsuId,
          kode: widget.kode,
          tanggalTerima: dateStr,
          waktuTerima: timeStr,
          fotoPath: widget.photoPath,
          status: AppConstants.statusNotUploaded,
          userId: userId,
          createdAt: DateTime.now().toIso8601String(),
          masterLsu: widget.masterLsu,
        );
        await _dbHelper.insertReceivedSample(sample);
      }

      if (mounted) {
        ref.read(homeCountsRefreshProvider.notifier).state++;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isCompleteSample
                  ? 'Sampel selesai berhasil disimpan'
                  : 'Sampel berhasil disimpan',
            ),
            backgroundColor: AppTheme.successColor(context),
          ),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan sampel: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _showSaveConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          widget.isCompleteSample ? 'Simpan Sampel Selesai?' : 'Simpan Sampel?',
        ),
        content: Text(
          widget.isCompleteSample
              ? 'Anda yakin ingin menyimpan data sampel selesai ini?'
              : 'Anda yakin ingin menyimpan data sampel diterima ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, Simpan'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _saveSample();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isCompleteSample ? 'Konfirmasi Selesai' : 'Konfirmasi',
        ),
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
                    final dateLabel = widget.isCompleteSample
                        ? 'Tanggal Selesai'
                        : 'Tanggal Diterima';
                    final timeLabel = widget.isCompleteSample
                        ? 'Waktu Selesai'
                        : 'Waktu Diterima';
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
                            dateLabel: DateUtils.formatDateForDisplay(
                              _selectedDate,
                            ),
                            timeLabel:
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        widget.isCompleteSample
                            ? 'Tanggal Selesai'
                            : 'Tanggal Diterima',
                        DateUtils.formatDateForDisplay(_selectedDate),
                      ),
                      _buildInfoRow(
                        widget.isCompleteSample
                            ? 'Waktu Selesai'
                            : 'Waktu Diterima',
                        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _showSaveConfirmation,
                child: _isSaving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : Text(
                        widget.isCompleteSample
                            ? 'Simpan Sampel Selesai'
                            : 'Simpan Sampel',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
