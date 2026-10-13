// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Serbian (`sr`).
class AppLocalizationsSr extends AppLocalizations {
  AppLocalizationsSr([String locale = 'sr']) : super(locale);

  @override
  String get appTitle => 'Open Smart Home';

  @override
  String get mockModeBanner => 'MOCK REŽIM — demo podaci, bez stvarnih uređaja';

  @override
  String get welcomeTitle => 'Vaš dom, u jednoj aplikaciji';

  @override
  String get welcomeBody =>
      'Upravljajte svetlima, klimom, senzorima i scenama svih proizvođača i protokola koje podržava vaš Home Assistant server.';

  @override
  String get welcomeLocalFirst => 'Radi lokalno. Cloud nalog nije potreban.';

  @override
  String get chooseLanguage => 'Jezik';

  @override
  String get languageSystem => 'Sistemski';

  @override
  String get languageSerbian => 'Srpski';

  @override
  String get languageEnglish => 'English';

  @override
  String get getStarted => 'Započni';

  @override
  String get back => 'Nazad';

  @override
  String get cancel => 'Otkaži';

  @override
  String get continueAction => 'Nastavi';

  @override
  String get serverAddressTitle => 'Povezivanje sa Home Assistantom';

  @override
  String get serverAddressIntro =>
      'Unesite adresu vašeg Home Assistant servera, na primer onu koju kod kuće otvarate u pregledaču.';

  @override
  String get serverAddressLabel => 'Adresa servera';

  @override
  String get serverAddressHint => 'homeassistant.local:8123';

  @override
  String get checkConnection => 'Proveri vezu';

  @override
  String get checking => 'Proveravam…';

  @override
  String serverReachable(String address) {
    return 'Home Assistant je pronađen na adresi $address';
  }

  @override
  String get addressErrorEmpty => 'Unesite adresu servera.';

  @override
  String get addressErrorMalformed => 'Ovo nije ispravna adresa.';

  @override
  String get addressErrorUnsupportedScheme =>
      'Podržane su samo http:// i https:// adrese.';

  @override
  String get addressErrorMissingHost =>
      'Adresi nedostaje naziv računara ili IP adresa.';

  @override
  String get addressErrorCredentials =>
      'Ne unosite korisničko ime ili lozinku u adresu.';

  @override
  String get addressErrorPath =>
      'Home Assistant mora biti dostupan na korenu adrese (bez putanje kao što je /ha).';

  @override
  String get addressErrorQuery => 'Uklonite deo adrese posle znaka ? ili #.';

  @override
  String get addressErrorPort => 'Port mora biti između 1 i 65535.';

  @override
  String get riskLocalHttp => 'Nešifrovana veza unutar vaše lokalne mreže.';

  @override
  String get riskRemoteExposure =>
      'Ovo je javna adresa. Proverite da je server ažuran i zaštićen.';

  @override
  String get riskInsecureRemote =>
      'Upozorenje: ova javna adresa koristi nešifrovani HTTP. Vaš pristupni token može biti presretnut. Koristite HTTPS, osim ako veza ide kroz VPN.';

  @override
  String get insecureAcknowledge => 'Razumem rizik (npr. koristim VPN)';

  @override
  String get certificateUntrustedTitle => 'Nepouzdan sertifikat';

  @override
  String get certificateUntrustedBody =>
      'Ovaj uređaj ne veruje sertifikatu servera. To je uobičajeno za samopotpisani sertifikat, ali može značiti i da neko presreće vezu. Nastavite samo ako se otisak poklapa sa onim na vašem serveru.';

  @override
  String get certificateSubject => 'Izdat za';

  @override
  String get certificateIssuer => 'Izdavač';

  @override
  String get certificateValidUntil => 'Važi do';

  @override
  String get certificateFingerprint => 'SHA-256 otisak';

  @override
  String get certificateExpired => 'Ovaj sertifikat je istekao.';

  @override
  String get certificateConfirm =>
      'Uporedio/la sam otisak i verujem ovom sertifikatu';

  @override
  String get trustCertificate => 'Veruj ovom sertifikatu';

  @override
  String get tokenTitle => 'Prijava';

  @override
  String get tokenIntro =>
      'Aplikacija se prijavljuje pomoću dugotrajnog pristupnog tokena iz vašeg Home Assistant korisničkog profila.';

  @override
  String get tokenSteps =>
      '1. Otvorite Home Assistant u pregledaču.\n2. Kliknite na svoje korisničko ime (dole levo) → Security.\n3. U delu „Long-lived access tokens” izaberite „Create token”.\n4. Kopirajte token i nalepite ga ispod. Home Assistant ga prikazuje samo jednom.';

  @override
  String get tokenLabel => 'Pristupni token';

  @override
  String get tokenMockHint =>
      'Mock režim: svaki token radi; „invalid” simulira odbijen token.';

  @override
  String get showToken => 'Prikaži token';

  @override
  String get hideToken => 'Sakrij token';

  @override
  String get connect => 'Poveži se';

  @override
  String get connecting => 'Povezivanje…';

  @override
  String get tokenInvalidFormat =>
      'Token ne sme biti prazan niti sadržati razmake.';

  @override
  String get failureNetwork =>
      'Server nije dostupan. Proverite adresu i da li je uređaj na odgovarajućoj mreži.';

  @override
  String get failureTimeout => 'Server predugo ne odgovara.';

  @override
  String get failureAuthentication =>
      'Pristupni token je odbijen. Možda je pogrešan, istekao ili opozvan.';

  @override
  String get failureAuthorization =>
      'Ovaj korisnik nema dozvolu za ovu radnju.';

  @override
  String get failureValidation => 'Server nije prihvatio zahtev.';

  @override
  String get failureParsing => 'Server je poslao neočekivan odgovor.';

  @override
  String get failureServer =>
      'Server je odgovorio, ali ne kao Home Assistant, ili je prijavio grešku.';

  @override
  String get failureCertificate =>
      'Bezbedna veza ne može da se potvrdi (problem sa sertifikatom).';

