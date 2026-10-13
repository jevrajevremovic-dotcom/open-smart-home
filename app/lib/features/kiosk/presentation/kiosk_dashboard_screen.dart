import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n.dart';
import '../../../app/router/app_router.dart';
import '../../../core/widgets/status_widgets.dart';
import '../../authentication/application/session_controller.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import 'kiosk_shell.dart';
import 'pin_dialog.dart';

/// Text is enlarged on the wall panel so it is readable from a distance.
const double kioskTextScale = 1.2;

/// Wraps kiosk pages with larger text.
class KioskScale extends StatelessWidget {
  const KioskScale({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = MediaQuery.textScalerOf(context).scale(1);
    return MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(base * kioskTextScale)),
      child: child,
    );
  }
}

/// Fullscreen wall-panel dashboard: clock, status and the regular
/// dashboard content with large controls; no standard navigation.
class KioskDashboardScreen extends ConsumerWidget {
  const KioskDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final title =
        ref.watch(serverConfigProvider).value?.locationName ?? l10n.appTitle;
    return Scaffold(
      body: MockModeBanner(
        child: SafeArea(
          child: KioskScale(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(child: KioskClock()),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const ConnectionIndicator(),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        key: const Key('kioskExit'),
                        tooltip: l10n.kioskExit,
                        icon: const Icon(Icons.lock_outline),
                        onPressed: () async {
                          if (await showKioskExitDialog(context, ref) &&
                              context.mounted) {
                            context.go(AppRoutes.home);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const Expanded(child: DashboardBody(kiosk: true)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
