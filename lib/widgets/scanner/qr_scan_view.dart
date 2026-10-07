import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_spacing.dart';
import '../display/app_error_state.dart';
import 'qr_scan_throttle.dart';

/// Builds the camera surface. The default is [MobileScanner]; tests pass a
/// fake because no camera exists there.
typedef QrScannerSurfaceBuilder =
    Widget Function(
      BuildContext context,
      MobileScannerController controller,
      ValueChanged<BarcodeCapture> onDetect,
      Widget Function(BuildContext, MobileScannerException) errorBuilder,
    );

/// Camera preview that reports each QR code once.
///
/// Handles the parts every scanner screen needs: torch, a framing guide,
/// pause while a dialog is open, stop in the background, throttling of repeated
/// reads, a haptic tick on read, and a recoverable camera-permission state.
class QrScanView extends StatefulWidget {
  const QrScanView({
    super.key,
    required this.onCode,
    this.paused = false,
    this.hint,
    this.bottom,
    this.surfaceBuilder,
    this.openSettings = openAppSettings,
    this.throttle,
  });

  final ValueChanged<String> onCode;

  /// While true the camera stops and reads are ignored (a dialog is open).
  final bool paused;

  /// One short line under the framing guide.
  final String? hint;

  /// Anything pinned to the bottom edge, such as a count of scanned samples.
  final Widget? bottom;

  final QrScannerSurfaceBuilder? surfaceBuilder;
  final Future<bool> Function() openSettings;
  final QrScanThrottle? throttle;

  @override
  State<QrScanView> createState() => _QrScanViewState();
}

class _QrScanViewState extends State<QrScanView> with WidgetsBindingObserver {
  late final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  late final QrScanThrottle _throttle = widget.throttle ?? QrScanThrottle();
  bool _inBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(QrScanView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paused != widget.paused) {
      if (widget.paused) {
        _controller.stop();
      } else {
        _throttle.reset();
        _controller.start();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_inBackground && !widget.paused) _controller.start();
      _inBackground = false;
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _inBackground = true;
      _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (widget.paused) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code == null || code.isEmpty) continue;
      if (!_throttle.accept(code)) return;
      HapticFeedback.mediumImpact();
      widget.onCode(code);
      return;
    }
  }

  Widget _buildError(BuildContext context, MobileScannerException error) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    final unsupported = error.errorCode == MobileScannerErrorCode.unsupported;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: AppErrorState(
        title: denied
            ? 'Izin kamera ditolak'
            : unsupported
            ? 'Perangkat tidak mendukung pemindaian'
            : 'Kamera tidak dapat dibuka',
        message: denied
            ? 'Aktifkan izin kamera di pengaturan, lalu kembali ke sini untuk memindai label.'
            : unsupported
            ? 'Ketik kode sampel secara manual sebagai gantinya.'
            : 'Tutup aplikasi lain yang memakai kamera, lalu coba lagi.',
        retryLabel: denied ? 'Buka pengaturan' : 'Coba lagi',
        onRetry: unsupported
            ? null
            : denied
            ? widget.openSettings
            : () => _controller.start(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final builder = widget.surfaceBuilder;
    final surface = builder != null
        ? builder(context, _controller, _onDetect, _buildError)
        : MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: _buildError,
          );

    return Stack(
      fit: StackFit.expand,
      children: [
        surface,
        const IgnorePointer(child: _FramingGuide()),
        Positioned(
          top: AppSpacing.sm,
          right: AppSpacing.sm,
          child: _TorchButton(controller: _controller),
        ),
        if (widget.hint != null)
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: widget.bottom == null ? AppSpacing.md : 96,
            child: _HintPill(text: widget.hint!),
          ),
        if (widget.bottom != null)
          Positioned(left: 0, right: 0, bottom: 0, child: widget.bottom!),
      ],
    );
  }
}

/// White frame over a dimmed camera feed. The feed can be any color, so the
/// frame does not follow the theme: white on a black scrim always reads.
class _FramingGuide extends StatelessWidget {
  const _FramingGuide();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = (constraints.biggest.shortestSide * 0.7).clamp(
          180.0,
          320.0,
        );
        return Center(
          child: Container(
            width: side,
            height: side,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Color(0x73000000), spreadRadius: 1200),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TorchButton extends StatelessWidget {
  const _TorchButton({required this.controller});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controller,
      builder: (context, state, _) {
        if (state.torchState == TorchState.unavailable) {
          return const SizedBox.shrink();
        }
        final on = state.torchState == TorchState.on;
        return Material(
          color: on ? scheme.primary : scheme.surface,
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: on ? 'Matikan senter' : 'Nyalakan senter',
            constraints: const BoxConstraints(
              minWidth: AppSizes.tapTarget,
              minHeight: AppSizes.tapTarget,
            ),
            color: on ? scheme.onPrimary : scheme.onSurface,
            icon: Icon(on ? Icons.flash_on_rounded : Icons.flash_off_rounded),
            onPressed: controller.toggleTorch,
          ),
        );
      },
    );
  }
}

class _HintPill extends StatelessWidget {
  const _HintPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusChip),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
          ),
        ),
      ),
    );
  }
}
