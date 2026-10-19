part of 'kiosk_layout_view.dart';

/// Asks for a template and adds a page after the others, then shows it.
Future<void> addKioskPage(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final settings = ref.read(kioskSettingsProvider);
  if (settings.pages.length >= KioskPage.maxPages) return;
  String label(KioskPageTemplate t) => switch (t) {
    KioskPageTemplate.empty => l10n.kioskPageEmpty,
    KioskPageTemplate.cameras => l10n.camerasTitle,
    KioskPageTemplate.climateEnergy => l10n.kioskPageClimateEnergy,
  };
  final template = await showDialog<KioskPageTemplate>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l10n.kioskAddPage),
      children: [
        for (final t in KioskPageTemplate.values)
          SimpleDialogOption(
            key: ValueKey('kioskPageTemplate-${t.name}'),
            onPressed: () => Navigator.of(context).pop(t),
            child: Text(label(t)),
          ),
      ],
    ),
  );
  if (template == null) return;
  final name = template == KioskPageTemplate.empty
      ? l10n.kioskPageNumber(settings.pages.length + 2)
      : label(template);
  await ref
      .read(kioskSettingsProvider.notifier)
      .update(
        (s) =>
            s.copyWith(pages: [...s.pages, KioskPage.create(template, name)]),
      );
  ref
      .read(kioskPageProvider.notifier)
      .set(ref.read(kioskSettingsProvider).pages.length);
}

Future<void> renameKioskPage(
  BuildContext context,
  WidgetRef ref,
  int page,
) async {
  final pages = ref.read(kioskSettingsProvider).pages;
  if (page < 1 || page > pages.length) return;
  final name = await showDialog<String>(
    context: context,
    builder: (_) => _RenameDialog(initial: pages[page - 1].name),
  );
  if (name == null || name.trim().isEmpty) return;
  await ref
      .read(kioskSettingsProvider.notifier)
      .update(
        (s) => s.copyWith(
          pages: [
            for (final (i, p) in s.pages.indexed)
              i == page - 1 ? p.copyWith(name: name.trim()) : p,
          ],
        ),
      );
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.kioskRenamePage),
      content: TextField(
        key: const Key('kioskPageName'),
        controller: _controller,
        autofocus: true,
        maxLength: 30,
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('kioskPageNameSave'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// When page [page] shows by itself: a time window (the same time twice =
/// never).
Future<void> scheduleKioskPage(
  BuildContext context,
  WidgetRef ref,
  int page,
) async {
  final l10n = context.l10n;
  final pages = ref.read(kioskSettingsProvider).pages;
  if (page < 1 || page > pages.length) return;
  final current = pages[page - 1];
  TimeOfDay time(int m) => TimeOfDay(hour: m ~/ 60, minute: m % 60);
  final from = await showAppTimePicker(
    context: context,
    initialTime: time(current.from ?? 19 * 60),
    helpText: l10n.kioskPageScheduleFrom,
  );
  if (from == null || !context.mounted) return;
  final to = await showAppTimePicker(
    context: context,
    initialTime: time(current.to ?? 23 * 60),
    helpText: l10n.kioskPageScheduleTo,
  );
  if (to == null) return;
  final schedule = (from.hour * 60 + from.minute, to.hour * 60 + to.minute);
  await ref
      .read(kioskSettingsProvider.notifier)
      .update(
        (s) => s.copyWith(
          pages: [
            for (final (i, p) in s.pages.indexed)
              i == page - 1
                  ? (schedule.$1 == schedule.$2
                        ? p.copyWith(clearSchedule: true)
                        : p.copyWith(schedule: schedule))
                  : p,
          ],
        ),
      );
}
