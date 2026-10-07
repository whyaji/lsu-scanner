import 'pupuk_lab_form.dart';
import 'pupuk_lab_sample.dart';

/// `pupukLab[]` entry of `POST /data-sampel-pupuk/upload`.
class PupukLabUploadItem {
  const PupukLabUploadItem({
    required this.id,
    required this.clientUuid,
    required this.noSurat,
    required this.samples,
    required this.form,
    required this.fotoPaths,
  });

  final int id;
  final String clientUuid;
  final String noSurat;
  final List<PupukLabSample> samples;
  final PupukLabForm form;
  final List<String> fotoPaths;

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientUuid': clientUuid,
    'noSurat': noSurat,
    'samples': samples.map((e) => e.toJson()).toList(),
    'form': form.toJson(),
    'fotoPaths': fotoPaths,
  };
}

class PupukLabUploadSuccess {
  const PupukLabUploadSuccess({
    required this.id,
    required this.kodeTrack,
    required this.nomorLab,
    required this.nomorKupa,
    this.duplicate = false,
  });

  final int id;
  final String kodeTrack;
  final String nomorLab;
  final int nomorKupa;

  /// The server already had this `clientUuid` (an earlier attempt succeeded).
  final bool duplicate;

  factory PupukLabUploadSuccess.fromJson(Map<String, dynamic> json) =>
      PupukLabUploadSuccess(
        id: (json['id'] as num).toInt(),
        kodeTrack: json['kodeTrack'] as String? ?? '',
        nomorLab: json['nomorLab'] as String? ?? '',
        nomorKupa: (json['nomorKupa'] as num?)?.toInt() ?? 0,
        duplicate: json['duplicate'] as bool? ?? false,
      );
}

class PupukLabUploadFailure {
  const PupukLabUploadFailure({
    required this.id,
    required this.error,
    required this.retryable,
  });

  final int id;
  final String error;

  /// False for validation errors the user has to fix (edit or delete the
  /// receipt); true for outages that the next upload can retry.
  final bool retryable;

  factory PupukLabUploadFailure.fromJson(Map<String, dynamic> json) =>
      PupukLabUploadFailure(
        id: (json['id'] as num).toInt(),
        error: json['error'] as String? ?? 'Kesalahan tidak diketahui',
        retryable: json['retryable'] as bool? ?? true,
      );
}

class PupukLabUploadResult {
  const PupukLabUploadResult({this.success = const [], this.failed = const []});

  final List<PupukLabUploadSuccess> success;
  final List<PupukLabUploadFailure> failed;

  factory PupukLabUploadResult.fromJson(Map<String, dynamic> json) {
    final success = json['success'];
    final failed = json['failed'];
    return PupukLabUploadResult(
      success: success is List
          ? success
                .map(
                  (e) =>
                      PupukLabUploadSuccess.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : const [],
      failed: failed is List
          ? failed
                .map(
                  (e) =>
                      PupukLabUploadFailure.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : const [],
    );
  }
}
