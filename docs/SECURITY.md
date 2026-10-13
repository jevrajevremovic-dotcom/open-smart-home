# Bezbednost

## Autentifikacija

### MVP: Long-lived access token (implementirano)
Dokumentovan Home Assistant mehanizam ([Authentication API](https://developers.home-assistant.io/docs/auth_api/#long-lived-access-token)). Korisnik ga kreira u profilu → *Security*. Aplikacija:

1. proverava token pozivom `GET /api/` sa `Authorization: Bearer …` (očekuje `{"message": "API running."}`),
2. pozivom `GET /api/config` potvrđuje da je server zaista Home Assistant,
3. tek tada token upisuje u bezbedno skladište i aktivira sesiju.

Odbijen token na WebSocket-u (`auth_invalid`) zaustavlja ponovne pokušaje i nudi ponovnu prijavu.

Ograničenje: LLAT ne ističe sam; korisnik ga opoziva u HA profilu. Zato aplikacija nudi odjavu i brisanje svih podataka, a dokumentacija preporučuje poseban token po uređaju.

### OAuth2 Authorization Code – web (implementirano)
- `client_id` = poreklo aplikacije, `redirect_uri` = stranica aplikacije (isti host, pa HA ne mora da preuzima stranicu i sve radi lokalno).
- Zaštita od podmetnutog callback-a: nasumični `state` u `sessionStorage`, jednokratan, važi 15 minuta; kod se odmah uklanja iz adrese.
- Access token (30 min) se automatski obnavlja refresh tokenom, jednim zahtevom za sve paralelne pozive; odbijen refresh token traži novu prijavu, a mrežna greška se ponavlja.
- Odjava opoziva refresh token (`/auth/revoke`, best effort).
- „Zapamti me“: tokeni u `localStorage` (kao HA frontend); bez toga u `sessionStorage`.

### OAuth2 na mobilnom (planirano)
Zahteva javno hostovanu `client_id` stranicu sa `<link rel="redirect_uri">` i HA sa pristupom internetu; do tada mobilni koristi long-lived token.

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

## Vreme na lokaciji telefona (opciono)
- Podrazumevano isključeno; prikazuje se vreme iz Home Assistanta (lokacija doma), bez slanja podataka van mreže.
- Pre uključivanja dijalog objašnjava šta se šalje i kome; tek tada se traži dozvola.
- Samo približna lokacija (Android `ACCESS_COARSE_LOCATION`, `LocationAccuracy.low`), dodatno zaokružena na 2 decimale (~1 km) pre slanja servisu MET Norway; ništa drugo se ne šalje. Osvežavanje na 30 min dok je aplikacija otvorena.
- Samo na mobilnom; na webu i u kiosku se ne nudi.

## Assist

- Tekst se šalje samo na korisnikov HA (`/api/conversation/process`) i izvršava se sa ovlašćenjima prijavljenog naloga; aplikacija ga ne čuva ni ne loguje.
- Slike medija (`entity_picture` sa `token` parametrom) učitavaju se bez tog parametra, sa `Authorization` zaglavljem.

## Kamere

- Slika se uzima preko dokumentovanog `GET /api/camera_proxy/<entity_id>` sa `Authorization` zaglavljem; token se nikad ne stavlja u URL (ne koristi se `access_token` iz `entity_picture`).
- Snimci se osvežavaju (svake 2 s) **samo dok je kamera na ekranu**; kad se ekran zatvori ili kiosk pređe u čuvar ekrana, preuzimanje staje. Ništa se ne snima, ne kešira na disk i ne šalje dalje.
- Na zidnom tabletu kamere vidi svako u prostoriji, pa se panel može isključiti (Podešavanja → Kiosk → Prikaži kamere).

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
