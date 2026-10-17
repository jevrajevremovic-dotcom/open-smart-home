# Open Smart Home

Open-source, lokalno orijentisana Smart Home aplikacija za Android i iOS telefone, tablete, zidne panele i **web pregledač**. Aplikacija je korisnički interfejs; komunikaciju sa uređajima (Zigbee, Z-Wave, Matter, Thread, Wi-Fi, MQTT…) obavlja lokalni **Home Assistant** server.

> Status: **MVP 0.1.0 + razvoj posle MVP-a**: kompletna aplikacija za telefon, tablet, web i zidni panel. Šta je urađeno po verzijama: [CHANGELOG](docs/CHANGELOG.md) · plan: [ROADMAP](docs/ROADMAP.md).

## Mogućnosti

**Povezivanje i bezbednost**
- Automatsko pronalaženje Home Assistanta na mreži (mDNS) ili ručna adresa; provera adrese i rizika (lokalno / javno / bez HTTPS-a)
- Prijava korisničkim imenom i lozinkom na HA stranici (OAuth2, web i telefon) ili long-lived tokenom; samopotpisani sertifikat samo uz eksplicitno pinovanje otiska
- Token u Keychain-u / Android Keystore-u, nikad u logovima; zaključavanje aplikacije otiskom/licem/PIN-om i potvrda pre otključavanja brava i alarma
- **Više domova** (više HA servera) sa prebacivanjem
- **Van kuće**: uz kućnu i spoljna adresa (Nabu Casa, HTTPS domen, Tailscale) sa automatskim prebacivanjem; Tailscale adrese se prepoznaju kao VPN

**Upravljanje uređajima**
- Uređaji grupisani po sobama i vrstama, omiljeni (sa redosledom), pretraga, scene, skripte
- „Upali/ugasi sva” svetla i „podigni/spusti sve” roletne u sobi
- Editor automatizacija: više okidača (vreme, uređaj, vrednost senzora, sunce), uslovi „samo ako” (dani, vremenski prozor, stanje uređaja, mrak/dan); čuva se kao obična HA automatizacija
- Aktivnost doma (HA dnevnik, 24 h) sa filterima
- Svetla (jačina, boja, temperatura boje), klima i termostati (režimi, preset), roletne, brave, alarm (režimi, tastatura za kod), mediji (pesma, omot, jačina, izvor), ventilatori, ovlaživači, usisivači, pomoćnici „izbor” i „broj”, senzori
- Istorija uređaja: grafikon za senzore i vremenska traka sa aktivnošću
- Kamere: snimci (osvežavanje na 2 s samo dok se gledaju) i video uživo (HLS)
- Izmena imena i prostorije uređaja iz aplikacije

**Dodavanje uređaja (preko huba)**
- Zigbee (ZHA ili Zigbee2MQTT) sa odbrojavanjem; Wi-Fi/LAN uređaji koje je HA pronašao, sa vođenim podešavanjem; Matter: novi uređaji preko Bluetooth-a (Android, Google Play services) ili deljeni iz druge aplikacije (QR ili kod); Z-Wave sa S2 bezbednošću i SmartStart QR

