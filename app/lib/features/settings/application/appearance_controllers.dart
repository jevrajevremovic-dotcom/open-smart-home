import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_locales.dart';
import '../../../core/storage/app_preferences.dart';

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(appPreferencesProvider).themeMode;

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(appPreferencesProvider).setThemeMode(mode);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// Selected app language; `null` follows the system language.
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() =>
      AppLocales.fromTag(ref.watch(appPreferencesProvider).localeTag);

  Future<void> set(Locale? locale) async {
    state = locale;
    await ref
        .read(appPreferencesProvider)
        .setLocaleTag(locale == null ? null : AppLocales.toTag(locale));
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);
