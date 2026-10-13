import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../integrations/home_assistant/api/home_assistant_api.dart';
import '../../../integrations/home_assistant/mappers/ha_command_translator.dart';
import '../../authentication/application/session_controller.dart';
import '../domain/device_command.dart';
import '../domain/smart_home_device.dart';

/// The single entry point for controlling devices.
///
/// Guards, in order: device available → capability declared → critical
/// commands confirmed. Only then is the command translated and sent. The UI
/// is not updated optimistically; the resulting `state_changed` event does it.
class DeviceCommandService {
  DeviceCommandService(
    this._api, {
    this._translator = const HaCommandTranslator(),
  });

  final HomeAssistantApi _api;
  final HaCommandTranslator _translator;
  static final _log = AppLogger('DeviceCommand');

  Future<void> execute(
    SmartHomeDevice device,
    DeviceCommand command, {
    bool confirmed = false,
  }) async {
    if (!device.available) {
      throw AppFailure(
        FailureKind.unavailableEntity,
        debugMessage: '${device.id} unavailable',
      );
    }
    if (!device.supports(command.requiredCapability)) {
      throw AppFailure(
        FailureKind.unsupportedFeature,
        debugMessage: '${device.id} lacks ${command.requiredCapability.name}',
      );
    }
    if (command.isCritical(device) && !confirmed) {
      throw AppFailure(
        FailureKind.confirmationRequired,
        debugMessage:
            '${command.runtimeType} on ${device.id} needs confirmation',
      );
    }
    final call = _translator.translate(device, command);
    _log.info('→ $call'); // entity id and service only; never the payload
    await _api.callService(call.domain, call.service, data: call.data);
  }
}

final deviceCommandServiceProvider = Provider<DeviceCommandService?>((ref) {
  final api = ref.watch(homeAssistantApiProvider);
  return api == null ? null : DeviceCommandService(api);
});
