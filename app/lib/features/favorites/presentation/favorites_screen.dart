import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/l10n.dart';
import '../../../core/utils/value_list.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../devices/application/device_providers.dart';
import '../../devices/presentation/device_grid.dart';
import '../../devices/presentation/stale_data_banner.dart';
import '../application/favorites_controller.dart';

/// Favorite ids that still exist on the server, in the user's order.
final existingFavoritesProvider = Provider<ValueList<String>>((ref) {
  final favorites = ref.watch(favoritesProvider);
  final devices = ref.watch(homeSnapshotProvider.select((s) => s.devices));
  // Not synced yet: keep the stored order; tiles of missing devices hide.
  if (devices.isEmpty) return ValueList(favorites);
  return ValueList([
    for (final id in favorites)
      if (devices.containsKey(id)) id,
  ]);
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ids = ref.watch(existingFavoritesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navFavorites)),
      body: MockModeBanner(
        child: CustomScrollView(
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(child: StaleDataBanner()),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: ids.isEmpty
                  ? SliverToBoxAdapter(
                      child: EmptyHint(
                        icon: Icons.star_border,
                        text: l10n.favoritesEmpty,
                      ),
                    )
                  : DeviceSliverGrid(deviceIds: ids),
            ),
          ],
        ),
      ),
    );
  }
}
