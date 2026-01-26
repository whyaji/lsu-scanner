import 'package:flutter_riverpod/legacy.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/database/database_helper.dart';
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
  final ApiService _apiService;
  final DatabaseHelper _dbHelper;

  SyncNotifier(this._apiService, this._dbHelper) : super(SyncState()) {
    _loadLastSyncTime();
  }

  Future<void> _loadLastSyncTime() async {
    final lastSyncStr = await _dbHelper.getPreference(
      AppConstants.keyLastSyncTime,
    );
    if (lastSyncStr != null) {
      final lastSync = DateTime.tryParse(lastSyncStr);
      if (lastSync != null) {
        final regionalStr = await _dbHelper.getPreference(
          AppConstants.keySelectedRegional,
        );
        state = state.copyWith(
          lastSyncTime: lastSync,
          syncedRegional: regionalStr != null
              ? int.tryParse(regionalStr)
              : null,
        );
      }
    }
  }

  Future<bool> syncData(int regional) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.syncData(regional);

      if (response.success && response.data != null) {
        final syncData = response.data!;

        // Clear existing data
        await _dbHelper.clearMasterSampel();
        await _dbHelper.clearMasterLsu();

        // Insert new data
        await _dbHelper.insertMasterSampelBatch(syncData.masterSampel);
        await _dbHelper.insertMasterLsuBatch(syncData.masterLsu);

        // Update last sync time
        final now = DateTime.now();
        await _dbHelper.setPreference(
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
          error: response.error?.message ?? 'Sync failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Network error occurred');
      return false;
    }
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final apiService = ApiService(ApiClient().dio);
  final dbHelper = DatabaseHelper.instance;
  return SyncNotifier(apiService, dbHelper);
});
