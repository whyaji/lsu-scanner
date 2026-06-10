import 'package:flutter/material.dart';

import '../../../core/database/models/data_sampel_pupuk.dart';

enum DataSampelPupukProgress {
  semua,
  gudangEstate,
  dikirimEstate,
  dikirimLab,
  registrasiLab,
  sertifikatLabRilis,
  sertifikatTerkirim,
}

class DataSampelPupukProgressTab {
  const DataSampelPupukProgressTab({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });

  final DataSampelPupukProgress id;
  final String label;
  final IconData icon;
  final Color color;
}

const dataSampelPupukProgressTabs = <DataSampelPupukProgressTab>[
  DataSampelPupukProgressTab(
    id: DataSampelPupukProgress.semua,
    label: 'Semua',
    icon: Icons.grid_view_rounded,
    color: Colors.blueGrey,
  ),
  DataSampelPupukProgressTab(
    id: DataSampelPupukProgress.gudangEstate,
    label: 'Gudang Estate',
    icon: Icons.warehouse_outlined,
    color: Colors.grey,
  ),
  DataSampelPupukProgressTab(
    id: DataSampelPupukProgress.dikirimEstate,
    label: 'Dikirim Estate',
    icon: Icons.local_shipping_outlined,
    color: Colors.blue,
  ),
  DataSampelPupukProgressTab(
    id: DataSampelPupukProgress.dikirimLab,
    label: 'Dikirim Lab',
    icon: Icons.science_outlined,
    color: Colors.cyan,
  ),
  DataSampelPupukProgressTab(
    id: DataSampelPupukProgress.registrasiLab,
    label: 'Registrasi Lab',
    icon: Icons.fact_check_outlined,
    color: Colors.purple,
  ),
  DataSampelPupukProgressTab(
    id: DataSampelPupukProgress.sertifikatLabRilis,
    label: 'Sertifikat Lab Rilis',
    icon: Icons.workspace_premium_outlined,
    color: Colors.orange,
  ),
  DataSampelPupukProgressTab(
    id: DataSampelPupukProgress.sertifikatTerkirim,
    label: 'Sertifikat Terkirim',
    icon: Icons.check_circle_outline,
    color: Colors.green,
  ),
];

bool _isEmptyDate(String? value) => value == null || value.trim().isEmpty;

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

DataSampelPupukProgress resolveDataSampelPupukProgress(DataSampelPupuk item) {
  if (_isEmptyDate(item.tanggalKirimDariEstate)) {
    return DataSampelPupukProgress.gudangEstate;
  }
  if (_isEmptyDate(item.tanggalKirimLab)) {
    return DataSampelPupukProgress.dikirimEstate;
  }
  if (_isEmptyDate(item.tanggalRegistrasiLab)) {
    return DataSampelPupukProgress.dikirimLab;
  }
  if (!_hasText(item.noSertifikat)) {
    return DataSampelPupukProgress.registrasiLab;
  }
  if (_isEmptyDate(item.tanggalKirimSertifikatEstate)) {
    return DataSampelPupukProgress.sertifikatLabRilis;
  }
  return DataSampelPupukProgress.sertifikatTerkirim;
}

DataSampelPupukProgressTab tabForProgress(DataSampelPupukProgress progress) {
  return dataSampelPupukProgressTabs.firstWhere((t) => t.id == progress);
}

String labelForProgress(DataSampelPupukProgress progress) {
  return tabForProgress(progress).label;
}

bool matchesProgressFilter(
  DataSampelPupuk item,
  DataSampelPupukProgress filter,
) {
  if (filter == DataSampelPupukProgress.semua) return true;
  return resolveDataSampelPupukProgress(item) == filter;
}

Map<DataSampelPupukProgress, int> countByProgress(List<DataSampelPupuk> items) {
  final counts = {for (final tab in dataSampelPupukProgressTabs) tab.id: 0};
  counts[DataSampelPupukProgress.semua] = items.length;
  for (final item in items) {
    final progress = resolveDataSampelPupukProgress(item);
    counts[progress] = (counts[progress] ?? 0) + 1;
  }
  return counts;
}

const dataSampelPupukListPageSize = 20;

String? progressToApiParam(DataSampelPupukProgress progress) {
  switch (progress) {
    case DataSampelPupukProgress.semua:
      return null;
    case DataSampelPupukProgress.gudangEstate:
      return 'gudang-estate';
    case DataSampelPupukProgress.dikirimEstate:
      return 'dikirim-estate';
    case DataSampelPupukProgress.dikirimLab:
      return 'dikirim-lab';
    case DataSampelPupukProgress.registrasiLab:
      return 'registrasi-lab';
    case DataSampelPupukProgress.sertifikatLabRilis:
      return 'sertifikat-lab-rilis';
    case DataSampelPupukProgress.sertifikatTerkirim:
      return 'sertifikat-terkirim';
  }
}

DataSampelPupukProgress? progressFromApiParam(String? value) {
  switch (value) {
    case 'gudang-estate':
      return DataSampelPupukProgress.gudangEstate;
    case 'dikirim-estate':
      return DataSampelPupukProgress.dikirimEstate;
    case 'dikirim-lab':
      return DataSampelPupukProgress.dikirimLab;
    case 'registrasi-lab':
      return DataSampelPupukProgress.registrasiLab;
    case 'sertifikat-lab-rilis':
      return DataSampelPupukProgress.sertifikatLabRilis;
    case 'sertifikat-terkirim':
      return DataSampelPupukProgress.sertifikatTerkirim;
    default:
      return null;
  }
}

Map<DataSampelPupukProgress, int> emptyProgressCounts() {
  return {for (final tab in dataSampelPupukProgressTabs) tab.id: 0};
}

Map<DataSampelPupukProgress, int> parseProgressCountsFromApi(
  Map<String, dynamic> json,
) {
  return {
    DataSampelPupukProgress.semua: (json['semua'] as num?)?.toInt() ?? 0,
    DataSampelPupukProgress.gudangEstate:
        (json['gudang-estate'] as num?)?.toInt() ?? 0,
    DataSampelPupukProgress.dikirimEstate:
        (json['dikirim-estate'] as num?)?.toInt() ?? 0,
    DataSampelPupukProgress.dikirimLab:
        (json['dikirim-lab'] as num?)?.toInt() ?? 0,
    DataSampelPupukProgress.registrasiLab:
        (json['registrasi-lab'] as num?)?.toInt() ?? 0,
    DataSampelPupukProgress.sertifikatLabRilis:
        (json['sertifikat-lab-rilis'] as num?)?.toInt() ?? 0,
    DataSampelPupukProgress.sertifikatTerkirim:
        (json['sertifikat-terkirim'] as num?)?.toInt() ?? 0,
  };
}

bool matchesSearchQuery(DataSampelPupuk item, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  final haystack = [
    item.kodeSampel,
    item.estate,
    item.supplier,
    item.noPo,
    item.noSurat,
    item.noSertifikat,
    item.jenisPupuk,
    item.merek,
  ].whereType<String>().join(' ').toLowerCase();
  return haystack.contains(q);
}
