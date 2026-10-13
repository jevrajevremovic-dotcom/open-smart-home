# Changelog

## [Unreleased] – 0.1.0

### Dodato
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
- 106 unit/widget testova.
