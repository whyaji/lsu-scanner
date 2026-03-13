import 'dart:convert';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/models/auth_models.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/constants/app_constants.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({User? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final SecureStorage _storage;
  final DatabaseHelper _dbHelper;

  AuthNotifier(this._apiService, this._storage, this._dbHelper)
    : super(AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final token = await _storage.getAccessToken();
      if (token != null) {
        final userDataStr = await _dbHelper.getPreference('user_data');
        if (userDataStr != null) {
          try {
            final userData = jsonDecode(userDataStr) as Map<String, dynamic>;
            final user = User.fromJson(userData);
            state = state.copyWith(user: user);
          } catch (e) {
            // If parsing fails, try to get from API
            final response = await _apiService.getCurrentUser();
            if (response.success && response.data != null) {
              state = state.copyWith(user: response.data);
            }
          }
        } else {
          // Try to get from API
          final response = await _apiService.getCurrentUser();
          if (response.success && response.data != null) {
            state = state.copyWith(user: response.data);
          }
        }
      }
    } catch (e) {
      // Not authenticated
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.login(username, password);

      if (response.success && response.data != null) {
        final loginData = response.data!;

        // Save tokens
        await _storage.saveAccessToken(loginData.accessToken);
        await _storage.saveRefreshToken(loginData.refreshToken);
        final expiresAt = DateTime.now()
            .add(Duration(seconds: loginData.expiresIn))
            .millisecondsSinceEpoch;
        await _storage.saveAccessTokenExpiresAt(expiresAt.toString());

        // Save user data
        await _dbHelper.setPreference(
          'user_data',
          jsonEncode(loginData.user.toJson()),
        );
        await _dbHelper.setPreference('user_id', loginData.user.id.toString());

        state = state.copyWith(user: loginData.user, isLoading: false);

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error?.message ?? 'Login gagal',
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

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Continue with logout even if API call fails
    }

    // Clear storage
    await _storage.clearTokens();
    await _dbHelper.deletePreference('user_data');
    await _dbHelper.deletePreference('user_id');
    await _dbHelper.deletePreference(AppConstants.keySelectedRegional);
    await _dbHelper.deletePreference(AppConstants.keyLastSyncTime);

    state = AuthState();
  }

  User? get currentUser => state.user;

  /// Updates stored user (e.g. after sync-sampel-pupuk returns user with access).
  Future<void> updateUserFromSync(User user) async {
    await _dbHelper.setPreference('user_data', jsonEncode(user.toJson()));
    state = state.copyWith(user: user);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ApiService(ApiClient().dio);
  final storage = SecureStorage();
  final dbHelper = DatabaseHelper.instance;
  return AuthNotifier(apiService, storage, dbHelper);
});
