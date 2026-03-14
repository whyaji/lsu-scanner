import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_loading_state.dart';
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

  Color _statusColor(BuildContext context, String status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case AppConstants.statusUploaded:
        return colorScheme.primary;
      case AppConstants.statusError:
        return colorScheme.error;
      default:
        return colorScheme.tertiary;
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const AppLoadingState(itemCount: 8)
          : RefreshIndicator(
              onRefresh: _loadSamples,
              child: _entries.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: AppEmptyState(
                            title: 'Tidak ada sampel $title',
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: AppSpacing.paddingScreen,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final s = _entries[index];
                        return Card(
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
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: AppSpacing.paddingMd,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
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
                                            color: colorScheme
                                                .surfaceContainerHighest,
                                            child: Icon(
                                              Icons.image_not_supported,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                  ),
                                  AppSpacing.gapMd,
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
                                                style: theme
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                            ? colorScheme
                                                                  .primary
                                                            : colorScheme
                                                                  .onSurfaceVariant)
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
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: s.isCompleted
                                                          ? colorScheme.primary
                                                          : colorScheme
                                                                .onSurfaceVariant,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        AppSpacing.gapXs,
                                        Text(
                                          s.dateTimeText,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                        AppSpacing.gapSm,
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _statusColor(
                                              context,
                                              s.status,
                                            ).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            _statusLabel(s.status),
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  color: _statusColor(
                                                    context,
                                                    s.status,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: colorScheme.onSurfaceVariant,
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
