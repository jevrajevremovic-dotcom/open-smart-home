// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Open Smart Home';

  @override
  String get mockModeBanner => 'MOCK MODE — demo data, no real devices';

  @override
  String get welcomeTitle => 'Your home, in one app';

  @override
  String get welcomeBody =>
      'Control lights, climate, sensors and scenes from every brand and protocol your Home Assistant server supports.';

  @override
  String get welcomeLocalFirst => 'Works locally. No cloud account required.';

  @override
  String get chooseLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageSerbian => 'Srpski';

  @override
  String get languageEnglish => 'English';

  @override
  String get getStarted => 'Get started';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get continueAction => 'Continue';

  @override
  String get serverAddressTitle => 'Connect to Home Assistant';

  @override
  String get serverAddressIntro =>
      'Enter the address of your Home Assistant server, for example the one you open in a browser at home.';

  @override
  String get serverAddressLabel => 'Server address';

  @override
  String get serverAddressHint => 'homeassistant.local:8123';

  @override
  String get checkConnection => 'Check connection';

  @override
  String get checking => 'Checking…';

  @override
  String serverReachable(String address) {
    return 'Home Assistant found at $address';
  }

  @override
  String get addressErrorEmpty => 'Enter a server address.';

  @override
  String get addressErrorMalformed => 'This is not a valid address.';

  @override
  String get addressErrorUnsupportedScheme =>
      'Only http:// and https:// addresses are supported.';

  @override
  String get addressErrorMissingHost =>
      'The address is missing a host name or IP address.';

  @override
  String get addressErrorCredentials =>
      'Do not put a user name or password in the address.';

  @override
  String get addressErrorPath =>
      'Home Assistant must be served from the root of the address (no path such as /ha).';

  @override
  String get addressErrorQuery =>
      'Remove the part after ? or # from the address.';

  @override
  String get addressErrorPort => 'The port must be between 1 and 65535.';

  @override
  String get riskLocalHttp =>
      'Unencrypted connection inside your local network.';

  @override
  String get riskRemoteExposure =>
      'This is a public address. Make sure your server is kept up to date and protected.';

  @override
  String get riskInsecureRemote =>
      'Warning: this public address uses unencrypted HTTP. Your access token could be intercepted. Use HTTPS unless the connection runs through a VPN.';

  @override
  String get insecureAcknowledge => 'I understand the risk (e.g. I use a VPN)';

  @override
  String get certificateUntrustedTitle => 'Untrusted certificate';

  @override
  String get certificateUntrustedBody =>
      'The server\'s certificate is not trusted by this device. This is normal for a self-signed certificate, but can also mean someone is intercepting the connection. Only continue if the fingerprint matches the one shown on your server.';

  @override
  String get certificateSubject => 'Issued to';

  @override
  String get certificateIssuer => 'Issued by';

  @override
  String get certificateValidUntil => 'Valid until';

  @override
  String get certificateFingerprint => 'SHA-256 fingerprint';

  @override
  String get certificateExpired => 'This certificate has expired.';

  @override
  String get certificateConfirm =>
      'I compared the fingerprint and trust this certificate';

  @override
  String get trustCertificate => 'Trust this certificate';

  @override
  String get tokenTitle => 'Sign in';

  @override
  String get tokenIntro =>
      'The app signs in with a long-lived access token from your Home Assistant user profile.';

  @override
  String get tokenSteps =>
      '1. Open Home Assistant in a browser.\n2. Click your user name (bottom left) → Security.\n3. Under “Long-lived access tokens” choose “Create token”.\n4. Copy the token and paste it below. Home Assistant shows it only once.';

  @override
  String get tokenLabel => 'Access token';

  @override
  String get tokenMockHint =>
      'Mock mode: any token works; “invalid” simulates a rejected token.';

  @override
  String get showToken => 'Show token';

  @override
  String get hideToken => 'Hide token';

  @override
  String get connect => 'Connect';

  @override
  String get connecting => 'Connecting…';

  @override
  String get tokenInvalidFormat =>
      'The token must not be empty or contain spaces.';

  @override
  String get failureNetwork =>
      'The server cannot be reached. Check the address and that this device is on the right network.';

  @override
  String get failureTimeout => 'The server took too long to respond.';

  @override
  String get failureAuthentication =>
      'The access token was rejected. It may be wrong, expired or revoked.';

  @override
  String get failureAuthorization =>
      'This user is not allowed to perform this action.';

  @override
  String get failureValidation => 'The request was not accepted by the server.';

  @override
  String get failureParsing => 'The server sent an unexpected response.';

  @override
  String get failureServer =>
      'The server responded, but not like Home Assistant, or reported an error.';

  @override
  String get failureCertificate =>
      'The secure connection could not be verified (certificate problem).';

  @override
  String get failureUnavailableEntity =>
      'This device is currently unavailable.';

  @override
  String get failureUnsupportedFeature =>
      'This device does not support this action.';

  @override
  String get failureWebSocket => 'The live connection was interrupted.';

  @override
  String get failureStorage =>
      'Secure storage on this device could not be accessed.';

  @override
  String get failureUnknown => 'Something went wrong. Please try again.';

  @override
  String get navHome => 'Home';

  @override
  String get navSettings => 'Settings';

  @override
  String get statusConnected => 'Connected';

  @override
  String get statusConnecting => 'Connecting…';

  @override
  String get statusAuthenticating => 'Signing in…';

  @override
  String get statusReconnecting => 'Reconnecting…';

  @override
  String statusReconnectingIn(int seconds) {
    return 'Reconnecting in $seconds s';
  }

  @override
  String get statusDisconnected => 'Disconnected';

  @override
  String get statusAuthFailed => 'Sign-in rejected';

  @override
  String get statusServerUnavailable => 'Server unavailable';

  @override
  String get statusError => 'Connection error';

  @override
  String get retryNow => 'Retry now';

  @override
  String get signInAgain => 'Sign in again';

  @override
  String serverVersion(String version) {
    return 'Home Assistant $version';
  }

  @override
  String get liveEventsTitle => 'Live state changes';

  @override
  String get liveEventsEmpty => 'Waiting for changes from Home Assistant…';

  @override
  String get homeComingSoon =>
      'Rooms, devices and favorites arrive in the next development phase.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get serverSection => 'Server';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutConfirmBody =>
      'The access token will be deleted from this device. You can sign in again at any time.';

  @override
  String get deleteAllData => 'Delete all local data';

  @override
  String get deleteAllConfirmTitle => 'Delete all local data?';

  @override
  String get deleteAllConfirmBody =>
      'This removes the access token, server address and all settings from this device. Nothing is changed on your Home Assistant server.';

  @override
  String get delete => 'Delete';

  @override
  String get privacySection => 'Privacy & data';

  @override
  String get addressErrorMixedContent =>
      'This page is loaded over HTTPS, so the browser blocks connections to an http:// server. Use the server\'s https:// address, or open this web app from the same address as Home Assistant.';

  @override
  String get webConnectionHint =>
      'In a browser this can also mean that Home Assistant does not allow this web app\'s address (add it to http: cors_allowed_origins in configuration.yaml), or that the browser does not trust the server\'s certificate (open the server address in a new tab once and accept it there).';

  @override
  String get webSessionNotice =>
      'In the browser the token is kept only while this tab is open. Closing the tab signs you out.';

  @override
  String get failureConfirmationRequired => 'Please confirm this action.';

  @override
  String devicesInRooms(int devices, int rooms) {
    String _temp0 = intl.Intl.pluralLogic(
      devices,
      locale: localeName,
      other: '$devices devices',
      one: '1 device',
    );
    String _temp1 = intl.Intl.pluralLogic(
      rooms,
      locale: localeName,
      other: '$rooms rooms',
      one: '1 room',
      zero: 'no rooms',
    );
    return '$_temp0 in $_temp1';
  }

  @override
  String dataStaleSince(String time) {
    return 'Offline — showing data last updated at $time. It may not be current.';
  }
}
