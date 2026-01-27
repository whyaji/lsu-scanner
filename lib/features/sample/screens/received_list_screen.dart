import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/received_sample.dart';
import 'received_sample_detail_screen.dart';

class ReceivedListScreen extends StatefulWidget {
  final bool isPending;

  const ReceivedListScreen({super.key, required this.isPending});

  @override
  State<ReceivedListScreen> createState() => _ReceivedListScreenState();
}

class _ReceivedListScreenState extends State<ReceivedListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<ReceivedSample> _samples = [];
  bool _loading = true;

  Future<void> _loadSamples() async {
    setState(() => _loading = true);
    final list = widget.isPending
        ? await _dbHelper.getPendingUploads()
        : await _dbHelper.getUploadedSamples();
    if (mounted) {
      setState(() {
        _samples = list;
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSamples();
  }

  Color _statusColor(String status) {
    switch (status) {
      case AppConstants.statusUploaded:
        return AppColors.success;
      case AppConstants.statusError:
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case AppConstants.statusUploaded:
        return 'Terdunggah';
      case AppConstants.statusError:
        return 'Gagal';
      default:
        return 'Menunggu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isPending ? 'Menunggu' : 'Terdunggah';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSamples,
              child: _samples.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tidak ada sampel $title',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _samples.length,
                      itemBuilder: (context, index) {
                        final s = _samples[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              if (s.id != null) {
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ReceivedSampleDetailScreen(
                                              sampleId: s.id!,
                                            ),
                                      ),
                                    )
                                    .then((_) => _loadSamples());
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: File(s.fotoPath).existsSync()
                                        ? Image.file(
                                            File(s.fotoPath),
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 56,
                                            height: 56,
                                            color: AppColors.background,
                                            child: Icon(
                                              Icons.image_not_supported,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.kode,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${s.tanggalTerima} ${s.waktuTerima}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _statusColor(
                                              s.status,
                                            ).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            _statusLabel(s.status),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: _statusColor(s.status),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
