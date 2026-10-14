import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../integrations/home_assistant/api/home_assistant_api.dart';
import '../../../integrations/home_assistant/mappers/ha_command_translator.dart';
import '../../authentication/application/session_controller.dart';
import '../data/home_state_repository.dart';
import '../domain/device_command.dart';
import 'device_providers.dart';
import '../domain/capability.dart';
import '../domain/device_kind.dart';
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
    this._isOnline,
  });

  final HomeAssistantApi _api;
  final HaCommandTranslator _translator;

  /// Whether the shown data is live. Commands are refused while showing
  /// cached/stale data: the user could not see the real current state, nor
  /// the result of the command.
  final bool Function()? _isOnline;
  static final _log = AppLogger('DeviceCommand');

  Future<void> execute(
    SmartHomeDevice device,
    DeviceCommand command, {
    bool confirmed = false,
  }) async {
    if (!(_isOnline?.call() ?? true)) {
      throw const AppFailure(
        FailureKind.network,
        debugMessage: 'data not live; command refused',
      );
    }
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

  /// All [lights] on or off in one documented `light.turn_on/off` call.
  Future<void> setLights(
    Iterable<SmartHomeDevice> lights, {
    required bool on,
  }) async {
    if (!(_isOnline?.call() ?? true)) {
      throw const AppFailure(
        FailureKind.network,
        debugMessage: 'data not live; command refused',
      );
    }
    final ids = [
      for (final d in lights)
        if (d.available && d.kind.isLight) d.sourceId,
    ];
    if (ids.isEmpty) return;
    _log.info('→ light.${on ? 'turn_on' : 'turn_off'} (${ids.length})');
    await _api.callService(
      'light',
      on ? 'turn_on' : 'turn_off',
      data: {'entity_id': ids},
    );
  }

  /// Opens or closes all [covers] (blinds, curtains) in one documented
  /// `cover.open_cover/close_cover` call. Garage doors are never included:
  /// opening one needs its own confirmation.
  Future<void> setCovers(
    Iterable<SmartHomeDevice> covers, {
    required bool open,
  }) async {
    if (!(_isOnline?.call() ?? true)) {
      throw const AppFailure(
        FailureKind.network,
        debugMessage: 'data not live; command refused',
      );
    }
    final ids = [
      for (final d in covers)
        if (d.available &&
            isGroupCover(d) &&
            d.supports(open ? Capability.open : Capability.close))
          d.sourceId,
    ];
    if (ids.isEmpty) return;
    _log.info('→ cover.${open ? 'open_cover' : 'close_cover'} (${ids.length})');
    await _api.callService(
      'cover',
      open ? 'open_cover' : 'close_cover',
      data: {'entity_id': ids},
    );
  }
}

/// Blinds and curtains, the covers that may be moved together.
bool isGroupCover(SmartHomeDevice d) =>
    d.kind == DeviceKind.blind || d.kind == DeviceKind.curtain;

final deviceCommandServiceProvider = Provider<DeviceCommandService?>((ref) {
  final api = ref.watch(homeAssistantApiProvider);
  return api == null
      ? null
      : DeviceCommandService(
          api,
          isOnline: () => ref.read(syncStatusProvider) == SyncStatus.live,
        );
});
