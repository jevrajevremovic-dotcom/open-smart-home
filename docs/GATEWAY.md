# Lokalni Smart Home Gateway (Docker Compose)

Ovaj folder (`gateway/`) podiže lokalni hub na Linux računaru (mini PC, Raspberry Pi 4/5, server). Mobilna i web aplikacija se zatim povezuju na Home Assistant na tom računaru.

```
Telefon / tablet / web ──HTTPS/HTTP + WebSocket──► Home Assistant (host mreža, :8123)
                                                    │
        ┌──────────────── MQTT (:1883) ─────────────┤
        │                                           ├── Z-Wave JS (ws://localhost:3000)
  Mosquitto ◄── Zigbee2MQTT ◄── Zigbee USB          ├── Matter Server (ws://localhost:5580/ws)
        ▲                                           └── OTBR (Thread) ◄── RCP USB
        └── ESPHome / Tasmota / sopstveni uređaji
```

> Ako vam je cilj samo „da radi”, **Home Assistant OS** (na Raspberry Pi-ju, mini PC-ju ili Home Assistant Green) je jednostavniji: dodaci (Mosquitto, Zigbee2MQTT, Z-Wave JS, Matter, OTBR) se instaliraju klikom. Ovaj Compose je za one koji žele HA na postojećem Linux sistemu.

## Preduslovi

- Linux sa Docker Engine-om i **Compose pluginom** (`docker compose version`).
  - Arch/CachyOS: `sudo pacman -S docker docker-compose && sudo systemctl enable --now docker`
  - Debian/Ubuntu: paket `docker-compose-plugin` iz Docker repozitorijuma.
- Za Zigbee/Z-Wave/Thread: odgovarajući USB adapter.
- Fiksna IP adresa računara (DHCP rezervacija na ruteru), da bi aplikacija uvek našla server.

## Pokretanje

```bash
cd gateway
cp .env.example .env
# u .env zamenite svaki "change-me"; jake lozinke: openssl rand -base64 24
docker compose up -d                       # samo Home Assistant + Mosquitto
docker compose --profile zigbee up -d      # + Zigbee2MQTT
docker compose --profile zigbee --profile zwave --profile matter up -d
```

Servisi za koje nemate hardver se ne pokreću (Compose profili). Bez podešenog adaptera, profil `zigbee`/`zwave`/`thread` neće startovati – to je namerno.

Zatim otvorite `http://<ip-računara>:8123`, napravite HA korisnika i povežite integracije (dole).

## USB adapteri

Koristite **stabilne putanje** – `/dev/ttyUSB0` / `/dev/ttyACM0` mogu da zamene mesta posle restarta:

```bash
ls -l /dev/serial/by-id/
# npr. usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_…-if00-port0 -> ../../ttyUSB0
```

Tu punu putanju upišite u `.env` (`ZIGBEE_ADAPTER_PATH`, `ZWAVE_ADAPTER_PATH`, `THREAD_RCP_PATH`). U kontejneru je adapter uvek `/dev/zigbee`, `/dev/zwave` ili `/dev/thread-rcp`.

- Korisnik koji pokreće Docker ne mora biti u `dialout`, ali kontejner jeste (`group_add: dialout`).
- **Ne delite** jedan adapter između dva servisa (npr. HA ZHA i Zigbee2MQTT istovremeno).
- Zigbee adapter na kratkom USB produžnom kablu, dalje od USB 3.0 portova i Wi-Fi rutera, osetno smanjuje smetnje.
- `ZIGBEE_ADAPTER_TYPE`: `zstack` (TI, npr. Sonoff ZBDongle-P), `ember` (Silicon Labs, npr. ZBDongle-E), `deconz` (ConBee), `zigate`, `zboss`.

## Mreža i portovi

| Servis | Mreža | Port | Napomena |
|---|---|---|---|
| Home Assistant | host | 8123 | Host mreža je potrebna za otkrivanje uređaja (mDNS/SSDP), Matter i Thread |
| Mosquitto | bridge | 1883 | `MQTT_BIND=127.0.0.1` ako MQTT uređaja na mreži nema |
| Zigbee2MQTT | bridge | 8080 | Web UI (uparivanje uređaja, mapa mreže) |
| Z-Wave JS UI | bridge | 8091, 3000 | 8091 web UI; 3000 WebSocket za HA, vezan samo za `127.0.0.1` |
| Matter Server | host | 5580 | WebSocket za HA; potreban IPv6 na hostu |
| OTBR | host | (vidi dokumentaciju OTBR-a) | Thread border router |
| ESPHome | host | 6052 | Dashboard, zaštićen korisnikom i lozinkom iz `.env` |

