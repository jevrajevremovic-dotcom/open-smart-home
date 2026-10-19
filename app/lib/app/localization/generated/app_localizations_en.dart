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
      'With a token, sign-in lasts only while this tab is open.';

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
    return 'Not connected — showing data last updated $time. It may not be current.';
  }

  @override
  String get navRooms => 'Rooms';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navScenes => 'Scenes';

  @override
  String get stateOn => 'On';

  @override
  String get stateOff => 'Off';

  @override
  String get stateUnavailable => 'Unavailable';

  @override
  String get stateUnknown => 'Unknown';

  @override
  String stateOnBrightness(int percent) {
    return 'On · $percent %';
  }

  @override
  String get motionDetected => 'Motion detected';

  @override
  String get motionClear => 'No motion';

  @override
  String get occupancyDetected => 'Occupied';

  @override
  String get occupancyClear => 'Clear';

  @override
  String get contactOpen => 'Open';

  @override
  String get contactClosed => 'Closed';

  @override
  String get smokeDetected => 'Smoke detected!';

  @override
  String get smokeClear => 'No smoke';

  @override
  String get coDetected => 'CO detected!';

  @override
  String get coClear => 'No CO';

  @override
  String get leakDetected => 'Water leak!';

  @override
  String get leakClear => 'Dry';

  @override
  String get vibrationDetected => 'Vibration';

  @override
  String get vibrationClear => 'Still';

  @override
  String get binaryActive => 'Active';

  @override
  String get binaryInactive => 'Inactive';

  @override
  String get coverOpening => 'Opening…';

  @override
  String get coverClosing => 'Closing…';

  @override
  String coverOpenPercent(int percent) {
    return 'Open $percent %';
  }

  @override
  String get lockLocked => 'Locked';

  @override
  String get lockUnlocked => 'Unlocked';

  @override
  String get lockLocking => 'Locking…';

  @override
  String get lockUnlocking => 'Unlocking…';

  @override
  String get lockJammed => 'Jammed!';

  @override
  String get alarmDisarmed => 'Disarmed';

  @override
  String get alarmArmed => 'Armed';

  @override
  String get alarmArming => 'Arming…';

  @override
  String get alarmPending => 'Pending…';

  @override
  String get alarmTriggered => 'ALARM!';

  @override
  String get hvacOff => 'Off';

  @override
  String get hvacHeat => 'Heat';

  @override
  String get hvacCool => 'Cool';

  @override
  String get hvacHeatCool => 'Heat/Cool';

  @override
  String get hvacAuto => 'Auto';

  @override
  String get hvacDry => 'Dry';

  @override
  String get hvacFanOnly => 'Fan only';

  @override
  String climateStatus(String mode, String temperature) {
    return '$mode · $temperature';
  }

  @override
  String get mediaPlaying => 'Playing';

  @override
  String get mediaPaused => 'Paused';

  @override
  String get cameraIdle => 'Ready';

  @override
  String get cameraStreaming => 'Streaming';

  @override
  String get cameraRecording => 'Recording';

  @override
  String get scriptRunning => 'Running';

  @override
  String get routineReady => 'Ready';

  @override
  String doorbellLast(String time) {
    return 'Last ring $time';
  }

  @override
  String get lowBattery => 'Low battery';

  @override
  String batteryLevel(int percent) {
    return 'Battery $percent %';
  }

  @override
  String get protocolCloud => 'Cloud';

  @override
  String get protocolVirtual => 'Virtual';

  @override
  String get favoritesEmpty =>
      'Tap the star on a device\'s page to add it to your favorites.';

  @override
  String get scenesTitle => 'Scenes';

  @override
  String get scriptsTitle => 'Scripts';

  @override
  String get automationsTitle => 'Automations';

  @override
  String get noScenes => 'No scenes yet.';

  @override
  String get dashboardAttention => 'Needs attention';

  @override
  String get summaryTemperature => 'Indoor';

  @override
  String get summaryHumidity => 'Humidity';

  @override
  String get summaryLights => 'Lights on';

  @override
  String get summaryOpenings => 'Doors & windows';

  @override
  String get summaryOpeningsClosed => 'All closed';

  @override
  String summaryOpeningsOpen(int count) {
    return '$count open';
  }

  @override
  String get summaryPower => 'Power';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get greetingNight => 'Good night';

  @override
  String get summaryAlerts => 'Alerts';

  @override
  String get valueNotAvailable => 'Not available';

  @override
  String lightsOnOf(int on, int total) {
    return '$on of $total';
  }

  @override
  String lowBatteryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count low batteries',
      one: '1 low battery',
    );
    return '$_temp0';
  }

  @override
  String unavailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unavailable',
      one: '1 unavailable',
    );
    return '$_temp0';
  }

  @override
  String get roomNoRoom => 'Unassigned';

  @override
  String get allDevices => 'All devices';

  @override
  String roomDevicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count devices',
      one: '1 device',
      zero: 'No devices',
    );
    return '$_temp0';
  }

  @override
  String roomLightsOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lights on',
      one: '1 light on',
    );
    return '$_temp0';
  }

  @override
  String get roomEmpty => 'No devices in this room.';

  @override
  String get noRoomsYet => 'No rooms are defined in Home Assistant.';

  @override
  String get groupLights => 'Lights';

  @override
  String get groupClimate => 'Climate';

  @override
  String get groupCovers => 'Blinds & doors';

  @override
  String get groupSwitches => 'Switches & outlets';

  @override
  String get groupSecurity => 'Security';

  @override
  String get groupSensors => 'Sensors';

  @override
  String get groupMedia => 'Media';

  @override
  String get groupEnergy => 'Energy';

  @override
  String get groupOther => 'Other';

  @override
  String get addFavorite => 'Add to favorites';

  @override
  String get removeFavorite => 'Remove from favorites';

  @override
  String get brightness => 'Brightness';

  @override
  String get colorTemperature => 'Color temperature';

  @override
  String get warm => 'Warm';

  @override
  String get cool => 'Cool';

  @override
  String get color => 'Color';

  @override
  String get targetTemperature => 'Target temperature';

  @override
  String get currentTemperature => 'Current';

  @override
  String get increaseTemperature => 'Increase temperature';

  @override
  String get decreaseTemperature => 'Decrease temperature';

  @override
  String get mode => 'Mode';

  @override
  String get fanMode => 'Fan';

  @override
  String get position => 'Position';

  @override
  String get open => 'Open';

  @override
  String get close => 'Close';

  @override
  String get stop => 'Stop';

  @override
  String get lock => 'Lock';

  @override
  String get unlock => 'Unlock';

  @override
  String confirmUnlockTitle(String name) {
    return 'Unlock $name?';
  }

  @override
  String confirmOpenTitle(String name) {
    return 'Open $name?';
  }

  @override
  String confirmDisarmTitle(String name) {
    return 'Disarm $name?';
  }

  @override
  String get confirmCriticalBody =>
      'This action affects the security of your home.';

  @override
  String get confirm => 'Confirm';

  @override
  String get activate => 'Activate';

  @override
  String get runNow => 'Run now';

  @override
  String sceneActivated(String name) {
    return '$name activated';
  }

  @override
  String get automationEnabled => 'Enabled';

  @override
  String lastTriggered(String time) {
    return 'Last triggered $time';
  }

  @override
  String get neverTriggered => 'Never triggered';

  @override
  String get volume => 'Volume';

  @override
  String get detailInfo => 'Information';

  @override
  String get infoRoom => 'Room';

  @override
  String get infoManufacturer => 'Manufacturer';

  @override
  String get infoModel => 'Model';

  @override
  String get infoProtocol => 'Protocol';

  @override
  String get infoLastChanged => 'Last changed';

  @override
  String get infoEntityId => 'Entity ID';

  @override
  String get infoSignal => 'Signal';

  @override
  String get infoBattery => 'Battery';

  @override
  String get deviceNotFound => 'This device no longer exists.';

  @override
  String get unavailableBanner =>
      'This device is unavailable. Controls are disabled until it reconnects.';

  @override
  String get controlsOffline =>
      'Controls are available again once the connection is restored.';

  @override
  String get kioskSection => 'Kiosk mode (wall tablet)';

  @override
  String get kioskStart => 'Start kiosk mode';

  @override
  String get kioskStartOnLaunch => 'Open in kiosk mode on launch';

  @override
  String get kioskKeepAwake => 'Keep screen on';

  @override
  String get kioskDimAfter => 'Dim screen after';

  @override
  String get kioskReturnAfter => 'Return to dashboard after';

  @override
  String get kioskPin => 'Exit PIN';

  @override
  String get kioskPinSet => 'PIN is set';

  @override
  String get kioskPinNotSet => 'No PIN — anyone can leave kiosk mode';

  @override
  String get kioskSetPin => 'Set PIN';

  @override
  String get kioskChangePin => 'Change PIN';

  @override
  String get kioskRemovePin => 'Remove PIN';

  @override
  String get kioskPinHint => '4–8 digits';

  @override
  String get kioskPinConfirm => 'Repeat PIN';

  @override
  String get kioskPinMismatch => 'The PINs do not match.';

  @override
  String get kioskPinInvalid => 'Use 4–8 digits.';

  @override
  String get kioskExit => 'Exit kiosk mode';

  @override
  String get kioskEnterPin => 'Enter PIN';

  @override
  String get kioskWrongPin => 'Wrong PIN.';

  @override
  String kioskLockedOut(int seconds) {
    return 'Too many attempts. Try again in $seconds s.';
  }

  @override
  String get kioskTapToWake => 'Tap to wake';

  @override
  String get kioskOsHint =>
      'For a fully locked wall panel also use the system\'s kiosk feature: Android screen pinning or a kiosk launcher, iOS Guided Access. They can also start the app automatically.';

  @override
  String get durationNever => 'Never';

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
    return 'Showing data from $time — updating…';
  }

  @override
  String get oauthSignIn => 'Sign in with Home Assistant';

  @override
  String get oauthHint =>
      'You sign in on your Home Assistant\'s own login page – this app never sees your password.';

  @override
  String get rememberMe => 'Remember me on this device';

  @override
  String get rememberMeHint =>
      'Stay signed in after the browser is closed. You can revoke access anytime in your Home Assistant profile (Security → Refresh tokens).';

  @override
  String get orUseToken => 'Or use a long-lived access token';

  @override
  String get loginFailed => 'Sign-in did not complete. Please try again.';

  @override
  String get discoveryTitle => 'Home Assistant on this network';

  @override
  String get discoverySearching => 'Searching…';

  @override
  String get discoveryNothingFound =>
      'No server found automatically. Enter the address below.';

  @override
  String get discoverySearchAgain => 'Search again';

  @override
  String get energyTitle => 'Energy';

  @override
  String get energyToday => 'Today';

  @override
  String get energyWeek => 'This week';

  @override
  String get energyMonth => 'This month';

  @override
  String get energyCurrentPower => 'Power now';

  @override
  String get energyNotConfigured =>
      'Energy is not set up in Home Assistant yet (Settings → Dashboards → Energy). Once it is, consumption, solar and devices appear here.';

  @override
  String get energyOffline =>
      'Energy statistics are loaded from Home Assistant and are available while connected.';

  @override
  String get energyConsumption => 'Home consumption';

  @override
  String get energyFromGrid => 'From grid';

  @override
  String get energyToGrid => 'To grid';

  @override
  String get energySolar => 'Solar production';

  @override
  String get energyBatteryCharge => 'Battery charged';

  @override
  String get energyBatteryDischarge => 'Battery discharged';

  @override
  String get energyGas => 'Gas';

  @override
  String get energyCostEstimate => 'Estimated cost';

  @override
  String get energySetTariff => 'Enter a tariff for a cost estimate';

  @override
  String get energyPerHour => 'Consumption per hour';

  @override
  String get energyPerDay => 'Consumption per day';

  @override
  String get energyTopConsumers => 'Top consumers';

  @override
  String get energyNoDevices =>
      'No individual devices are added to the Energy dashboard in Home Assistant.';

  @override
  String get energyNoData => 'No data for this period yet.';

  @override
  String energyPeak(String time, String value) {
    return 'Highest: $time · $value';
  }

  @override
  String get energyShowChart => 'Chart';

  @override
  String get energyShowTable => 'Table';

  @override
  String get energyConsumptionChart => 'Consumption chart';

  @override
  String get energyTariffTitle => 'Electricity tariff';

  @override
  String get energyTariffHint =>
      'Used only for an estimate on this device. Real bills also include fixed fees, taxes and consumption zones.';

  @override
  String get energyTariffImport => 'Price per kWh from the grid';

  @override
  String get energyTariffExport =>
      'Compensation per kWh to the grid (optional)';

  @override
  String get energyTariffCurrency => 'Currency';

  @override
  String get energyTariffInvalid => 'Enter a valid, non-negative price.';

  @override
  String get save => 'Save';

  @override
  String get weatherClear => 'Clear';

  @override
  String get weatherClearNight => 'Clear night';

  @override
  String get weatherPartlyCloudy => 'Partly cloudy';

  @override
  String get weatherCloudy => 'Cloudy';

  @override
  String get weatherFog => 'Fog';

  @override
  String get weatherRain => 'Rain';

  @override
  String get weatherHeavyRain => 'Heavy rain';

  @override
  String get weatherSnow => 'Snow';

  @override
  String get weatherSleet => 'Sleet';

  @override
  String get weatherHail => 'Hail';

  @override
  String get weatherThunderstorm => 'Thunderstorm';

  @override
  String get weatherWindy => 'Windy';

  @override
  String get weatherExceptional => 'Severe weather';

  @override
  String get weatherAtHome => 'Weather at home';

  @override
  String get weatherAtMyLocation => 'Weather at my location';

  @override
  String get weatherEnableDevice => 'Weather at my location';

  @override
  String get weatherEnableDeviceConfirm => 'Turn on';

  @override
  String get weatherDeviceDisclosure =>
      'The app will ask for your approximate location (not precise GPS), round it to about 1 km and send it to MET Norway (api.met.no) to get the forecast – about every 30 minutes while the app is open. Nothing else is sent. You can turn this off anytime in Settings → Privacy & data.';

  @override
  String get weatherDeviceSettingHint =>
      'Approximate location is sent to MET Norway. Off by default.';

  @override
  String get weatherMetAttribution => 'Data: MET Norway (CC BY 4.0)';

  @override
  String get weatherLocationDeniedForever =>
      'Location access is blocked for this app.';

  @override
  String get weatherOpenSettings => 'Open settings';

  @override
  String get weatherLocationOff =>
      'Location services are turned off on this device.';

  @override
  String get weatherLocationDenied => 'Location access was not allowed.';

  @override
  String get weatherDeviceUnavailable =>
      'Weather for your location is not available right now.';

  @override
  String get weatherWind => 'Wind';

  @override
  String get summaryOutdoor => 'Outdoor';

  @override
  String get presetNone => 'No preset';

  @override
  String get presetHome => 'Home';

  @override
  String get presetAway => 'Away';

  @override
  String get presetSleep => 'Sleep';

  @override
  String get presetEco => 'Eco';

  @override
  String get presetComfort => 'Comfort';

  @override
  String get presetBoost => 'Boost';

  @override
  String get presetActivity => 'Activity';

  @override
  String get kioskShortcuts => 'Shortcuts';

  @override
  String get kioskShortcutsEmpty => 'Star devices to show them here.';

  @override
  String kioskLightsOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lights on',
      one: '1 light on',
      zero: 'All lights off',
    );
    return '$_temp0';
  }

  @override
  String get kioskClimate => 'Climate';

  @override
  String kioskAverage(String value) {
    return 'Average $value';
  }

  @override
  String kioskOpenings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open',
      zero: 'Everything closed',
    );
    return '$_temp0';
  }

  @override
  String get kioskDoorsWindows => 'Doors and windows';

  @override
  String get kioskPower => 'Power now';

  @override
  String get kioskBackground => 'Background';

  @override
  String get kioskBackgroundAurora => 'Aurora';

  @override
  String get kioskBackgroundOcean => 'Ocean';

  @override
  String get kioskBackgroundDusk => 'Dusk';

  @override
  String get kioskBackgroundForest => 'Forest';

  @override
  String get kioskLiteEffects => 'Lighter effects';

  @override
  String get kioskLiteEffectsHint => 'No glass blur, for slower tablets.';

  @override
  String get thermostatModes => 'Modes';

  @override
  String get powerToggle => 'On/off';

  @override
  String get personHome => 'Home';

  @override
  String get personAway => 'Away';

  @override
  String get householdTitle => 'Household';

  @override
  String get kioskStatusEntities => 'Status chips at the top';

  @override
  String kioskStatusEntitiesHint(int max) {
    return 'Pick up to $max devices or sensors to show at the top of the kiosk screen, for example the washing machine, a printer or a sleep sensor.';
  }

  @override
  String get kioskStatusNone => 'None';

  @override
  String kioskStatusSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get searchHint => 'Search';

  @override
  String get done => 'Done';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get weatherForecastTitle => 'Weather forecast';

  @override
  String get weatherHourly => 'Next hours';

  @override
  String get weatherDaily => 'Next days';

  @override
  String get weatherToday => 'Today';

  @override
  String get weatherNow => 'Now';

  @override
  String get weatherNoForecast =>
      'Your Home Assistant weather entity provides no forecast.';

  @override
  String get weatherPrecipitation => 'Precipitation';

  @override
  String get weatherFeelsHint =>
      'From your Home Assistant weather entity. Nothing leaves your network.';

  @override
  String get camerasTitle => 'Cameras';

  @override
  String get cameraUnavailable => 'The camera isn\'t sending images right now.';

  @override
  String cameraSnapshotAt(String time) {
    return 'Snapshot $time';
  }

  @override
  String cameraRefreshHint(int seconds) {
    return 'The picture refreshes every $seconds s while this screen is open. Nothing is recorded or stored.';
  }

  @override
  String get cameraFullscreen => 'Full screen';

  @override
  String get cameraLoading => 'Loading the camera…';

  @override
  String get kioskShowCameras => 'Show cameras';

  @override
  String get kioskShowCamerasHint =>
      'Camera pictures are visible to anyone looking at the wall tablet.';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarToday => 'Today';

  @override
  String get calendarTomorrow => 'Tomorrow';

  @override
  String get calendarAllDay => 'All day';

  @override
  String get calendarNoEvents => 'No events';

  @override
  String get calendarNone =>
      'Home Assistant has no calendars. Add one there, for example Google Calendar, CalDAV or the Local Calendar integration.';

  @override
  String get calendarUnavailable => 'The calendar isn\'t available right now.';

  @override
  String get calendarPrevMonth => 'Previous month';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String get calendarBackToToday => 'Today';

  @override
  String get kioskShowCalendar => 'Show calendar';

  @override
  String get kioskShowCalendarHint =>
      'Events are visible to anyone looking at the wall tablet.';

  @override
  String get assistTitle => 'Assist';

  @override
  String get assistHint => 'Type a command or a question';

  @override
  String get assistSend => 'Send';

  @override
  String get assistIntro => 'Ask Home Assistant to do something, for example:';

  @override
  String get assistSuggestionLightsOff => 'Turn off the lights';

  @override
  String get assistSuggestionTemperature =>
      'What is the temperature in the living room?';

  @override
  String get assistSuggestionLightsOn => 'Turn on the lights';

  @override
  String get assistUnavailable => 'Assist isn\'t available right now.';

  @override
  String get assistNotUnderstood => 'Assist couldn\'t do that.';

  @override
  String get assistPrivacy =>
      'Your text goes only to your Home Assistant server. Assist understands the languages set up there and acts with your account\'s permissions.';

  @override
  String get mediaPlayPause => 'Play or pause';

  @override
  String get mediaNext => 'Next';

  @override
  String get mediaPrevious => 'Previous';

  @override
  String get mediaNowPlaying => 'Now playing';

  @override
  String get addDeviceTitle => 'Add device';

  @override
  String get addDeviceIntro =>
      'New devices pair with your Home Assistant hub, which has the Zigbee or Z-Wave radio, not with this phone. The app guides you through it.';

  @override
  String get addDeviceZigbee => 'Zigbee';

  @override
  String get addDeviceZigbeeSubtitle => 'Sensors, bulbs, plugs, switches';

  @override
  String get addDeviceWifi => 'Wi-Fi and LAN';

  @override
  String get addDeviceMatter => 'Matter';

  @override
  String get addDeviceZwave => 'Z-Wave';

  @override
  String get addDeviceSoon => 'Coming soon';

  @override
  String get zigbeeViaZha => 'Via ZHA';

  @override
  String get zigbeeViaZ2m => 'Via Zigbee2MQTT';

  @override
  String get zigbeeNotFound =>
      'Neither ZHA nor Zigbee2MQTT was found in Home Assistant. Add a Zigbee coordinator there first.';

  @override
  String get zigbeeStep1 => 'Start pairing with the button below.';

  @override
  String get zigbeeStep2 =>
      'Reset the device or put it in pairing mode. Usually you hold its button for about 5 seconds until it blinks; check the device\'s manual.';

  @override
  String get zigbeeStep3 =>
      'Keep the device near the hub until it shows up in the list.';

  @override
  String get pairingStart => 'Start pairing';

  @override
  String get pairingStop => 'Stop';

  @override
  String get pairingExtend => 'Extend';

  @override
  String get pairingOpen => 'Pairing is on';

  @override
  String pairingRemaining(String time) {
    return '$time left';
  }

  @override
  String get pairingClosed => 'Pairing is off';

  @override
  String get pairingWaiting => 'Waiting for new devices…';

  @override
  String get pairingFound => 'New devices';

  @override
  String pairingFailed(String reason) {
    return 'Pairing couldn\'t be started. $reason';
  }

  @override
  String get newDeviceSetUp => 'Set up';

  @override
  String get setUpDeviceTitle => 'Name and room';

  @override
  String get deviceNameLabel => 'Name';

  @override
  String get deviceRoomLabel => 'Room';

  @override
  String get setUpSaved => 'Saved.';

  @override
  String get setUpFailed =>
      'Name and room can\'t be changed from here. Do it in Home Assistant under Settings, Devices.';

  @override
  String get weatherHomeLocationTitle => 'Forecast for your home';

  @override
  String get weatherHomeLocationHint =>
      'Home Assistant has no weather entity. Add the Met.no integration in Home Assistant, or turn on the forecast in the app.';

  @override
  String get weatherHomeLocationEnable => 'Turn on forecast';

  @override
  String get weatherHomeLocationDisclosure =>
      'The app will send your home\'s approximate location from Home Assistant, rounded to about 1 km, to MET Norway (api.met.no) every 30 minutes. Nothing else is sent. You can turn it off in Settings.';

  @override
  String get weatherHomeLocationSetting =>
      'Forecast for the home location (MET Norway)';

  @override
  String get weatherHomeLocationSettingHint =>
      'Only when Home Assistant has no weather entity. Sends the home\'s approximate location.';

  @override
  String get weatherNoHomeCoordinates =>
      'Home Assistant has no home location set.';

  @override
  String get kioskWeatherMissing =>
      'No weather forecast. Turn it on in Settings, Privacy, or add the Met.no integration in Home Assistant.';

  @override
  String get calendarNoneShort => 'No calendars in Home Assistant';

  @override
  String get mediaTitle => 'Music and media';

  @override
  String get mediaNoPlayers =>
      'Home Assistant has no media players yet. Add one there, for example Spotify, Google Cast, Sonos, DLNA, Kodi or your smart TV\'s integration, and it shows up here.';

  @override
  String get mediaSource => 'Source';

  @override
  String get mediaIdle => 'Not playing';

  @override
  String weatherHomeLocationFar(int km) {
    return 'Home Assistant\'s home location is about $km km from this device. If that\'s wrong, set it in Home Assistant under Settings, System, General; the home forecast uses it.';
  }

  @override
  String get mediaNoPlayersShort => 'No media players yet';

  @override
  String get assistMic => 'Speak a command';

  @override
  String get assistListening => 'Listening…';

  @override
  String get voicePrivacyTitle => 'Voice commands';

  @override
  String get voicePrivacyBody =>
      'Your phone\'s speech recogniser turns speech into text; only the text goes to your Home Assistant. Some phones can only recognise speech online (for example Google\'s or Apple\'s service), which then receives a recording of your voice.';

  @override
  String get voiceOnDeviceOnly => 'On this device only';

  @override
  String get voiceAllowCloud => 'Allow online too';

  @override
  String get voiceUnavailable =>
      'Speech recognition isn\'t available. Check the microphone permission.';

  @override
  String get voiceOnDeviceUnavailable =>
      'This device can\'t recognise this language offline. You can allow online recognition in Settings.';

  @override
  String get voiceNoMatch => 'I didn\'t catch that. Try again.';

  @override
  String get voiceCloudSetting => 'Online speech recognition';

  @override
  String get voiceCloudSettingHint =>
      'When off, voice commands are recognised on this device only.';

  @override
  String get addDeviceWifiSubtitle =>
      'Devices Home Assistant found on your network';

  @override
  String get discoveredTitle => 'Found on the network';

  @override
  String get discoveredEmpty =>
      'Home Assistant hasn\'t found any new devices. Connect the device to the same Wi-Fi network and wait a minute; devices HA can\'t find on its own are added in Home Assistant under Settings, Devices.';

  @override
  String discoveredVia(String source) {
    return 'Found via $source';
  }

  @override
  String get discoveredRefresh => 'Search again';

  @override
  String get discoveredUnavailable =>
      'The list of found devices isn\'t available. This usually needs an administrator account in Home Assistant.';

  @override
  String get flowAdd => 'Add';

  @override
  String get flowNext => 'Next';

  @override
  String flowConfirm(String name) {
    return 'Add $name to your home?';
  }

  @override
  String flowDone(String title) {
    return 'Added: $title';
  }

  @override
  String get flowDoneDevices => 'New devices';

  @override
  String flowAborted(String reason) {
    return 'Setup stopped: $reason';
  }

  @override
  String get flowAbortedGeneric => 'Home Assistant stopped the setup.';

  @override
  String get flowUnsupported =>
      'This step needs Home Assistant itself (for example a sign-in in a browser). Continue there.';

  @override
  String get flowUnsupportedField =>
      'This form has fields the app can\'t show yet. Continue in Home Assistant.';

  @override
  String get flowWorking => 'Setting up…';

  @override
  String get flowRequired => 'Required';

  @override
  String get flowFinish => 'Done';

  @override
  String get matterTitle => 'Matter';

  @override
  String get matterIntro =>
      'Add a Matter device that already works with another app (Google Home, Apple Home, SmartThings, Alexa…).';

  @override
  String get matterStep1 =>
      'In that app, open the device and choose to share it with another app or controller (\"Linked Matter apps\", \"Turn on pairing mode\").';

  @override
  String get matterStep2 =>
      'Scan the QR code it shows, or type the 11-digit code.';

  @override
  String get matterStep3 =>
      'Home Assistant then adds the device over your network; both apps can control it.';

  @override
  String get matterNewDeviceNote =>
      'Brand-new Matter devices over Bluetooth can be added from the Android app.';

  @override
  String get matterCodeLabel => 'Setup code';

  @override
  String get matterCodeHint => '1234-567-8901 or MT:…';

  @override
  String get matterInvalidCode =>
      'That isn\'t a valid Matter code. Check the digits.';

  @override
  String get matterScan => 'Scan QR code';

  @override
  String get matterAdding => 'Adding the device… this can take a minute.';

  @override
  String get matterNotAvailable =>
      'The Matter integration isn\'t set up in Home Assistant. Add it there first.';

  @override
  String get matterFailed =>
      'The device couldn\'t be added. Make sure sharing is still on in the other app (the code is valid for a few minutes) and the device is on the same network.';

  @override
  String get matterAdded => 'Device added';

  @override
  String get scanPointCamera => 'Point the camera at the Matter QR code.';

  @override
  String get zwaveTitle => 'Z-Wave';

  @override
  String get zwaveIntro =>
      'Add a Z-Wave device through your Z-Wave JS controller.';

  @override
  String get zwaveNotAvailable =>
      'The Z-Wave JS integration isn\'t set up in Home Assistant.';

  @override
  String get zwaveStart => 'Start inclusion';

  @override
  String get zwaveStop => 'Stop';

  @override
  String get zwaveStatusWaiting =>
      'Put the device into inclusion mode (often three quick presses of its button; see the manual).';

  @override
  String get zwaveStatusFound => 'Device found…';

  @override
  String get zwaveStatusInterview =>
      'Getting to know the device (interview)… battery devices can take a few minutes.';

  @override
  String get zwaveStatusDone => 'Device added';

  @override
  String get zwaveStatusFailed =>
      'Inclusion didn\'t work. Try again closer to the controller.';

  @override
  String get zwaveStatusStopped => 'Inclusion stopped.';

  @override
  String get zwaveGrantTitle => 'Security';

  @override
  String get zwaveGrantBody =>
      'The device asks for these security levels. Allowing all of them is recommended.';

  @override
  String get zwaveS2Unauth => 'S2 unauthenticated';

  @override
  String get zwaveS2Auth => 'S2 authenticated';

  @override
  String get zwaveS2Access => 'S2 access control (locks, garage doors)';

  @override
  String get zwaveS0 => 'S0 (legacy)';

  @override
  String get zwaveGrant => 'Allow';

  @override
  String get zwavePinTitle => 'PIN from the device';

  @override
  String zwavePinBody(String dsk) {
    return 'Enter the first 5 digits of the DSK from the device label or box (usually underlined). The rest of the code: $dsk';
  }

  @override
  String get zwavePinLabel => '5 digits';

  @override
  String get zwavePinInvalid => 'Enter exactly 5 digits.';

  @override
  String get zwaveSmartStart => 'SmartStart: scan QR';

  @override
  String get zwaveSmartStartHint =>
      'Devices with a SmartStart QR code join by themselves once powered on.';

  @override
  String get zwaveSmartStartDone =>
      'Device registered. Power it on; it joins by itself within a few minutes.';

  @override
  String get zwaveSmartStartInvalid => 'That isn\'t a Z-Wave QR code.';

  @override
  String get scanPointCameraZwave => 'Point the camera at the Z-Wave QR code.';

  @override
  String get historyTitle => 'History';

  @override
  String get history24h => '24 h';

  @override
  String get history7d => '7 days';

  @override
  String historyMin(String value) {
    return 'Min $value';
  }

  @override
  String historyMax(String value) {
    return 'Max $value';
  }

  @override
  String get historyEmpty => 'No data for this period.';

  @override
  String get historyUnavailable =>
      'History isn\'t available. The recorder may be turned off in Home Assistant.';

  @override
  String get activityTitle => 'Activity';

  @override
  String get activityByUser => 'by a person';

  @override
  String get activityEmpty => 'Nothing happened in the last 24 hours.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String notificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notifications from Home Assistant',
      one: '1 notification from Home Assistant',
    );
    return '$_temp0';
  }

  @override
  String get notificationDismiss => 'Dismiss';

  @override
  String get notificationsDismissAll => 'Dismiss all';

  @override
  String get notificationsEmpty => 'No notifications.';

  @override
  String get cameraSnapshots => 'Snapshots';

  @override
  String get cameraLive => 'Live';

  @override
  String get cameraLiveHint =>
      'Live video from Home Assistant while this screen is open; sound is off. Nothing is recorded.';

  @override
  String get cameraLiveFailed =>
      'Live video isn\'t available for this camera (or the server\'s certificate isn\'t trusted by the video player). Snapshots still work.';

  @override
  String get appLockTitle => 'Open Smart Home is locked';

  @override
  String get appUnlock => 'Unlock';

  @override
  String get appLockReason => 'Unlock Open Smart Home';

  @override
  String appLockCriticalReason(String device) {
    return 'Confirm: $device';
  }

  @override
  String get securitySection => 'Security';

  @override
  String get appLockSetting => 'Lock the app';

  @override
  String get appLockSettingHint =>
      'Ask for fingerprint, face or the device PIN when opening the app (after 1 minute in the background).';

  @override
  String get appLockCriticalSetting => 'Confirm locks and alarm';

  @override
  String get appLockCriticalSettingHint =>
      'Also ask before unlocking doors, opening the garage or disarming the alarm.';

  @override
  String get appLockNoDeviceAuth =>
      'This device has no screen lock or biometrics set up.';

  @override
  String get homesTitle => 'Homes';

  @override
  String get addHome => 'Add another home';

  @override
  String get alarmArm_home => 'Home';

  @override
  String get alarmArm_away => 'Away';

  @override
  String get alarmArm_night => 'Night';

  @override
  String get alarmArm_vacation => 'Vacation';

  @override
  String get alarmArm_custom_bypass => 'Custom';

  @override
  String get alarmArmTitle => 'Arm';

  @override
  String get alarmDisarm => 'Disarm';

  @override
  String get alarmCodeTitle => 'Alarm code';

  @override
  String get vacuumCleaning => 'Cleaning';

  @override
  String get vacuumDocked => 'Docked';

  @override
  String get vacuumReturning => 'Returning to dock';

  @override
  String get vacuumPaused => 'Paused';

  @override
  String get vacuumError => 'Error';

  @override
  String get vacuumIdle => 'Idle';

  @override
  String get vacuumStart => 'Start';

  @override
  String get vacuumPause => 'Pause';

  @override
  String get vacuumReturnHome => 'Dock';

  @override
  String get fanSpeed => 'Speed';

  @override
  String get fanOscillate => 'Oscillate';

  @override
  String get targetHumidityLabel => 'Target humidity';

  @override
  String get modeLabel => 'Mode';

  @override
  String get valueLabel => 'Value';

  @override
  String get editDevice => 'Edit name and room';

  @override
  String get deviceSearchHint => 'Search by name, room or type';

  @override
  String get deviceSearchEmpty => 'No device matches.';

  @override
  String get favoritesReorder => 'Change order';

  @override
  String get restrictedTitle => 'Child / guest mode';

  @override
  String get restrictedHint =>
      'Hides sensitive devices and locks settings with a PIN on this device. Home Assistant permissions don\'t change; for real limits use a separate HA user.';

  @override
  String get restrictedHideSecurity => 'Hide locks, alarm and garage doors';

  @override
  String get restrictedHideCameras => 'Hide cameras';

  @override
  String get restrictedEnable => 'Turn on (set a PIN)';

  @override
  String get restrictedActive => 'Child / guest mode is on';

  @override
  String get restrictedDisable => 'Turn off (PIN)';

  @override
  String get restrictedHidden => 'Not available in child / guest mode.';

  @override
  String get autoNew => 'New automation';

  @override
  String get autoWhen => 'When';

  @override
  String get autoThen => 'Then';

  @override
  String get autoName => 'Name';

  @override
  String get autoTriggerTime => 'Time';

  @override
  String get autoTriggerDevice => 'Device';

  @override
  String get autoTriggerSun => 'Sun';

  @override
  String get autoEveryDay => 'Every day';

  @override
  String get autoSunrise => 'Sunrise';

  @override
  String get autoSunset => 'Sunset';

  @override
  String autoOffset(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
      zero: 'Exactly at the time',
    );
    return '$_temp0';
  }

  @override
  String get autoPickDevice => 'Choose a device';

  @override
  String get autoAddAction => 'Add an action';

  @override
  String get autoSave => 'Save to Home Assistant';

  @override
  String get autoSaved => 'Automation saved in Home Assistant.';

  @override
  String get autoSaveFailed =>
      'The automation wasn\'t saved. This needs an administrator account in Home Assistant.';

  @override
  String get autoDelete => 'Delete automation';

  @override
  String autoDeleteConfirm(String name) {
    return 'Delete \"$name\"? This can\'t be undone.';
  }

  @override
  String get autoIncomplete => 'Choose when it runs and at least one action.';

  @override
  String get autoChangesTo => 'changes to';

  @override
  String get autoNameHint => 'For example: Hallway light at night';

  @override
  String get autoHint =>
      'Saved as a normal Home Assistant automation, so it runs even when this phone is off. You can change it later in Home Assistant too.';

  @override
  String get svc_turn_on => 'Turn on';

  @override
  String get svc_turn_off => 'Turn off';

  @override
  String get svc_open_cover => 'Open';

  @override
  String get svc_close_cover => 'Close';

  @override
  String get svc_lock => 'Lock';

  @override
  String get svc_start => 'Start';

  @override
  String get svc_return_to_base => 'Back to dock';

  @override
  String get svc_media_play => 'Play';

  @override
  String get svc_media_pause => 'Pause';

  @override
  String get svc_activate => 'Activate';

  @override
  String get allLightsOn => 'All on';

  @override
  String get allLightsOff => 'All off';

  @override
  String get allLightsTitle => 'All lights in the home';

  @override
  String get floorOther => 'Other';

  @override
  String get sceneNew => 'New scene from now';

  @override
  String get sceneHint =>
      'Saves how the chosen devices are right now (on/off, brightness, colour, blinds, temperature) as a Home Assistant scene.';

  @override
  String get sceneName => 'Scene name';

  @override
  String get sceneDevices => 'Devices';

  @override
  String get sceneSave => 'Save scene';

  @override
  String get sceneSaved => 'Scene saved in Home Assistant.';

  @override
  String get sceneNeedDevice => 'Choose at least one device.';

  @override
  String get sceneDelete => 'Delete scene';

  @override
  String sceneDefaultName(String time) {
    return 'Scene $time';
  }

  @override
  String energyPrevDay(String value) {
    return 'Yesterday: $value';
  }

  @override
  String energyPrevWeek(String value) {
    return 'Last week: $value';
  }

  @override
  String energyPrevMonth(String value) {
    return 'Last month: $value';
  }

  @override
  String get autoEdit => 'Edit automation';

  @override
  String get autoTooComplex =>
      'This automation does more than the app\'s editor can show. Change it in Home Assistant.';

  @override
  String get kioskPhoto => 'Own background photo';

  @override
  String get kioskPhotoHint =>
      'Shown darkened behind the panels. Stays on this device only.';

  @override
  String get kioskPhotoPick => 'Choose photo';

  @override
  String get kioskPhotoRemove => 'Remove photo';

  @override
  String get backupSection => 'Move to another device';

  @override
  String get backupHint =>
      'Copies theme, language, favourites and kiosk layout as text, to paste in the app on another phone or tablet. Tokens, PINs and privacy choices are never included.';

  @override
  String get backupCopy => 'Copy settings';

  @override
  String get backupPaste => 'Paste settings';

  @override
  String get backupCopied =>
      'Settings copied. Paste them in the app on the other device.';

  @override
  String get backupImported => 'Settings applied.';

  @override
  String get backupInvalid =>
      'The clipboard doesn\'t contain Open Smart Home settings.';

  @override
  String get autoAddTrigger => 'Add a trigger';

  @override
  String get autoAnyTrigger => 'Runs when any of these happens.';

  @override
  String get autoOnlyIf => 'Only if';

  @override
  String get autoOnlyIfHint =>
      'Optional. All of these must be true when it starts.';

  @override
  String get autoAddCondition => 'Add a condition';

  @override
  String get autoTriggerValue => 'Value';

  @override
  String get autoAbove => 'Rises above';

  @override
  String get autoBelow => 'Falls below';

  @override
  String get autoThreshold => 'Threshold';

  @override
  String get autoCondTime => 'Between two times';

  @override
  String get autoCondAfter => 'From';

  @override
  String get autoCondBefore => 'Until';

  @override
  String get autoCondDevice => 'A device is in a state';

  @override
  String get autoCondDark => 'Only when it\'s dark';

  @override
  String get autoCondLight => 'Only when it\'s light';

  @override
  String get autoIs => 'is';

  @override
  String get activityAll => 'All';

  @override
  String get activitySecurity => 'Doors & security';

  @override
  String get activityPeople => 'People';

  @override
  String get activityHint =>
      'From Home Assistant\'s logbook for the last 24 hours. Sensors that measure continuously (temperature, power) aren\'t listed.';

  @override
  String get alertsSetting => 'Notify about critical alerts';

  @override
  String get alertsSettingHint =>
      'Smoke, CO, water leak, a triggered alarm or a jammed lock as a phone notification, shown by this device. While the app runs — or always, with “Also when the app is closed” under Messages from Home Assistant.';

  @override
  String get alertsPermissionDenied =>
      'Notifications are turned off for this app in the phone\'s settings.';

  @override
  String get fanLow => 'Low';

  @override
  String get fanMedium => 'Medium';

  @override
  String get fanMiddle => 'Middle';

  @override
  String get fanHigh => 'High';

  @override
  String get fanTop => 'Top';

  @override
  String get fanFocus => 'Focused';

  @override
  String get fanDiffuse => 'Diffuse';

  @override
  String get allCoversOpen => 'Open all';

  @override
  String get allCoversClose => 'Close all';

  @override
  String get widgetNoScenes => 'No scenes yet: create one in the app';

  @override
  String get widgetSignedOut => 'Sign in to Open Smart Home';

  @override
  String get riskVpnTunnel =>
      'Tailscale VPN address: the connection is encrypted and also works away from home.';

  @override
  String get remoteTitle => 'Address away from home';

  @override
  String get remoteNotSet => 'Not set: only the home address is used';

  @override
  String get remoteInUse => 'In use now (the home address does not answer)';

  @override
  String get remoteHint =>
      'The same Home Assistant as reached from outside: a Home Assistant Cloud (Nabu Casa) address, your own domain with HTTPS, or a Tailscale address. At home the app uses the home address; when it doesn\'t answer, it switches to this one. The same token is used.';

  @override
  String get remoteSameAsLocal => 'This is already the home address.';

  @override
  String get remoteNeedsHttps =>
      'A public address needs HTTPS (or use Tailscale), otherwise the token would cross the internet unencrypted.';

  @override
  String get remoteRemove => 'Remove';

  @override
  String get clapSetting => 'Double clap';

  @override
  String get clapSettingHint =>
      'Clap twice to switch something. Only while the kiosk is shown.';

  @override
  String get clapPrivacyTitle => 'Listen for claps?';

  @override
  String get clapPrivacyBody =>
      'While the kiosk is on screen the microphone stays on, and Android shows its microphone indicator. The app only measures how loud it is, 50 times a second, on this tablet: no sound is recorded, stored or sent anywhere. Turn it off here at any time.';

  @override
  String get clapAllow => 'Turn on';

  @override
  String get clapPermissionDenied =>
      'The microphone is not allowed for this app in the system settings.';

  @override
  String get clapTarget => 'What a double clap does';

  @override
  String get clapTargetNone => 'Nothing chosen yet';

  @override
  String get clapToggle => 'switch on/off';

  @override
  String get clapSensitivity => 'Sensitivity';

  @override
  String get clapLow => 'Low';

  @override
  String get clapMedium => 'Medium';

  @override
  String get clapHigh => 'High';

  @override
  String clapSwitched(String name, String state) {
    return '$name: $state';
  }

  @override
  String clapDone(String name) {
    return '$name: done';
  }

  @override
  String get clapLockAction =>
      'lock / unlock (unlocking asks for confirmation)';

  @override
  String get clapGarageAction => 'open (asks for confirmation) / close';

  @override
  String get clapCoverAction => 'open / close';

  @override
  String get clapVacuumAction => 'start / back to dock';

  @override
  String get clapMediaAction => 'play / pause';

  @override
  String get clapOpenScreen => 'opens its screen';

  @override
  String get clapSearch => 'Search devices';

  @override
  String get oauthHintNative =>
      'Sign in on your Home Assistant\'s own login page with your user name and password. The app receives only a one-time code and keeps no password; no long-lived token is needed.';

  @override
  String get oauthPageFailed =>
      'Home Assistant\'s login page did not load. Check the connection, or sign in with a token below. (A self-signed certificate works only with a token.)';

  @override
  String get haPushTitle => 'Messages from Home Assistant';

  @override
  String get haPushHint =>
      'Let Home Assistant automations send notifications to this device';

  @override
  String get haPushExplain =>
      'This device is added to Home Assistant (Mobile App integration). Automations can then send it messages with a notify service. They arrive over the local connection while the app is running, without any cloud service.';

  @override
  String get haPushName => 'Device name in Home Assistant';

  @override
  String get haPushDefaultName => 'Open Smart Home';

  @override
  String get haPushRegister => 'Add to Home Assistant';

  @override
  String haPushReady(String service) {
    return 'Automations send messages with $service';
  }

  @override
  String get haPushCopy => 'Copy the service name';

  @override
  String get haPushCopied => 'Service name copied.';

  @override
  String get haPushTest => 'Send a test message';

  @override
  String get haPushTestMessage =>
      'Messages from Home Assistant arrive on this device.';

  @override
  String get haPushForget => 'Stop messages';

  @override
  String get haPushForgetHint =>
      'The app stops listening for messages. To remove the device completely, delete it in Home Assistant: Settings → Devices & services → Mobile App.';

  @override
  String get haPushBackground => 'Also when the app is closed';

  @override
  String get haPushBackgroundHint =>
      'Keeps the connection open in the background, also after a restart. Android then shows a quiet, permanent notification; uses a little more battery.';

  @override
  String get haPushServiceTitle => 'Connected to Home Assistant';

  @override
  String get haPushServiceText => 'Waiting for messages from your automations';

  @override
  String get haPushRemovedInHa =>
      'This device was removed in Home Assistant (Mobile App). Add it again to receive messages.';

  @override
  String get kioskPopup => 'Camera pop-up';

  @override
  String get kioskPopupHint =>
      'Show a camera when someone rings or moves at the door';

  @override
  String kioskPopupSummary(String camera, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count triggers',
      one: '1 trigger',
    );
    return '$camera · $_temp0';
  }

  @override
  String get kioskPopupExplain =>
      'When one of the chosen devices fires — a doorbell press, motion, a door or gate opening — the kiosk wakes up and shows the camera full screen.';

  @override
  String get kioskPopupCamera => 'Camera';

  @override
  String get kioskPopupOff => 'Off';

  @override
  String get kioskPopupDuration => 'Show for';

  @override
  String get kioskPopupTriggers => 'Triggered by';

  @override
  String kioskPopupClosesIn(int seconds) {
    return 'closes in $seconds s';
  }

  @override
  String get kioskDarkScreensaver => 'Dimmed backlight when idle';

  @override
  String get kioskDarkScreensaverHint =>
      'While the screen is idle the backlight is at the level below (at night at most “Darker at night”).';

  @override
  String get kioskNight => 'Darker at night';

  @override
  String get kioskNightHint => 'Lower brightness on a schedule';

  @override
  String kioskNightRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String kioskNightFrom(String time) {
    return 'From $time';
  }

  @override
  String kioskNightTo(String time) {
    return 'Until $time';
  }

  @override
  String get kioskNightFromHelp => 'Night starts at';

  @override
  String get kioskNightToHelp => 'Night ends at';

  @override
  String kioskNightLevel(int percent) {
    return 'Night brightness: $percent %';
  }

  @override
  String get dashLayoutTitle => 'Home screen';

  @override
  String get dashLayoutSubtitle => 'Choose and order the cards';

  @override
  String get dashLayoutHint =>
      'Drag or use the arrow to change the order; the switch shows or hides a card. Warnings (connection, critical alerts) always stay on top. On tablets favorites and rooms are in the right column.';

  @override
  String get dashLayoutReset => 'Default';

  @override
  String get dashMoveUp => 'Move up';

  @override
  String get dashCardSummary => 'Summary (temperature, lights, power…)';

  @override
  String get dashCardWeather => 'Weather';

  @override
  String get dashCardMedia => 'Now playing';

  @override
  String get dashCardNotifications => 'Notifications from Home Assistant';

  @override
  String get dashCardShortcuts => 'Energy, calendar, activity';

  @override
  String get dashCardAttention => 'Needs attention (batteries, unavailable)';

  @override
  String get kioskPopupLive => 'Live video';

  @override
  String get kioskPopupLiveHint =>
      'When the camera offers a stream; until it starts, and otherwise, snapshots are shown.';

  @override
  String get timerSet => 'Timer';

  @override
  String get timerTurnOff => 'Turn off';

  @override
  String get timerTurnOn => 'Turn on';

  @override
  String timerHours(int hours) {
    return '$hours h';
  }

  @override
  String get timerHint =>
      'Home Assistant counts down, so it also works when this phone is off. It creates a small script for this device (visible in Home Assistant); this needs an administrator account.';

  @override
  String get timerRunning => 'Timer is running';

  @override
  String timerTurnsOffAt(String time) {
    return 'Turns off at $time';
  }

  @override
  String timerTurnsOnAt(String time) {
    return 'Turns on at $time';
  }

  @override
  String get timerNeedsAdmin =>
      'Timers need an administrator account in Home Assistant.';

  @override
  String energyShareOfHome(int percent) {
    return '$percent % of the home';
  }

  @override
  String get matterNewTitle => 'New Matter device';

  @override
  String get matterNewHint =>
      'Out of the box, with a QR code on it or its box. Google Play services sets it up over Bluetooth and puts it on your Wi-Fi or Thread network, then Home Assistant adds it. Keep the phone close to the device.';

  @override
  String get matterNewButton => 'Add a new Matter device';

  @override
  String get matterNoPlayServices =>
      'Adding new Matter devices on Android goes through Google Play services, which are not available here (for example an emulator, or a phone without Google services). Use Home Assistant\'s own app, or share the device from another Matter app below.';

  @override
  String get matterNewFailed =>
      'The device was not added. Reset it (see its manual) and try again close to the phone. Thread devices also need a Thread border router known to this phone.';

  @override
  String get matterSharedTitle => 'Device already in another app';

  @override
  String get kioskPanelThermostat => 'Thermostat';

  @override
  String get kioskPanelDevice => 'Device';

  @override
  String get kioskLayoutEmpty => 'No panels. Edit the layout to add some.';

  @override
  String kioskPanelUnavailable(String panel) {
    return '$panel: nothing to show right now';
  }

  @override
  String get kioskPanelEarlier => 'Move earlier';

  @override
  String get kioskPanelLater => 'Move later';

  @override
  String get kioskPanelNarrower => 'Narrower';

  @override
  String get kioskPanelWider => 'Wider';

  @override
  String get kioskPanelHeight => 'Normal / tall';

  @override
  String get kioskPanelChooseDevice => 'Choose device';

  @override
  String get kioskPanelRemove => 'Remove panel';

  @override
  String get kioskEditHint =>
      'Hold a panel and drag it onto another to move it; buttons change its size.';

  @override
  String get kioskAddPanel => 'Add panel';

  @override
  String get kioskEditLayout => 'Edit layout';

  @override
  String get kioskEditLayoutHint =>
      'Arrange, resize, add and remove panels by dragging on the tablet';

  @override
  String get settingsNotificationsSection => 'Notifications';

  @override
  String get settingsAppearanceHint => 'Theme, language, home screen';

  @override
  String get settingsServerHint => 'Address, away address, homes, sign out';

  @override
  String get settingsKioskHint =>
      'Wall tablet: layout, PIN, screensaver, camera';

  @override
  String get settingsNotificationsHint =>
      'Messages from Home Assistant, alerts';

  @override
  String get settingsSecurityHint => 'App lock, kids and guests mode';

  @override
  String get settingsPrivacyHint => 'Location, voice, deleting data';

  @override
  String get settingsBackupHint => 'Copy settings to another phone or tablet';

  @override
  String get loadingContent => 'Loading…';

  @override
  String get houseCheckTitle => 'House check';

  @override
  String get houseCheckShort => 'Check';

  @override
  String get houseCheckLeaving => 'Leaving';

  @override
  String get houseCheckNight => 'Good night';

  @override
  String get houseCheckAllGood => 'All good';

  @override
  String get houseCheckAllGoodLeaving =>
      'Lights are off, locks are locked, nothing is left open. Have a good trip!';

  @override
  String get houseCheckAllGoodNight =>
      'The house is ready for the night. Good night!';

  @override
  String houseCheckCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count things to check',
      one: '$count thing to check',
    );
    return '$_temp0';
  }

  @override
  String houseCheckFixAll(int count) {
    return 'Fix all ($count)';
  }

  @override
  String get houseCheckFixing => 'Fixing…';

  @override
  String get houseCheckManualHint =>
      'The app cannot close windows and doors with a sensor — please check them. The alarm is armed on its own screen.';

  @override
  String get houseCheckLightOn => 'On';

  @override
  String get houseCheckMediaOn => 'On';

  @override
  String get houseCheckClimateOn => 'Running';

  @override
  String get houseCheckUnlocked => 'Unlocked';

  @override
  String get houseCheckGarageOpen => 'Open';

  @override
  String get houseCheckOpened => 'Open';

  @override
  String get houseCheckAlarmOff => 'Alarm not armed';

  @override
  String get houseCheckTurnOff => 'Turn off';

  @override
  String get houseCheckLock => 'Lock';

  @override
  String get houseCheckClose => 'Close';

  @override
  String get houseCheckPause => 'Pause';

  @override
  String get houseCheckOpenDevice => 'Open';

  @override
  String todoOpenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
      zero: 'All done',
    );
    return '$_temp0';
  }

  @override
  String get todoTitle => 'Lists';

  @override
  String get todoAddHint => 'Add an item…';

  @override
  String get todoAdd => 'Add';

  @override
  String todoDone(int count) {
    return 'Done ($count)';
  }

  @override
  String get todoClearDone => 'Clear done';

  @override
  String get todoEmpty => 'No items. Add the first one.';

  @override
  String get todoNoLists =>
      'Home Assistant has no lists. Add the “Shopping list” or “Local to-do” integration.';

  @override
  String get todoRename => 'Edit item';

  @override
  String get todoDelete => 'Delete';

  @override
  String get todoReadOnly => 'This list is read-only here.';

  @override
  String todoDue(String date) {
    return 'Due: $date';
  }

  @override
  String get todoUnavailable => 'The list is not available right now.';

  @override
  String get dashCardLists => 'Lists';

  @override
  String get energyTwoRate => 'Two-rate meter';

  @override
  String get energyTwoRateHint =>
      'The lower (night) rate applies in the hours you set. They differ by area — check your bill or your distributor.';

  @override
  String get energyLowPrice => 'Low-rate price (per kWh)';

  @override
  String get energyHighPrice => 'High-rate price (per kWh)';

  @override
  String get energyLowFrom => 'From';

  @override
  String get energyLowTo => 'To';

  @override
  String get energyLowPresetBelgrade => 'Belgrade 00–08';

  @override
  String get energyLowPresetVojvodina => 'Vojvodina 23–07';

  @override
  String get energyLowPresetCentral => 'Central Serbia 22–06';

  @override
  String get energyHighRateKwh => 'High rate';

  @override
  String get energyLowRateKwh => 'Low rate';

  @override
  String energyLowShare(int percent) {
    return '$percent % of use';
  }

  @override
  String energyLowNow(String time) {
    return 'Low rate now, until $time';
  }

  @override
  String energyHighNow(String time) {
    return 'High rate now — low rate starts at $time';
  }

  @override
  String get energyLowLegend => 'Low-rate hours';

  @override
  String get boardTitle => 'Board';

  @override
  String get boardNewPage => 'New page';

  @override
  String get boardEmpty =>
      'No pages yet. Make the first one and write or draw with a finger or a pen.';

  @override
  String get boardStorageNote =>
      'Pages are saved on your Home Assistant as pictures (image_upload), so all your devices see them. Home Assistant shows such pictures without signing in to anyone on the network who knows their long random link.';

  @override
  String get boardPen => 'Pen';

  @override
  String get boardEraser => 'Eraser';

  @override
  String get boardUndo => 'Undo';

  @override
  String get boardRedo => 'Redo';

  @override
  String get boardClear => 'Clear page';

  @override
  String get boardClearConfirm => 'Clear everything on this page?';

  @override
  String get boardDeletePage => 'Delete page';

  @override
  String get boardDeleteConfirm => 'Delete this page from Home Assistant?';

  @override
  String get boardDeleteNeedsAdmin =>
      'Deleting pictures in Home Assistant needs an administrator account.';

  @override
  String get boardSaving => 'Saving…';

  @override
  String get boardSaved => 'Saved';

  @override
  String get boardSaveFailed => 'Not saved — will try again.';

  @override
  String get boardChangedElsewhere =>
      'This page was changed on another device.';

  @override
  String get boardReload => 'Load';

  @override
  String boardColor(int n) {
    return 'Colour $n';
  }

  @override
  String boardWidth(int n) {
    return 'Width $n';
  }

  @override
  String get boardZoomHint => 'Two fingers: zoom and move';

  @override
  String get boardUnavailable =>
      'The board is not available. Check the connection to Home Assistant.';

  @override
  String boardPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '$count page',
      zero: 'Empty — write or draw something',
    );
    return '$_temp0';
  }

  @override
  String get deviceSensorBattery => 'Battery';

  @override
  String get deviceSensorBatteryState => 'Battery state';

  @override
  String get deviceSensorCharging => 'Charging';

  @override
  String get deviceSensorKiosk => 'Kiosk';

  @override
  String get deviceSensorsSwitch => 'Send battery state to Home Assistant';

  @override
  String get deviceSensorsHint =>
      'Battery level, charging and whether the kiosk is on become sensors of this device in your HA. Nothing else is sent.';

  @override
  String get smartChargeTitle => 'Smart charging';

  @override
  String smartChargeHint(int low, int high) {
    return 'The charger\'s plug turns on at $low % and off at $high % — the wall tablet\'s battery lasts longer.';
  }

  @override
  String get smartChargeWaiting =>
      'Waiting for the battery sensor to appear in Home Assistant…';

  @override
  String get smartChargePlug => 'Charger plug or switch';

  @override
  String get smartChargeCreate => 'Create automation';

  @override
  String smartChargeDone(String name) {
    return 'Automation “$name” created in Home Assistant.';
  }

  @override
  String get smartChargeNeedsAdmin =>
      'Creating automations needs an administrator account.';

  @override
  String smartChargeAlias(String device) {
    return 'Smart charging – $device';
  }

  @override
  String get nfcTitle => 'NFC tags';

  @override
  String get nfcHint =>
      'Hold the phone to a tag and Home Assistant runs what you chose — e.g. a “Leaving” scene by the front door. Tags use the same format as the official HA app.';

  @override
  String get nfcSectionHint => 'A scene with a tap of the phone';

  @override
  String get nfcOff => 'NFC is turned off in the phone\'s settings.';

  @override
  String get nfcMissing =>
      'This device has no NFC. Existing tags still work from other phones.';

  @override
  String get nfcNeedsRegistration =>
      'To scan, add this device to Home Assistant (Notifications → Messages from Home Assistant).';

  @override
  String get nfcNew => 'New tag';

  @override
  String get nfcName => 'Tag name';

  @override
  String get nfcRuns => 'When scanned, run';

  @override
  String get nfcWrite => 'Write tag';

  @override
  String get nfcHold => 'Hold the tag to the back of the phone…';

  @override
  String nfcWritten(String name) {
    return 'Tag “$name” is ready.';
  }

  @override
  String get nfcWrittenNoAdmin =>
      'The tag is written, but adding it to Home Assistant (and the automation) needs an administrator account. Scans still reach HA.';

  @override
  String get nfcErrorReadOnly => 'The tag is locked and cannot be written.';

  @override
  String get nfcErrorTooSmall => 'The address does not fit on this tag.';

  @override
  String get nfcErrorUnsupported => 'This kind of tag is not supported.';

  @override
  String get nfcErrorFailed =>
      'Writing failed — hold the tag still against the phone and try again.';

  @override
  String nfcScanned(String name) {
    return 'Tag “$name” scanned';
  }

  @override
  String nfcScanFailed(String reason) {
    return 'The tag did not reach Home Assistant: $reason';
  }

  @override
  String get nfcEmpty => 'Home Assistant has no tags yet.';

  @override
  String nfcLastScanned(String when) {
    return 'Last: $when';
  }

  @override
  String get nfcNeverScanned => 'Not scanned yet';

  @override
  String get nfcScannedUnnamed => 'Tag scanned';

  @override
  String homeSayTime(String time) {
    return 'It\'s $time.';
  }

  @override
  String homeSayWeather(String condition, String temperature) {
    return 'Outside it\'s $condition, $temperature.';
  }

  @override
  String homeSayLights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lights are on',
      one: '$count light is on',
    );
    return '$_temp0';
  }

  @override
  String get homeSayLightsOff => 'All lights are off';

  @override
  String homeSayOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'and $count windows or doors are open.',
      one: 'and $count window or door is open.',
    );
    return '$_temp0';
  }

  @override
  String get homeSayClosed => 'and everything is closed.';

  @override
  String homeSayUnlocked(String names) {
    return 'Unlocked: $names.';
  }

  @override
  String homeSayAlarm(String state) {
    return 'Alarm: $state.';
  }

  @override
  String homeSayAlerts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Attention: $count alerts.',
      one: 'Attention: $count alert.',
    );
    return '$_temp0';
  }

  @override
  String get kioskStatOutside => 'Outside';

  @override
  String get kioskStatInside => 'Inside';

  @override
  String get kioskStatHumidity => 'Humidity';

  @override
  String get kioskStatPower => 'Power';

  @override
  String get kioskStatOpenings => 'Open';

  @override
  String get kioskStyle => 'Kiosk look';

  @override
  String get kioskStyleBubble => 'Bubbles';

  @override
  String get kioskStyleGlass => 'Glass';

  @override
  String get mediaShuffle => 'Shuffle';

  @override
  String get mediaRepeat => 'Repeat';

  @override
  String get mediaRepeatOff => 'Repeat off';

  @override
  String get mediaRepeatAll => 'Repeat all';

  @override
  String get mediaRepeatOne => 'Repeat one';

  @override
  String get mediaSeek => 'Position';

  @override
  String get quickTilesTitle => 'Quick tiles';

  @override
  String get quickTilesHint =>
      'Three tiles in the pull-down menu (Android): one tap switches a device or runs a scene, without opening the app. Works only on an unlocked phone; locks, garage doors and alarms are not offered.';

  @override
  String quickTileSlot(int n) {
    return 'Tile $n';
  }

  @override
  String get quickTileUnset => 'Not set up';

  @override
  String quickTileChoose(int n) {
    return 'What tile $n does';
  }

  @override
  String get quickTileClear => 'Remove';

  @override
  String get quickTileAdd => 'Add to menu';

  @override
  String get quickTileAdded => 'The tile is in the Quick Settings menu.';

  @override
  String quickTileAddManually(int n) {
    return 'Pull down the menu, tap the pencil and drag “Smart Home $n” to the tiles.';
  }

  @override
  String get aodTitle => 'Always-on screen';

  @override
  String get aodHint =>
      'When the kiosk is not used: a black screen with the clock, the forecast and one thing you choose. The content shifts slowly so the screen does not burn in.';

  @override
  String get aodFocus => 'Under the clock';

  @override
  String get aodFocusNone => 'Nothing';

  @override
  String get aodFocusNextEvent => 'Next event';

  @override
  String get aodFocusList => 'List';

  @override
  String get aodFocusDevice => 'Device';

  @override
  String get aodFocusEnergy => 'Power now';

  @override
  String get aodFocusMedia => 'Now playing';

  @override
  String get aodFocusHome => 'Home sentence';

  @override
  String get aodChoose => 'Choose';

  @override
  String get aodNextEvent => 'Next';

  @override
  String get aodNoEvents => 'No events in the next 7 days';

  @override
  String get aodToday => 'today';

  @override
  String get aodTomorrow => 'tomorrow';

  @override
  String get morningScreen => 'Morning screen';

  @override
  String get morningScreenHint =>
      'In the morning the always-on screen shows today\'s forecast, events and reminders (items due today).';

  @override
  String get morningFrom => 'From';

  @override
  String get morningTo => 'To';

  @override
  String get morningToday => 'Today';

  @override
  String get morningReminders => 'Reminders';

  @override
  String get morningNothing => 'Nothing on today.';

  @override
  String morningHighLow(String high, String low) {
    return 'high $high, low $low';
  }

  @override
  String aodNowUntil(String time) {
    return 'now, until $time';
  }

  @override
  String get aodBrightness => 'Always-on brightness';

  @override
  String get settingsAssistSection => 'Assist (voice)';

  @override
  String get settingsAssistHint => 'Spoken answers, phone assistant';

  @override
  String get assistSpeak => 'Speak answers';

  @override
  String get assistSpeakHint =>
      'When you ask by voice, the answer is spoken too (the device\'s text-to-speech, nothing is sent).';

  @override
  String get assistDefault => 'Phone assistant';

  @override
  String get assistDefaultHint =>
      'Choose Open Smart Home as the “digital assistant”: a long press of home or power opens Assist, listening.';

  @override
  String get wakeWordSetting => 'Wake word (hands-free)';

  @override
  String get wakeWordSettingHint =>
      'Say the wake word set up in Home Assistant (for example “Okay Nabu”), then the command. Only while the kiosk is shown.';

  @override
  String get wakeWordPrivacyTitle => 'Listen for the wake word?';

  @override
  String get wakeWordPrivacyBody =>
      'While the kiosk is on screen the microphone stays on (Android shows its microphone indicator) and the sound is streamed continuously to your Home Assistant server, over the same connection as everything else, so that its wake word engine (openWakeWord) can recognise the wake word. Nothing is recorded or stored on this tablet. What Home Assistant does with the command after the wake word depends on its Assist settings: local recognition (for example Whisper) stays at home, Home Assistant Cloud sends it to the internet.';

  @override
  String get wakeWordAllow => 'Turn on';

  @override
  String get wakeWordActive => 'Listening for the wake word';

  @override
  String get wakeWordMissing =>
      'Home Assistant has no wake word engine. Install the openWakeWord add-on (the Wyoming integration finds it), then turn this on again.';

  @override
  String get wakeWordNeedsServer => 'Needs a connection to Home Assistant.';

  @override
  String get approachWake => 'Wake the screen when someone comes near';

  @override
  String get approachWakeHint => 'Only while the kiosk screen is idle.';

  @override
  String get approachOff => 'Off';

  @override
  String get approachSensor => 'Motion sensor (Home Assistant)';

  @override
  String get approachCamera => 'Tablet camera';

  @override
  String get approachSensorPick => 'Sensor';

  @override
  String get approachNoSensors =>
      'Home Assistant has no motion or presence sensors.';

  @override
  String get approachCameraTitle => 'Use the tablet\'s camera?';

  @override
  String get approachCameraBody =>
      'While the screen is idle, the front camera checks a few times a second whether something moves in front of the tablet, and Android shows its camera indicator. Pictures are processed only on this tablet and dropped at once: nothing is recorded, stored or sent anywhere — not even to Home Assistant. While the screen is awake the camera is off.';

  @override
  String get approachCameraAllow => 'Turn on';

  @override
  String get approachCameraDenied =>
      'The camera is not allowed for this app in the system settings.';

  @override
  String get presenceTitle => 'Presence simulation';

  @override
  String get presenceHint =>
      'Lights go on and off by themselves in the evening while nobody is home';

  @override
  String get presenceIntro =>
      'While nobody is home, Home Assistant switches one of the chosen lights on or off every 15 minutes in the evening (with a random wait of up to 10 minutes), and turns them all off at the end time. It runs in Home Assistant, so it works even when this device is off. Saving needs an administrator account.';

  @override
  String get presenceOn => 'Simulation on';

  @override
  String get presenceNotSaved => 'Not saved in Home Assistant yet.';

  @override
  String get presenceLights => 'Lights';

  @override
  String get presenceNoLights => 'Home Assistant has no lights.';

  @override
  String get presenceWhen => 'When';

  @override
  String get presenceWhenAway => 'When nobody is home';

  @override
  String get presenceWhenAwayHint =>
      'By the people in Home Assistant (the Home zone).';

  @override
  String get presenceWhenAlarm => 'When the alarm is armed away';

  @override
  String get presenceWhenAlways => 'Always while it is on';

  @override
  String get presenceFromSunset => 'From sunset';

  @override
  String get presenceStart => 'Start';

  @override
  String get presenceEnd => 'End (all chosen lights go off)';

  @override
  String get presenceSave => 'Save to Home Assistant';

  @override
  String get presenceSaved => 'Presence simulation saved in Home Assistant.';

  @override
  String get presenceRemove => 'Remove';

  @override
  String get presenceRemoved => 'Presence simulation removed.';

  @override
  String get presenceNeedsAdmin =>
      'This needs an administrator account in Home Assistant.';

  @override
  String lowTariffAlias(String device) {
    return 'Lower rate reminder ($device)';
  }

  @override
  String get lowTariffTitle => 'The lower rate has started';

  @override
  String lowTariffMessage(String until, String price) {
    return 'Electricity is cheaper until $until ($price/kWh): a good time for the washing machine, the dishwasher or charging.';
  }

  @override
  String get lowTariffRemind => 'Remind me when the lower rate starts';

  @override
  String get lowTariffRemindOn => 'Lower rate reminder is on';

  @override
  String lowTariffDialogBody(String time) {
    return 'When the lower rate starts ($time), Home Assistant sends a message to this phone; when it ends, the message goes away by itself. It runs as an automation in Home Assistant (saving needs an administrator account), and the message arrives while the app is connected, as all messages from Home Assistant.';
  }

  @override
  String get lowTariffCreate => 'Turn on reminder';

  @override
  String get lowTariffRemove => 'Remove reminder';

  @override
  String get lowTariffCreated => 'Lower rate reminder is on.';

  @override
  String get lowTariffRemoved => 'Lower rate reminder removed.';

  @override
  String get lowTariffNeedsPush =>
      'First turn on “Messages from Home Assistant” (Settings › Notifications).';

  @override
  String get kioskAlertAck => 'Got it';

  @override
  String get kioskAlertShow => 'Show device';

  @override
  String kioskAlertOpenFor(int minutes) {
    return 'Open for $minutes min';
  }

  @override
  String kioskAlertMore(int count) {
    return '+$count more';
  }

  @override
  String kioskAlertSpeech(String name, String status) {
    return 'Warning! $name: $status.';
  }

  @override
  String get kioskAlertSetting => 'Full-screen alerts';

  @override
  String get kioskAlertSettingHint =>
      'Smoke, carbon monoxide, water leak, a triggered alarm or a jammed lock covers the whole screen and is spoken until someone confirms it.';

  @override
  String get kioskOpenAlert => 'Door or window open longer than';

  @override
  String get kioskOpenAlertNever => 'Never';

  @override
  String kioskOpenAlertMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get timerTitle => 'Timer';

  @override
  String get timerNew => 'New timer';

  @override
  String get timerStart => 'Start';

  @override
  String get timerStop => 'Stop';

  @override
  String get timerCancel => 'Cancel timer';

  @override
  String get timerAddMinute => '+1 min';

  @override
  String timerDone(String label) {
    return 'Timer $label is done';
  }

  @override
  String timerDoneSpeech(String label) {
    return 'The $label timer is done.';
  }

  @override
  String timerStarted(String label) {
    return 'Timer for $label started.';
  }

  @override
  String kioskNightLightHint(String name) {
    return 'Tap: $name at 10 %';
  }

  @override
  String kioskNightLightOn(String name) {
    return '$name is on · tap again for the screen';
  }

  @override
  String get kioskNightClock => 'Red night clock';

  @override
  String get kioskNightClockHint =>
      'At night the idle screen shows only the time, in dim red.';

  @override
  String get kioskNightLight => 'Night light on tap';

  @override
  String get kioskNightLightNone => 'None (a tap wakes the screen)';

  @override
  String get kioskLeaving => 'I\'m leaving';

  @override
  String get kioskLeavingAllGood =>
      'Everything is off and closed. Have a nice day!';

  @override
  String get kioskLeavingManual =>
      'Windows and doors marked without a tick must be closed by hand.';

  @override
  String kioskLeavingGo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Switch off $count things',
      one: 'Switch off 1 thing',
      zero: 'Nothing to switch off',
    );
    return '$_temp0';
  }

  @override
  String kioskLeavingGoArm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Switch off $count and arm',
      one: 'Switch off 1 thing and arm',
      zero: 'Arm the alarm',
    );
    return '$_temp0';
  }

  @override
  String get kioskLeavingBye => 'Goodbye!';

  @override
  String kioskEnergyToday(String kwh) {
    return 'Today $kwh';
  }

  @override
  String kioskEnergySolar(String kwh) {
    return 'Solar today $kwh';
  }

  @override
  String kioskEnergyLowFor(String time) {
    return 'Lower rate for another $time';
  }

  @override
  String kioskEnergyLowIn(String time) {
    return 'Higher rate · lower in $time';
  }

  @override
  String get kioskAddPage => 'New page';

  @override
  String get kioskRenamePage => 'Rename page';

  @override
  String get kioskDeletePage => 'Delete page';

  @override
  String get kioskPageEmpty => 'Empty';

  @override
  String get kioskPageClimateEnergy => 'Climate and energy';

  @override
  String kioskPageNumber(int number) {
    return 'Page $number';
  }

  @override
  String get kioskHomePage => 'Home';

  @override
  String get kioskPageSchedule => 'Show by itself';

  @override
  String get kioskPageScheduleFrom => 'Show this page from';

  @override
  String get kioskPageScheduleTo => 'until';

  @override
  String get photoFrame => 'Photo frame';

  @override
  String get photoFrameHint =>
      'While idle, show photos from this tablet (they stay on it).';

  @override
  String photoFrameCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos · stay on this tablet',
      one: '1 photo · stays on this tablet',
    );
    return '$_temp0';
  }

  @override
  String get photoFrameAdd => 'Add photos';

  @override
  String get photoFrameRemove => 'Remove all';

  @override
  String photoFrameEverySeconds(int seconds) {
    return 'every $seconds s';
  }

  @override
  String photoFrameEveryMinutes(int minutes) {
    return 'every $minutes min';
  }

  @override
  String get familyMessages => 'Messages';

  @override
  String get familyMessagesNone => 'No messages. Leave one for the household.';

  @override
  String get familyMessageNew => 'New message';

  @override
  String get familyMessageEveryone => 'Everyone';

  @override
  String familyMessageFor(String name) {
    return 'Message for $name';
  }

  @override
  String get familyMessageForAll => 'Message for everyone';

  @override
  String get familyMessageRead => 'Read';

  @override
  String get familyMessageHint => 'For example: there is soup in the fridge';

  @override
  String get familyMessageSend => 'Leave message';

  @override
  String welcomeHome(String name) {
    return 'Welcome home, $name!';
  }

  @override
  String get greetPeople => 'Greet people coming home';

  @override
  String get greetPeopleHint =>
      'When someone arrives (by their person in Home Assistant), the tablet says hello and shows their messages.';

  @override
  String get kioskIntercom => 'Intercom';

  @override
  String get kioskIntercomOpen => '“Open” button';

  @override
  String get kioskIntercomSpeaker => 'Speaker by the door (“Coming” button)';

  @override
  String get kioskIntercomSpeakerHint =>
      'Home Assistant says the reply there with its own text-to-speech.';

  @override
  String get kioskIntercomReply => 'Coming!';

  @override
  String get kioskIntercomReplyText => 'Coming, just a moment!';

  @override
  String get kioskIntercomReplied =>
      'Said at the door: “Coming, just a moment!”';

  @override
  String get kioskIntercomNoTts =>
      'Home Assistant has no text-to-speech set up.';

  @override
  String kioskIntercomUnlock(String name) {
    return 'Unlock $name';
  }

  @override
  String kioskIntercomOpenDevice(String name) {
    return 'Open $name';
  }

  @override
  String get kioskColumnsNoRooms =>
      'No rooms yet. Add areas in Home Assistant.';

  @override
  String get kioskColumnsDevices => 'Devices';

  @override
  String get kioskOpenDevice => 'Open device';

  @override
  String get kioskStyleColumns => 'Columns';

  @override
  String get kioskBundleMain => 'Main';

  @override
  String get kioskBundleActions => 'Actions';

  @override
  String get kioskBundleSettings => 'Settings';

  @override
  String get kioskBundleState => 'State';

  @override
  String kioskBundleCount(int count) {
    return '$count controls';
  }

  @override
  String get kioskQuickControls => 'Quick controls';

  @override
  String get kioskQuickControlsAdd => 'Add';

  @override
  String get kioskQuickControlsEdit => 'Change';

  @override
  String get kioskQuickControlsHint =>
      'Choose devices to keep at hand here — lights, the air fryer, a scene…';
}
