import 'package:audioplayers/audioplayers.dart';

/// Plays in-app notification sounds for foreground FCM messages.
class NotificationSoundService {
  NotificationSoundService._();

  static final NotificationSoundService instance = NotificationSoundService._();

  static const _defaultSound = 'notification';
  static const _assetBySound = <String, String>{
    'notification': 'sounds/notification.wav',
    'notification2': 'sounds/notification2.wav',
  };

  final AudioPlayer _player = AudioPlayer();

  Future<void> play([String? soundKey]) async {
    final key = _normalizeSoundKey(soundKey);
    final assetPath = _assetBySound[key] ?? _assetBySound[_defaultSound]!;
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (_) {
      // Ignore playback errors (e.g. silent mode); push sound still works in background.
    }
  }

  String _normalizeSoundKey(String? soundKey) {
    final key = soundKey?.trim();
    if (key == 'notification2') return 'notification2';
    return _defaultSound;
  }
}
