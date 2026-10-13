# Changelog

## [Unreleased]

### Izmenjeno
- Novi kiosk ekran za zidni tablet: stakleni paneli preko gradijenta (4 pozadine po izboru, opcija „lakši efekti” bez zamućenja), krupan sat sa sekundama, vreme sa prognozom, termostat sa polukružnim regulatorom (prevlačenje, −/+, uključi/isključi, režimi), sobe sa brojem upaljenih svetala i temperaturom, prečice (dodir uključuje/isključuje, dugi dodir otvara uređaj), scene i statusna traka (svetla, klima, vrata i prozori, snaga, upozorenja). Na uspravnom tabletu paneli idu jedan ispod drugog.
- Nova komanda `SetPresetMode` (`climate`/`fan.set_preset_mode`, `humidifier.set_mode`) uz proveru dozvoljenih vrednosti.
- Novi vizuelni stil „topli minimalizam”: topla pozadina, bele zaobljene kartice bez okvira, pill dugmad, pozdrav i datum na početnom ekranu. Uključeni uređaji dobijaju boju svoje vrste (svetla žuto, hlađenje plavo, grejanje narandžasto, utičnice zeleno, mediji ljubičasto, roletne/senzori tirkizno), upozorenja i alarmi svoje boje. Sve kombinacije imaju kontrast teksta ≥ 4,5:1, posebno podešene za svetlu i tamnu temu.

### Dodato
- Kontrola muzike i medija: panel „Muzika i mediji” (izbor plejera, uključi/isključi, pusti/pauziraj, prethodna/sledeća, jačina, izvor) sa početnog ekrana i iz kioska; dugme je u kiosku uvek vidljivo pored Assista; komanda `select_source`.
- Prognoza za lokaciju doma (MET Norway, uz pristanak) kad HA nema `weather` entitet; koordinate iz `/api/config`, zaokružene na ~1 km; 24 h po satima i 7 dana.

### Ispravljeno
- Dve kartice za vreme kad su uključene i prognoza za dom i „Vreme na mojoj lokaciji”: kartica za lokaciju uređaja se sada prikazuje samo kad je uređaj dalje od 10 km od doma; ako je lokacija doma u HA daleko (> 50 km), aplikacija upozorava da je proverite.
- „Muzika i mediji” je uvek vidljivo (početni ekran i kiosk); bez media plejera objašnjava šta treba dodati u Home Assistantu.
- Kiosk: panel vremena i kalendar više se ne skrivaju kad HA nema entitet za vreme ili kalendare – prikazuju objašnjenje (kalendar i dalje prikazuje mesec).
- Kiosk: „sada svira” je na užim tabletima bio van ekrana u donjoj traci.
- „Dodaj uređaj”: Zigbee uparivanje iz aplikacije preko huba (ZHA `zha.permit` ili Zigbee2MQTT preko `mqtt.publish`), odbrojavanje 3 min sa produžavanjem i zaustavljanjem, automatsko zatvaranje pri izlasku, lista novih uređaja i podešavanje imena i prostorije; Wi-Fi/LAN, Matter i Z-Wave označeni kao „uskoro”. Ulaz iz Podešavanja i sa ekrana Sobe (+).
- Mediji: „sada svira” (naslov, izvođač, omot) na početnom ekranu i u kiosk traci, pusti/pauziraj, prethodna/sledeća, jačina zvuka; komande `media_play_pause`, `media_next_track`, `media_previous_track`.
- Assist: tekstualne komande i pitanja Home Assistantu (dokumentovani `/api/conversation/process`) sa predlozima, u kiosku (dugme u traci) i u aplikaciji (plutajuće dugme); razgovor se nastavlja u istoj sesiji.
- Kalendar: događaji iz svih HA kalendara (dokumentovani REST `/api/calendars`), mesečni prikaz sa označenim danima i lista po danima (Danas, Sutra…), boja po kalendaru, osvežavanje na 5 min; ekran „Kalendar” i kiosk panel (scene tada prelaze u prečice); kalendar u kiosku može da se isključi.
- Kamere: snimci preko dokumentovanog `camera_proxy` (osvežavanje svake 2 s samo dok je kamera na ekranu, pauza u čuvaru ekrana), ekran kamere sa celim ekranom i zumiranjem, kiosk panel sa prebacivanjem između kamera; kamere u kiosku mogu da se isključe. Demo režim ima tri generisane kamere.
- Ukućani: HA `person` entiteti (kod kuće / nije kod kuće / zona) kao avatari sa slikom ili inicijalima u kiosk zaglavlju.
- Statusi na vrhu kiosk ekrana: do 6 izabranih uređaja ili senzora sa stanjem i vremenom poslednje promene („Veš mašina · Završeno · pre 2 minuta”); izbor u Podešavanjima → Kiosk.
- Vremenska prognoza: po satima (24 h, kriva temperature, verovatnoća padavina) i za narednih 7 dana (raspon temperatura); poseban ekran koji se otvara dodirom na karticu vremena (i u kiosku). Kiosk panel vremena prikazuje i naredne sate.
- Vreme na dashboardu: kod kuće iz Home Assistanta (trenutno, 5 dana, pločica „Napolju”), opciono na lokaciji telefona preko MET Norway uz prethodni pristanak; približna lokacija zaokružena na ~1 km.
- Energy ekran: trenutna snaga uživo, potrošnja danas / ove nedelje / ovog meseca po satima ili danima (grafikon + tabela), mreža, solar, baterija, gas, najveći potrošači, procena troška po lokalno unetoj tarifi. Nekonfigurisani izvori se ne prikazuju; bez veze jasna poruka.
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
