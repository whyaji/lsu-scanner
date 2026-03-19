import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/models/data_sampel_pupuk.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../scanner/utils/qr_parser.dart';
import '../constants/pupuk_activity_types.dart';
import 'sampel_pupuk_photo_capture_screen.dart';

/// Form data to pass to photo capture and then confirmation.
class SampelPupukFormData {
  final String activityType;
  final int dataSampelPupukId;
  final String kodeSampel;
  final String tanggalTerimaDariGudang;
  final String tanggalKirimDariEstate;
  final String? namaPengirim;
  final String? noSurat;
  final String tanggalTerimaDariEstate;
  final String tanggalKirimLab;

  SampelPupukFormData({
    required this.activityType,
    required this.dataSampelPupukId,
    required this.kodeSampel,
    this.tanggalTerimaDariGudang = '',
    this.tanggalKirimDariEstate = '',
    this.namaPengirim,
    this.noSurat,
    this.tanggalTerimaDariEstate = '',
    this.tanggalKirimLab = '',
  });
}

class SampelPupukActivityFormScreen extends StatefulWidget {
  final String activityType;
  final int dataSampelPupukId;
  final String kodeSampel;
  final DataSampelPupuk? dataSampelPupuk;
  final QRPupukData qrPupukData;

  const SampelPupukActivityFormScreen({
    super.key,
    required this.activityType,
    required this.dataSampelPupukId,
    required this.kodeSampel,
    this.dataSampelPupuk,
    required this.qrPupukData,
  });

  @override
  State<SampelPupukActivityFormScreen> createState() =>
      _SampelPupukActivityFormScreenState();
}

class _SampelPupukActivityFormScreenState
    extends State<SampelPupukActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();

  /// Fixed at form open; user cannot change (API: datetime with time, local consistency).
  late DateTime _fixedDateTime;
  String? _namaPengirim;
  String? _noSurat;

  @override
  void initState() {
    super.initState();
    _fixedDateTime = DateTime.now();
  }

  String get _dateTimeIso => _fixedDateTime.toIso8601String();
  String get _dateTimeDisplay =>
      app_date_utils.DateUtils.formatDateTime(_fixedDateTime);

  SampelPupukFormData _buildFormData() {
    return SampelPupukFormData(
      activityType: widget.activityType,
      dataSampelPupukId: widget.dataSampelPupukId,
      kodeSampel: widget.kodeSampel,
      tanggalTerimaDariGudang: widget.activityType == kTerimaDariGudang
          ? _dateTimeIso
          : '',
      tanggalKirimDariEstate: widget.activityType == kKirimDariEstate
          ? _dateTimeIso
          : '',
      namaPengirim: widget.activityType == kKirimDariEstate
          ? _namaPengirim
          : null,
      noSurat: widget.activityType == kKirimLab ? _noSurat : null,
      tanggalTerimaDariEstate: widget.activityType == kTerimaDariEstate
          ? _dateTimeIso
          : '',
      tanggalKirimLab: widget.activityType == kKirimLab ? _dateTimeIso : '',
    );
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi field yang wajib diisi.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SampelPupukPhotoCaptureScreen(
          formData: _buildFormData(),
          dataSampelPupuk: widget.dataSampelPupuk,
          qrPupukData: widget.qrPupukData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(labelForPupukActivityType(widget.activityType)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                IgnorePointer(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal & Waktu',
                      border: OutlineInputBorder(),
                      hintText: 'Diisi otomatis',
                    ),
                    child: Text(_dateTimeDisplay),
                  ),
                ),
                if (widget.activityType == kKirimDariEstate) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Nama Pengirim',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) {
                        return 'Nama Pengirim wajib diisi';
                      }
                      return null;
                    },
                    onSaved: (v) => _namaPengirim = v?.trim(),
                    initialValue: _namaPengirim,
                    onChanged: (v) =>
                        _namaPengirim = v.trim().isEmpty ? null : v.trim(),
                  ),
                ],
                if (widget.activityType == kKirimLab) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'No. Surat',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) {
                        return 'No. Surat wajib diisi';
                      }
                      return null;
                    },
                    onSaved: (v) => _noSurat = v?.trim(),
                    initialValue: _noSurat,
                    onChanged: (v) =>
                        _noSurat = v.trim().isEmpty ? null : v.trim(),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Lanjutkan – Ambil Foto'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
