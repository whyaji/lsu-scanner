import 'package:flutter/widgets.dart';

/// Holds the app navigator key so toasts can be shown without a BuildContext.
/// main.dart calls [register] once with its navigator key.
class AppFeedbackHost {
  AppFeedbackHost._();

  static GlobalKey<NavigatorState>? _navigatorKey;

  static void register(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  static OverlayState? get overlay => _navigatorKey?.currentState?.overlay;
}
