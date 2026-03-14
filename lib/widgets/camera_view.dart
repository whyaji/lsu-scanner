import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Flash mode for the camera: off, always on (torch), or flash when taking photo.
enum CameraFlashMode { off, torch, onCapture }

/// Signature for building a custom header (e.g. back + title + flash on the right).
typedef CameraHeaderBuilder =
    Widget Function(
      BuildContext context, {
      required CameraFlashMode flashMode,
      required VoidCallback cycleFlash,
      required bool flashSupported,
    });

/// Reusable camera widget: live preview (no watermark overlay), capture button.
/// Caller handles watermark, compress, save, and gallery.
///
/// [onCaptured] is called with the temp file path from [CameraController.takePicture()].
/// [onError] is called when permission is denied or camera init fails.
/// When [buildHeader] is provided, it is shown at the top and the default flash button is not drawn.
class CameraView extends StatefulWidget {
  /// Called with the path of the temporary image file from takePicture().
  final void Function(String path) onCaptured;

  /// Called when permission is denied or camera fails to initialize.
  final void Function(String message)? onError;

  /// Optional overlay widget (e.g. hint text). Do not use for watermark — apply after capture.
  final Widget? overlay;

  /// When set, this header is shown at the top (e.g. back, title, flash right). Flash is not drawn separately.
  final CameraHeaderBuilder? buildHeader;

  const CameraView({
    super.key,
    required this.onCaptured,
    this.onError,
    this.overlay,
    this.buildHeader,
  });

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isReady = false;
  bool _isCapturing = false;
  CameraFlashMode _flashMode = CameraFlashMode.off;
  bool _flashSupported = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _setError('Izin kamera diperlukan');
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _setError('Tidak ada kamera');
        return;
      }

      // Default to rear (back) camera; fallback to first if no back camera.
      final backCameras = _cameras.where(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      final camera = backCameras.isNotEmpty
          ? backCameras.first
          : _cameras.first;

      final controller = CameraController(
        camera,
        ResolutionPreset.veryHigh,
        imageFormatGroup: ImageFormatGroup.jpeg,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isReady = true;
        _errorMessage = null;
      });
    } catch (e) {
      _setError('Kesalahan kamera: $e');
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _isReady = false;
      _errorMessage = message;
    });
    widget.onError?.call(message);
  }

  Future<void> _capture() async {
    final ctrl = _controller;
    if (ctrl == null || !_isReady || _isCapturing) return;
    if (!ctrl.value.isInitialized) return;

    setState(() => _isCapturing = true);
    try {
      final file = await ctrl.takePicture();
      if (!mounted) return;
      widget.onCaptured(file.path);
    } catch (e) {
      if (mounted) {
        _setError('Pengambilan gagal: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  /// Cycles flash: off → torch → onCapture → off.
  Future<void> _cycleFlash() async {
    final ctrl = _controller;
    if (ctrl == null || !_isReady || !ctrl.value.isInitialized) return;
    try {
      final next = switch (_flashMode) {
        CameraFlashMode.off => CameraFlashMode.torch,
        CameraFlashMode.torch => CameraFlashMode.onCapture,
        CameraFlashMode.onCapture => CameraFlashMode.off,
      };
      final flashMode = switch (next) {
        CameraFlashMode.off => FlashMode.off,
        CameraFlashMode.torch => FlashMode.torch,
        CameraFlashMode.onCapture => FlashMode.always,
      };
      await ctrl.setFlashMode(flashMode);
      if (mounted) setState(() => _flashMode = next);
    } catch (_) {
      if (mounted) setState(() => _flashSupported = false);
    }
  }

  Widget _buildPreviewFit() {
    final previewSize = _controller!.value.previewSize;
    if (previewSize == null) return const SizedBox.shrink();
    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: previewSize.width,
          height: previewSize.height,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return SafeArea(
        child: Container(
          color: Colors.black87,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isReady || _controller == null) {
      return SafeArea(
        child: Container(
          color: Colors.black87,
          alignment: Alignment.center,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Menginisialisasi kamera…',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildPreviewFit(),
          if (widget.overlay != null) widget.overlay!,
          if (widget.buildHeader != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: widget.buildHeader!(
                  context,
                  flashMode: _flashMode,
                  cycleFlash: _cycleFlash,
                  flashSupported: _flashSupported,
                ),
              ),
            )
          else if (_flashSupported)
            Positioned(
              top: 16,
              right: 16,
              child: Material(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: _cycleFlash,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      switch (_flashMode) {
                        CameraFlashMode.off => Icons.flash_off,
                        CameraFlashMode.torch => Icons.flash_on,
                        CameraFlashMode.onCapture => Icons.flash_auto,
                      },
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          // Shutter button — center right
          Positioned(
            right: 24,
            top: 0,
            bottom: 0,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isCapturing ? null : _capture,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: _isCapturing
                          ? Colors.white54
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                    child: _isCapturing
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 36,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
