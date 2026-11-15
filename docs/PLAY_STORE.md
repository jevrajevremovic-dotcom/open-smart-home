# Objava na Google Play-u

Spisak svega što Play traži, sa odgovorima koji odgovaraju onome što aplikacija stvarno radi
([PRIVACY.md](PRIVACY.md)). Odgovore u Play Console-u daje vlasnik naloga; ovde su predlozi,
proverite ih pri svakoj novoj verziji.

## 1. Build

```bash
cd app
tool/build_play.sh        # → build/app/outputs/bundle/release/app-release.aab
```

- Potpisuje se ključem iz `android/key.properties` (upload ključ). Play App Signing zatim
  potpisuje svojim ključem, pa **aplikacija sa Play-a ne može da ažurira APK sa GitHub-a i
  obrnuto** (drugi potpis). Kupcima dajte jedan izvor.
- `STORE_BUILD=true`: nema provere ni instaliranja ažuriranja iz aplikacije (to radi Play).
- `-Pplay=true` (`android/app/src/play/AndroidManifest.xml`) uklanja iz manifesta:
  - `REQUEST_INSTALL_PACKAGES` — Play ne dozvoljava aplikacijama koje se same ažuriraju;
  - geolocator-ov servis za lokaciju u pozadini — aplikacija lokaciju traži samo jednom, za
    vreme, pa nije potrebna izjava za lokaciju u prvom planu/pozadini.
- Provera posle build-a: u
  `build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml`
  ne sme biti ni `REQUEST_INSTALL_PACKAGES` ni `GeolocatorLocationService`.
- `targetSdk` 36, `minSdk` 24 (Play traži target 35+ za nove aplikacije od avgusta 2025).
- Brendirana verzija: `android/brand.properties` važi i ovde (svoj `applicationId`, ime, boja).

## 2. Politika privatnosti (obavezan URL)

[`docs/privacy/index.html`](privacy/index.html) je ista izjava kao `PRIVACY.md`, kao web
stranica. Objavljivanje preko GitHub Pages: repozitorijum → Settings → Pages → Source
„Deploy from a branch”, grana `main`, folder `/docs`. Adresa je onda
`https://<korisnik>.github.io/<repozitorijum>/privacy/`. Brend koji ima svoj sajt stavlja istu
stranu na svoj domen (sa svojim imenom i kontaktom).

## 3. Data safety (Bezbednost podataka)

Ključno: autor aplikacije **nema server i ne prima nikakve podatke**. Podaci idu samo na
Home Assistant koji korisnik sam unese (svoj server), a ka trećima samo ono što korisnik
izričito uključi.

| Pitanje | Predlog odgovora | Zašto |
|---|---|---|
| Da li aplikacija prikuplja ili deli podatke? | **Da** (konzervativno) | Lokacija za vreme ide MET Norway; glas i tekst komandi idu na korisnikov HA |
| Šifrovanje u prenosu | Da, kad server koristi HTTPS; na kućnoj mreži korisnik može izabrati HTTP | Upozorenje se prikazuje u aplikaciji; ako Play traži „sve šifrovano”, odgovorite „Ne” |
| Brisanje podataka | Korisnik može da obriše sve | Podešavanja → „Obriši sve lokalne podatke”; nema naloga kod autora |
| **Lokacija → Približna** | Prikupljeno, deljeno (MET Norway), opciono, nije čuvano, svrha: funkcionalnost aplikacije | Samo kad korisnik izabere „vreme na mestu telefona”; zaokruženo na ~1 km |
| **Audio → Glasovni snimci** | Prikupljeno, nije deljeno, opciono, obrađuje se prolazno, svrha: funkcionalnost | Assist: snimak ide samo na korisnikov HA dok se drži dugme |
| **Poruke / Tekst** (komande Assist-u, poruke ukućanima) | Prikupljeno, nije deljeno, opciono, svrha: funkcionalnost | Samo ka korisnikovom HA |
| **Fotografije** (slike soba, foto-okvir) | Ne napušta uređaj | Ostaju na uređaju, ne prijavljuju se |
| Lični podaci, finansije, kontakti, istorija pregledača, ID uređaja, analitika, reklame | **Ne** | Nema analitike, praćenja ni reklama |
| Dijagnostika („Pošalji servisu”) | Ne prikuplja je aplikacija sama | Korisnik je ručno šalje preko menija za deljenje, kome izabere |

