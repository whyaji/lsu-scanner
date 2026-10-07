import 'package:dio/dio.dart' show ProgressCallback;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sampletrack/core/network/api/upload_api.dart';
import 'package:sampletrack/core/network/models/api_response.dart';
import 'package:sampletrack/core/network/models/pupuk_upload_models.dart';
import 'package:sampletrack/features/pupuk/constants/pupuk_activity_types.dart';

/// Records every call and answers from the configured behavior.
class FakeUploadApi extends Fake implements UploadApi {
  final List<String> pupukPhotoCalls = [];
  final List<String> labPhotoCalls = [];
  final Map<String, int> failuresLeft = {};
  int uploadCalls = 0;
  SampelPupukUploadPayload? lastPayload;
  ApiResponse<SampelPupukUploadResponse> Function(
    SampelPupukUploadPayload payload,
  )?
  respond;

  bool _shouldFail(String path) {
    final left = failuresLeft[path] ?? 0;
    if (left <= 0) return false;
    failuresLeft[path] = left - 1;
    return true;
  }

  @override
  Future<ApiResponse<PhotoPupukUploadResponse>> uploadPhotoPupuk({
    required int dataSampelPupukId,
    required String kodeSampel,
    required String type,
    String? filePath,
    String? reuseFilePath,
    ProgressCallback? onSendProgress,
  }) async {
    pupukPhotoCalls.add('$type|$kodeSampel|$filePath');
    if (_shouldFail(filePath!)) {
      return ApiResponse(
        success: false,
        error: ApiError(code: 'NETWORK_ERROR', message: 'putus'),
      );
    }
    return ApiResponse(
      success: true,
      data: PhotoPupukUploadResponse(
        filePath: '/protected/pupuk/${p.basename(filePath)}',
        type: type,
      ),
    );
  }

  @override
  Future<ApiResponse<String>> uploadPhotoPupukLab({
    required String clientUuid,
    required String filePath,
    ProgressCallback? onSendProgress,
  }) async {
    labPhotoCalls.add('$clientUuid|$filePath');
    if (_shouldFail(filePath)) {
      return ApiResponse(
        success: false,
        error: ApiError(code: 'NETWORK_ERROR', message: 'putus'),
      );
    }
    return ApiResponse(
      success: true,
      data: '/protected/pupuk-lab/$clientUuid-${p.basename(filePath)}',
    );
  }

  @override
  Future<ApiResponse<SampelPupukUploadResponse>> uploadSampelPupuk(
    SampelPupukUploadPayload payload,
  ) async {
    uploadCalls++;
    lastPayload = payload;
    return respond!(payload);
  }
}

ApiResponse<SampelPupukUploadResponse> ok(Map<String, dynamic> body) =>
    ApiResponse(success: true, data: SampelPupukUploadResponse.fromJson(body));

/// Marks every item of every type as accepted by the server.
ApiResponse<SampelPupukUploadResponse> acceptAll(
  SampelPupukUploadPayload payload,
) {
  final json = payload.toJson();
  return ok({
    for (final type in kUploadablePupukActivityTypes)
      type: {
        'success': [
          for (final item in json[type] as List)
            type == kPupukLab
                ? {
                    'id': (item as Map)['id'],
                    'kodeTrack': 'TRK${item['id']}',
                    'nomorLab': '1\$${item['id']}',
                    'nomorKupa': 10 + (item['id'] as int),
                    'duplicate': false,
                  }
                : {'id': (item as Map)['id']},
        ],
        'failed': [],
      },
  });
}
