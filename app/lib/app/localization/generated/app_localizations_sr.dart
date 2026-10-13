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
  String get liveEventsTitle => 'Promene stanja uživo';

  @override
  String get liveEventsEmpty => 'Čekam promene sa Home Assistanta…';

  @override
  String get homeComingSoon =>
      'Prostorije, uređaji i omiljeno stižu u sledećoj fazi razvoja.';

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
      'U pregledaču se token čuva samo dok je ova kartica otvorena. Zatvaranjem kartice se odjavljujete.';

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
    return 'Van mreže — prikazani su podaci poslednji put ažurirani u $time. Možda nisu aktuelni.';
  }
}

/// The translations for Serbian, using the Latin script (`sr_Latn`).
class AppLocalizationsSrLatn extends AppLocalizationsSr {
  AppLocalizationsSrLatn() : super('sr_Latn');
}
