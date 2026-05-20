import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../constants/pupuk_activity_types.dart';
import '../models/pupuk_sampel_entry.dart';
import 'sampel_pupuk_photo_capture_screen.dart';

/// Form data to pass to photo capture and then confirmation.
class SampelPupukFormData {
  final String activityType;
  final List<PupukSampelEntry> samples;
  final String tanggalKirimDariEstate;
  final String? namaPengirim;
  final String? noSurat;
  final String tanggalKirimLab;

  SampelPupukFormData({
    required this.activityType,
    required this.samples,
    this.tanggalKirimDariEstate = '',
    this.namaPengirim,
    this.noSurat,
    this.tanggalKirimLab = '',
  });

  bool get isMultiSample => samples.length > 1;
}

class SampelPupukActivityFormScreen extends StatefulWidget {
  final String activityType;
  final List<PupukSampelEntry> samples;

  SampelPupukActivityFormScreen({
    super.key,
    required this.activityType,
    required this.samples,
  }) : assert(samples.isNotEmpty, 'At least one sample is required');

  @override
  State<SampelPupukActivityFormScreen> createState() =>
      _SampelPupukActivityFormScreenState();
}

class _SampelPupukActivityFormScreenState
    extends State<SampelPupukActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();

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
      app_date_utils.DateUtils.formatDateTimeForDisplay(_fixedDateTime);

  bool get _isKirimLabMulti =>
      widget.activityType == kKirimLab && widget.samples.length > 1;

  SampelPupukFormData _buildFormData() {
    return SampelPupukFormData(
      activityType: widget.activityType,
      samples: widget.samples,
      tanggalKirimDariEstate: widget.activityType == kKirimDariEstate
          ? _dateTimeIso
          : '',
      namaPengirim: widget.activityType == kKirimDariEstate
          ? _namaPengirim
          : null,
      noSurat: widget.activityType == kKirimLab ? _noSurat : null,
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
        builder: (context) =>
            SampelPupukPhotoCaptureScreen(formData: _buildFormData()),
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
                if (_isKirimLabMulti) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sampel (${widget.samples.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No. Surat dan foto berlaku untuk semua sampel berikut.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          ...widget.samples.map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 18,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      s.displayKodeSampel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
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
                if (widget.activityType == kKirimDariEstate) ...[
                  const SizedBox(height: 16),
                  if (widget.samples.length == 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Kode: ${widget.samples.first.displayKodeSampel}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Nama Pengirim',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Nama Pengirim wajib diisi';
                      return null;
                    },
                    initialValue: _namaPengirim,
                    onChanged: (v) =>
                        _namaPengirim = v.trim().isEmpty ? null : v.trim(),
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
                  child: Text(
                    _isKirimLabMulti
                        ? 'Lanjutkan – Ambil Foto (semua sampel)'
                        : 'Lanjutkan – Ambil Foto',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
