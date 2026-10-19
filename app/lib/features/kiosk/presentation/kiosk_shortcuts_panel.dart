part of 'kiosk_panels.dart';

/// Favorite devices as large glass tiles. Tap switches (or activates),
/// long press opens the device.
class KioskShortcutsPanel extends ConsumerWidget {
  const KioskShortcutsPanel({
    super.key,
    this.scrollable = true,
    this.sceneIds = const [],
  });

  final bool scrollable;

  /// Scenes shown as chips under the title (when there is no room for a
  /// separate scenes panel).
  final List<String> sceneIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ids = ref.watch(existingFavoritesProvider);
    const delegate = SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 200,
      mainAxisExtent: 136,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
    );
    final Widget body = ids.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              l10n.kioskShortcutsEmpty,
              style: const TextStyle(color: GlassColors.muted),
            ),
          )
        : GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: !scrollable,
            physics: scrollable ? null : const NeverScrollableScrollPhysics(),
            gridDelegate: delegate,
            itemCount: ids.length,
            itemBuilder: (context, i) =>
                _ShortcutTile(key: ValueKey(ids[i]), deviceId: ids[i]),
          );
    return GlassPanel(
      key: const Key('kioskShortcuts'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: scrollable ? MainAxisSize.max : MainAxisSize.min,
        children: [
          GlassTitle(l10n.kioskShortcuts),
          if (sceneIds.isNotEmpty) ...[
            EdgeFade(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final id in sceneIds)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: KioskSceneChip(sceneId: id),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (scrollable)
            Expanded(
              child: EdgeFade(
                child: ids.isEmpty ? SingleChildScrollView(child: body) : body,
              ),
            )
          else
            body,
        ],
      ),
    );
  }
}

class _ShortcutTile extends ConsumerStatefulWidget {
  const _ShortcutTile({super.key, required this.deviceId});

  final String deviceId;

  @override
  ConsumerState<_ShortcutTile> createState() => _ShortcutTileState();
}

class _ShortcutTileState extends ConsumerState<_ShortcutTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(deviceProvider(widget.deviceId));
    if (d == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final live = ref.watch(syncStatusProvider) == SyncStatus.live;
    final tone = DevicePresentation.tone(d);
    final accents = DeviceAccents.light; // pastel tiles read well on glass
    final swatch = switch (tone) {
      DeviceTone.active => accents.of(DevicePresentation.accent(d)),
      DeviceTone.warning => accents.warning,
      DeviceTone.critical => accents.critical,
      _ => null,
    };
    final status = DevicePresentation.status(l10n, d);

    void open() => context.push(AppRoutes.device(d.id, kiosk: true));
    Future<void> run(DeviceCommand c) async {
      setState(() => _busy = true);
      await runDeviceCommand(context, ref, d, c);
      if (mounted) setState(() => _busy = false);
    }

    final canToggle =
        d.available && live && DevicePresentation.hasQuickToggle(d);
    final canActivate =
        d.available && live && DevicePresentation.hasQuickActivate(d);
    final VoidCallback onTap = _busy
        ? () {}
        : canToggle
        ? () => run(d.state.isOn == true ? const TurnOff() : const TurnOn())
        : canActivate
        ? () => run(const Activate())
        : open;

    return Semantics(
      button: true,
      toggled: canToggle ? d.state.isOn == true : null,
      label: '${d.name}, $status',
      excludeSemantics: true,
      onLongPress: open,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: swatch?.container ?? GlassColors.fill,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: swatch == null ? GlassColors.border : Colors.transparent,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            onLongPress: open,
            child: Opacity(
              opacity: d.available ? 1 : 0.55,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      DevicePresentation.icon(d),
                      size: 30,
                      color: swatch?.icon ?? GlassColors.text,
                    ),
                    const Spacer(),
                    Text(
                      d.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: swatch?.onContainer ?? GlassColors.text,
                      ),
                    ),
                    Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: swatch?.onContainer ?? GlassColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scenes as large buttons.
class KioskScenesPanel extends ConsumerWidget {
  const KioskScenesPanel({
    super.key,
    required this.sceneIds,
    this.scrollable = true,
  });

  final List<String> sceneIds;
  final bool scrollable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return GlassPanel(
      key: const Key('kioskScenes'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassTitle(l10n.scenesTitle),
          _maybeScroll(
            scrollable,
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final id in sceneIds) KioskSceneChip(sceneId: id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A scene as a glass chip; tap activates it.
class KioskSceneChip extends ConsumerWidget {
  const KioskSceneChip({super.key, required this.sceneId});

  final String sceneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final d = ref.watch(deviceProvider(sceneId));
    if (d == null) return const SizedBox.shrink();
    return ActionChip(
      backgroundColor: GlassColors.fill,
      side: const BorderSide(color: GlassColors.border),
      avatar: const Icon(Icons.play_arrow_rounded, color: GlassColors.text),
      label: Text(d.name, style: const TextStyle(color: GlassColors.text)),
      onPressed: d.available
          ? () async {
              final messenger = ScaffoldMessenger.of(context);
              if (await runDeviceCommand(context, ref, d, const Activate())) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.sceneActivated(d.name))),
                );
              }
            }
          : null,
    );
  }
}

/// Scrolls inside a fixed-height panel; plain inside a scrolling page.
Widget _maybeScroll(bool scrollable, Widget child) =>
    scrollable ? Flexible(child: SingleChildScrollView(child: child)) : child;
