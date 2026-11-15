// What tool/provision.dart reads from a new Home Assistant and the handover
// report it writes. Pure functions, so they are tested without a server.

/// Everything read from one Home Assistant over its WebSocket API.
class ProvisionData {
  ProvisionData({
    required this.config,
    required this.states,
    required this.areas,
    required this.devices,
    required this.entities,
    required this.entries,
    this.backup,
  });

  /// `get_config`.
  final Map<String, Object?> config;

  /// `get_states`.
  final List<Map<String, Object?>> states;

  /// `config/area_registry/list`, `config/device_registry/list`,
  /// `config/entity_registry/list`.
  final List<Map<String, Object?>> areas;
  final List<Map<String, Object?>> devices;
  final List<Map<String, Object?>> entities;

  /// `config_entries/get`: the integrations.
  final List<Map<String, Object?>> entries;

  /// `backup/config/info` (`null`: no backup integration / older HA).
  final Map<String, Object?>? backup;
}

/// Wanted areas that do not exist yet (names compared without case).
List<String> missingAreas(
  List<Map<String, Object?>> existing,
  List<String> wanted,
) {
  final have = {for (final a in existing) '${a['name']}'.trim().toLowerCase()};
  return [
    for (final w in wanted)
      if (w.trim().isNotEmpty && !have.contains(w.trim().toLowerCase()))
        w.trim(),
  ];
}

/// Core settings to change: only the ones given and different.
Map<String, Object?> coreChanges(
  Map<String, Object?> config, {
  String? timeZone,
  String? country,
  String? currency,
}) => {
  if (timeZone != null && config['time_zone'] != timeZone)
    'time_zone': timeZone,
  if (country != null && config['country'] != country) 'country': country,
  if (currency != null && config['currency'] != currency) 'currency': currency,
};

/// How often automatic backups run, or `null` when they are off.
String? backupSchedule(Map<String, Object?>? backup) {
  final config = backup?['config'];
  if (config is! Map) return null;
  final schedule = config['schedule'];
  final recurrence = schedule is Map ? schedule['recurrence'] : null;
  return recurrence is String && recurrence != 'never' ? recurrence : null;
}

/// Last successful automatic backup, if HA reports one.
String? lastBackup(Map<String, Object?>? backup) {
  final config = backup?['config'];
  final last = config is Map ? config['last_completed_automatic_backup'] : null;
  return last is String ? last : null;
}

String _name(Map<String, Object?> s) {
  final attrs = s['attributes'];
  final n = attrs is Map ? attrs['friendly_name'] : null;
  return n is String && n.isNotEmpty ? n : '${s['entity_id']}';
}

const _notDevices = {
  'automation',
  'button',
  'conversation',
  'event',
  'image',
  'scene',
  'script',
  'stt',
  'tts',
  'update',
  'zone',
};

/// A finding of the automatic checks: `ok` or something to fix.
typedef Check = ({bool ok, String text});

List<Check> handoverChecks(ProvisionData d) {
  final unavailable = [
    for (final s in d.states)
      if (s['state'] == 'unavailable' &&
          !_notDevices.contains('${s['entity_id']}'.split('.').first))
        _name(s),
  ];
  final low = [
    for (final s in d.states)
      if ('${s['entity_id']}'.startsWith('sensor.') &&
          (s['attributes'] as Map?)?['device_class'] == 'battery' &&
          (double.tryParse('${s['state']}') ?? 100) <= 15)
        '${_name(s)} (${s['state']} %)',
  ];
  final updates = [
    for (final s in d.states)
      if ('${s['entity_id']}'.startsWith('update.') && s['state'] == 'on')
        _name(s),
  ];
  final noArea = [
    for (final dev in d.devices)
      if (dev['area_id'] == null &&
          dev['disabled_by'] == null &&
          dev['entry_type'] != 'service')
        '${dev['name_by_user'] ?? dev['name']}',
  ];
  final failed = [
    for (final e in d.entries)
      if (e['state'] != 'loaded' && e['disabled_by'] == null)
        '${e['title']} (${e['domain']}: ${e['state']})',
  ];
  final schedule = backupSchedule(d.backup);
  final external = d.config['external_url'];
  String list(List<String> l) => l.length <= 8
      ? l.join(', ')
      : '${l.take(8).join(', ')} … (+${l.length - 8})';
  return [
    unavailable.isEmpty
        ? (ok: true, text: 'Svi uređaji se javljaju.')
        : (
            ok: false,
            text: 'Nedostupno (${unavailable.length}): ${list(unavailable)}',
          ),
    low.isEmpty
        ? (ok: true, text: 'Nema praznih baterija.')
        : (ok: false, text: 'Prazne baterije: ${list(low)}'),
    noArea.isEmpty
        ? (ok: true, text: 'Svi uređaji su u nekoj prostoriji.')
        : (
            ok: false,
            text: 'Bez prostorije (${noArea.length}): ${list(noArea)}',
          ),
    failed.isEmpty
        ? (ok: true, text: 'Sve integracije su učitane.')
        : (ok: false, text: 'Integracije sa greškom: ${list(failed)}'),
    updates.isEmpty
        ? (ok: true, text: 'Nema ažuriranja na čekanju.')
        : (ok: false, text: 'Ažuriranja na čekanju: ${list(updates)}'),
    schedule == null
        ? (
            ok: false,
            text:
                'Automatski backup nije uključen (Podešavanja → Sistem → '
                'Rezervne kopije); ključ za šifrovanje predati vlasniku.',
          )
        : (
            ok: true,
            text:
                'Automatski backup: $schedule'
                '${lastBackup(d.backup) == null ? ', još nijedan uspešan' : ', poslednji ${lastBackup(d.backup)}'}.',
          ),
    external is String && external.isNotEmpty
        ? (ok: true, text: 'Spoljna adresa: $external')
        : (
            ok: false,
            text:
                'Spoljna adresa nije podešena (Tailscale/Nabu Casa) — servis '
                'na daljinu neće biti moguć.',
          ),
  ];
}

