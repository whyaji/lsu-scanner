import 'package:sampletrack/features/pupuk_lab/models/pupuk_lab.dart';
import 'package:sampletrack/features/pupuk_lab/models/pupuk_lab_form.dart';
import 'package:sampletrack/features/pupuk_lab/models/pupuk_lab_master.dart';
import 'package:sampletrack/features/pupuk_lab/models/pupuk_lab_sample.dart';

Map<String, dynamic> masterApiJson() => {
  'version': 'abc123',
  'fetchedAt': '2026-10-06T01:00:00.000Z',
  'jenisSampel': [
    {
      'id': 1,
      'kode': 'W',
      'nama': 'Pupuk',
      'progressIds': [3, 1, 99],
      'nomorDokumenKupa': 'KUPA-01',
      'nomorDokumenIdentitas': 'ID-01',
      'penyelia': 'Budi',
      'petugasPreperasi': 'Sari',
    },
    {
      'id': 2,
      'kode': 'T',
      'nama': 'Tanah',
      'progressIds': [2],
      'nomorDokumenKupa': null,
      'nomorDokumenIdentitas': null,
      'penyelia': null,
      'petugasPreperasi': null,
    },
  ],
  'progressPengerjaan': [
    {'id': 1, 'nama': 'Preparasi'},
    {'id': 2, 'nama': 'Analisis'},
    {'id': 3, 'nama': 'Selesai'},
  ],
  'parameterAnalisis': [
    {
      'id': 10,
      'jenisSampelId': 1,
      'namaParameter': 'Nitrogen',
      'namaUnsur': 'N',
      'harga': 12000,
      'satuan': '%',
      'metodeAnalisis': 'Kjeldahl',
    },
    {
      'id': 11,
      'jenisSampelId': 1,
      'namaParameter': 'Fosfor',
      'namaUnsur': null,
      'harga': 15000.5,
      'satuan': null,
      'metodeAnalisis': null,
    },
    {
      'id': 20,
      'jenisSampelId': 2,
      'namaParameter': 'pH',
      'namaUnsur': null,
      'harga': 5000,
      'satuan': null,
      'metodeAnalisis': null,
    },
  ],
  'departemen': ['Agronomi', 'Lab'],
  'options': {
    'asalSampel': ['Internal', 'Eksternal'],
    'kondisiSampel': ['Normal', 'Abnormal'],
    'skalaPrioritas': ['Normal', 'Tinggi'],
    'peralatan': ['Personel', 'Alat', 'Bahan'],
  },
  'defaults': {
    'emailCc': ['cs.labcbi@citraborneo.co.id'],
    'asalSampel': 'Internal',
  },
};

PupukLabMaster sampleMaster() => PupukLabMaster.fromApiJson(masterApiJson());

const List<PupukLabSample> sampleSamples = [
  PupukLabSample(dataSampelPupukId: 5, kodeSampel: 'W-001'),
  PupukLabSample(dataSampelPupukId: 6, kodeSampel: 'W-002'),
  PupukLabSample(kodeSampel: 'MANUAL-9', isManual: true),
];

PupukLabForm sampleForm({
  int jenisSampelId = 1,
  int statusPengerjaan = 3,
  String tanggalTerima = '2026-10-07',
  String estimasiKupa = '2026-10-20',
  List<PupukLabParameterEntry>? parameters,
  List<String> emailTo = const ['pelanggan@example.com'],
  int? diskon,
}) {
  return PupukLabForm(
    jenisSampelId: jenisSampelId,
    jenisPupuk: 'NPK 15-15-15',
    statusPengerjaan: statusPengerjaan,
    asalSampel: 'Internal',
    tanggalMemo: '2026-10-06T13:30:00.000',
    tanggalTerima: tanggalTerima,
    estimasiKupa: estimasiKupa,
    namaPengirim: 'Andi Saputra',
    departemen: 'Agronomi',
    kemasanSampel: 'Plastik klip',
    kondisiSampel: 'Normal',
    tujuan: 'Analisis kadar hara',
    skalaPrioritas: 'Normal',
    peralatan: const ['Personel', 'Alat'],
    penerimaSampel: 'Rina Lab',
    petugasPreperasi: 'Sari',
    penyelia: 'Budi',
    noDocument: 'KUPA-01',
    noDocumentIdentitas: 'ID-01',
    namaFormulir: 'Form Pupuk',
    emailTo: emailTo,
    emailCc: const ['cs.labcbi@citraborneo.co.id'],
    diskon: diskon,
    konfirmasi: true,
    noHp: const ['081234567890'],
    parameters:
        parameters ??
        const [
          PupukLabParameterEntry(
            parameterId: 10,
            totalSample: 3,
            kodeSampel: ['W-001', 'W-002', 'MANUAL-9'],
          ),
          PupukLabParameterEntry(
            parameterId: 11,
            totalSample: 1,
            kodeSampel: ['W-001'],
          ),
        ],
    catatan: 'Segel utuh',
  );
}

PupukLab samplePupukLab({
  int? id,
  String clientUuid = '11111111-1111-4111-8111-111111111111',
  String noSurat = 'SRS/001',
  List<PupukLabSample> samples = sampleSamples,
  List<String> fotoPaths = const [],
  String status = 'not_uploaded',
  String createdAt = '2026-10-06T10:00:00.000',
}) {
  return PupukLab(
    id: id,
    clientUuid: clientUuid,
    noSurat: noSurat,
    samples: samples,
    form: sampleForm(),
    fotoPaths: fotoPaths,
    status: status,
    createdAt: createdAt,
  );
}
