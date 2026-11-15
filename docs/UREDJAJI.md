# Provereni uređaji

Uređaji koje instalater prodaje treba da budu isprobani sa ovom aplikacijom **pre** prve
ugradnje. Ovaj spisak popunjava instalater posle provere; **za sada nijedan uređaj nije
potvrđen na pravom hardveru** (aplikacija je testirana na demo kući i na jednom tabletu).

## Kako se uređaj proverava

Uređaj ulazi na spisak tek kad prođe sve:

- [ ] Uparuje se iz aplikacije (Dodaj uređaj) ili iz HA bez dodatnog oblaka proizvođača.
- [ ] U aplikaciji se prikazuje kao prava vrsta (sijalica, utičnica, senzor vrata…), sa
      ispravnim ikonama i jedinicama.
- [ ] Upravljanje iz aplikacije: odziv do 1 s; stanje se vraća i kad se uređaj promeni
      ručno (prekidač na zidu).
- [ ] **Radi bez interneta** (isključite ruter ka internetu: kuća mora i dalje da radi).
- [ ] Posle nestanka struje vraća se sam, u dogovoreno stanje.
- [ ] Baterija (ako je ima) se prijavljuje u procentima; Zigbee LQI na mapi mreže ≥ 80 na
      predviđenom mestu.
- [ ] Nedelja dana bez „nedostupan” u Pregledu svih kuća.
- [ ] Ima oznake usaglašenosti potrebne za prodaju u Srbiji (radio-oprema) i uputstvo na
      srpskom ili engleskom.

## Spisak

| Vrsta | Proizvođač i model | Protokol | Firmver / HA integracija | Provereno (datum, ko) | Napomena |
|---|---|---|---|---|---|
| | | | | | |

Primer upisa (izmišljen, obrisati):
`| Utičnica sa merenjem | Proizvođač X, model Y | Zigbee (ruter) | ZHA, HA 2026.11 | 20.11.2026, M. P. | dobar ruter za hodnik |`

## Saveti za izbor (bez garancije za konkretan model)

- **Zigbee ili Matter preko Thread-a** radi lokalno i ne zavisi od oblaka; utičnice i
  sijalice na struju su ujedno ruteri i jačaju mrežu.
- **Wi-Fi uređaji koji rade samo preko oblaka proizvođača** (bez lokalnog API-ja) prestaju
  da rade bez interneta i kad proizvođač ugasi servis — izbegavati za bitne stvari
  (brava, grejanje, alarm).
- **Brave i alarm:** samo modeli sa lokalnom integracijom i stanjem „zaglavljena/otvorena”;
  otključavanje iz aplikacije uvek traži potvrdu (i PIN na zidnom panelu).
- **Kamere:** sa lokalnim RTSP/ONVIF strimom; snimanje na NVR ili Frigate u kući, ne samo
  u oblaku.
- **Senzori dima i vode** u aplikaciji su dodatna obaveštenja, **ne** zamena za sertifikovan
  protivpožarni ili protivprovalni sistem — tako i u ugovoru sa kupcem.
