import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/l10n.dart';
import '../../../core/storage/app_preferences.dart';
import '../../authentication/application/session_controller.dart';
import '../../devices/application/device_providers.dart';
import '../domain/habits.dart';
import '../domain/simple_automation.dart';
import 'automation_editor_screen.dart';

/// Habits found in the last two weeks of the logbook. Worked out once and
/// kept for a few hours: the logbook of a whole home is not small.
final habitSuggestionsProvider = FutureProvider<List<HabitSuggestion>>((
  ref,
) async {
  final api = ref.watch(homeAssistantApiProvider);
  if (api == null) return const [];
  final refresh = Timer(const Duration(hours: 6), ref.invalidateSelf);
  ref.onDispose(refresh.cancel);
  final now = DateTime.now();
  final entries = await api.fetchLogbook(
    null,
    now.subtract(const Duration(days: 14)),
    now,
  );
  return findHabits(entries, ref.read(homeSnapshotProvider).devices);
});

/// Suggestions the user turned down or already made into automations.
class HabitsDoneController extends Notifier<Set<String>> {
  static const _key = 'automations.habitsDone';

  @override
  Set<String> build() => {
    ...?(ref.watch(appPreferencesProvider).readJson(_key)?['keys'] as List?)
        ?.whereType<String>(),
  };

  Future<void> add(String key) async {
    state = {...state, key};
    await ref.read(appPreferencesProvider).writeJson(_key, {
      'keys': state.toList(),
    });
  }
}

final habitsDoneProvider = NotifierProvider<HabitsDoneController, Set<String>>(
  HabitsDoneController.new,
);

/// The suggestions still worth showing.
final openHabitsProvider = Provider.autoDispose<List<HabitSuggestion>>((ref) {
  final done = ref.watch(habitsDoneProvider);
  return [
    for (final h
        in ref.watch(habitSuggestionsProvider).value ??
            const <HabitSuggestion>[])
      if (!done.contains(h.key)) h,
  ];
});

/// "From your habits": above the automations, only when there are any.
class HabitSuggestionsSection extends ConsumerWidget {
  const HabitSuggestionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final habits = ref.watch(openHabitsProvider);
    if (habits.isEmpty) return const SizedBox.shrink();
    return Card(
      key: const Key('habitSuggestions'),
      color: theme.colorScheme.secondaryContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: Text(l10n.habitsTitle, style: theme.textTheme.titleMedium),
              subtitle: Text(l10n.habitsHint),
            ),
            for (final h in habits) _HabitTile(habit: h),
          ],
        ),
      ),
    );
  }
}

class _HabitTile extends ConsumerWidget {
  const _HabitTile({required this.habit});

  final HabitSuggestion habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final action = habit.action;
    final device = ref.watch(deviceProvider(action.entityId));
    final what =
        '${serviceLabel(l10n, device, action.service)}: '
        '${device?.name ?? action.entityId}';
    final days = habit.weekdays;
    final when = switch (habit.trigger) {
      TimeTrigger() => [
        l10n.habitAt(triggerLabel(context, ref, habit.trigger)),
        if (days != null && days.contains(1)) l10n.habitWeekdays,
        if (days != null && !days.contains(1)) l10n.habitWeekend,
        l10n.habitDays(habit.seen, habit.outOf),
      ].join(' · '),
      _ => [
        l10n.habitAfter(triggerLabel(context, ref, habit.trigger)),
        for (final c in habit.automation.conditions)
          conditionLabel(context, ref, c),
        l10n.habitTimes(habit.seen, habit.outOf),
      ].join(' · '),
    };
    return Column(
      key: Key('habit-${habit.key}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: Icon(
            habit.kind == HabitKind.time
                ? Icons.schedule
                : Icons.subdirectory_arrow_right,
          ),
          title: Text(what),
          subtitle: Text(when),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: 8,
            children: [
              TextButton(
                onPressed: () =>
                    ref.read(habitsDoneProvider.notifier).add(habit.key),
                child: Text(l10n.habitDismiss),
              ),
              FilledButton.tonal(
                onPressed: () async {
                  final saved = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) =>
                          AutomationEditorScreen(initial: habit.automation),
                    ),
                  );
                  if (saved ?? false) {
                    await ref.read(habitsDoneProvider.notifier).add(habit.key);
                  }
                },
                child: Text(l10n.habitCreate),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
