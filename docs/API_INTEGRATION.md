# Home Assistant integracija

Koriste se isključivo dokumentovani API-ji:
- REST: https://developers.home-assistant.io/docs/api/rest/
- WebSocket: https://developers.home-assistant.io/docs/api/websocket/
- Autentifikacija: https://developers.home-assistant.io/docs/auth_api/

## Otkrivanje servera (zeroconf)
Home Assistant se oglašava kao `_home-assistant._tcp` (integracija *Zeroconf*, deo `default_config`). Iz TXT zapisa se čitaju `location_name`, `version`, `uuid`, `internal_url` i `base_url`. Izbor adrese i pravila (samo lokalne adrese, IPv4 pre `.local`) opisani su u `server_discovery.dart`. Pronađena adresa prolazi kroz istu proveru kao ručno uneta (`GET /api/` → 401).

## REST

| Poziv | Gde | Svrha |
|---|---|---|
| `GET /api/` bez tokena | `probe()` | `401` ⇒ HA API postoji i traži autentifikaciju |
| `GET /api/` sa tokenom | `verifyAccessToken()` | provera tokena (`{"message":"API running."}`) |
| `GET /api/config` | `fetchConfig()` | naziv lokacije, verzija, vremenska zona, jedinice |
| `GET /api/states` | `fetchStates()` | početno učitavanje svih entiteta |
| `POST /api/services/<domain>/<service>` | `callService()` | komande; odgovor je lista promenjenih stanja |
| `GET /api/history/period/<start>?filter_entity_id=&end_time=&minimal_response&no_attributes` | `fetchHistory()` | istorija jednog entiteta (24 h / 7 dana) za grafikon ili vremensku traku |
| `GET /api/logbook/<start>?entity=&end_time=` | `fetchLogbook()` | aktivnost uređaja u poslednja 24 h (uz oznaku da li je promenu napravila osoba); bez `entity` – aktivnost celog doma (ekran Aktivnost) |
| `GET /api/services` | `fetchServices()` | dostupni servisi po domenu (otkrivanje ZHA/Zigbee2MQTT) |
| `POST /api/conversation/process` | `processConversation()` | Assist: tekstualna komanda/pitanje (`text`, `language`, `conversation_id`); odgovor `response.speech.plain.speech`, `response_type` |
| `GET /api/calendars` | `fetchCalendars()` | lista kalendara (Google, CalDAV, Local Calendar…) |
| `GET /api/calendars/<entity_id>?start=&end=` | `fetchCalendarEvents()` | događaji u opsegu (ponavljajući već razvijeni); `start`/`end` kao `dateTime` ili `date` (ceo dan, kraj isključiv); ID se proverava (`calendar.[a-z0-9_]+`) |
| `GET /api/camera_proxy/<entity_id>` | `fetchImage()` | snimak kamere (JPEG/PNG); osvežava se svake 2 s samo dok je kamera prikazana |
| `GET <entity_picture>` (npr. `/api/image/serve/<id>/512x512`) | `fetchImage()` | slika ukućana; prihvataju se samo putanje na samom HA serveru koje počinju sa `/api/`, tako da token nikad ne ide drugom hostu; spoljne slike se ne učitavaju (prikazuju se inicijali); najviše 5 MB |

Mapiranje statusa: `401` → authentication, `403` → authorization, `400/405/422` → validation, `404` i `5xx` → server; timeout-i → timeout; socket greške → network; TLS → certificate.

## WebSocket (`/api/websocket`)

```
server: {"type":"auth_required","ha_version":"…"}
client: {"type":"auth","access_token":"…"}
server: {"type":"auth_ok","ha_version":"…"}  |  {"type":"auth_invalid","message":"…"}

client: {"id":1,"type":"subscribe_events","event_type":"state_changed"}
server: {"id":1,"type":"result","success":true,"result":null}
server: {"id":1,"type":"event","event":{"event_type":"state_changed","data":{"entity_id":…,"old_state":…,"new_state":…},…}}

client: {"id":2,"type":"ping"}      server: {"id":2,"type":"pong"}
client: {"id":3,"type":"unsubscribe_events","subscription":1}
```

`id` počinje od 1 na svakoj novoj vezi i strogo raste. Greške komandi (`success:false`) mapiraju se po `error.code`: `unauthorized` → authorization, `invalid_format` → validation, `not_found` → unavailableEntity, `not_supported` → unsupportedFeature, ostalo → server. Ako server pošalje niz poruka (coalescing), obrađuje se svaka.

