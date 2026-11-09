import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/l10n.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../authentication/application/session_controller.dart';
import '../../devices/domain/smart_home_device.dart';
import '../application/cheap_run.dart';
import '../application/electricity_prices.dart';
import 'price_section.dart';

/// On a plug or switch: run it for a few hours when electricity is
/// cheapest. Only when Home Assistant has a price sensor.
class CheapRunSection extends ConsumerStatefulWidget {
  const CheapRunSection({super.key, required this.device});

  final SmartHomeDevice device;

  @override
  ConsumerState<CheapRunSection> createState() => _CheapRunSectionState();
}

class _CheapRunSectionState extends ConsumerState<CheapRunSection> {
  int _hours = 2;
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String done) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(cheapRunProvider(widget.device.sourceId));
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(done)));
    } on AppFailure catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e.kind == FailureKind.authorization
                  ? l10n.presenceNeedsAdmin
                  : failureMessage(l10n, e),
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final hm = DateFormat.Hm(l10n.localeName);
    final prices = ref.watch(electricityPricesProvider).value;
    if (prices == null) return const SizedBox.shrink();
    final d = widget.device;
    final planned = ref.watch(cheapRunProvider(d.sourceId)).value;
    final now = DateTime.now();
    final best = cheapestWindow(prices.slots, Duration(hours: _hours), now);
    final api = ref.watch(homeAssistantApiProvider);

    return Card.outlined(
      key: const Key('cheapRun'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.cheapRunTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.cheapRunHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (planned != null) ...[
              Text(
                l10n.cheapRunPlanned(
                  '${planned.start.day != now.day ? '${l10n.priceTomorrow} ' : ''}'
                  '${hm.format(planned.start)}',
                  hm.format(planned.end),
                ),
                key: const Key('cheapRunPlanned'),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: OutlinedButton(
                  key: const Key('cheapRunCancel'),
                  onPressed: _busy || api == null
                      ? null
                      : () => _run(
                          () => api.deleteAutomation(cheapRunId(d.sourceId)),
                          l10n.cheapRunCancelled,
                        ),
                  child: Text(l10n.cheapRunCancel),
                ),
              ),
            ] else ...[
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final h in const [1, 2, 3, 4, 6])
                    ChoiceChip(
                      key: ValueKey('cheapRunHours-$h'),
                      label: Text(l10n.priceHours(h)),
                      selected: _hours == h,
                      onSelected: (_) => setState(() => _hours = h),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                best == null
                    ? l10n.priceNoWindow
                    : cheapestLabel(l10n, best, now, prices.unit),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.tonalIcon(
                  key: const Key('cheapRunPlan'),
                  onPressed: _busy || best == null || api == null
                      ? null
                      : () => _run(() async {
                          final (start, end, _) = best;
                          final startNow = !start.isAfter(now);
                          await api.saveAutomation(
                            cheapRunId(d.sourceId),
                            cheapRunConfig(
                              d,
                              start,
                              end,
                              alias: l10n.cheapRunAlias(d.name),
                              startNow: startNow,
                            ),
                          );
                          if (startNow) {
                            await api.callService(
                              'homeassistant',
                              'turn_on',
                              data: {'entity_id': d.sourceId},
                            );
                          }
                        }, l10n.cheapRunDone),
                  icon: const Icon(Icons.savings_outlined),
                  label: Text(l10n.cheapRunPlan),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
