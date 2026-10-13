# Changelog

## [Unreleased]

### Dodato
- Automatsko pronalaženje Home Assistant servera na lokalnoj mreži (mDNS `_home-assistant._tcp`, Android NsdManager / Apple Bonjour), pretraga od 10 s sa ponavljanjem, samo lokalne adrese, IPv4 pre `.local`.
- OAuth2 prijava na webu (HA login stranica, automatska obnova tokena, opoziv pri odjavi, „Zapamti me“); kompatibilno sa tokenima sačuvanim u 0.1.0.
- `gateway/`: Docker Compose za lokalni hub (Home Assistant, Mosquitto, Zigbee2MQTT, Z-Wave JS UI, Matter Server, OTBR, ESPHome) sa profilima, named volumenima, health check-ovima, `.env.example`, MQTT lozinkama generisanim iz okruženja i backup/restore skriptama; uputstvo `docs/GATEWAY.md`.
- Apache-2.0 licenca i NOTICE.

## [0.1.0] – 2026-10-13 (MVP)

### Dodato
- Faza 9 – stabilizacija:
  - integration testovi na pravom uređaju (Keystore, SharedPreferences, keš na disku, wakelock);
  - performance test sa 2200 entiteta; događaji se spajaju u najviše jedno osvežavanje na 50 ms;
  - test curenja resursa (soketi i pretplate kroz cikluse prijave i odjave);
  - CI (format, analiza, testovi, web i Android build), CONTRIBUTING.md, TROUBLESHOOTING.md;
  - verzija 0.1.0.
- Faza 8 – offline keš:
  - poslednji snimak doma (stanja, registri, konfiguracija) čuva se u sirovom HA formatu i pri pokretanju se odmah prikazuje;
  - podaci iz keša i podaci tokom prekida veze uvek su označeni trakom sa vremenom poslednjeg potvrđenog ažuriranja;
  - dok podaci nisu aktuelni, kontrole su onemogućene, a servis komandi ih odbija;
  - posle povezivanja puna sinhronizacija zamenjuje keš, a stari keš nikad ne prepisuje novije žive podatke;
  - mobilni keš: privatni folder aplikacije, atomični upis, heširan naziv fajla; web keš: samo `sessionStorage` taba;
  - upis 3 s posle poslednje promene i pri slanju aplikacije u pozadinu; odjava i brisanje podataka brišu keš;
  - naziv doma se čita iz WS `get_config` i kešira.
- Faza 7 – tablet i kiosk:
  - kiosk režim: fullscreen dashboard sa satom i datumom, tekst uvećan 20 %, bez standardne navigacije, ekran stalno uključen;
  - izlaz zaključan PIN-om (PBKDF2-HMAC-SHA256 sa solju, blokada 30 s posle 5 pogrešnih pokušaja);
  - dok je kiosk aktivan, ruter preusmerava svaku drugu rutu nazad u kiosk, a „back” je blokiran;
  - povratak na kiosk dashboard i zatamnjenje sa satom posle neaktivnosti (podesivo), buđenje dodirom;
  - opcija „otvori u kiosk režimu pri pokretanju”; odjava uvek izlazi iz kioska;
  - dashboard na širokim i landscape ekranima prikazuje dva panela;
  - ponovno povezivanje odmah kad se aplikacija vrati u prvi plan.
- Faza 6 – korisnički interfejs: navigacija Početna / Prostorije / Omiljeno / Scene / Podešavanja.
- Dashboard generisan iz uređaja: temperatura, vlažnost, upaljena svetla, otvorena vrata i prozori, snaga, upozorenja, omiljeno, scene, prostorije i „potrebna pažnja” (slabe baterije, nedostupni uređaji). Nedostupni podaci prikazuju se kao „—”, nikad izmišljeni.
- Prostorije (temperatura, broj upaljenih svetala, upozorenja) i uređaji grupisani po kategorijama.
- Detalji uređaja generisani iz mogućnosti: uključi/isključi, svetlina, temperatura boje, boja, termostat (+/− sa debounce-om, režimi, ventilator), roletne (otvori/stop/zatvori/položaj), brava sa potvrdom otključavanja, jačina zvuka, senzori, scene i automatizacije, informacije o uređaju.
- Omiljeno, lokalno po serveru.
- Scene, skripte i automatizacije (pokretanje, uključivanje/isključivanje).
- Jedinstveni model uređaja (`SmartHomeDevice`, 49 kategorija, 45 mogućnosti) i mapper iz Home Assistant entiteta za 20+ domena, na osnovu `device_class`, color modova i `supported_features` bitova.
- Učitavanje HA registara (prostorije, proizvođač, model, protokol); baterija i signal se pridružuju uređaju.
- `HomeStateRepository`: snimak + događaji bez gubitaka, ponovna sinhronizacija posle reconnect-a, status zastarelih podataka.
- Tipizovane komande uređaja sa proverom dostupnosti, mogućnosti i potvrdom kritičnih radnji.
- `docs/DEVICE_CAPABILITIES.md`.
- Web platforma (JS i WebAssembly build): platformski transportni sloj, token u `sessionStorage`, provera mixed content-a, automatski predlog adrese kada aplikaciju hostuje Home Assistant, uputstvo za CORS.
- Flutter projekat (Android, iOS) sa feature-first strukturom, strožim lint pravilima.
- Material 3 tema (svetla/tamna/sistemska) sa semantičkim statusnim bojama.
- Lokalizacija: srpski (latinica) i engleski, izbor jezika u onboardingu i podešavanjima.
- Onboarding: dobrodošlica, adresa servera sa validacijom i procenom rizika, provera dostupnosti, prijava tokenom.
- Pinovanje samopotpisanih sertifikata uz eksplicitnu potvrdu otiska.
- Bezbedno čuvanje tokena, odjava, brisanje svih lokalnih podataka.
- Home Assistant REST klijent i WebSocket menadžer sa reconnect logikom.
- Mock režim sa in-memory Home Assistant serverom.
- Početni ekran sa statusom veze i živim prikazom promena stanja.
- 157 unit/widget/performance testova + 4 integration testa na uređaju.
