# Bezbednost

## Autentifikacija

### MVP: Long-lived access token (implementirano)
Dokumentovan Home Assistant mehanizam ([Authentication API](https://developers.home-assistant.io/docs/auth_api/#long-lived-access-token)). Korisnik ga kreira u profilu → *Security*. Aplikacija:

1. proverava token pozivom `GET /api/` sa `Authorization: Bearer …` (očekuje `{"message": "API running."}`),
2. pozivom `GET /api/config` potvrđuje da je server zaista Home Assistant,
3. tek tada token upisuje u bezbedno skladište i aktivira sesiju.

Odbijen token na WebSocket-u (`auth_invalid`) zaustavlja ponovne pokušaje i nudi ponovnu prijavu.

Ograničenje: LLAT ne ističe sam; korisnik ga opoziva u HA profilu. Zato aplikacija nudi odjavu i brisanje svih podataka, a dokumentacija preporučuje poseban token po uređaju.

### Sledeći korak: OAuth2 Authorization Code (planirano)
HA podržava OAuth2 (`/auth/authorize`, `/auth/token`, refresh token). Uslov za mobilnu aplikaciju: `client_id` je URL, a `redirect_uri` sa custom šemom (npr. `opensmarthome://auth-callback`) mora biti deklarisan na stranici `client_id` URL-a (`<link rel="redirect_uri" …>`), jer nije na istom hostu. To znači da projekat mora da hostuje tu stranicu (npr. GitHub Pages) pre nego što OAuth može da radi. Arhitektura je spremna: token se čita isključivo preko funkcije (`AccessTokenReader`), pa se može zameniti provajderom koji osvežava access token bez izmena u API i WebSocket sloju.

## Čuvanje tajni
- Token: `flutter_secure_storage` – iOS Keychain (`first_unlock_this_device`: dostupan zidnom tabletu posle restarta, ne prenosi se u backup), Android Keystore.
- Android: `allowBackup="false"` da enkriptovani podaci ne završe u cloud backup-u.
- `SharedPreferences` sadrži samo adresu servera, pin sertifikata (javna informacija), temu i jezik. Test proverava da token nikad ne dospe tamo.
- Polje za token je skriveno, bez autocorrect/autofill sugestija; kontroler se briše pri napuštanju ekrana.

## Web verzija
- **Token:** samo u `sessionStorage` kartice (`credential_store_web.dart`). Pregledač nema hardverski zaštićeno skladište. Šifrovanje u `localStorage` ne bi pomoglo, jer bi ključ stajao pored podataka, a Web Crypto ne radi na `http://` adresama. Token zato ne preživljava zatvaranje kartice. U `localStorage` je samo netajni profil servera.
- **TLS:** obrađuje ga pregledač; pinovanje sertifikata nije moguće i ne nudi se.
- **Mixed content:** sa `https://` stranice aplikacija odbija `http://` server pre bilo kakvog zahteva (osim loopback-a).
- **CORS:** HA mora eksplicitno dozvoliti poreklo aplikacije (`cors_allowed_origins`), osim kada aplikaciju servira sam HA.
- **Referrer:** `index.html` postavlja `no-referrer`, da adresa doma ne odlazi trećim stranama.
- **Glavni rizik je XSS:** sve što se izvrši u istom poreklu može da pročita `sessionStorage`. Zato aplikaciju ne hostujte na istom poreklu sa nepouzdanim sadržajem.

## Offline keš
- Sadrži poslednje poznato stanje doma (uključujući prisustvo, brave i alarm), ali nikada token.
- **Mobilni:** privatni folder aplikacije (sandbox), izuzet iz Android backup-a; naziv fajla je heš adrese servera.
- **Web:** samo `sessionStorage` kartice, pa podaci ne ostaju na deljenom računaru posle zatvaranja.
- Briše se pri odjavi (za taj server) i pri „Obriši sve lokalne podatke” (sve).
- Keširani podaci se uvek prikazuju sa oznakom vremena, a komande su blokirane dok se ne potvrde živi podaci.

## Kiosk PIN
- PIN (4–8 cifara) štiti samo izlazak iz kiosk režima na tom uređaju; nije pristupni podatak za server.
- Čuva se isključivo kao PBKDF2-HMAC-SHA256 heš (20 000 iteracija, nasumična so od 16 bajtova), a poredi se u konstantnom vremenu.
- Posle 5 pogrešnih pokušaja unos je blokiran 30 s.
- Dok je kiosk aktivan, ruter ne dozvoljava nijednu rutu van kioska (ni duboke linkove ni „back”). Odjava uvek izlazi iz kioska.
- Aplikacija ne može da spreči izlazak u sistem (Home dugme, notifikacije); za to služe Android App pinning i iOS Guided Access.

## Logovanje
- `AppLogger` propušta svaku poruku i grešku kroz `Redactor` (Bearer tokeni, JWT, `access_token`/`password`/`token` u JSON-u i query-ju).
- HTTP logovi sadrže samo metodu, putanju i status – nikad zaglavlja ni telo.
- Release build loguje samo `warning`+, bez stack trace-ova.
- Korisniku se prikazuje lokalizovana poruka po kategoriji greške, nikad sirov izuzetak.

## Transport
| Adresa | Ponašanje |
|---|---|
| HTTPS (bilo gde) | Sistemski CA; nepoznat sertifikat → dijalog sa otiskom, prihvata se samo eksplicitno pinovanje |
| HTTP u lokalnoj mreži | Dozvoljeno, uz informativnu napomenu |
| HTTPS javna adresa | Dozvoljeno, uz napomenu da je server izložen internetu |
| HTTP javna adresa | Blokirano dok korisnik ne potvrdi rizik (npr. VPN); iOS ATS dodatno blokira javne nazive domena |
| HTTP sa HTTPS web stranice | Blokirano (mixed content) |

Ne postoji opcija „prihvati sve sertifikate”.

## Ostalo
- Validacija svih odgovora; neispravni entiteti se preskaču, neočekivan JSON daje `parsing` grešku.
- Nazivi servisa se validiraju pre ugradnje u URL.
- Mock režim je nemoguć u release build-u.
- Kritične komande (brave, alarm, garaža) – dodatna potvrda / biometrija planirana uz UI uređaja.

## Prijava ranjivosti
Ne otvarajte javni issue. Pošaljite opis održavaocima privatno (kontakt dodati pre javnog objavljivanja).
