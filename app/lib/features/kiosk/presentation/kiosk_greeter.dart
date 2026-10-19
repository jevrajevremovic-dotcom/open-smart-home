import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/l10n.dart';
import '../../../app/theme/app_theme.dart';
import '../../assist/application/voice_providers.dart';
import '../../dashboard/application/home_sentence.dart';
import '../../devices/application/device_providers.dart';
import '../../devices/data/home_state_repository.dart';
import '../../household/application/household_providers.dart';
import '../../household/family_messages.dart';
import '../../household/presentation/person_avatar.dart';
import '../application/kiosk_controller.dart';

/// When someone comes home (their person in Home Assistant becomes
/// `home`), the kiosk wakes, says hello, and shows — and reads — the
/// household messages left for them.
class KioskGreeter extends ConsumerStatefulWidget {
  const KioskGreeter({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<KioskGreeter> createState() => _KioskGreeterState();
}

class _KioskGreeterState extends ConsumerState<KioskGreeter> {
  String? _person;
  Timer? _hide;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  void _greet(String personId) {
    final name = ref.read(deviceProvider(personId))?.name;
    if (name == null) return;
    _hide?.cancel();
    setState(() => _person = personId);
    _hide = Timer(const Duration(seconds: 20), _dismiss);
    if (ref.read(kioskDimmedProvider)) {
      ref.read(kioskDimmedProvider.notifier).set(false);
    }
    final speech = ref.read(speechOutputProvider);
    if (!speech.supported) return;
    final l10n = context.l10n;
    final messages = [
      for (final m in ref.read(familyMessagesProvider))
        if (m.isFor(personId)) m.text,
    ];
    unawaited(
      speech
          .speak(
            [
              l10n.welcomeHome(name),
              for (final m in messages) '${l10n.familyMessages}: $m',
            ].join(' '),
            languageTag: l10n.localeName,
          )
          .catchError((Object _) => false),
    );
  }

  void _dismiss() {
    _hide?.cancel();
    if (mounted && _person != null) setState(() => _person = null);
  }

  @override
  Widget build(BuildContext context) {
    final enabled =
        ref.watch(kioskSettingsProvider.select((s) => s.greetPeople)) &&
        ref.watch(kioskActiveProvider);
    if (enabled) {
      final people = ref.watch(peopleIdsProvider);
      ref.listen(
        homeSnapshotProvider.select(
          (s) => {for (final id in people) id: s.devices[id]?.state.raw},
        ),
        (before, now) {
          // Only real arrivals: not the first load or a reconnect.
          if (before == null ||
              ref.read(syncStatusProvider) != SyncStatus.live) {
            return;
          }
          for (final MapEntry(:key, :value) in now.entries) {
            final was = before[key];
            if (value == 'home' && was != null && was != 'home') {
              _greet(key);
              return;
            }
          }
        },
      );
    }
    final person = _person;
    return Stack(
      children: [
        widget.child,
        if (person != null)
          Positioned(
            top: 24,
            left: 24,
            right: 24,
            child: SafeArea(
              child: Center(
                child: Theme(
                  data: AppTheme.dark(),
                  child: _Welcome(personId: person, onClose: _dismiss),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Welcome extends ConsumerWidget {
  const _Welcome({required this.personId, required this.onClose});

  final String personId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final name = ref.watch(deviceProvider(personId))?.name ?? '';
    final messages = [
      for (final m in ref.watch(familyMessagesProvider))
        if (m.isFor(personId)) m,
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Material(
        key: const Key('kioskWelcome'),
        color: theme.colorScheme.surfaceContainerHigh,
        elevation: 12,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  PersonAvatar(personId: personId, size: 56),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.welcomeHome(name),
                          style: theme.textTheme.headlineSmall,
                        ),
                        Text(
                          ref.watch(homeSentenceProvider(l10n)),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('kioskWelcomeClose'),
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              for (final m in messages.take(3))
                FamilyMessageTile(key: ValueKey(m.id), message: m),
            ],
          ),
        ),
      ),
    );
  }
}
