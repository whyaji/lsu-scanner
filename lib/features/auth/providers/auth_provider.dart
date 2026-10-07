import 'dart:convert';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/network/api/auth_api.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/network/interceptors/auth_interceptor.dart';
import '../../../core/network/models/auth_models.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/database/daos/preferences_dao.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/constants/app_constants.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  /// Set when session ended via API (409 / refresh failure); main clears after navigation.
  final bool shouldNavigateToLogin;

  /// Show one-shot banner on login after forced session end (distinct from login failure).
  final bool pendingSessionTerminationBanner;

  /// True during the initial check of stored credentials from secure storage/database.
  final bool isCheckingAuth;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.shouldNavigateToLogin = false,
    this.pendingSessionTerminationBanner = false,
    this.isCheckingAuth = true,
  });

  static const Object _unset = Object();

  AuthState copyWith({
    User? user,
    bool? isLoading,
    Object? error = _unset,
    bool? shouldNavigateToLogin,
    bool? isCheckingAuth,
    bool clearUser = false,
    bool clearNavigateFlag = false,
    bool clearSessionBanner = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      shouldNavigateToLogin: clearNavigateFlag
          ? false
          : (shouldNavigateToLogin ?? this.shouldNavigateToLogin),
      pendingSessionTerminationBanner: clearSessionBanner
          ? false
          : pendingSessionTerminationBanner,
      isCheckingAuth: isCheckingAuth ?? this.isCheckingAuth,
    );
  }

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApi _authApi;
  final SecureStorage _storage;
  final PreferencesDao _preferences;

  AuthNotifier(this._authApi, this._storage, this._preferences)
    : super(AuthState()) {
    AuthInterceptor.configure(onForceLogout: forceLogoutFromApi);
    _checkAuthStatus();
  }

  Future<void> _clearLocalSession() async {
    await _storage.clearTokens();
    await _preferences.delete('user_data');
    await _preferences.delete('user_id');
    await _preferences.delete(AppConstants.keySelectedRegional);
    await _preferences.delete(AppConstants.keyLastSyncTime);
  }

  /// Session invalid / other device logged in. Does not call mobile-logout.
  Future<void> forceLogoutFromApi(String message) async {
    await _clearLocalSession();
    state = AuthState(
      error: message,
      shouldNavigateToLogin: true,
      pendingSessionTerminationBanner: true,
      isCheckingAuth: false,
    );
  }

  void acknowledgeSessionTerminatedNavigation() {
    if (!state.shouldNavigateToLogin) return;
    state = AuthState(
      user: state.user,
      isLoading: state.isLoading,
      error: state.error,
      shouldNavigateToLogin: false,
      pendingSessionTerminationBanner: state.pendingSessionTerminationBanner,
      isCheckingAuth: false,
    );
  }

  void clearSessionTerminationBanner() {
    if (!state.pendingSessionTerminationBanner) return;
    state = state.copyWith(clearSessionBanner: true);
  }

  Future<void> _persistUser(User user) async {
    await _preferences.set('user_data', jsonEncode(user.toJson()));
    await _preferences.set('user_id', user.userId.toString());
  }

  Future<void> _checkAuthStatus() async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        state = state.copyWith(isCheckingAuth: false);
        return;
      }

      User? user;
      final userDataStr = await _preferences.get('user_data');
      if (userDataStr != null) {
        try {
          final userData = jsonDecode(userDataStr) as Map<String, dynamic>;
          user = User.fromJson(userData);
        } catch (_) {
          user = null;
        }
      }

      final needsRefresh =
          user == null ||
          user.permissions.isEmpty ||
          userDataStr != null && !userDataStr.contains('"permissions"');

      if (needsRefresh) {
        final response = await _authApi.getCurrentUser();
        final refreshed = response.data;
        if (response.success && refreshed != null) {
          user = refreshed;
          await _persistUser(refreshed);
        } else {
          // If refresh fails, we should clear the session and token so the user is logged out.
          user = null;
          await _clearLocalSession();
        }
      } else if (userDataStr != null && userDataStr.contains('"access"')) {
        await _persistUser(user);
      }

      state = state.copyWith(user: user, isCheckingAuth: false);
    } catch (e) {
      // Not authenticated
      await _clearLocalSession();
      state = state.copyWith(isCheckingAuth: false, user: null);
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      shouldNavigateToLogin: false,
      clearSessionBanner: true,
    );

    try {
      final response = await _authApi.login(username, password);

      if (response.success && response.data != null) {
        final loginData = response.data!;

        await _storage.saveAccessToken(loginData.accessToken);
        await _storage.saveRefreshToken(loginData.refreshToken);
        final expiresAt = DateTime.now()
            .add(Duration(seconds: loginData.expiresIn))
            .millisecondsSinceEpoch;
        await _storage.saveAccessTokenExpiresAt(expiresAt.toString());

        await _persistUser(loginData.user);

        state = state.copyWith(
          user: loginData.user,
          isLoading: false,
          error: null,
        );

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
      await _authApi.logout();
    } catch (e) {
      // Continue clearing local session
    }

    await _clearLocalSession();
    state = AuthState(isCheckingAuth: false);
  }

  User? get currentUser => state.user;

  Future<void> updateUserFromSync(User user) async {
    await _persistUser(user);
    state = state.copyWith(user: user);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authApiProvider),
    SecureStorage(),
    ref.watch(preferencesDaoProvider),
  );
});
