part of 'dashboard_screen.dart';

class DashboardSummaryRow extends ConsumerWidget {
  const DashboardSummaryRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = ref.watch(dashboardSummaryProvider);
    final power = s.powerDeviceId == null
        ? null
        : ref.watch(deviceProvider(s.powerDeviceId!));
    final locale = l10n.localeName;
    final colors = context.statusColors;
    final outdoor = ref.watch(
      homeWeatherProvider.select((w) => w?.now.temperature),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Two equal columns on phones; natural widths on larger screens.
        final compact =
            WindowSize.fromWidth(constraints.maxWidth) == WindowSize.compact;
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: _SummaryWrap(
            fullWidth: compact ? constraints.maxWidth : null,
            children: [
              _SummaryCard(
                icon: Icons.thermostat,
                label: l10n.summaryTemperature,
                value: s.averageTemperature == null
                    ? null
                    : formatNumber(locale, s.averageTemperature!, unit: '°'),
              ),
              if (outdoor != null)
                _SummaryCard(
                  icon: Icons.wb_cloudy_outlined,
                  label: l10n.summaryOutdoor,
                  value: formatNumber(locale, outdoor, unit: '°'),
                ),
              _SummaryCard(
                icon: Icons.water_drop_outlined,
                label: l10n.summaryHumidity,
                value: s.averageHumidity == null
                    ? null
                    : formatNumber(locale, s.averageHumidity!, unit: '%'),
              ),
              if (s.lightsTotal > 0)
                _SummaryCard(
                  key: const Key('summaryLights'),
                  icon: Icons.lightbulb_outline,
                  label: l10n.summaryLights,
                  value: l10n.lightsOnOf(s.lightsOn, s.lightsTotal),
                  onTap: () => showAllLightsSheet(context),
                ),
              _SummaryCard(
                icon: Icons.door_front_door_outlined,
                label: l10n.summaryOpenings,
                value: s.openingIds.isEmpty
                    ? l10n.summaryOpeningsClosed
                    : l10n.summaryOpeningsOpen(s.openingIds.length),
                color: s.openingIds.isEmpty ? null : colors.warning,
              ),
              if (power != null)
                _SummaryCard(
                  icon: Icons.bolt,
                  label: l10n.summaryPower,
                  value: DevicePresentation.sensorValue(l10n, power.state),
                  tooltip: power.name,
                ),
              _SummaryCard(
                icon: Icons.warning_amber_rounded,
                label: l10n.summaryAlerts,
                value: '${s.criticalIds.length}',
                color: s.criticalIds.isEmpty ? null : colors.critical,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A link to a secondary screen (energy, calendar, activity). On phones the
/// icon sits above the label so three fit in a row.
class _QuickLink extends StatelessWidget {
  const _QuickLink({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.vertical = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool vertical;

  _QuickLink stacked() => _QuickLink(
    key: key,
    onPressed: onPressed,
    icon: icon,
    label: label,
    vertical: true,
  );

  @override
  Widget build(BuildContext context) {
    if (!vertical) {
      return FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(icon),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// Lays out summary cards: two equal columns on phones, where an odd last
/// card takes the whole row; natural widths otherwise.
class _SummaryWrap extends StatelessWidget {
  const _SummaryWrap({required this.fullWidth, required this.children});

  /// The row width on phones; `null` on larger screens.
  final double? fullWidth;
  final List<_SummaryCard> children;

  @override
  Widget build(BuildContext context) {
    final full = fullWidth;
    final half = full == null ? null : (full - 12) / 2;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final (i, card) in children.indexed)
          card.withWidth(
            full != null && children.length.isOdd && i == children.length - 1
                ? full
                : half,
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    super.key,
    this.onTap,
    this.width,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.tooltip,
  });

  final double? width;
  final IconData icon;
  final String label;

  /// `null` = no such data in this home.
  final String? value;
  final Color? color;
  final String? tooltip;
  final VoidCallback? onTap;

  _SummaryCard withWidth(double? width) => _SummaryCard(
    key: key,
    onTap: onTap,
    width: width,
    icon: icon,
    label: label,
    value: value,
    color: color,
    tooltip: tooltip,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = color ?? theme.colorScheme.primary;
    final card = Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          // Bounded width so long labels wrap instead of overflowing.
          constraints: width != null
              ? BoxConstraints.tightFor(width: width)
              : const BoxConstraints(minWidth: 150, maxWidth: 220),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: accent),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      // A changed value fades in rather than jumping.
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.centerLeft,
                          children: [...previous, ?current],
                        ),
                        child: Text(
                          value ?? '—',
                          key: ValueKey(value),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          semanticsLabel: value ?? l10n.valueNotAvailable,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? card : Tooltip(message: tooltip, child: card);
  }
}