/// The handover report (Markdown): what was installed, what the checks
/// found, and what is checked by hand and signed. Names and counts only,
/// never a token or password.
String handoverReport(ProvisionData d, DateTime now, {String? host}) {
  final c = d.config;
  final date =
      '${now.day}.${now.month}.${now.year}. '
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  final devicesByArea = <String?, int>{};
  for (final dev in d.devices) {
    if (dev['disabled_by'] != null || dev['entry_type'] == 'service') continue;
    devicesByArea.update(
      dev['area_id'] as String?,
      (v) => v + 1,
      ifAbsent: () => 1,
    );
  }
  final domains = <String, int>{};
  for (final e in d.entries) {
    domains.update('${e['domain']}', (v) => v + 1, ifAbsent: () => 1);
  }
  final checks = handoverChecks(d);
  return [
    '# Zapisnik o primopredaji – ${c['location_name'] ?? 'Home Assistant'}',
    '',
    '| | |',
    '|---|---|',
    '| Datum | $date |',
    '| Server | ${host ?? '?'} |',
    '| Home Assistant | ${c['version'] ?? '?'} |',
    '| Vremenska zona | ${c['time_zone'] ?? '?'} |',
    '| Zemlja / valuta | ${c['country'] ?? '?'} / ${c['currency'] ?? '?'} |',
    '| Uređaja / entiteta | ${d.devices.length} / ${d.entities.length} |',
    '',
    '## Prostorije',
    '',
    for (final a in d.areas)
      '- ${a['name']}: ${devicesByArea[a['area_id']] ?? 0} uređaja',
    if ((devicesByArea[null] ?? 0) > 0)
      '- (bez prostorije): ${devicesByArea[null]} uređaja',
    '',
    '## Integracije',
    '',
    for (final e
        in (domains.entries.toList()..sort((a, b) => a.key.compareTo(b.key))))
      '- ${e.key}${e.value > 1 ? ' ×${e.value}' : ''}',
    '',
    '## Automatske provere',
    '',
    for (final ch in checks) '- ${ch.ok ? '✅' : '⚠️'} ${ch.text}',
    '',
    '## Proverava instalater (ručno)',
    '',
    '- [ ] Svaki uređaj uključen/isključen iz aplikacije, odziv do 1 s',
    '- [ ] Senzori (vrata, pokret, voda, dim) okinuti i viđeni u aplikaciji',
    '- [ ] Upozorenja (dim, voda, alarm) stižu na telefone ukućana',
    '- [ ] Ukućani imaju svoje HA naloge (ne administratorske) i prijavljeni su u aplikaciju',
    '- [ ] Zidni panel: vlasnik uređaja, kiosk PIN, pokretanje posle nestanka struje',
    '- [ ] Automatski backup uključen; ključ za šifrovanje predat vlasniku (ne čuva ga instalater)',
    '- [ ] Pristup na daljinu za servis dogovoren i opisan u ugovoru',
    '- [ ] Vlasnik zna: šta radi bez interneta, koga zove, kako se gasi server',
    '',
    'Instalater: ______________________   Vlasnik: ______________________',
    '',
  ].join('\n');
}