**Početni ekran i kiosk (zidni tablet)**
- Topli, minimalistički izgled (svetla/tamna tema), pozdrav, pregled doma, vreme (HA ili MET Norway uz pristanak) sa prognozom po satima i 7 dana, kalendar, obaveštenja iz HA, „sada svira”
- Brzi prekidači u Androidovom meniju koji se spušta odozgo (uređaj ili scena jednim dodirom)
- NFC nalepnice: prislonite telefon i pokreće se scena (isti format kao zvanična HA aplikacija)
- Baterija i punjenje telefona/tableta kao senzori u HA, pametno punjenje zidnog tableta (40–80 %)
- Dvotarifno brojilo: potrošnja i trošak u višoj i nižoj tarifi, koja tarifa važi sada
- Tabla za pisanje i crtanje (prst ili olovka), deljena preko Home Assistanta, i na zidnom tabletu
- Liste iz Home Assistanta (kupovina, zadaci) na telefonu i zidnom tabletu, uživo
- Provera kuće pred odlazak i spavanje: šta je ostalo upaljeno, otvoreno ili otključano, „Sredi sve” jednim dodirom
- Kiosk: ekran u mirovanju (sat, prognoza, jedna stvar po izboru) i jutarnji pregled dana
- Kiosk u stilu „Mehurići” (inspirisano [jlnbln/My-HA-Dashboard](https://github.com/jlnbln/My-HA-Dashboard)) ili „Staklo”
- Kiosk: raspored po želji — prevlačenje, veličina, dodavanje i uklanjanje panela
- Kiosk: tamnije noću i najniža osvetljenost na čuvaru ekrana
- Kiosk: iskačuća kamera kad neko pozvoni ili se pomeri ispred vrata
- Kiosk: dvostruki pljesak za bilo koji uređaj ili scenu (Android, po želji, samo jačina zvuka na uređaju; otključavanje i sl. uz potvrdu)
- Kiosk: stakleni paneli preko gradijenta, sat, ukućani, statusi po izboru, kamera, vreme, termostat, sobe, prečice, kalendar, mediji i Assist; PIN za izlaz, čuvar ekrana, povratak na početak
- Assist: tekstualne i glasovne komande (govor se podrazumevano prepoznaje samo na uređaju)
- Android: widget „Scene” na početnom ekranu, prečice na ikonici, opciona obaveštenja o kritičnim upozorenjima (dim, CO, curenje vode, alarm) dok aplikacija radi
- Energija: snaga uživo, potrošnja po satima/danima, solar, baterija, gas, najveći potrošači, procena troška

**Ostalo**
- Srpski (latinica) i engleski, pristupačnost (čitači ekrana, krupan tekst do 150 %)
- Offline keš poslednjeg stanja, automatsko ponovno povezivanje
- Mock režim (demo kuća bez pravog HA), web verzija, lokalni gateway (Docker Compose)

## Arhitektura ukratko

```
Telefon / tablet (Flutter)
   │  REST (početno učitavanje, komande)  +  WebSocket (događaji u realnom vremenu)
   ▼
Home Assistant Core ── Zigbee2MQTT / Z-Wave JS / Matter Server / OTBR / MQTT / ESPHome / LAN integracije
```

Lokalni gateway (Docker Compose): [docs/GATEWAY.md](docs/GATEWAY.md) · Detalji: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) · Model uređaja: [docs/DEVICE_CAPABILITIES.md](docs/DEVICE_CAPABILITIES.md) · Bezbednost: [docs/SECURITY.md](docs/SECURITY.md) · Korišćeni HA API-ji: [docs/API_INTEGRATION.md](docs/API_INTEGRATION.md)

## Tehnologije

| Paket | Uloga |
|---|---|
| `flutter_riverpod` 3 | state management i dependency injection (bez code-gen-a) |
| `go_router` | navigacija, redirect na osnovu sesije |
| `dio` | REST klijent: timeout-i, mapiranje grešaka, prilagođen `HttpClient` za TLS pinovanje |
| `web_socket_channel` | WebSocket transport (`IOWebSocketChannel` sa istim TLS pravilima; u pregledaču browser WebSocket) |
| `web` | pristup `sessionStorage`/`localStorage` u web verziji |
| `geolocator` | približna lokacija telefona, samo za opciono „Vreme na mojoj lokaciji” |
| `nsd_ios`, `nsd_macos`, `nsd_windows` | mDNS/zeroconf pretraga (`_home-assistant._tcp`) preko Apple Bonjour / Windows; na Androidu sopstveni kanal ka NsdManager-u (`NsdDiscoveryHandler.kt`) |
| `flutter_secure_storage` | Keychain / Keystore za pristupni token |
| `shared_preferences` | samo netajna podešavanja (tema, jezik, adresa servera) |
| `crypto` | SHA-256 otisak sertifikata |
| `intl`, `flutter_localizations` | lokalizacija (ARB + `gen-l10n`), formatiranje datuma |
| `speech_to_text` | glasovne komande (podrazumevano prepoznavanje na uređaju) |
| `mobile_scanner` | skeniranje Matter i Z-Wave QR kodova |
| `video_player` | video uživo sa kamera (HLS) |
| `local_auth` | zaključavanje aplikacije otiskom / licem / PIN-om uređaja |
| `wakelock_plus` | ekran ostaje uključen u kiosku |
| `image_picker` | izbor fotografije za pozadinu kioska |
| `flutter_local_notifications` | opciona lokalna obaveštenja o kritičnim upozorenjima (bez push servera) |
| `quick_actions` | prečice na ikonici aplikacije (scene, Assist, Kiosk) |
| `mocktail` (dev) | mock-ovi u testovima |

Namerno **nisu** dodati: Drift (offline keš je jednostavan JSON snimak), freezed/json_serializable (modeli su mali i parsiraju se ručno, defanzivno), grafikon biblioteke (grafikoni su crtani ručno, `CustomPainter`). Svaka zavisnost se dodaje tek kada ima konkretnu ulogu.

## Preduslovi

- Flutter **3.47+** (Dart 3.13+) – `flutter --version`
- Android: Android Studio / Android SDK, `minSdk 24` (zahtev `flutter_secure_storage`)
- iOS: macOS + Xcode
- Home Assistant server dostupan sa uređaja (ili mock režim)

## Pokretanje

```bash
cd app
flutter pub get
flutter gen-l10n
```

Development sa mock serverom (bez stvarnog Home Assistanta):

```bash
flutter run --dart-define=SMARTHOME_MOCK=true
```

U mock režimu prihvata se bilo koja adresa i bilo koji token; token `invalid` simulira odbijenu prijavu. Mock režim je **uvek isključen u release build-u** (`kReleaseMode`), a dok je aktivan na ekranima povezivanja prikazuje se upozoravajuća traka.

Sa stvarnim serverom:

```bash
flutter run
```

## Povezivanje sa Home Assistantom

1. Unesite adresu, npr. `homeassistant.local:8123` ili `192.168.1.10:8123` (bez šeme se za lokalne adrese podrazumeva `http`, za javne `https`).
2. Aplikacija proverava `GET /api/` – odgovor `401` potvrđuje da Home Assistant API postoji.
3. U Home Assistantu: korisnički profil → **Security** → **Long-lived access tokens** → *Create token*.
4. Nalepite token. Aplikacija ga proverava (`GET /api/`, `GET /api/config`) i tek tada čuva u bezbednom skladištu.

## Build

```bash
flutter build web --release        # Web (JS); dodajte --wasm za WebAssembly
flutter build apk --release        # Android
flutter build appbundle --release  # Google Play
flutter build ipa --release        # iOS (macOS + Xcode, potpisivanje)
```

## Web verzija

### Preporučeno: hostovanje iz Home Assistanta
Tako su aplikacija i API na istoj adresi, pa nema CORS ni mixed-content problema, a adresa servera se popunjava sama.

```bash
cd app
flutter build web --release --base-href /local/opensmarthome/
```

Sadržaj `app/build/web/` kopirajte u `<HA config>/www/opensmarthome/` i otvorite `http://homeassistant.local:8123/local/opensmarthome/`. Za WebAssembly build dodajte `--wasm`.

> Napomena: sve što je u `/config/www` HA servira **bez autentifikacije**. To je u redu za samu aplikaciju (u njoj nema tajni), ali tamo ne stavljajte ništa drugo.

### Hostovanje na drugoj adresi
U `configuration.yaml` Home Assistanta dozvolite adresu aplikacije, pa restartujte HA:

```yaml
http:
  cors_allowed_origins:
    - https://panel.example.com
```

Ako je aplikacija na `https://`, i HA mora biti na `https://`, jer pregledač blokira `http://` pozive (aplikacija to proverava odmah pri unosu adrese).

### Razvoj

```bash
flutter run -d chrome --dart-define=SMARTHOME_MOCK=true
```

### Razlike u odnosu na mobilnu verziju
- Prijava preko Home Assistant login stranice (OAuth2), uz opciju „Zapamti me“; sa long-lived tokenom prijava traje dok je kartica otvorena.
- TLS obrađuje pregledač: samopotpisani sertifikat morate prihvatiti u pregledaču, pinovanje u aplikaciji nije moguće.
- Pregledač ne otkriva uzrok mrežne greške (CORS, mixed content, sertifikat, DNS), pa aplikacija prikazuje objašnjenje mogućih uzroka.
- Rute koriste `#` (npr. `/#/home`), pa statičkom serveru ne treba posebno podešavanje.

## Zidni tablet (kiosk režim)

Podešavanja → **Kiosk režim** → *Pokreni kiosk režim*. Preporučeno je i da postavite **PIN za izlaz**.

- Fullscreen dashboard sa satom, krupnijim tekstom i kontrolama, bez standardne navigacije.
- Raspored panela se menja na samom tabletu: ikonica u zaglavlju (ili Podešavanja → Kiosk → *Uredi raspored*), pa držite i prevucite panel; dugmad menjaju širinu, visinu i uređaj, a *Dodaj panel* dodaje nove.
- Posle neaktivnosti vraća se na kiosk dashboard, a zatim zatamnjuje ekran i prikazuje sat; dodir ga budi. Oba vremena su podesiva.
- Ekran ostaje uključen dok je kiosk aktivan (može da se isključi).
- *Otvori u kiosk režimu pri pokretanju* vraća panel u kiosk i posle restarta aplikacije.
- Veza sa serverom se obnavlja sama (backoff) i odmah kad se aplikacija vrati u prvi plan.

Aplikacija ne može sama da zabrani izlazak iz operativnog sistema. Za potpuno zaključan panel koristite i sistemsku funkciju:
- **Android:** *Settings → Security → App pinning*, ili poseban kiosk launcher (npr. Fully Kiosk Browser / launcher MDM) koji pokreće aplikaciju pri paljenju uređaja.
- **iOS/iPadOS:** *Settings → Accessibility → Guided Access*.
- **Web:** pregledač u kiosk modu (npr. `chromium --kiosk http://homeassistant.local:8123/local/opensmarthome/`).

## Testovi

```bash
flutter analyze
flutter test                                  # unit, widget i performance testovi
flutter test integration_test -d <uređaj>     # na emulatoru ili telefonu
```

Test obaveštenja u `integration_test` traži dozvolu za obaveštenja; na Androidu je dajte čim se aplikacija instalira:
`adb shell pm grant org.opensmarthome.open_smart_home android.permission.POST_NOTIFICATIONS`.

| Vrsta | Šta pokriva |
|---|---|
| Unit | validacija adrese, redakcija tajni, REST klijent i mapiranje grešaka, WebSocket menadžer (auth, reconnect, backoff, deljene pretplate, ping timeout), mapper uređaja i komande, sažeci dashboarda, keš (format, atomični upis na disk, prednost živih podataka), kiosk PIN (RFC 7914 vektor, blokada), redirect pravila |
| Widget | onboarding do živog dashboarda, telefon/tablet raspored, tema i jezik, detalji uređaja po mogućnostima, potvrda otključavanja, omiljeno, scene, kiosk (izlaz PIN-om, neaktivnost, zatamnjenje), pokretanje bez servera sa keširanim podacima, tekst od 150 % bez prelivanja |
| Performance | dom sa 2200 entiteta: mapiranje, početna sinhronizacija, nalet od 2000 promena (spajanje u jedno osvežavanje) |
| Curenje resursa | 5 ciklusa prijave i odjave: jedan soket i 4 pretplate po sesiji, a posle odjave nula |
| Integration (uređaj) | pravi Keystore/Keychain, SharedPreferences, keš na disku i wakelock: prijava → kontrola svetla → odjava briše token i keš; restart bez servera prikazuje keš; kiosk drži i oslobađa wakelock; tema i jezik ostaju posle restarta |

CI (`.github/workflows/ci.yml`) na svaki push i pull request proverava formatiranje, analizu i testove, pa pravi web i Android (debug) build.

**Napomena za Linux:** ako se integration testovi pokreću dok radi Gradle daemon pokrenut iz Android Studija, a `/tmp` nije zajednički (sandbox, različite sesije), postavite `TMPDIR` na folder u home direktorijumu.

## Performanse (izmereno, debug VM)

| Scenario (2200 entiteta, 220 uređaja, 20 prostorija) | Vreme |
|---|---|
| Mapiranje svih entiteta | ~25 ms |
| Početna sinhronizacija preko WebSocket-a | ~110 ms |
| 2000 promena stanja u naletu | ~80 ms, **1** osvežavanje UI-ja (spajanje 50 ms) |

Kartica uređaja se obnavlja samo kad se promeni njen uređaj, izvedene liste imaju jednakost po vrednosti, a mreže se grade lenjo.

## Struktura

```
app/lib/
  app/            bootstrap, MaterialApp, router + adaptivni shell, tema, lokalizacija (ARB)
  core/           config, errors, logging (redakcija), network (adresa, TLS), storage, widgets
  features/       onboarding, connection, authentication (sesija), home, settings
  integrations/
    home_assistant/  api (REST), websocket (menadžer, backoff), models, mock
app/test/         core, integrations, features, widgets
docs/             ARCHITECTURE, SECURITY, API_INTEGRATION, ROADMAP, CHANGELOG
```

## Poznata ograničenja

- Mobilni koristi long-lived token; OAuth2 je za sada samo na webu – vidi [SECURITY.md](docs/SECURITY.md#autentifikacija).
- Automatsko pronalaženje servera radi na Androidu i iOS-u; na webu nije moguće (pregledači ne podržavaju mDNS), pa se predlaže adresa stranice.
- iOS ATS blokira čist HTTP ka javnim **nazivima domena** (IP adrese i `.local` rade). To je namerno; za udaljeni pristup koristite HTTPS.
- Na webu se keš (kao i token) čuva samo dok je kartica otvorena.
- Na webu nema pinovanja sertifikata (vidi „Web verzija”).

## Doprinos i licenca

Doprinosi su dobrodošli – vidi [CONTRIBUTING.md](CONTRIBUTING.md). Problemi i rešenja: [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

Licenca: [Apache License 2.0](LICENSE) – vidi i [NOTICE](NOTICE). Projekat nije povezan sa Home Assistant projektom niti ga on podržava.
