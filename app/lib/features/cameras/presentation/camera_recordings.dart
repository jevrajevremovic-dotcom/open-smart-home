import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../app/localization/l10n.dart';
import '../../../integrations/home_assistant/mappers/ha_device_mapper.dart'
    show localPicturePath;
import '../../authentication/application/session_controller.dart';

/// One entry of HA's media browser (`media_source/browse_media`).
@immutable
class MediaItem {
  const MediaItem({
    required this.id,
    required this.title,
    required this.canPlay,
    required this.canExpand,
    this.thumbnail,
    this.children = const [],
  });

  factory MediaItem.fromJson(Map<Object?, Object?> j) => MediaItem(
    id: j['media_content_id'] as String? ?? '',
    title: j['title'] as String? ?? '',
    canPlay: j['can_play'] == true,
    canExpand: j['can_expand'] == true,
    thumbnail: localPicturePath(j['thumbnail']),
    children: [
      if (j['children'] case final List<Object?> children)
        for (final c in children)
          if (c is Map) MediaItem.fromJson(c),
    ],
  );

  final String id;
  final String title;
  final bool canPlay;
  final bool canExpand;

  /// A path on the HA server (never another host).
  final String? thumbnail;
  final List<MediaItem> children;
}

/// Sources that are not recordings (radio, spoken text, live cameras,
/// uploaded pictures) are left out of the top level.
const _notRecordings = [
  'media-source://radio_browser',
  'media-source://tts',
  'media-source://camera',
  'media-source://image_upload',
];

/// A folder of HA's media browser; `''` is the top. The same browser HA's
/// own Media panel uses, so Frigate, Reolink, Synology and local folders
/// all show up without the app knowing them.
final mediaFolderProvider = FutureProvider.autoDispose
    .family<MediaItem, String>((ref, id) async {
      final ws = ref.watch(webSocketManagerProvider);
      if (ws == null) throw StateError('not connected');
      final result = await ws.sendCommand({
        'type': 'media_source/browse_media',
        if (id.isNotEmpty) 'media_content_id': id,
      });
      if (result is! Map) throw StateError('unexpected answer');
      final folder = MediaItem.fromJson(result);
      if (id.isNotEmpty) return folder;
      return MediaItem(
        id: folder.id,
        title: folder.title,
        canPlay: false,
        canExpand: true,
        children: [
          for (final c in folder.children)
            if (!_notRecordings.any(c.id.startsWith)) c,
        ],
      );
    });

/// A short-lived, signed address of a clip on the HA server
/// (`media_source/resolve_media`). Anything pointing elsewhere is refused.
final mediaUrlProvider = FutureProvider.autoDispose.family<Uri, String>((
  ref,
  id,
) async {
  final ws = ref.watch(webSocketManagerProvider);
  final api = ref.watch(homeAssistantApiProvider);
  if (ws == null || api == null) throw StateError('not connected');
  final result = await ws.sendCommand({
    'type': 'media_source/resolve_media',
    'media_content_id': id,
  });
  final url = result is Map ? result['url'] : null;
  if (url is! String) throw StateError('unexpected answer');
  final uri = Uri.tryParse(url);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      !url.startsWith('/') ||
      url.contains('..')) {
    throw StateError('clip is not on the Home Assistant server');
  }
  return api.address.baseUri.resolve(url);
});

final _thumbnailProvider = FutureProvider.autoDispose.family<Uint8List, String>(
  (ref, path) async {
    final api = ref.watch(homeAssistantApiProvider);
    if (api == null) throw StateError('not connected');
    return api.fetchImage(path);
  },
);

/// The recordings browser. Pushed on the nearest navigator so the kiosk's
/// "return to dashboard" closes it too.
Future<void> openRecordings(BuildContext context, {String id = ''}) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => RecordingsScreen(folderId: id)),
    );

class RecordingsScreen extends ConsumerWidget {
  const RecordingsScreen({super.key, this.folderId = ''});

  final String folderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final folder = ref.watch(mediaFolderProvider(folderId));
    return Scaffold(
      key: const Key('recordingsScreen'),
      appBar: AppBar(
        title: Text(
          folderId.isEmpty
              ? l10n.cameraRecordings
              : folder.value?.title ?? l10n.cameraRecordings,
        ),
      ),
      body: switch (folder) {
        AsyncData(:final value) when value.children.isEmpty => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              folderId.isEmpty
                  ? l10n.cameraRecordingsNone
                  : l10n.cameraRecordingsEmpty,
              key: const Key('recordingsEmpty'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            for (final item in value.children)
              ListTile(
                key: Key('media-${item.id}'),
                leading: _Thumbnail(item),
                title: Text(item.title),
                trailing: item.canExpand
                    ? const Icon(Icons.chevron_right)
                    : item.canPlay
                    ? const Icon(Icons.play_circle_outline)
                    : null,
                onTap: item.canExpand
                    ? () => openRecordings(context, id: item.id)
                    : item.canPlay
                    ? () => _play(context, item)
                    : null,
              ),
          ],
        ),
        AsyncError() => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.cameraRecordingsFailed,
              key: const Key('recordingsFailed'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  void _play(BuildContext context, MediaItem item) => Navigator.of(context)
      .push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => _ClipPlayer(item),
        ),
      );
}

class _Thumbnail extends ConsumerWidget {
  const _Thumbnail(this.item);

  final MediaItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = item.thumbnail;
    final bytes = path == null ? null : ref.watch(_thumbnailProvider(path));
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 72,
        height: 44,
        child: bytes?.value != null
            ? Image.memory(bytes!.value!, fit: BoxFit.cover)
            : ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  item.canExpand ? Icons.folder_outlined : Icons.movie_outlined,
                ),
              ),
      ),
    );
  }
}

class _ClipPlayer extends ConsumerStatefulWidget {
  const _ClipPlayer(this.item);

  final MediaItem item;

  @override
  ConsumerState<_ClipPlayer> createState() => _ClipPlayerState();
}

class _ClipPlayerState extends ConsumerState<_ClipPlayer> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(mediaUrlProvider(widget.item.id), (_, next) {
      switch (next) {
        case AsyncData(:final value):
          _open(value);
        case AsyncError():
          if (mounted) setState(() => _failed = true);
        default:
      }
    }, fireImmediately: true);
  }

  Future<void> _open(Uri url) async {
    if (_controller != null) return;
    if (kIsWeb) {
      setState(() => _failed = true);
      return;
    }
    final controller = VideoPlayerController.networkUrl(url);
    _controller = controller;
    try {
      await controller.initialize();
      await controller.play();
      if (mounted) setState(() {});
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    return Scaffold(
      key: const Key('clipPlayer'),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.item.title),
      ),
      body: Center(
        child: _failed
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.cameraClipFailed,
                  key: const Key('clipFailed'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              )
            : !ready
            ? const CircularProgressIndicator(color: Colors.white70)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                  VideoProgressIndicator(controller, allowScrubbing: true),
                  ValueListenableBuilder(
                    valueListenable: controller,
                    builder: (context, value, _) => IconButton(
                      key: const Key('clipPlayPause'),
                      iconSize: 48,
                      color: Colors.white,
                      tooltip: value.isPlaying
                          ? l10n.cameraClipPause
                          : l10n.cameraClipPlay,
                      icon: Icon(
                        value.isPlaying
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                      ),
                      onPressed: value.isPlaying
                          ? controller.pause
                          : controller.play,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
