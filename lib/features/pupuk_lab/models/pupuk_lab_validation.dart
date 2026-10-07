import 'pupuk_lab_form.dart';
import 'pupuk_lab_master.dart';
import 'pupuk_lab_sample.dart';

/// Limits of the SmartLab `track-sampel` endpoint. Text lengths follow the
/// `track_sampel` column widths: SmartLab answers a longer value with a
/// permanent 422, so the form has to stop it before it is saved.
abstract final class PupukLabLimits {
  static const int maxSamples = 1000;
  static const int maxFotos = 5;
  static const int maxTotalSample = 1000;
  static const int maxDiskon = 99;
  static const int maxEmailToJoined = 256;

  static const int noSuratMin = 2;
  static const int noSuratMax = 100;
  static const int namaPengirimMin = 2;
  static const int namaPengirimMax = 50;
  static const int departemenMin = 1;
  static const int departemenMax = 50;
  static const int kemasanSampelMin = 2;
  static const int kemasanSampelMax = 20;
  static const int tujuanMin = 2;
  static const int tujuanMax = 100;
  static const int penerimaSampelMin = 2;
  static const int penerimaSampelMax = 50;
  static const int jenisPupukMin = 1;
  static const int jenisPupukMax = 100;
  static const int petugasPreperasiMax = 500;
  static const int penyeliaMax = 100;
  static const int noDocumentMax = 255;
  static const int namaFormulirMax = 255;
}

final RegExp _kodeForbidden = RegExp(r'''['"\\$\u0000-\u001F\u007F]''');

/// Same cleanup SmartLab applies to a sample code (`sanitizeKodeSampel`):
/// quotes, backslashes, `$` and control characters are dropped. Codes must
/// stay unique after this step.
String sanitizeKodeSampel(String kode) => kode.replaceAll(_kodeForbidden, '');

/// Field errors keyed by form field. Parameter rows use
/// `parameters.<index>.<field>`; the list itself uses `parameters`.
class PupukLabValidation {
  const PupukLabValidation(this.errors);

  final Map<String, String> errors;

  bool get isValid => errors.isEmpty;

  String? operator [](String field) => errors[field];
}

final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final RegExp _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

bool isValidPupukLabEmail(String value) => _emailPattern.hasMatch(value.trim());

/// Parses `yyyy-MM-dd` strictly; returns null for anything else (including
/// dates the calendar rolls over such as 2026-02-30).
DateTime? parsePupukLabDate(String value) {
  final trimmed = value.trim();
  if (!_datePattern.hasMatch(trimmed)) return null;
  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) return null;
  final roundTrip =
      '${parsed.year.toString().padLeft(4, '0')}-'
      '${parsed.month.toString().padLeft(2, '0')}-'
      '${parsed.day.toString().padLeft(2, '0')}';
  return roundTrip == trimmed ? parsed : null;
}

PupukLabValidation validatePupukLabSamples(List<PupukLabSample> samples) {
  final errors = <String, String>{};
  if (samples.isEmpty) {
    errors['samples'] = 'Tambahkan minimal 1 sampel.';
  } else if (samples.length > PupukLabLimits.maxSamples) {
    errors['samples'] =
        'Maksimal ${PupukLabLimits.maxSamples} sampel per penerimaan.';
  } else {
    final seen = <String>{};
    for (final sample in samples) {
      final kode = sanitizeKodeSampel(sample.kodeSampel.trim());
      if (kode.isEmpty) {
        errors['samples'] = 'Kode sampel tidak boleh kosong.';
        break;
      }
      if (!seen.add(kode)) {
        errors['samples'] = 'Kode sampel $kode terdaftar lebih dari sekali.';
        break;
      }
      if (!sample.isManual && sample.dataSampelPupukId == null) {
        errors['samples'] = 'Sampel $kode belum terhubung ke data sampel.';
        break;
      }
    }
  }
  return PupukLabValidation(errors);
}

