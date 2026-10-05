// =====================================================================
//  iPhone 17e – TPU-deksel med hevet relieff (original design)
//  Venstre halvdel (sett bakfra): magi – åpen gammel bok, måne, stjerner, eliksirflaske
//  Høyre halvdel:                 gresk mytologi – søyler/tempel, laurbærkrans, bølger
//  Ramme rundt kanten:            gresk meander (nøkkelmønster) som binder halvdelene sammen
//  OpenSCAD 2021.01 eller nyere.  Alle mål i mm.
//
//  Del velges med  -D 'part="..."' :
//    case_print   deksel + relieff i ett legeme (STL for vanlig print)
//    base_print   kun dekselet (uten relieff)      } samme koordinater – for AMS / flerfarge
//    relief_print kun relieffet                    }
//    film_print   valgfri tynn avtrekksfilm som bærer bakplaten (se README)
//    preview_*    forhåndsvisninger
//
//  KOORDINATER (printretning): baksiden ned mot byggeplaten (z = 0), åpningen opp.
//  Sett ovenfra = sett forfra på telefonen: +X = telefonens høyre side (skjermsiden), +Y = toppen.
//  Relieffet tegnes «sett bakfra» (u = høyre, v = opp) og speilvendes automatisk.
// =====================================================================

part = "case_print";

// ---------------------------------------------------------------------
//  TELEFON – OFFISIELLE MÅL (Apple, iPhone 17e tekniske spesifikasjoner)
// ---------------------------------------------------------------------
phone_h = 146.7;   // høyde
phone_w = 71.5;    // bredde
phone_t = 7.80;    // tykkelse

// ---------------------------------------------------------------------
//  TELEFON – ESTIMATER (IKKE offisielle! Mål selv med skyvelære og juster)
//  Basert på at 17e har samme kroppsform som iPhone 16e/14 (hakk, én kamera).
// ---------------------------------------------------------------------
phone_r = 10.0;    // ytre hjørneradius på telefonen   (USIKKER)

// Kamera (sett BAKFRA, målt fra telefonens øvre venstre hjørne)  (USIKKER)
// Én rektangulær åpning som dekker linse + blits.
cam_x = 19.5;      // midten av åpningen, mm fra venstre kant
cam_y = 17.5;      // midten av åpningen, mm fra toppkanten
cam_w = 32;        // åpningens bredde
cam_h = 26;        // åpningens høyde
cam_r = 9;         // hjørneradius på åpningen

// Sideknapper: [avstand fra toppkanten til knappens midte, knappens lengde]  (USIKKER)
// Venstre side (sett forfra): Action-knapp, volum opp, volum ned.  Høyre side: på/av.
btn_action = [24.0, 9.0];
btn_volup  = [38.5, 14.5];
btn_voldn  = [55.0, 14.5];
btn_power  = [45.0, 21.0];
btn_extra  = 1.5;  // ekstra membran-lengde på hver ende
btn_zh     = 4.4;  // høyde på knappe-lommen (z)

// Bunn (sett forfra): USB-C midt på, høyttaler-/mikrofonåpninger på hver side  (USIKKER)
usb_w = 13.0;  usb_h = 6.0;                // USB-C-åpning
spk_x = 17.5;  spk_d = 2.4;  spk_pitch = 3.4; // 4 dråpehull pr. side (høyttaler/mikrofon), avstand fra midten

// ---------------------------------------------------------------------
//  DEKSEL
// ---------------------------------------------------------------------
tol      = 0.3;    // toleranse (total slark pr. mål, fordelt likt = tol/2 pr. side)
wall     = 1.5;    // veggtykkelse
back_t   = 1.5;    // bakplate-tykkelse (uten relieff)
lip_over = 1.0;    // kanten går 1 mm inn over skjermen
lip_t    = 0.8;    // tykkelse på kantens topp (over 45°-skråningen)
membrane = 0.6;    // tykkelse på fleksible knappetrykk (veggen tynnes ut innvendig)

// ---------------------------------------------------------------------
//  RELIEFF
// ---------------------------------------------------------------------
relief_h    = 0.6;       // relieffhøyde
relief_mode = "raised";  // "raised" = hevet (som bestilt) | "inlay" = flatt innlegg (printes helt uten støtte)
cam_margin  = 1.5;       // relieffet holdes så langt unna kameraåpningen
meander_s   = 0.8;       // strekbredde i meander (bånd = 5 × s)
meander_m   = 4.0;       // avstand fra ytterkant til meander-båndet
art_inset   = 9.5;       // motivet holdes innenfor dette fra ytterkanten