## Sinhronizacija stanja (implementirano, `HomeStateRepository`)
1. Posle `auth_ok` WebSocket menadžer ponovo šalje `subscribe_events` za `state_changed` i za `area_registry_updated`, `device_registry_updated` i `entity_registry_updated`.
2. Repozitorijum zatim preko **istog soketa** šalje `config/area_registry/list`, `config/device_registry/list`, `config/entity_registry/list`, `get_states` i `get_config`. HA obrađuje poruke redom, pa je snimak sigurno napravljen posle početka pretplate.
3. Događaji pristigli dok se snimak učitava čuvaju se u redu i primenjuju posle njega. Događaj stariji (`last_updated`) od poznatog stanja se odbacuje.
4. Pri gubitku veze podaci ostaju vidljivi sa statusom `stale`; posle reconnect-a ceo postupak se ponavlja.
5. Događaj o promeni registra pokreće ponovno učitavanje registara (debounce 500 ms).

## Vreme
- Trenutno stanje iz `weather` entiteta (stanje = uslov, atributi `temperature`, `humidity`, `wind_speed`…). Podrazumevano `weather.forecast_home` (integracija Met.no).
- Prognoza preko dokumentovanog servisa `weather.get_forecasts` (`POST /api/services/weather/get_forecasts?return_response`, `type: daily` i `type: hourly`); odgovor `service_response.<entity>.forecast`. Ako entitet nema prognozu po satima (greška servisa), prikazuje se samo dnevna.
- Opciono, za lokaciju telefona: MET Norway Locationforecast 2.0 `compact` (User-Agent sa identifikacijom aplikacije, koordinate na 2 decimale, keš 30 min, oznaka CC BY 4.0).

## Energija
- `energy/get_prefs` – HA Energy podešavanja: koji statistički nizovi su uvoz/izvoz mreže, solar, baterija (punjenje = `stat_energy_to`, pražnjenje = `stat_energy_from`), gas i potrošnja po uređaju. Odgovor `not_found` znači da Energy nije podešen.
- `recorder/statistics_during_period` sa `types: ["change"]`, `period: hour|day` i `units: {energy: kWh, volume: m³}` – promena po satu/danu. `start` je epoch u milisekundama (stariji HA: ISO tekst); oba formata se prihvataju.
- Potrošnja doma = uvoz + solar − izvoz − punjenje baterije + pražnjenje baterije (definicija HA). Periodi bez podataka su „nema podatka”, ne 0.
- Obe komande koristi HA frontend, ali nisu u developer dokumentaciji – opcione su; bez njih ekran jasno kaže da Energy nije dostupan.

## Registri
`config/area_registry/list`, `config/device_registry/list`, `config/entity_registry/list` i `config/floor_registry/list` (spratovi; HA 2024.4+) koristi zvanični HA frontend, ali nisu opisane na stranici developer dokumentacije. Zato su opcione: ako komanda ne uspe (npr. stariji server ili korisnik bez prava), aplikacija radi dalje bez prostorija i informacija o proizvođaču i protokolu. Iz odgovora se čitaju samo polja `area_id`, `name`, `icon`, `picture` / `id`, `name`, `name_by_user`, `manufacturer`, `model`, `area_id`, `identifiers`, `connections`, `via_device_id` / `entity_id`, `device_id`, `area_id`, `platform`, `entity_category`, `hidden_by`, `disabled_by`.

`config/entity_registry/update` (`entity_id`, `name`, `area_id`) i `config/device_registry/update` (`device_id`, `name_by_user`, `area_id`) takođe koristi frontend i nije u developer dokumentaciji; aplikacija ga koristi samo u koraku „Dodaj uređaj → Podesi” (ime i prostorija novog uređaja). Ako ne uspe (npr. korisnik nije administrator), poruka upućuje na HA podešavanja.

## Poruke iz HA (mobile_app, dokumentovani native app API)

