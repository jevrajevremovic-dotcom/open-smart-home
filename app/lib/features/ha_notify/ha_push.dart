import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../core/storage/app_preferences.dart';
import '../../core/storage/credential_store.dart';
import '../alerts/alert_notifications.dart';
import '../authentication/application/session_controller.dart';

/// This app registered with Home Assistant's `mobile_app` integration
/// (documented native app API), so automations can send it messages with
/// `notify.mobile_app_<name>`. They arrive over the WebSocket connection
/// (`push_websocket_channel`): no push server, no cloud.
@immutable
class MobileAppRegistration {
  const MobileAppRegistration({
    required this.webhookId,
    required this.deviceName,
  });

  static MobileAppRegistration? tryParse(String? raw) {
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final webhook = json['webhookId'];
      final name = json['deviceName'];
      return webhook is String && name is String
          ? MobileAppRegistration(webhookId: webhook, deviceName: name)
          : null;
    } on FormatException {
      return null;
    }
  }

  /// Secret: anyone with it can post to the webhook. Kept with the token.
  final String webhookId;
  final String deviceName;

  /// The notify service Home Assistant creates for this device.
  String get notifyService => 'notify.mobile_app_${haSlug(deviceName)}';

  String serialize() =>
      jsonEncode({'webhookId': webhookId, 'deviceName': deviceName});
}

/// Close to Home Assistant's `slugify` for the names people type here.
String haSlug(String text) {
  const map = {
    'č': 'c', 'ć': 'c', 'š': 's', 'ž': 'z', 'đ': 'd', //
    'ä': 'a', 'ö': 'o', 'ü': 'u', 'ß': 'ss', 'é': 'e', 'è': 'e', 'á': 'a',
  };
  final lower = text.toLowerCase().split('').map((c) => map[c] ?? c).join();
  return lower
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

class HaPushController extends AsyncNotifier<MobileAppRegistration?> {
  static final _log = AppLogger('HaPush');
  static const _deviceIdKey = 'mobile_app.device_id';

  String? get _key {
    final profile = ref.read(activeProfileProvider);
    return profile == null ? null : 'mobile_app::${profile.id}';
  }

  @override
  Future<MobileAppRegistration?> build() async {
    final profile = ref.watch(activeProfileProvider);
    if (profile == null) return null;
    return MobileAppRegistration.tryParse(
      await ref
          .read(credentialStoreProvider)
          .readCredential('mobile_app::${profile.id}'),
    );
  }

  /// A random id for this installation (not secret, not a hardware id).
  String _deviceId() {
    final prefs = ref.read(appPreferencesProvider);
    final existing = prefs.readJson(_deviceIdKey)?['id'];
    if (existing is String) return existing;
    final r = Random.secure();
    final id = List.generate(
      16,
      (_) => r.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    unawaited(prefs.writeJson(_deviceIdKey, {'id': id}));
    return id;
  }

  Future<void> register(String deviceName) async {
    final api = ref.read(homeAssistantApiProvider);
    final key = _key;
    if (api == null || key == null) return;
    final answer = await api.registerMobileApp({
      'device_id': _deviceId(),
      'app_id': 'org.opensmarthome.open_smart_home',
      'app_name': 'Open Smart Home',
      'app_version': '0.1.0',
      'device_name': deviceName,
      'manufacturer': 'Open Smart Home',
      'model': defaultTargetPlatform.name,
      'os_name': defaultTargetPlatform.name,
      'os_version': 'unknown',
      'supports_encryption': false,
      'app_data': {'push_websocket_channel': true},
    });
    final registration = MobileAppRegistration(
      webhookId: answer['webhook_id']! as String,
      deviceName: deviceName,
    );
    await ref
        .read(credentialStoreProvider)
        .writeCredential(key, registration.serialize(), persistent: true);
    _log.info('Registered with mobile_app');
    state = AsyncData(registration);
  }

  /// Forgets the registration here; the device itself is removed in Home
  /// Assistant (Settings → Devices → Mobile App).
  Future<void> forget() async {
    final key = _key;
    if (key != null) {
      await ref.read(credentialStoreProvider).deleteCredential(key);
    }
    state = const AsyncData(null);
  }
}

final haPushProvider =
    AsyncNotifierProvider<HaPushController, MobileAppRegistration?>(
      HaPushController.new,
    );

/// Keeps the push channel open while connected and shows each message.
class HaPushHost extends ConsumerStatefulWidget {
  const HaPushHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<HaPushHost> createState() => _HaPushHostState();
}

class _HaPushHostState extends ConsumerState<HaPushHost> {
  static final _log = AppLogger('HaPush');
  StreamSubscription<Map<String, Object?>>? _sub;
  String? _webhook;
  int _counter = 0;

  void _sync() {
    final registration = ref.read(haPushProvider).value;
    final manager = ref.read(webSocketManagerProvider);
    final connected =
        ref.read(connectionStatusProvider).value?.isConnected ?? false;
    final notifier = ref.read(alertNotifierProvider);
    if (registration == null ||
        manager == null ||
        !connected ||
        !notifier.supported) {
      if (registration == null || manager == null) _stop();
      return;
    }
    if (_sub != null && _webhook == registration.webhookId) return;
    _stop();
    unawaited(notifier.initialize((_) {}));
    _webhook = registration.webhookId;
    _sub = manager
        .subscribeCommand({
          'type': 'mobile_app/push_notification_channel',
          'webhook_id': registration.webhookId,
          'support_confirm': true,
        })
        .listen(
          (event) {
            final message = event['message'];
            if (message is! String) return;
            final title = event['title'];
            unawaited(
              notifier.showMessage(
                'ha-${_counter++}',
                title is String ? title : null,
                message,
              ),
            );
            final confirm = event['hass_confirm_id'];
            if (confirm is String) {
              // Tells Home Assistant it arrived (no cloud fallback needed).
              unawaited(
                manager
                    .sendCommand({
                      'type': 'mobile_app/push_notification_confirm',
                      'webhook_id': registration.webhookId,
                      'confirm_id': confirm,
                    })
                    .catchError((Object _) => null),
              );
            }
          },
          // The connection dropped: subscribe again once it is back.
          onError: (Object e) {
            _log.debug('push channel closed: ${e.runtimeType}');
            _closed();
          },
          onDone: _closed,
          cancelOnError: true,
        );
  }

  /// The channel ended (usually a dropped connection). The connection may
  /// already be back by now, so check again instead of waiting for the
  /// next status change.
  void _closed() {
    _sub = null;
    _webhook = null;
    scheduleMicrotask(() {
      if (mounted) _sync();
    });
  }

  void _stop() {
    unawaited(_sub?.cancel());
    _sub = null;
    _webhook = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(haPushProvider, (_, _) => _sync())
      ..listen(connectionStatusProvider, (_, _) => _sync())
      ..listen(webSocketManagerProvider, (_, _) {
        _stop();
        _sync();
      });
    return widget.child;
  }
}
