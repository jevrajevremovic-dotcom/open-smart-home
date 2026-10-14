import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../alerts/alert_notifications.dart';
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
import '../../restricted/application/restricted_mode.dart';
import '../../restricted/presentation/restricted_settings.dart';
import '../data/settings_backup.dart';
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

    // Child / guest mode: settings are closed until the PIN is entered.
    if (ref.watch(restrictedModeProvider).enabled) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [RestrictedActiveCard()],
        ),
      );
    }
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
                  const _HomesList(),
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
                  if (!(ref.watch(deviceAuthAvailableProvider).value ?? false))
                    section(l10n.securitySection),
                  const RestrictedSettingsTile(),
                  if (ref.watch(alertNotifierProvider).supported)
                    SwitchListTile(
                      key: const Key('alertNotifySwitch'),
                      contentPadding: EdgeInsets.zero,
                      secondary: const Icon(
                        Icons.notifications_active_outlined,
                      ),
                      title: Text(l10n.alertsSetting),
                      subtitle: Text(l10n.alertsSettingHint),
                      value: ref.watch(alertNotificationsProvider),
                      onChanged: (v) async {
                        final alerts = ref.read(
                          alertNotificationsProvider.notifier,
                        );
                        if (!v) return alerts.disable();
                        final messenger = ScaffoldMessenger.of(context);
                        if (!await alerts.enable()) {
                          messenger
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(l10n.alertsPermissionDenied),
                              ),
                            );
                        }
                      },
                    ),
                  section(l10n.backupSection),
                  Text(l10n.backupHint, style: textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        key: const Key('backupCopy'),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await Clipboard.setData(
                            ClipboardData(text: SettingsBackup.export(ref)),
                          );
                          messenger
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(content: Text(l10n.backupCopied)),
                            );
                        },
                        icon: const Icon(Icons.copy),
                        label: Text(l10n.backupCopy),
                      ),
                      OutlinedButton.icon(
                        key: const Key('backupPaste'),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final text = (await Clipboard.getData('text/plain'))
                              ?.text;
                          final ok =
                              text != null &&
                              await SettingsBackup.import(ref, text);
                          messenger
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok ? l10n.backupImported : l10n.backupInvalid,
                                ),
                              ),
                            );
                        },
                        icon: const Icon(Icons.paste),
                        label: Text(l10n.backupPaste),
                      ),
                    ],
                  ),
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

/// Saved homes (several Home Assistant servers): switch or add one.
class _HomesList extends ConsumerWidget {
  const _HomesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final homes = ref.watch(savedHomesProvider).value ?? const [];
    final active = ref.watch(activeProfileProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (homes.length > 1) ...[
          Text(l10n.homesTitle, style: Theme.of(context).textTheme.labelLarge),
          for (final h in homes)
            ListTile(
              key: ValueKey('home-${h.profile.id}'),
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                h.profile.id == active?.id
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(h.name),
              subtitle: Text(h.profile.address.host),
              onTap: h.profile.id == active?.id
                  ? null
                  : () => ref
                        .read(sessionControllerProvider.notifier)
                        .switchTo(h.profile),
            ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('addHome'),
            onPressed: () {
              ref.read(addingHomeProvider.notifier).set(true);
              context.go(AppRoutes.connectServer);
            },
            icon: const Icon(Icons.add_home_outlined),
            label: Text(l10n.addHome),
          ),
        ),
      ],
    );
  }
}
