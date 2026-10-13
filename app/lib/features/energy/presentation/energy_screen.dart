import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/l10n.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../devices/application/device_providers.dart';
import '../../devices/domain/device_kind.dart';
import '../../devices/presentation/device_grid.dart';
import '../../devices/presentation/device_presentation.dart';
import '../application/energy_providers.dart';
import '../data/energy_repository.dart';
import '../data/tariff.dart';
import 'energy_chart.dart';
import 'energy_format.dart';

/// Energy overview: live power, consumption for today / this week / this
/// month, grid, solar, battery, gas, top consumers and a cost estimate.
/// Everything comes from Home Assistant; nothing is estimated except the
/// cost, which is labelled as such and needs a tariff from the user.
class EnergyScreen extends ConsumerWidget {
  const EnergyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final range = ref.watch(energyRangeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.energyTitle)),
      body: MockModeBanner(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(energyPrefsProvider);
            await ref.read(energyReportProvider.future).catchError((_) => null);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ConstrainedContent(
                maxWidth: 900,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _CurrentPower(),
                    const SizedBox(height: 8),
                    SegmentedButton<EnergyRange>(
                      segments: [
                        ButtonSegment(
                          value: EnergyRange.today,
                          label: Text(l10n.energyToday),
                        ),
                        ButtonSegment(
                          value: EnergyRange.week,
                          label: Text(l10n.energyWeek),
                        ),
                        ButtonSegment(
                          value: EnergyRange.month,
                          label: Text(l10n.energyMonth),
                        ),
                      ],
                      selected: {range},
                      onSelectionChanged: (s) => ref
                          .read(energyRangeProvider.notifier)
                          .select(s.single),
                    ),
                    const SizedBox(height: 8),
                    const _ReportSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Live power from power sensors (not part of statistics, always current).
class _CurrentPower extends ConsumerWidget {
  const _CurrentPower();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final devices = ref.watch(homeSnapshotProvider.select((s) => s.devices));
    final meters =
        devices.values
            .where(
              (d) =>
                  d.kind == DeviceKind.powerMeter &&
                  d.available &&
                  d.state.numericValue != null,
            )
            .toList()
          ..sort(
            (a, b) => b.state.numericValue!.compareTo(a.state.numericValue!),
          );
    if (meters.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l10n.energyCurrentPower),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final m in meters.take(4))
              _StatTile(
                icon: Icons.bolt,
                label: m.name,
                value: DevicePresentation.sensorValue(l10n, m.state),
              ),
          ],
        ),
      ],
    );
  }
}

