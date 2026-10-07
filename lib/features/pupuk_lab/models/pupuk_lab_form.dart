import 'package:flutter/foundation.dart';
import 'pupuk_lab_master.dart';
import 'pupuk_lab_sample.dart';
import 'pupuk_lab_validation.dart';

/// One parameter row of the form: which sample codes get tested and how many.
class PupukLabParameterEntry {
  const PupukLabParameterEntry({
    required this.parameterId,
    required this.totalSample,
    required this.kodeSampel,
  });

  final int parameterId;
  final int totalSample;
  final List<String> kodeSampel;

  factory PupukLabParameterEntry.fromJson(Map<String, dynamic> json) {
    return PupukLabParameterEntry(
      parameterId: (json['parameterId'] as num).toInt(),
      totalSample: (json['totalSample'] as num).toInt(),
      kodeSampel: _stringList(json['kodeSampel']),
    );
  }

  Map<String, dynamic> toJson() => {
    'parameterId': parameterId,
    'totalSample': totalSample,
    'kodeSampel': kodeSampel,
  };

  @override
  bool operator ==(Object other) =>
      other is PupukLabParameterEntry &&
      other.parameterId == parameterId &&
      other.totalSample == totalSample &&
      listEquals(other.kodeSampel, kodeSampel);

  @override
  int get hashCode =>
      Object.hash(parameterId, totalSample, Object.hashAll(kodeSampel));
}

List<String> _stringList(Object? value) =>
    value is List ? value.map((e) => e.toString()).toList() : const [];

/// Terima Lab form. JSON shape is the contract `PupukLabForm` (camelCase), so
/// the stored `form_json` is uploaded unchanged.
class PupukLabForm {
  const PupukLabForm({
    required this.jenisSampelId,
    required this.jenisPupuk,
    required this.statusPengerjaan,
    required this.asalSampel,
    required this.tanggalMemo,
    required this.tanggalTerima,
    required this.estimasiKupa,
    required this.namaPengirim,
    required this.departemen,
    required this.kemasanSampel,
    required this.kondisiSampel,
    required this.tujuan,
    required this.skalaPrioritas,
    required this.peralatan,
    required this.penerimaSampel,
    this.petugasPreperasi,
    this.penyelia,
    this.noDocument,
    this.noDocumentIdentitas,
    this.namaFormulir,
    required this.emailTo,
    required this.emailCc,
    this.diskon,
    required this.konfirmasi,
    required this.noHp,
    required this.parameters,
    this.catatan,
  });

  final int jenisSampelId;
  final String jenisPupuk;
  final int statusPengerjaan;
  final String asalSampel;

  /// ISO 8601 datetime.
  final String tanggalMemo;

  /// `yyyy-MM-dd`.
  final String tanggalTerima;

  /// `yyyy-MM-dd`.
  final String estimasiKupa;
  final String namaPengirim;
  final String departemen;
  final String kemasanSampel;
  final String kondisiSampel;
  final String tujuan;
  final String skalaPrioritas;
  final List<String> peralatan;
  final String penerimaSampel;
  final String? petugasPreperasi;
  final String? penyelia;
  final String? noDocument;
  final String? noDocumentIdentitas;
  final String? namaFormulir;
  final List<String> emailTo;
  final List<String> emailCc;

  /// Percent, 0..99.
  final int? diskon;
  final bool konfirmasi;
  final List<String> noHp;
  final List<PupukLabParameterEntry> parameters;
  final String? catatan;

  /// Web rule: the receipt date is the memo date, one day later when the memo
  /// was written at 12:00 or after.
  static DateTime defaultTanggalTerima(DateTime tanggalMemo) {
    final day = DateTime(tanggalMemo.year, tanggalMemo.month, tanggalMemo.day);
    return tanggalMemo.hour >= 12 ? day.add(const Duration(days: 1)) : day;
  }

  factory PupukLabForm.fromJson(Map<String, dynamic> json) {
    final parameters = json['parameters'];
    return PupukLabForm(
      jenisSampelId: (json['jenisSampelId'] as num).toInt(),
      jenisPupuk: json['jenisPupuk'] as String,
      statusPengerjaan: (json['statusPengerjaan'] as num).toInt(),
      asalSampel: json['asalSampel'] as String,
      tanggalMemo: json['tanggalMemo'] as String,
      tanggalTerima: json['tanggalTerima'] as String,
      estimasiKupa: json['estimasiKupa'] as String,
      namaPengirim: json['namaPengirim'] as String,
      departemen: json['departemen'] as String,
      kemasanSampel: json['kemasanSampel'] as String,
      kondisiSampel: json['kondisiSampel'] as String,
      tujuan: json['tujuan'] as String,
      skalaPrioritas: json['skalaPrioritas'] as String,
      peralatan: _stringList(json['peralatan']),
      penerimaSampel: json['penerimaSampel'] as String,
      petugasPreperasi: json['petugasPreperasi'] as String?,
      penyelia: json['penyelia'] as String?,
      noDocument: json['noDocument'] as String?,
      noDocumentIdentitas: json['noDocumentIdentitas'] as String?,
      namaFormulir: json['namaFormulir'] as String?,
      emailTo: _stringList(json['emailTo']),
      emailCc: _stringList(json['emailCc']),
      diskon: (json['diskon'] as num?)?.toInt(),
      konfirmasi: json['konfirmasi'] as bool? ?? false,
      noHp: _stringList(json['noHp']),
      parameters: parameters is List
          ? parameters
                .map(
                  (e) => PupukLabParameterEntry.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList()
          : const [],
      catatan: json['catatan'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'jenisSampelId': jenisSampelId,
    'jenisPupuk': jenisPupuk,
    'statusPengerjaan': statusPengerjaan,
    'asalSampel': asalSampel,
    'tanggalMemo': tanggalMemo,
    'tanggalTerima': tanggalTerima,
    'estimasiKupa': estimasiKupa,
    'namaPengirim': namaPengirim,
    'departemen': departemen,
    'kemasanSampel': kemasanSampel,
    'kondisiSampel': kondisiSampel,
    'tujuan': tujuan,
    'skalaPrioritas': skalaPrioritas,
    'peralatan': peralatan,
    'penerimaSampel': penerimaSampel,
    'petugasPreperasi': petugasPreperasi,
    'penyelia': penyelia,
    'noDocument': noDocument,
    'noDocumentIdentitas': noDocumentIdentitas,
    'namaFormulir': namaFormulir,
    'emailTo': emailTo,
    'emailCc': emailCc,
    'diskon': diskon,
    'konfirmasi': konfirmasi,
    'noHp': noHp,
    'parameters': parameters.map((e) => e.toJson()).toList(),
    'catatan': catatan,
  };

  /// Checks the whole receipt against the SmartLab rules. [master] enables the
  /// checks that need reference data (jenis, progress, options, parameters);
  /// without it only the structural rules run. [fotoCount] is the number of
  /// photos attached to the receipt.
  PupukLabValidation validate({
    required List<PupukLabSample> samples,
    required String noSurat,
    int fotoCount = 0,
    PupukLabMaster? master,
  }) => validatePupukLabForm(
    this,
    samples: samples,
    noSurat: noSurat,
    fotoCount: fotoCount,
    master: master,
  );
}
