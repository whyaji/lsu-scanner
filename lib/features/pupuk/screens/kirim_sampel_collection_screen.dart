import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../widgets/layout/app_card.dart';
import '../../../widgets/layout/app_page.dart';
import '../../../widgets/layout/app_sticky_action_bar.dart';
import '../constants/pupuk_activity_types.dart';
import '../models/pupuk_sampel_entry.dart';
import '../widgets/pupuk_sampel_info_card.dart';
import '../../../widgets/feedback/app_banner.dart';
import '../../../widgets/feedback/app_notice_type.dart';
import 'pupuk_qr_scanner_screen.dart';
import 'sampel_pupuk_activity_form_screen.dart';

/// Collects multiple sampel for one Kirim Lab or Kirim Estate submission (shared photo & fields).
class KirimSampelCollectionScreen extends StatefulWidget {
  const KirimSampelCollectionScreen({
    super.key,
    required this.activityType,
    required this.initialSamples,
  });

  final String activityType;
  final List<PupukSampelEntry> initialSamples;

  @override
  State<KirimSampelCollectionScreen> createState() =>
      _KirimSampelCollectionScreenState();
}

class _KirimSampelCollectionScreenState
    extends State<KirimSampelCollectionScreen> {
  late List<PupukSampelEntry> _samples;
  String? _removeError;

  @override
  void initState() {
    super.initState();
    _samples = List.from(widget.initialSamples);
  }

  Set<String> get _sampleCodes => _samples.map((s) => s.kodeSampel).toSet();

  Future<void> _addSample() async {
    final added = await Navigator.of(context).push<PupukSampelEntry>(
      MaterialPageRoute(
        builder: (context) => PupukQRScannerScreen(
          activityType: widget.activityType,
          addToCollection: true,
          existingSampleCodes: _sampleCodes,
        ),
      ),
    );
    if (!mounted || added == null) return;
    setState(() => _samples.add(added));
  }

  void _removeSample(int index) {
    if (_samples.length <= 1) {
      setState(
        () => _removeError = 'Minimal satu sampel harus ada dalam daftar.',
      );
      return;
    }
    setState(() {
      _removeError = null;
      _samples.removeAt(index);
    });
  }

  void _continueToForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SampelPupukActivityFormScreen(
          activityType: widget.activityType,
          samples: List.unmodifiable(_samples),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLab = widget.activityType == kKirimLab;
    final title = isLab ? 'Konfirmasi Kirim Lab' : 'Konfirmasi Kirim Estate';
    final desc = isLab
        ? 'No. Surat dan foto akan sama untuk semua sampel di bawah. Anda dapat menambah sampel lain dengan memindai QR.'
        : 'Nama pengirim dan foto akan sama untuk semua sampel di bawah. Anda dapat menambah sampel lain dengan memindai QR.';

    return AppPage(
      title: title,
      scroll: false,
      bottomBar: AppStickyActionBar(
        primaryLabel: 'Lanjutkan ke formulir',
        onPrimary: _continueToForm,
        secondaryLabel: 'Tambah sampel',
        onSecondary: _addSample,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppSpacing.paddingScreen,
            child: AppCard(
              child: Padding(
                padding: AppSpacing.paddingMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daftar sampel (${_samples.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.gapSm,
                    Text(
                      desc,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _samples.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = _samples[index];
                return PupukSampelInfoCard(
                  entry: entry,
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Hapus dari daftar',
                    onPressed: () => _removeSample(index),
                  ),
                );
              },
            ),
          ),
          if (_removeError != null)
            Padding(
              padding: AppSpacing.paddingScreen,
              child: AppBanner(
                type: AppNoticeType.warning,
                message: _removeError!,
                onDismiss: () => setState(() => _removeError = null),
              ),
            ),
        ],
      ),
    );
  }
}