- `POST /api/mobile_app/registrations` sa `app_data: {push_websocket_channel: true}` → `webhook_id` (tajna, Keystore/Keychain).
- WebSocket `mobile_app/push_notification_channel` (`webhook_id`, `support_confirm: true`) → događaji `{message, title?, data?, hass_confirm_id}`; potvrda `mobile_app/push_notification_confirm`. Posle prekida veze pretplata se obnavlja.
- Automatizacije: `notify.mobile_app_<slug imena uređaja>`. Podržani `data` ključevi: `tag`, `actions` (`action`/`title`, do 3; `REPLY` i `URI` se ignorišu), `entity_id` (dodir otvara uređaj); poruka `clear_notification` sa `tag` briše obaveštenje.
- Dugme → WebSocket `webhook/handle` (`webhook_id`, `method: POST`, `body` = `{"type":"fire_event","data":{"event_type":"mobile_app_notification_action","event_data":{"action":…,"tag":…}}}`), dokumentovani mobile_app webhook.

Primer automatizacije:

```yaml
actions:
  - action: notify.mobile_app_zidni_tablet
    data:
      title: Ulazna vrata
      message: Neko zvoni.
      data:
        tag: vrata
        entity_id: camera.front_yard
        actions:
          - action: UPALI_SVETLO
            title: Upali svetlo
          - action: IGNORISI
            title: Ignoriši
  - wait_for_trigger:
      - trigger: event
        event_type: mobile_app_notification_action
        event_data:
          action: UPALI_SVETLO
    timeout: "00:02:00"
  - action: light.turn_on
    target:
      entity_id: light.hallway
```

## Matter preko Bluetooth-a (Android)

- Google Play services: `Matter.getCommissioningClient(activity).commissionDevice(CommissioningRequest{commissioningService = MatterCommissioningService})` → Googleovi ekrani (QR, BLE, Wi-Fi/Thread).
- `MatterCommissioningService.onCommissioningRequested(metadata)` → Flutter → WS `matter/commission_on_network` (`pin` = `metadata.passcode`, `ip_addr` = adresa uređaja; link-local/scoped IPv6 se izostavlja pa ga server sam pronalazi) → `sendCommissioningComplete` ili `sendCommissioningError(OTHER)`.
- Zahteva administratorski nalog u HA i Matter integraciju; Thread uređajima treba Thread border router poznat telefonu.

## Tajmer uređaja

- `POST /api/config/script/config/osh_timer_<entity>` (frontend API, admin): `mode: restart`, `sequence: [delay {minutes: "{{ minutes | int(0) }}"}, choose (service == 'turn_on') → homeassistant.turn_on, inače homeassistant.turn_off]`, cilj = entitet uređaja.
- Pokretanje: `script.turn_on` sa `variables: {minutes, service}`; otkazivanje: `script.turn_off`. Da li tajmer radi, vidi se po stanju `script.osh_timer_…` (`on`).

## Automatizacije (jednostavan editor)

- REST HA frontenda `GET` / `POST` / `DELETE /api/config/automation/config/<id>` (administrator; ID se proverava `[A-Za-z0-9_]`). HA posle čuvanja sam ponovo učitava automatizacije.
- Format 2024.10+: `triggers` (jedan ili više: `time` / `state` / `numeric_state` sa `above` ili `below` / `sun` sa `offset`), `conditions` (`condition: time` sa `weekday` i/ili `after`/`before`; `condition: state` za uređaj; `sun.sun` `below_horizon`/`above_horizon` za mrak/dan), `actions` (`action: <domen>.<servis>`, `target.entity_id`).
- Iz aplikacije se ne mogu napraviti radnje otključavanja ni isključivanja alarma; brisanje samo za UI automatizacije (atribut `id`).

## Scene

- REST HA frontenda `POST` / `DELETE /api/config/scene/config/<id>` (administrator): `{"id", "name", "entities": {"<entity_id>": {"state", "brightness", "rgb_color" | "color_temp_kelvin", "current_position", "temperature", "percentage"}}}`.

## Obaveštenja

- WS `persistent_notification/subscribe` (frontend; pretplata – događaji `current` / `added` / `updated` / `removed`); ako nije dostupno, kartica se ne prikazuje.
- Odbacivanje dokumentovanim servisima `persistent_notification.dismiss` (`notification_id`) i `persistent_notification.dismiss_all`.
- Markdown iz poruke se prikazuje kao običan tekst; linkovi se ne otvaraju.

## Dodavanje Wi-Fi/LAN uređaja (pronađenih na mreži)

