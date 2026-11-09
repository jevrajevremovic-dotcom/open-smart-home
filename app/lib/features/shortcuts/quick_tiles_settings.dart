import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/l10n.dart';
import '../devices/application/device_providers.dart';
import '../devices/presentation/device_presentation.dart';
import 'quick_tiles.dart';

/// Settings → Appearance: what each Quick Settings tile does.
class QuickTilesSettings extends ConsumerWidget {
  const QuickTilesSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platform = ref.watch(quickTilesPlatformProvider);
    if (!platform.supported) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final ids = ref.watch(quickTilesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text(l10n.quickTilesTitle, style: theme.textTheme.labelLarge),
        ),
        Text(l10n.quickTilesHint, style: theme.textTheme.bodySmall),
        for (var i = 0; i < quickTileCount; i++)
          _Slot(index: i, deviceId: ids[i]),
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text(l10n.carButtonsTitle, style: theme.textTheme.labelLarge),
        ),
        Text(l10n.carButtonsHint, style: theme.textTheme.bodySmall),
        for (final (i, id) in ref.watch(carButtonsProvider).indexed)
          _Slot(index: i, deviceId: id, car: true),
      ],
    );
  }
}

class _Slot extends ConsumerWidget {
  const _Slot({required this.index, this.deviceId, this.car = false});

  final int index;
  final String? deviceId;

  /// A button on the car screen rather than a tile.
  final bool car;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final d = deviceId == null ? null : ref.watch(deviceProvider(deviceId!));
    final slots = car ? carButtonsProvider : quickTilesProvider;
    return ListTile(
      key: ValueKey(car ? 'carButton-$index' : 'quickTile-$index'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        d == null ? Icons.add_box_outlined : DevicePresentation.icon(d),
      ),
      title: Text(
        car ? l10n.carButtonSlot(index + 1) : l10n.quickTileSlot(index + 1),
      ),
      subtitle: Text(d?.name ?? l10n.quickTileUnset),
      onTap: () async {
        final id = await showDialog<String>(
          context: context,
          builder: (_) => _PickDialog(index: index, car: car),
        );
        if (id != null) {
          await ref.read(slots.notifier).set(index, id);
        }
      },
      trailing: d == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!car)
                  TextButton(
                    key: ValueKey('quickTileAdd-$index'),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final added = await ref
                          .read(quickTilesPlatformProvider)
                          .requestAdd(index, d.name)
                          .catchError((Object _) => false);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            added
                                ? l10n.quickTileAdded
                                : l10n.quickTileAddManually(index + 1),
                          ),
                        ),
                      );
                    },
                    child: Text(l10n.quickTileAdd),
                  ),
                IconButton(
                  key: ValueKey(
                    car ? 'carButtonClear-$index' : 'quickTileClear-$index',
                  ),
                  tooltip: l10n.quickTileClear,
                  onPressed: () => ref.read(slots.notifier).set(index, null),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
    );
  }
}

class _PickDialog extends ConsumerStatefulWidget {
  const _PickDialog({required this.index, this.car = false});

  final int index;
  final bool car;

  @override
  ConsumerState<_PickDialog> createState() => _PickDialogState();
}

class _PickDialogState extends ConsumerState<_PickDialog> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final devices = ref.watch(homeSnapshotProvider.select((s) => s.devices));
    final list =
        devices.values
            .where(
              (d) =>
                  !d.isAuxiliary &&
                  (widget.car ? carCommand(d) : quickTileCommand(d)) != null &&
                  d.name.toLowerCase().contains(_q.toLowerCase()),
            )
            .toList()
          // Scenes first: they are what tiles are most used for.
          ..sort((a, b) {
            final r = (b.kind.isRoutine ? 1 : 0) - (a.kind.isRoutine ? 1 : 0);
            return r != 0 ? r : a.name.compareTo(b.name);
          });
    return AlertDialog(
      title: Text(
        widget.car
            ? l10n.carButtonChoose(widget.index + 1)
            : l10n.quickTileChoose(widget.index + 1),
      ),
      content: SizedBox(
        width: 420,
        height: 440,
        child: Column(
          children: [
            TextField(
              key: const Key('quickTileSearch'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.searchHint,
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final d in list)
                    ListTile(
                      key: ValueKey('quickTilePick-${d.id}'),
                      leading: Icon(DevicePresentation.icon(d)),
                      title: Text(d.name),
                      subtitle: Text(DevicePresentation.status(l10n, d)),
                      onTap: () => Navigator.of(context).pop(d.id),
                    ),
                ],
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
      ],
    );
  }
}
