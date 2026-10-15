import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Microphone loudness levels (one per 20 ms frame, 0…1) for clap
/// detection. No audio is recorded or leaves the device.
abstract interface class ClapPlatform {
  bool get supported;

  /// Asks for the microphone permission; `true` when granted.
  Future<bool> requestPermission();

  /// Listening starts with the subscription and stops when it is cancelled.
  Stream<double> levels();
}

/// MainActivity's `audio_level` stream (AudioLevelHandler.kt).
class AndroidClapPlatform implements ClapPlatform {
  static const _levels = EventChannel('org.opensmarthome/audio_level');
  static const _microphone = MethodChannel('org.opensmarthome/microphone');

  @override
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> requestPermission() async {
    try {
      return await _microphone.invokeMethod<bool>('request') ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Stream<double> levels() =>
      _levels.receiveBroadcastStream().map((e) => e is num ? e.toDouble() : 0);
}

final clapPlatformProvider = Provider<ClapPlatform>(
  (ref) => AndroidClapPlatform(),
);
