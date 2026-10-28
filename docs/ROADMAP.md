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
- Ukućani, statusi u kiosku, kalendar, kamere (snimci + uživo), mediji, Assist (tekst + glas, izgovoreni odgovori, asistent telefona, ključna reč bez ruku na kiosku preko HA openWakeWord) ✅
- Kiosk se budi kad neko priđe (senzor iz HA ili kamera tableta, obrada samo na tabletu); simulacija prisustva kao HA automatizacija ✅
- Podsetnik kad počne niža tarifa (HA automatizacija → poruka na telefon) ✅
- Kiosk: upozorenja preko celog ekrana, kuhinjski tajmeri (i glasom), noćni režim, alarm tastatura, „Izlazim”, panel energije, više stranica i raspored po dobu dana, foto-okvir, pozdrav ukućana, porodične poruke, objave iz HA (TTS), interfon ✅
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
- Kiosk: iskačuća kamera (zvono, pokret, vrata) ✅, tamnije noću i minimum na čuvaru ekrana ✅, raspored u tri kolone ✅
- Provera kuće („Odlazim” / „Laku noć”) ✅
- Liste (spisak za kupovinu, zadaci) na telefonu i u kiosku ✅
- Dvotarifno brojilo (viša/niža tarifa) ✅
- Tabla za pisanje i crtanje (deljena preko HA) ✅
- Senzori uređaja (baterija, punjenje, kiosk) i pametno punjenje ✅
- NFC nalepnice (upis, očitavanje, automatizacija) ✅
- Brzi prekidači u meniju (Android Quick Settings) ✅
- Kiosk: AOD ekran i jutarnji ekran ✅
- Prijava korisničkim imenom i lozinkom na telefonu ✅, Tailscale adrese ✅
- Prilagodljiv početni ekran (izbor i redosled kartica) ✅
- Video uživo u iskačućoj kameri ✅
- Tajmer na uređaju („ugasi za 30 min”), izvršava HA ✅
- Istorija potrošnje po uređaju ✅
- Matter za potpuno nove uređaje preko Bluetooth-a ✅ (Google Play services; provera sa pravim uređajem na telefonu)
- Verzija za instalatere ✅ (brend, vođeno podešavanje, servisni ekran, device owner, rezervna kopija u HA)
- Release potpisivanje pravim ključem ✅ (ključ pravi i čuva vlasnik, nikad u repozitorijumu)
- Ažuriranja sa GitHub Releases uz SHA-256 proveru ✅
- Bezbednosna provera ✅ (widget, NFC linkovi, PIN za kritične radnje u kiosku — [SECURITY.md](SECURITY.md))

## Dalje

- Ko koristi tablet ✅ (dodir na sliku: pozdrav i brze kontrole; lični PIN za kritične radnje)
- „Još” ✅: baterije, dnevnik ko je otključao, Na odmoru, Stižem kući, Wi-Fi za goste, provetravanje, Žurka, buđenje svetlom, Ova nedelja, sezonski ukrasi, rođendani, priča za laku noć
- Provera na pravim uređajima: Matter preko Bluetooth-a, NFC, iOS
- Pristupačnost: prolaz sa TalkBack/VoiceOver
- Distribucija: F-Droid i/ili Google Play
- Pregled više kuća za instalatera (bez slanja kućnih podataka van kuće)

## Put do 1.0

- **0.3 — sređivanje** ✅: pregled koda novijih delova, krupan tekst na uskom telefonu (automatski test do 160 %), pristupačnost (automatska provera imena i veličine dugmadi), bezbednosni pregled ulaza iz drugih aplikacija, manje crtanja na zidnom tabletu.
- **0.9 — probni rad** ✅: dve nedelje svakodnevne upotrebe na tabletu i telefonima; provera na pravim uređajima (widgeti, NFC, buđenje svetlom, priča na srpskom glasu, Matter preko Bluetooth-a); odluka o iOS-u (1.0: Android i web; iOS nije deo izdanja).
- **1.0** ✅ (čeka objavu): README sa slikama ekrana, ažurirana uputstva, sređen CHANGELOG, spisak licenci paketa i kratka izjava o privatnosti; po želji F-Droid.

