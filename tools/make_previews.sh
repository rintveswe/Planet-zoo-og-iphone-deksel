#!/bin/bash
# Lager PNG-forhåndsvisninger (krever openscad + xvfb). Kjør fra prosjektroten.
mkdir -p previews
r() { # part outfile rotx,rotz  [dist] [size]
  xvfb-run -a openscad -D "part=\"$1\"" --camera=0,0,0,$3,700 --imgsize=${5:-1400,1000} --colorscheme=Tomorrow \
     --autocenter --viewall --render ${6:-} -o "previews/$2" hugo_lysboks.scad 2>&1 | grep -E "ERROR|WARN"
  convert "previews/$2" -trim +repage -bordercolor '#f9f9f9' -border 40 "previews/$2"
}
r assembly   01_montert_forfra.png            "70,0,335"
r assembly   02_montert_bakfra.png            "70,0,205"
r exploded   03_eksplodert.png                "75,0,320"
r section    04_snitt_LED_og_diffuser.png     "90,0,-90" 700 2400,2400 --projection=o
r front      05_frontpanel_forfra.png         "90,0,0"
r front      06_frontpanel_bakside.png        "72,0,160"
r body       07_hovedkropp.png                "110,0,160"
r back       08_bakplate_innside.png          "72,0,335"
r diffuser   09_diffuser.png                  "90,0,0"
true
# Rett forfra med lys bak (viser hva som lyser gjennom) – brukes også av tools/check_islands.py
xvfb-run -a openscad -D 'part="lit"' --camera=0,0,0,90,0,0,420 --projection=o --imgsize=1400,1120 --colorscheme=Tomorrow -o previews/10_frontpanel_lyst_forfra.png hugo_lysboks.scad 2>&1 | grep -E "ERROR|WARN"
true
