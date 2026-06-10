import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../constants/pupuk_activity_types.dart';
import '../models/pupuk_sampel_entry.dart';
import '../widgets/pupuk_sampel_info_card.dart';
import 'pupuk_qr_scanner_screen.dart';
import 'sampel_pupuk_activity_form_screen.dart';

/// Collects multiple sampel for one Kirim Lab submission (shared no. surat & foto).
class KirimLabSampelCollectionScreen extends StatefulWidget {
  const KirimLabSampelCollectionScreen({
    super.key,
    required this.initialSamples,
  });

  final List<PupukSampelEntry> initialSamples;

  @override
  State<KirimLabSampelCollectionScreen> createState() =>
      _KirimLabSampelCollectionScreenState();
}

class _KirimLabSampelCollectionScreenState
    extends State<KirimLabSampelCollectionScreen> {
  late List<PupukSampelEntry> _samples;

  @override
  void initState() {
    super.initState();
    _samples = List.from(widget.initialSamples);
  }

  Set<int> get _sampleIds => _samples.map((s) => s.dataSampelPupukId).toSet();

  Future<void> _addSample() async {
    final added = await Navigator.of(context).push<PupukSampelEntry>(
      MaterialPageRoute(
        builder: (context) => PupukQRScannerScreen(
          activityType: kKirimLab,
          addToCollection: true,
          existingSampleIds: _sampleIds,
        ),
      ),
    );
    if (!mounted || added == null) return;
    setState(() => _samples.add(added));
  }

  void _removeSample(int index) {
    if (_samples.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal satu sampel harus ada dalam daftar.'),
        ),
      );
      return;
    }
    setState(() => _samples.removeAt(index));
  }

  void _continueToForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SampelPupukActivityFormScreen(
          activityType: kKirimLab,
          samples: List.unmodifiable(_samples),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Kirim Lab')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: AppSpacing.paddingScreen,
              child: Card(
                child: Padding(
                  padding: AppSpacing.paddingMd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daftar sampel (${_samples.length})',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      AppSpacing.gapSm,
                      Text(
                        'No. Surat dan foto akan sama untuk semua sampel di bawah. '
                        'Anda dapat menambah sampel lain dengan memindai QR.',
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
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
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
            Padding(
              padding: AppSpacing.paddingScreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _addSample,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Tambah Sampel Lain'),
                  ),
                  AppSpacing.gapSm,
                  ElevatedButton(
                    onPressed: _continueToForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Lanjutkan ke Formulir (${_samples.length} sampel)',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
