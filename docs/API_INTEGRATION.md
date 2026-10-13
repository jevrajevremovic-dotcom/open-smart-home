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

## Registri
`config/area_registry/list`, `config/device_registry/list` i `config/entity_registry/list` koristi zvanični HA frontend, ali nisu opisane na stranici developer dokumentacije. Zato su opcione: ako komanda ne uspe (npr. stariji server ili korisnik bez prava), aplikacija radi dalje bez prostorija i informacija o proizvođaču i protokolu. Iz odgovora se čitaju samo polja `area_id`, `name`, `icon`, `picture` / `id`, `name`, `name_by_user`, `manufacturer`, `model`, `area_id`, `identifiers`, `connections`, `via_device_id` / `entity_id`, `device_id`, `area_id`, `platform`, `entity_category`, `hidden_by`, `disabled_by`.

Komande uređajima se šalju preko REST-a (`POST /api/services/<domain>/<service>`), vidi [DEVICE_CAPABILITIES.md](DEVICE_CAPABILITIES.md#komande).
