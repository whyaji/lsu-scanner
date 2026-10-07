import '../models/kirim_dari_estate.dart';
import 'status_table.dart';

class KirimDariEstateDao extends SampelActivityTable<KirimDariEstate> {
  KirimDariEstateDao(super.appDatabase)
    : super(
        table: 'kirim_dari_estate',
        fromJson: KirimDariEstate.fromJson,
        toJson: (row) => row.toJson(),
      );
}
