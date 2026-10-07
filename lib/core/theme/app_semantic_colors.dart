import 'package:flutter/material.dart';

/// Accessible color triple for one semantic meaning.
/// [accent] is for icons and for text on the page surface, [onContainer] is for text on [container].
@immutable
class AppNoticeColors {
  const AppNoticeColors({
    required this.accent,
    required this.container,
    required this.onContainer,
  });

  final Color accent;
  final Color container;
  final Color onContainer;

  static AppNoticeColors lerp(AppNoticeColors a, AppNoticeColors b, double t) =>
      AppNoticeColors(
        accent: Color.lerp(a.accent, b.accent, t)!,
        container: Color.lerp(a.container, b.container, t)!,
        onContainer: Color.lerp(a.onContainer, b.onContainer, t)!,
      );
}

/// Success, info, warning and error colors tuned to pass WCAG AA in both themes.
/// The brand warning color (F57C00) is 2.70:1 on white, so warning text uses a darker variant here.
/// Measured ratios are listed in docs/design-system.md.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.info,
    required this.warning,
    required this.error,
  });

  final AppNoticeColors success;
  final AppNoticeColors info;
  final AppNoticeColors warning;
  final AppNoticeColors error;

  static const AppSemanticColors light = AppSemanticColors(
    success: AppNoticeColors(
      accent: Color(0xFF2E7D32),
      container: Color(0xFFE8F5E9),
      onContainer: Color(0xFF1B5E20),
    ),
    info: AppNoticeColors(
      accent: Color(0xFF1565C0),
      container: Color(0xFFE3F2FD),
      onContainer: Color(0xFF0D47A1),
    ),
    warning: AppNoticeColors(
      accent: Color(0xFF9A4A00),
      container: Color(0xFFFFF3E0),
      onContainer: Color(0xFF6B3400),
    ),
    error: AppNoticeColors(
      accent: Color(0xFFB00020),
      container: Color(0xFFFDECEA),
      onContainer: Color(0xFF8C0019),
    ),
  );

  static const AppSemanticColors dark = AppSemanticColors(
    success: AppNoticeColors(
      accent: Color(0xFF81C784),
      container: Color(0xFF1B3A1F),
      onContainer: Color(0xFFA5D6A7),
    ),
    info: AppNoticeColors(
      accent: Color(0xFF90CAF9),
      container: Color(0xFF1E3A5F),
      onContainer: Color(0xFFD1E4FF),
    ),
    warning: AppNoticeColors(
      accent: Color(0xFFFFB74D),
      container: Color(0xFF3E2A0A),
      onContainer: Color(0xFFFFD699),
    ),
    error: AppNoticeColors(
      accent: Color(0xFFFF9AA5),
      container: Color(0xFF3F1A1E),
      onContainer: Color(0xFFFFB4AB),
    ),
  );

  /// Falls back to the brightness default so widgets also work under a bare [ThemeData].
  static AppSemanticColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppSemanticColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  AppSemanticColors copyWith({
    AppNoticeColors? success,
    AppNoticeColors? info,
    AppNoticeColors? warning,
    AppNoticeColors? error,
  }) => AppSemanticColors(
    success: success ?? this.success,
    info: info ?? this.info,
    warning: warning ?? this.warning,
    error: error ?? this.error,
  );

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: AppNoticeColors.lerp(success, other.success, t),
      info: AppNoticeColors.lerp(info, other.info, t),
      warning: AppNoticeColors.lerp(warning, other.warning, t),
      error: AppNoticeColors.lerp(error, other.error, t),
    );
  }
}
