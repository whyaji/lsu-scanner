import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_helper.dart';
import 'received_sample_detail_screen.dart';
import 'completed_sample_detail_screen.dart';

/// Unified list entry for received or completed sample.
class _SampleListEntry {
  final bool isCompleted;
  final int id;
  final String kode;
  final String dateTimeText;
  final String status;
  final String fotoPath;
  final String createdAt;

  _SampleListEntry({
    required this.isCompleted,
    required this.id,
    required this.kode,
    required this.dateTimeText,
    required this.status,
    required this.fotoPath,
    required this.createdAt,
  });
}

class ReceivedListScreen extends StatefulWidget {
  final bool isPending;

  const ReceivedListScreen({super.key, required this.isPending});

  @override
  State<ReceivedListScreen> createState() => _ReceivedListScreenState();
}

class _ReceivedListScreenState extends State<ReceivedListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<_SampleListEntry> _entries = [];
  bool _loading = true;

  Future<void> _loadSamples() async {
    setState(() => _loading = true);
    final List<_SampleListEntry> combined = [];
    if (widget.isPending) {
      final received = await _dbHelper.getPendingUploads();
      final completed = await _dbHelper.getPendingCompleteUploads();
      for (final s in received) {
        if (s.id != null) {
          combined.add(
            _SampleListEntry(
              isCompleted: false,
              id: s.id!,
              kode: s.kode,
              dateTimeText: '${s.tanggalTerima} ${s.waktuTerima}',
              status: s.status,
              fotoPath: s.fotoPath,
              createdAt: s.createdAt,
            ),
          );
        }
      }
      for (final s in completed) {
        if (s.id != null) {
          combined.add(
            _SampleListEntry(
              isCompleted: true,
              id: s.id!,
              kode: s.kode,
              dateTimeText: '${s.tanggalSelesai} ${s.waktuSelesai}',
              status: s.status,
              fotoPath: s.fotoPath,
              createdAt: s.createdAt,
            ),
          );
        }
      }
    } else {
      final received = await _dbHelper.getUploadedSamples();
      final allCompleted = await _dbHelper.getAllCompletedSamples();
      final completed = allCompleted
          .where((s) => s.status == AppConstants.statusUploaded)
          .toList();
      for (final s in received) {
        if (s.id != null) {
          combined.add(
            _SampleListEntry(
              isCompleted: false,
              id: s.id!,
              kode: s.kode,
              dateTimeText: '${s.tanggalTerima} ${s.waktuTerima}',
              status: s.status,
              fotoPath: s.fotoPath,
              createdAt: s.createdAt,
            ),
          );
        }
      }
      for (final s in completed) {
        if (s.id != null) {
          combined.add(
            _SampleListEntry(
              isCompleted: true,
              id: s.id!,
              kode: s.kode,
              dateTimeText: '${s.tanggalSelesai} ${s.waktuSelesai}',
              status: s.status,
              fotoPath: s.fotoPath,
              createdAt: s.createdAt,
            ),
          );
        }
      }
    }
    combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (mounted) {
      setState(() {
        _entries = combined;
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
        return 'Terunggah';
      case AppConstants.statusError:
        return 'Gagal';
      default:
        return 'Menunggu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isPending ? 'Menunggu' : 'Terunggah';

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
              child: _entries.isEmpty
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
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final s = _entries[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              if (s.isCompleted) {
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CompletedSampleDetailScreen(
                                              sampleId: s.id,
                                            ),
                                      ),
                                    )
                                    .then((_) => _loadSamples());
                              } else {
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ReceivedSampleDetailScreen(
                                              sampleId: s.id,
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
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                s.kode,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    (s.isCompleted
                                                            ? AppColors.primary
                                                            : AppColors
                                                                  .textSecondary)
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                s.isCompleted
                                                    ? 'Selesai'
                                                    : 'Diterima',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: s.isCompleted
                                                      ? AppColors.primary
                                                      : AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          s.dateTimeText,
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
