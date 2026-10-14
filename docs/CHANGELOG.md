# Changelog

## [Unreleased]

### Izmenjeno
- Novi kiosk ekran za zidni tablet: stakleni paneli preko gradijenta (4 pozadine po izboru, opcija „lakši efekti” bez zamućenja), krupan sat sa sekundama, vreme sa prognozom, termostat sa polukružnim regulatorom (prevlačenje, −/+, uključi/isključi, režimi), sobe sa brojem upaljenih svetala i temperaturom, prečice (dodir uključuje/isključuje, dugi dodir otvara uređaj), scene i statusna traka (svetla, klima, vrata i prozori, snaga, upozorenja). Na uspravnom tabletu paneli idu jedan ispod drugog.
- Nova komanda `SetPresetMode` (`climate`/`fan.set_preset_mode`, `humidifier.set_mode`) uz proveru dozvoljenih vrednosti.
- Novi vizuelni stil „topli minimalizam”: topla pozadina, bele zaobljene kartice bez okvira, pill dugmad, pozdrav i datum na početnom ekranu. Uključeni uređaji dobijaju boju svoje vrste (svetla žuto, hlađenje plavo, grejanje narandžasto, utičnice zeleno, mediji ljubičasto, roletne/senzori tirkizno), upozorenja i alarmi svoje boje. Sve kombinacije imaju kontrast teksta ≥ 4,5:1, posebno podešene za svetlu i tamnu temu.

### Dodato
- Tailscale adrese (`100.64.0.0/10`, `fd7a:115c:a1e0::/48`, `*.ts.net`) se prepoznaju kao VPN: nema lažnog upozorenja da token putuje nešifrovano preko interneta kada se koristi `http://` kroz Tailscale.
- Android widget za početni ekran „Scene”: do četiri scene (omiljene prve) kao dugmad; dodir otvara aplikaciju i pokreće scenu čim su podaci uživo, uz poruku „Pokrenuto: …” (i za prečice sa ikonice). Napravljen bez dodatnog plugina (sopstveni kanal u `MainActivity`), pa nema upozorenja o Kotlin Gradle Plugin-u. Widget sadrži samo imena i ID-jeve scena, nikad token; prati svetlu/tamnu temu sistema.
- „Podigni sve / Spusti sve” za roletne i zavese u sobi (kad ih ima bar dve), jednim `cover.open_cover/close_cover` pozivom; garažna vrata nikad nisu uključena jer otvaranje traži posebnu potvrdu.
- Opciona obaveštenja o kritičnim upozorenjima (dim, CO, curenje vode, aktiviran alarm, zaglavljena brava) kao sistemsko obaveštenje telefona, dok aplikacija radi; dodir otvara uređaj, rešeno upozorenje nestaje. Bez push servera i clouda. Android build sada koristi core library desugaring.
- Ekran „Aktivnost” (početni ekran → Aktivnost): šta se desilo u domu u poslednja 24 h iz HA dnevnika – svetla, vrata i bezbednost, ukućani – sa oznakom kada je promenu napravila osoba; dodir otvara uređaj. U režimu za decu i goste skriveni uređaji se ne prikazuju ni ovde.
- Napredniji editor automatizacija: više okidača (pokreće se na bilo koji), novi okidač „vrednost senzora poraste iznad / padne ispod”, i uslovi „samo ako” – dani u nedelji, vremenski prozor (i preko ponoći), uređaj u određenom stanju, samo kad je mrak / dan. Automatizacije koje koriste nešto što editor ne ume da prikaže (npr. `for:`, `data:` u radnji, šabloni) i dalje se ne menjaju u aplikaciji, da se ništa tiho ne izgubi.
- Prenos podešavanja na drugi uređaj (Podešavanja → Prenos): tema, jezik, omiljeni i kiosk raspored se kopiraju kao tekst i nalepe na drugom uređaju; tokeni, PIN-ovi, fotografija i izbori privatnosti se nikad ne kopiraju.
- Kiosk: sopstvena fotografija kao pozadina (zatamnjena radi čitljivosti), čuva se samo na uređaju; nije dostupno na webu.
- Izmena postojećih automatizacija u editoru aplikacije (učitava se konfiguracija iz HA; složenije automatizacije se menjaju u HA). Razume i stari format (`platform`/`service`).
- Prečice na ikonici aplikacije (dugi pritisak, Android/iOS): do dve scene (omiljene prve), Assist i Kiosk; scena se pokreće čim su podaci uživo.
- Energija: ukupna potrošnja prethodnog perioda (juče / prošle nedelje / prošlog meseca) ispod trenutne, radi poređenja.
- Scene od trenutnog stanja (Scene → +): izaberete uređaje (podrazumevano uključeni), aplikacija sačuva stanje, jačinu, boju, položaj roletni i temperaturu kao HA scenu; brisanje UI scena.
- Spratovi: ako su u HA podešeni (registar spratova, HA 2024.4+), sobe se na ekranu Sobe grupišu po spratovima (od najnižeg), ostale pod „Ostalo”.
- „Upali sva / Ugasi sva” svetla u sobi i u celoj kući (dodir na karticu svetala na početnom ekranu ili u kiosku), jednim `light.turn_on/off` pozivom.
- Jednostavan editor automatizacija (Scene → Automatizacije → +): „kada” (vreme i dani, promena uređaja, izlazak/zalazak sunca uz pomeraj) i „uradi” (jedna ili više radnji na uređajima ili scenama); čuva se kao obična HA automatizacija; brisanje automatizacija napravljenih u UI-ju.
- Režim za decu i goste (Podešavanja → Bezbednost): skriva brave, alarm, garažna vrata i kamere, isključuje Assist i dodavanje uređaja, a podešavanja zaključava PIN-om (PBKDF2 heš). Lokalno na uređaju; ovlašćenja u HA se ne menjaju.
- Izmena imena i prostorije bilo kog uređaja sa njegovog ekrana (HA uređaj ili, za pomoćnike, entitet; nije dostupno u kiosku).
- Pretraga svih uređaja po imenu, prostoriji, vrsti ili stanju.
- Promena redosleda omiljenih (prevlačenjem) – isti redosled je na početnom ekranu i u kiosku.
- Nove kontrole: ventilator (brzina u koracima ventilatora, okretanje, režimi), ovlaživač/odvlaživač (ciljna vlažnost, režim), robot usisivač (pokreni, pauza, na punjač), HA pomoćnici „izbor” (`select`/`input_select`) i „broj” (`number`/`input_number`, sa korakom i opsegom).
- Alarmni panel: stanje (sa režimom), uključivanje u režimima koje panel podržava (kod kuće, odsutni, noć, odmor, prilagođeno) i isključivanje sa tastaturom za kod (kod se ne čuva); isključivanje je kritična komanda (potvrda + opciono otisak).
- Više domova: Podešavanja → „Dodaj još jedan dom” (prijava na drugi HA server bez odjave sa prvog), lista domova i prebacivanje (i dodirom na ime doma na početnom ekranu); svaki dom ima svoj token, keš i omiljene; odjava sa jednog prelazi na drugi.

