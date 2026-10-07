import 'package:flutter/material.dart';

import '../../core/theme/app_semantic_colors.dart';

/// Meaning of a banner, toast, dialog or status chip.
enum AppNoticeType { success, info, warning, error }

/// Resolved colors and icon for an [AppNoticeType] in the current theme.
/// Icons differ by shape so meaning never depends on color alone.
@immutable
class AppNoticeStyle {
  const AppNoticeStyle({
    required this.accent,
    required this.container,
    required this.onContainer,
    required this.icon,
  });

  final Color accent;
  final Color container;
  final Color onContainer;
  final IconData icon;
}

extension AppNoticeTypeStyle on AppNoticeType {
  AppNoticeStyle resolve(BuildContext context) {
    final colors = AppSemanticColors.of(context);
    final (AppNoticeColors c, IconData icon) = switch (this) {
      AppNoticeType.success => (colors.success, Icons.check_circle_rounded),
      AppNoticeType.info => (colors.info, Icons.info_rounded),
      AppNoticeType.warning => (colors.warning, Icons.warning_amber_rounded),
      AppNoticeType.error => (colors.error, Icons.error_rounded),
    };
    return AppNoticeStyle(
      accent: c.accent,
      container: c.container,
      onContainer: c.onContainer,
      icon: icon,
    );
  }

  /// Spoken prefix for screen readers, since the icon is decorative.
  String get spokenLabel => switch (this) {
    AppNoticeType.success => 'Berhasil',
    AppNoticeType.info => 'Informasi',
    AppNoticeType.warning => 'Peringatan',
    AppNoticeType.error => 'Kesalahan',
  };
}