class _ReportSection extends ConsumerWidget {
  const _ReportSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final report = ref.watch(energyReportProvider);
    return switch (report) {
      AsyncData(value: null) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: InlineNotice.info(l10n.energyNotConfigured),
      ),
      AsyncData(:final value?) => _Report(report: value),
      AsyncError(error: EnergyUnavailableOffline()) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: InlineNotice.warning(l10n.energyOffline),
      ),
      AsyncError(:final error) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: InlineNotice.error(
          error is AppFailure
              ? failureMessage(l10n, error)
              : l10n.failureUnknown,
        ),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _Report extends ConsumerWidget {
  const _Report({required this.report});

  final EnergyReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final tariff = ref.watch(tariffProvider);
    String kwh(double v) => formatKwh(locale, v);
    final cost = tariff?.estimate(
      gridImport: report.gridImport,
      gridExport: report.gridExport,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (report.consumption != null)
              _StatTile(
                icon: Icons.home_outlined,
                label: l10n.energyConsumption,
                value: kwh(report.consumption!),
              ),
            if (report.gridImport != null)
              _StatTile(
                icon: Icons.electrical_services,
                label: l10n.energyFromGrid,
                value: kwh(report.gridImport!),
              ),
            if (report.gridExport != null)
              _StatTile(
                icon: Icons.upload_outlined,
                label: l10n.energyToGrid,
                value: kwh(report.gridExport!),
              ),
            if (report.solar != null)
              _StatTile(
                icon: Icons.solar_power_outlined,
                label: l10n.energySolar,
                value: kwh(report.solar!),
              ),
            if (report.batteryCharge != null)
              _StatTile(
                icon: Icons.battery_charging_full,
                label: l10n.energyBatteryCharge,
                value: kwh(report.batteryCharge!),
              ),
            if (report.batteryDischarge != null)
              _StatTile(
                icon: Icons.battery_std,
                label: l10n.energyBatteryDischarge,
                value: kwh(report.batteryDischarge!),
              ),
            if (report.gas != null)
              _StatTile(
                icon: Icons.local_fire_department_outlined,
                label: l10n.energyGas,
                value: formatNumber(locale, report.gas!, unit: 'm³'),
              ),
            if (cost != null)
              _StatTile(
                key: const Key('energyCost'),
                icon: Icons.payments_outlined,
                label: l10n.energyCostEstimate,
                value: formatMoney(locale, cost, tariff!.currency),
                onTap: () => _editTariff(context, ref, tariff),
              ),
          ],
        ),
        if (tariff == null && report.gridImport != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('energySetTariff'),
              onPressed: () => _editTariff(context, ref, null),
              icon: const Icon(Icons.payments_outlined),
              label: Text(l10n.energySetTariff),
            ),
          ),
        if (report.consumption != null) ...[
          SectionHeader(
            report.range == EnergyRange.today
                ? l10n.energyPerHour
                : l10n.energyPerDay,
          ),
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ConsumptionChart(report: report),
            ),
          ),
        ],
        SectionHeader(l10n.energyTopConsumers),
        if (report.devices.isEmpty)
          InlineNotice.info(l10n.energyNoDevices)
        else
          _TopConsumers(report: report),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _TopConsumers extends StatelessWidget {
  const _TopConsumers({required this.report});

  final EnergyReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final max = report.devices.first.kwh;
    final total = report.consumption;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final d in report.devices.take(8))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            d.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          [
                            formatKwh(l10n.localeName, d.kwh),
                            if (total != null && total > 0)
                              '${(d.kwh / total * 100).round()} %',
                          ].join(' · '),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ExcludeSemantics(
                      // Name and value are read from the row above.
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 8,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ColoredBox(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                              ),
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: max > 0
                                    ? (d.kwh / max).clamp(0.0, 1.0)
                                    : 0,
                                child: ColoredBox(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.filled(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 150, maxWidth: 240),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelMedium,
                        maxLines: 2,
                      ),
                      Text(value, style: theme.textTheme.titleLarge),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _editTariff(
  BuildContext context,
  WidgetRef ref,
  Tariff? current,
) async {
  final result = await showDialog<_TariffResult>(
    context: context,
    builder: (_) => _TariffDialog(current: current),
  );
  if (result != null) {
    await ref.read(tariffProvider.notifier).save(result.tariff);
  }
}

class _TariffResult {
  const _TariffResult(this.tariff);
  final Tariff? tariff;
}

class _TariffDialog extends StatefulWidget {
  const _TariffDialog({this.current});

  final Tariff? current;

  @override
  State<_TariffDialog> createState() => _TariffDialogState();
}

class _TariffDialogState extends State<_TariffDialog> {
  late final _import = TextEditingController(
    text: widget.current?.importPrice.toString() ?? '',
  );
  late final _export = TextEditingController(
    text: widget.current?.exportPrice?.toString() ?? '',
  );
  late final _currency = TextEditingController(
    text: widget.current?.currency ?? 'RSD',
  );
  String? _error;

  @override
  void dispose() {
    _import.dispose();
    _export.dispose();
    _currency.dispose();
    super.dispose();
  }

  double? _number(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  void _save() {
    final price = _number(_import.text);
    final exportText = _export.text.trim();
    final export = exportText.isEmpty ? null : _number(exportText);
    if (price == null ||
        price < 0 ||
        (exportText.isNotEmpty && (export == null || export < 0))) {
      setState(() => _error = context.l10n.energyTariffInvalid);
      return;
    }
    Navigator.of(context).pop(
      _TariffResult(
        Tariff(
          importPrice: price,
          exportPrice: export,
          currency: _currency.text.trim().isEmpty
              ? 'RSD'
              : _currency.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final numeric = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    return AlertDialog(
      title: Text(l10n.energyTariffTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.energyTariffHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('tariffImport'),
              controller: _import,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: numeric,
              decoration: InputDecoration(
                labelText: l10n.energyTariffImport,
                errorText: _error,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _export,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: numeric,
              decoration: InputDecoration(labelText: l10n.energyTariffExport),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _currency,
              decoration: InputDecoration(labelText: l10n.energyTariffCurrency),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.current != null)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(const _TariffResult(null)),
            child: Text(l10n.delete),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('tariffSave'),
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