Koristi API HA frontenda (nije u developer dokumentaciji, potreban je administrator), pa je opciono i uz jasnu poruku kad nije dostupno:
- WS `config_entries/flow/progress` – tokovi koje je HA sam pokrenuo kad je pronašao uređaj (prikazuju se samo izvori `zeroconf`, `ssdp`, `dhcp`, `bluetooth`, `homekit`, `mqtt`, `usb`, …).
- REST `GET` / `POST /api/config/config_entries/flow/<flow_id>` – trenutni korak i slanje odgovora; `flow_id` se proverava (`[A-Za-z0-9_-]`).
- WS `frontend/get_translations` (`category: config`) – naslovi, opisi, nazivi polja i poruke o greškama na jeziku aplikacije (rezervno engleski).
- Formulari se crtaju iz `data_schema` (tekst, broj, da/ne, izbor; klasični `type` i noviji `selector`). Polja sa „password/key/token/secret/pin” u imenu su skrivena i nikad se ne loguju. Koraci koje aplikacija ne ume (prijava u pregledaču i sl.) upućuju na HA.

## Dodavanje Matter uređaja (deljenog iz druge aplikacije)

- Otkrivanje: `matter` u `components` iz `/api/config`.
- WS `matter/commission` sa `{"code": "<MT:… ili 11/21 cifara>", "network_only": true}` (frontend API, administrator). Kod se pre slanja proverava (QR `MT:` ili ručni kod sa Verhoeff kontrolnom cifrom).
- QR se skenira kamerom telefona (`mobile_scanner`, ne na webu); slika se ne čuva. Potpuno novi uređaji preko Bluetooth-a zahtevaju nativne Matter API-je (Companion app) – nije u aplikaciji.

## Dodavanje Z-Wave uređaja

Frontend WS komande Z-Wave JS integracije (administrator), opciono:
- `config_entries/get` (`domain: zwave_js`) – `entry_id` učitane integracije.
- `zwave_js/add_node` (`inclusion_strategy: 0` = S2 kad uređaj podržava) – pretplata koja šalje događaje (`inclusion started`, `node found`, `grant security classes`, `validate dsk and enter pin`, `interview started/completed/failed`, `device registered`); otkazivanje pretplate zaustavlja uključivanje (i kad se ekran napusti).
- `zwave_js/grant_security_classes`, `zwave_js/validate_dsk_and_enter_pin` (PIN = prvih 5 cifara DSK-a sa nalepnice), `zwave_js/provision_smart_start_node` (SmartStart QR, počinje sa „90”).
- `HaWebSocketManager.subscribeCommand()` – opšta podrška za komande koje odgovaraju nizom događaja; `unsubscribe_events` pri otkazivanju; prekid veze završava tok greškom.

## Dodavanje Zigbee uređaja

- `GET /api/services` (dokumentovano) – otkrivanje: ZHA ako postoji servis `zha.permit`; Zigbee2MQTT ako postoji `mqtt.publish` i poznat je Zigbee2MQTT bridge uređaj.
- ZHA: `POST /api/services/zha/permit` sa `{"duration": 180}` (0 zatvara; najviše 254 s).
- Zigbee2MQTT: `POST /api/services/mqtt/publish` na temu `<base_topic>/bridge/request/permit_join` sa `{"value": true, "time": 180}` (Z2M 2.x koristi `time`, 1.x `value`; šalju se oba). Tema se proverava (`[A-Za-z0-9_-/]`).
- Uparivanje se zatvara kad istekne vreme, na „Zaustavi” i kad se ekran napusti. Novi uređaji se prepoznaju po HA uređajima/entitetima koji nisu postojali kad je uparivanje počelo (registri se osvežavaju na `device_registry_updated`).

