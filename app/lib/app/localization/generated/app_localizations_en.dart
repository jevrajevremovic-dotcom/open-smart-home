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
  String get summaryOpenings => 'Doors & windows open';

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
      'Used only for an estimate on this device. Real bills also include fixed fees, taxes and time-of-day rates.';

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
      'Brand-new Matter devices that pair over Bluetooth need Home Assistant\'s Companion app for now.';

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
}
