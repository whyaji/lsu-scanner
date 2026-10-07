/// Drops a code the camera reports again while the user is still pointing at it.
///
/// A scanner fires several times per second for one label. Without this a single
/// scan would open the same dialog repeatedly.
class QrScanThrottle {
  QrScanThrottle({
    this.repeatWindow = const Duration(seconds: 2),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Duration repeatWindow;
  final DateTime Function() _clock;

  String? _lastCode;
  DateTime? _lastAt;

  /// True when [code] should be handled. Records it as the latest code.
  bool accept(String code) {
    final now = _clock();
    final lastAt = _lastAt;
    final repeated =
        code == _lastCode &&
        lastAt != null &&
        now.difference(lastAt) < repeatWindow;
    if (repeated) return false;
    _lastCode = code;
    _lastAt = now;
    return true;
  }

  /// Forget the last code, so the same label can be scanned again at once.
  void reset() {
    _lastCode = null;
    _lastAt = null;
  }
}
