import 'package:flutter_riverpod/legacy.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/daos/data_sampel_pupuk_dao.dart';
import '../../../core/database/daos/preferences_dao.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/network/api/pupuk_api.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/network/models/auth_models.dart';
import '../../../core/network/models/sync_sampel_pupuk_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pupuk_lab/data/pupuk_lab_master_repository.dart';
import '../../pupuk_lab/providers/pupuk_lab_providers.dart';
import '../../regional/providers/regional_provider.dart';

class SyncSampelPupukState {
  final bool isSyncing;
  final String? error;
  final String? lastSyncTime;

  /// Why the Pupuk Lab master could not be refreshed (lab users only). The
  /// previously cached master, if any, stays usable.
  final String? pupukLabMasterError;

  /// The cached master is older than the backend wanted to serve: SmartLab was
  /// unreachable at the last sync.
  final bool pupukLabMasterStale;

  SyncSampelPupukState({
    this.isSyncing = false,
    this.error,
    this.lastSyncTime,
    this.pupukLabMasterError,
    this.pupukLabMasterStale = false,
  });

  static const Object _unset = Object();

  SyncSampelPupukState copyWith({
    bool? isSyncing,
    String? error,
    String? lastSyncTime,
    Object? pupukLabMasterError = _unset,
    bool? pupukLabMasterStale,
  }) {
    return SyncSampelPupukState(
      isSyncing: isSyncing ?? this.isSyncing,
      error: error,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pupukLabMasterError: identical(pupukLabMasterError, _unset)
          ? this.pupukLabMasterError
          : pupukLabMasterError as String?,
      pupukLabMasterStale: pupukLabMasterStale ?? this.pupukLabMasterStale,
    );
  }
}

class SyncSampelPupukNotifier extends StateNotifier<SyncSampelPupukState> {
  SyncSampelPupukNotifier({
    required PupukApi api,
    required DataSampelPupukDao dataSampelPupukDao,
    required PreferencesDao preferences,
    required PupukLabMasterRepository masterRepository,
    required User? Function() currentUser,
    required Future<void> Function(User user) onUserSynced,
    required void Function() onPupukLabMasterChanged,
  }) : _api = api,
       _dataSampelPupukDao = dataSampelPupukDao,
       _preferences = preferences,
       _masterRepository = masterRepository,
       _currentUser = currentUser,
       _onUserSynced = onUserSynced,
       _onPupukLabMasterChanged = onPupukLabMasterChanged,
       super(SyncSampelPupukState());

  final PupukApi _api;
  final DataSampelPupukDao _dataSampelPupukDao;
  final PreferencesDao _preferences;
  final PupukLabMasterRepository _masterRepository;
  final User? Function() _currentUser;
  final Future<void> Function(User user) _onUserSynced;
  final void Function() _onPupukLabMasterChanged;

  /// [regional] is ignored for users that do not need one (Pupuk Lab only):
  /// the request carries no regional and the local snapshot is replaced whole.
  Future<void> sync(int? regional) async {
    final user = _currentUser();
    final needsRegional = requiresRegional(user);
    final reg = needsRegional ? (regional ?? 1) : null;
    if (reg != null &&
        (reg < AppConstants.minRegional || reg > AppConstants.maxRegional)) {
      state = state.copyWith(error: 'Pilih regional 1–5');
      return;
    }

    state = state.copyWith(isSyncing: true, error: null);

    try {
      final response = await _api.syncSampelPupuk(regional: reg);
      if (!response.success || response.data == null) {
        state = state.copyWith(
          isSyncing: false,
          error: response.error?.message ?? 'Sync gagal',
        );
        return;
      }

      final data = response.data!;
      final syncedUser = data.user ?? user;
      final isLabUser = syncedUser?.hasPupukMobilePupukLab ?? false;

      // A lab user also receives samples of other regionals, so a regional-only
      // clear would leave already received samples behind.
      await _dataSampelPupukDao.replaceSnapshot(
        data.dataSampelPupuk,
        regional: isLabUser ? null : reg,
      );

      if (data.user != null) {
        await _onUserSynced(data.user!);
      }

      final masterStale = await _storePupukLabMaster(data, isLabUser);

      final now = DateTime.now().toIso8601String();
      await _preferences.set(AppConstants.keyLastSyncSampelPupukTime, now);

      state = state.copyWith(
        isSyncing: false,
        error: null,
        lastSyncTime: now,
        pupukLabMasterError: isLabUser ? data.pupukLabMasterError : null,
        pupukLabMasterStale: masterStale,
      );
    } catch (e) {
      state = state.copyWith(isSyncing: false, error: e.toString());
    }
  }

  /// Returns whether the cached master is flagged stale after this sync.
  Future<bool> _storePupukLabMaster(
    SyncSampelPupukResponse data,
    bool isLabUser,
  ) async {
    if (!isLabUser) return false;
    final master = data.pupukLabMaster;
    if (master != null) {
      await _masterRepository.store(
        master,
        serverStale: data.pupukLabMasterStale,
      );
      _onPupukLabMasterChanged();
      return data.pupukLabMasterStale;
    }
    _masterRepository.markStale();
    _onPupukLabMasterChanged();
    return true;
  }

  Future<void> loadLastSyncTime() async {
    final t = await _preferences.get(AppConstants.keyLastSyncSampelPupukTime);
    state = state.copyWith(lastSyncTime: t);
  }
}

final syncSampelPupukProvider =
    StateNotifierProvider<SyncSampelPupukNotifier, SyncSampelPupukState>((ref) {
      return SyncSampelPupukNotifier(
        api: ref.watch(pupukApiProvider),
        dataSampelPupukDao: ref.watch(dataSampelPupukDaoProvider),
        preferences: ref.watch(preferencesDaoProvider),
        masterRepository: ref.watch(pupukLabMasterRepositoryProvider),
        currentUser: () => ref.read(authProvider).user,
        onUserSynced: ref.read(authProvider.notifier).updateUserFromSync,
        onPupukLabMasterChanged: () => ref.invalidate(pupukLabMasterProvider),
      );
    });
