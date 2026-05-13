import 'package:sampletrack/core/database/models/data_sampel_pupuk.dart';
import 'package:sampletrack/core/database/models/kirim_dari_estate.dart';
import 'package:sampletrack/core/database/models/kirim_lab.dart';
import 'package:sampletrack/core/database/models/kirim_sertifikat_estate.dart';

class AktivitasSampelPupuk {
  final int id;
  final String kodeSampel;
  final DataSampelPupuk dataSampelPupuk;
  final KirimDariEstate? kirimDariEstate;
  final KirimLab? kirimLab;
  final KirimSertifikatEstate? kirimSertifikatEstate;

  AktivitasSampelPupuk({
    required this.id,
    required this.kodeSampel,
    required this.dataSampelPupuk,
    this.kirimDariEstate,
    this.kirimLab,
    this.kirimSertifikatEstate,
  });

  factory AktivitasSampelPupuk.fromJson(Map<String, dynamic> json) {
    return AktivitasSampelPupuk(
      id: json['id'] as int,
      kodeSampel: json['kode_sampel'] as String,
      dataSampelPupuk: DataSampelPupuk.fromJson(json['data_sampel_pupuk']),
      kirimDariEstate: json['kirim_dari_estate'] != null
          ? KirimDariEstate.fromJson(json['kirim_dari_estate'])
          : null,
      kirimLab: json['kirim_lab'] != null
          ? KirimLab.fromJson(json['kirim_lab'])
          : null,
      kirimSertifikatEstate: json['kirim_sertifikat_estate'] != null
          ? KirimSertifikatEstate.fromJson(json['kirim_sertifikat_estate'])
          : null,
    );
  }
}
