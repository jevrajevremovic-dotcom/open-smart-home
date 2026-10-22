# Uputstvo za instalatere

Kako se aplikacija isporučuje pod sopstvenim brendom i kako se zidni panel priprema tako da
se kiosk ne može napustiti i sam se pokreće posle nestanka struje.

## 1. Brendirana verzija

1. `app/android/brand.properties` (nije u gitu) napravite od `brand.properties.example`:

   ```
   name=Pametna Kuća Jagodina          # ime ispod ikonice i u aplikaciji
   applicationId=rs.example.pametnakuca # sopstveni Android ID
   accent=#1F6FB2                       # boja brenda
   support=+381 60 000 0000 · servis@example.rs   # na servisnom ekranu
   logo=/putanja/do/logo.png            # kvadratni PNG (opciono)
   ```

2. Ključ za potpis: `docs/RELEASE.md` (jedan ključ po brendu; čuvajte ga van računara).
3. Build: `cd app && tool/build_brand.sh` → `build/app/outputs/flutter-apk/`.

Brendirana aplikacija ima svoj ID, pa se instalira pored obične, ne preko nje. Ikonica na
početnom ekranu telefona se menja zamenom `android/app/src/main/res/mipmap-*` (Android Studio →
Image Asset). Licenca (Apache 2.0) traži da `LICENSE` i `NOTICE` ostanu uz aplikaciju; ime i
logo „Home Assistant” ne smeju se predstavljati kao vaš proizvod.

## 2. Zidni panel kao „vlasnik uređaja” (preporučeno)

Tada aplikacija: zaključava kiosk (bez početnog ekrana, nedavnih aplikacija i obaveštenja),
postaje početni ekran (pa se sama pokreće posle restarta) i drži ekran upaljen dok je na struji.

Uslovi: uređaj **bez ijednog naloga** (Google, Samsung…), najbolje odmah posle fabričkog
resetovanja.

1. Fabričko resetovanje, pa prvo pokretanje **bez** prijave na Google/Samsung nalog
   (preskočite; Wi-Fi može).
2. Podešavanja → O uređaju → 7× „Broj verzije” (opcije za programere) → uključite
   „USB otklanjanje grešaka”.
3. Sa računara:

   ```bash
   adb install app-arm64-v8a-release.apk
   adb shell dpm set-device-owner <applicationId>/org.opensmarthome.open_smart_home.KioskAdminReceiver
   ```

   Za običnu verziju `<applicationId>` je `org.opensmarthome.open_smart_home`; za brendiranu —
   vaš `applicationId`. Greška „already some accounts on the device” znači da postoji nalog:
   uklonite ga ili resetujte uređaj.
4. Otvorite aplikaciju, prijavite se na Home Assistant, pa **Podešavanja → Servis →
   Čarobnjak za instalaciju**: veza, prostorije, poruke, kiosk + PIN, „Primeni pravila
   panela”, „Pokreni kiosk režim”.
5. Isključite „USB otklanjanje grešaka”.

Google nalog se posle sme dodati ako vam treba Play prodavnica; upravljanje ostaje.

**Vraćanje uređaja** (prodaja, servis): izađite iz kioska PIN-om → Podešavanja → Servis →
„Vrati uređaj”. Ponovno uključivanje traži novo fabričko resetovanje.

## 3. Bez „vlasnika uređaja”

Na uređaju koji već ima nalog: kiosk + PIN radi, ali se aplikacija može napustiti
sistemskim gestovima. Dopunite Androidovim „Kačenjem aplikacije” (Podešavanja → Bezbednost)
i opcijom proizvođača za ograničenje punjenja baterije (npr. Samsung „Zaštita baterije”).

## 4. Ažuriranje

Ista aplikacija, isti ključ: `adb install -r <apk>` čuva podešavanja. APK potpisan drugim
ključem se ne može instalirati preko postojećeg (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`).

## 5. Servis

Podešavanja → **Servis**: verzija, uređaj, server (samo adresa, bez porta), broj
nedostupnih uređaja, stanje panela i poslednje greške. „Kopiraj dijagnostiku” daje tekst bez
tokena i lozinki — za prijavu kvara.

## 6. Pre predaje klijentu (provera)

- [ ] Uređaji raspoređeni po prostorijama u HA (čarobnjak: „Bez prostorije: 0”).
- [ ] PIN za izlaz iz kioska postavljen i predat vlasniku.
- [ ] Ograničenje punjenja ili napajanje bez baterije (PoE / „rad bez baterije”).
- [ ] Pristup van kuće (Tailscale ili Home Assistant Cloud) i pisani pristanak klijenta za
      vaš servisni pristup.
- [ ] Rezervne kopije Home Assistanta uključene.
- [ ] Klijentu objašnjeno koji podaci napuštaju kuću (kamere, prisustvo, pristup van kuće).

## Demo aplikacija (za prikaz kupcima)

`app/tool/build_demo.sh` pravi **Open Smart Home Demo** (`org.opensmarthome.open_smart_home.demo`): aplikaciju sa ugrađenom izmišljenom kućom, bez Home Assistanta i bez mreže. Ima svoj ID, pa se instalira **pored** prave aplikacije i ne dira njene podatke; ne nudi ažuriranja. To je profile build (demo server nikad ne ulazi u release), potpisan debug ključem — samo za prikaz.

```bash
cd app && tool/build_demo.sh
adb install build/app/outputs/flutter-apk/app-arm64-v8a-profile.apk
```

U demo aplikaciji: Započni → „Demo dom (mock)” → prijava bilo kojim tokenom. Na vrhu stoji traka „MOCK REŽIM”, da se nikad ne pomeša sa pravom kućom.
