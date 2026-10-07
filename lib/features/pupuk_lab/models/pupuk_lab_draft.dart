import 'package:intl/intl.dart';
import 'pupuk_lab.dart';
import 'pupuk_lab_form.dart';
import 'pupuk_lab_master.dart';
import 'pupuk_lab_sample.dart';
import 'pupuk_lab_validation.dart';

/// Wizard steps of the Terima Lab form, in order.
enum PupukLabStep {
  samples('Sampel'),
  info('Informasi'),
  contact('Pengirim'),
  parameters('Parameter'),
  review('Ringkasan');

  const PupukLabStep(this.label);

  final String label;
}

/// Step that shows the field with validation error [key].
PupukLabStep pupukLabStepOfError(String key) {
  if (key == 'samples' || key == 'noSurat') return PupukLabStep.samples;
  if (key == 'parameters' || key.startsWith('parameters.')) {
    return PupukLabStep.parameters;
  }
  const info = {
    'jenisSampelId',
    'jenisPupuk',
    'statusPengerjaan',
    'asalSampel',
    'tanggalMemo',
    'tanggalTerima',
    'estimasiKupa',
    'kemasanSampel',
    'kondisiSampel',
    'tujuan',
    'skalaPrioritas',
    'peralatan',
  };
  if (info.contains(key)) return PupukLabStep.info;
  if (key == 'fotoPaths' || key == 'catatan') return PupukLabStep.review;
  return PupukLabStep.contact;
}

/// One sample on the receipt plus what the list shows about it.
class PupukLabDraftSample {
  const PupukLabDraftSample({
    required this.sample,
    this.supplier,
    this.jenisPupuk,
    this.estate,
    this.qtyKg,
  });

  final PupukLabSample sample;
  final String? supplier;
  final String? jenisPupuk;
  final String? estate;
  final int? qtyKg;

  String get kode => sample.kodeSampel;
  bool get isManual => sample.isManual;
}

/// One row of the parameter step. [key] keeps the row's widgets stable while
/// rows are added and removed.
class PupukLabParameterDraft {
  const PupukLabParameterDraft({
    required this.key,
    this.parameterId,
    this.totalSample = 1,
    this.kodeSampel = const [],
  });

  final int key;
  final int? parameterId;
  final int totalSample;
  final List<String> kodeSampel;

  PupukLabParameterDraft copyWith({
    Object? parameterId = _keep,
    int? totalSample,
    List<String>? kodeSampel,
  }) => PupukLabParameterDraft(
    key: key,
    parameterId: identical(parameterId, _keep)
        ? this.parameterId
        : parameterId as int?,
    totalSample: totalSample ?? this.totalSample,
    kodeSampel: kodeSampel ?? this.kodeSampel,
  );
}

const Object _keep = Object();

const String _namaFormulirPrefix =
    'Kaji Ulang Permintaan,Tender dan Kontrak Sampel ';

String _date(DateTime value) => DateFormat('yyyy-MM-dd').format(value);