Ako vaš brend dodaje svoj server (npr. pregled kuća preko vašeg sistema), ovi odgovori se
menjaju.

## 4. Izjave za dozvole i posebne mogućnosti

| Stavka | Šta Play pita | Odgovor / šta pripremiti |
|---|---|---|
| `FOREGROUND_SERVICE_REMOTE_MESSAGING` (servis `ConnectionService`) | Izjava o servisu u prvom planu + kratak video | Opciono („Poruke i kad je aplikacija zatvorena”): drži vezu sa korisnikovim HA da bi stigle poruke i upozorenja (dim, voda, alarm) bez Google push servera. Video: uključivanje u Podešavanjima → stalno obaveštenje → poruka iz HA stiže dok je aplikacija zatvorena |
| `BIND_DEVICE_ADMIN` (vlasnik uređaja za zidni panel) | Politika „Device Admin” | Koristi se samo kad instalater podesi namenski zidni tablet kao *device owner* preko `adb` (kiosk, pokretanje posle nestanka struje). Na običnom telefonu se ne traži. Ako Play odbije, za Play verziju se može izostaviti, a panel instalirati sa APK-a |
| `CAMERA` | Uobičajena dozvola | QR kod za prijavu/uređaje; po želji buđenje zidnog panela kad neko priđe (obrada na uređaju) |
| `RECORD_AUDIO` | Uobičajena dozvola | Glasovne komande, ključna reč na panelu, pljesak — samo kad se uključi |
| `ACCESS_COARSE_LOCATION` | Uobičajena dozvola | Vreme na mestu telefona, samo ako se izabere |
| `NFC` | — | NFC nalepnice Home Assistanta |
| Asistent (ASSIST intent) | Nema posebne izjave | Može se izabrati kao digitalni asistent telefona |
| Android Auto (kategorija IoT) | Posebna prijava za Android Auto u Play Console-u | IoT aplikacije su dozvoljene; prijava traži opis i snimke ekrana iz automobila. Za prvu objavu može se odložiti |
| Wear OS | Poseban Wear build se objavljuje kao deo istog listinga | Za sada samo kao APK (`open-smart-home-wear.apk`); za Play treba poseban App Bundle modula `wear` |

## 5. Pristup za recenzente (App access)

Aplikacija bez Home Assistant servera ne radi ništa, a demo kuća postoji samo u profile
build-u. Recenzent mora dobiti:

- **adresu probnog HA** dostupnog sa interneta (npr. Nabu Casa ili poseban server sa par
  izmišljenih uređaja — *ne* stvarnu kuću) i **probni nalog** (korisničko ime i lozinka, ne
  dugotrajni token sa vašeg pravog naloga);
- uputstvo u 3 koraka: „Get started → upišite adresu → prijavite se”.

Bez toga Play obično odbije aplikaciju („nismo mogli da pristupimo”).

## 6. Ostalo u Play Console-u

- **Kategorija:** Kuća i dom (House & Home); **ciljna publika:** 18+ (ne deca — kontrola
  brava i alarma); **upitnik o sadržaju:** bez nasilja, bez korisničkog sadržaja koji se deli
  javno, bez kupovine u aplikaciji, bez reklama.
- **Grafika:** ikonica 512×512, *feature graphic* 1024×500, bar 2 snimka ekrana telefona
  (postoje u `docs/screenshots/`) i, za listing tableta, snimci 7" i 10" (`tablet-kiosk.jpg`).
- **Opis:** jasno da je potreban sopstveni Home Assistant server i da aplikacija nije
  zvanična aplikacija Home Assistant projekta (ime i logo Home Assistanta se ne koriste kao
  ikonica ni naziv).
- **Nalog programera:** jednokratna taksa; organizacioni nalog traži D-U-N-S broj firme. Novi
  lični nalozi moraju pre objave da sprovedu zatvoreno testiranje (bar 12 testera, 14 dana) —
  dobra prilika za probni rad u pravim kućama.
- **Testiranje:** interni/zatvoreni test pre produkcije; Play-ov *pre-launch report* će
  prijaviti da bez servera ne može dalje — to je očekivano.