film_t = 0.4;  film_gap = 0.2;   // avtrekksfilm (valgfri støtte-erstatning)

// ------------------------------ Avledet ------------------------------
$fn = 48;
ts   = tol/2;
cw   = phone_w/2 + ts;               // halv innvendig bredde
ch   = phone_h/2 + ts;               // halv innvendig høyde
Wo   = phone_w + 2*(ts + wall);      // ytre bredde
Ho   = phone_h + 2*(ts + wall);      // ytre høyde
Ro   = phone_r + ts + wall;          // ytre hjørneradius
plate_z0 = (relief_mode == "raised") ? relief_h : 0;   // bakplatens underside
z_floor  = plate_z0 + back_t;
phone_back = z_floor + ts;
phone_top  = phone_back + phone_t;
z_slope0 = phone_top - ts + 0.1;     // 45°-skråningen starter her (ved veggen)
z_tip    = z_slope0 + ts + lip_over; // ... og slutter her (ved kantens innside)
z_top    = z_tip + lip_t;
z_mid    = phone_back + phone_t/2;   // knapper/USB sitter midt på tykkelsen

// --------------------------- Hjelpemoduler ----------------------------
module rrect(w, h, r) { offset(r = r) square([w - 2*r, h - 2*r], center = true); }
module slice(z, w, h, r) { translate([0, 0, z]) linear_extrude(0.01) rrect(w, h, r); }
module seg(a, b, w) { hull() { translate(a) circle(d = w, $fn = 16); translate(b) circle(d = w, $fn = 16); } }
module sseg(a, b, w) { hull() { translate(a) square(w, center = true); translate(b) square(w, center = true); } }
module pstroke(pts, w) { for (i = [0:len(pts) - 2]) seg(pts[i], pts[i + 1], w); }
function earc(c, rx, ry, a0, a1, n = 24) =
    [for (i = [0:n]) let(a = a0 + (a1 - a0)*i/n) [c[0] + rx*cos(a), c[1] + ry*sin(a)]];
module blob(c, rx, ry, a = 0) { translate(c) rotate(a) scale([rx, ry]) circle(r = 1, $fn = 28); }
module star4(r, k = 0.26) polygon([for (i = [0:7]) let(rr = (i % 2 == 0) ? r : r*k) [rr*cos(i*45 + 90), rr*sin(i*45 + 90)]]);
module star5(r) polygon([for (i = [0:9]) let(rr = (i % 2 == 0) ? r : r*0.42) [rr*cos(i*36 + 90), rr*sin(i*36 + 90)]]);

// ========================= RELIEFF (sett bakfra) =========================
// ---------- Venstre halvdel: magi ----------
module moon() { difference() { circle(r = 7.2); translate([3.4, 1.6]) circle(r = 6.2); } }

module book() {          // åpen bok, bredde ca. 25
    pages = [[[-0.7, -7.2], [-11.4, -5.6], [-11.4, 6.2], [-6, 8.2], [-0.7, 6]],
             [[0.7, -7.2], [11.4, -5.6], [11.4, 6.2], [6, 8.2], [0.7, 6]]];
    difference() {
        union() {
            for (p = pages) polygon(p);
            // omslag
            difference() {
                union() for (p = pages) offset(delta = 1.6) polygon(p);
                union() for (p = pages) offset(delta = 0.7) polygon(p);
            }
        }
        // tekstlinjer på venstre side
        for (i = [0:3]) translate([-10, -3.6 + i*2.6]) rotate(3) square([8.2 - (i == 3 ? 3 : 0), 0.55]);
        // liten stjerne på høyre side
        translate([6, 1.2]) star4(3.0);
        for (i = [0:1]) translate([2.4, -4.8 - i*0]) rotate(-3) square([7.2, 0.55]);
    }
}

