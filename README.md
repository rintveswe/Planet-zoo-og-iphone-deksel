# HUGO – lysboks med dyrepark-tema

Parametrisk, 3D-printbar lysboks (ca. **200 × 160 × 60 mm**). Frontpanelet har en egen, original silhuett
(elefant, giraff, to palmer, sol og gresstotter) i en stor sirkulær ramme. Teksten «HUGO» er fjernet.
Motivet er tegnet fra bunnen av i OpenSCAD. Under scenen kan du legge inn en egen logo som SVG (`logo_file` øverst i filen); da flyttes scenen opp automatisk.
En importert logo må ha broer i lukkede former (som O) så ingen deler faller ut.

![Montert](previews/01_montert_forfra.png)

## Filer

| Fil | Innhold |
|---|---|
| `hugo_lysboks.scad` | Hele modellen. **Alle mål er variabler øverst i filen.** |
| `stl/hugo_frontpanel.stl` | Frontpanel (mørk PLA) – printes med forsiden ned |
| `stl/hugo_hovedkropp.stl` | Hovedkropp (ring med LED-liste) – printes med bakkanten ned |
| `stl/hugo_bakplate.stl` | Avtagbar bakplate med USB-hull – printes med utsiden ned |
| `stl/hugo_diffuser.stl` | Diffuserplate 0,8 mm (hvit PLA) |
| `previews/` | PNG-forhåndsvisninger (se under) |
| `tools/` | Skript for forhåndsvisning og kontroller (øy-sjekk, overheng-sjekk) |

Eksportere på nytt (OpenSCAD 2021.01 eller nyere):

```bash
openscad -D 'part="front_print"'    -o stl/hugo_frontpanel.stl  hugo_lysboks.scad
openscad -D 'part="body_print"'     -o stl/hugo_hovedkropp.stl  hugo_lysboks.scad
openscad -D 'part="back_print"'     -o stl/hugo_bakplate.stl    hugo_lysboks.scad
openscad -D 'part="diffuser_print"' -o stl/hugo_diffuser.stl    hugo_lysboks.scad
tools/make_previews.sh              # PNG-er (krever xvfb + imagemagick)
```

## Printinnstillinger

Alle deler: dyse 0,4 mm, **lagtykkelse 0,2 mm**, **ingen support**, ingen brim nødvendig (se tips under).
Alle deler er under 256 × 256 mm (200 × 160 mm) og printes som de ligger i STL-filene.

| Del | Farge | Vegger | Topp/bunn | Infill | Merknad |
|---|---|---|---|---|---|
| Frontpanel | **Svart/mørk** PLA (må være ugjennomsiktig) | 3–4 | 6+ lag | 100 % (platen er bare 2,4 mm) | Forsiden mot byggeplaten gir fin overflate. |
| Hovedkropp | Hvit (best for lys) eller valgfri farge | 3 | 5 | 10–15 % gyroid | LED-listen er en 45°-trekant og printes uten support. |
| Bakplate | Hvit PLA (reflekterer lys) | 3 | 6+ | 100 % | Utsiden ned. Pluggringen/klikkesporene printes uten support. |
| Diffuser | **Hvit** PLA, ikke «silk» | – | – | 100 % | 4 lag à 0,2 mm. Gir jevnt lys. Bruk 0,2 mm første lag, ev. brim/lim mot vridning; lav viftehastighet. |

Tips:
- Veggtykkelsen er 2,4 mm (= 6 linjer à 0,4 mm / 12 lag), 0,8 mm diffuser = 4 lag.
- Sett «elefantfot-kompensasjon» til ca. 0,1–0,15 mm hvis bakplaten blir trang. Pass-toleransen `tol` (0,2 mm pr. side) kan endres øverst i filen.
- Rens første lag fint på frontpanelet – det er den synlige siden.

## Montering (rekkefølge)

1. **Frontpanel** ligger med baksiden opp. Legg **diffuserplaten** i lommen på baksiden (de fire utsparingene passer rundt klossene).
2. Trykk **hovedkroppen** ned over klossene. Klossene har små press-ribber (0,2 mm), så den sitter stramt; en dråpe lim gjør den permanent.
   Diffuseren klemmes fast mellom kroppens kant og frontpanelet.
3. Lim **LED-stripen** (5 V USB, WS2812B 10 mm bred) på den skrå 45°-flaten rundt innsiden (flanken som vender mot fronten). Stripen tåler ikke de krappe hjørnene: kutt den ved kuttmerkene (kobberpadene) og koble de fire rette strekkene sammen med korte ledninger.
   Avstand LED → diffuser er **16 mm** (variabel `led_gap`, kravet er ≥ 15 mm – filen stopper med `assert` hvis du går under).
4. Før USB-kabelen ut gjennom **12 × 8 mm**-hullet i **bakplaten**, koble til stripen.
5. Trykk **bakplaten** på plass: pluggringen glir inn med 0,2 mm slark og klikker i V-ribbene (topp, bunn og sider). For å bytte LED: lirk med en flat skrutrekker i de to 45°-sporene i bunnkanten bak.

Eksplodert visning: `previews/03_eksplodert.png`. Snitt (LED-liste, diffuser, klikk): `previews/04_snitt_LED_og_diffuser.png`.

**Strøm:** 700 mm WS2812B (60 LED/m) ≈ 42 LED; maks ca. 2,5 A ved full hvit. Begrens lysstyrken i kontrolleren
(~30–50 %) for en vanlig USB-lader/powerbank. Boksen står stødig på flat bunn.

## Viktigste variabler (øverst i `hugo_lysboks.scad`)

`W`, `H`, `D` (ytre mål) · `wall` (2,4) · `tol` (0,2) · `corner_r` · `diff_t` (0,8) · `led_w` (10) · `led_gap` (16) ·
`usb_w`/`usb_h` (12/8) · `usb_x`, `usb_z_from_bottom` · motiv: `frame_r`, `scene_sc`, `letter_h`, `stroke_w`, `bridge_w`.

## Kontroller som er kjørt

- **Ingen løse «øyer»:** frontpanelets plastflate er ett sammenhengende område (`tools/check_islands.py` på
  `previews/10_frontpanel_lyst_forfra.png`). Rammens lysspalte holdes av 6 broer (2,4 mm), og midten i **O** holdes av to 2,0 mm broer
  (stensil-O). Den eneste frittstående delen i motivet (sola) er et hull, ikke en øy. Tynneste steg er ≥ 1,6 mm.
- **Overheng:** `tools/check_stl.py` – 0 flater brattere enn 45° (LED-listen, klikk-ribbene og spor har ca. 43° flanker) → ingen support.
- **Mål:** frontpanel 200 × 160 × 11,2 · hovedkropp 200 × 160 × 54,4 · bakplate 200 × 160 × 8,4 · diffuser 196,8 × 156,8 × 0,8 mm. Montert dybde 60 mm.
- **Passform:** programmatisk kollisjonstest – ingen overlapp mellom delene bortsett fra de bevisste press-ribbene (ca. 30 mm³ totalt).
- Alle STL-filer er lukkede legemer (hver kant delt av to flater).

## Forhåndsvisninger

| | |
|---|---|
| `01_montert_forfra.png` | `02_montert_bakfra.png` |
| `03_eksplodert.png` | `04_snitt_LED_og_diffuser.png` |
| `05_frontpanel_forfra.png` | `06_frontpanel_bakside.png` |
| `07_hovedkropp.png` | `08_bakplate_innside.png` |
| `09_diffuser.png` | `10_frontpanel_lyst_forfra.png` (slik det lyser) |
