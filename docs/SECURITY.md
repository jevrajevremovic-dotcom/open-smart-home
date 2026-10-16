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

### OAuth2 na telefonu i tabletu (implementirano)
- Ekran za token nudi i „Prijavi se preko Home Assistanta”: HA-ova stranica za prijavu otvara se u aplikaciji (WebView, kao u zvaničnim HA aplikacijama); dugotrajni token nije potreban.
- `client_id` = `http://open-smart-home.localhost/`, `redirect_uri` = `http://open-smart-home.localhost/auth-callback`: isti host, pa ga HA prihvata bez preuzimanja ičega (radi na LAN-u bez interneta). Aplikacija preusmerenje presreće pre učitavanja; ta adresa se nikad ne otvara.
- `state` iz `Random.secure()` se proverava (zaštita od login CSRF-a); aplikacija dobija jednokratni kod i lozinku ne čuva. Kolačići WebView-a se brišu posle prijave.
- Tokeni (access + refresh, vezan za `client_id`) idu u Keystore/Keychain kao i na webu; refresh token se opoziva pri odjavi.
- Sa samopotpisanim (pinovanim) sertifikatom WebView ne može da otvori stranicu: tada se koristi token.

## Čuvanje tajni
- Token: `flutter_secure_storage` – iOS Keychain (`first_unlock_this_device`: dostupan zidnom tabletu posle restarta, ne prenosi se u backup), Android Keystore.
- Android: `allowBackup="false"` da enkriptovani podaci ne završe u cloud backup-u.
- `SharedPreferences` sadrži samo adresu servera, pin sertifikata (javna informacija), temu i jezik. Test proverava da token nikad ne dospe tamo.
- Polje za token je skriveno, bez autocorrect/autofill sugestija; kontroler se briše pri napuštanju ekrana.

## Adresa van kuće

- Opciona druga adresa istog doma; token i ključ za skladište ostaju vezani za kućnu adresu.
- Javna spoljna adresa mora biti `https://` (ili Tailscale): nešifrovani `http://` preko interneta se odbija već pri unosu.
- Pinovani samopotpisani sertifikat važi samo za kućnu adresu; spoljna mora imati važeći sertifikat.
- Izbor adrese: kratka provera `GET /api/` bez tokena (odgovor 401 = server je tu); token se šalje tek izabranoj adresi.

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

## Dodavanje uređaja

- Zigbee mreža se otvara samo na zahtev, najviše 3 minuta (protokolski maksimum 254 s), i zatvara se kad korisnik napusti ekran ili pritisne „Zaustavi”.
- Za uparivanje i promenu imena/prostorije HA obično traži administratorski nalog; bez njega aplikacija prikazuje grešku i ništa ne menja.

## Assist

- Glas: mikrofon se koristi samo dok je dugme aktivno. Podrazumevano se govor prepoznaje **samo na uređaju** (`onDevice`); prepoznavanje preko interneta (Google/Apple servis telefona, koji tada dobija snimak) uključuje se samo izričitim izborom. Snimak ne čuva ni ne šalje aplikacija – Home Assistantu ide samo tekst.

- Tekst se šalje samo na korisnikov HA (`/api/conversation/process`) i izvršava se sa ovlašćenjima prijavljenog naloga; aplikacija ga ne čuva ni ne loguje.
- Slike medija (`entity_picture` sa `token` parametrom) učitavaju se bez tog parametra, sa `Authorization` zaglavljem.

## Kamere

- Slika se uzima preko dokumentovanog `GET /api/camera_proxy/<entity_id>` sa `Authorization` zaglavljem; token se nikad ne stavlja u URL (ne koristi se `access_token` iz `entity_picture`).
- Snimci se osvežavaju (svake 2 s) **samo dok je kamera na ekranu**; kad se ekran zatvori ili kiosk pređe u čuvar ekrana, preuzimanje staje. Ništa se ne snima, ne kešira na disk i ne šalje dalje.
- Na zidnom tabletu kamere vidi svako u prostoriji, pa se panel može isključiti (Podešavanja → Kiosk → Prikaži kamere).

## Prognoza za lokaciju doma (opciono)

- Isključeno dok korisnik ne potvrdi dijalog koji objašnjava šta se šalje. Koristi se samo kad HA nema `weather` entitet.
- MET Norway dobija samo koordinate doma iz HA zaokružene na 2 decimale (~1 km), najviše jednom u 30 min, sa User-Agent identifikacijom aplikacije.

## Video uživo (kamere)

- URL dobija WS `camera/stream` (`format: hls`): kratkotrajna, potpisana putanja `/api/hls/<token>/…` na istom serveru; prihvata se samo ta putanja.
- Video plejer koristi mrežni sloj platforme, pa **ne vidi** sertifikat koji je korisnik ručno odobrio (pinning) u aplikaciji: sa samopotpisanim sertifikatom uživo ne radi, a aplikacija nudi snimke. Ništa se ne snima; zvuk je isključen.

## Zaključavanje aplikacije (opciono)