**Ne izlažite ove portove internetu** (bez port-forwardinga na ruteru). Za udaljeni pristup koristite VPN (WireGuard, Tailscale) ili HTTPS reverse proxy ispred Home Assistanta.

## Povezivanje u Home Assistantu

Podešavanja → Uređaji i servisi → *Dodaj integraciju*:

| Integracija | Vrednosti |
|---|---|
| **MQTT** | broker `127.0.0.1`, port `1883`, korisnik/lozinka `MQTT_HA_USER` / `MQTT_HA_PASSWORD` |
| **Z-Wave** (Z-Wave JS) | URL `ws://127.0.0.1:3000` (u Z-Wave JS UI → Settings → Home Assistant uključite *WS Server*) |
| **Matter** | URL `ws://127.0.0.1:5580/ws` |
| **Thread / OTBR** | po uputstvu OTBR integracije (REST API border routera) |
| **ESPHome** | uređaji se otkrivaju automatski |

Zigbee2MQTT objavljuje uređaje preko MQTT discovery-ja (`homeassistant: enabled`), pa se pojavljuju u HA posle MQTT integracije, a zatim i u aplikaciji.

Zigbee2MQTT čita podešavanja iz promenljivih `ZIGBEE2MQTT_CONFIG_*` (imaju prednost nad `configuration.yaml`). Pri prvom pokretanju napravite i sačuvajte rezervnu kopiju (`backup.sh`) – u podacima su i ključevi Zigbee mreže.

## Thread (OpenThread Border Router)

Najmanje zreo deo seta – pre korišćenja proverite aktuelno uputstvo projekta OpenThread (ime image-a i argumenti se menjaju između verzija):

- potreban je adapter sa **RCP** firmverom (ne Zigbee firmver);
- host mora imati uključen IPv6 i prosleđivanje (`net.ipv6.conf.all.forwarding=1`);
- kontejner radi `privileged` sa host mrežom jer menja mrežne interfejse i rute.

Matter-over-Thread uređaji rade i sa postojećim border routerom (npr. Apple TV/HomePod, Google Nest Hub) – tada OTBR ovde nije potreban.

## Rezervne kopije

```bash
scripts/backup.sh                       # → backups/<datum-vreme>/*.tar.gz
scripts/restore.sh backups/20261013-120000
```

`backup.sh` kratko zaustavlja kontejnere da bi baze bile konzistentne, pa ih ponovo pokreće. Kopija sadrži tajne (HA prijave, ključeve Zigbee/Z-Wave mreže) – čuvajte je šifrovanu i van računara. Home Assistant ima i sopstvene backup-e (Podešavanja → Sistem → Backups).

## Ažuriranje

```bash
docker compose pull
docker compose up -d
```

Za predvidljiva ažuriranja upišite tačne verzije image-a u `.env` (`HA_IMAGE=…:2026.10.1`) i pročitajte release notes pre promene – posebno kod Home Assistanta i Zigbee2MQTT-a.

## Bezbednost

- Tajne su samo u `.env` (ignorisan u gitu); `mosquitto` lozinke se generišu iz njega pri svakom startu, anonimni MQTT pristup je isključen.
- Z-Wave JS WebSocket je vezan za `127.0.0.1`.
- Web UI-ji (Zigbee2MQTT, Z-Wave JS UI) nemaju podrazumevano autentifikaciju – ne izlažite ih van lokalne mreže; po potrebi uključite autentifikaciju u njihovim podešavanjima ili postavite `*_BIND=127.0.0.1`.
- `.env.example` ne sadrži stvarne tajne; skripta za Mosquitto odbija start dok su lozinke `change-me`.

## Ograničenja ovog Compose-a

- Proveren je strukturno (validacija YAML-a, deklarisane promenljive i volumeni, sintaksa skripti); pre prve upotrebe pokrenite `docker compose config` na svom sistemu.
- Home Assistant „Container” instalacija nema prodavnicu dodataka (Supervisor) – zato su servisi ovde posebni kontejneri.
