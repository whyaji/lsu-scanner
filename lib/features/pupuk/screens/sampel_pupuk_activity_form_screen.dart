import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api/auth_api.dart';
import '../../../core/network/api/pupuk_api.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/network/models/api_response.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../constants/pupuk_activity_types.dart';
import '../models/pupuk_sampel_entry.dart';
import 'sampel_pupuk_photo_capture_screen.dart';
import '../../../widgets/feedback/app_dialog.dart';
import '../../../widgets/layout/app_card.dart';
import '../../../widgets/layout/app_page.dart';
import '../../../widgets/layout/app_sticky_action_bar.dart';

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

class SampelPupukActivityFormScreen extends ConsumerStatefulWidget {
  final String activityType;
  final List<PupukSampelEntry> samples;

  SampelPupukActivityFormScreen({
    super.key,
    required this.activityType,
    required this.samples,
  }) : assert(samples.isNotEmpty, 'At least one sample is required');

  @override
  ConsumerState<SampelPupukActivityFormScreen> createState() =>
      _SampelPupukActivityFormScreenState();
}

class _SampelPupukActivityFormScreenState
    extends ConsumerState<SampelPupukActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  AuthApi get _authApi => ref.read(authApiProvider);
  PupukApi get _pupukApi => ref.read(pupukApiProvider);
  final _noSuratController = TextEditingController();
  late DateTime _fixedDateTime;
  String? _namaPengirim;
  String? _noSurat;
  bool _isOnline = false;
  bool _loadingNoSurat = false;

  @override
  void initState() {
    super.initState();
    _fixedDateTime = DateTime.now();
    if (widget.activityType == kKirimLab) {
      _checkOnline();
    }
  }

  @override
  void dispose() {
    _noSuratController.dispose();
    super.dispose();
  }

  bool _isNetworkFailure<T>(ApiResponse<T> response) {
    return !response.success &&
        (response.error?.code == 'NETWORK_ERROR' ||
            response.error?.message.toLowerCase().contains('network') == true);
  }

  Future<void> _checkOnline() async {
    final response = await _authApi.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _isOnline = response.success && !_isNetworkFailure(response);
    });
  }

  Future<void> _fetchNextNoSurat() async {
    setState(() => _loadingNoSurat = true);
    final response = await _pupukApi.getNextNoSurat();
    if (!mounted) return;

    setState(() => _loadingNoSurat = false);

    if (response.success && response.data != null) {
      final noSurat = response.data!.noSurat.trim();
      if (noSurat.isNotEmpty) {
        _noSuratController.text = noSurat;
        _noSurat = noSurat;
        _formKey.currentState?.validate();
      }
      return;
    }

    await AppDialog.error(
      context,
      title: 'Nomor surat tidak tersedia',
      message:
          response.error?.message ?? 'Gagal mendapatkan nomor surat otomatis.',
    );
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

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      await AppDialog.warning(
        context,
        title: 'Form belum lengkap',
        message: 'Lengkapi semua field wajib sebelum melanjutkan.',
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
    return AppPage(
      title: labelForPupukActivityType(widget.activityType),
      bottomBar: AppStickyActionBar(
        primaryLabel: _isKirimLabMulti
            ? 'Lanjutkan, ambil foto semua sampel'
            : 'Lanjutkan, ambil foto',
        onPrimary: _submit,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isKirimLabMulti) ...[
              AppCard(
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
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  s.displayKodeSampel,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
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
              if (_isOnline) ...[
                OutlinedButton.icon(
                  onPressed: _loadingNoSurat ? null : _fetchNextNoSurat,
                  icon: _loadingNoSurat
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.numbers_outlined),
                  label: Text(
                    _loadingNoSurat
                        ? 'Mengambil no. surat...'
                        : 'Dapatkan no surat otomatis',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _noSuratController,
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
                onChanged: (v) => _noSurat = v.trim().isEmpty ? null : v.trim(),
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
          ],
        ),
      ),
    );
  }
}
