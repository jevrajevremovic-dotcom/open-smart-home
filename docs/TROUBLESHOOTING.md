# Rešavanje problema

## Povezivanje

| Simptom | Uzrok i rešenje |
|---|---|
| „Server nije dostupan” | Proverite da je telefon na istoj mreži kao HA i da adresa (sa portom, obično `:8123`) radi u pregledaču na telefonu. `homeassistant.local` (mDNS) ne rade svi Android uređaji – probajte IP adresu. |
| „Server je odgovorio, ali ne kao Home Assistant” | Na adresi je nešto drugo (ruter, reverse proxy stranica). Proverite port. Reverse proxy mora da prosleđuje `/api/` i `/api/websocket` (WebSocket upgrade). HA ne podržava rad sa podputanje (`/ha`). |
| „Pristupni token je odbijen” | Token je pogrešno kopiran, obrisan u HA profilu ili je korisnik deaktiviran. Napravite novi u Profil → Security → Long-lived access tokens. |
| „Problem sa sertifikatom” | HTTPS sa samopotpisanim sertifikatom: aplikacija prikazuje otisak; uporedite ga sa sertifikatom na serveru i potvrdite. Na webu sertifikat mora prihvatiti pregledač. |
| Android emulator ne vidi HA na istom računaru | Iz emulatora je računar `10.0.2.2`, npr. `http://10.0.2.2:8123`. |
| Javna `http://` adresa je blokirana | Namerno – token bi putovao nešifrovano. Koristite HTTPS ili potvrdite rizik (npr. VPN). iOS dodatno blokira čist HTTP ka javnim nazivima. |

## Web verzija

| Simptom | Uzrok i rešenje |
|---|---|
| Mrežna greška odmah pri proveri | CORS: dodajte adresu aplikacije u `http: cors_allowed_origins` u `configuration.yaml` i restartujte HA. Ili hostujte aplikaciju iz HA (`/config/www` → `/local/…`). |
| „Ova stranica je učitana preko HTTPS-a…” | Mixed content: sa HTTPS stranice ne može `http://` server. Koristite `https://` HA adresu ili aplikaciju sa iste adrese kao HA. |
| Posle zatvaranja kartice traži ponovnu prijavu | Namerno: na webu se token i keš čuvaju samo dok je kartica otvorena. |
| Prazna stranica posle kopiranja u `/config/www` | Build mora imati odgovarajući `--base-href`, npr. `/local/opensmarthome/` (sa kosom crtom na kraju). |

## Prikaz i uređaji

| Simptom | Uzrok i rešenje |
|---|---|
| Nema prostorija | Uređaji nemaju dodeljenu oblast u HA, ili korisnik nema pristup registrima. Aplikacija tada prikazuje „Bez prostorije”. |
| Uređaj se ne vidi u listama | Skriveni, dijagnostički i konfiguracioni entiteti se ne prikazuju (vidljivi su njihovi podaci, npr. baterija, na glavnom uređaju). Onemogućeni entiteti se ignorišu. |
| Uređaj je „nepoznat” ili bez kontrola | Domen još nije podržan, ili integracija ne prijavljuje `supported_features`/color modove. Prijavite issue sa atributima entiteta (Developer Tools → States). |
| Žuta traka „podaci od …” | Veza nije aktivna; prikazani su poslednji poznati podaci. Kontrole se vraćaju kad se veza uspostavi (povucite ekran nadole ili „Pokušaj odmah”). |

## Kiosk

| Simptom | Uzrok i rešenje |
|---|---|
| Zaboravljen PIN | Na samom uređaju: Android Podešavanja → Aplikacije → Open Smart Home → Obriši podatke (briše i prijavu). |
| Ekran se ipak gasi | Proverite „Drži ekran uključen”, režim štednje baterije i podešavanja proizvođača. Na webu Wake Lock radi samo na HTTPS. |
| Korisnik izađe Home dugmetom | Aplikacija to ne može da spreči – uključite Android App pinning ili iOS Guided Access. |

## Razvoj

| Simptom | Rešenje |
|---|---|
| `flutter: command not found` | Dodajte Flutter u PATH (fish: `fish_add_path ~/development/flutter/bin`). |
| Greške u `app_localizations.dart` | `flutter gen-l10n` posle izmene ARB fajlova. |
| `cmdline-tools component is missing` | Android Studio → SDK Manager → SDK Tools → Android SDK Command-line Tools, pa `flutter doctor --android-licenses`. |
