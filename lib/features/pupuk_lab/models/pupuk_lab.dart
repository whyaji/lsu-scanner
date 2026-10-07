import 'dart:convert';
import '../../../core/constants/app_constants.dart';
import 'pupuk_lab_form.dart';
import 'pupuk_lab_sample.dart';
import 'pupuk_lab_upload.dart';

/// Local Terima Lab receipt (`pupuk_lab` row). One receipt becomes one
/// SmartLab `track_sampel` row.
class PupukLab {
  const PupukLab({
    this.id,
    required this.clientUuid,
    required this.noSurat,
    required this.samples,
    required this.form,
    this.fotoPaths = const [],
    this.status = AppConstants.statusNotUploaded,
    this.errorMessage,
    this.kodeTrack,
    this.nomorLab,
    this.nomorKupa,
    required this.createdAt,
    this.updatedAt,
    this.errorRetryable = true,
  });

  final int? id;

  /// Idempotency key (uuid v4), generated once when the receipt is created and
  /// kept across edits so a retried upload never creates a second SmartLab row.
  final String clientUuid;
  final String noSurat;
  final List<PupukLabSample> samples;
  final PupukLabForm form;

  /// Local photo files; replaced by server paths only inside the upload item.
  final List<String> fotoPaths;
  final String status;
  final String? errorMessage;
  final String? kodeTrack;
  final String? nomorLab;
  final int? nomorKupa;
  final String createdAt;
  final String? updatedAt;

  /// False after SmartLab rejected the data for good: sending it again fails
  /// the same way, so uploads skip the row until it is edited.
  final bool errorRetryable;

  bool get isUploaded => status == AppConstants.statusUploaded;

  bool get needsEdit => status == AppConstants.statusError && !errorRetryable;

  List<String> get kodeSampel => samples.map((s) => s.kodeSampel).toList();

  factory PupukLab.fromJson(Map<String, dynamic> json) {
    final samples = jsonDecode(json['samples_json'] as String) as List;
    final fotos = json['foto_paths_json'] as String?;
    return PupukLab(
      id: (json['id'] as num?)?.toInt(),
      clientUuid: json['client_uuid'] as String,
      noSurat: json['no_surat'] as String,
      samples: samples
          .map((e) => PupukLabSample.fromJson(e as Map<String, dynamic>))
          .toList(),
      form: PupukLabForm.fromJson(
        jsonDecode(json['form_json'] as String) as Map<String, dynamic>,
      ),
      fotoPaths: fotos == null
          ? const []
          : (jsonDecode(fotos) as List).map((e) => e.toString()).toList(),
      status: json['status'] as String? ?? AppConstants.statusNotUploaded,
      errorMessage: json['error_message'] as String?,
      kodeTrack: json['kode_track'] as String?,
      nomorLab: json['nomor_lab'] as String?,
      nomorKupa: (json['nomor_kupa'] as num?)?.toInt(),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String?,
      errorRetryable: (json['error_retryable'] as num?)?.toInt() != 0,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'client_uuid': clientUuid,
    'no_surat': noSurat,
    'samples_json': jsonEncode(samples.map((e) => e.toJson()).toList()),
    'form_json': jsonEncode(form.toJson()),
    'foto_paths_json': fotoPaths.isEmpty ? null : jsonEncode(fotoPaths),
    'status': status,
    'error_message': errorMessage,
    'kode_track': kodeTrack,
    'nomor_lab': nomorLab,
    'nomor_kupa': nomorKupa,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'error_retryable': errorRetryable ? 1 : 0,
  };

  /// Upload payload entry. [serverFotoPaths] are the `/protected/...` paths
  /// returned by the photo endpoint, not the local files.
  PupukLabUploadItem toUploadItem(List<String> serverFotoPaths) {
    return PupukLabUploadItem(
      id: id!,
      clientUuid: clientUuid,
      noSurat: noSurat,
      samples: samples,
      form: form,
      fotoPaths: serverFotoPaths,
    );
  }
}
