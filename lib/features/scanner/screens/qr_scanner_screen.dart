import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utils/qr_parser.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../../sample/screens/sample_detail_screen.dart';

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

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String rawValue) async {
    print('rawValue: $rawValue');
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // Parse QR code
    final qrData = QRParser.parse(rawValue);
    if (qrData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Format QR code tidak valid'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      }
      return;
    }

    // Get master LSU data from local database
    final dbHelper = DatabaseHelper.instance;
    final masterLsu = await dbHelper.getMasterLsuById(qrData.masterLsuId);

    if (masterLsu == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data Master LSU tidak ditemukan'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      }
      return;
    }

    // Navigate to sample detail screen
    if (mounted) {
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
