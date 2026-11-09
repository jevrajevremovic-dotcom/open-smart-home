import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/l10n.dart';
import '../application/restricted_mode.dart';

/// Covers the whole app once a guest's time is up; only the PIN of the
/// one who set it up opens it again (and ends the guest mode).
class GuestExpiredGate extends ConsumerWidget {
  const GuestExpiredGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expired = ref.watch(guestExpiredProvider);
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          excluding: expired,
          child: Offstage(offstage: expired, child: child),
        ),
        // Above the app's navigator: the PIN field brings its own overlay
        // (text selection needs one).
        if (expired)
          Positioned.fill(
            child: Overlay(
              initialEntries: [OverlayEntry(builder: (_) => const _Expired())],
            ),
          ),
      ],
    );
  }
}

class _Expired extends ConsumerStatefulWidget {
  const _Expired();

  @override
  ConsumerState<_Expired> createState() => _ExpiredState();
}

class _ExpiredState extends ConsumerState<_Expired> {
  final _pin = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin
      ..clear()
      ..dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final ok = await ref
        .read(restrictedModeProvider.notifier)
        .disable(_pin.text);
    _pin.clear();
    if (!ok && mounted) setState(() => _error = l10n.kioskWrongPin);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Material(
      key: const Key('guestExpired'),
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_off_outlined,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.guestExpired,
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.guestExpiredHint, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  TextField(
                    key: const Key('guestExpiredPin'),
                    controller: _pin,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28, letterSpacing: 12),
                    decoration: InputDecoration(
                      labelText: l10n.kioskEnterPin,
                      errorText: _error,
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const Key('guestExpiredUnlock'),
                    onPressed: _submit,
                    icon: const Icon(Icons.lock_open),
                    label: Text(l10n.restrictedDisable),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
