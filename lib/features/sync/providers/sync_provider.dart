import 'package:flutter_riverpod/legacy.dart';
import '../../../core/database/daos/lsu_dao.dart';
import '../../../core/database/daos/preferences_dao.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/network/api/lsu_api.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/constants/app_constants.dart';

class SyncState {
  final bool isLoading;
  final String? error;
  final DateTime? lastSyncTime;
  final int? syncedRegional;

  SyncState({
    this.isLoading = false,
    this.error,
    this.lastSyncTime,
    this.syncedRegional,
  });

  SyncState copyWith({
    bool? isLoading,
    String? error,
    DateTime? lastSyncTime,
    int? syncedRegional,
  }) {
    return SyncState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      syncedRegional: syncedRegional ?? this.syncedRegional,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final LsuApi _api;
  final LsuDao _lsuDao;
  final PreferencesDao _preferences;

  SyncNotifier(this._api, this._lsuDao, this._preferences) : super(SyncState()) {
    _loadLastSyncTime();
  }

  Future<void> _loadLastSyncTime() async {
    final lastSyncStr = await _preferences.get(
      AppConstants.keyLastSyncTime,
    );
    if (lastSyncStr != null) {
      final lastSync = DateTime.tryParse(lastSyncStr);
      if (lastSync != null) {
        final regionalStr = await _preferences.get(
          AppConstants.keySelectedRegional,
        );
        // Only apply stored values when we don't already have in-memory state,
        // so we never overwrite a fresh sync done in this session (e.g. first
        // regional select after login).
        if (state.lastSyncTime == null) {
          state = state.copyWith(
            lastSyncTime: lastSync,
            syncedRegional: regionalStr != null
                ? int.tryParse(regionalStr)
                : null,
          );
        }
      }
    }
  }

  Future<bool> syncData(int regional) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.syncData(regional);

      if (response.success && response.data != null) {
        final syncData = response.data!;

        // Clear existing data
        await _lsuDao.clearMasterSampel();
        await _lsuDao.clearMasterLsu();

        // Insert new data
        await _lsuDao.insertMasterSampelBatch(syncData.masterSampel);
        await _lsuDao.insertMasterLsuBatch(syncData.masterLsu);

        // Update last sync time
        final now = DateTime.now();
        await _preferences.set(
          AppConstants.keyLastSyncTime,
          now.toIso8601String(),
        );

        state = state.copyWith(
          isLoading: false,
          lastSyncTime: now,
          syncedRegional: regional,
        );

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error?.message ?? 'Sinkronisasi gagal',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Terjadi kesalahan jaringan',
      );
      return false;
    }
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(
    ref.watch(lsuApiProvider),
    ref.watch(lsuDaoProvider),
    ref.watch(preferencesDaoProvider),
  );
});