/// [fotoCount] is the number of photos attached to the receipt.
PupukLabValidation validatePupukLabForm(
  PupukLabForm form, {
  required List<PupukLabSample> samples,
  required String noSurat,
  int fotoCount = 0,
  PupukLabMaster? master,
}) {
  final errors = <String, String>{}
    ..addAll(validatePupukLabSamples(samples).errors);

  void text(
    String field,
    String label,
    String? value, {
    required int min,
    required int max,
  }) {
    final length = (value ?? '').trim().length;
    if (length == 0 && min == 0) return;
    if (length < min) {
      errors[field] = min == 1
          ? '$label wajib diisi.'
          : '$label minimal $min karakter.';
    } else if (length > max) {
      errors[field] = '$label maksimal $max karakter.';
    }
  }

  text(
    'noSurat',
    'No. surat',
    noSurat,
    min: PupukLabLimits.noSuratMin,
    max: PupukLabLimits.noSuratMax,
  );
  text(
    'namaPengirim',
    'Nama pengirim',
    form.namaPengirim,
    min: PupukLabLimits.namaPengirimMin,
    max: PupukLabLimits.namaPengirimMax,
  );
  text(
    'departemen',
    'Departemen',
    form.departemen,
    min: PupukLabLimits.departemenMin,
    max: PupukLabLimits.departemenMax,
  );
  text(
    'kemasanSampel',
    'Kemasan sampel',
    form.kemasanSampel,
    min: PupukLabLimits.kemasanSampelMin,
    max: PupukLabLimits.kemasanSampelMax,
  );
  text(
    'tujuan',
    'Tujuan',
    form.tujuan,
    min: PupukLabLimits.tujuanMin,
    max: PupukLabLimits.tujuanMax,
  );
  text(
    'penerimaSampel',
    'Penerima sampel',
    form.penerimaSampel,
    min: PupukLabLimits.penerimaSampelMin,
    max: PupukLabLimits.penerimaSampelMax,
  );
  text(
    'jenisPupuk',
    'Jenis pupuk',
    form.jenisPupuk,
    min: PupukLabLimits.jenisPupukMin,
    max: PupukLabLimits.jenisPupukMax,
  );
  text(
    'petugasPreperasi',
    'Petugas preparasi',
    form.petugasPreperasi,
    min: 0,
    max: PupukLabLimits.petugasPreperasiMax,
  );
  text(
    'penyelia',
    'Penyelia',
    form.penyelia,
    min: 0,
    max: PupukLabLimits.penyeliaMax,
  );
  text(
    'noDocument',
    'No. dokumen',
    form.noDocument,
    min: 0,
    max: PupukLabLimits.noDocumentMax,
  );
  text(
    'noDocumentIdentitas',
    'No. dokumen identitas',
    form.noDocumentIdentitas,
    min: 0,
    max: PupukLabLimits.noDocumentMax,
  );
  text(
    'namaFormulir',
    'Nama formulir',
    form.namaFormulir,
    min: 0,
    max: PupukLabLimits.namaFormulirMax,
  );

  if (fotoCount == 0) {
    errors['fotoPaths'] = 'Ambil minimal 1 foto sampel.';
  } else if (fotoCount > PupukLabLimits.maxFotos) {
    errors['fotoPaths'] = 'Maksimal ${PupukLabLimits.maxFotos} foto.';
  }

  _validateDates(form, errors);
  _validateContacts(form, errors);

  final diskon = form.diskon;
  if (diskon != null && (diskon < 0 || diskon > PupukLabLimits.maxDiskon)) {
    errors['diskon'] = 'Diskon harus antara 0 dan ${PupukLabLimits.maxDiskon}.';
  }

  final sampleKodes = {
    for (final s in samples) sanitizeKodeSampel(s.kodeSampel.trim()),
  };
  _validateParameters(form, sampleKodes, master, errors);

  if (master != null) _validateAgainstMaster(form, master, errors);

  return PupukLabValidation(errors);
}

void _validateDates(PupukLabForm form, Map<String, String> errors) {
  if (DateTime.tryParse(form.tanggalMemo) == null) {
    errors['tanggalMemo'] = 'Tanggal memo tidak valid.';
  }
  final terima = parsePupukLabDate(form.tanggalTerima);
  final estimasi = parsePupukLabDate(form.estimasiKupa);
  if (terima == null) errors['tanggalTerima'] = 'Tanggal terima tidak valid.';
  if (estimasi == null) {
    errors['estimasiKupa'] = 'Estimasi KUPA tidak valid.';
  } else if (terima != null && estimasi.isBefore(terima)) {
    errors['estimasiKupa'] =
        'Estimasi KUPA tidak boleh sebelum tanggal terima.';
  }
}

