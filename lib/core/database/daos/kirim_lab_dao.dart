import '../models/kirim_lab.dart';
import 'status_table.dart';

class KirimLabDao extends SampelActivityTable<KirimLab> {
  KirimLabDao(super.appDatabase)
    : super(
        table: 'kirim_lab',
        fromJson: KirimLab.fromJson,
        toJson: (row) => row.toJson(),
      );

  /// No. surat of the latest Kirim Lab row for the sample, or null when blank.
  Future<String?> latestNoSurat(int dataSampelPupukId) async {
    final db = await appDatabase.database;
    final rows = await db.query(
      table,
      columns: ['no_surat'],
      where: 'data_sampel_pupuk_id = ?',
      whereArgs: [dataSampelPupukId],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final noSurat = (rows.first['no_surat'] as String?)?.trim() ?? '';
    return noSurat.isEmpty ? null : noSurat;
  }
}