  @override
  String get failureUnavailableEntity => 'Ovaj uređaj trenutno nije dostupan.';

  @override
  String get failureUnsupportedFeature => 'Ovaj uređaj ne podržava ovu radnju.';

  @override
  String get failureWebSocket => 'Veza u realnom vremenu je prekinuta.';

  @override
  String get failureStorage =>
      'Nije moguće pristupiti bezbednom skladištu na uređaju.';

  @override
  String get failureUnknown => 'Došlo je do greške. Pokušajte ponovo.';

  @override
  String get navHome => 'Početna';

  @override
  String get navSettings => 'Podešavanja';

  @override
  String get statusConnected => 'Povezano';

  @override
  String get statusConnecting => 'Povezivanje…';

  @override
  String get statusAuthenticating => 'Prijavljivanje…';

  @override
  String get statusReconnecting => 'Ponovno povezivanje…';

  @override
  String statusReconnectingIn(int seconds) {
    return 'Ponovno povezivanje za $seconds s';
  }

  @override
  String get statusDisconnected => 'Nije povezano';

  @override
  String get statusAuthFailed => 'Prijava odbijena';

  @override
  String get statusServerUnavailable => 'Server nije dostupan';

  @override
  String get statusError => 'Greška veze';

  @override
  String get retryNow => 'Pokušaj odmah';

  @override
  String get signInAgain => 'Prijavi se ponovo';

  @override
  String serverVersion(String version) {
    return 'Home Assistant $version';
  }

  @override
  String get settingsTitle => 'Podešavanja';

  @override
  String get appearance => 'Izgled';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Sistemska';

  @override
  String get themeLight => 'Svetla';

  @override
  String get themeDark => 'Tamna';

  @override
  String get language => 'Jezik';

  @override
  String get serverSection => 'Server';

  @override
  String get signOut => 'Odjavi se';

  @override
  String get signOutConfirmTitle => 'Odjaviti se?';

  @override
  String get signOutConfirmBody =>
      'Pristupni token biće obrisan sa ovog uređaja. Možete se ponovo prijaviti u bilo kom trenutku.';

  @override
  String get deleteAllData => 'Obriši sve lokalne podatke';

  @override
  String get deleteAllConfirmTitle => 'Obrisati sve lokalne podatke?';

  @override
  String get deleteAllConfirmBody =>
      'Sa ovog uređaja biće uklonjeni pristupni token, adresa servera i sva podešavanja. Na Home Assistant serveru se ništa ne menja.';

  @override
  String get delete => 'Obriši';

  @override
  String get privacySection => 'Privatnost i podaci';

  @override
  String get addressErrorMixedContent =>
      'Ova stranica je učitana preko HTTPS-a, pa pregledač blokira veze ka http:// serveru. Koristite https:// adresu servera ili otvorite web aplikaciju sa iste adrese kao Home Assistant.';

  @override
  String get webConnectionHint =>
      'U pregledaču ovo može značiti i da Home Assistant ne dozvoljava adresu ove web aplikacije (dodajte je u http: cors_allowed_origins u configuration.yaml) ili da pregledač ne veruje sertifikatu servera (jednom otvorite adresu servera u novoj kartici i prihvatite ga).';

  @override
  String get webSessionNotice =>
      'Sa tokenom prijava traje samo dok je ova kartica otvorena.';

  @override
  String get failureConfirmationRequired => 'Potvrdite ovu radnju.';

  @override
  String devicesInRooms(int devices, int rooms) {
    String _temp0 = intl.Intl.pluralLogic(
      devices,
      locale: localeName,
      other: '$devices uređaja',
      few: '$devices uređaja',
      one: '$devices uređaj',
    );
    String _temp1 = intl.Intl.pluralLogic(
      rooms,
      locale: localeName,
      other: '$rooms prostorija',
      one: '$rooms prostoriji',
      zero: '0 prostorija',
    );
    return '$_temp0 u $_temp1';
  }

  @override
  String dataStaleSince(String time) {
    return 'Nema veze — prikazani su podaci poslednji put ažurirani $time. Možda nisu aktuelni.';
  }

  @override
  String get navRooms => 'Prostorije';

  @override
  String get navFavorites => 'Omiljeno';

  @override
  String get navScenes => 'Scene';

  @override
  String get stateOn => 'Uključeno';

  @override
  String get stateOff => 'Isključeno';

  @override
  String get stateUnavailable => 'Nedostupno';

  @override
  String get stateUnknown => 'Nepoznato';

  @override
  String stateOnBrightness(int percent) {
    return 'Uključeno · $percent %';
  }

  @override
  String get motionDetected => 'Detektovan pokret';

  @override
  String get motionClear => 'Nema pokreta';

  @override
  String get occupancyDetected => 'Prisutno';

  @override
  String get occupancyClear => 'Nema prisustva';

  @override
  String get contactOpen => 'Otvoreno';

  @override
  String get contactClosed => 'Zatvoreno';

  @override
  String get smokeDetected => 'Detektovan dim!';

  @override
  String get smokeClear => 'Nema dima';

  @override
  String get coDetected => 'Detektovan CO!';

  @override
  String get coClear => 'Nema CO';

  @override
  String get leakDetected => 'Curenje vode!';

  @override
  String get leakClear => 'Suvo';

  @override
  String get vibrationDetected => 'Vibracija';

  @override
  String get vibrationClear => 'Mirno';

  @override
  String get binaryActive => 'Aktivno';

  @override
  String get binaryInactive => 'Neaktivno';

  @override
  String get coverOpening => 'Otvara se…';

  @override
  String get coverClosing => 'Zatvara se…';

  @override
  String coverOpenPercent(int percent) {
    return 'Otvoreno $percent %';
  }

  @override
  String get lockLocked => 'Zaključano';

  @override
  String get lockUnlocked => 'Otključano';

  @override
  String get lockLocking => 'Zaključava se…';

