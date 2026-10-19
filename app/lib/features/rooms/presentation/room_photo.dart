import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/localization/l10n.dart';
import '../../../core/storage/app_preferences.dart';
import '../../kiosk/presentation/glass.dart' show kioskPhotoStoreProvider;

/// A photo per room (room id → file on this device). Kept only here:
/// never sent to Home Assistant, not in the settings backup.
class RoomPhotosController extends Notifier<Map<String, String>> {
  static const _key = 'room.photos';

  @override
  Map<String, String> build() => {
    for (final e
        in (ref.watch(appPreferencesProvider).readJson(_key) ?? const {})
            .entries)
      if (e.value is String) e.key: e.value! as String,
  };

  Future<void> set(String roomId, Uint8List bytes) async {
    final store = ref.read(kioskPhotoStoreProvider);
    final path = await store.save(bytes);
    final old = state[roomId];
    state = {...state, roomId: path};
    await _save();
    if (old != null) await store.delete(old);
  }

  Future<void> remove(String roomId) async {
    final old = state[roomId];
    if (old == null) return;
    state = {...state}..remove(roomId);
    await _save();
    await ref.read(kioskPhotoStoreProvider).delete(old);
  }

  Future<void> _save() => ref
      .read(appPreferencesProvider)
      .writeJson(_key, state.isEmpty ? null : state);
}

final roomPhotosProvider =
    NotifierProvider<RoomPhotosController, Map<String, String>>(
      RoomPhotosController.new,
    );

/// One photo from the gallery, resized on the way in (tests replace it).
final roomPhotoPickerProvider = Provider<Future<Uint8List?> Function()>(
  (ref) => () async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    return file?.readAsBytes();
  },
);

/// The room's photo as a wide header, or nothing.
class RoomPhotoHeader extends ConsumerWidget {
  const RoomPhotoHeader({
    super.key,
    required this.roomId,
    this.height = 180,
    this.radius = 24,
  });

  final String roomId;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(roomPhotosProvider.select((m) => m[roomId]));
    final image = path == null
        ? null
        : ref.watch(kioskPhotoStoreProvider).image(path);
    if (image == null) return const SizedBox.shrink();
    return ClipRRect(
      key: ValueKey('roomPhoto-$roomId'),
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Image(
          // Decoded no larger than a tablet needs, not at camera size.
          image: ResizeImage.resizeIfNeeded(1600, null, image),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// App bar button: choose or remove the room's photo.
class RoomPhotoButton extends ConsumerWidget {
  const RoomPhotoButton({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(kioskPhotoStoreProvider).supported) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final has = ref.watch(roomPhotosProvider.select((m) => m[roomId] != null));
    Future<void> choose() async {
      final bytes = await ref.read(roomPhotoPickerProvider)();
      if (bytes == null) return;
      await ref.read(roomPhotosProvider.notifier).set(roomId, bytes);
    }

    return IconButton(
      key: const Key('roomPhoto'),
      tooltip: l10n.roomPhoto,
      icon: const Icon(Icons.add_photo_alternate_outlined),
      onPressed: () async {
        if (!has) return choose();
        await showModalBottomSheet<void>(
          context: context,
          builder: (sheet) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  key: const Key('roomPhotoChange'),
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(l10n.roomPhotoChange),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    choose();
                  },
                ),
                ListTile(
                  key: const Key('roomPhotoRemove'),
                  leading: const Icon(Icons.delete_outline),
                  title: Text(l10n.roomPhotoRemove),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    ref.read(roomPhotosProvider.notifier).remove(roomId);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Text(
                    l10n.roomPhotoHint,
                    style: Theme.of(sheet).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