module potion() {        // liten eliksirflaske med glitter
    difference() {
        union() {
            difference() { circle(r = 7.2); circle(r = 6.0); }                      // glasskant
            intersection() {                                                         // eliksir
                circle(r = 6.0);
                translate([-8, -8]) square([16, 8.4]);
            }
            translate([-2.3, 5.6]) square([4.6, 5.8]);                              // hals
            translate([-3.4, 10.8]) square([6.8, 1.5]);                             // leppe
            translate([-1.9, 12.8]) square([3.8, 3.0]);                             // kork
        }
        translate([-1.2, 6.6]) square([2.4, 4.8]);                                  // åpning i halsen
        for (p = [[-2.8, -3.2], [2.6, -1.8], [0.2, -4.6]]) translate(p) star4(1.5);    // glitter i væsken
        for (p = [[-3.6, -1.0], [3.8, -4.0], [-0.4, -1.4]]) translate(p) circle(r = 0.45, $fn = 10);
    }
    for (p = [[-3, 2.4, 1.5], [3.2, 3.2, 1.1]]) translate([p[0], p[1]]) star4(p[2]);   // glitter i luften over væsken
}

module left_art() {
    translate([-15, 28.5]) rotate(12) moon();
    translate([-24.5, 36.5]) star5(2.3);
    translate([-4.5, 33.5]) star4(2.6);
    translate([-7.5, 21]) star5(1.7);
    translate([-23, 20.5]) star4(2.3);
    translate([-26, 9.5]) star4(1.6);
    translate([-14, -6]) book();
    translate([-14, 7.8]) star4(2.0);
    translate([-14, 17]) star4(1.2);
    translate([-14, -46]) potion();
    translate([-24, -34.5]) star4(1.6);
    translate([-4.5, -32]) star4(1.9);
    translate([-24.5, -56]) star4(1.3);
    translate([-4, -52]) star4(1.5);
    translate([-4, -20]) star4(1.2);
    translate([-25, -20]) star4(1.4);
}

// ---------- Høyre halvdel: gresk mytologi ----------
module column(h) {
    difference() {
        union() {
            translate([-1.9, 0.9]) square([3.8, h - 1.8]);
            translate([-2.7, 0]) square([5.4, 1.0]);
            translate([-2.7, h - 1.5]) square([5.4, 1.5]);
        }
        for (x = [-0.9, 0.9]) translate([x - 0.25, 1.6]) square([0.5, h - 3.6]);   // fluting
    }
}
module temple() {                  // bunnsenter i (0,0)
    translate([-13, 0]) square([26, 1.8]);
    translate([-11.5, 1.8]) square([23, 1.8]);
    for (x = [-8.5, 0, 8.5]) translate([x, 3.6]) column(16.4);
    translate([-12, 20.4]) square([24, 3.0]);
    difference() {
        polygon([[-13, 23.8], [13, 23.8], [0, 31.5]]);
        polygon([[-9.6, 25.2], [9.6, 25.2], [0, 29.6]]);
    }
    translate([0, 26.4]) circle(r = 1.0, $fn = 16);
}
module wreath() {                  // laurbærkrans, midt i (0,0), åpen øverst
    R = 9.0;
    for (s = [-1, 1]) {
        pstroke(earc([0, 0], R, R, 90 + s*18, 90 + s*172, 20), 0.9);
        for (k = [0:9]) {
            th = 90 + s*(22 + k*15.5);
            p = [R*cos(th), R*sin(th)];
            tan = th + s*90;
            translate(p) {
                rotate(tan + s*38) translate([2.0, 0]) blob([0, 0], 3.1, 1.25);
                rotate(tan - s*38) translate([2.0, 0]) blob([0, 0], 2.8, 1.15);
            }
        }
    }
    translate([0, -R]) { blob([-2.6, -0.4], 2.8, 1.3, 25); blob([2.6, -0.4], 2.8, 1.3, -25); circle(r = 1.1, $fn = 12); }
    translate([0, 0]) star5(3.4);
}
module waves() {                   // bølgelinjer i 0 <= x <= 27, rundt (0,0)
    for (k = [0:7]) translate([0, -k*7])
        pstroke([for (x = [-1:0.7:28.5]) [x, 2.4*sin((x + k*1.3)*360/8.7)]], 1.4);
}
module right_art() {
    translate([14.5, 53]) wreath();
    translate([14.5, 3.0]) temple();
    translate([0, -6]) intersection() { translate([1.2, -64]) square([26.6, 70]); translate([0, 0]) waves(); }
}

module art_all() { left_art(); right_art(); }