  @override
  String get lockUnlocking => 'Otključava se…';

  @override
  String get lockJammed => 'Zaglavljeno!';

  @override
  String get alarmDisarmed => 'Isključen';

  @override
  String get alarmArmed => 'Uključen';

  @override
  String get alarmArming => 'Uključuje se…';

  @override
  String get alarmPending => 'Odbrojavanje…';

  @override
  String get alarmTriggered => 'ALARM!';

  @override
  String get hvacOff => 'Isključeno';

  @override
  String get hvacHeat => 'Grejanje';

  @override
  String get hvacCool => 'Hlađenje';

  @override
  String get hvacHeatCool => 'Grejanje/hlađenje';

  @override
  String get hvacAuto => 'Automatski';

  @override
  String get hvacDry => 'Sušenje';

  @override
  String get hvacFanOnly => 'Samo ventilator';

  @override
  String climateStatus(String mode, String temperature) {
    return '$mode · $temperature';
  }

  @override
  String get mediaPlaying => 'Reprodukcija';

  @override
  String get mediaPaused => 'Pauzirano';

  @override
  String get cameraIdle => 'Spremna';

  @override
  String get cameraStreaming => 'Prenos';

  @override
  String get cameraRecording => 'Snimanje';

  @override
  String get scriptRunning => 'Pokrenuto';

  @override
  String get routineReady => 'Spremno';

  @override
  String doorbellLast(String time) {
    return 'Poslednje zvono $time';
  }

  @override
  String get lowBattery => 'Slaba baterija';

  @override
  String batteryLevel(int percent) {
    return 'Baterija $percent %';
  }

  @override
  String get protocolCloud => 'Cloud';

  @override
  String get protocolVirtual => 'Virtuelni';

  @override
  String get favoritesEmpty =>
      'Dodirnite zvezdicu na stranici uređaja da ga dodate u omiljeno.';

  @override
  String get scenesTitle => 'Scene';

  @override
  String get scriptsTitle => 'Skripte';

  @override
  String get automationsTitle => 'Automatizacije';

  @override
  String get noScenes => 'Još nema scena.';

  @override
  String get dashboardAttention => 'Potrebna pažnja';

  @override
  String get summaryTemperature => 'Unutra';

  @override
  String get summaryHumidity => 'Vlažnost';

  @override
  String get summaryLights => 'Upaljena svetla';

  @override
  String get summaryOpenings => 'Otvorena vrata i prozori';

  @override
  String get summaryPower => 'Snaga';

  @override
  String get greetingMorning => 'Dobro jutro';

  @override
  String get greetingAfternoon => 'Dobar dan';

  @override
  String get greetingEvening => 'Dobro veče';

  @override
  String get greetingNight => 'Laku noć';

  @override
  String get summaryAlerts => 'Upozorenja';

  @override
  String get valueNotAvailable => 'Nije dostupno';

  @override
  String lightsOnOf(int on, int total) {
    return '$on od $total';
  }

