import '../../../../core/database/models/kirim_dari_estate.dart';
import '../../../../core/database/models/kirim_lab.dart';
import '../../../../core/database/models/kirim_sertifikat_estate.dart';
import '../../../../core/database/daos/kirim_dari_estate_dao.dart';
import '../../../../core/database/daos/kirim_lab_dao.dart';
import '../../../../core/database/daos/kirim_sertifikat_estate_dao.dart';
import '../../../../core/network/models/pupuk_upload_models.dart';
import '../../constants/pupuk_activity_types.dart';
import 'status_table_strategy.dart';

class KirimDariEstateUploadStrategy
    extends StatusTableUploadStrategy<KirimDariEstate> {
  KirimDariEstateUploadStrategy(KirimDariEstateDao super.table, super.uploadApi);

  @override
  String get type => kKirimDariEstate;

  @override
  UploadTypeResult resultOf(SampelPupukUploadResponse response) =>
      response.kirimDariEstate;

  @override
  int idOf(KirimDariEstate row) => row.id!;

  @override
  int dataSampelPupukIdOf(KirimDariEstate row) => row.dataSampelPupukId;

  @override
  String kodeSampelOf(KirimDariEstate row) => row.kodeSampel;

  @override
  List<String> localFiles(List<KirimDariEstate> group) {
    final foto = group.first.fotoKirimDariEstate;
    return foto != null && foto.isNotEmpty ? [foto] : const [];
  }

  @override
  Map<String, dynamic> buildItem(KirimDariEstate row, List<String> serverFiles) =>
      KirimDariEstateItem(
        id: row.id!,
        dataSampelPupukId: row.dataSampelPupukId,
        kodeSampel: row.kodeSampel,
        tanggalKirimDariEstate: row.tanggalKirimDariEstate,
        fotoKirimDariEstate: serverFiles.firstOrNull ?? row.fotoKirimDariEstate,
        namaPengirim: row.namaPengirim,
      ).toJson();
}

/// Rows with the same no. surat and local photo share one photo upload.
class KirimLabUploadStrategy extends StatusTableUploadStrategy<KirimLab> {
  KirimLabUploadStrategy(KirimLabDao super.table, super.uploadApi);

  @override
  String get type => kKirimLab;

  @override
  UploadTypeResult resultOf(SampelPupukUploadResponse response) =>
      response.kirimLab;

  @override
  int idOf(KirimLab row) => row.id!;

  @override
  int dataSampelPupukIdOf(KirimLab row) => row.dataSampelPupukId;

  @override
  String kodeSampelOf(KirimLab row) => row.kodeSampel;

  String _groupKey(KirimLab row) {
    final noSurat = row.noSurat?.trim() ?? '';
    final foto = row.fotoKirimLab?.trim() ?? '';
    if (foto.isEmpty) return 'no-foto:${row.id}';
    if (noSurat.isNotEmpty) return 'batch:$noSurat|$foto';
    return 'foto:$foto';
  }

  @override
  List<List<KirimLab>> groupRows(List<KirimLab> rows) {
    final groups = <String, List<KirimLab>>{};
    for (final row in rows) {
      groups.putIfAbsent(_groupKey(row), () => []).add(row);
    }
    return groups.values.toList();
  }

  @override
  List<String> localFiles(List<KirimLab> group) {
    final foto = group.first.fotoKirimLab?.trim() ?? '';
    return foto.isNotEmpty ? [foto] : const [];
  }

  @override
  Map<String, dynamic> buildItem(KirimLab row, List<String> serverFiles) =>
      KirimLabItem(
        id: row.id!,
        dataSampelPupukId: row.dataSampelPupukId,
        kodeSampel: row.kodeSampel,
        noSurat: row.noSurat,
        tanggalKirimLab: row.tanggalKirimLab,
        fotoKirimLab: serverFiles.firstOrNull ?? row.fotoKirimLab,
      ).toJson();
}

/// Rows with the same local PDF share one upload.
class KirimSertifikatEstateUploadStrategy
    extends StatusTableUploadStrategy<KirimSertifikatEstate> {
  KirimSertifikatEstateUploadStrategy(
    KirimSertifikatEstateDao super.table,
    super.uploadApi,
  );

  @override
  String get type => kKirimSertifikatEstate;

  @override
  String get photoFailureMessage => 'Gagal mengunggah file sertifikat';

  @override
  UploadTypeResult resultOf(SampelPupukUploadResponse response) =>
      response.kirimSertifikatEstate;

  @override
  int idOf(KirimSertifikatEstate row) => row.id!;

  @override
  int dataSampelPupukIdOf(KirimSertifikatEstate row) => row.dataSampelPupukId;

  @override
  String kodeSampelOf(KirimSertifikatEstate row) => row.kodeSampel;

  String _groupKey(KirimSertifikatEstate row) {
    final file = row.fileSertifikat.trim();
    return file.isEmpty ? 'no-file:${row.id}' : 'batch:$file';
  }

  @override
  List<List<KirimSertifikatEstate>> groupRows(
    List<KirimSertifikatEstate> rows,
  ) {
    final groups = <String, List<KirimSertifikatEstate>>{};
    for (final row in rows) {
      groups.putIfAbsent(_groupKey(row), () => []).add(row);
    }
    return groups.values.toList();
  }

  @override
  List<String> localFiles(List<KirimSertifikatEstate> group) {
    final file = group.first.fileSertifikat.trim();
    return file.isNotEmpty ? [file] : const [];
  }

  @override
  Map<String, dynamic> buildItem(
    KirimSertifikatEstate row,
    List<String> serverFiles,
  ) => KirimSertifikatEstateItem(
    id: row.id!,
    dataSampelPupukId: row.dataSampelPupukId,
    kodeSampel: row.kodeSampel,
    tanggalKirimSertifikatEstate: row.tanggalKirimSertifikatEstate,
    rekomendasi: row.rekomendasi,
    fileSertifikat: serverFiles.firstOrNull ?? row.fileSertifikat,
  ).toJson();
}
