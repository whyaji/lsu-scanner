import 'package:flutter_riverpod/legacy.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/constants/app_constants.dart';

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
  final DatabaseHelper _dbHelper;

  RegionalNotifier(this._dbHelper) : super(RegionalState()) {
    _loadSelectedRegional();
  }

  Future<void> _loadSelectedRegional() async {
    final regionalStr = await _dbHelper.getPreference(
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

    await _dbHelper.setPreference(
      AppConstants.keySelectedRegional,
      regional.toString(),
    );

    state = state.copyWith(isLoading: false);
  }

  int? get currentRegional => state.selectedRegional;
}

final regionalProvider = StateNotifierProvider<RegionalNotifier, RegionalState>(
  (ref) {
    final dbHelper = DatabaseHelper.instance;
    return RegionalNotifier(dbHelper);
  },
);
