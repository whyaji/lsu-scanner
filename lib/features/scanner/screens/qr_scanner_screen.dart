import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/database/database_helper.dart';
import '../../../widgets/app_error_dialog.dart';
import '../../sample/screens/sample_detail_screen.dart';
import '../utils/qr_parser.dart';

class QRScannerScreen extends StatefulWidget {
  /// When true, flow saves to completed_sample (tanggal_selesai/waktu_selesai).
  final bool isCompleteSample;

  const QRScannerScreen({super.key, this.isCompleteSample = false});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
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

    final qrData = QRParser.parse(rawValue);
    if (qrData == null) {
      if (mounted) {
        await _showErrorAndStop(
          'QR Tidak Valid',
          'Format QR code tidak valid. Pastikan memindai kode LSU yang benar.',
        );
      }
      return;
    }

    final dbHelper = DatabaseHelper.instance;
    final masterLsu = await dbHelper.getMasterLsuById(qrData.masterLsuId);

    if (masterLsu == null) {
      if (mounted) {
        await _showErrorAndStop(
          'Data Tidak Ditemukan',
          'Data Master LSU tidak ditemukan. Sinkronkan data terlebih dahulu.',
        );
      }
      return;
    }

    if (mounted) {
      _controller.stop();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SampleDetailScreen(
            dataLsuId: qrData.id,
            masterLsuId: qrData.masterLsuId,
            kode: qrData.kode,
            masterLsu: masterLsu,
            isCompleteSample: widget.isCompleteSample,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isCompleteSample ? 'Pindai QR Selesai' : 'Pindai QR Code',
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
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
