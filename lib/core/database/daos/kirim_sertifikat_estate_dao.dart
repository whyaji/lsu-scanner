import '../models/kirim_sertifikat_estate.dart';
import 'status_table.dart';

class KirimSertifikatEstateDao
    extends SampelActivityTable<KirimSertifikatEstate> {
  KirimSertifikatEstateDao(super.appDatabase)
    : super(
        table: 'kirim_sertifikat_estate',
        fromJson: KirimSertifikatEstate.fromJson,
        toJson: (row) => row.toJson(),
      );
}
