import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/data_sampel_pupuk.dart';
import '../../../core/database/models/terima_dari_gudang.dart';
import '../../../core/database/models/kirim_dari_estate.dart';
import '../../../core/database/models/terima_dari_estate.dart';
import '../../../core/database/models/kirim_lab.dart';
import '../../home/providers/home_counts_refresh_provider.dart';
import '../../sample/screens/full_screen_image_preview_screen.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../constants/pupuk_activity_types.dart';
import 'sampel_pupuk_activity_form_screen.dart';
import '../../scanner/utils/qr_parser.dart';

class SampelPupukConfirmationScreen extends ConsumerStatefulWidget {
  final SampelPupukFormData formData;
  final String photoPath;
  final QRPupukData qrPupukData;
  final DataSampelPupuk? dataSampelPupuk;

  const SampelPupukConfirmationScreen({
    super.key,
    required this.formData,
    required this.photoPath,
    required this.qrPupukData,
    this.dataSampelPupuk,
  });

  @override
  ConsumerState<SampelPupukConfirmationScreen> createState() =>
      _SampelPupukConfirmationScreenState();
}

class _SampelPupukConfirmationScreenState
    extends ConsumerState<SampelPupukConfirmationScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isSaving = false;

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final now = app_date_utils.DateUtils.getCurrentIso8601DateTime();
      final kode = widget.formData.kodeSampel.isEmpty
          ? widget.qrPupukData.kodeSampel
          : widget.formData.kodeSampel;

      switch (widget.formData.activityType) {
        case kTerimaDariGudang:
          await _dbHelper.insertTerimaDariGudang(
            TerimaDariGudang(
              dataSampelPupukId: widget.formData.dataSampelPupukId,
              kodeSampel: kode,
              tanggalTerimaDariGudang: widget.formData.tanggalTerimaDariGudang,
              fotoTerimaDariGudang: widget.photoPath,
              status: AppConstants.statusNotUploaded,
              createdAt: now,
            ),
          );
          break;
        case kKirimDariEstate:
          await _dbHelper.insertKirimDariEstate(
            KirimDariEstate(
              dataSampelPupukId: widget.formData.dataSampelPupukId,
              kodeSampel: kode,
              tanggalKirimDariEstate: widget.formData.tanggalKirimDariEstate,
              fotoKirimDariEstate: widget.photoPath,
              namaPengirim: widget.formData.namaPengirim,
              status: AppConstants.statusNotUploaded,
              createdAt: now,
            ),
          );
          break;
        case kTerimaDariEstate:
          await _dbHelper.insertTerimaDariEstate(
            TerimaDariEstate(
              dataSampelPupukId: widget.formData.dataSampelPupukId,
              kodeSampel: kode,
              noSurat: widget.formData.noSurat,
              tanggalTerimaDariEstate: widget.formData.tanggalTerimaDariEstate,
              fotoTerimaDariEstate: widget.photoPath,
              status: AppConstants.statusNotUploaded,
              createdAt: now,
            ),
          );
          break;
        case kKirimLab:
          await _dbHelper.insertKirimLab(
            KirimLab(
              dataSampelPupukId: widget.formData.dataSampelPupukId,
              kodeSampel: kode,
              tanggalKirimLab: widget.formData.tanggalKirimLab,
              fotoKirimLab: widget.photoPath,
              status: AppConstants.statusNotUploaded,
              createdAt: now,
            ),
          );
          break;
        default:
          throw Exception(
            'Unknown activity type: ${widget.formData.activityType}',
          );
      }

      if (mounted) {
        ref.read(fertilizerCountsRefreshProvider.notifier).state++;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data Sampel Pupuk berhasil disimpan'),
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
    final kode = widget.formData.kodeSampel.isEmpty
        ? widget.qrPupukData.kodeSampel
        : widget.formData.kodeSampel;
    String dateLabel = '';
    switch (widget.formData.activityType) {
      case kTerimaDariGudang:
        dateLabel = 'Tanggal Terima dari Gudang';
        break;
      case kKirimDariEstate:
        dateLabel = 'Tanggal Kirim dari Estate';
        break;
      case kTerimaDariEstate:
        dateLabel = 'Tanggal Terima dari Estate';
        break;
      case kKirimLab:
        dateLabel = 'Tanggal Kirim Lab';
        break;
      default:
        dateLabel = 'Tanggal';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Simpan')),
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
                            'Kode': kode,
                            dateLabel: _getDateValue(),
                            if (widget.formData.namaPengirim != null)
                              'Nama Pengirim': widget.formData.namaPengirim!,
                            if (widget.formData.noSurat != null)
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
                              child: Icon(Icons.image_not_supported, size: 48),
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
                      _row('Kode Sampel', kode),
                      _row(
                        'Aktivitas',
                        labelForPupukActivityType(widget.formData.activityType),
                      ),
                      _row(dateLabel, _getDateValue()),
                      if (widget.formData.namaPengirim != null)
                        _row('Nama Pengirim', widget.formData.namaPengirim!),
                      if (widget.formData.noSurat != null)
                        _row('No. Surat', widget.formData.noSurat!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
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
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDateValue() {
    String? raw;
    switch (widget.formData.activityType) {
      case kTerimaDariGudang:
        raw = widget.formData.tanggalTerimaDariGudang;
        break;
      case kKirimDariEstate:
        raw = widget.formData.tanggalKirimDariEstate;
        break;
      case kTerimaDariEstate:
        raw = widget.formData.tanggalTerimaDariEstate;
        break;
      case kKirimLab:
        raw = widget.formData.tanggalKirimLab;
        break;
      default:
        return '-';
    }
    return app_date_utils.DateUtils.formatDateTimeFromIso(raw);
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
