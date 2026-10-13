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
| 8 | Drift cache, poslednja stanja, oznaka zastarelih podataka, sinhronizacija posle reconnect-a | ⏭ sledeće |
| 9 | Integration testovi, performanse, curenje memorije, dokumentacija, build | |

Kasnije: OAuth2 prijava, mDNS otkrivanje servera, energy dashboard, kamere, alarm panel, biometrijska potvrda, multi-home, uloge, instalaterski režim, push, sopstveni backend, vizuelni editor automatizacija, Docker Compose gateway (HA, Mosquitto, Zigbee2MQTT, Z-Wave JS UI, Matter Server, OTBR).