void _validateContacts(PupukLabForm form, Map<String, String> errors) {
  if (form.emailTo.isEmpty) {
    errors['emailTo'] = 'Isi minimal 1 email tujuan.';
  } else {
    final bad = form.emailTo.where((e) => !isValidPupukLabEmail(e));
    if (bad.isNotEmpty) {
      errors['emailTo'] = 'Email tidak valid: ${bad.first}.';
    } else if (form.emailTo.join(',').length >
        PupukLabLimits.maxEmailToJoined) {
      errors['emailTo'] =
          'Email tujuan terlalu panjang (maksimal '
          '${PupukLabLimits.maxEmailToJoined} karakter bila digabung).';
    }
  }
  final badCc = form.emailCc.where((e) => !isValidPupukLabEmail(e));
  if (badCc.isNotEmpty) {
    errors['emailCc'] = 'Email CC tidak valid: ${badCc.first}.';
  }
}

void _validateParameters(
  PupukLabForm form,
  Set<String> sampleKodes,
  PupukLabMaster? master,
  Map<String, String> errors,
) {
  if (form.parameters.isEmpty) {
    errors['parameters'] = 'Pilih minimal 1 parameter uji.';
    return;
  }
  final seenIds = <int>{};
  for (var i = 0; i < form.parameters.length; i++) {
    final entry = form.parameters[i];
    final key = 'parameters.$i';
    if (!seenIds.add(entry.parameterId)) {
      errors['$key.parameterId'] = 'Parameter ini sudah dipilih.';
    }
    if (entry.totalSample < 1 ||
        entry.totalSample > PupukLabLimits.maxTotalSample) {
      errors['$key.totalSample'] =
          'Jumlah harus antara 1 dan ${PupukLabLimits.maxTotalSample}.';
    }
    if (entry.kodeSampel.isEmpty) {
      errors['$key.kodeSampel'] = 'Pilih minimal 1 kode sampel.';
    } else {
      final outside = entry.kodeSampel.where((k) => !sampleKodes.contains(k));
      if (outside.isNotEmpty) {
        errors['$key.kodeSampel'] =
            'Kode ${outside.first} tidak ada di daftar sampel.';
      }
    }
    if (master != null) {
      final belongs = master
          .parametersFor(form.jenisSampelId)
          .any((p) => p.id == entry.parameterId);
      if (!belongs) {
        errors['$key.parameterId'] =
            'Parameter tidak tersedia untuk jenis komoditas ini.';
      }
    }
  }
}

void _validateAgainstMaster(
  PupukLabForm form,
  PupukLabMaster master,
  Map<String, String> errors,
) {
  final jenis = master.jenisById(form.jenisSampelId);
  if (jenis == null) {
    errors['jenisSampelId'] = 'Jenis komoditas tidak ditemukan.';
  } else if (!jenis.progressIds.contains(form.statusPengerjaan)) {
    errors['statusPengerjaan'] =
        'Status pengerjaan tidak tersedia untuk jenis komoditas ini.';
  }

  void oneOf(String field, String label, String value, List<String> allowed) {
    if (allowed.isNotEmpty && !allowed.contains(value)) {
      errors[field] = '$label tidak valid.';
    }
  }

  oneOf(
    'asalSampel',
    'Asal sampel',
    form.asalSampel,
    master.options.asalSampel,
  );
  oneOf(
    'kondisiSampel',
    'Kondisi sampel',
    form.kondisiSampel,
    master.options.kondisiSampel,
  );
  oneOf(
    'skalaPrioritas',
    'Skala prioritas',
    form.skalaPrioritas,
    master.options.skalaPrioritas,
  );
  final badPeralatan = form.peralatan.where(
    (p) => !master.options.peralatan.contains(p),
  );
  if (master.options.peralatan.isNotEmpty && badPeralatan.isNotEmpty) {
    errors['peralatan'] = 'Peralatan tidak valid: ${badPeralatan.first}.';
  }
}
