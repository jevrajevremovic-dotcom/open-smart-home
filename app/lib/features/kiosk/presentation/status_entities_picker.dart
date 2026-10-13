import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/l10n.dart';
import '../../devices/application/device_providers.dart';
import '../../devices/domain/device_kind.dart';
import '../../devices/presentation/device_presentation.dart';
import '../data/kiosk_settings.dart';

/// Lets the user pick the entities shown as chips at the top of the kiosk.
/// Returns the new selection, or `null` when cancelled.
Future<List<String>?> showStatusEntitiesPicker(
  BuildContext context,
  List<String> current,
) => showDialog<List<String>>(
  context: context,
  builder: (_) => _Picker(initial: current),
);

class _Picker extends ConsumerStatefulWidget {
  const _Picker({required this.initial});

  final List<String> initial;

  @override
  ConsumerState<_Picker> createState() => _PickerState();
}

class _PickerState extends ConsumerState<_Picker> {
  late final List<String> _selected = [...widget.initial];
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final devices = ref.watch(homeSnapshotProvider.select((s) => s.devices));
    final q = _query.trim().toLowerCase();
    final candidates =
        devices.values
            .where(
              (d) =>
                  !d.kind.isRoutine &&
                  d.kind != DeviceKind.unknown &&
                  d.kind != DeviceKind.person &&
                  (q.isEmpty ||
                      d.name.toLowerCase().contains(q) ||
                      d.id.toLowerCase().contains(q)),
            )
            .toList()
          ..sort((a, b) {
            // Selected first, in their order; then by name.
            final ia = _selected.indexOf(a.id);
            final ib = _selected.indexOf(b.id);
            if (ia != -1 || ib != -1) {
              if (ia == -1) return 1;
              if (ib == -1) return -1;
              return ia.compareTo(ib);
            }
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
    final full = _selected.length >= KioskSettings.maxStatusEntities;

    return AlertDialog(
      title: Text(l10n.kioskStatusEntities),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 480,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.kioskStatusEntitiesHint(KioskSettings.maxStatusEntities),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('statusEntitiesSearch'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.searchHint,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: candidates.length,
                itemBuilder: (context, i) {
                  final d = candidates[i];
                  final checked = _selected.contains(d.id);
                  return CheckboxListTile(
                    key: ValueKey('status-${d.id}'),
                    value: checked,
                    secondary: Icon(DevicePresentation.icon(d)),
                    title: Text(d.name),
                    subtitle: Text(DevicePresentation.status(l10n, d)),
                    onChanged: !checked && full
                        ? null
                        : (v) => setState(
                            () => v == true
                                ? _selected.add(d.id)
                                : _selected.remove(d.id),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('statusEntitiesDone'),
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(l10n.done),
        ),
      ],
    );
  }
}
