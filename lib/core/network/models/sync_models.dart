import '../../database/models/master_sampel.dart';
import '../../database/models/master_lsu.dart';

class SyncResponse {
  final List<MasterSampel> masterSampel;
  final List<MasterLsu> masterLsu;

  SyncResponse({required this.masterSampel, required this.masterLsu});

  factory SyncResponse.fromJson(Map<String, dynamic> json) {
    return SyncResponse(
      masterSampel:
          (json['masterSampel'] as List<dynamic>?)
              ?.map((e) => MasterSampel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      masterLsu:
          (json['masterLsu'] as List<dynamic>?)
              ?.map((e) => MasterLsu.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
