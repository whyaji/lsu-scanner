import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/kirim_dari_estate.dart';
import '../../../core/database/models/kirim_lab.dart';
import '../../home/providers/home_counts_refresh_provider.dart';
import '../../sample/screens/full_screen_image_preview_screen.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../constants/pupuk_activity_types.dart';
import 'sampel_pupuk_activity_form_screen.dart';

class SampelPupukConfirmationScreen extends ConsumerStatefulWidget {
  final SampelPupukFormData formData;
  final String photoPath;

  const SampelPupukConfirmationScreen({
    super.key,
    required this.formData,
    required this.photoPath,
  });

  @override
  ConsumerState<SampelPupukConfirmationScreen> createState() =>
      _SampelPupukConfirmationScreenState();
}

class _SampelPupukConfirmationScreenState
    extends ConsumerState<SampelPupukConfirmationScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isSaving = false;

  Future<bool> _showBackRetakePhotoDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.photo_camera_outlined, size: 40, color: cs.primary),
          iconColor: cs.primary,
          title: const Text('Kembali dan ambil foto ulang?'),
          content: const Text(
            'Apakah Anda yakin ingin kembali?\n\n'
            'Foto yang sudah diambil tidak akan dipakai. Anda akan kembali ke langkah sebelumnya untuk mengambil foto baru.',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Tetap di sini'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Ya, ambil ulang'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<bool> _showSaveDataDialog() async {
    final count = widget.formData.samples.length;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.save_alt_rounded, size: 40, color: cs.primary),
          iconColor: cs.primary,
          title: const Text('Simpan data aktivitas?'),
          content: Text(
            count > 1
                ? 'Pastikan ringkasan dan foto sudah sesuai.\n\n'
                      'Data $count sampel akan disimpan dengan No. Surat dan foto yang sama.'
                : 'Pastikan ringkasan dan foto sudah sesuai.\n\n'
                      'Data akan disimpan di perangkat Anda dan dapat diunggah nanti saat koneksi tersedia.',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Periksa lagi'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, simpan'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _onBackPressed() async {
    if (!mounted) return;
    final ok = await _showBackRetakePhotoDialog();
    if (!mounted || !ok) return;
    Navigator.of(context).pop();
  }

  Future<void> _confirmAndSave() async {
    if (_isSaving) return;
    if (!mounted) return;
    final ok = await _showSaveDataDialog();
    if (!mounted || !ok) return;
    await _save();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final now = app_date_utils.DateUtils.getCurrentIso8601DateTime();

      switch (widget.formData.activityType) {
        case kKirimDariEstate:
          for (final sample in widget.formData.samples) {
            await _dbHelper.insertKirimDariEstate(
              KirimDariEstate(
                dataSampelPupukId: sample.dataSampelPupukId,
                kodeSampel: sample.displayKodeSampel,
                tanggalKirimDariEstate: widget.formData.tanggalKirimDariEstate,
                fotoKirimDariEstate: widget.photoPath,
                namaPengirim: widget.formData.namaPengirim,
                status: AppConstants.statusNotUploaded,
                createdAt: now,
              ),
            );
          }
          break;
        case kKirimLab:
          for (final sample in widget.formData.samples) {
            await _dbHelper.insertKirimLab(
              KirimLab(
                dataSampelPupukId: sample.dataSampelPupukId,
                kodeSampel: sample.displayKodeSampel,
                noSurat: widget.formData.noSurat,
                tanggalKirimLab: widget.formData.tanggalKirimLab,
                fotoKirimLab: widget.photoPath,
                status: AppConstants.statusNotUploaded,
                createdAt: now,
              ),
            );
          }
          break;
        default:
          throw Exception(
            'Unknown activity type: ${widget.formData.activityType}',
          );
      }

      if (mounted) {
        ref.read(fertilizerCountsRefreshProvider.notifier).state++;
        final count = widget.formData.samples.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count > 1
                  ? '$count data Sampel Pupuk berhasil disimpan'
                  : 'Data Sampel Pupuk berhasil disimpan',
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
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateLabel = '';
    switch (widget.formData.activityType) {
      case kKirimDariEstate:
        dateLabel = 'Tanggal Kirim dari Estate';
        break;
      case kKirimLab:
        dateLabel = 'Tanggal Kirim Lab';
        break;
      default:
        dateLabel = 'Tanggal';
    }

    final previewKode = widget.formData.isMultiSample
        ? '${widget.formData.samples.length} sampel'
        : widget.formData.samples.first.displayKodeSampel;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        await _onBackPressed();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Konfirmasi Simpan'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Kembali',
            onPressed: _onBackPressed,
          ),
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
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => FullScreenImagePreviewScreen(
                            imagePath: widget.photoPath,
                            title: 'Foto Sampel Pupuk',
                            details: {
                              'Kode': previewKode,
                              dateLabel: _getDateValue(),
                              if (widget.formData.namaPengirim != null)
                                'Nama Pengirim': widget.formData.namaPengirim!,
                              if (widget.formData.noSurat != null &&
                                  widget.formData.noSurat!.isNotEmpty)
                                'No. Surat': widget.formData.noSurat!,
                            },
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: File(widget.photoPath).existsSync()
                          ? Image.file(
                              File(widget.photoPath),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              height: 200,
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 48,
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
                        const Text(
                          'Ringkasan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (widget.formData.isMultiSample) ...[
                          _row(
                            'Jumlah Sampel',
                            '${widget.formData.samples.length}',
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Kode Sampel',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          ...widget.formData.samples.map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('• ${s.displayKodeSampel}'),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ] else
                          _row(
                            'Kode Sampel',
                            widget.formData.samples.first.displayKodeSampel,
                          ),
                        _row(
                          'Aktivitas',
                          labelForPupukActivityType(
                            widget.formData.activityType,
                          ),
                        ),
                        _row(dateLabel, _getDateValue()),
                        if (widget.formData.namaPengirim != null)
                          _row('Nama Pengirim', widget.formData.namaPengirim!),
                        if (widget.formData.noSurat != null &&
                            widget.formData.noSurat!.isNotEmpty)
                          _row('No. Surat', widget.formData.noSurat!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : _confirmAndSave,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : Text(
                          widget.formData.isMultiSample
                              ? 'Simpan ${widget.formData.samples.length} Sampel'
                              : 'Simpan',
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDateValue() {
    String? raw;
    switch (widget.formData.activityType) {
      case kKirimDariEstate:
        raw = widget.formData.tanggalKirimDariEstate;
        break;
      case kKirimLab:
        raw = widget.formData.tanggalKirimLab;
        break;
      default:
        return '-';
    }
    return app_date_utils.DateUtils.formatPupukDetailTanggal(raw);
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
