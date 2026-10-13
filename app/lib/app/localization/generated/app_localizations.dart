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
  /// **'With a token, sign-in lasts only while this tab is open.'**
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
  /// **'Not connected — showing data last updated {time}. It may not be current.'**
  String dataStaleSince(String time);

  /// No description provided for @navRooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get navRooms;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @navScenes.
  ///
  /// In en, this message translates to:
  /// **'Scenes'**
  String get navScenes;

  /// No description provided for @stateOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get stateOn;

  /// No description provided for @stateOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get stateOff;

  /// No description provided for @stateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get stateUnavailable;

  /// No description provided for @stateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get stateUnknown;

  /// No description provided for @stateOnBrightness.
  ///
  /// In en, this message translates to:
  /// **'On · {percent} %'**
  String stateOnBrightness(int percent);

  /// No description provided for @motionDetected.
  ///
  /// In en, this message translates to:
  /// **'Motion detected'**
  String get motionDetected;

  /// No description provided for @motionClear.
  ///
  /// In en, this message translates to:
  /// **'No motion'**
  String get motionClear;

  /// No description provided for @occupancyDetected.
  ///
  /// In en, this message translates to:
  /// **'Occupied'**
  String get occupancyDetected;

  /// No description provided for @occupancyClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get occupancyClear;

  /// No description provided for @contactOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get contactOpen;

  /// No description provided for @contactClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get contactClosed;

  /// No description provided for @smokeDetected.
  ///
  /// In en, this message translates to:
  /// **'Smoke detected!'**
  String get smokeDetected;

  /// No description provided for @smokeClear.
  ///
  /// In en, this message translates to:
  /// **'No smoke'**
  String get smokeClear;

  /// No description provided for @coDetected.
  ///
  /// In en, this message translates to:
  /// **'CO detected!'**
  String get coDetected;

  /// No description provided for @coClear.
  ///
  /// In en, this message translates to:
  /// **'No CO'**
  String get coClear;

  /// No description provided for @leakDetected.
  ///
  /// In en, this message translates to:
  /// **'Water leak!'**
  String get leakDetected;

  /// No description provided for @leakClear.
  ///
  /// In en, this message translates to:
  /// **'Dry'**
  String get leakClear;

  /// No description provided for @vibrationDetected.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibrationDetected;

  /// No description provided for @vibrationClear.
  ///
  /// In en, this message translates to:
  /// **'Still'**
  String get vibrationClear;

  /// No description provided for @binaryActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get binaryActive;

  /// No description provided for @binaryInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get binaryInactive;

  /// No description provided for @coverOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening…'**
  String get coverOpening;

  /// No description provided for @coverClosing.
  ///
  /// In en, this message translates to:
  /// **'Closing…'**
  String get coverClosing;

  /// No description provided for @coverOpenPercent.
  ///
  /// In en, this message translates to:
  /// **'Open {percent} %'**
  String coverOpenPercent(int percent);

  /// No description provided for @lockLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lockLocked;

  /// No description provided for @lockUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get lockUnlocked;

  /// No description provided for @lockLocking.
  ///
  /// In en, this message translates to:
  /// **'Locking…'**
  String get lockLocking;

  /// No description provided for @lockUnlocking.
  ///
  /// In en, this message translates to:
  /// **'Unlocking…'**
  String get lockUnlocking;

  /// No description provided for @lockJammed.
  ///
  /// In en, this message translates to:
  /// **'Jammed!'**
  String get lockJammed;

  /// No description provided for @alarmDisarmed.
  ///
  /// In en, this message translates to:
  /// **'Disarmed'**
  String get alarmDisarmed;

  /// No description provided for @alarmArmed.
  ///
  /// In en, this message translates to:
  /// **'Armed'**
  String get alarmArmed;

  /// No description provided for @alarmArming.
  ///
  /// In en, this message translates to:
  /// **'Arming…'**
  String get alarmArming;

  /// No description provided for @alarmPending.
  ///
  /// In en, this message translates to:
  /// **'Pending…'**
  String get alarmPending;

  /// No description provided for @alarmTriggered.
  ///
  /// In en, this message translates to:
  /// **'ALARM!'**
  String get alarmTriggered;

  /// No description provided for @hvacOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get hvacOff;

  /// No description provided for @hvacHeat.
  ///
  /// In en, this message translates to:
  /// **'Heat'**
  String get hvacHeat;

  /// No description provided for @hvacCool.
  ///
  /// In en, this message translates to:
  /// **'Cool'**
  String get hvacCool;

  /// No description provided for @hvacHeatCool.
  ///
  /// In en, this message translates to:
  /// **'Heat/Cool'**
  String get hvacHeatCool;

  /// No description provided for @hvacAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get hvacAuto;

  /// No description provided for @hvacDry.
  ///
  /// In en, this message translates to:
  /// **'Dry'**
  String get hvacDry;

  /// No description provided for @hvacFanOnly.
  ///
  /// In en, this message translates to:
  /// **'Fan only'**
  String get hvacFanOnly;

  /// No description provided for @climateStatus.
  ///
  /// In en, this message translates to:
  /// **'{mode} · {temperature}'**
  String climateStatus(String mode, String temperature);

  /// No description provided for @mediaPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get mediaPlaying;

  /// No description provided for @mediaPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get mediaPaused;

  /// No description provided for @cameraIdle.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get cameraIdle;

  /// No description provided for @cameraStreaming.
  ///
  /// In en, this message translates to:
  /// **'Streaming'**
  String get cameraStreaming;

  /// No description provided for @cameraRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get cameraRecording;

  /// No description provided for @scriptRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get scriptRunning;

  /// No description provided for @routineReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get routineReady;

  /// No description provided for @doorbellLast.
  ///
  /// In en, this message translates to:
  /// **'Last ring {time}'**
  String doorbellLast(String time);

  /// No description provided for @lowBattery.
  ///
  /// In en, this message translates to:
  /// **'Low battery'**
  String get lowBattery;

  /// No description provided for @batteryLevel.
  ///
  /// In en, this message translates to:
  /// **'Battery {percent} %'**
  String batteryLevel(int percent);

  /// No description provided for @protocolCloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud'**
  String get protocolCloud;

  /// No description provided for @protocolVirtual.
  ///
  /// In en, this message translates to:
  /// **'Virtual'**
  String get protocolVirtual;

  /// No description provided for @favoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Tap the star on a device\'s page to add it to your favorites.'**
  String get favoritesEmpty;

  /// No description provided for @scenesTitle.
  ///
  /// In en, this message translates to:
  /// **'Scenes'**
  String get scenesTitle;

  /// No description provided for @scriptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Scripts'**
  String get scriptsTitle;

  /// No description provided for @automationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Automations'**
  String get automationsTitle;

  /// No description provided for @noScenes.
  ///
  /// In en, this message translates to:
  /// **'No scenes yet.'**
  String get noScenes;

  /// No description provided for @dashboardAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get dashboardAttention;

  /// No description provided for @summaryTemperature.
  ///
  /// In en, this message translates to:
  /// **'Indoor'**
  String get summaryTemperature;

  /// No description provided for @summaryHumidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get summaryHumidity;

  /// No description provided for @summaryLights.
  ///
  /// In en, this message translates to:
  /// **'Lights on'**
  String get summaryLights;

  /// No description provided for @summaryOpenings.
  ///
  /// In en, this message translates to:
  /// **'Doors & windows open'**
  String get summaryOpenings;

  /// No description provided for @summaryPower.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get summaryPower;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @greetingNight.
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get greetingNight;

  /// No description provided for @summaryAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get summaryAlerts;

  /// No description provided for @valueNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get valueNotAvailable;

  /// No description provided for @lightsOnOf.
  ///
  /// In en, this message translates to:
  /// **'{on} of {total}'**
  String lightsOnOf(int on, int total);

  /// No description provided for @lowBatteryCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 low battery} other{{count} low batteries}}'**
  String lowBatteryCount(int count);

  /// No description provided for @unavailableCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unavailable} other{{count} unavailable}}'**
  String unavailableCount(int count);

  /// No description provided for @roomNoRoom.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get roomNoRoom;

  /// No description provided for @allDevices.
  ///
  /// In en, this message translates to:
  /// **'All devices'**
  String get allDevices;

  /// No description provided for @roomDevicesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No devices} =1{1 device} other{{count} devices}}'**
  String roomDevicesCount(int count);

  /// No description provided for @roomLightsOn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 light on} other{{count} lights on}}'**
  String roomLightsOn(int count);

  /// No description provided for @roomEmpty.
  ///
  /// In en, this message translates to:
  /// **'No devices in this room.'**
  String get roomEmpty;

  /// No description provided for @noRoomsYet.
  ///
  /// In en, this message translates to:
  /// **'No rooms are defined in Home Assistant.'**
  String get noRoomsYet;

  /// No description provided for @groupLights.
  ///
  /// In en, this message translates to:
  /// **'Lights'**
  String get groupLights;

  /// No description provided for @groupClimate.
  ///
  /// In en, this message translates to:
  /// **'Climate'**
  String get groupClimate;

  /// No description provided for @groupCovers.
  ///
  /// In en, this message translates to:
  /// **'Blinds & doors'**
  String get groupCovers;

  /// No description provided for @groupSwitches.
  ///
  /// In en, this message translates to:
  /// **'Switches & outlets'**
  String get groupSwitches;

  /// No description provided for @groupSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get groupSecurity;

  /// No description provided for @groupSensors.
  ///
  /// In en, this message translates to:
  /// **'Sensors'**
  String get groupSensors;

  /// No description provided for @groupMedia.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get groupMedia;

  /// No description provided for @groupEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get groupEnergy;

  /// No description provided for @groupOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get groupOther;

  /// No description provided for @addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addFavorite;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFavorite;

  /// No description provided for @brightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get brightness;

  /// No description provided for @colorTemperature.
  ///
  /// In en, this message translates to:
  /// **'Color temperature'**
  String get colorTemperature;

  /// No description provided for @warm.
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get warm;

  /// No description provided for @cool.
  ///
  /// In en, this message translates to:
  /// **'Cool'**
  String get cool;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @targetTemperature.
  ///
  /// In en, this message translates to:
  /// **'Target temperature'**
  String get targetTemperature;

  /// No description provided for @currentTemperature.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentTemperature;

  /// No description provided for @increaseTemperature.
  ///
  /// In en, this message translates to:
  /// **'Increase temperature'**
  String get increaseTemperature;

  /// No description provided for @decreaseTemperature.
  ///
  /// In en, this message translates to:
  /// **'Decrease temperature'**
  String get decreaseTemperature;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// No description provided for @fanMode.
  ///
  /// In en, this message translates to:
  /// **'Fan'**
  String get fanMode;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @lock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lock;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @confirmUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock {name}?'**
  String confirmUnlockTitle(String name);

  /// No description provided for @confirmOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Open {name}?'**
  String confirmOpenTitle(String name);

  /// No description provided for @confirmDisarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Disarm {name}?'**
  String confirmDisarmTitle(String name);

  /// No description provided for @confirmCriticalBody.
  ///
  /// In en, this message translates to:
  /// **'This action affects the security of your home.'**
  String get confirmCriticalBody;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @runNow.
  ///
  /// In en, this message translates to:
  /// **'Run now'**
  String get runNow;

  /// No description provided for @sceneActivated.
  ///
  /// In en, this message translates to:
  /// **'{name} activated'**
  String sceneActivated(String name);

  /// No description provided for @automationEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get automationEnabled;

  /// No description provided for @lastTriggered.
  ///
  /// In en, this message translates to:
  /// **'Last triggered {time}'**
  String lastTriggered(String time);

  /// No description provided for @neverTriggered.
  ///
  /// In en, this message translates to:
  /// **'Never triggered'**
  String get neverTriggered;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @detailInfo.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get detailInfo;

  /// No description provided for @infoRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get infoRoom;

  /// No description provided for @infoManufacturer.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer'**
  String get infoManufacturer;

  /// No description provided for @infoModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get infoModel;

  /// No description provided for @infoProtocol.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get infoProtocol;

  /// No description provided for @infoLastChanged.
  ///
  /// In en, this message translates to:
  /// **'Last changed'**
  String get infoLastChanged;

  /// No description provided for @infoEntityId.
  ///
  /// In en, this message translates to:
  /// **'Entity ID'**
  String get infoEntityId;

  /// No description provided for @infoSignal.
  ///
  /// In en, this message translates to:
  /// **'Signal'**
  String get infoSignal;

  /// No description provided for @infoBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get infoBattery;

  /// No description provided for @deviceNotFound.
  ///
  /// In en, this message translates to:
  /// **'This device no longer exists.'**
  String get deviceNotFound;

  /// No description provided for @unavailableBanner.
  ///
  /// In en, this message translates to:
  /// **'This device is unavailable. Controls are disabled until it reconnects.'**
  String get unavailableBanner;

  /// No description provided for @controlsOffline.
  ///
  /// In en, this message translates to:
  /// **'Controls are available again once the connection is restored.'**
  String get controlsOffline;

  /// No description provided for @kioskSection.
  ///
  /// In en, this message translates to:
  /// **'Kiosk mode (wall tablet)'**
  String get kioskSection;

  /// No description provided for @kioskStart.
  ///
  /// In en, this message translates to:
  /// **'Start kiosk mode'**
  String get kioskStart;

  /// No description provided for @kioskStartOnLaunch.
  ///
  /// In en, this message translates to:
  /// **'Open in kiosk mode on launch'**
  String get kioskStartOnLaunch;

  /// No description provided for @kioskKeepAwake.
  ///
  /// In en, this message translates to:
  /// **'Keep screen on'**
  String get kioskKeepAwake;

  /// No description provided for @kioskDimAfter.
  ///
  /// In en, this message translates to:
  /// **'Dim screen after'**
  String get kioskDimAfter;

  /// No description provided for @kioskReturnAfter.
  ///
  /// In en, this message translates to:
  /// **'Return to dashboard after'**
  String get kioskReturnAfter;

  /// No description provided for @kioskPin.
  ///
  /// In en, this message translates to:
  /// **'Exit PIN'**
  String get kioskPin;

  /// No description provided for @kioskPinSet.
  ///
  /// In en, this message translates to:
  /// **'PIN is set'**
  String get kioskPinSet;

  /// No description provided for @kioskPinNotSet.
  ///
  /// In en, this message translates to:
  /// **'No PIN — anyone can leave kiosk mode'**
  String get kioskPinNotSet;

  /// No description provided for @kioskSetPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get kioskSetPin;

  /// No description provided for @kioskChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get kioskChangePin;

  /// No description provided for @kioskRemovePin.
  ///
  /// In en, this message translates to:
  /// **'Remove PIN'**
  String get kioskRemovePin;

  /// No description provided for @kioskPinHint.
  ///
  /// In en, this message translates to:
  /// **'4–8 digits'**
  String get kioskPinHint;

  /// No description provided for @kioskPinConfirm.
  ///
  /// In en, this message translates to:
  /// **'Repeat PIN'**
  String get kioskPinConfirm;

  /// No description provided for @kioskPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'The PINs do not match.'**
  String get kioskPinMismatch;

  /// No description provided for @kioskPinInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use 4–8 digits.'**
  String get kioskPinInvalid;

  /// No description provided for @kioskExit.
  ///
  /// In en, this message translates to:
  /// **'Exit kiosk mode'**
  String get kioskExit;

  /// No description provided for @kioskEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get kioskEnterPin;

  /// No description provided for @kioskWrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN.'**
  String get kioskWrongPin;

  /// No description provided for @kioskLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {seconds} s.'**
  String kioskLockedOut(int seconds);

  /// No description provided for @kioskTapToWake.
  ///
  /// In en, this message translates to:
  /// **'Tap to wake'**
  String get kioskTapToWake;

  /// No description provided for @kioskOsHint.
  ///
  /// In en, this message translates to:
  /// **'For a fully locked wall panel also use the system\'s kiosk feature: Android screen pinning or a kiosk launcher, iOS Guided Access. They can also start the app automatically.'**
  String get kioskOsHint;

  /// No description provided for @durationNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get durationNever;

  /// No description provided for @durationSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String durationSeconds(int seconds);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @dataUpdating.
  ///
  /// In en, this message translates to:
  /// **'Showing data from {time} — updating…'**
  String dataUpdating(String time);

  /// No description provided for @oauthSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Home Assistant'**
  String get oauthSignIn;

  /// No description provided for @oauthHint.
  ///
  /// In en, this message translates to:
  /// **'You sign in on your Home Assistant\'s own login page – this app never sees your password.'**
  String get oauthHint;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me on this device'**
  String get rememberMe;

  /// No description provided for @rememberMeHint.
  ///
  /// In en, this message translates to:
  /// **'Stay signed in after the browser is closed. You can revoke access anytime in your Home Assistant profile (Security → Refresh tokens).'**
  String get rememberMeHint;

  /// No description provided for @orUseToken.
  ///
  /// In en, this message translates to:
  /// **'Or use a long-lived access token'**
  String get orUseToken;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in did not complete. Please try again.'**
  String get loginFailed;

  /// No description provided for @discoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant on this network'**
  String get discoveryTitle;

  /// No description provided for @discoverySearching.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get discoverySearching;

  /// No description provided for @discoveryNothingFound.
  ///
  /// In en, this message translates to:
  /// **'No server found automatically. Enter the address below.'**
  String get discoveryNothingFound;

  /// No description provided for @discoverySearchAgain.
  ///
  /// In en, this message translates to:
  /// **'Search again'**
  String get discoverySearchAgain;

  /// No description provided for @energyTitle.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get energyTitle;

  /// No description provided for @energyToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get energyToday;

  /// No description provided for @energyWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get energyWeek;

  /// No description provided for @energyMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get energyMonth;

  /// No description provided for @energyCurrentPower.
  ///
  /// In en, this message translates to:
  /// **'Power now'**
  String get energyCurrentPower;

  /// No description provided for @energyNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Energy is not set up in Home Assistant yet (Settings → Dashboards → Energy). Once it is, consumption, solar and devices appear here.'**
  String get energyNotConfigured;

  /// No description provided for @energyOffline.
  ///
  /// In en, this message translates to:
  /// **'Energy statistics are loaded from Home Assistant and are available while connected.'**
  String get energyOffline;

  /// No description provided for @energyConsumption.
  ///
  /// In en, this message translates to:
  /// **'Home consumption'**
  String get energyConsumption;

  /// No description provided for @energyFromGrid.
  ///
  /// In en, this message translates to:
  /// **'From grid'**
  String get energyFromGrid;

  /// No description provided for @energyToGrid.
  ///
  /// In en, this message translates to:
  /// **'To grid'**
  String get energyToGrid;

  /// No description provided for @energySolar.
  ///
  /// In en, this message translates to:
  /// **'Solar production'**
  String get energySolar;

  /// No description provided for @energyBatteryCharge.
  ///
  /// In en, this message translates to:
  /// **'Battery charged'**
  String get energyBatteryCharge;

  /// No description provided for @energyBatteryDischarge.
  ///
  /// In en, this message translates to:
  /// **'Battery discharged'**
  String get energyBatteryDischarge;

  /// No description provided for @energyGas.
  ///
  /// In en, this message translates to:
  /// **'Gas'**
  String get energyGas;

  /// No description provided for @energyCostEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimated cost'**
  String get energyCostEstimate;

  /// No description provided for @energySetTariff.
  ///
  /// In en, this message translates to:
  /// **'Enter a tariff for a cost estimate'**
  String get energySetTariff;

  /// No description provided for @energyPerHour.
  ///
  /// In en, this message translates to:
  /// **'Consumption per hour'**
  String get energyPerHour;

  /// No description provided for @energyPerDay.
  ///
  /// In en, this message translates to:
  /// **'Consumption per day'**
  String get energyPerDay;

  /// No description provided for @energyTopConsumers.
  ///
  /// In en, this message translates to:
  /// **'Top consumers'**
  String get energyTopConsumers;

  /// No description provided for @energyNoDevices.
  ///
  /// In en, this message translates to:
  /// **'No individual devices are added to the Energy dashboard in Home Assistant.'**
  String get energyNoDevices;

  /// No description provided for @energyNoData.
  ///
  /// In en, this message translates to:
  /// **'No data for this period yet.'**
  String get energyNoData;

  /// No description provided for @energyPeak.
  ///
  /// In en, this message translates to:
  /// **'Highest: {time} · {value}'**
  String energyPeak(String time, String value);

  /// No description provided for @energyShowChart.
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get energyShowChart;

  /// No description provided for @energyShowTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get energyShowTable;

  /// No description provided for @energyConsumptionChart.
  ///
  /// In en, this message translates to:
  /// **'Consumption chart'**
  String get energyConsumptionChart;

  /// No description provided for @energyTariffTitle.
  ///
  /// In en, this message translates to:
  /// **'Electricity tariff'**
  String get energyTariffTitle;

  /// No description provided for @energyTariffHint.
  ///
  /// In en, this message translates to:
  /// **'Used only for an estimate on this device. Real bills also include fixed fees, taxes and time-of-day rates.'**
  String get energyTariffHint;

  /// No description provided for @energyTariffImport.
  ///
  /// In en, this message translates to:
  /// **'Price per kWh from the grid'**
  String get energyTariffImport;

  /// No description provided for @energyTariffExport.
  ///
  /// In en, this message translates to:
  /// **'Compensation per kWh to the grid (optional)'**
  String get energyTariffExport;

  /// No description provided for @energyTariffCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get energyTariffCurrency;

  /// No description provided for @energyTariffInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid, non-negative price.'**
  String get energyTariffInvalid;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @weatherClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get weatherClear;

  /// No description provided for @weatherClearNight.
  ///
  /// In en, this message translates to:
  /// **'Clear night'**
  String get weatherClearNight;

  /// No description provided for @weatherPartlyCloudy.
  ///
  /// In en, this message translates to:
  /// **'Partly cloudy'**
  String get weatherPartlyCloudy;

  /// No description provided for @weatherCloudy.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get weatherCloudy;

  /// No description provided for @weatherFog.
  ///
  /// In en, this message translates to:
  /// **'Fog'**
  String get weatherFog;

  /// No description provided for @weatherRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherRain;

  /// No description provided for @weatherHeavyRain.
  ///
  /// In en, this message translates to:
  /// **'Heavy rain'**
  String get weatherHeavyRain;

  /// No description provided for @weatherSnow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get weatherSnow;

  /// No description provided for @weatherSleet.
  ///
  /// In en, this message translates to:
  /// **'Sleet'**
  String get weatherSleet;

  /// No description provided for @weatherHail.
  ///
  /// In en, this message translates to:
  /// **'Hail'**
  String get weatherHail;

  /// No description provided for @weatherThunderstorm.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get weatherThunderstorm;

  /// No description provided for @weatherWindy.
  ///
  /// In en, this message translates to:
  /// **'Windy'**
  String get weatherWindy;

  /// No description provided for @weatherExceptional.
  ///
  /// In en, this message translates to:
  /// **'Severe weather'**
  String get weatherExceptional;

  /// No description provided for @weatherAtHome.
  ///
  /// In en, this message translates to:
  /// **'Weather at home'**
  String get weatherAtHome;

  /// No description provided for @weatherAtMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Weather at my location'**
  String get weatherAtMyLocation;

  /// No description provided for @weatherEnableDevice.
  ///
  /// In en, this message translates to:
  /// **'Weather at my location'**
  String get weatherEnableDevice;

  /// No description provided for @weatherEnableDeviceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get weatherEnableDeviceConfirm;

  /// No description provided for @weatherDeviceDisclosure.
  ///
  /// In en, this message translates to:
  /// **'The app will ask for your approximate location (not precise GPS), round it to about 1 km and send it to MET Norway (api.met.no) to get the forecast – about every 30 minutes while the app is open. Nothing else is sent. You can turn this off anytime in Settings → Privacy & data.'**
  String get weatherDeviceDisclosure;

  /// No description provided for @weatherDeviceSettingHint.
  ///
  /// In en, this message translates to:
  /// **'Approximate location is sent to MET Norway. Off by default.'**
  String get weatherDeviceSettingHint;

  /// No description provided for @weatherMetAttribution.
  ///
  /// In en, this message translates to:
  /// **'Data: MET Norway (CC BY 4.0)'**
  String get weatherMetAttribution;

  /// No description provided for @weatherLocationDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location access is blocked for this app.'**
  String get weatherLocationDeniedForever;

  /// No description provided for @weatherOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get weatherOpenSettings;

  /// No description provided for @weatherLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are turned off on this device.'**
  String get weatherLocationOff;

  /// No description provided for @weatherLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location access was not allowed.'**
  String get weatherLocationDenied;

  /// No description provided for @weatherDeviceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Weather for your location is not available right now.'**
  String get weatherDeviceUnavailable;

  /// No description provided for @weatherWind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get weatherWind;

  /// No description provided for @summaryOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get summaryOutdoor;

  /// No description provided for @presetNone.
  ///
  /// In en, this message translates to:
  /// **'No preset'**
  String get presetNone;

  /// No description provided for @presetHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get presetHome;

  /// No description provided for @presetAway.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get presetAway;

  /// No description provided for @presetSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get presetSleep;

  /// No description provided for @presetEco.
  ///
  /// In en, this message translates to:
  /// **'Eco'**
  String get presetEco;

  /// No description provided for @presetComfort.
  ///
  /// In en, this message translates to:
  /// **'Comfort'**
  String get presetComfort;

  /// No description provided for @presetBoost.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get presetBoost;

  /// No description provided for @presetActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get presetActivity;

  /// No description provided for @kioskShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get kioskShortcuts;

  /// No description provided for @kioskShortcutsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Star devices to show them here.'**
  String get kioskShortcutsEmpty;

  /// No description provided for @kioskLightsOn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{All lights off} =1{1 light on} other{{count} lights on}}'**
  String kioskLightsOn(int count);

  /// No description provided for @kioskClimate.
  ///
  /// In en, this message translates to:
  /// **'Climate'**
  String get kioskClimate;

  /// No description provided for @kioskAverage.
  ///
  /// In en, this message translates to:
  /// **'Average {value}'**
  String kioskAverage(String value);

  /// No description provided for @kioskOpenings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Everything closed} other{{count} open}}'**
  String kioskOpenings(int count);

  /// No description provided for @kioskDoorsWindows.
  ///
  /// In en, this message translates to:
  /// **'Doors and windows'**
  String get kioskDoorsWindows;

  /// No description provided for @kioskPower.
  ///
  /// In en, this message translates to:
  /// **'Power now'**
  String get kioskPower;

  /// No description provided for @kioskBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get kioskBackground;

  /// No description provided for @kioskBackgroundAurora.
  ///
  /// In en, this message translates to:
  /// **'Aurora'**
  String get kioskBackgroundAurora;

  /// No description provided for @kioskBackgroundOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get kioskBackgroundOcean;

  /// No description provided for @kioskBackgroundDusk.
  ///
  /// In en, this message translates to:
  /// **'Dusk'**
  String get kioskBackgroundDusk;

  /// No description provided for @kioskBackgroundForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get kioskBackgroundForest;

  /// No description provided for @kioskLiteEffects.
  ///
  /// In en, this message translates to:
  /// **'Lighter effects'**
  String get kioskLiteEffects;

  /// No description provided for @kioskLiteEffectsHint.
  ///
  /// In en, this message translates to:
  /// **'No glass blur, for slower tablets.'**
  String get kioskLiteEffectsHint;

  /// No description provided for @thermostatModes.
  ///
  /// In en, this message translates to:
  /// **'Modes'**
  String get thermostatModes;

  /// No description provided for @powerToggle.
  ///
  /// In en, this message translates to:
  /// **'On/off'**
  String get powerToggle;

  /// No description provided for @personHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get personHome;

  /// No description provided for @personAway.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get personAway;

  /// No description provided for @householdTitle.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get householdTitle;

  /// No description provided for @kioskStatusEntities.
  ///
  /// In en, this message translates to:
  /// **'Status chips at the top'**
  String get kioskStatusEntities;

  /// No description provided for @kioskStatusEntitiesHint.
  ///
  /// In en, this message translates to:
  /// **'Pick up to {max} devices or sensors to show at the top of the kiosk screen, for example the washing machine, a printer or a sleep sensor.'**
  String kioskStatusEntitiesHint(int max);

  /// No description provided for @kioskStatusNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get kioskStatusNone;

  /// No description provided for @kioskStatusSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String kioskStatusSelected(int count);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHint;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String timeDaysAgo(int count);

  /// No description provided for @weatherForecastTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather forecast'**
  String get weatherForecastTitle;

  /// No description provided for @weatherHourly.
  ///
  /// In en, this message translates to:
  /// **'Next hours'**
  String get weatherHourly;

  /// No description provided for @weatherDaily.
  ///
  /// In en, this message translates to:
  /// **'Next days'**
  String get weatherDaily;

  /// No description provided for @weatherToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get weatherToday;

  /// No description provided for @weatherNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get weatherNow;

  /// No description provided for @weatherNoForecast.
  ///
  /// In en, this message translates to:
  /// **'Your Home Assistant weather entity provides no forecast.'**
  String get weatherNoForecast;

  /// No description provided for @weatherPrecipitation.
  ///
  /// In en, this message translates to:
  /// **'Precipitation'**
  String get weatherPrecipitation;

  /// No description provided for @weatherFeelsHint.
  ///
  /// In en, this message translates to:
  /// **'From your Home Assistant weather entity. Nothing leaves your network.'**
  String get weatherFeelsHint;

  /// No description provided for @camerasTitle.
  ///
  /// In en, this message translates to:
  /// **'Cameras'**
  String get camerasTitle;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The camera isn\'t sending images right now.'**
  String get cameraUnavailable;

  /// No description provided for @cameraSnapshotAt.
  ///
  /// In en, this message translates to:
  /// **'Snapshot {time}'**
  String cameraSnapshotAt(String time);

  /// No description provided for @cameraRefreshHint.
  ///
  /// In en, this message translates to:
  /// **'The picture refreshes every {seconds} s while this screen is open. Nothing is recorded or stored.'**
  String cameraRefreshHint(int seconds);

  /// No description provided for @cameraFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get cameraFullscreen;

  /// No description provided for @cameraLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading the camera…'**
  String get cameraLoading;

  /// No description provided for @kioskShowCameras.
  ///
  /// In en, this message translates to:
  /// **'Show cameras'**
  String get kioskShowCameras;

  /// No description provided for @kioskShowCamerasHint.
  ///
  /// In en, this message translates to:
  /// **'Camera pictures are visible to anyone looking at the wall tablet.'**
  String get kioskShowCamerasHint;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @calendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// No description provided for @calendarTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get calendarTomorrow;

  /// No description provided for @calendarAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get calendarAllDay;

  /// No description provided for @calendarNoEvents.
  ///
  /// In en, this message translates to:
  /// **'No events'**
  String get calendarNoEvents;

  /// No description provided for @calendarNone.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant has no calendars. Add one there, for example Google Calendar, CalDAV or the Local Calendar integration.'**
  String get calendarNone;

  /// No description provided for @calendarUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The calendar isn\'t available right now.'**
  String get calendarUnavailable;

  /// No description provided for @calendarPrevMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get calendarPrevMonth;

  /// No description provided for @calendarNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get calendarNextMonth;

  /// No description provided for @calendarBackToToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarBackToToday;

  /// No description provided for @kioskShowCalendar.
  ///
  /// In en, this message translates to:
  /// **'Show calendar'**
  String get kioskShowCalendar;

  /// No description provided for @kioskShowCalendarHint.
  ///
  /// In en, this message translates to:
  /// **'Events are visible to anyone looking at the wall tablet.'**
  String get kioskShowCalendarHint;

  /// No description provided for @assistTitle.
  ///
  /// In en, this message translates to:
  /// **'Assist'**
  String get assistTitle;

  /// No description provided for @assistHint.
  ///
  /// In en, this message translates to:
  /// **'Type a command or a question'**
  String get assistHint;

  /// No description provided for @assistSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get assistSend;

  /// No description provided for @assistIntro.
  ///
  /// In en, this message translates to:
  /// **'Ask Home Assistant to do something, for example:'**
  String get assistIntro;

  /// No description provided for @assistSuggestionLightsOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off the lights'**
  String get assistSuggestionLightsOff;

  /// No description provided for @assistSuggestionTemperature.
  ///
  /// In en, this message translates to:
  /// **'What is the temperature in the living room?'**
  String get assistSuggestionTemperature;

  /// No description provided for @assistSuggestionLightsOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on the lights'**
  String get assistSuggestionLightsOn;

  /// No description provided for @assistUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Assist isn\'t available right now.'**
  String get assistUnavailable;

  /// No description provided for @assistNotUnderstood.
  ///
  /// In en, this message translates to:
  /// **'Assist couldn\'t do that.'**
  String get assistNotUnderstood;

  /// No description provided for @assistPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Your text goes only to your Home Assistant server. Assist understands the languages set up there and acts with your account\'s permissions.'**
  String get assistPrivacy;

  /// No description provided for @mediaPlayPause.
  ///
  /// In en, this message translates to:
  /// **'Play or pause'**
  String get mediaPlayPause;

  /// No description provided for @mediaNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get mediaNext;

  /// No description provided for @mediaPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get mediaPrevious;

  /// No description provided for @mediaNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get mediaNowPlaying;

  /// No description provided for @addDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add device'**
  String get addDeviceTitle;

  /// No description provided for @addDeviceIntro.
  ///
  /// In en, this message translates to:
  /// **'New devices pair with your Home Assistant hub, which has the Zigbee or Z-Wave radio, not with this phone. The app guides you through it.'**
  String get addDeviceIntro;

  /// No description provided for @addDeviceZigbee.
  ///
  /// In en, this message translates to:
  /// **'Zigbee'**
  String get addDeviceZigbee;

  /// No description provided for @addDeviceZigbeeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sensors, bulbs, plugs, switches'**
  String get addDeviceZigbeeSubtitle;

  /// No description provided for @addDeviceWifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi and LAN'**
  String get addDeviceWifi;

  /// No description provided for @addDeviceMatter.
  ///
  /// In en, this message translates to:
  /// **'Matter'**
  String get addDeviceMatter;

  /// No description provided for @addDeviceZwave.
  ///
  /// In en, this message translates to:
  /// **'Z-Wave'**
  String get addDeviceZwave;

  /// No description provided for @addDeviceSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get addDeviceSoon;

  /// No description provided for @zigbeeViaZha.
  ///
  /// In en, this message translates to:
  /// **'Via ZHA'**
  String get zigbeeViaZha;

  /// No description provided for @zigbeeViaZ2m.
  ///
  /// In en, this message translates to:
  /// **'Via Zigbee2MQTT'**
  String get zigbeeViaZ2m;

  /// No description provided for @zigbeeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Neither ZHA nor Zigbee2MQTT was found in Home Assistant. Add a Zigbee coordinator there first.'**
  String get zigbeeNotFound;

  /// No description provided for @zigbeeStep1.
  ///
  /// In en, this message translates to:
  /// **'Start pairing with the button below.'**
  String get zigbeeStep1;

  /// No description provided for @zigbeeStep2.
  ///
  /// In en, this message translates to:
  /// **'Reset the device or put it in pairing mode. Usually you hold its button for about 5 seconds until it blinks; check the device\'s manual.'**
  String get zigbeeStep2;

  /// No description provided for @zigbeeStep3.
  ///
  /// In en, this message translates to:
  /// **'Keep the device near the hub until it shows up in the list.'**
  String get zigbeeStep3;

  /// No description provided for @pairingStart.
  ///
  /// In en, this message translates to:
  /// **'Start pairing'**
  String get pairingStart;

  /// No description provided for @pairingStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get pairingStop;

  /// No description provided for @pairingExtend.
  ///
  /// In en, this message translates to:
  /// **'Extend'**
  String get pairingExtend;

  /// No description provided for @pairingOpen.
  ///
  /// In en, this message translates to:
  /// **'Pairing is on'**
  String get pairingOpen;

  /// No description provided for @pairingRemaining.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String pairingRemaining(String time);

  /// No description provided for @pairingClosed.
  ///
  /// In en, this message translates to:
  /// **'Pairing is off'**
  String get pairingClosed;

  /// No description provided for @pairingWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for new devices…'**
  String get pairingWaiting;

  /// No description provided for @pairingFound.
  ///
  /// In en, this message translates to:
  /// **'New devices'**
  String get pairingFound;

  /// No description provided for @pairingFailed.
  ///
  /// In en, this message translates to:
  /// **'Pairing couldn\'t be started. {reason}'**
  String pairingFailed(String reason);

  /// No description provided for @newDeviceSetUp.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get newDeviceSetUp;

  /// No description provided for @setUpDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Name and room'**
  String get setUpDeviceTitle;

  /// No description provided for @deviceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get deviceNameLabel;

  /// No description provided for @deviceRoomLabel.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get deviceRoomLabel;

  /// No description provided for @setUpSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get setUpSaved;

  /// No description provided for @setUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Name and room can\'t be changed from here. Do it in Home Assistant under Settings, Devices.'**
  String get setUpFailed;

  /// No description provided for @weatherHomeLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Forecast for your home'**
  String get weatherHomeLocationTitle;

  /// No description provided for @weatherHomeLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant has no weather entity. Add the Met.no integration in Home Assistant, or turn on the forecast in the app.'**
  String get weatherHomeLocationHint;

  /// No description provided for @weatherHomeLocationEnable.
  ///
  /// In en, this message translates to:
  /// **'Turn on forecast'**
  String get weatherHomeLocationEnable;

  /// No description provided for @weatherHomeLocationDisclosure.
  ///
  /// In en, this message translates to:
  /// **'The app will send your home\'s approximate location from Home Assistant, rounded to about 1 km, to MET Norway (api.met.no) every 30 minutes. Nothing else is sent. You can turn it off in Settings.'**
  String get weatherHomeLocationDisclosure;

  /// No description provided for @weatherHomeLocationSetting.
  ///
  /// In en, this message translates to:
  /// **'Forecast for the home location (MET Norway)'**
  String get weatherHomeLocationSetting;

  /// No description provided for @weatherHomeLocationSettingHint.
  ///
  /// In en, this message translates to:
  /// **'Only when Home Assistant has no weather entity. Sends the home\'s approximate location.'**
  String get weatherHomeLocationSettingHint;

  /// No description provided for @weatherNoHomeCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Home Assistant has no home location set.'**
  String get weatherNoHomeCoordinates;

  /// No description provided for @kioskWeatherMissing.
  ///
  /// In en, this message translates to:
  /// **'No weather forecast. Turn it on in Settings, Privacy, or add the Met.no integration in Home Assistant.'**
  String get kioskWeatherMissing;

  /// No description provided for @calendarNoneShort.
  ///
  /// In en, this message translates to:
  /// **'No calendars in Home Assistant'**
  String get calendarNoneShort;

  /// No description provided for @mediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Music and media'**
  String get mediaTitle;

  /// No description provided for @mediaNoPlayers.
  ///
  /// In en, this message translates to:
  /// **'No media players in Home Assistant.'**
  String get mediaNoPlayers;

  /// No description provided for @mediaSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get mediaSource;

  /// No description provided for @mediaIdle.
  ///
  /// In en, this message translates to:
  /// **'Not playing'**
  String get mediaIdle;
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