- Podešavanja → Bezbednost (samo kad uređaj ima zaključavanje ekrana ili biometriju): „Zaključaj aplikaciju” traži otisak, lice ili PIN uređaja pri otvaranju i posle 1 min u pozadini; pre uključivanja se jednom proverava da provera radi.
- „Potvrda za brave i alarm”: posle dijaloga za potvrdu kritičnih komandi (otključavanje, garaža, alarm) traži se i otisak/lice/PIN.
- Provera ide preko sistema (`local_auth`; Android BiometricPrompt, iOS Face ID/Touch ID); aplikacija ne vidi niti čuva biometrijske podatke. Kiosk koristi svoj PIN i ne zaključava se ovako.

## Režim za decu i goste

- Lokalno ograničenje interfejsa (skriveni osetljivi uređaji, zaključana podešavanja i dodavanje uređaja, bez Assista); PIN se čuva kao PBKDF2 heš kao kiosk PIN.
- Nije zamena za HA ovlašćenja: token i dalje ima prava naloga. Za prava ograničenja treba poseban HA korisnik (ne-administrator).

## Prenos podešavanja

- Izvoz u međuspremnik sadrži samo temu, jezik, omiljene i kiosk raspored. Bez tokena, adresa sa tajnama, PIN heševa, fotografije i pristanaka (lokacija, glas); pri uvozu se PIN i fotografija na uređaju zadržavaju.

## Obaveštenja o upozorenjima (opciono)

- Isključeno dok ih korisnik ne uključi (Podešavanja → Bezbednost); dozvolu za obaveštenja sistem traži tek tada.
- Obaveštenja pravi sam uređaj iz podataka koje već prima od HA – nema push servera ni clouda; zato rade samo dok aplikacija radi.
- Samo iz podataka uživo (ne iz offline keša), da staro upozorenje ne izazove lažnu uzbunu; rešeno upozorenje se uklanja.
- Na zaključanom ekranu Android prikazuje samo da postoji upozorenje (`visibility: private`), bez imena uređaja.

## Widget za početni ekran (Android)

- U widget se upisuju samo ID-jevi i imena scena (lokalno, u podacima aplikacije); nema tokena ni adrese servera.
- Dodir samo otvara aplikaciju sa linkom `opensmarthome://scene?id=scene.…`; aplikacija prihvata isključivo `scene.*` ID-jeve i scenu pokreće tek kada je prijavljena i podaci su uživo. Brave, alarm i slično se ne mogu pokrenuti iz widgeta.
- Posle odjave widget prikazuje samo poziv na prijavu.
- Flutter deep linking je isključen (`flutter_deeplinking_enabled=false`): spoljni linkovi ne mogu da otvore proizvoljan ekran aplikacije.

## Dvostruki pljesak (kiosk, Android)

- Isključen dok ga korisnik ne uključi; pre toga dijalog objašnjava da je mikrofon uključen dok je kiosk na ekranu, a sistem traži dozvolu za mikrofon.
- `AudioLevelHandler.kt` čita mikrofon u okvirima od 20 ms i iz svakog šalje samo najglasniji uzorak (jedan broj); uzorci se odmah odbacuju. Zvuk se ne snima, ne čuva i ne šalje nigde — ni HA-u.
- Sluša samo dok je kiosk na ekranu, aplikacija u prvom planu i ništa ga ne prekriva; Android pritom prikazuje oznaku mikrofona.
- Cilj može biti bilo koji uređaj (izbor korisnika). Kritične radnje — otključavanje, otvaranje garaže, isključivanje alarma — idu istim putem kao dodir: potvrda na ekranu (i opciono otisak/lice), pa zvuk spolja ili sa TV-a sam ne može da otključa vrata.
- Podešavanje se ne prenosi „Prenosom podešavanja” na drugi uređaj.

## Poruke iz Home Assistanta (mobile_app)

- Po želji: korisnik imenuje uređaj i dodaje ga u HA; tek tada sistem traži dozvolu za obaveštenja.
- `webhook_id` iz odgovora je tajna (preko njega se šalju podaci HA-u bez prijave), pa se čuva u Keystore/Keychain zajedno sa tokenom i briše pri odjavi. Aplikacija sama ne šalje ništa na webhook.
- `supports_encryption: false`, bez senzora i lokacije: registracija služi samo za `notify`; poruke stižu preko već autentifikovane WebSocket veze (`push_websocket_channel`), ne preko clouda.
- „I kad je aplikacija zatvorena” (Android): po želji; servis u prvom planu samo drži proces živim (sam ne komunicira), Android prikazuje stalno obaveštenje; isključuje se istim prekidačem, odjavom ili brisanjem registracije.
- „Prestani da primaš poruke” briše lokalnu registraciju; sam uređaj se uklanja u HA (Mobile App integracija).

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

## Tabla (slike u Home Assistantu)

Strane table se čuvaju kao slike preko HA integracije `image_upload`. Home Assistant te slike servira na `/api/image/serve/<id>/original` **bez prijave**: ko zna id (32 nasumična heksadecimalna znaka) i može da dođe do servera, može da je vidi. Aplikacija to piše na ekranu table. Ne pišite na tablu lozinke ni druge tajne.

## Senzori uređaja

Uključuju se posebno (podrazumevano isključeno) i idu samo na vaš Home Assistant: procenat i stanje baterije, vrsta punjača i da li je kiosk uključen. Lokacija, Wi-Fi mreža i ništa drugo se ne šalju.

