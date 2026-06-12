import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sampletrack/core/constants/app_constants.dart';

/// Type of alert for icon and color.
enum AppAlertType { success, error, warning, info }

/// Replaces SnackBar with a modern, eye-catching in-app toast.
/// Use [AppAlerts] static methods from anywhere that has [BuildContext].
/// Toasts can be swiped horizontally off-screen to dismiss (same as timeout / action).
class AppAlerts {
  AppAlerts._();

  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  /// Show a toast message. [type] controls icon and color. [duration] defaults to 3s.
  static void show(
    BuildContext context, {
    required String message,
    AppAlertType type = AppAlertType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _dismiss();
    final overlay = Overlay.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color backgroundColor;
    Color foregroundColor;
    IconData icon;
    switch (type) {
      case AppAlertType.success:
        backgroundColor = AppColors.success;
        foregroundColor = Colors.white;
        icon = Icons.check_circle_rounded;
        break;
      case AppAlertType.error:
        backgroundColor = AppColors.error;
        foregroundColor = Colors.white;
        icon = Icons.error_rounded;
        break;
      case AppAlertType.warning:
        backgroundColor = AppColors.warning;
        foregroundColor = Colors.black87;
        icon = Icons.warning_rounded;
        break;
      case AppAlertType.info:
        backgroundColor = theme.colorScheme.primary;
        foregroundColor = Colors.white;
        icon = Icons.info_rounded;
        break;
    }

    _currentEntry = OverlayEntry(
      builder: (ctx) => _AppAlertOverlay(
        message: message,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        icon: icon,
        isDark: isDark,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: _dismiss,
      ),
    );
    overlay.insert(_currentEntry!);

    _timer = Timer(duration, () {
      _dismiss();
    });
  }

  static void success(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      type: AppAlertType.success,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void error(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      type: AppAlertType.error,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      type: AppAlertType.warning,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  static void info(BuildContext context, String message, {Duration? duration}) {
    show(
      context,
      message: message,
      type: AppAlertType.info,
      duration: duration ?? const Duration(seconds: 3),
    );
  }
}

class _AppAlertOverlay extends StatefulWidget {
  const _AppAlertOverlay({
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.isDark,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  });

  final String message;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final bool isDark;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  @override
  State<_AppAlertOverlay> createState() => _AppAlertOverlayState();
}

class _AppAlertOverlayState extends State<_AppAlertOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  final Key _dismissibleKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: Dismissible(
          key: _dismissibleKey,
          direction: DismissDirection.horizontal,
          onDismissed: (_) => widget.onDismiss(),
          background: const ColoredBox(
            color: Colors.transparent,
            child: SizedBox.expand(),
          ),
          secondaryBackground: const ColoredBox(
            color: Colors.transparent,
            child: SizedBox.expand(),
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.foregroundColor, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: widget.foregroundColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (widget.actionLabel != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        widget.onDismiss();
                        widget.onAction?.call();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: widget.foregroundColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        widget.actionLabel!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
