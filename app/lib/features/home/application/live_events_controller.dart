import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../integrations/home_assistant/models/ha_models.dart';
import '../../authentication/application/session_controller.dart';

/// The most recent `state_changed` events, newest first. A diagnostic view
/// that proves the real-time pipeline works until the device UI exists.
class LiveEventsController extends Notifier<List<HaStateChangedEvent>> {
  static const int capacity = 25;

  @override
  List<HaStateChangedEvent> build() {
    final manager = ref.watch(webSocketManagerProvider);
    if (manager == null) return const [];
    final subscription = manager.stateChanges().listen((event) {
      state = [event, ...state.take(capacity - 1)];
    });
    ref.onDispose(() => unawaited(subscription.cancel()));
    return const [];
  }
}

final liveEventsProvider =
    NotifierProvider<LiveEventsController, List<HaStateChangedEvent>>(
      LiveEventsController.new,
    );
