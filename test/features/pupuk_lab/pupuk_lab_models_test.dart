import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sampletrack/features/pupuk_lab/models/pupuk_lab.dart';
import 'package:sampletrack/features/pupuk_lab/models/pupuk_lab_sample.dart';
import 'package:sampletrack/features/pupuk_lab/models/pupuk_lab_upload.dart';

import '../../helpers/pupuk_lab_fixtures.dart';

void main() {
  test('PupukLab row round trips through its table map', () {
    final row = samplePupukLab(id: 3, fotoPaths: const ['/a.jpg', '/b.jpg']);
    final restored = PupukLab.fromJson(row.toJson());

    expect(restored.id, 3);
    expect(restored.clientUuid, row.clientUuid);
    expect(restored.samples, row.samples);
    expect(restored.fotoPaths, ['/a.jpg', '/b.jpg']);
    expect(jsonEncode(restored.form.toJson()), jsonEncode(row.form.toJson()));
    expect(restored.kodeSampel, ['W-001', 'W-002', 'MANUAL-9']);
  });

  test('toJson stores null foto_paths_json when there are no photos', () {
    expect(samplePupukLab().toJson()['foto_paths_json'], isNull);
    expect(PupukLab.fromJson(samplePupukLab().toJson()).fotoPaths, isEmpty);
  });

  test('upload item carries server photo paths, not local files', () {
    final row = samplePupukLab(id: 4, fotoPaths: const ['/local.jpg']);
    final json = row.toUploadItem(const [
      '/protected/pupuk-lab/x-1.jpg',
    ]).toJson();

    expect(json.keys.toSet(), {
      'id',
      'clientUuid',
      'noSurat',
      'samples',
      'form',
      'fotoPaths',
    });
    expect(json['id'], 4);
    expect(json['clientUuid'], row.clientUuid);
    expect(json['fotoPaths'], ['/protected/pupuk-lab/x-1.jpg']);
    expect((json['samples'] as List).first, {
      'dataSampelPupukId': 5,
      'kodeSampel': 'W-001',
      'isManual': false,
    });
  });

  test('manual samples serialize without a record id', () {
    final json = sampleSamples.last.toJson();
    expect(json['dataSampelPupukId'], isNull);
    expect(json['isManual'], isTrue);
    expect(PupukLabSample.fromJson(json), sampleSamples.last);
  });

  test('upload result parses success, duplicate and retryable flags', () {
    final result = PupukLabUploadResult.fromJson({
      'success': [
        {
          'id': 1,
          'kodeTrack': 'AB12CD3',
          'nomorLab': '224\$226',
          'nomorKupa': 7,
          'duplicate': true,
        },
      ],
      'failed': [
        {'id': 2, 'error': 'Parameter tidak valid', 'retryable': false},
        {'id': 3, 'error': 'SmartLab tidak dapat dihubungi'},
      ],
    });

    expect(result.success.single.duplicate, isTrue);
    expect(result.success.single.nomorKupa, 7);
    expect(result.failed[0].retryable, isFalse);
    expect(result.failed[1].retryable, isTrue);
  });

  test('upload result tolerates an empty object', () {
    final result = PupukLabUploadResult.fromJson({});
    expect(result.success, isEmpty);
    expect(result.failed, isEmpty);
  });
}
