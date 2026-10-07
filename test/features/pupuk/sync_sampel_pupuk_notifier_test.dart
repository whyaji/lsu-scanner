import 'package:flutter_test/flutter_test.dart';
import 'package:sampletrack/core/constants/app_constants.dart';
import 'package:sampletrack/core/constants/permission_constants.dart';
import 'package:sampletrack/core/database/app_database.dart';
import 'package:sampletrack/core/database/daos/data_sampel_pupuk_dao.dart';
import 'package:sampletrack/core/database/daos/preferences_dao.dart';
import 'package:sampletrack/core/database/models/data_sampel_pupuk.dart';
import 'package:sampletrack/core/network/api/pupuk_api.dart';
import 'package:sampletrack/core/network/models/api_response.dart';
import 'package:sampletrack/core/network/models/auth_models.dart';
import 'package:sampletrack/core/network/models/sync_sampel_pupuk_models.dart';
import 'package:sampletrack/features/pupuk/providers/sync_sampel_pupuk_provider.dart';
import 'package:sampletrack/features/pupuk_lab/data/pupuk_lab_master_dao.dart';
import 'package:sampletrack/features/pupuk_lab/data/pupuk_lab_master_repository.dart';
import 'package:sampletrack/features/pupuk_lab/models/pupuk_lab_master.dart';
import 'package:sampletrack/features/regional/providers/regional_provider.dart';

import '../../helpers/pupuk_lab_fixtures.dart';
import '../../helpers/test_database.dart';
import '../../helpers/test_user.dart';

class FakePupukApi extends Fake implements PupukApi {
  final List<int?> regionals = [];
  ApiResponse<SyncSampelPupukResponse> Function()? respond;

  @override
  Future<ApiResponse<SyncSampelPupukResponse>> syncSampelPupuk({
    int? regional,
  }) async {
    regionals.add(regional);
    return respond!();
  }
}

const estate = PermissionConstants.pupukMobileKirimEstate;
const pupukLab = PermissionConstants.pupukMobilePupukLab;

ApiResponse<SyncSampelPupukResponse> synced(
  List<DataSampelPupuk> list, {
  User? user,
  Map<String, dynamic>? master,
  bool stale = false,
  String? error,
}) => ApiResponse(
  success: true,
  data: SyncSampelPupukResponse(
    dataSampelPupuk: list,
    user: user,
    pupukLabMaster: master == null ? null : PupukLabMaster.fromApiJson(master),
    pupukLabMasterStale: stale,
    pupukLabMasterError: error,
  ),
);

DataSampelPupuk sample(int id, int regional) =>
    DataSampelPupuk(id: id, kodeSampel: 'K$id', regional: regional);

