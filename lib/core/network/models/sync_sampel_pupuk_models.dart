import '../../../features/pupuk_lab/models/pupuk_lab_master.dart';
import '../../database/models/data_sampel_pupuk.dart';
import 'auth_models.dart';

class PaginatedDataSampelPupukResponse {
  final List<DataSampelPupuk> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PaginatedDataSampelPupukResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginatedDataSampelPupukResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'];
    final items = list is List
        ? list
              .map(
                (e) => DataSampelPupuk.fromApiJson(e as Map<String, dynamic>),
              )
              .toList()
        : <DataSampelPupuk>[];
    return PaginatedDataSampelPupukResponse(
      data: items,
      total: (json['total'] as num?)?.toInt() ?? items.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? items.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

/// `GET /mobile/sync-sampel-pupuk`. The `pupukLab*` fields are only present
/// for users with the Pupuk Lab permission.
class SyncSampelPupukResponse {
  final List<DataSampelPupuk> dataSampelPupuk;
  final User? user;

  /// Null when the user has no lab permission, or the backend had no snapshot
  /// and SmartLab was unreachable (then [pupukLabMasterError] is set).
  final PupukLabMaster? pupukLabMaster;

  /// The master came from an old snapshot because SmartLab was unreachable.
  final bool pupukLabMasterStale;
  final String? pupukLabMasterError;

  SyncSampelPupukResponse({
    required this.dataSampelPupuk,
    this.user,
    this.pupukLabMaster,
    this.pupukLabMasterStale = false,
    this.pupukLabMasterError,
  });

  factory SyncSampelPupukResponse.fromJson(Map<String, dynamic> json) {
    final list = json['dataSampelPupuk'];
    final master = json['pupukLabMaster'];
    return SyncSampelPupukResponse(
      dataSampelPupuk: list is List
          ? list
                .map(
                  (e) => DataSampelPupuk.fromApiJson(e as Map<String, dynamic>),
                )
                .toList()
          : const [],
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      pupukLabMaster: master is Map<String, dynamic>
          ? PupukLabMaster.fromApiJson(master)
          : null,
      pupukLabMasterStale: json['pupukLabMasterStale'] as bool? ?? false,
      pupukLabMasterError: json['pupukLabMasterError'] as String?,
    );
  }
}

class NextNoSuratResponse {
  final String noSurat;
  final int sequence;

  NextNoSuratResponse({required this.noSurat, required this.sequence});

  factory NextNoSuratResponse.fromJson(Map<String, dynamic> json) {
    return NextNoSuratResponse(
      noSurat: json['noSurat'] as String? ?? '',
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
    );
  }
}
