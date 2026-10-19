import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/edge_fade.dart';
import '../../../app/localization/l10n.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../dashboard/application/home_summaries.dart';
import '../../devices/application/device_providers.dart';
import '../../devices/data/home_state_repository.dart';
import '../../devices/domain/device_command.dart';
import '../../devices/presentation/device_actions.dart';
import '../../devices/presentation/device_presentation.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../rooms/presentation/room_card.dart';
import '../../weather/application/weather_providers.dart';
import '../../weather/domain/weather.dart';
import '../../weather/presentation/weather_labels.dart';
import '../../household/application/household_providers.dart';
import '../../household/presentation/person_avatar.dart';
import '../application/kiosk_controller.dart';
import '../../calendar/presentation/calendar_browser.dart';
import '../../calendar/presentation/calendar_widgets.dart';
import '../../assist/presentation/assist_sheet.dart';
import '../../devices/domain/capability.dart';
import '../../media/application/media_providers.dart';
import '../../media/presentation/media_artwork.dart';
import '../../media/presentation/media_sheet.dart';
import '../../devices/presentation/all_lights.dart';
import 'glass.dart';

part 'kiosk_weather_panel.dart';
part 'kiosk_rooms_panel.dart';
part 'kiosk_shortcuts_panel.dart';
part 'kiosk_status_bar.dart';

/// Large clock with small seconds and the date underneath.
class KioskHeaderClock extends StatefulWidget {
  const KioskHeaderClock({super.key, this.alignEnd = false, this.subtitle});

  final bool alignEnd;

  /// Shown after the date, e.g. the home's name.
  final String? subtitle;

  @override
  State<KioskHeaderClock> createState() => _KioskHeaderClockState();
}

class _KioskHeaderClockState extends State<KioskHeaderClock> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final theme = Theme.of(context);
    return Semantics(
      label:
          '${DateFormat.Hm(locale).format(_now)}, '
          '${DateFormat.MMMMEEEEd(locale).format(_now)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: widget.alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat.Hm(locale).format(_now),
                style: theme.textTheme.displayLarge?.copyWith(
                  color: GlassColors.text,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -2,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('ss').format(_now),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: GlassColors.faint,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              toBeginningOfSentenceCase(
                DateFormat.MMMMEEEEd(locale).format(_now),
                locale,
              ),
              ?widget.subtitle,
            ].join(' · '),
            style: theme.textTheme.titleMedium?.copyWith(
              color: GlassColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Current time, refreshed every 30 s, for "… minutes ago" labels.
final kioskNowProvider = Provider<DateTime>((ref) {
  final timer = Timer(const Duration(seconds: 30), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return DateTime.now();
});

/// Household members' avatars.
class KioskPeople extends ConsumerWidget {
  const KioskPeople({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(peopleIdsProvider);
    if (ids.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: context.l10n.householdTitle,
      child: Row(
        key: const Key('kioskPeople'),
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final id in ids.take(6))
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: PersonAvatar(personId: id, size: 48),
            ),
        ],
      ),
    );
  }
}

/// Agenda and month of the Home Assistant calendars.
class KioskCalendarPanel extends ConsumerWidget {
  const KioskCalendarPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.l10n.localeName;
    return GlassPanel(
      key: const Key('kioskCalendar'),
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
      child: CalendarBrowser(
        palette: CalendarPalette.glass,
        fitGrid: true,
        header: GlassTitle(
          toBeginningOfSentenceCase(
            DateFormat.MMMMEEEEd(locale).format(ref.watch(kioskNowProvider)),
            locale,
          ),
        ),
      ),
    );
  }
}