Komande uređajima se šalju preko REST-a (`POST /api/services/<domain>/<service>`), vidi [DEVICE_CAPABILITIES.md](DEVICE_CAPABILITIES.md#komande).

## Liste (`todo`)

Provereno u izvornom kodu HA (`homeassistant/components/todo`):

| Šta | Poziv |
|---|---|
| Stavke uživo | WS `todo/item/subscribe` `{entity_id}` → događaji `{items: [...]}` (prvi odmah) |
| Stavke jednom (stariji HA) | WS `todo/item/list` `{entity_id}` → `{items: [...]}` |
| Dodavanje | `todo.add_item` `{entity_id, item}` (zahteva funkciju 1) |
| Štikliranje / izmena | `todo.update_item` `{entity_id, item: uid, status: needs_action\|completed}` ili `rename` (funkcija 4) |
| Brisanje | `todo.remove_item` `{entity_id, item: [uid]}` (funkcija 2) |
| Brisanje urađenih | `todo.remove_completed_items` `{entity_id}` (funkcija 2) |

Stavka: `uid`, `summary`, `status`, opciono `due`, `description`. Stanje entiteta je broj neurađenih stavki.

## Tabla (`image_upload`)

Provereno u izvornom kodu HA (`homeassistant/components/image_upload`, `helpers/collection.py`):

| Šta | Poziv | Ko sme |
|---|---|---|
| Nova verzija strane | `POST /api/image/upload`, multipart polje `file` (PNG), do 10 MB → `{id, name, …}` | svaki prijavljeni korisnik |
| Spisak i promene uživo | WS `image/subscribe` → događaji su liste `{change_type, image_id, item}` (prvi sa svim slikama) | svaki korisnik |
| Sadržaj | `GET /api/image/serve/<id>/original` (fajl bajt po bajt kako je poslat) | **bez prijave** (dovoljan je id) |
| Brisanje | WS `image/delete {image_id}` | samo administrator |

Strane se zovu `osh-board_<strana>_<ms>.png`; ostale slike u HA aplikacija ne dira. Potezi su JSON (base64) u PNG `tEXt` bloku sa ključem `osh-board`.

## Senzori uređaja (Mobile App)

Provereno u `homeassistant/components/mobile_app/webhook.py`. Šalje se kroz WS `webhook/handle` sa telom `{type, data}`:

- `register_sensor`: `{type: sensor|binary_sensor, unique_id, name, state, device_class?, unit_of_measurement?, state_class?, icon?, attributes?}` → 201. HA entitet nazove „<ime uređaja> <ime senzora>”.
- `update_sensor_states`: lista `{type, unique_id, state, icon?, attributes?}` → 200; neregistrovan senzor HA odbija.

Aplikacija šalje: `battery_level` (%), `battery_state` (atribut `charger`), `is_charging` (binary, `battery_charging`), `kiosk` (binary).

## Ključna reč (`assist_pipeline/run`)

Provereno u `homeassistant/components/assist_pipeline` (`websocket_api.py`, `default_pipeline.py`, `run.py`) i `websocket_api/http.py`:

- Komanda: WS `assist_pipeline/run` `{start_stage: wake_word, end_stage: intent, input: {sample_rate: 16000, timeout: 0, noise_suppression_level: 2, auto_gain_dbfs: 0}}`. `input.timeout: 0` = bez isteka zbog tišine; ceo run i dalje ističe posle podrazumevanih 300 s (događaj `error` `timeout`), pa aplikacija pokreće novi. Koristi se preferirani Assist pipeline.
- Događaji (`event: {type, data, timestamp}`): `run-start` (`runner_data.stt_binary_handler_id`), `wake_word-start`, `wake_word-end`, `stt-start`, `stt-vad-start/end`, `stt-end` (`stt_output.text`), `intent-start`, `intent-end` (`intent_output` = isti oblik kao `conversation/process`), `run-end`, `error` (`code`, `message`).
- Zvuk: binarne WS poruke, prvi bajt je id binarnog rukovaoca, ostalo sirovi PCM 16 kHz/16-bit/mono; prazna poruka (samo id) završava zvuk. Aplikacija ga zaustavlja posle `stt-end`.
- Greške pri proveri (pre `result`): `wake-engine-missing`, `wake-provider-missing` (nema openWakeWord-a), `pipeline-not-found`. Otkazivanje pretplate (`unsubscribe_events`) prekida run.
- Odgovor izgovara tablet sam (lokalni TTS), pa se `tts` faza ne koristi.

## NFC nalepnice (`tag`)

Provereno u `homeassistant/components/tag` i `mobile_app/webhook.py`, format URL-a u dokumentaciji companion aplikacija:

- Na nalepnici: NDEF URI `https://www.home-assistant.io/tag/<tag_id>` (kao zvanične aplikacije).
- Očitavanje: Mobile App webhook `scan_tag` `{tag_id}` (kroz WS `webhook/handle`) → `tag_scanned`; nepoznata nalepnica se dodaje sama.
- Spisak: WS `tag/list`; nova: WS `tag/create {tag_id, name}` (administrator).
- Automatizacija: okidač `{trigger: tag, tag_id}`.

