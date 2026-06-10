import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/data_sampel_pupuk.dart';
import '../../../widgets/app_error_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../scanner/utils/qr_parser.dart';
import '../constants/pupuk_activity_types.dart';
import '../models/pupuk_sampel_entry.dart';
import 'kirim_lab_sampel_collection_screen.dart';
import 'sampel_pupuk_detail_screen.dart';

class PupukQRScannerScreen extends ConsumerStatefulWidget {
  const PupukQRScannerScreen({
    super.key,
    required this.activityType,
    this.addToCollection = false,
    this.existingSampleIds = const {},
  });

  final String activityType;

  /// When true, pops with [PupukSampelEntry] instead of opening a new screen.
  final bool addToCollection;

  /// Sample IDs already in the Kirim Lab batch (duplicate check).
  final Set<int> existingSampleIds;

  @override
  ConsumerState<PupukQRScannerScreen> createState() =>
      _PupukQRScannerScreenState();
}

class _PupukQRScannerScreenState extends ConsumerState<PupukQRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  bool _isShowingDialog = false;

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  void _resumeScanning() {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _isShowingDialog = false;
    });
    _controller.start();
  }

  Future<void> _showErrorAndStop(String title, String message) async {
    if (!mounted || _isShowingDialog) return;
    _isShowingDialog = true;
    _controller.stop();
    await AppErrorDialog.show(
      context,
      title: title,
      message: message,
      onRetry: _resumeScanning,
    );
    if (mounted) setState(() => _isShowingDialog = false);
  }

  String _activityAlreadyRecordedMessage() {
    switch (widget.activityType) {
      case kKirimDariEstate:
        return 'Kirim dari Estate untuk sampel ini sudah dicatat.';
      case kKirimLab:
        return 'Kirim Lab untuk sampel ini sudah dicatat.';
      default:
        return 'Aktivitas ini sudah dicatat untuk sampel tersebut.';
    }
  }

  Future<void> _handleQRCode(String rawValue) async {
    if (_isProcessing || _isShowingDialog) return;
    setState(() => _isProcessing = true);

    final qrData = QRParser.parsePupuk(rawValue);
    if (qrData == null) {
      if (mounted) {
        await _showErrorAndStop(
          'QR Tidak Valid',
          'Format QR Sampel Pupuk tidak valid.',
        );
      }
      return;
    }

    if (widget.existingSampleIds.contains(qrData.id)) {
      if (mounted) {
        await _showErrorAndStop(
          'Sampel Sudah Ada',
          'Sampel ini sudah ada dalam daftar Kirim Lab.',
        );
      }
      return;
    }

    final permissions = ref.read(authProvider).user?.permissions;
    final dbHelper = DatabaseHelper.instance;
    final DataSampelPupuk? synced = await dbHelper.getDataSampelPupukById(
      qrData.id,
    );
    final aktivitas = synced != null
        ? await dbHelper.getAktivitasSampelPupukByDataSampelPupukId(qrData.id)
        : null;

    final allowed = allowedPupukActivityTypes(
      permissions,
      aktivitas,
      dataSampelPupukFallback: synced,
    );

    if (!allowed.contains(widget.activityType)) {
      if (mounted) {
        await _showErrorAndStop(
          'Aktivitas Tidak Tersedia',
          _activityAlreadyRecordedMessage(),
        );
      }
      return;
    }

    final entry = PupukSampelEntry.fromScan(
      qrPupukData: qrData,
      dataSampelPupuk: synced,
    );

    if (!mounted) return;
    _controller.stop();

    if (widget.addToCollection) {
      Navigator.of(context).pop(entry);
      return;
    }

    if (widget.activityType == kKirimLab) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              KirimLabSampelCollectionScreen(initialSamples: [entry]),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SampelPupukDetailScreen(
          entry: entry,
          selectedActivityType: widget.activityType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activityLabel = labelForPupukActivityType(widget.activityType);
    final title = widget.addToCollection
        ? 'Tambah Sampel – $activityLabel'
        : 'Pindai QR – $activityLabel';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                if (barcode.rawValue != null) {
                  _handleQRCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