void main() {
  late AppDatabase db;
  late FakePupukApi api;
  late DataSampelPupukDao dao;
  late PupukLabMasterRepository repo;
  late User? user;
  late List<User> syncedUsers;
  late int masterChanged;
  late SyncSampelPupukNotifier notifier;

  setUp(() {
    db = newTestDatabase();
    api = FakePupukApi();
    dao = DataSampelPupukDao(db);
    repo = PupukLabMasterRepository(PupukLabMasterDao(db));
    user = testUser([estate]);
    syncedUsers = [];
    masterChanged = 0;
    notifier = SyncSampelPupukNotifier(
      api: api,
      dataSampelPupukDao: dao,
      preferences: PreferencesDao(db),
      masterRepository: repo,
      currentUser: () => user,
      onUserSynced: (u) async => syncedUsers.add(u),
      onPupukLabMasterChanged: () => masterChanged++,
    );
  });

  tearDown(() => db.close());

  group('requiresRegional', () {
    test('only a Pupuk Lab-only account skips the regional', () {
      expect(requiresRegional(testUser([pupukLab])), isFalse);
      expect(requiresRegional(testUser([pupukLab, estate])), isTrue);
      expect(
        requiresRegional(
          testUser([pupukLab, PermissionConstants.lsuMobileTerima]),
        ),
        isTrue,
      );
      expect(requiresRegional(testUser([estate])), isTrue);
      expect(requiresRegional(testUser(const [])), isTrue);
      expect(requiresRegional(null), isTrue);
    });
  });

  group('SyncSampelPupukNotifier.sync', () {
    test(
      'estate user sends the regional and only replaces that regional',
      () async {
        await dao.replaceSnapshot([sample(1, 1), sample(2, 2)]);
        api.respond = () => synced([sample(3, 2)]);

        await notifier.sync(2);

        expect(api.regionals, [2]);
        expect((await dao.getAll()).map((e) => e.id), [1, 3]);
        expect(notifier.debugState.error, isNull);
        expect(notifier.debugState.isSyncing, isFalse);
        expect(
          await PreferencesDao(db).get(AppConstants.keyLastSyncSampelPupukTime),
          notifier.debugState.lastSyncTime,
        );
        expect(masterChanged, 0);
      },
    );

    test(
      'defaults to regional 1 and rejects a regional out of range',
      () async {
        api.respond = () => synced(const []);

        await notifier.sync(null);
        expect(api.regionals, [1]);

        await notifier.sync(9);
        expect(api.regionals, [
          1,
        ], reason: 'no request for an invalid regional');
        expect(notifier.debugState.error, 'Pilih regional 1–5');
      },
    );

    test(
      'lab-only user sends no regional and gets the snapshot replaced whole',
      () async {
        user = testUser([pupukLab]);
        await dao.replaceSnapshot([sample(1, 1), sample(2, 4)]);
        api.respond = () => synced([sample(7, 3)], master: masterApiJson());

        await notifier.sync(3);

        expect(api.regionals, [null]);
        expect((await dao.getAll()).map((e) => e.id), [7]);
      },
    );

    test('lab-only user is not blocked by an out-of-range regional', () async {
      user = testUser([pupukLab]);
      api.respond = () => synced(const [], master: masterApiJson());

      await notifier.sync(99);

      expect(api.regionals, [null]);
      expect(notifier.debugState.error, isNull);
    });

    test('stores the master and clears the stale flag and error', () async {
      user = testUser([pupukLab]);
      api.respond = () => synced(const [], master: masterApiJson());

      await notifier.sync(null);

      expect((await repo.load())!.master.version, 'abc123');
      expect(masterChanged, 1);
      expect(notifier.debugState.pupukLabMasterStale, isFalse);
      expect(notifier.debugState.pupukLabMasterError, isNull);
    });

    test(
      'keeps the previous master when the response has none and flags it',
      () async {
        user = testUser([pupukLab]);
        await repo.store(sampleMaster());
        api.respond = () =>
            synced(const [], error: 'SmartLab tidak dapat dihubungi');

        await notifier.sync(null);

        final snapshot = (await repo.load())!;
        expect(snapshot.master.version, 'abc123');
        expect(snapshot.isStale, isTrue);
        expect(notifier.debugState.pupukLabMasterStale, isTrue);
        expect(
          notifier.debugState.pupukLabMasterError,
          'SmartLab tidak dapat dihubungi',
        );
        expect(masterChanged, 1);
      },
    );

    test('a stale master from the server is stored and flagged', () async {
      user = testUser([pupukLab]);
      api.respond = () =>
          synced(const [], master: masterApiJson(), stale: true);

      await notifier.sync(null);

      expect((await repo.load())!.isStale, isTrue);
      expect(notifier.debugState.pupukLabMasterStale, isTrue);
    });

    test(
      'a later successful sync clears the error from the earlier one',
      () async {
        user = testUser([pupukLab]);
        api.respond = () => synced(const [], error: 'down');
        await notifier.sync(null);
        expect(notifier.debugState.pupukLabMasterError, 'down');

        api.respond = () => synced(const [], master: masterApiJson());
        await notifier.sync(null);
        expect(notifier.debugState.pupukLabMasterError, isNull);
        expect(notifier.debugState.pupukLabMasterStale, isFalse);
      },
    );

    test('users without the lab permission never touch the master', () async {
      api.respond = () => synced(const [], master: masterApiJson());

      await notifier.sync(1);

      expect(await repo.hasMaster, isFalse);
      expect(masterChanged, 0);
      expect(notifier.debugState.pupukLabMasterError, isNull);
    });

    test(
      'a refreshed user from the response decides the lab path and is persisted',
      () async {
        final promoted = testUser([estate, pupukLab]);
        api.respond = () =>
            synced([sample(5, 1)], user: promoted, master: masterApiJson());

        await notifier.sync(1);

        expect(syncedUsers, [promoted]);
        expect(await repo.hasMaster, isTrue);
        expect(api.regionals, [
          1,
        ], reason: 'estate access still needs a regional');
      },
    );

    test('an API failure reports the error and keeps local data', () async {
      await dao.replaceSnapshot([sample(1, 1)]);
      api.respond = () => ApiResponse(
        success: false,
        error: ApiError(code: 'NETWORK_ERROR', message: 'Tidak ada koneksi'),
      );

      await notifier.sync(1);

      expect(notifier.debugState.error, 'Tidak ada koneksi');
      expect(notifier.debugState.isSyncing, isFalse);
      expect((await dao.getAll()).map((e) => e.id), [1]);
    });
  });
}
