# Izdavanje (Android)

Release verzije se potpisuju sopstvenim ključem. Ključ i lozinke **nikad** ne idu u git
(`*.jks`, `*.keystore` i `key.properties` su u `.gitignore`).

## Ključ (jednom)

```bash
mkdir -p ~/keys && keytool -genkey -v -keystore ~/keys/open-smart-home-release.jks \
  -keyalg RSA -keysize 4096 -validity 10000 -alias osh
chmod 600 ~/keys/open-smart-home-release.jks
```

Fajl `app/android/key.properties` (dozvole 600):

```
storePassword=…
keyPassword=…
keyAlias=osh
storeFile=/apsolutna/putanja/do/open-smart-home-release.jks
```

Čuvajte rezervnu kopiju ključa i lozinke van računara (menadžer lozinki, USB). Bez istog
ključa aplikacija se ne može ažurirati — samo obrisati i instalirati iznova.

## Build

```bash
cd app && flutter build apk --release --split-per-abi
```

Bez `key.properties` build i dalje radi, ali potpisuje **debug** ključem i to piše u izlazu
(„release signed with the DEBUG key”) — takve verzije se ne dele.

Provera potpisa:

```bash
$ANDROID_HOME/build-tools/<verzija>/apksigner verify --print-certs \
  build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## Prelazak sa debug ključa

Uređaj na kome je verzija potpisana drugim ključem ne prima ažuriranje
(`INSTALL_FAILED_UPDATE_INCOMPATIBLE`): aplikacija se mora jednom obrisati, što briše njena
lokalna podešavanja i prijavu. Pre toga sačuvajte podešavanja (rezervna kopija).
