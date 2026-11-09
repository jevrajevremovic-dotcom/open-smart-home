import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/l10n.dart';

import 'package:intl/intl.dart';

import '../../../core/security/pin_hasher.dart';
import '../../devices/application/device_providers.dart';
import '../../kiosk/presentation/pin_dialog.dart';
import '../application/restricted_mode.dart';

/// Shown instead of the settings while the mode is on.
class RestrictedActiveCard extends ConsumerWidget {
  const RestrictedActiveCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      key: const Key('restrictedActive'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.child_care, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.restrictedActive,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (ref.watch(restrictedModeProvider).until case final until?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.guestUntil(
                    DateFormat.MMMd(l10n.localeName).add_Hm().format(until),
                  ),
                  key: const Key('restrictedUntil'),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('restrictedDisable'),
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => PinEntryDialog(
                  title: l10n.kioskEnterPin,
                  onSubmit: (pin) async =>
                      await ref
                          .read(restrictedModeProvider.notifier)
                          .disable(pin)
                      ? null
                      : l10n.kioskWrongPin,
                ),
              ),
              icon: const Icon(Icons.lock_open),
              label: Text(l10n.restrictedDisable),
            ),
          ],
        ),
      ),
    );
  }
}

/// Entry in Settings → Security.
class RestrictedSettingsTile extends StatelessWidget {
  const RestrictedSettingsTile({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
    key: const Key('restrictedSettings'),
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.child_care),
    title: Text(context.l10n.restrictedTitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const _RestrictedSetupScreen()),
    ),
  );
}

/// How long a guest may use the app.
enum GuestTime { always, hours2, midnight, day, days3, week }

DateTime? guestEnd(GuestTime t, DateTime now) => switch (t) {
  GuestTime.always => null,
  GuestTime.hours2 => now.add(const Duration(hours: 2)),
  GuestTime.midnight => DateTime(now.year, now.month, now.day + 1),
  GuestTime.day => now.add(const Duration(days: 1)),
  GuestTime.days3 => now.add(const Duration(days: 3)),
  GuestTime.week => now.add(const Duration(days: 7)),
};

class _RestrictedSetupScreen extends ConsumerStatefulWidget {
  const _RestrictedSetupScreen();

  @override
  ConsumerState<_RestrictedSetupScreen> createState() =>
      _RestrictedSetupScreenState();
}

class _RestrictedSetupScreenState
    extends ConsumerState<_RestrictedSetupScreen> {
  GuestTime _time = GuestTime.always;

  /// Empty: every room.
  final Set<String> _rooms = {};

  Future<void> _enable(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    String? first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => PinEntryDialog(
        title: l10n.kioskSetPin,
        helper: l10n.kioskPinHint,
        onSubmit: (pin) async {
          if (!PinHasher.validPin.hasMatch(pin)) return l10n.kioskPinInvalid;
          first = pin;
          return null;
        },
      ),
    );
    if (ok != true || first == null || !context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => PinEntryDialog(
        title: l10n.kioskPinConfirm,
        onSubmit: (pin) async {
          if (pin != first) return l10n.kioskPinMismatch;
          await ref
              .read(restrictedModeProvider.notifier)
              .enable(
                pin,
                rooms: _rooms.isEmpty ? null : (_rooms.toList()..sort()),
                until: guestEnd(_time, DateTime.now()),
              );
          return null;
        },
      ),
    );
    if (confirmed == true && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final s = ref.watch(restrictedModeProvider);
    final rooms = ref.watch(roomsProvider);
    final controller = ref.read(restrictedModeProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.restrictedTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.restrictedHint),
          const SizedBox(height: 16),
          SwitchListTile(
            key: const Key('restrictedHideSecurity'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.restrictedHideSecurity),
            value: s.hideSecurity,
            onChanged: (v) => controller.setOptions(hideSecurity: v),
          ),
          SwitchListTile(
            key: const Key('restrictedHideCameras'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.restrictedHideCameras),
            value: s.hideCameras,
            onChanged: (v) => controller.setOptions(hideCameras: v),
          ),
          if (rooms.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l10n.guestRooms, style: theme.textTheme.titleSmall),
            Text(
              _rooms.isEmpty ? l10n.guestRoomsAll : l10n.guestRoomsSome,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final r in rooms)
                  FilterChip(
                    key: ValueKey('guestRoom-${r.id}'),
                    label: Text(r.name),
                    selected: _rooms.contains(r.id),
                    onSelected: (v) => setState(
                      () => v ? _rooms.add(r.id) : _rooms.remove(r.id),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(l10n.guestTime, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final t in GuestTime.values)
                ChoiceChip(
                  key: ValueKey('guestTime-${t.name}'),
                  label: Text(switch (t) {
                    GuestTime.always => l10n.guestTimeAlways,
                    GuestTime.hours2 => l10n.guestTimeHours(2),
                    GuestTime.midnight => l10n.guestTimeMidnight,
                    GuestTime.day => l10n.guestTimeDays(1),
                    GuestTime.days3 => l10n.guestTimeDays(3),
                    GuestTime.week => l10n.guestTimeDays(7),
                  }),
                  selected: _time == t,
                  onSelected: (_) => setState(() => _time = t),
                ),
            ],
          ),
          if (_time != GuestTime.always)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l10n.guestTimeHint, style: theme.textTheme.bodySmall),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('restrictedEnable'),
            onPressed: () => _enable(context, ref),
            icon: const Icon(Icons.child_care),
            label: Text(l10n.restrictedEnable),
          ),
        ],
      ),
    );
  }
}
