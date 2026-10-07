import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/daos/preferences_dao.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/network/models/auth_models.dart';
import '../../auth/providers/auth_provider.dart';

/// Single rule for whether a user has to pick a regional: every module except
/// a Pupuk Lab-only account, whose samples span all regionals.
bool requiresRegional(User? user) => user == null || !user.isPupukLabOnly;

final regionalRequiredProvider = Provider<bool>(
  (ref) => requiresRegional(ref.watch(authProvider).user),
);

class RegionalState {
  final int? selectedRegional;
  final bool isLoading;

  RegionalState({this.selectedRegional, this.isLoading = false});

  RegionalState copyWith({int? selectedRegional, bool? isLoading}) {
    return RegionalState(
      selectedRegional: selectedRegional ?? this.selectedRegional,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class RegionalNotifier extends StateNotifier<RegionalState> {
  final PreferencesDao _preferences;

  RegionalNotifier(this._preferences) : super(RegionalState()) {
    _loadSelectedRegional();
  }

  Future<void> _loadSelectedRegional() async {
    final regionalStr = await _preferences.get(
      AppConstants.keySelectedRegional,
    );
    if (regionalStr != null) {
      final regional = int.tryParse(regionalStr);
      if (regional != null &&
          regional >= AppConstants.minRegional &&
          regional <= AppConstants.maxRegional) {
        state = state.copyWith(selectedRegional: regional);
      }
    }
  }

  Future<void> selectRegional(int regional) async {
    if (regional < AppConstants.minRegional ||
        regional > AppConstants.maxRegional) {
      return;
    }

    state = state.copyWith(selectedRegional: regional, isLoading: true);

    await _preferences.set(
      AppConstants.keySelectedRegional,
      regional.toString(),
    );

    state = state.copyWith(isLoading: false);
  }

  int? get currentRegional => state.selectedRegional;
}

final regionalProvider = StateNotifierProvider<RegionalNotifier, RegionalState>(
  (ref) => RegionalNotifier(ref.watch(preferencesDaoProvider)),
);
