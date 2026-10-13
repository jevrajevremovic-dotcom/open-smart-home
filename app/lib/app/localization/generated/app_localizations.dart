import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sr'),
    Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Open Smart Home'**
  String get appTitle;

  /// No description provided for @mockModeBanner.
  ///
  /// In en, this message translates to:
  /// **'MOCK MODE — demo data, no real devices'**
  String get mockModeBanner;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your home, in one app'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Control lights, climate, sensors and scenes from every brand and protocol your Home Assistant server supports.'**
  String get welcomeBody;

  /// No description provided for @welcomeLocalFirst.
  ///
  /// In en, this message translates to:
  /// **'Works locally. No cloud account required.'**
  String get welcomeLocalFirst;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get chooseLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageSerbian.
  ///
  /// In en, this message translates to:
  /// **'Srpski'**
  String get languageSerbian;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @serverAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to Home Assistant'**
  String get serverAddressTitle;

  /// No description provided for @serverAddressIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter the address of your Home Assistant server, for example the one you open in a browser at home.'**
  String get serverAddressIntro;

  /// No description provided for @serverAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get serverAddressLabel;

  /// No description provided for @serverAddressHint.
  ///
  /// In en, this message translates to:
  /// **'homeassistant.local:8123'**
  String get serverAddressHint;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Check connection'**
  String get checkConnection;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checking;

  /// No description provided for @serverReachable.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant found at {address}'**
  String serverReachable(String address);

  /// No description provided for @addressErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a server address.'**
  String get addressErrorEmpty;

  /// No description provided for @addressErrorMalformed.
  ///
  /// In en, this message translates to:
  /// **'This is not a valid address.'**
  String get addressErrorMalformed;

  /// No description provided for @addressErrorUnsupportedScheme.
  ///
  /// In en, this message translates to:
  /// **'Only http:// and https:// addresses are supported.'**
  String get addressErrorUnsupportedScheme;

  /// No description provided for @addressErrorMissingHost.
  ///
  /// In en, this message translates to:
  /// **'The address is missing a host name or IP address.'**
  String get addressErrorMissingHost;

  /// No description provided for @addressErrorCredentials.
  ///
  /// In en, this message translates to:
  /// **'Do not put a user name or password in the address.'**
  String get addressErrorCredentials;

  /// No description provided for @addressErrorPath.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant must be served from the root of the address (no path such as /ha).'**
  String get addressErrorPath;

  /// No description provided for @addressErrorQuery.
  ///
  /// In en, this message translates to:
  /// **'Remove the part after ? or # from the address.'**
  String get addressErrorQuery;

  /// No description provided for @addressErrorPort.
  ///
  /// In en, this message translates to:
  /// **'The port must be between 1 and 65535.'**
  String get addressErrorPort;

  /// No description provided for @riskLocalHttp.
  ///
  /// In en, this message translates to:
  /// **'Unencrypted connection inside your local network.'**
  String get riskLocalHttp;

  /// No description provided for @riskRemoteExposure.
  ///
  /// In en, this message translates to:
  /// **'This is a public address. Make sure your server is kept up to date and protected.'**
  String get riskRemoteExposure;

  /// No description provided for @riskInsecureRemote.
  ///
  /// In en, this message translates to:
  /// **'Warning: this public address uses unencrypted HTTP. Your access token could be intercepted. Use HTTPS unless the connection runs through a VPN.'**
  String get riskInsecureRemote;

  /// No description provided for @insecureAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I understand the risk (e.g. I use a VPN)'**
  String get insecureAcknowledge;

  /// No description provided for @certificateUntrustedTitle.
  ///
  /// In en, this message translates to:
  /// **'Untrusted certificate'**
  String get certificateUntrustedTitle;

  /// No description provided for @certificateUntrustedBody.
  ///
  /// In en, this message translates to:
  /// **'The server\'s certificate is not trusted by this device. This is normal for a self-signed certificate, but can also mean someone is intercepting the connection. Only continue if the fingerprint matches the one shown on your server.'**
  String get certificateUntrustedBody;

  /// No description provided for @certificateSubject.
  ///
  /// In en, this message translates to:
  /// **'Issued to'**
  String get certificateSubject;

  /// No description provided for @certificateIssuer.
  ///
  /// In en, this message translates to:
  /// **'Issued by'**
  String get certificateIssuer;

  /// No description provided for @certificateValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until'**
  String get certificateValidUntil;

  /// No description provided for @certificateFingerprint.
  ///
  /// In en, this message translates to:
  /// **'SHA-256 fingerprint'**
  String get certificateFingerprint;

  /// No description provided for @certificateExpired.
  ///
  /// In en, this message translates to:
  /// **'This certificate has expired.'**
  String get certificateExpired;

  /// No description provided for @certificateConfirm.
  ///
  /// In en, this message translates to:
  /// **'I compared the fingerprint and trust this certificate'**
  String get certificateConfirm;

  /// No description provided for @trustCertificate.
  ///
  /// In en, this message translates to:
  /// **'Trust this certificate'**
  String get trustCertificate;

  /// No description provided for @tokenTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get tokenTitle;

  /// No description provided for @tokenIntro.
  ///
  /// In en, this message translates to:
  /// **'The app signs in with a long-lived access token from your Home Assistant user profile.'**
  String get tokenIntro;

  /// No description provided for @tokenSteps.
  ///
  /// In en, this message translates to:
  /// **'1. Open Home Assistant in a browser.\n2. Click your user name (bottom left) → Security.\n3. Under “Long-lived access tokens” choose “Create token”.\n4. Copy the token and paste it below. Home Assistant shows it only once.'**
  String get tokenSteps;

  /// No description provided for @tokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Access token'**
  String get tokenLabel;

  /// No description provided for @tokenMockHint.
  ///
  /// In en, this message translates to:
  /// **'Mock mode: any token works; “invalid” simulates a rejected token.'**
  String get tokenMockHint;

  /// No description provided for @showToken.
  ///
  /// In en, this message translates to:
  /// **'Show token'**
  String get showToken;

  /// No description provided for @hideToken.
  ///
  /// In en, this message translates to:
  /// **'Hide token'**
  String get hideToken;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @tokenInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'The token must not be empty or contain spaces.'**
  String get tokenInvalidFormat;

  /// No description provided for @failureNetwork.
  ///
  /// In en, this message translates to:
  /// **'The server cannot be reached. Check the address and that this device is on the right network.'**
  String get failureNetwork;

  /// No description provided for @failureTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server took too long to respond.'**
  String get failureTimeout;

  /// No description provided for @failureAuthentication.
  ///
  /// In en, this message translates to:
  /// **'The access token was rejected. It may be wrong, expired or revoked.'**
  String get failureAuthentication;

  /// No description provided for @failureAuthorization.
  ///
  /// In en, this message translates to:
  /// **'This user is not allowed to perform this action.'**
  String get failureAuthorization;

  /// No description provided for @failureValidation.
  ///
  /// In en, this message translates to:
  /// **'The request was not accepted by the server.'**
  String get failureValidation;

  /// No description provided for @failureParsing.
  ///
  /// In en, this message translates to:
  /// **'The server sent an unexpected response.'**
  String get failureParsing;

  /// No description provided for @failureServer.
  ///
  /// In en, this message translates to:
  /// **'The server responded, but not like Home Assistant, or reported an error.'**
  String get failureServer;

  /// No description provided for @failureCertificate.
  ///
  /// In en, this message translates to:
  /// **'The secure connection could not be verified (certificate problem).'**
  String get failureCertificate;

  /// No description provided for @failureUnavailableEntity.
  ///
  /// In en, this message translates to:
  /// **'This device is currently unavailable.'**
  String get failureUnavailableEntity;

  /// No description provided for @failureUnsupportedFeature.
  ///
  /// In en, this message translates to:
  /// **'This device does not support this action.'**
  String get failureUnsupportedFeature;

  /// No description provided for @failureWebSocket.
  ///
  /// In en, this message translates to:
  /// **'The live connection was interrupted.'**
  String get failureWebSocket;

  /// No description provided for @failureStorage.
  ///
  /// In en, this message translates to:
  /// **'Secure storage on this device could not be accessed.'**
  String get failureStorage;

  /// No description provided for @failureUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get failureUnknown;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @statusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get statusConnected;

  /// No description provided for @statusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get statusConnecting;

  /// No description provided for @statusAuthenticating.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get statusAuthenticating;

  /// No description provided for @statusReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get statusReconnecting;

  /// No description provided for @statusReconnectingIn.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting in {seconds} s'**
  String statusReconnectingIn(int seconds);

  /// No description provided for @statusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get statusDisconnected;

  /// No description provided for @statusAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in rejected'**
  String get statusAuthFailed;

  /// No description provided for @statusServerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Server unavailable'**
  String get statusServerUnavailable;

  /// No description provided for @statusError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get statusError;

  /// No description provided for @retryNow.
  ///
  /// In en, this message translates to:
  /// **'Retry now'**
  String get retryNow;

  /// No description provided for @signInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get signInAgain;

  /// No description provided for @serverVersion.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant {version}'**
  String serverVersion(String version);

  /// No description provided for @liveEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Live state changes'**
  String get liveEventsTitle;

  /// No description provided for @liveEventsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Waiting for changes from Home Assistant…'**
  String get liveEventsEmpty;

  /// No description provided for @homeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Rooms, devices and favorites arrive in the next development phase.'**
  String get homeComingSoon;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @serverSection.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get serverSection;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The access token will be deleted from this device. You can sign in again at any time.'**
  String get signOutConfirmBody;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete all local data'**
  String get deleteAllData;

  /// No description provided for @deleteAllConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all local data?'**
  String get deleteAllConfirmTitle;

  /// No description provided for @deleteAllConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the access token, server address and all settings from this device. Nothing is changed on your Home Assistant server.'**
  String get deleteAllConfirmBody;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @privacySection.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get privacySection;

  /// No description provided for @addressErrorMixedContent.
  ///
  /// In en, this message translates to:
  /// **'This page is loaded over HTTPS, so the browser blocks connections to an http:// server. Use the server\'s https:// address, or open this web app from the same address as Home Assistant.'**
  String get addressErrorMixedContent;

  /// No description provided for @webConnectionHint.
  ///
  /// In en, this message translates to:
  /// **'In a browser this can also mean that Home Assistant does not allow this web app\'s address (add it to http: cors_allowed_origins in configuration.yaml), or that the browser does not trust the server\'s certificate (open the server address in a new tab once and accept it there).'**
  String get webConnectionHint;

  /// No description provided for @webSessionNotice.
  ///
  /// In en, this message translates to:
  /// **'In the browser the token is kept only while this tab is open. Closing the tab signs you out.'**
  String get webSessionNotice;

  /// No description provided for @failureConfirmationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm this action.'**
  String get failureConfirmationRequired;

  /// No description provided for @devicesInRooms.
  ///
  /// In en, this message translates to:
  /// **'{devices, plural, =1{1 device} other{{devices} devices}} in {rooms, plural, =0{no rooms} =1{1 room} other{{rooms} rooms}}'**
  String devicesInRooms(int devices, int rooms);

  /// No description provided for @dataStaleSince.
  ///
  /// In en, this message translates to:
  /// **'Offline — showing data last updated at {time}. It may not be current.'**
  String dataStaleSince(String time);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'sr':
      {
        switch (locale.scriptCode) {
          case 'Latn':
            return AppLocalizationsSrLatn();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sr':
      return AppLocalizationsSr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
