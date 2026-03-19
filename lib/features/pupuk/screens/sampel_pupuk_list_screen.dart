import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../core/database/models/terima_dari_gudang.dart';
import '../../../core/database/models/kirim_dari_estate.dart';
import '../../../core/database/models/terima_dari_estate.dart';
import '../../../core/database/models/kirim_lab.dart';
import '../../../core/database/models/kirim_sertifikat_estate.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_loading_state.dart';
import '../constants/pupuk_activity_types.dart';
import 'sampel_pupuk_activity_detail_screen.dart';

/// Unified list entry for any Sampel Pupuk activity.
class _PupukListEntry {
  final String activityType;
  final int id;
  final String kodeSampel;
  final String dateText;
  final String status;
  final String? errorMessage;
  final String createdAt;
  final String? fotoPath;

  /// e.g. No. Surat for Kirim Lab
  final String? extraSubtitle;

  _PupukListEntry({
    required this.activityType,
    required this.id,
    required this.kodeSampel,
    required this.dateText,
    required this.status,
    this.errorMessage,
    required this.createdAt,
    this.fotoPath,
    this.extraSubtitle,
  });
}

class SampelPupukListScreen extends StatefulWidget {
  final bool isPending;

  const SampelPupukListScreen({super.key, required this.isPending});

  @override
  State<SampelPupukListScreen> createState() => _SampelPupukListScreenState();
}

