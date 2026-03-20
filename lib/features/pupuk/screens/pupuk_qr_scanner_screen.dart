import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/data_sampel_pupuk.dart';
import '../../../widgets/app_error_dialog.dart';
import '../../scanner/utils/qr_parser.dart';
import 'sampel_pupuk_detail_screen.dart';

class PupukQRScannerScreen extends StatefulWidget {
  const PupukQRScannerScreen({super.key});

  @override
  State<PupukQRScannerScreen> createState() => _PupukQRScannerScreenState();
}

class _PupukQRScannerScreenState extends State<PupukQRScannerScreen> {
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

    final dbHelper = DatabaseHelper.instance;
    final DataSampelPupuk? synced = await dbHelper.getDataSampelPupukById(
      qrData.id,
    );
    final aktivitas = synced != null
        ? await dbHelper.getAktivitasSampelPupukByDataSampelPupukId(qrData.id)
        : null;

    if (mounted) {
      _controller.stop();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SampelPupukDetailScreen(
            dataSampelPupuk: synced,
            aktivitasSampelPupuk: aktivitas,
            qrPupukData: qrData,
            fromSync: synced != null,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pindai QR Sampel Pupuk')),
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
