#!/bin/bash
# PNG-forhåndsvisninger for iPhone 17e-dekselet. Kjør fra iphone17e/ (krever openscad, xvfb, imagemagick, python3+pillow).
mkdir -p previews
r() { # part file rot size [extra]
  xvfb-run -a openscad -D "part=\"$1\"" --camera=0,0,0,$3,400 --imgsize=$4 --colorscheme=Tomorrow --autocenter --viewall ${5:-} \
     -o "previews/$2" iphone17e_deksel.scad 2>&1 | grep -E "ERROR|WARN"
  convert "previews/$2" -trim +repage -bordercolor '#f9f9f9' -border 40 "previews/$2"
}
r preview 01_forfra.png            "35,0,-20"  1400,1600
r preview 02_bakfra.png            "180,0,180" 1000,1900 --projection=o
r preview 03_fra_siden.png         "78,0,90"   1800,800
r preview 04_bunn_USB_hoyttaler.png "75,0,180" 1600,800
r preview 05_skraa_bakfra.png      "150,0,205" 1400,1600
r relief_print 06_relieff_alene.png "180,0,180" 1000,1900 --projection=o
openscad -D 'part="xsec_btn"' -o /tmp/xbtn.svg iphone17e_deksel.scad 2>/dev/null
openscad -D 'part="xsec_len"' -o /tmp/xlen.svg iphone17e_deksel.scad 2>/dev/null
python3 ../tools/svg_section.py /tmp/xbtn.svg previews/07_snitt_tverr_knapp_og_kant.png 30 "Tverrsnitt ved volum-opp: bakplate+relieff nederst, fleksibel knappemembran (venstre), 45-graders kant (z opp, 5 mm rutenett)"
python3 ../tools/svg_section.py /tmp/xlen.svg previews/08_snitt_lengde.png 14 "Lengdesnitt midt (USB-C-åpning til høyre/venstre, kamera)"
true
