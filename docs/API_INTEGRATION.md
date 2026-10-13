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
`config/area_registry/list`, `config/device_registry/list` i `config/entity_registry/list` koristi zvanični HA frontend, ali nisu opisane na stranici developer dokumentacije. Zato su opcione: ako komanda ne uspe (npr. stariji server ili korisnik bez prava), aplikacija radi dalje bez prostorija i informacija o proizvođaču i protokolu. Iz odgovora se čitaju samo polja `area_id`, `name`, `icon`, `picture` / `id`, `name`, `name_by_user`, `manufacturer`, `model`, `area_id`, `identifiers`, `connections`, `via_device_id` / `entity_id`, `device_id`, `area_id`, `platform`, `entity_category`, `hidden_by`, `disabled_by`.

`config/device_registry/update` (`device_id`, `name_by_user`, `area_id`) takođe koristi frontend i nije u developer dokumentaciji; aplikacija ga koristi samo u koraku „Dodaj uređaj → Podesi” (ime i prostorija novog uređaja). Ako ne uspe (npr. korisnik nije administrator), poruka upućuje na HA podešavanja.

## Dodavanje Wi-Fi/LAN uređaja (pronađenih na mreži)

Koristi API HA frontenda (nije u developer dokumentaciji, potreban je administrator), pa je opciono i uz jasnu poruku kad nije dostupno:
- WS `config_entries/flow/progress` – tokovi koje je HA sam pokrenuo kad je pronašao uređaj (prikazuju se samo izvori `zeroconf`, `ssdp`, `dhcp`, `bluetooth`, `homekit`, `mqtt`, `usb`, …).
- REST `GET` / `POST /api/config/config_entries/flow/<flow_id>` – trenutni korak i slanje odgovora; `flow_id` se proverava (`[A-Za-z0-9_-]`).
- WS `frontend/get_translations` (`category: config`) – naslovi, opisi, nazivi polja i poruke o greškama na jeziku aplikacije (rezervno engleski).
- Formulari se crtaju iz `data_schema` (tekst, broj, da/ne, izbor; klasični `type` i noviji `selector`). Polja sa „password/key/token/secret/pin” u imenu su skrivena i nikad se ne loguju. Koraci koje aplikacija ne ume (prijava u pregledaču i sl.) upućuju na HA.

## Dodavanje Zigbee uređaja

- `GET /api/services` (dokumentovano) – otkrivanje: ZHA ako postoji servis `zha.permit`; Zigbee2MQTT ako postoji `mqtt.publish` i poznat je Zigbee2MQTT bridge uređaj.
- ZHA: `POST /api/services/zha/permit` sa `{"duration": 180}` (0 zatvara; najviše 254 s).
- Zigbee2MQTT: `POST /api/services/mqtt/publish` na temu `<base_topic>/bridge/request/permit_join` sa `{"value": true, "time": 180}` (Z2M 2.x koristi `time`, 1.x `value`; šalju se oba). Tema se proverava (`[A-Za-z0-9_-/]`).
- Uparivanje se zatvara kad istekne vreme, na „Zaustavi” i kad se ekran napusti. Novi uređaji se prepoznaju po HA uređajima/entitetima koji nisu postojali kad je uparivanje počelo (registri se osvežavaju na `device_registry_updated`).

Komande uređajima se šalju preko REST-a (`POST /api/services/<domain>/<service>`), vidi [DEVICE_CAPABILITIES.md](DEVICE_CAPABILITIES.md#komande).
