import 'package:flutter_test/flutter_test.dart';
import 'package:sampletrack/core/database/app_database.dart';
import 'package:sampletrack/core/database/daos/kirim_lab_dao.dart';
import 'package:sampletrack/core/database/models/kirim_lab.dart';
import 'package:sampletrack/core/network/models/api_response.dart';
import 'package:sampletrack/features/pupuk/constants/pupuk_activity_types.dart';
import 'package:sampletrack/features/pupuk/providers/upload/pupuk_upload_pipeline.dart';
import 'package:sampletrack/features/pupuk/providers/upload/pupuk_upload_strategies.dart';
import 'package:sampletrack/features/pupuk/providers/upload_sampel_pupuk_provider.dart';
import 'package:sampletrack/features/pupuk_lab/data/pupuk_lab_dao.dart';
import 'package:sampletrack/features/pupuk_lab/providers/pupuk_lab_upload_strategy.dart';

import '../../helpers/fake_upload_api.dart';
import '../../helpers/pupuk_lab_fixtures.dart';
import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late FakeUploadApi api;
  late KirimLabDao labDao;
  late PupukLabDao pupukLabDao;
  late UploadSampelPupukNotifier notifier;

  setUp(() {
    db = newTestDatabase();
    api = FakeUploadApi();
    labDao = KirimLabDao(db);
    pupukLabDao = PupukLabDao(db);
    notifier = UploadSampelPupukNotifier(
      PupukUploadPipeline(
        uploadApi: api,
        retryDelay: Duration.zero,
        compress: (_) async => null,
        strategies: [
          KirimLabUploadStrategy(labDao, api),
          PupukLabUploadStrategy(pupukLabDao, api),
        ],
      ),
    );
  });

  tearDown(() => db.close());

  test('exposes counts and per-type results after the run', () async {
    await labDao.insert(
      KirimLab(
        dataSampelPupukId: 1,
        kodeSampel: 'L-1',
        tanggalKirimLab: '2026-10-01',
        createdAt: '2026-10-01T08:00:00',
      ),
    );
    final receipt = await pupukLabDao.insert(samplePupukLab());
    api.respond = (payload) {
      final labId = (payload.toJson()[kKirimLab] as List).single['id'];
      return ok({
        kKirimLab: {
          'success': [
            {'id': labId},
          ],
          'failed': [],
        },
        kPupukLab: {
          'success': [],
          'failed': [
            {
              'id': receipt,
              'error': 'Parameter tidak valid',
              'retryable': false,
            },
          ],
        },
      });
    };

    await notifier.uploadAll();

    final state = notifier.debugState;
    expect(state.isUploading, isFalse);
    expect(state.progress, isNull);
    expect(state.error, isNull);
    expect(state.lastSuccessCount, 1);
    expect(state.lastFailedCount, 1);
    expect(state.resultsByType.keys, {kKirimLab, kPupukLab});
    expect(state.resultsByType[kKirimLab]!.uploaded, 1);
    final failure = state.resultsByType[kPupukLab]!.failures.single;
    expect(failure.label, 'SRS/001');
    expect(failure.message, 'Parameter tidak valid');
    expect(failure.retryable, isFalse);
  });

  test('a failed request sets the error and counts every row failed', () async {
    await pupukLabDao.insert(samplePupukLab());
    api.respond = (_) => ApiResponse(
      success: false,
      error: ApiError(code: 'NETWORK_ERROR', message: 'Tidak ada koneksi'),
    );

    await notifier.uploadAll();

    final state = notifier.debugState;
    expect(state.error, 'Tidak ada koneksi');
    expect(state.lastSuccessCount, 0);
    expect(state.lastFailedCount, 1);
    expect(state.isUploading, isFalse);
  });

  test('with nothing pending it ends idle without counts', () async {
    await notifier.uploadAll();

    final state = notifier.debugState;
    expect(state.isUploading, isFalse);
    expect(state.lastSuccessCount, isNull);
    expect(state.resultsByType, isEmpty);
  });

  test('an unexpected exception is reported as the error', () async {
    await pupukLabDao.insert(samplePupukLab());
    api.respond = (_) => throw StateError('boom');

    await notifier.uploadAll();

    expect(notifier.debugState.error, contains('boom'));
    expect(notifier.debugState.isUploading, isFalse);
  });
}