class _SampelPupukListScreenState extends State<SampelPupukListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<_PupukListEntry> _entries = [];
  bool _loading = true;

  Future<void> _loadEntries() async {
    setState(() => _loading = true);
    final List<_PupukListEntry> combined = [];

    if (widget.isPending) {
      final t1 = await _dbHelper.getPendingTerimaDariGudang();
      final t2 = await _dbHelper.getPendingKirimDariEstate();
      final t3 = await _dbHelper.getPendingTerimaDariEstate();
      final t4 = await _dbHelper.getPendingKirimLab();
      final t5 = await _dbHelper.getPendingKirimSertifikatEstate();
      _addTerimaGudang(combined, t1);
      _addKirimEstate(combined, t2);
      _addTerimaEstate(combined, t3);
      _addKirimLab(combined, t4);
      _addKirimSertifikat(combined, t5);
    } else {
      final t1 = await _dbHelper.getAllTerimaDariGudang();
      final t2 = await _dbHelper.getAllKirimDariEstate();
      final t3 = await _dbHelper.getAllTerimaDariEstate();
      final t4 = await _dbHelper.getAllKirimLab();
      final t5 = await _dbHelper.getAllKirimSertifikatEstate();
      for (final row in t1) {
        if (row.status == AppConstants.statusUploaded && row.id != null) {
          combined.add(_entryFromTerimaGudang(row));
        }
      }
      for (final row in t2) {
        if (row.status == AppConstants.statusUploaded && row.id != null) {
          combined.add(_entryFromKirimEstate(row));
        }
      }
      for (final row in t3) {
        if (row.status == AppConstants.statusUploaded && row.id != null) {
          combined.add(_entryFromTerimaEstate(row));
        }
      }
      for (final row in t4) {
        if (row.status == AppConstants.statusUploaded && row.id != null) {
          combined.add(_entryFromKirimLab(row));
        }
      }
      for (final row in t5) {
        if (row.status == AppConstants.statusUploaded && row.id != null) {
          combined.add(_entryFromKirimSertifikat(row));
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

  void _addTerimaGudang(
    List<_PupukListEntry> out,
    List<TerimaDariGudang> list,
  ) {
    for (final row in list) {
      if (row.id != null) out.add(_entryFromTerimaGudang(row));
    }
  }

  _PupukListEntry _entryFromTerimaGudang(TerimaDariGudang row) {
    return _PupukListEntry(
      activityType: kTerimaDariGudang,
      id: row.id!,
      kodeSampel: row.kodeSampel,
      dateText: row.tanggalTerimaDariGudang,
      status: row.status,
      errorMessage: row.errorMessage,
      createdAt: row.createdAt,
      fotoPath: row.fotoTerimaDariGudang,
    );
  }

  void _addKirimEstate(List<_PupukListEntry> out, List<KirimDariEstate> list) {
    for (final row in list) {
      if (row.id != null) out.add(_entryFromKirimEstate(row));
    }
  }

  _PupukListEntry _entryFromKirimEstate(KirimDariEstate row) {
    return _PupukListEntry(
      activityType: kKirimDariEstate,
      id: row.id!,
      kodeSampel: row.kodeSampel,
      dateText: row.tanggalKirimDariEstate,
      status: row.status,
      errorMessage: row.errorMessage,
      createdAt: row.createdAt,
      fotoPath: row.fotoKirimDariEstate,
    );
  }

  void _addTerimaEstate(
    List<_PupukListEntry> out,
    List<TerimaDariEstate> list,
  ) {
    for (final row in list) {
      if (row.id != null) out.add(_entryFromTerimaEstate(row));
    }
  }

  _PupukListEntry _entryFromTerimaEstate(TerimaDariEstate row) {
    return _PupukListEntry(
      activityType: kTerimaDariEstate,
      id: row.id!,
      kodeSampel: row.kodeSampel,
      dateText: row.tanggalTerimaDariEstate,
      status: row.status,
      errorMessage: row.errorMessage,
      createdAt: row.createdAt,
      fotoPath: row.fotoTerimaDariEstate,
    );
  }

  void _addKirimLab(List<_PupukListEntry> out, List<KirimLab> list) {
    for (final row in list) {
      if (row.id != null) out.add(_entryFromKirimLab(row));
    }
  }

  _PupukListEntry _entryFromKirimLab(KirimLab row) {
    final ns = row.noSurat;
    return _PupukListEntry(
      activityType: kKirimLab,
      id: row.id!,
      kodeSampel: row.kodeSampel,
      dateText: row.tanggalKirimLab,
      status: row.status,
      errorMessage: row.errorMessage,
      createdAt: row.createdAt,
      fotoPath: row.fotoKirimLab,
      extraSubtitle: ns != null && ns.isNotEmpty ? 'No. Surat: $ns' : null,
    );
  }

  void _addKirimSertifikat(
    List<_PupukListEntry> out,
    List<KirimSertifikatEstate> list,
  ) {
    for (final row in list) {
      if (row.id != null) out.add(_entryFromKirimSertifikat(row));
    }
  }

  _PupukListEntry _entryFromKirimSertifikat(KirimSertifikatEstate row) {
    return _PupukListEntry(
      activityType: kKirimSertifikatEstate,
      id: row.id!,
      kodeSampel: row.kodeSampel,
      dateText: row.tanggalKirimSertifikatEstate,
      status: row.status,
      errorMessage: row.errorMessage,
      createdAt: row.createdAt,
      fotoPath: null,
      extraSubtitle: 'Rekomendasi: ${row.rekomendasi}',
    );
  }

  @override
  void initState() {
    super.initState();
    _loadEntries();
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
              onRefresh: _loadEntries,
              child: _entries.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: AppEmptyState(
                            title: 'Tidak ada data sampel pupuk $title',
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: AppSpacing.paddingScreen,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final e = _entries[index];
                        return Card(
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          SampelPupukActivityDetailScreen(
                                            activityType: e.activityType,
                                            id: e.id,
                                          ),
                                    ),
                                  )
                                  .then((_) => _loadEntries());
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: AppSpacing.paddingMd,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child:
                                        e.fotoPath != null &&
                                            e.fotoPath!.isNotEmpty &&
                                            File(e.fotoPath!).existsSync()
                                        ? Image.file(
                                            File(e.fotoPath!),
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
                                                e.kodeSampel,
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
                                                color: colorScheme
                                                    .onSurfaceVariant
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                labelForPupukActivityType(
                                                  e.activityType,
                                                ),
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        AppSpacing.gapXs,
                                        Text(
                                          app_date_utils
                                              .DateUtils.formatDateTimeFromIso(
                                            e.dateText,
                                          ),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                        if (e.extraSubtitle != null &&
                                            e.extraSubtitle!.isNotEmpty) ...[
                                          AppSpacing.gapXs,
                                          Text(
                                            e.extraSubtitle!,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                        AppSpacing.gapSm,
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _statusColor(
                                              context,
                                              e.status,
                                            ).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            _statusLabel(e.status),
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  color: _statusColor(
                                                    context,
                                                    e.status,
                                                  ),
                                                ),
                                          ),
                                        ),
                                        if (e.errorMessage != null &&
                                            e.errorMessage!.isNotEmpty) ...[
                                          AppSpacing.gapSm,
                                          Text(
                                            e.errorMessage!,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: colorScheme.error,
                                                ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
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
