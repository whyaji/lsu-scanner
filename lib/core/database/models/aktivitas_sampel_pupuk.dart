import 'package:sampletrack/core/database/models/data_sampel_pupuk.dart';
import 'package:sampletrack/core/database/models/terima_dari_gudang.dart';
import 'package:sampletrack/core/database/models/kirim_dari_estate.dart';
import 'package:sampletrack/core/database/models/terima_dari_estate.dart';
import 'package:sampletrack/core/database/models/kirim_lab.dart';
import 'package:sampletrack/core/database/models/kirim_sertifikat_estate.dart';

class AktivitasSampelPupuk {
  final int id;
  final String kodeSampel;
  final DataSampelPupuk dataSampelPupuk;
  final TerimaDariGudang? terimaDariGudang;
  final KirimDariEstate? kirimDariEstate;
  final TerimaDariEstate? terimaDariEstate;
  final KirimLab? kirimLab;
  final KirimSertifikatEstate? kirimSertifikatEstate;

  AktivitasSampelPupuk({
    required this.id,
    required this.kodeSampel,
    required this.dataSampelPupuk,
    this.terimaDariGudang,
    this.kirimDariEstate,
    this.terimaDariEstate,
    this.kirimLab,
    this.kirimSertifikatEstate,
  });

  factory AktivitasSampelPupuk.fromJson(Map<String, dynamic> json) {
    return AktivitasSampelPupuk(
      id: json['id'] as int,
      kodeSampel: json['kode_sampel'] as String,
      dataSampelPupuk: DataSampelPupuk.fromJson(json['data_sampel_pupuk']),
      terimaDariGudang: json['terima_dari_gudang'] != null
          ? TerimaDariGudang.fromJson(json['terima_dari_gudang'])
          : null,
      kirimDariEstate: json['kirim_dari_estate'] != null
          ? KirimDariEstate.fromJson(json['kirim_dari_estate'])
          : null,
      terimaDariEstate: json['terima_dari_estate'] != null
          ? TerimaDariEstate.fromJson(json['terima_dari_estate'])
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
