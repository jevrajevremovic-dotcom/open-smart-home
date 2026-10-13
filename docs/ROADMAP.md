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

Urađeno posle 0.1.0: OAuth2 prijava na webu ✅, mDNS otkrivanje servera ✅

Kasnije: OAuth2 na mobilnom, energy dashboard, kamere, alarm panel, biometrijska potvrda, multi-home, uloge, instalaterski režim, push, sopstveni backend, vizuelni editor automatizacija.
