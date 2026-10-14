import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_smart_home/app/app.dart';
import 'package:open_smart_home/app/router/app_router.dart';
import 'package:open_smart_home/features/kiosk/application/kiosk_controller.dart';
import 'package:open_smart_home/features/kiosk/data/kiosk_photo.dart';
import 'package:open_smart_home/features/kiosk/presentation/glass.dart';
import 'package:open_smart_home/features/kiosk/presentation/kiosk_settings_section.dart';
import 'package:open_smart_home/integrations/home_assistant/mock/mock_camera_image.dart';

import '../widgets/app_widget_test.dart'
    show goTo, pumpApp, settle, tapKey, unmount;

class MemoryPhotoStore implements KioskPhotoStore {
  final Map<String, Uint8List> files = {};

  @override
  bool get supported => true;

  @override
  Future<String> save(Uint8List bytes) async {
    final path = 'photo${files.length}';
    files[path] = bytes;
    return path;
  }

  @override
  Future<void> delete(String path) async => files.remove(path);

  @override
  ImageProvider? image(String path) =>
      files[path] == null ? null : MemoryImage(files[path]!);
}

void main() {
  testWidgets('choose a kiosk photo, see it behind the panels, remove it', (
    tester,
  ) async {
    final store = MemoryPhotoStore();
    final photo = mockCameraFrame(0, DateTime(2026));
    await pumpApp(
      tester,
      signedIn: true,
      size: const Size(1280, 800),
      overrides: [
        kioskPhotoStoreProvider.overrideWithValue(store),
        kioskPhotoPickerProvider.overrideWithValue(() async => photo),
      ],
    );
    await settle(tester, 10);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SmartHomeApp)),
    );
    await goTo(tester, AppRoutes.settings);
    await tapKey(tester, 'kioskPhotoPick');
    await settle(tester, 4);
    expect(container.read(kioskSettingsProvider).photoPath, 'photo0');
    expect(store.files, hasLength(1));

    await tapKey(tester, 'startKiosk');
    await settle(tester, 8);
    final backdrop = find.descendant(
      of: find.byType(KioskBackdrop),
      matching: find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).image != null,
      ),
    );
    expect(backdrop, findsOneWidget);
    await unmount(tester);
  });
}
