import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/l10n.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../add_device/application/add_device_providers.dart';
import '../../authentication/application/session_controller.dart';
import '../../devices/application/device_providers.dart';
import '../domain/ai_automation.dart';

/// Whether Home Assistant has an AI Task set up.
final aiTaskAvailableProvider = Provider.autoDispose<bool>(
  (ref) =>
      ref
          .watch(haServicesProvider)
          .value?[aiTaskDomain]
          ?.contains(aiTaskService) ??
      false,
);

/// How long an AI may take to answer.
const aiTimeout = Duration(seconds: 90);

/// "Describe it in words": the AI in Home Assistant writes the automation,
/// the app checks it, and nothing is saved until the user has read it.
class AiAutomationScreen extends ConsumerStatefulWidget {
  const AiAutomationScreen({super.key});

  @override
  ConsumerState<AiAutomationScreen> createState() => _AiAutomationScreenState();
}

class _AiAutomationScreenState extends ConsumerState<AiAutomationScreen> {
  final _text = TextEditingController();
  bool _busy = false;
  AiDraft? _draft;
  String? _problem;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final l10n = context.l10n;
    final ws = ref.read(webSocketManagerProvider);
    final request = _text.text.trim();
    if (ws == null || request.isEmpty) return;
    setState(() {
      _busy = true;
      _draft = null;
      _problem = null;
    });
    final devices = ref.read(homeSnapshotProvider).devices;
    try {
      final services = await ref.read(haServicesProvider.future);
      final result = await ws.sendCommand({
        'type': 'call_service',
        'domain': aiTaskDomain,
        'service': aiTaskService,
        'service_data': {
          'task_name': 'Open Smart Home automation',
          'instructions': aiAutomationInstructions(
            request,
            devices.values,
            language: l10n.localeName,
          ),
        },
        'return_response': true,
      }, timeout: aiTimeout);
      final response = result is Map ? result['response'] : null;
      final draft = parseAiDraft(
        response is Map ? response['data'] : null,
        entities: devices.keys.toSet(),
        services: services,
      );
      if (mounted) setState(() => _draft = draft);
    } on AiDraftError catch (e) {
      if (mounted) {
        setState(
          () => _problem = e.message == null
              ? l10n.aiAutoNotUnderstood
              : l10n.aiAutoMissing(e.message!),
        );
      }
    } on AppFailure catch (e) {
      if (mounted) setState(() => _problem = failureMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(AiDraft draft) async {
    final l10n = context.l10n;
    final api = ref.read(homeAssistantApiProvider);
    if (api == null) return;
    setState(() => _busy = true);
    try {
      final id = 'osh_ai_${DateTime.now().millisecondsSinceEpoch}';
      await api.saveAutomation(id, draft.config);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.aiAutoSaved(draft.alias))));
      Navigator.of(context).pop();
    } on AppFailure catch (e) {
      if (mounted) setState(() => _problem = failureMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final draft = _draft;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiAutoTitle)),
      body: ListView(
        key: const Key('aiAutoScreen'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(l10n.aiAutoHint),
          const SizedBox(height: 12),
          TextField(
            key: const Key('aiAutoText'),
            controller: _text,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: l10n.aiAutoExample,
            ),
          ),
          const SizedBox(height: 8),
          Text(l10n.aiAutoPrivacy, style: muted),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('aiAutoAsk'),
            onPressed: _busy ? null : _ask,
            icon: const Icon(Icons.auto_awesome),
            label: Text(l10n.aiAutoAsk),
          ),
          if (_busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (_problem case final problem?) ...[
            const SizedBox(height: 12),
            Text(
              problem,
              key: const Key('aiAutoProblem'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          if (draft != null) ...[
            const SizedBox(height: 20),
            Text(l10n.aiAutoReview, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card.outlined(
              key: const Key('aiAutoDraft'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(draft.alias, style: theme.textTheme.titleMedium),
                    if (draft.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(draft.description),
                    ],
                    for (final (key, text, color) in [
                      if (draft.unknownEntities.isNotEmpty)
                        (
                          'aiAutoUnknownEntities',
                          l10n.aiAutoUnknownEntities(
                            draft.unknownEntities.join(', '),
                          ),
                          theme.colorScheme.error,
                        ),
                      if (draft.unknownActions.isNotEmpty)
                        (
                          'aiAutoUnknownActions',
                          l10n.aiAutoUnknownActions(
                            draft.unknownActions.join(', '),
                          ),
                          theme.colorScheme.error,
                        ),
                      if (draft.blocked.isNotEmpty)
                        (
                          'aiAutoBlocked',
                          l10n.aiAutoBlocked(draft.blocked.join(', ')),
                          theme.colorScheme.error,
                        ),
                      if (draft.sensitive.isNotEmpty)
                        (
                          'aiAutoSensitive',
                          l10n.aiAutoSensitive(draft.sensitive.join(', ')),
                          theme.colorScheme.tertiary,
                        ),
                    ]) ...[
                      const SizedBox(height: 8),
                      Text(
                        text,
                        key: Key(key),
                        style: TextStyle(color: color),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(l10n.aiAutoDetails),
                      children: [
                        SelectableText(
                          const JsonEncoder.withIndent('  ')
                              .convert(draft.config),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('aiAutoSave'),
              onPressed: _busy || !draft.canSave ? null : () => _save(draft),
              icon: const Icon(Icons.check),
              label: Text(l10n.aiAutoSave),
            ),
            const SizedBox(height: 8),
            Text(l10n.aiAutoAfterSave, style: muted),
          ],
        ],
      ),
    );
  }
}
