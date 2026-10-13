# Open Smart Home

Open-source, lokalno orijentisana Smart Home aplikacija za Android i iOS telefone, tablete, zidne panele i **web pregledač**. Aplikacija je korisnički interfejs; komunikaciju sa uređajima (Zigbee, Z-Wave, Matter, Thread, Wi-Fi, MQTT…) obavlja lokalni **Home Assistant** server.

> Status: **MVP 0.1.0 – faze 1–9 završene**: povezivanje, model uređaja, kompletan interfejs, kiosk režim, offline keš i stabilizacija. Plan dalje: [ROADMAP](docs/ROADMAP.md).

## Mogućnosti (trenutno)

- Onboarding: dobrodošlica → izbor jezika → **automatsko pronalaženje servera na mreži (mDNS)** ili ručna adresa → provera dostupnosti → prijava
- Validacija adrese (IP, DNS, `.local`, HTTPS domen), procena rizika (lokalno / javno / javno bez HTTPS-a)
- Samopotpisani sertifikat se prihvata **samo** eksplicitnim pinovanjem SHA-256 otiska, nikad automatski
- Token u Keychain-u / Android Keystore-u (`flutter_secure_storage`), nikad u logovima ni u SharedPreferences
- WebSocket menadžer: autentifikacija, deljene pretplate, ping/pong heartbeat, exponential backoff sa jitter-om, ponovna pretplata nakon reconnect-a, prekid pokušaja kod odbijenog tokena
- Status veze u realnom vremenu, živi prikaz `state_changed` događaja
- Material 3, svetla/tamna/sistemska tema, srpski (latinica) i engleski
- Responsive raspored: `NavigationBar` na telefonu, `NavigationRail` na tabletu
- Mock režim sa in-memory Home Assistant serverom (REST + WebSocket protokol)
- Web verzija (JS i WebAssembly build), koja se može hostovati direktno iz Home Assistanta
- Odjava i brisanje svih lokalnih podataka

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
| `nsd` | mDNS/zeroconf pretraga (`_home-assistant._tcp`) preko sistemskih servisa: Android NsdManager, Apple Bonjour |
| `flutter_secure_storage` | Keychain / Keystore za pristupni token |
| `shared_preferences` | samo netajna podešavanja (tema, jezik, adresa servera) |
| `crypto` | SHA-256 otisak sertifikata |
| `intl`, `flutter_localizations` | lokalizacija (ARB + `gen-l10n`), formatiranje datuma |
| `mocktail` (dev) | mock-ovi u testovima |

Namerno **nisu** dodati u ovoj fazi: Drift (lokalni cache – faza 8), freezed/json_serializable (modeli su mali i parsiraju se ručno, defanzivno), QR skener, notifikacije, kiosk paketi. Svaka zavisnost se dodaje tek kada ima konkretnu ulogu.

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
