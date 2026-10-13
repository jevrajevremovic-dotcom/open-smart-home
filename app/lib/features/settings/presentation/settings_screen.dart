import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/localization/l10n.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../authentication/application/session_controller.dart';
import '../../devices/application/device_providers.dart';
import '../../kiosk/presentation/kiosk_settings_section.dart';
import '../../app_lock/application/app_lock.dart';
import '../../assist/application/voice_providers.dart';
import '../../weather/application/weather_providers.dart';
import '../../weather/presentation/weather_card.dart';
import 'language_selector.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(activeProfileProvider);
    final version = ref.watch(serverConfigProvider).value?.version;
    final deviceCount = ref.watch(
      visibleDeviceIdsProvider.select((ids) => ids.length),
    );
    final roomCount = ref.watch(roomsProvider.select((r) => r.length));
    final textTheme = Theme.of(context).textTheme;
    final critical = context.statusColors.critical;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
      child: Text(title, style: textTheme.titleSmall),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: MockModeBanner(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ConstrainedContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  section(l10n.appearance),
                  Text(l10n.theme, style: textTheme.labelLarge),
                  const SizedBox(height: 8),
                  const ThemeModeSelector(),
                  const SizedBox(height: 16),
                  Text(l10n.language, style: textTheme.labelLarge),
                  const SizedBox(height: 8),
                  const LanguageSelector(),
                  section(l10n.serverSection),
                  if (profile != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        profile.address.isSecure
                            ? Icons.lock_outline
                            : Icons.dns_outlined,
                      ),
                      title: Text(profile.address.toString()),
                      subtitle: Text(
                        [
                          if (version != null) l10n.serverVersion(version),
                          if (deviceCount > 0)
                            l10n.devicesInRooms(deviceCount, roomCount),
                        ].join('\n'),
                      ),
                    ),
                  ListTile(
                    key: const Key('settingsAddDevice'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.add_circle_outline),
                    title: Text(l10n.addDeviceTitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.addDevice),
                  ),
                  OutlinedButton.icon(
                    key: const Key('signOutButton'),
                    onPressed: () => _confirmSignOut(context, ref),
                    icon: const Icon(Icons.logout),
                    label: Text(l10n.signOut),
                  ),
                  section(l10n.kioskSection),
                  const KioskSettingsSection(),
                  if (ref.watch(deviceAuthAvailableProvider).value ??
                      false) ...[
                    section(l10n.securitySection),
                    SwitchListTile(
                      key: const Key('appLockSwitch'),
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.fingerprint),
                      title: Text(l10n.appLockSetting),
                      subtitle: Text(l10n.appLockSettingHint),
                      value: ref.watch(appLockSettingsProvider).lockApp,
                      onChanged: (v) async {
                        // Prove it works before relying on it.
                        if (v &&
                            !await ref
                                .read(deviceAuthProvider)
                                .authenticate(l10n.appLockReason)) {
                          return;
                        }
                        await ref
                            .read(appLockSettingsProvider.notifier)
                            .update((s) => s.copyWith(lockApp: v));
                      },
                    ),
                    SwitchListTile(
                      key: const Key('appLockCriticalSwitch'),
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.lock_person_outlined),
                      title: Text(l10n.appLockCriticalSetting),
                      subtitle: Text(l10n.appLockCriticalSettingHint),
                      value: ref.watch(appLockSettingsProvider).confirmCritical,
                      onChanged: (v) => ref
                          .read(appLockSettingsProvider.notifier)
                          .update((s) => s.copyWith(confirmCritical: v)),
                    ),
                  ],
                  section(l10n.privacySection),
                  if (ref.watch(deviceLocatorProvider).isSupported)
                    SwitchListTile(
                      key: const Key('deviceWeatherSwitch'),
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(Icons.my_location_outlined),
                      title: Text(l10n.weatherEnableDevice),
                      subtitle: Text(l10n.weatherDeviceSettingHint),
                      value: ref.watch(deviceWeatherEnabledProvider),
                      onChanged: (v) => v
                          ? enableDeviceWeather(context, ref)
                          : ref
                                .read(deviceWeatherEnabledProvider.notifier)
                                .set(false),
                    ),
                  SwitchListTile(
                    key: const Key('voiceCloudSwitch'),
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.mic_none),
                    title: Text(l10n.voiceCloudSetting),
                    subtitle: Text(l10n.voiceCloudSettingHint),
                    value: ref.watch(voiceCloudAllowedProvider) ?? false,
                    onChanged: (v) =>
                        ref.read(voiceCloudAllowedProvider.notifier).set(v),
                  ),
                  SwitchListTile(
                    key: const Key('homeWeatherSwitch'),
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.cloud_outlined),
                    title: Text(l10n.weatherHomeLocationSetting),
                    subtitle: Text(l10n.weatherHomeLocationSettingHint),
                    value: ref.watch(homeLocationWeatherEnabledProvider),
                    onChanged: (v) => v
                        ? enableHomeLocationWeather(context, ref)
                        : ref
                              .read(homeLocationWeatherEnabledProvider.notifier)
                              .set(false),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _confirmDeleteAll(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: critical,
                      side: BorderSide(color: critical),
                    ),
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: Text(l10n.deleteAllData),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await _confirm(
      context,
      title: l10n.signOutConfirmTitle,
      body: l10n.signOutConfirmBody,
      action: l10n.signOut,
    );
    if (ok) await ref.read(sessionControllerProvider.notifier).signOut();
  }

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await _confirm(
      context,
      title: l10n.deleteAllConfirmTitle,
      body: l10n.deleteAllConfirmBody,
      action: l10n.delete,
      destructive: true,
    );
    if (ok) {
      await ref.read(sessionControllerProvider.notifier).deleteAllLocalData();
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = context.statusColors;
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              key: const Key('confirmDialogAction'),
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: colors.critical,
                      foregroundColor: colors.onCritical,
                    )
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(action),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
