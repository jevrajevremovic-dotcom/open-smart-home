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

## Objavljivanje izdanja (ažuriranje u aplikaciji)

Instalirane aplikacije same nalaze nove verzije (Podešavanja → Servis → Ažuriranje aplikacije;
automatska provera je opciona). Izvor su **GitHub Releases** javnog repozitorijuma
(`UPDATE_REPO`, podrazumevano `jevrajevremovic-dotcom/open-smart-home`; brend ga zadaje sa
`updates=` u `brand.properties`).

```bash
cd app && tool/release.sh 0.2.0 --notes "Šta je novo"
```

Skripta podiže verziju (i build broj, koji Android zahteva da raste), pravi APK-ove potpisane
vašim ključem, piše `SHA256SUMS` i objavljuje izdanje `v0.2.0`. Aplikacija instalira samo APK
čiji se SHA-256 poklapa sa `SHA256SUMS`, a Android sam odbija APK potpisan drugim ključem.
Zatim komitujte `pubspec.yaml` i `lib/app/app_info.dart`.

Repozitorijum mora biti **javan** da bi ga aplikacije videle bez tokena (tokeni se u aplikaciju
ne ugrađuju). Ako izvorni kod treba da ostane privatan, napravite poseban javni repozitorijum
samo za izdanja i navedite ga u `UPDATE_REPO` / `updates=`.
