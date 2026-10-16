# Plan razvoja

| Faza | Sadržaj | Status |
|---|---|---|
| 1 | Flutter projekat, struktura, lint, Riverpod, go_router, tema, lokalizacija, error model, logging | ✅ |
| 2 | Onboarding, adresa servera, validacija, provera dostupnosti, token, bezbedno čuvanje, odjava | ✅ |
| 3 | REST klijent, HA modeli, mapiranje grešaka, mock API | ✅ |
| 4 | WebSocket menadžer, auth, `state_changed`, reconnect, backoff | ✅ |
| — | Web platforma (JS/Wasm), hostovanje iz HA | ✅ |
| 5 | `SmartHomeDevice`, capability model, mapper (light, switch, sensor, binary_sensor, climate, scene), registri oblasti/uređaja | ✅ |
| 6 | Dashboard, prostorije, lista i detalji uređaja, favorites, scene | ✅ |
| 7 | Tablet grid, landscape, fullscreen, osnovni kiosk, velike kontrole | ✅ |
| 8 | Offline keš (snimak HA podataka), poslednja stanja, oznaka zastarelih podataka, sinhronizacija posle reconnect-a | ✅ |
| 9 | Integration testovi, performanse, curenje memorije, dokumentacija, build | ✅ |

Gateway: Docker Compose za Home Assistant, Mosquitto, Zigbee2MQTT, Z-Wave JS UI, Matter Server, OTBR i ESPHome (`gateway/`, [GATEWAY.md](GATEWAY.md)) ✅

## Urađeno posle 0.1.0

- OAuth2 prijava na webu, mDNS otkrivanje servera, energy dashboard ✅
- Vreme (HA, MET Norway uz pristanak; po satima i 7 dana), novi vizuelni stil, stakleni kiosk ✅
- Ukućani, statusi u kiosku, kalendar, kamere (snimci + uživo), mediji, Assist (tekst + glas) ✅
- Dodavanje uređaja: Zigbee, Wi-Fi/LAN (HA config flow), Matter (deljeni), Z-Wave (S2, SmartStart) ✅
- Istorija uređaja, obaveštenja, alarmni panel, ventilator/ovlaživač/usisivač/izbor/broj ✅
- Zaključavanje aplikacije i biometrijska potvrda kritičnih komandi, više domova ✅
- Izmena imena/prostorije, pretraga, redosled omiljenih, režim za decu i goste, jednostavan editor automatizacija ✅

## Sledeće

- OAuth2 na mobilnom ✅ (HA stranica u aplikaciji, `client_id` na `*.localhost`, bez hostovane stranice)
- Zamena `nsd` paketa sopstvenim kodom na Androidu (upozorenje o Kotlin Gradle Plugin-u) ✅
- Napredni editor automatizacija ✅ (uslovi, više okidača, numerički okidač, izmena postojećih)
- Android widget za početni ekran ✅, lokalna obaveštenja o kritičnim upozorenjima ✅, adresa van kuće ✅, dvostruki pljesak u kiosku ✅
- Poruke iz HA automatizacija (mobile_app, lokalno) ✅
- Poruke i kad je aplikacija zatvorena (Android servis u prvom planu, i posle restarta) ✅
- Poruke sa dugmićima (`mobile_app_notification_action`), `tag`, `clear_notification` ✅
- Kiosk: iskačuća kamera (zvono, pokret, vrata) ✅, tamnije noću i minimum na čuvaru ekrana ✅, raspored panela prevlačenjem ✅
- Provera kuće („Odlazim” / „Laku noć”) ✅
- Liste (spisak za kupovinu, zadaci) na telefonu i u kiosku ✅
- Dvotarifno brojilo (viša/niža tarifa) ✅
- Tabla za pisanje i crtanje (deljena preko HA) ✅
- Prijava korisničkim imenom i lozinkom na telefonu ✅, Tailscale adrese ✅
- Prilagodljiv početni ekran (izbor i redosled kartica) ✅
- Video uživo u iskačućoj kameri ✅
- Tajmer na uređaju („ugasi za 30 min”), izvršava HA ✅
- Istorija potrošnje po uređaju ✅
- Matter za potpuno nove uređaje preko Bluetooth-a ✅ (Google Play services; provera sa pravim uređajem na telefonu)
- Uloge (instalater) — treba definisati šta tačno obuhvata
- Release potpisivanje pravim ključem (ključ pravi i čuva vlasnik, nikad u repozitorijumu)
