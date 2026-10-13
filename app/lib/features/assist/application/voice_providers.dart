import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_preferences.dart';
import '../data/voice_input.dart';

final voiceInputProvider = Provider<VoiceInput>(
  (ref) => SpeechToTextVoiceInput(),
);

/// Voice privacy choice, asked once before the first recording:
/// `null` = not asked yet, `false` = on-device recognition only,
/// `true` = the phone's online recogniser is allowed too.
class VoiceCloudController extends Notifier<bool?> {
  static const _key = 'assist.voice';

  @override
  bool? build() {
    final json = ref.watch(appPreferencesProvider).readJson(_key);
    return json?['cloudAllowed'] as bool?;
  }

  Future<void> set(bool? cloudAllowed) async {
    state = cloudAllowed;
    await ref
        .read(appPreferencesProvider)
        .writeJson(
          _key,
          cloudAllowed == null ? null : {'cloudAllowed': cloudAllowed},
        );
  }
}

final voiceCloudAllowedProvider = NotifierProvider<VoiceCloudController, bool?>(
  VoiceCloudController.new,
);
