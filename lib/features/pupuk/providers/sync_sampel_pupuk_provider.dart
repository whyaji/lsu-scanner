import 'package:flutter_riverpod/legacy.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/data_sampel_pupuk.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';

class SyncSampelPupukState {
  final bool isSyncing;
  final String? error;
  final String? lastSyncTime;

  SyncSampelPupukState({this.isSyncing = false, this.error, this.lastSyncTime});

  SyncSampelPupukState copyWith({
    bool? isSyncing,
    String? error,
    String? lastSyncTime,
  }) {
    return SyncSampelPupukState(
      isSyncing: isSyncing ?? this.isSyncing,
      error: error,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

class SyncSampelPupukNotifier extends StateNotifier<SyncSampelPupukState> {
  final ApiService _apiService;
  final DatabaseHelper _dbHelper;
  final AuthNotifier _authNotifier;

  SyncSampelPupukNotifier(this._apiService, this._dbHelper, this._authNotifier)
    : super(SyncSampelPupukState());

  Future<void> sync(int? regional) async {
    final reg = regional ?? 1;
    if (reg < AppConstants.minRegional || reg > AppConstants.maxRegional) {
      state = state.copyWith(error: 'Pilih regional 1–5');
      return;
    }

    state = state.copyWith(isSyncing: true, error: null);

    try {
      final response = await _apiService.syncSampelPupuk(reg);
      if (!response.success || response.data == null) {
        state = state.copyWith(
          isSyncing: false,
          error: response.error?.message ?? 'Sync gagal',
        );
        return;
      }

      final data = response.data!;
      final list = data.dataSampelPupuk
          .map((dto) => DataSampelPupuk.fromApiJson(dto.toJson()))
          .toList();

      await _dbHelper.clearDataSampelPupukByRegional(reg);
      if (list.isNotEmpty) {
        await _dbHelper.insertDataSampelPupukBatch(list);
      }

      if (data.user != null) {
        await _authNotifier.updateUserFromSync(data.user!);
      }

      final now = DateTime.now().toIso8601String();
      await _dbHelper.setPreference(
        AppConstants.keyLastSyncSampelPupukTime,
        now,
      );

      state = state.copyWith(isSyncing: false, error: null, lastSyncTime: now);
    } catch (e) {
      state = state.copyWith(isSyncing: false, error: e.toString());
    }
  }

  Future<void> loadLastSyncTime() async {
    final t = await _dbHelper.getPreference(
      AppConstants.keyLastSyncSampelPupukTime,
    );
    state = state.copyWith(lastSyncTime: t);
  }
}

final syncSampelPupukProvider =
    StateNotifierProvider<SyncSampelPupukNotifier, SyncSampelPupukState>((ref) {
      final apiService = ApiService(ApiClient().dio);
      final dbHelper = DatabaseHelper.instance;
      final authNotifier = ref.read(authProvider.notifier);
      return SyncSampelPupukNotifier(apiService, dbHelper, authNotifier);
    });
