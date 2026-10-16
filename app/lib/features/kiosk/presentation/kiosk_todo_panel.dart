import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/l10n.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../devices/application/device_providers.dart';
import '../../todo/todo_lists.dart';
import '../../todo/todo_screen.dart' show showTodoTextDialog;
import 'glass.dart';

/// A to-do / shopping list on the wall panel: tap an item to check it off,
/// "+" to add one. Done items leave the panel (they stay in the list in
/// Home Assistant until cleared).
class KioskTodoPanel extends ConsumerWidget {
  const KioskTodoPanel({super.key, required this.listId});

  final String listId;

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = context.l10n;
    try {
      await action();
    } on AppFailure catch (e) {
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failureMessage(l10n, e))));
    }
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final text = await showTodoTextDialog(
      context,
      title: l10n.todoAddHint,
      action: l10n.todoAdd,
      fieldKey: const Key('kioskTodoField'),
      saveKey: const Key('kioskTodoSave'),
    );
    if (text == null || text.trim().isEmpty || !context.mounted) return;
    await _run(context, () => ref.read(todoActionsProvider).add(listId, text));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(deviceProvider(listId));
    if (list == null) return const SizedBox.shrink();
    final items = ref.watch(todoItemsProvider(listId));
    final open = items.value?.where((i) => !i.completed).toList() ?? const [];
    final style = Theme.of(context).textTheme.titleMedium
        ?.copyWith(color: GlassColors.text);

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassTitle(
            list.name,
            trailing: list.canAddItems
                ? IconButton.filledTonal(
                    key: const Key('kioskTodoAdd'),
                    tooltip: l10n.todoAdd,
                    onPressed: () => _add(context, ref),
                    icon: const Icon(Icons.add),
                  )
                : null,
          ),
          Expanded(
            child: switch (items) {
              AsyncValue(hasValue: true) when open.isEmpty => Center(
                child: Text(
                  l10n.todoOpenCount(0),
                  style: const TextStyle(color: GlassColors.muted),
                ),
              ),
              AsyncValue(hasValue: true) => ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: open.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: GlassColors.border),
                itemBuilder: (context, i) {
                  final item = open[i];
                  return InkWell(
                    key: ValueKey('kioskTodo-${item.uid}'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: list.canUpdateItems
                        ? () => _run(
                            context,
                            () => ref
                                .read(todoActionsProvider)
                                .setCompleted(listId, item, true),
                          )
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_box_outline_blank,
                            color: GlassColors.muted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: style,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              AsyncError() => Center(
                child: Text(
                  l10n.todoUnavailable,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: GlassColors.muted),
                ),
              ),
              _ => const Center(
                child: CircularProgressIndicator(color: GlassColors.muted),
              ),
            },
          ),
        ],
      ),
    );
  }
}
