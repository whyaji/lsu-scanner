import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/data_sampel_pupuk.dart';
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

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String rawValue) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final qrData = QRParser.parsePupuk(rawValue);
    if (qrData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Format QR Sampel Pupuk tidak valid. Harap gunakan format: id^supplier^kodeSampel^jenisPupukFull^qty',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isProcessing = false);
      }
      return;
    }

    final dbHelper = DatabaseHelper.instance;
    final DataSampelPupuk? synced = await dbHelper.getDataSampelPupukById(
      qrData.id,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SampelPupukDetailScreen(
            dataSampelPupuk: synced,
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
      appBar: AppBar(
        title: const Text('Pindai QR Sampel Pupuk'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
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
