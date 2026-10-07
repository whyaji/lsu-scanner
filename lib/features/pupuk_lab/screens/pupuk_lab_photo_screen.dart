import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/photo_capture_helper.dart';
import '../../../widgets/camera_view.dart';
import '../../../widgets/feedback/app_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/pupuk_lab_draft_notifier.dart';

/// Takes one photo of the sample, stamps it, saves it on the device and pops
/// with its path. Landscape like the other pupuk photo screens, because the
/// shutter sits at the right edge.
class PupukLabPhotoScreen extends ConsumerStatefulWidget {
  const PupukLabPhotoScreen({super.key});

  @override
  ConsumerState<PupukLabPhotoScreen> createState() =>
      _PupukLabPhotoScreenState();
}

class _PupukLabPhotoScreenState extends ConsumerState<PupukLabPhotoScreen> {
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  String _watermark() {
    final draft = ref.read(pupukLabDraftProvider);
    final stamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final noSurat = draft.noSurat.trim();
    return 'TERIMA LAB\n${noSurat.isEmpty ? '-' : noSurat}\n${draft.samples.length} sampel\n$stamp';
  }

  Future<void> _fail(String message) async {
    if (!mounted) return;
    setState(() => _processing = false);
    await AppDialog.error(
      context,
      title: 'Foto belum tersimpan',
      message: message,
    );
  }

  Future<void> _onCaptured(String tempPath) async {
    if (_processing || !mounted) return;
    setState(() => _processing = true);
    try {
      final stamped = await PhotoCaptureHelper.applyWatermark(
        sourcePath: tempPath,
        watermarkText: _watermark(),
      );
      if (stamped == null) {
        return _fail('Gagal menambahkan cap pada foto. Coba ambil lagi.');
      }

      final dir = await PhotoCaptureHelper.getAppPicturesDirectory(
        feature: 'Pupuk',
      );
      final draft = ref.read(pupukLabDraftProvider);
      final saved = await PhotoCaptureHelper.compressAndSave(
        sourcePath: stamped,
        outputDir: dir,
        outputFileName: PhotoCaptureHelper.newCaptureFileName(
          userId: ref.read(authProvider).user?.id.toString(),
          dataId: 'terima_lab',
          sampelKode: draft.samples.isEmpty ? null : draft.samples.first.kode,
        ),
      );
      if (saved == null) {
        return _fail('Gagal menyimpan foto. Pastikan ruang penyimpanan cukup.');
      }

      await PhotoCaptureHelper.notifyGallery(saved);
      await PhotoCaptureHelper.handleAutoDownload(saved, feature: 'Pupuk');
      if (mounted) Navigator.of(context).pop(saved);
    } catch (e) {
      await _fail('Terjadi kesalahan saat memproses foto: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraView(
            onCaptured: _onCaptured,
            onError: (message) {
              if (mounted) {
                AppDialog.error(
                  context,
                  title: 'Kamera tidak bisa dipakai',
                  message: message,
                );
              }
            },
            buildHeader:
                (
                  context, {
                  required flashMode,
                  required cycleFlash,
                  required flashSupported,
                }) => Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Kembali',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Expanded(
                        child: Text(
                          'Foto sampel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (flashSupported)
                        IconButton(
                          tooltip: 'Ganti mode senter',
                          onPressed: cycleFlash,
                          icon: Icon(switch (flashMode) {
                            CameraFlashMode.off => Icons.flash_off,
                            CameraFlashMode.torch => Icons.flash_on,
                            CameraFlashMode.onCapture => Icons.flash_auto,
                          }, color: Colors.white),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
          ),
          if (_processing)
            const ColoredBox(
              color: Color(0x99000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
