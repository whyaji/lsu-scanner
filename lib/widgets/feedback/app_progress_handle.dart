import 'package:flutter/widgets.dart';

/// Controls a progress dialog opened by AppDialog.progress.
class AppProgressHandle {
  AppProgressHandle.internal({
    required NavigatorState navigator,
    required Route<void> route,
    required ValueNotifier<AppProgressState> state,
  }) : _navigator = navigator,
       _route = route,
       _state = state;

  final NavigatorState _navigator;
  final Route<void> _route;
  final ValueNotifier<AppProgressState> _state;
  bool _closed = false;

  bool get isClosed => _closed;

  /// Pass [value] between 0 and 1 for a determinate bar, or null to keep it indeterminate.
  void update({String? message, double? value}) {
    if (_closed) return;
    final current = _state.value;
    _state.value = AppProgressState(
      message: message ?? current.message,
      value: value,
    );
  }

  void close() {
    if (_closed) return;
    _closed = true;
    if (_route.isActive) {
      if (_route.isCurrent) {
        _navigator.pop();
      } else {
        _navigator.removeRoute(_route);
      }
    }
    _state.dispose();
  }
}

@immutable
class AppProgressState {
  const AppProgressState({required this.message, this.value});

  final String message;
  final double? value;
}
