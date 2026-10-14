import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_locales.dart';
import '../../favorites/application/favorites_controller.dart';
import '../../kiosk/application/kiosk_controller.dart';
import '../../kiosk/data/kiosk_settings.dart';
import '../application/appearance_controllers.dart';

/// App settings as a small JSON text to move to another device.
///
/// Never included: tokens and server credentials, PINs, the kiosk photo,
/// and privacy choices (location, voice) – those are asked again on the
/// new device.
abstract final class SettingsBackup {
  static const _marker = 'open-smart-home-settings';
  static const _version = 1;

  static String export(WidgetRef ref) {
    final kiosk = ref.read(kioskSettingsProvider);
    final locale = ref.read(localeProvider);
    return const JsonEncoder.withIndent('  ').convert({
      'app': _marker,
      'version': _version,
      'theme': ref.read(themeModeProvider).name,
      'language': locale == null ? null : AppLocales.toTag(locale),
      'favorites': ref.read(favoritesProvider),
      'kiosk': {
        'background': kiosk.background.name,
        'liteEffects': kiosk.liteEffects,
        'showCameras': kiosk.showCameras,
        'showCalendar': kiosk.showCalendar,
        'statusEntityIds': kiosk.statusEntityIds,
        'keepScreenOn': kiosk.keepScreenOn,
        'dimAfterSeconds': kiosk.dimAfter.inSeconds,
        'returnHomeAfterSeconds': kiosk.returnHomeAfter.inSeconds,
      },
    });
  }

  /// Applies [text]; `false` when it is not an Open Smart Home backup.
  static Future<bool> import(WidgetRef ref, String text) async {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      return false;
    }
    if (json is! Map || json['app'] != _marker || json['version'] != 1) {
      return false;
    }
    final themeName = json['theme'];
    final theme = ThemeMode.values
        .where((m) => m.name == themeName)
        .firstOrNull;
    if (theme != null) await ref.read(themeModeProvider.notifier).set(theme);
    if (json['language'] case final String tag) {
      await ref.read(localeProvider.notifier).set(AppLocales.fromTag(tag));
    }
    if (json['favorites'] case final List<Object?> favorites) {
      await ref.read(favoritesProvider.notifier).setOrder([
        for (final f in favorites)
          if (f is String) f,
      ]);
    }
    if (json['kiosk'] case final Map<String, Object?> k) {
      final current = ref.read(kioskSettingsProvider);
      final imported = KioskSettings.fromJson(k);
      await ref
          .read(kioskSettingsProvider.notifier)
          .update(
            (_) => imported.copyWith(
              // Keep this device's own PIN, photo and start-up choice.
              pinHash: current.pinHash,
              pinSalt: current.pinSalt,
              photoPath: current.photoPath,
              startInKiosk: current.startInKiosk,
            ),
          );
    }
    return true;
  }
}
