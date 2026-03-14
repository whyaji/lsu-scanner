import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

enum AppThemeMode { light, dark, system }

extension AppThemeModeX on AppThemeMode {
  String get value {
    switch (this) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.system:
        return 'system';
    }
  }

  static AppThemeMode fromString(String? value) {
    switch (value) {
      case 'dark':
        return AppThemeMode.dark;
      case 'light':
        return AppThemeMode.light;
      case 'system':
      default:
        return AppThemeMode.system;
    }
  }

  ThemeMode get themeMode {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return 'Terang';
      case AppThemeMode.dark:
        return 'Gelap';
      case AppThemeMode.system:
        return 'Sistem';
    }
  }
}

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.system) {
    _load();
  }

  static SharedPreferences? _prefs;
  static Future<SharedPreferences> get _prefsAsync async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> _load() async {
    final prefs = await _prefsAsync;
    final value = prefs.getString(AppConstants.keyThemeMode);
    state = AppThemeModeX.fromString(value);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    final prefs = await _prefsAsync;
    await prefs.setString(AppConstants.keyThemeMode, mode.value);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((
  ref,
) {
  return ThemeNotifier();
});
