# Open Smart Home

Open-source, lokalno orijentisana Smart Home aplikacija za Android i iOS telefone, tablete, zidne panele i **web pregledač**. Aplikacija je korisnički interfejs; komunikaciju sa uređajima (Zigbee, Z-Wave, Matter, Thread, Wi-Fi, MQTT…) obavlja lokalni **Home Assistant** server.

> Status: **MVP – faze 1–6**: povezivanje, model uređaja i kompletan osnovni interfejs (dashboard, prostorije, detalji uređaja, omiljeno, scene). Sledi tablet/kiosk (faza 7) i offline cache (faza 8). Vidi [ROADMAP](docs/ROADMAP.md).

## Mogućnosti (trenutno)

- Onboarding: dobrodošlica → izbor jezika → adresa servera → provera dostupnosti → pristupni token
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

Detalji: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) · Model uređaja: [docs/DEVICE_CAPABILITIES.md](docs/DEVICE_CAPABILITIES.md) · Bezbednost: [docs/SECURITY.md](docs/SECURITY.md) · Korišćeni HA API-ji: [docs/API_INTEGRATION.md](docs/API_INTEGRATION.md)

## Tehnologije

| Paket | Uloga |
|---|---|
| `flutter_riverpod` 3 | state management i dependency injection (bez code-gen-a) |
| `go_router` | navigacija, redirect na osnovu sesije |
| `dio` | REST klijent: timeout-i, mapiranje grešaka, prilagođen `HttpClient` za TLS pinovanje |
| `web_socket_channel` | WebSocket transport (`IOWebSocketChannel` sa istim TLS pravilima; u pregledaču browser WebSocket) |
| `web` | pristup `sessionStorage` za token u web verziji |
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
- Token se čuva samo u `sessionStorage` kartice; zatvaranjem kartice se odjavljujete. Trajna prijava na webu planirana je preko OAuth2.
- TLS obrađuje pregledač: samopotpisani sertifikat morate prihvatiti u pregledaču, pinovanje u aplikaciji nije moguće.
- Pregledač ne otkriva uzrok mrežne greške (CORS, mixed content, sertifikat, DNS), pa aplikacija prikazuje objašnjenje mogućih uzroka.
- Rute koriste `#` (npr. `/#/home`), pa statičkom serveru ne treba posebno podešavanje.

## Testovi

```bash
flutter analyze
flutter test
```

Pokriveno: parsiranje i validacija adrese, redakcija tajni u logovima, REST klijent (lažni HTTP adapter), mapiranje grešaka, WebSocket menadžer protiv mock servera (auth OK/odbijen, nedostupan server, restart servera i ponovna pretplata, deljene pretplate, ping timeout, disconnect), tok sesije (pogrešan token, čuvanje tokena, obnova sesije, odjava, brisanje podataka), redirect pravila rutera i widget testovi (onboarding do živog početnog ekrana, promena jezika i teme, telefon/tablet raspored, odjava).

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

- Prijava je trenutno samo pomoću long-lived access tokena. OAuth2 tok je planiran – vidi [SECURITY.md](docs/SECURITY.md#autentifikacija).
- Automatsko pronalaženje servera (mDNS/zeroconf) još nije implementirano; adresa se unosi ručno.
- iOS ATS blokira čist HTTP ka javnim **nazivima domena** (IP adrese i `.local` rade). To je namerno; za udaljeni pristup koristite HTTPS.
- Lokalni cache (offline prikaz) još ne postoji – faza 8.
- Na webu nema trajne prijave ni pinovanja sertifikata (vidi „Web verzija”).

## Doprinos i licenca

Doprinosi su dobrodošli preko pull request-a; pre slanja pokrenite `flutter analyze` i `flutter test`. Licenca još nije izabrana (predlog: Apache-2.0, ista kao Home Assistant) – dodati `LICENSE` pre prvog javnog objavljivanja.