// ---------- Gresk meander (nøkkelmønster) som ramme ----------
mb = 5*meander_s;                       // båndhøyde
module key_row(Ls) {                    // lokalt: x langs siden, y innover fra ytterkant
    n  = floor((Ls/meander_s - 1)/6);
    sx = Ls/(6*n + 1);
    w  = meander_s;
    sseg([0.5*sx, 0.5*w], [(6*n + 0.5)*sx, 0.5*w], w);                // skinne ytterst
    for (i = [0:n - 1]) {
        o = 6*i*sx;
        pts = [[0.5*sx, 0.5*w], [0.5*sx, 4.5*w], [4.5*sx, 4.5*w], [4.5*sx, 2.5*w], [2.5*sx, 2.5*w]];
        for (j = [0:len(pts) - 2]) sseg([o + pts[j][0], pts[j][1]], [o + pts[j + 1][0], pts[j + 1][1]], w);
    }
    sseg([(6*n + 0.5)*sx, 0.5*w], [(6*n + 0.5)*sx, 4.5*w], w);          // avslutning
}
module key_corner() {
    difference() { square(mb, center = true); square(mb - 2*meander_s, center = true); }
    square(meander_s, center = true);
}
module meander_frame() {
    Lh = Wo - 2*(meander_m + mb);
    Lv = Ho - 2*(meander_m + mb);
    translate([-Lh/2, Ho/2 - meander_m]) mirror([0, 1]) key_row(Lh);                       // topp
    translate([-Lh/2, -Ho/2 + meander_m]) key_row(Lh);                                    // bunn
    multmatrix([[0, 1, 0, -Wo/2 + meander_m], [1, 0, 0, -Lv/2], [0, 0, 1, 0], [0, 0, 0, 1]]) key_row(Lv);   // venstre
    multmatrix([[0, -1, 0, Wo/2 - meander_m], [1, 0, 0, -Lv/2], [0, 0, 1, 0], [0, 0, 0, 1]]) key_row(Lv);   // høyre
    for (sx = [-1, 1], sy = [-1, 1])
        translate([sx*(Wo/2 - meander_m - mb/2), sy*(Ho/2 - meander_m - mb/2)]) key_corner();
}

// ---------- Kamera ----------
module cam2d_back() { translate([-phone_w/2 + cam_x, phone_h/2 - cam_y]) rrect(cam_w, cam_h, cam_r); }

module relief2d_back() {
    difference() {
        union() {
            meander_frame();
            intersection() { art_all(); rrect(Wo - 2*art_inset, Ho - 2*art_inset, max(Ro - art_inset, 1)); }
        }
        offset(delta = cam_margin) cam2d_back();       // dekker aldri kameraåpningen
    }
}
module relief2d()  { mirror([1, 0]) relief2d_back(); }  // til modellkoordinater (sett forfra)
module cam2d()     { mirror([1, 0]) cam2d_back(); }

// ============================= DEKSEL ===================================
module cavity() {
    r_c = phone_r + ts;
    translate([0, 0, z_floor - 0.001]) linear_extrude(z_slope0 - z_floor + 0.002) rrect(2*cw, 2*ch, r_c);
    hull() {                                               // 45° skråning under kanten
        slice(z_slope0, 2*cw, 2*ch, r_c);
        slice(z_tip, phone_w - 2*lip_over, phone_h - 2*lip_over, max(phone_r - lip_over, 1));
    }
    translate([0, 0, z_tip - 0.001]) linear_extrude(z_top - z_tip + 1)
        rrect(phone_w - 2*lip_over, phone_h - 2*lip_over, max(phone_r - lip_over, 1));
}

