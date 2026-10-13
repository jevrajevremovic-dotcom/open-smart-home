import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../devices/application/device_providers.dart';
import '../../devices/domain/device_kind.dart';

/// The media player to show as "now playing": one that is playing, else
/// one that is paused; `null` when nothing is playing.
final nowPlayingIdProvider = Provider<String?>((ref) {
  final players = ref.watch(
    homeSnapshotProvider.select(
      (s) => [
        for (final d in s.devices.values)
          if (d.available &&
              (d.kind == DeviceKind.mediaPlayer ||
                  d.kind == DeviceKind.speaker ||
                  d.kind == DeviceKind.television))
            (d.id, d.state.raw),
      ]..sort((a, b) => a.$1.compareTo(b.$1)),
    ),
  );
  for (final state in ['playing', 'paused']) {
    for (final (id, s) in players) {
      if (s == state) return id;
    }
  }
  return null;
});
