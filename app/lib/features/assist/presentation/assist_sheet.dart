import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/l10n.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/errors/app_failure.dart';
import '../../authentication/application/session_controller.dart';

/// Opens Assist: a short text conversation with Home Assistant.
Future<void> showAssist(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => const AssistSheet(),
);

class _Message {
  const _Message(this.text, {required this.fromUser, this.error = false});

  final String text;
  final bool fromUser;
  final bool error;
}

class AssistSheet extends ConsumerStatefulWidget {
  const AssistSheet({super.key});

  @override
  ConsumerState<AssistSheet> createState() => _AssistSheetState();
}

class _AssistSheetState extends ConsumerState<AssistSheet> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_Message>[];
  String? _conversationId;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final l10n = context.l10n;
    final trimmed = text.trim();
    final api = ref.read(homeAssistantApiProvider);
    if (trimmed.isEmpty || _busy || api == null) return;
    setState(() {
      _messages.add(_Message(trimmed, fromUser: true));
      _busy = true;
      _controller.clear();
    });
    _scrollToEnd();
    try {
      final reply = await api.processConversation(
        trimmed,
        language: l10n.localeName,
        conversationId: _conversationId,
      );
      _conversationId = reply.conversationId ?? _conversationId;
      _messages.add(
        _Message(
          reply.speech.isEmpty
              ? (reply.isError ? l10n.assistNotUnderstood : '✓')
              : reply.speech,
          fromUser: false,
          error: reply.isError,
        ),
      );
    } on AppFailure catch (e) {
      _messages.add(
        _Message(failureMessage(l10n, e), fromUser: false, error: true),
      );
    } on Object {
      _messages.add(
        _Message(l10n.assistUnavailable, fromUser: false, error: true),
      );
    }
    if (mounted) setState(() => _busy = false);
    _scrollToEnd();
  }

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final suggestions = [
      l10n.assistSuggestionLightsOff,
      l10n.assistSuggestionTemperature,
      l10n.assistSuggestionLightsOn,
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          maxWidth: 720,
        ),
        child: Column(
          key: const Key('assistSheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(
                      Icons.assistant_outlined,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.assistTitle, style: theme.textTheme.titleLarge),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                controller: _scroll,
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  if (_messages.isEmpty) ...[
                    Text(l10n.assistIntro, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in suggestions)
                          ActionChip(label: Text(s), onPressed: () => _send(s)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.assistPrivacy,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  for (final m in _messages) _Bubble(message: m),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('assistInput'),
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: InputDecoration(hintText: l10n.assistHint),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const Key('assistSend'),
                    tooltip: l10n.assistSend,
                    onPressed: _busy ? null : () => _send(_controller.text),
                    icon: const Icon(Icons.send),
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final _Message message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = message.fromUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: user
              ? scheme.primary
              : message.error
              ? scheme.errorContainer
              : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(user ? 18 : 4),
            bottomRight: Radius.circular(user ? 4 : 18),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: user
                ? scheme.onPrimary
                : message.error
                ? scheme.onErrorContainer
                : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