// Fleksibelt knappetrykk: veggen tynnes innenfra til 'membrane'; taket er 45° (ingen støtte)
module button_pocket(side, spec) {
    L = spec[1] + 2*btn_extra;
    yc = phone_h/2 - spec[0];
    d = wall - membrane;
    zlo = z_mid - btn_zh/2;  zhi = z_mid + btn_zh/2;
    translate([0, yc + L/2, 0]) rotate([90, 0, 0]) linear_extrude(L)
        polygon([[side*(cw - 0.05), zlo], [side*(cw + d), zlo], [side*(cw + d), zhi - d - 0.15], [side*(cw - 0.05), zhi]]);   // tak ca. 42° fra vertikalen
}
// Åpning i bunnveggen (tak avfaset 45° -> ingen støtte). USB-C: sekskant; høyttaler: dråpeformede hull
module bottom_slot(x, w, h) {
    c = 0.9*h;  z0 = z_mid - h/2;  z1 = z_mid + h/2;
    translate([0, -ch + 0.5, 0]) rotate([90, 0, 0]) linear_extrude(wall + 1.5)
        polygon([[x - w/2, z0], [x + w/2, z0], [x + w/2, z1 - c], [x + w/2 - c, z1], [x - w/2 + c, z1], [x - w/2, z1 - c]]);
}
module bottom_tear(x, d) {
    translate([0, -ch + 0.5, 0]) rotate([90, 0, 0]) linear_extrude(wall + 1.5)
        hull() { translate([x, z_mid]) circle(d = d, $fn = 20); translate([x, z_mid + d/2*1.4142]) square(0.01, center = true); }
}
module case_solid() {
    difference() {
        translate([0, 0, plate_z0]) linear_extrude(z_top - plate_z0) rrect(Wo, Ho, Ro);
        cavity();
        translate([0, 0, -1]) linear_extrude(z_floor + 1.5) cam2d();                   // kamera
        for (b = [btn_action, btn_volup, btn_voldn]) button_pocket(-1, b);            // venstre side
        button_pocket(1, btn_power);                                                  // høyre side
        bottom_slot(0, usb_w, usb_h);                                                  // USB-C
        for (s = [-1, 1], k = [-1.5:1:1.5]) bottom_tear(s*spk_x + k*spk_pitch, spk_d);   // høyttaler/mikrofon
        if (relief_mode == "inlay") translate([0, 0, -0.01]) linear_extrude(relief_h + 0.01) relief2d();
    }
}
module relief3d() { linear_extrude(relief_h) relief2d(); }

// Avtrekksfilm: tynn plate under bakplaten (0,2 mm luft) som erstatter slicer-støtte
module film() {
    linear_extrude(film_t) difference() {
        offset(delta = -0.6) rrect(Wo, Ho, Ro);
        offset(delta = 0.5) relief2d();
        offset(delta = 0.5) cam2d();
    }
}

// ============================= FORHÅNDSVISNING ==========================
module phone_ghost() translate([0, 0, phone_back]) linear_extrude(phone_t) rrect(phone_w, phone_h, phone_r);

if (part == "case_print") { case_solid(); relief3d(); }
else if (part == "base_print") case_solid();
else if (part == "relief_print") relief3d();
else if (part == "film_print") film();
else if (part == "preview") { color([0.42, 0.5, 0.72]) case_solid(); color([0.96, 0.78, 0.28]) relief3d(); }
else if (part == "section_btn") difference() { union() { case_solid(); relief3d(); } translate([-100, phone_h/2 - btn_volup[0], -10]) cube([200, 200, 50]); }
else if (part == "section_usb") difference() { union() { case_solid(); relief3d(); } translate([0, -200, -10]) cube([200, 200 + 0, 50]) ; }
else if (part == "section_len") difference() { union() { case_solid(); relief3d(); } translate([-200, -200, -10]) cube([200, 400, 50]); }
else if (part == "section_btnpocket") intersection() {     // tverrsnitt gjennom volum-opp-knappen, venstre vegg
    difference() { union() { case_solid(); relief3d(); } translate([-100, phone_h/2 - btn_volup[0], -10]) cube([200, 200, 50]); }
    translate([-cw - wall - 2, -400, -5]) cube([14, 800, 30]); }
// 2D-snitt (eksporteres som SVG): transversalt ved volum-opp, og langs midten
else if (part == "xsec_btn") projection(cut = true) rotate([90, 0, 0]) translate([0, -(phone_h/2 - btn_volup[0]), 0]) { case_solid(); relief3d(); }
else if (part == "xsec_len") projection(cut = true) rotate([90, 0, 90]) { case_solid(); relief3d(); }
else if (part == "clash_phone") intersection() { case_solid(); phone_ghost(); }
else if (part == "preview_phone") { color([0.2, 0.3, 0.55, 1]) case_solid(); color([0.95, 0.75, 0.25]) relief3d(); color([1, 1, 1, 0.35]) phone_ghost(); }
else { case_solid(); relief3d(); }