String? _nullIfBlank(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Everything the user is typing into a Terima Lab receipt before it is saved.
/// Text fields hold plain strings (empty means not filled); only the pickers
/// that have no empty value are nullable.
class PupukLabDraft {
  const PupukLabDraft({
    this.started = false,
    this.dirty = false,
    this.editingId,
    this.clientUuid,
    this.createdAt,
    this.samples = const [],
    this.noSurat = '',
    this.jenisSampelId,
    this.jenisPupuk = '',
    this.statusPengerjaan,
    this.asalSampel = '',
    required this.tanggalMemo,
    required this.tanggalTerima,
    this.tanggalTerimaEdited = false,
    this.estimasiKupa,
    this.kemasanSampel = '',
    this.kondisiSampel = '',
    this.tujuan = '',
    this.skalaPrioritas = '',
    this.peralatan = const [],
    this.namaPengirim = '',
    this.departemen = '',
    this.penerimaSampel = '',
    this.petugasPreperasi = '',
    this.penyelia = '',
    this.noDocument = '',
    this.noDocumentIdentitas = '',
    this.namaFormulir = '',
    this.emailTo = const [],
    this.emailCc = const [],
    this.diskon = '',
    this.konfirmasi = true,
    this.noHp = const [],
    this.parameters = const [],
    this.nextParameterKey = 1,
    this.catatan = '',
    this.fotoPaths = const [],
  });

  /// Placeholder before the screen has loaded the master data.
  factory PupukLabDraft.empty() {
    final now = DateTime.now();
    return PupukLabDraft(
      tanggalMemo: now,
      tanggalTerima: PupukLabForm.defaultTanggalTerima(now),
    );
  }

  /// A new receipt. With exactly one jenis in [master] it is preselected.
  factory PupukLabDraft.create({
    required PupukLabMaster master,
    required String penerima,
    DateTime? now,
    List<PupukLabDraftSample> samples = const [],
    String noSurat = '',
  }) {
    final at = now ?? DateTime.now();
    final options = master.options;
    String pick(List<String> allowed, String? preferred) {
      if (preferred != null &&
          (allowed.isEmpty || allowed.contains(preferred))) {
        return preferred;
      }
      return '';
    }

    var draft = PupukLabDraft(
      started: true,
      samples: samples,
      noSurat: noSurat,
      tanggalMemo: at,
      tanggalTerima: PupukLabForm.defaultTanggalTerima(at),
      asalSampel: pick(options.asalSampel, master.defaults.asalSampel),
      skalaPrioritas: pick(options.skalaPrioritas, 'Normal'),
      penerimaSampel: penerima,
      emailCc: master.defaults.emailCc,
      jenisPupuk: samples.isEmpty ? '' : samples.first.jenisPupuk ?? '',
    );
    if (master.jenisSampel.length == 1) {
      draft = draft.withJenis(master, master.jenisSampel.first.id);
    }
    return draft.copyWith(dirty: false);
  }

  /// The receipt being edited, with its samples already resolved for display.
  factory PupukLabDraft.fromReceipt({
    required PupukLab receipt,
    required List<PupukLabDraftSample> samples,
  }) {
    final form = receipt.form;
    final memo = DateTime.tryParse(form.tanggalMemo) ?? DateTime.now();
    var key = 1;
    return PupukLabDraft(
      started: true,
      editingId: receipt.id,
      clientUuid: receipt.clientUuid,
      createdAt: receipt.createdAt,
      samples: samples,
      noSurat: receipt.noSurat,
      jenisSampelId: form.jenisSampelId,
      jenisPupuk: form.jenisPupuk,
      statusPengerjaan: form.statusPengerjaan,
      asalSampel: form.asalSampel,
      tanggalMemo: memo,
      tanggalTerima:
          parsePupukLabDate(form.tanggalTerima) ??
          PupukLabForm.defaultTanggalTerima(memo),
      tanggalTerimaEdited: true,
      estimasiKupa: parsePupukLabDate(form.estimasiKupa),
      kemasanSampel: form.kemasanSampel,
      kondisiSampel: form.kondisiSampel,
      tujuan: form.tujuan,
      skalaPrioritas: form.skalaPrioritas,
      peralatan: form.peralatan,
      namaPengirim: form.namaPengirim,
      departemen: form.departemen,
      penerimaSampel: form.penerimaSampel,
      petugasPreperasi: form.petugasPreperasi ?? '',
      penyelia: form.penyelia ?? '',
      noDocument: form.noDocument ?? '',
      noDocumentIdentitas: form.noDocumentIdentitas ?? '',
      namaFormulir: form.namaFormulir ?? '',
      emailTo: form.emailTo,
      emailCc: form.emailCc,
      diskon: form.diskon?.toString() ?? '',
      konfirmasi: form.konfirmasi,
      noHp: form.noHp,
      parameters: [
        for (final p in form.parameters)
          PupukLabParameterDraft(
            key: key++,
            parameterId: p.parameterId,
            totalSample: p.totalSample,
            kodeSampel: p.kodeSampel,
          ),
      ],
      nextParameterKey: key,
      catatan: form.catatan ?? '',
      fotoPaths: receipt.fotoPaths,
    );
  }

  /// False until the screen has loaded its inputs and called `start`.
  final bool started;

  /// True once the user changed anything, so leaving asks for confirmation.
  final bool dirty;
  final int? editingId;
  final String? clientUuid;
  final String? createdAt;

  final List<PupukLabDraftSample> samples;
  final String noSurat;

  final int? jenisSampelId;
  final String jenisPupuk;
  final int? statusPengerjaan;
  final String asalSampel;
  final DateTime tanggalMemo;
  final DateTime tanggalTerima;

  /// Once the user picks a receipt date, changing the memo no longer moves it.
  final bool tanggalTerimaEdited;
  final DateTime? estimasiKupa;
  final String kemasanSampel;
  final String kondisiSampel;
  final String tujuan;
  final String skalaPrioritas;
  final List<String> peralatan;

  final String namaPengirim;
  final String departemen;
  final String penerimaSampel;
  final String petugasPreperasi;
  final String penyelia;
  final String noDocument;
  final String noDocumentIdentitas;
  final String namaFormulir;
  final List<String> emailTo;
  final List<String> emailCc;

  /// Percent as typed; digits only.
  final String diskon;
  final bool konfirmasi;
  final List<String> noHp;

  final List<PupukLabParameterDraft> parameters;
  final int nextParameterKey;
  final String catatan;
  final List<String> fotoPaths;

  bool get isEditing => editingId != null;

  List<String> get kodes => [for (final s in samples) s.kode];

  int get systemSampleCount => samples.where((s) => !s.isManual).length;

  PupukLabDraft copyWith({
    bool? started,
    bool? dirty,
    List<PupukLabDraftSample>? samples,
    String? noSurat,
    Object? jenisSampelId = _keep,
    String? jenisPupuk,
    Object? statusPengerjaan = _keep,
    String? asalSampel,
    DateTime? tanggalMemo,
    DateTime? tanggalTerima,
    bool? tanggalTerimaEdited,
    Object? estimasiKupa = _keep,
    String? kemasanSampel,
    String? kondisiSampel,
    String? tujuan,
    String? skalaPrioritas,
    List<String>? peralatan,
    String? namaPengirim,
    String? departemen,
    String? penerimaSampel,
    String? petugasPreperasi,
    String? penyelia,
    String? noDocument,
    String? noDocumentIdentitas,
    String? namaFormulir,
    List<String>? emailTo,
    List<String>? emailCc,
    String? diskon,
    bool? konfirmasi,
    List<String>? noHp,
    List<PupukLabParameterDraft>? parameters,
    int? nextParameterKey,
    String? catatan,
    List<String>? fotoPaths,
  }) {
    return PupukLabDraft(
      started: started ?? this.started,
      dirty: dirty ?? true,
      editingId: editingId,
      clientUuid: clientUuid,
      createdAt: createdAt,
      samples: samples ?? this.samples,
      noSurat: noSurat ?? this.noSurat,
      jenisSampelId: identical(jenisSampelId, _keep)
          ? this.jenisSampelId
          : jenisSampelId as int?,
      jenisPupuk: jenisPupuk ?? this.jenisPupuk,
      statusPengerjaan: identical(statusPengerjaan, _keep)
          ? this.statusPengerjaan
          : statusPengerjaan as int?,
      asalSampel: asalSampel ?? this.asalSampel,
      tanggalMemo: tanggalMemo ?? this.tanggalMemo,
      tanggalTerima: tanggalTerima ?? this.tanggalTerima,
      tanggalTerimaEdited: tanggalTerimaEdited ?? this.tanggalTerimaEdited,
      estimasiKupa: identical(estimasiKupa, _keep)
          ? this.estimasiKupa
          : estimasiKupa as DateTime?,
      kemasanSampel: kemasanSampel ?? this.kemasanSampel,
      kondisiSampel: kondisiSampel ?? this.kondisiSampel,
      tujuan: tujuan ?? this.tujuan,
      skalaPrioritas: skalaPrioritas ?? this.skalaPrioritas,
      peralatan: peralatan ?? this.peralatan,
      namaPengirim: namaPengirim ?? this.namaPengirim,
      departemen: departemen ?? this.departemen,
      penerimaSampel: penerimaSampel ?? this.penerimaSampel,
      petugasPreperasi: petugasPreperasi ?? this.petugasPreperasi,
      penyelia: penyelia ?? this.penyelia,
      noDocument: noDocument ?? this.noDocument,
      noDocumentIdentitas: noDocumentIdentitas ?? this.noDocumentIdentitas,
      namaFormulir: namaFormulir ?? this.namaFormulir,
      emailTo: emailTo ?? this.emailTo,
      emailCc: emailCc ?? this.emailCc,
      diskon: diskon ?? this.diskon,
      konfirmasi: konfirmasi ?? this.konfirmasi,
      noHp: noHp ?? this.noHp,
      parameters: parameters ?? this.parameters,
      nextParameterKey: nextParameterKey ?? this.nextParameterKey,
      catatan: catatan ?? this.catatan,
      fotoPaths: fotoPaths ?? this.fotoPaths,
    );
  }

  /// Picks the jenis komoditas: its Status Pengerjaan list replaces the old
  /// one (a single choice is preselected), parameters from the old jenis are
  /// dropped, and the document and staff fields take the jenis defaults.
  PupukLabDraft withJenis(PupukLabMaster master, int id) {
    final jenis = master.jenisById(id);
    if (jenis == null) return this;
    final statuses = master.progressOptionsFor(id);
    return copyWith(
      jenisSampelId: id,
      statusPengerjaan: statuses.length == 1 ? statuses.first.id : null,
      parameters: const [],
      petugasPreperasi: jenis.petugasPreperasi ?? '',
      penyelia: jenis.penyelia ?? '',
      noDocument: jenis.nomorDokumenKupa ?? '',
      noDocumentIdentitas: jenis.nomorDokumenIdentitas ?? '',
      namaFormulir: '$_namaFormulirPrefix${jenis.nama}',
    );
  }

  List<PupukLabSample> get _plainSamples => [for (final s in samples) s.sample];

  /// The form as the upload sends it. Unset pickers become placeholders that
  /// [validate] turns into "Pilih ..." messages.
  PupukLabForm toForm() {
    final estimasi = estimasiKupa;
    return PupukLabForm(
      jenisSampelId: jenisSampelId ?? 0,
      jenisPupuk: jenisPupuk.trim(),
      statusPengerjaan: statusPengerjaan ?? 0,
      asalSampel: asalSampel,
      tanggalMemo: tanggalMemo.toIso8601String(),
      tanggalTerima: _date(tanggalTerima),
      estimasiKupa: estimasi == null ? '' : _date(estimasi),
      namaPengirim: namaPengirim.trim(),
      departemen: departemen.trim(),
      kemasanSampel: kemasanSampel.trim(),
      kondisiSampel: kondisiSampel,
      tujuan: tujuan.trim(),
      skalaPrioritas: skalaPrioritas,
      peralatan: peralatan,
      penerimaSampel: penerimaSampel.trim(),
      petugasPreperasi: _nullIfBlank(petugasPreperasi),
      penyelia: _nullIfBlank(penyelia),
      noDocument: _nullIfBlank(noDocument),
      noDocumentIdentitas: _nullIfBlank(noDocumentIdentitas),
      namaFormulir: _nullIfBlank(namaFormulir),
      emailTo: emailTo,
      emailCc: emailCc,
      diskon: int.tryParse(diskon.trim()),
      konfirmasi: konfirmasi,
      noHp: noHp,
      parameters: [
        for (final p in parameters)
          PupukLabParameterEntry(
            parameterId: p.parameterId ?? 0,
            totalSample: p.totalSample,
            kodeSampel: p.kodeSampel,
          ),
      ],
      catatan: _nullIfBlank(catatan),
    );
  }

  /// All rule violations, keyed by field. Messages for pickers the user has
  /// not touched say what to do ("Pilih ...") instead of "tidak valid".
  PupukLabValidation validate(PupukLabMaster? master) {
    final errors = Map<String, String>.of(
      toForm()
          .validate(
            samples: _plainSamples,
            noSurat: noSurat.trim(),
            fotoCount: fotoPaths.length,
            master: master,
          )
          .errors,
    );

    void missing(String field, bool isMissing, String message) {
      if (isMissing) errors[field] = message;
    }

    missing('jenisSampelId', jenisSampelId == null, 'Pilih jenis komoditas.');
    missing(
      'statusPengerjaan',
      statusPengerjaan == null,
      'Pilih status pengerjaan.',
    );
    missing('asalSampel', asalSampel.isEmpty, 'Pilih asal sampel.');
    missing('kondisiSampel', kondisiSampel.isEmpty, 'Pilih kondisi sampel.');
    missing('skalaPrioritas', skalaPrioritas.isEmpty, 'Pilih skala prioritas.');
    missing('estimasiKupa', estimasiKupa == null, 'Isi estimasi KUPA.');
    missing('noSurat', noSurat.trim().isEmpty, 'No. surat wajib diisi.');
    missing(
      'jenisPupuk',
      jenisPupuk.trim().isEmpty,
      'Jenis pupuk wajib diisi.',
    );
    missing(
      'kemasanSampel',
      kemasanSampel.trim().isEmpty,
      'Kemasan sampel wajib diisi.',
    );
    missing('tujuan', tujuan.trim().isEmpty, 'Tujuan wajib diisi.');
    missing(
      'namaPengirim',
      namaPengirim.trim().isEmpty,
      'Nama pengirim wajib diisi.',
    );
    missing('departemen', departemen.trim().isEmpty, 'Departemen wajib diisi.');
    missing(
      'penerimaSampel',
      penerimaSampel.trim().isEmpty,
      'Penerima sampel wajib diisi.',
    );
    for (var i = 0; i < parameters.length; i++) {
      missing(
        'parameters.$i.parameterId',
        parameters[i].parameterId == null,
        'Pilih parameter.',
      );
    }
    return PupukLabValidation(errors);
  }

  /// Errors of one step only.
  Map<String, String> errorsOf(PupukLabStep step, PupukLabMaster? master) => {
    for (final entry in validate(master).errors.entries)
      if (pupukLabStepOfError(entry.key) == step) entry.key: entry.value,
  };

  /// The receipt row for saving. Call after [validate] passes. A new receipt
  /// gets [newClientUuid]; an edited one keeps its own uuid and creation time.
  PupukLab toReceipt({required String newClientUuid, DateTime? now}) {
    return PupukLab(
      id: editingId,
      clientUuid: clientUuid ?? newClientUuid,
      noSurat: noSurat.trim(),
      samples: _plainSamples,
      form: toForm(),
      fotoPaths: fotoPaths,
      createdAt: createdAt ?? (now ?? DateTime.now()).toIso8601String(),
    );
  }
}
