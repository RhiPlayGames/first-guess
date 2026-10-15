import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Optional, local-only feedback sounds. Never blocks gameplay.
class SoundEffectsService {
  SoundEffectsService._();

  static const String _preferenceKey = 'first_guess_sound_effects_enabled';
  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);
  static final AudioPlayer _correctPlayer = AudioPlayer();
  static final AudioPlayer _incorrectPlayer = AudioPlayer();
  static Future<void>? _initialisation;

  static Future<void> initialise() =>
      _initialisation ??= _loadPreference();

  static Future<void> _loadPreference() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      enabled.value = preferences.getBool(_preferenceKey) ?? true;
      await _correctPlayer.setReleaseMode(ReleaseMode.stop);
      await _incorrectPlayer.setReleaseMode(ReleaseMode.stop);
    } catch (error) {
      debugPrint('Sound effects initialisation: $error');
    }
  }

  static Future<void> setEnabled(bool value) async {
    enabled.value = value;
    if (!value) {
      try {
        await Future.wait([_correctPlayer.stop(), _incorrectPlayer.stop()]);
      } catch (error) {
        debugPrint('Unable to stop sound effects: $error');
      }
    }
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_preferenceKey, value);
    } catch (error) {
      debugPrint('Unable to save sound preference: $error');
    }
  }

  static void correct() => _play(_correctPlayer, 'audio/happy_victory.wav');
  static void incorrect() => _play(_incorrectPlayer, 'audio/arcade_incorrect.wav');

  static void _play(AudioPlayer player, String path) {
    // Fire-and-forget. No audio failure should affect a score or a navigation.
    _playSafely(player, path);
  }

  static Future<void> _playSafely(AudioPlayer player, String path) async {
    await initialise();
    if (!enabled.value) return;
    try {
      await player.stop();
      if (enabled.value) await player.play(AssetSource(path));
    } catch (error) {
      debugPrint('Unable to play feedback sound ($path): $error');
    }
  }
}
