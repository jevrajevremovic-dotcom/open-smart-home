import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/app_locales.dart';
import '../../../app/localization/l10n.dart';
import '../application/appearance_controllers.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  static const _system = 'system';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(localeProvider);
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: _system, label: Text(l10n.languageSystem)),
        ButtonSegment(
          value: AppLocales.toTag(AppLocales.serbianLatin),
          label: Text(l10n.languageSerbian),
        ),
        ButtonSegment(
          value: AppLocales.toTag(AppLocales.english),
          label: Text(l10n.languageEnglish),
        ),
      ],
      selected: {current == null ? _system : AppLocales.toTag(current)},
      onSelectionChanged: (selection) {
        final tag = selection.single;
        ref
            .read(localeProvider.notifier)
            .set(tag == _system ? null : AppLocales.fromTag(tag));
      },
    );
  }
}

class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SegmentedButton<ThemeMode>(
      segments: [
        ButtonSegment(
          value: ThemeMode.system,
          icon: const Icon(Icons.brightness_auto_outlined),
          label: Text(l10n.themeSystem),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          icon: const Icon(Icons.light_mode_outlined),
          label: Text(l10n.themeLight),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: const Icon(Icons.dark_mode_outlined),
          label: Text(l10n.themeDark),
        ),
      ],
      selected: {ref.watch(themeModeProvider)},
      onSelectionChanged: (s) =>
          ref.read(themeModeProvider.notifier).set(s.single),
    );
  }
}
