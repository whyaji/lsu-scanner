import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/models/master_lsu.dart';
import '../../../core/utils/photo_capture_helper.dart';
import '../../../widgets/camera_view.dart';
import '../../auth/providers/auth_provider.dart';
import 'confirmation_screen.dart';

class PhotoCaptureScreen extends ConsumerStatefulWidget {
  final int dataLsuId;
  final int masterLsuId;
  final String kode;
  final MasterLsu masterLsu;
  final bool isCompleteSample;

  const PhotoCaptureScreen({
    super.key,
    required this.dataLsuId,
    required this.masterLsuId,
    required this.kode,
    required this.masterLsu,
    this.isCompleteSample = false,
  });

  @override
  ConsumerState<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends ConsumerState<PhotoCaptureScreen> {
  String? _savedImagePath;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _lockLandscape();
  }

  @override
  void dispose() {
    _unlockOrientation();
    super.dispose();
  }

  void _lockLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _lockPortrait() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  void _unlockOrientation() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  String _watermarkText() {
    final e = widget.masterLsu.estate ?? '-';
    final a = widget.masterLsu.afdeling ?? '-';
    final b = widget.masterLsu.blok ?? '-';
    final line2 = '$e/$a/$b';
    final now = DateTime.now();
    final part =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final statusLine = widget.isCompleteSample ? 'SELESAI' : 'DITERIMA';
    return '$statusLine\n${widget.kode}\n$line2\n$part';
  }

  Future<void> _onCaptured(String tempPath) async {
    if (_isProcessing || !mounted) return;
    setState(() => _isProcessing = true);

    try {
      final watermarkText = _watermarkText();
      final watermarkedPath = await PhotoCaptureHelper.applyWatermark(
        sourcePath: tempPath,
        watermarkText: watermarkText,
      );
      if (watermarkedPath == null || !mounted) {
        _showError('Gagal menerapkan watermark');
        return;
      }

      final dir = await PhotoCaptureHelper.getAppPicturesDirectory();
      final userId = ref.read(authProvider).user?.id.toString();
      final fileName = PhotoCaptureHelper.newCaptureFileName(
        userId: userId,
        dataId: widget.dataLsuId.toString(),
        sampelKode: widget.kode,
        blok: widget.masterLsu.blok,
      );
      final savedPath = await PhotoCaptureHelper.compressAndSave(
        sourcePath: watermarkedPath,
        outputDir: dir,
        outputFileName: fileName,
      );
      if (savedPath == null || !mounted) {
        _showError('Gagal menyimpan foto');
        return;
      }

      await PhotoCaptureHelper.notifyGallery(savedPath);
      if (mounted) {
        setState(() {
          _savedImagePath = savedPath;
          _isProcessing = false;
        });
        _lockPortrait();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _savedImagePath == null) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (context) => ConfirmationScreen(
                dataLsuId: widget.dataLsuId,
                masterLsuId: widget.masterLsuId,
                kode: widget.kode,
                masterLsu: widget.masterLsu,
                photoPath: _savedImagePath!,
                isCompleteSample: widget.isCompleteSample,
              ),
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Kesalahan: $e');
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, body: _buildCamera());
  }

  Widget _buildCamera() {
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraView(
          onCaptured: _onCaptured,
          onError: (msg) {
            if (mounted) _showError(msg);
          },
          buildHeader:
              (
                context, {
                required flashMode,
                required cycleFlash,
                required flashSupported,
              }) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  color: Colors.black.withValues(alpha: 0.6),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          widget.isCompleteSample
                              ? 'Ambil Foto Selesai'
                              : 'Ambil Foto',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (flashSupported)
                        IconButton(
                          onPressed: cycleFlash,
                          icon: Icon(
                            switch (flashMode) {
                              CameraFlashMode.off => Icons.flash_off,
                              CameraFlashMode.torch => Icons.flash_on,
                              CameraFlashMode.onCapture => Icons.flash_auto,
                            },
                            color: Colors.white,
                            size: 28,
                          ),
                          tooltip: switch (flashMode) {
                            CameraFlashMode.off => 'Flash mati',
                            CameraFlashMode.torch => 'Flash selalu menyala',
                            CameraFlashMode.onCapture =>
                              'Flash saat ambil foto',
                          },
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                );
              },
        ),
        if (_isProcessing)
          Container(
            color: Colors.black54,
            alignment: Alignment.center,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Menyimpan foto…',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
