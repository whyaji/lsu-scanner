import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/photo_capture_helper.dart';
import '../../../widgets/camera_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../constants/pupuk_activity_types.dart';
import 'sampel_pupuk_activity_form_screen.dart';
import 'sampel_pupuk_confirmation_screen.dart';

class SampelPupukPhotoCaptureScreen extends ConsumerStatefulWidget {
  final SampelPupukFormData formData;

  const SampelPupukPhotoCaptureScreen({super.key, required this.formData});

  @override
  ConsumerState<SampelPupukPhotoCaptureScreen> createState() =>
      _SampelPupukPhotoCaptureScreenState();
}

class _SampelPupukPhotoCaptureScreenState
    extends ConsumerState<SampelPupukPhotoCaptureScreen> {
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
    final typeLabel = labelForPupukActivityType(widget.formData.activityType);
    final samples = widget.formData.samples;
    final now = DateTime.now();
    final part =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    if (samples.length == 1) {
      return 'SAMPEL PUPUK\n$typeLabel\n${samples.first.displayKodeSampel}\n$part';
    }

    final kodes = samples.map((s) => s.displayKodeSampel).toList();
    final kodeLine = kodes.join('\n');
    return 'SAMPEL PUPUK\n$typeLabel\n$kodeLine\n${samples.length} sampel\n$part';
  }

  Future<void> _onCaptured(String tempPath) async {
    if (_isProcessing || !mounted) return;
    setState(() => _isProcessing = true);

    try {
      final watermarkedPath = await PhotoCaptureHelper.applyWatermark(
        sourcePath: tempPath,
        watermarkText: _watermarkText(),
      );
      if (watermarkedPath == null || !mounted) {
        _showError('Gagal menerapkan watermark');
        return;
      }

      final dir = await PhotoCaptureHelper.getAppPicturesDirectory(
        feature: 'Pupuk',
      );
      final userId = ref.read(authProvider).user?.id.toString();
      final first = widget.formData.samples.first;
      final fileName = PhotoCaptureHelper.newCaptureFileName(
        userId: userId,
        dataId: widget.formData.isMultiSample
            ? 'batch_${widget.formData.samples.length}'
            : first.dataSampelPupukId.toString(),
        sampelKode: widget.formData.isMultiSample
            ? first.displayKodeSampel
            : first.displayKodeSampel,
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
      await PhotoCaptureHelper.handleAutoDownload(savedPath, feature: 'Pupuk');
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
              builder: (context) => SampelPupukConfirmationScreen(
                formData: widget.formData,
                photoPath: _savedImagePath!,
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
    final sampleHint = widget.formData.isMultiSample
        ? ' (${widget.formData.samples.length} sampel)'
        : '';
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
                          'Ambil Foto – ${labelForPupukActivityType(widget.formData.activityType)}$sampleHint',
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