  @override
  String lowBatteryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count slabih baterija',
      few: '$count slabe baterije',
      one: '$count slaba baterija',
    );
    return '$_temp0';
  }

  @override
  String unavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nedostupnih',
      few: '$count nedostupna',
      one: '$count nedostupan',
    );
    return '$_temp0';
  }

  @override
  String get roomNoRoom => 'Bez prostorije';

  @override
  String get allDevices => 'Svi uređaji';

  @override
  String roomDevicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uređaja',
      few: '$count uređaja',
      one: '$count uređaj',
      zero: 'Nema uređaja',
    );
    return '$_temp0';
  }

  @override
  String roomLightsOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count upaljenih svetala',
      few: '$count upaljena svetla',
      one: '$count upaljeno svetlo',
    );
    return '$_temp0';
  }

  @override
  String get roomEmpty => 'Nema uređaja u ovoj prostoriji.';

  @override
  String get noRoomsYet => 'U Home Assistantu nisu definisane prostorije.';

  @override
  String get groupLights => 'Svetla';

  @override
  String get groupClimate => 'Klima';

  @override
  String get groupCovers => 'Roletne i vrata';

  @override
  String get groupSwitches => 'Prekidači i utičnice';

  @override
  String get groupSecurity => 'Bezbednost';

  @override
  String get groupSensors => 'Senzori';

  @override
  String get groupMedia => 'Mediji';

  @override
  String get groupEnergy => 'Energija';

  @override
  String get groupOther => 'Ostalo';

  @override
  String get addFavorite => 'Dodaj u omiljeno';

  @override
  String get removeFavorite => 'Ukloni iz omiljenog';

  @override
  String get brightness => 'Jačina svetla';

  @override
  String get colorTemperature => 'Temperatura boje';

  @override
  String get warm => 'Toplo';

  @override
  String get cool => 'Hladno';

  @override
  String get color => 'Boja';

  @override
  String get targetTemperature => 'Željena temperatura';

  @override
  String get currentTemperature => 'Trenutno';

  @override
  String get increaseTemperature => 'Povećaj temperaturu';

  @override
  String get decreaseTemperature => 'Smanji temperaturu';

  @override
  String get mode => 'Režim';

  @override
  String get fanMode => 'Ventilator';

  @override
  String get position => 'Položaj';

  @override
  String get open => 'Otvori';

  @override
  String get close => 'Zatvori';

  @override
  String get stop => 'Zaustavi';

  @override
  String get lock => 'Zaključaj';

  @override
  String get unlock => 'Otključaj';

  @override
  String confirmUnlockTitle(String name) {
    return 'Otključati: $name?';
  }

  @override
  String confirmOpenTitle(String name) {
    return 'Otvoriti: $name?';
  }

  @override
  String confirmDisarmTitle(String name) {
    return 'Isključiti alarm: $name?';
  }

  @override
  String get confirmCriticalBody =>
      'Ova radnja utiče na bezbednost vašeg doma.';

  @override
  String get confirm => 'Potvrdi';

  @override
  String get activate => 'Pokreni';

  @override
  String get runNow => 'Pokreni sada';

  @override
  String sceneActivated(String name) {
    return 'Pokrenuto: $name';
  }

  @override
  String get automationEnabled => 'Uključena';

  @override
  String lastTriggered(String time) {
    return 'Poslednje pokretanje $time';
  }

  @override
  String get neverTriggered => 'Nikad pokrenuta';

  @override
  String get volume => 'Jačina zvuka';

  @override
  String get detailInfo => 'Informacije';

  @override
  String get infoRoom => 'Prostorija';

  @override
  String get infoManufacturer => 'Proizvođač';

  @override
  String get infoModel => 'Model';

  @override
  String get infoProtocol => 'Protokol';

  @override
  String get infoLastChanged => 'Poslednja promena';

  @override
  String get infoEntityId => 'ID entiteta';

  @override
  String get infoSignal => 'Signal';

  @override
  String get infoBattery => 'Baterija';

  @override
  String get deviceNotFound => 'Ovaj uređaj više ne postoji.';

  @override
  String get unavailableBanner =>
      'Uređaj je nedostupan. Kontrole su onemogućene dok se ponovo ne poveže.';

  @override
  String get controlsOffline =>
      'Kontrole će ponovo biti dostupne kada se veza uspostavi.';

  @override
  String get kioskSection => 'Kiosk režim (zidni tablet)';

  @override
  String get kioskStart => 'Pokreni kiosk režim';

  @override
  String get kioskStartOnLaunch => 'Otvori u kiosk režimu pri pokretanju';

  @override
  String get kioskKeepAwake => 'Drži ekran uključen';

  @override
  String get kioskDimAfter => 'Zatamni ekran posle';

  @override
  String get kioskReturnAfter => 'Vrati na početni ekran posle';

  @override
  String get kioskPin => 'PIN za izlaz';

  @override
  String get kioskPinSet => 'PIN je postavljen';

  @override
  String get kioskPinNotSet =>
      'Nema PIN-a — svako može da izađe iz kiosk režima';

  @override
  String get kioskSetPin => 'Postavi PIN';

  @override
  String get kioskChangePin => 'Promeni PIN';

  @override
  String get kioskRemovePin => 'Ukloni PIN';

  @override
  String get kioskPinHint => '4–8 cifara';

  @override
  String get kioskPinConfirm => 'Ponovite PIN';

  @override
  String get kioskPinMismatch => 'PIN-ovi se ne poklapaju.';

  @override
  String get kioskPinInvalid => 'Koristite 4–8 cifara.';

  @override
  String get kioskExit => 'Izađi iz kiosk režima';

  @override
  String get kioskEnterPin => 'Unesite PIN';

  @override
  String get kioskWrongPin => 'Pogrešan PIN.';

  @override
  String kioskLockedOut(int seconds) {
    return 'Previše pokušaja. Pokušajte ponovo za $seconds s.';
  }

  @override
  String get kioskTapToWake => 'Dodirnite za buđenje';

  @override
  String get kioskOsHint =>
      'Za potpuno zaključan zidni panel koristite i sistemsku kiosk funkciju: Android pinovanje ekrana ili kiosk launcher, iOS Guided Access. One mogu i automatski da pokrenu aplikaciju.';

  @override
  String get durationNever => 'Nikad';

  @override
  String durationSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String dataUpdating(String time) {
    return 'Prikazani su podaci od $time — ažuriranje…';
  }

  @override
  String get oauthSignIn => 'Prijavi se preko Home Assistanta';

  @override
  String get oauthHint =>
      'Prijavljujete se na stranici za prijavu vašeg Home Assistanta – aplikacija nikad ne vidi vašu lozinku.';

  @override
  String get rememberMe => 'Zapamti me na ovom uređaju';

  @override
  String get rememberMeHint =>
      'Ostajete prijavljeni i posle zatvaranja pregledača. Pristup možete opozvati bilo kada u Home Assistant profilu (Security → Refresh tokens).';

  @override
  String get orUseToken => 'Ili koristite dugotrajni pristupni token';

  @override
  String get loginFailed => 'Prijava nije završena. Pokušajte ponovo.';

  @override
  String get discoveryTitle => 'Home Assistant na ovoj mreži';

  @override
  String get discoverySearching => 'Pretraga…';

  @override
  String get discoveryNothingFound =>
      'Server nije automatski pronađen. Unesite adresu ispod.';

  @override
  String get discoverySearchAgain => 'Traži ponovo';

  @override
  String get energyTitle => 'Energija';

  @override
  String get energyToday => 'Danas';

  @override
  String get energyWeek => 'Ova nedelja';

  @override
  String get energyMonth => 'Ovaj mesec';

  @override
  String get energyCurrentPower => 'Trenutna snaga';

  @override
  String get energyNotConfigured =>
      'Energija još nije podešena u Home Assistantu (Podešavanja → Kontrolne table → Energija). Kada se podesi, ovde se prikazuju potrošnja, solar i uređaji.';

  @override
  String get energyOffline =>
      'Statistika energije se učitava iz Home Assistanta i dostupna je dok je aplikacija povezana.';

  @override
  String get energyConsumption => 'Potrošnja doma';

  @override
  String get energyFromGrid => 'Iz mreže';

  @override
  String get energyToGrid => 'U mrežu';

  @override
  String get energySolar => 'Solarna proizvodnja';

  @override
  String get energyBatteryCharge => 'Baterija – punjenje';

  @override
  String get energyBatteryDischarge => 'Baterija – pražnjenje';

  @override
  String get energyGas => 'Gas';

  @override
  String get energyCostEstimate => 'Procena troška';

  @override
  String get energySetTariff => 'Unesite tarifu za procenu troška';

  @override
  String get energyPerHour => 'Potrošnja po satima';

  @override
  String get energyPerDay => 'Potrošnja po danima';

  @override
  String get energyTopConsumers => 'Najveći potrošači';

  @override
  String get energyNoDevices =>
      'U Home Assistantu nijedan uređaj nije dodat u Energy kontrolnu tablu.';

  @override
  String get energyNoData => 'Još nema podataka za ovaj period.';

  @override
  String energyPeak(String time, String value) {
    return 'Najviše: $time · $value';
  }

  @override
  String get energyShowChart => 'Grafikon';

  @override
  String get energyShowTable => 'Tabela';

  @override
  String get energyConsumptionChart => 'Grafikon potrošnje';

  @override
  String get energyTariffTitle => 'Tarifa za struju';

  @override
  String get energyTariffHint =>
      'Koristi se samo za procenu na ovom uređaju. Pravi račun uključuje i fiksne naknade, poreze i višu/nižu tarifu.';

  @override
  String get energyTariffImport => 'Cena po kWh iz mreže';

  @override
  String get energyTariffExport => 'Naknada po kWh predatom u mrežu (opciono)';

  @override
  String get energyTariffCurrency => 'Valuta';

  @override
  String get energyTariffInvalid => 'Unesite ispravnu, nenegativnu cenu.';

  @override
  String get save => 'Sačuvaj';

  @override
  String get weatherClear => 'Vedro';

  @override
  String get weatherClearNight => 'Vedra noć';

  @override
  String get weatherPartlyCloudy => 'Delimično oblačno';

  @override
  String get weatherCloudy => 'Oblačno';

  @override
  String get weatherFog => 'Magla';

  @override
  String get weatherRain => 'Kiša';

  @override
  String get weatherHeavyRain => 'Jaka kiša';

  @override
  String get weatherSnow => 'Sneg';

  @override
  String get weatherSleet => 'Susnežica';

  @override
  String get weatherHail => 'Grad';

  @override
  String get weatherThunderstorm => 'Grmljavina';

  @override
  String get weatherWindy => 'Vetrovito';

  @override
  String get weatherExceptional => 'Nepogoda';

  @override
  String get weatherAtHome => 'Vreme kod kuće';

  @override
  String get weatherAtMyLocation => 'Vreme na mojoj lokaciji';

  @override
  String get weatherEnableDevice => 'Vreme na mojoj lokaciji';

  @override
  String get weatherEnableDeviceConfirm => 'Uključi';

  @override
  String get weatherDeviceDisclosure =>
      'Aplikacija će tražiti vašu približnu lokaciju (ne precizan GPS), zaokružiti je na oko 1 km i slati je servisu MET Norway (api.met.no) radi prognoze – otprilike na svakih 30 minuta dok je aplikacija otvorena. Ništa drugo se ne šalje. Možete isključiti bilo kada u Podešavanja → Privatnost i podaci.';

  @override
  String get weatherDeviceSettingHint =>
      'Približna lokacija se šalje servisu MET Norway. Podrazumevano isključeno.';

  @override
  String get weatherMetAttribution => 'Podaci: MET Norway (CC BY 4.0)';

  @override
  String get weatherLocationDeniedForever =>
      'Pristup lokaciji je blokiran za ovu aplikaciju.';

  @override
  String get weatherOpenSettings => 'Otvori podešavanja';

  @override
  String get weatherLocationOff => 'Lokacija je isključena na ovom uređaju.';

  @override
  String get weatherLocationDenied => 'Pristup lokaciji nije dozvoljen.';

  @override
  String get weatherDeviceUnavailable =>
      'Vreme za vašu lokaciju trenutno nije dostupno.';

  @override
  String get weatherWind => 'Vetar';

  @override
  String get summaryOutdoor => 'Napolju';

  @override
  String get presetNone => 'Bez režima';

  @override
  String get presetHome => 'Kod kuće';

  @override
  String get presetAway => 'Odsutni';

  @override
  String get presetSleep => 'Spavanje';

  @override
  String get presetEco => 'Eco';

  @override
  String get presetComfort => 'Udobno';

  @override
  String get presetBoost => 'Pojačano';

  @override
  String get presetActivity => 'Aktivnost';

  @override
  String get kioskShortcuts => 'Prečice';

  @override
  String get kioskShortcutsEmpty =>
      'Označite uređaje zvezdicom da se pojave ovde.';

  @override
  String kioskLightsOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count svetala upaljeno',
      few: '$count svetla upaljena',
      one: '$count svetlo upaljeno',
      zero: 'Sva svetla ugašena',
    );
    return '$_temp0';
  }

  @override
  String get kioskClimate => 'Klima';

  @override
  String kioskAverage(String value) {
    return 'Prosečno $value';
  }

  @override
  String kioskOpenings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Otvoreno: $count',
      zero: 'Sve zatvoreno',
    );
    return '$_temp0';
  }

  @override
  String get kioskDoorsWindows => 'Vrata i prozori';

  @override
  String get kioskPower => 'Trenutna snaga';

  @override
  String get kioskBackground => 'Pozadina';

  @override
  String get kioskBackgroundAurora => 'Polarna svetlost';

  @override
  String get kioskBackgroundOcean => 'Okean';

  @override
  String get kioskBackgroundDusk => 'Sumrak';

  @override
  String get kioskBackgroundForest => 'Šuma';

  @override
  String get kioskLiteEffects => 'Lakši efekti';

  @override
  String get kioskLiteEffectsHint =>
      'Bez zamućenja stakla, za slabije tablete.';

  @override
  String get thermostatModes => 'Režimi';

  @override
  String get powerToggle => 'Uključi/isključi';

  @override
  String get personHome => 'Kod kuće';

  @override
  String get personAway => 'Nije kod kuće';

  @override
  String get householdTitle => 'Ukućani';

  @override
  String get kioskStatusEntities => 'Statusi na vrhu ekrana';

  @override
  String kioskStatusEntitiesHint(int max) {
    return 'Izaberite do $max uređaja ili senzora koji se prikazuju na vrhu kiosk ekrana, na primer veš mašinu, štampač ili senzor spavanja.';
  }

  @override
  String get kioskStatusNone => 'Nijedan';

  @override
  String kioskStatusSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count izabranih',
      few: '$count izabrana',
      one: '$count izabran',
    );
    return '$_temp0';
  }

  @override
  String get searchHint => 'Pretraži';

  @override
  String get done => 'Gotovo';

  @override
  String get timeJustNow => 'upravo';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pre $count minuta',
      few: 'pre $count minuta',
      one: 'pre $count minut',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pre $count sati',
      few: 'pre $count sata',
      one: 'pre $count sat',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'pre $count dana',
      few: 'pre $count dana',
      one: 'pre $count dan',
    );
    return '$_temp0';
  }

  @override
  String get weatherForecastTitle => 'Vremenska prognoza';

  @override
  String get weatherHourly => 'Narednih sati';

  @override
  String get weatherDaily => 'Narednih dana';

  @override
  String get weatherToday => 'Danas';

  @override
  String get weatherNow => 'Sada';

  @override
  String get weatherNoForecast =>
      'Vaš Home Assistant entitet za vreme ne daje prognozu.';

  @override
  String get weatherPrecipitation => 'Padavine';

  @override
  String get weatherFeelsHint =>
      'Iz vašeg Home Assistant entiteta za vreme. Ništa ne napušta vašu mrežu.';

  @override
  String get camerasTitle => 'Kamere';

  @override
  String get cameraUnavailable => 'Kamera trenutno ne šalje sliku.';

  @override
  String cameraSnapshotAt(String time) {
    return 'Snimak $time';
  }

  @override
  String cameraRefreshHint(int seconds) {
    return 'Slika se osvežava svake $seconds s dok je ovaj ekran otvoren. Ništa se ne snima niti čuva.';
  }

  @override
  String get cameraFullscreen => 'Ceo ekran';

  @override
  String get cameraLoading => 'Učitavam kameru…';

  @override
  String get kioskShowCameras => 'Prikaži kamere';

  @override
  String get kioskShowCamerasHint =>
      'Sliku kamera vidi svako ko gleda u zidni tablet.';

  @override
  String get calendarTitle => 'Kalendar';

  @override
  String get calendarToday => 'Danas';

  @override
  String get calendarTomorrow => 'Sutra';

  @override
  String get calendarAllDay => 'Ceo dan';

  @override
  String get calendarNoEvents => 'Nema događaja';

  @override
  String get calendarNone =>
      'U Home Assistantu nema kalendara. Dodajte ga tamo, na primer Google Calendar, CalDAV ili integraciju Local Calendar.';

  @override
  String get calendarUnavailable => 'Kalendar trenutno nije dostupan.';

  @override
  String get calendarPrevMonth => 'Prethodni mesec';

  @override
  String get calendarNextMonth => 'Sledeći mesec';

  @override
  String get calendarBackToToday => 'Danas';

  @override
  String get kioskShowCalendar => 'Prikaži kalendar';

  @override
  String get kioskShowCalendarHint =>
      'Događaje vidi svako ko gleda u zidni tablet.';

  @override
  String get assistTitle => 'Assist';

  @override
  String get assistHint => 'Napišite komandu ili pitanje';

  @override
  String get assistSend => 'Pošalji';

  @override
  String get assistIntro =>
      'Zamolite Home Assistant da nešto uradi, na primer:';

  @override
  String get assistSuggestionLightsOff => 'Ugasi svetla';

  @override
  String get assistSuggestionTemperature =>
      'Kolika je temperatura u dnevnoj sobi?';

  @override
  String get assistSuggestionLightsOn => 'Upali svetla';

  @override
  String get assistUnavailable => 'Assist trenutno nije dostupan.';

  @override
  String get assistNotUnderstood => 'Assist to nije mogao da uradi.';

  @override
  String get assistPrivacy =>
      'Tekst ide samo na vaš Home Assistant server. Assist razume jezike koji su tamo podešeni i radi sa ovlašćenjima vašeg naloga.';

  @override
  String get mediaPlayPause => 'Pusti ili pauziraj';

  @override
  String get mediaNext => 'Sledeća';

  @override
  String get mediaPrevious => 'Prethodna';

  @override
  String get mediaNowPlaying => 'Sada svira';

  @override
  String get addDeviceTitle => 'Dodaj uređaj';

  @override
  String get addDeviceIntro =>
      'Novi uređaji se uparuju sa vašim Home Assistant hubom, koji ima Zigbee ili Z-Wave radio, a ne sa ovim telefonom. Aplikacija vas vodi kroz postupak.';

  @override
  String get addDeviceZigbee => 'Zigbee';

  @override
  String get addDeviceZigbeeSubtitle =>
      'Senzori, sijalice, utičnice, prekidači';

  @override
  String get addDeviceWifi => 'Wi-Fi i LAN';

  @override
  String get addDeviceMatter => 'Matter';

  @override
  String get addDeviceZwave => 'Z-Wave';

  @override
  String get addDeviceSoon => 'Uskoro';

  @override
  String get zigbeeViaZha => 'Preko ZHA';

  @override
  String get zigbeeViaZ2m => 'Preko Zigbee2MQTT';

  @override
  String get zigbeeNotFound =>
      'U Home Assistantu nije pronađen ni ZHA ni Zigbee2MQTT. Prvo tamo dodajte Zigbee koordinator.';

  @override
  String get zigbeeStep1 => 'Pokrenite uparivanje dugmetom ispod.';

  @override
  String get zigbeeStep2 =>
      'Resetujte uređaj ili ga stavite u režim uparivanja. Obično držite njegovo dugme oko 5 sekundi dok ne zatrepće; pogledajte uputstvo uređaja.';

  @override
  String get zigbeeStep3 =>
      'Držite uređaj blizu huba dok se ne pojavi na listi.';

  @override
  String get pairingStart => 'Pokreni uparivanje';

  @override
  String get pairingStop => 'Zaustavi';

  @override
  String get pairingExtend => 'Produži';

  @override
  String get pairingOpen => 'Uparivanje je uključeno';

  @override
  String pairingRemaining(String time) {
    return 'Još $time';
  }

  @override
  String get pairingClosed => 'Uparivanje je isključeno';

  @override
  String get pairingWaiting => 'Čekam nove uređaje…';

  @override
  String get pairingFound => 'Novi uređaji';

  @override
  String pairingFailed(String reason) {
    return 'Uparivanje nije pokrenuto. $reason';
  }

  @override
  String get newDeviceSetUp => 'Podesi';

  @override
  String get setUpDeviceTitle => 'Ime i prostorija';

  @override
  String get deviceNameLabel => 'Ime';

  @override
  String get deviceRoomLabel => 'Prostorija';

  @override
  String get setUpSaved => 'Sačuvano.';

  @override
  String get setUpFailed =>
      'Ime i prostorija ne mogu da se promene odavde. Uradite to u Home Assistantu, u Podešavanja → Uređaji.';

  @override
  String get weatherHomeLocationTitle => 'Prognoza za vaš dom';

  @override
  String get weatherHomeLocationHint =>
      'Home Assistant nema entitet za vreme. Dodajte integraciju Met.no u Home Assistantu ili uključite prognozu u aplikaciji.';

  @override
  String get weatherHomeLocationEnable => 'Uključi prognozu';

  @override
  String get weatherHomeLocationDisclosure =>
      'Aplikacija će slati približnu lokaciju doma iz Home Assistanta, zaokruženu na oko 1 km, servisu MET Norway (api.met.no) svakih 30 minuta. Ništa drugo se ne šalje. Možete je isključiti u Podešavanjima.';

  @override
  String get weatherHomeLocationSetting =>
      'Prognoza za lokaciju doma (MET Norway)';

  @override
  String get weatherHomeLocationSettingHint =>
      'Samo kad Home Assistant nema entitet za vreme. Šalje približnu lokaciju doma.';

  @override
  String get weatherNoHomeCoordinates =>
      'U Home Assistantu nije podešena lokacija doma.';

  @override
  String get kioskWeatherMissing =>
      'Nema vremenske prognoze. Uključite je u Podešavanjima → Privatnost ili dodajte integraciju Met.no u Home Assistantu.';

  @override
  String get calendarNoneShort => 'U Home Assistantu nema kalendara';

  @override
  String get mediaTitle => 'Muzika i mediji';

  @override
  String get mediaNoPlayers =>
      'U Home Assistantu još nema media plejera. Dodajte ga tamo, na primer Spotify, Google Cast, Sonos, DLNA, Kodi ili integraciju vašeg smart TV-a, i pojaviće se ovde.';

  @override
  String get mediaSource => 'Izvor';

  @override
  String get mediaIdle => 'Ništa ne svira';

  @override
  String weatherHomeLocationFar(int km) {
    return 'Lokacija doma u Home Assistantu je oko $km km od ovog uređaja. Ako to nije tačno, podesite je u Home Assistantu (Podešavanja → Sistem → Opšte); prognoza za dom koristi tu lokaciju.';
  }

  @override
  String get mediaNoPlayersShort => 'Još nema media plejera';

  @override
  String get assistMic => 'Izgovorite komandu';

  @override
  String get assistListening => 'Slušam…';

  @override
  String get voicePrivacyTitle => 'Glasovne komande';

  @override
  String get voicePrivacyBody =>
      'Prepoznavač govora na telefonu pretvara govor u tekst; vašem Home Assistantu ide samo tekst. Neki telefoni prepoznaju govor samo preko interneta (na primer Google ili Apple servis), koji tada dobija snimak vašeg glasa.';

  @override
  String get voiceOnDeviceOnly => 'Samo na uređaju';

  @override
  String get voiceAllowCloud => 'Dozvoli i preko interneta';

  @override
  String get voiceUnavailable =>
      'Prepoznavanje govora nije dostupno. Proverite dozvolu za mikrofon.';

  @override
  String get voiceOnDeviceUnavailable =>
      'Ovaj uređaj ne može da prepozna ovaj jezik bez interneta. Prepoznavanje preko interneta možete dozvoliti u Podešavanjima.';

  @override
  String get voiceNoMatch => 'Nisam razumeo. Pokušajte ponovo.';

  @override
  String get voiceCloudSetting => 'Prepoznavanje govora preko interneta';

  @override
  String get voiceCloudSettingHint =>
      'Kad je isključeno, glasovne komande se prepoznaju samo na uređaju.';

  @override
  String get addDeviceWifiSubtitle =>
      'Uređaji koje je Home Assistant pronašao na mreži';

  @override
  String get discoveredTitle => 'Pronađeno na mreži';

  @override
  String get discoveredEmpty =>
      'Home Assistant nije pronašao nove uređaje. Povežite uređaj na istu Wi-Fi mrežu i sačekajte minut; uređaji koje HA ne može sam da pronađe dodaju se u Home Assistantu, u Podešavanja → Uređaji.';

  @override
  String discoveredVia(String source) {
    return 'Pronađeno preko: $source';
  }

  @override
  String get discoveredRefresh => 'Traži ponovo';

  @override
  String get discoveredUnavailable =>
      'Lista pronađenih uređaja nije dostupna. Za to je obično potreban administratorski nalog u Home Assistantu.';

  @override
  String get flowAdd => 'Dodaj';

  @override
  String get flowNext => 'Dalje';

  @override
  String flowConfirm(String name) {
    return 'Dodati $name u vaš dom?';
  }

  @override
  String flowDone(String title) {
    return 'Dodato: $title';
  }

  @override
  String get flowDoneDevices => 'Novi uređaji';

  @override
  String flowAborted(String reason) {
    return 'Podešavanje je prekinuto: $reason';
  }

  @override
  String get flowAbortedGeneric => 'Home Assistant je prekinuo podešavanje.';

  @override
  String get flowUnsupported =>
      'Ovaj korak zahteva sam Home Assistant (na primer prijavu u pregledaču). Nastavite tamo.';

  @override
  String get flowUnsupportedField =>
      'Ovaj formular ima polja koja aplikacija još ne prikazuje. Nastavite u Home Assistantu.';

  @override
  String get flowWorking => 'Podešavam…';

  @override
  String get flowRequired => 'Obavezno';

  @override
  String get flowFinish => 'Gotovo';

  @override
  String get matterTitle => 'Matter';

  @override
  String get matterIntro =>
      'Dodajte Matter uređaj koji već radi sa nekom drugom aplikacijom (Google Home, Apple Home, SmartThings, Alexa…).';

  @override
  String get matterStep1 =>
      'U toj aplikaciji otvorite uređaj i izaberite da ga podelite sa drugom aplikacijom ili kontrolerom („Povezane Matter aplikacije”, „Uključi režim uparivanja”).';

  @override
  String get matterStep2 =>
      'Skenirajte QR kod koji se prikaže ili unesite 11-cifreni kod.';

  @override
  String get matterStep3 =>
      'Home Assistant tada dodaje uređaj preko vaše mreže; obe aplikacije mogu da ga kontrolišu.';

  @override
  String get matterNewDeviceNote =>
      'Potpuno novi Matter uređaji koji se uparuju preko Bluetooth-a za sada zahtevaju Home Assistant Companion aplikaciju.';

  @override
  String get matterCodeLabel => 'Kod za uparivanje';

  @override
  String get matterCodeHint => '1234-567-8901 ili MT:…';

  @override
  String get matterInvalidCode =>
      'To nije ispravan Matter kod. Proverite cifre.';

  @override
  String get matterScan => 'Skeniraj QR kod';

  @override
  String get matterAdding => 'Dodajem uređaj… može potrajati do minut.';

  @override
  String get matterNotAvailable =>
      'Matter integracija nije podešena u Home Assistantu. Prvo je dodajte tamo.';

  @override
  String get matterFailed =>
      'Uređaj nije dodat. Proverite da je deljenje i dalje uključeno u drugoj aplikaciji (kod važi nekoliko minuta) i da je uređaj na istoj mreži.';

  @override
  String get matterAdded => 'Uređaj je dodat';

  @override
  String get scanPointCamera => 'Usmerite kameru na Matter QR kod.';

  @override
  String get zwaveTitle => 'Z-Wave';

  @override
  String get zwaveIntro =>
      'Dodajte Z-Wave uređaj preko vašeg Z-Wave JS kontrolera.';

  @override
  String get zwaveNotAvailable =>
      'Z-Wave JS integracija nije podešena u Home Assistantu.';

  @override
  String get zwaveStart => 'Pokreni uključivanje';

  @override
  String get zwaveStop => 'Zaustavi';

  @override
  String get zwaveStatusWaiting =>
      'Stavite uređaj u režim uključivanja (često tri brza pritiska dugmeta; pogledajte uputstvo).';

  @override
  String get zwaveStatusFound => 'Uređaj je pronađen…';

  @override
  String get zwaveStatusInterview =>
      'Upoznajem uređaj (intervju)… uređajima na bateriju može trebati nekoliko minuta.';

  @override
  String get zwaveStatusDone => 'Uređaj je dodat';

  @override
  String get zwaveStatusFailed =>
      'Uključivanje nije uspelo. Pokušajte ponovo, bliže kontroleru.';

  @override
  String get zwaveStatusStopped => 'Uključivanje je zaustavljeno.';

  @override
  String get zwaveGrantTitle => 'Bezbednost';

  @override
  String get zwaveGrantBody =>
      'Uređaj traži ove nivoe bezbednosti. Preporučeno je dozvoliti sve.';

  @override
  String get zwaveS2Unauth => 'S2 bez autentifikacije';

  @override
  String get zwaveS2Auth => 'S2 sa autentifikacijom';

  @override
  String get zwaveS2Access => 'S2 kontrola pristupa (brave, garažna vrata)';

  @override
  String get zwaveS0 => 'S0 (stari način)';

  @override
  String get zwaveGrant => 'Dozvoli';

  @override
  String get zwavePinTitle => 'PIN sa uređaja';

  @override
  String zwavePinBody(String dsk) {
    return 'Unesite prvih 5 cifara DSK koda sa nalepnice uređaja ili kutije (obično podvučene). Ostatak koda: $dsk';
  }

  @override
  String get zwavePinLabel => '5 cifara';

  @override
  String get zwavePinInvalid => 'Unesite tačno 5 cifara.';

  @override
  String get zwaveSmartStart => 'SmartStart: skeniraj QR';

  @override
  String get zwaveSmartStartHint =>
      'Uređaji sa SmartStart QR kodom se sami pridruže kad ih uključite.';

  @override
  String get zwaveSmartStartDone =>
      'Uređaj je prijavljen. Uključite ga; pridružiće se sam za nekoliko minuta.';

  @override
  String get zwaveSmartStartInvalid => 'To nije Z-Wave QR kod.';

  @override
  String get scanPointCameraZwave => 'Usmerite kameru na Z-Wave QR kod.';

  @override
  String get historyTitle => 'Istorija';

  @override
  String get history24h => '24 h';

  @override
  String get history7d => '7 dana';

  @override
  String historyMin(String value) {
    return 'Min $value';
  }

  @override
  String historyMax(String value) {
    return 'Maks $value';
  }

  @override
  String get historyEmpty => 'Nema podataka za ovaj period.';

  @override
  String get historyUnavailable =>
      'Istorija nije dostupna. Moguće je da je snimanje (recorder) isključeno u Home Assistantu.';

  @override
  String get activityTitle => 'Aktivnost';

  @override
  String get activityByUser => 'ručno';

  @override
  String get activityEmpty => 'U poslednja 24 sata nije bilo promena.';
}

/// The translations for Serbian, using the Latin script (`sr_Latn`).
class AppLocalizationsSrLatn extends AppLocalizationsSr {
  AppLocalizationsSrLatn() : super('sr_Latn');
}