### Ispravljeno
- Nepoznata adresa u aplikaciji vodi na početni ekran umesto stranice sa greškom rutera; Android linkovi se ne prosleđuju ruteru (Flutter deep linking isključen), čita ih samo kanal widgeta.
- Energija: prva i poslednja oznaka vremena na grafikonu više nisu odsečene.
- Ikonica klime/termostata prati režim (plamen za grejanje, pahulja za hlađenje, kapljica za sušenje…); standardni režimi ventilatora klime su prevedeni (Slabo, Srednje, Jako, Automatski…), prilagođeni ostaju kako ih integracija prijavi.
- Kiosk: statusni čipovi koriste celu širinu (media čip više ne uzima pola reda), a skriveni čipovi i događaji u kalendaru blago blede na ivici umesto da budu odsečeni.
- Senzori u istoriji, Aktivnosti i editoru automatizacija sada pišu šta stanje znači („Otvoreno/Zatvoreno”, „Pokret/Nema pokreta”, „Dim!”…) umesto „Uključeno/Isključeno”; filter „Svetla” u Aktivnosti; kvačica više ne prekriva ikonicu vrste okidača.
- Android build više ne prijavljuje upozorenje o Kotlin Gradle Plugin-u: pretraga HA na mreži na Androidu ide kroz sopstveni kanal ka NsdManager-u (paket `nsd_android` je uklonjen); pretraga se gasi i kada Android uništi aktivnost.
- Sistemsko „nazad” na ekranu „Dodaj još jedan dom” vraća na trenutni dom umesto da zatvori aplikaciju.
- Natpis „Podešavanja” u donjoj navigaciji se lomio u dva reda na telefonima širine oko 400 dp.
- Test energije je padao između 23:00 i ponoći (nema „budućeg” sata u danu).
- Zaključavanje aplikacije otiskom prsta, licem ili PIN-om uređaja i opciona dodatna potvrda pre otključavanja vrata, otvaranja garaže i isključivanja alarma (Podešavanja → Bezbednost).
- Kamere: režim „Uživo” (HLS iz HA, Android/iOS) pored snimaka, za kamere koje podržavaju stream; kad uživo nije moguće, jasna poruka i snimci.
- Obaveštenja iz Home Assistanta: kartica na početnom ekranu i zvonce u kiosku kad ih ima, lista sa vremenom, odbacivanje jednog ili svih; ažurira se uživo.
- Istorija na ekranu uređaja: grafikon za numeričke senzore (24 h / 7 dana, min/maks, očitavanje prevlačenjem prsta) i vremenska traka za uključeno/isključeno, otvoreno/zatvoreno, kod kuće…, uz listu aktivnosti (dokumentovani `/api/history` i `/api/logbook`).
- „Dodaj uređaj → Z-Wave”: uključivanje preko Z-Wave JS sa S2 bezbednošću (izbor nivoa, PIN sa nalepnice), praćenje intervjua i lista novih uređaja; SmartStart prijava skeniranjem QR koda. Uključivanje se zaustavlja pri izlasku sa ekrana.
- „Dodaj uređaj → Matter”: dodavanje Matter uređaja deljenog iz druge aplikacije (Google Home, Apple Home, SmartThings…) skeniranjem QR koda ili unosom 11-cifrenog koda (provera kontrolne cifre), preko HA Matter integracije.
- „Dodaj uređaj → Wi-Fi i LAN”: lista uređaja koje je HA pronašao na mreži (Shelly, ESPHome, Hue, Cast…) i vođeno podešavanje u aplikaciji – HA koraci i formulari prikazani na jeziku aplikacije, greške kod polja, na kraju lista novih uređaja.
- Glasovne komande u Assistu: mikrofon pored polja za unos; govor se pretvara u tekst na telefonu (podrazumevano samo na uređaju; prepoznavanje preko interneta samo uz izričitu dozvolu, pita se jednom i menja u Podešavanjima → Privatnost), tekst ide u HA Assist.
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
