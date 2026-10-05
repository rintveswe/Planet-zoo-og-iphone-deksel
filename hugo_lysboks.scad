// =====================================================================
//  Parametrisk lysboks med dyrepark-tema (original design)
//  Elefant, giraff og to palmer i sirkulær ramme (+ valgfri logo-SVG under).
//  OpenSCAD 2021.01 eller nyere.  Alle mål i mm.
//
//  Del velges med  -D 'part="..."'  :
//    front_print | body_print | back_print | diffuser_print   (STL, printretning)
//    assembly | exploded | section | lit                       (forhåndsvisning)
//    front | body | back | diffuser                            (enkeltdeler i monteringsretning)
//
//  Koordinater (montert boks): X = bredde, Z = høyde, Y = dybde.
//  Frontflaten ligger i Y=0, boksen går mot +Y.  Betrakter står på -Y-siden.
// =====================================================================

part = "assembly";

// ---------------------------- Hovedmål --------------------------------
W = 200;          // ytre bredde  (X)
H = 160;          // ytre høyde   (Z)
D = 60;           // ytre dybde   (Y), frontplate + kropp + bakplate
wall = 2.4;       // veggtykkelse
corner_r = 14;    // ytre hjørneradius (LED-stripen får myke svinger)

// --------------------------- Toleranser -------------------------------
tol = 0.2;        // slark pr. side for alle pass-flater (bakplate/frontklosser/diffuser)

// ----------------------------- Frontpanel -----------------------------
face_t = 2.4;     // tykkelse på selve frontflaten (her skjæres motivet)
diff_t = 0.8;     // diffuserplate-tykkelse (hvit PLA)
diff_overlap = 0.8; // diffuseren går så langt inn under kroppens veggkant (klemmes fast)

// ------------------------------- Lys ----------------------------------
led_w = 10;       // LED-stripens bredde (WS2812B 10 mm)
led_gap = 16;     // avstand diffuser (bakside) -> nærmeste LED-kant. Må være >= 15
led_min_gap = 15; // krav
led_tilt_ridge = true; // 45° list som vinkler LED-stripen mot diffuseren

// ----------------------------- Bakplate -------------------------------
back_t = 2.4;     // plate-tykkelse
plug_h = 6;       // hvor langt plugg-ringen går inn i kroppen
plug_wall = 2.0;  // veggtykkelse på plugg-ringen
click_h = 0.6;    // høyde på klikk-ribbe (45°-flanker)
click_len = 30;   // lengde på klikk-ribbe pr. side
usb_w = 12;       // USB-hull bredde
usb_h = 8;        // USB-hull høyde
usb_x = 0;        // USB-hull posisjon (X fra senter)
usb_z_from_bottom = 25; // USB-hull senter over bunnen

// -------------------------- Frontklosser ------------------------------
loc_len = 24;     // klossens lengde langs veggen
loc_t   = 2.0;    // klossens tykkelse inn fra veggen
loc_depth = 8;    // hvor langt klossene går inn i kroppen
loc_x = 50;       // klossposisjon langs topp/bunn (±)
loc_z = 35;       // klossposisjon langs sidene (±)
rib_crush = 0.2;  // press-ribbe: overlapp mot veggen

// ------------------------- Motiv (frontpanel) -------------------------
logo_file = "";   // sti til en SVG du har lov til å bruke (tom = ingen logo, scenen fyller panelet)
logo_w    = 110;  // logoens bredde
logo_z    = -58;  // logoens senter (Z) når den brukes
big       = (logo_file == "");     // uten logo: stor scene midt på panelet
frame_cz  = big ? 0 : 16;         // sirkelramme senter (Z)
frame_r   = big ? 68 : 57;        // sirkelramme ytre radius
frame_slit = 3;   // bredde på lysspalten i rammen
frame_bridges = 6;   // antall broer over spalten
bridge_w  = 2.4;  // bredde på broer (rammen)
scene_r   = big ? 63 : 52;   // motivet klippes til denne radiusen
ground_z  = -27;  // bakkenivå i motivet (før skalering)
scene_sc  = big ? 1.22 : 1.0; // skalering av motivet
scene_dz  = big ? -6 : -5;  // forskyvning av motivet i Z (relativt sirkelsenter)


// ------------------------------ Avledet -------------------------------
$fn = 48;
Wc = W - 2*wall;  Hc = H - 2*wall;  Rc = corner_r - wall;
front_t = face_t + diff_t;               // frontplatens totale tykkelse
body_y0 = front_t;                        // kroppens fremkant
body_y1 = D - back_t;                     // kroppens bakkant
body_L  = body_y1 - body_y0;
diff_w = Wc + 2*diff_overlap;  diff_h = Hc + 2*diff_overlap;
ridge_p = led_w*cos(45);                  // innoverstikk på LED-listen
led_y0  = front_t + led_gap;              // LED-listens start (nærmest diffuser)
ridge_dy = ridge_p*1.05;                  // litt slakere enn 45° => trygt support-fritt
led_ridge_ym = led_y0 + ridge_dy;
led_y1  = led_y0 + 2*ridge_dy;
Wp = Wc - 2*tol;  Hp = Hc - 2*tol;  Rp = Rc - tol;     // plugg-ring ytterkant
click_y = body_y1 - plug_h/2 - 0.4;       // klikk-ribbens Y-posisjon

assert(led_gap >= led_min_gap, "LED for nær diffuser (< 15 mm)");
assert(led_y1 < body_y1 - plug_h - 2, "LED-listen kolliderer med bakplatens plugg");
assert(W <= 256 && H <= 256, "Passer ikke på 256 mm byggeplate");

// --------------------------- Hjelpemoduler ----------------------------
module rrect(w, h, r) { offset(r = r) square([w - 2*r, h - 2*r], center = true); }
// Ekstruder 2D (x,z) fra y0 og h mm mot +Y
module xz_extrude(y0, h) { translate([0, y0 + h, 0]) rotate([90, 0, 0]) linear_extrude(h) children(); }

module seg(a, b, w) { hull() { translate(a) circle(d = w, $fn = 24); translate(b) circle(d = w, $fn = 24); } }
module pstroke(pts, w) { for (i = [0:len(pts) - 2]) seg(pts[i], pts[i + 1], w); }
function earc(c, rx, ry, a0, a1, n = 36) =
    [for (i = [0:n]) let(a = a0 + (a1 - a0)*i/n) [c[0] + rx*cos(a), c[1] + ry*sin(a)]];

// Valgfri logo (SVG) under scenen – se logo_file øverst
module logo_slot() {
    if (logo_file != "") translate([0, logo_z]) resize([logo_w, 0], auto = true) import(logo_file, center = true);
}

// ------------------------ 2D: dyrepark-scene --------------------------
module blob(c, rx, ry, a = 0) { translate(c) rotate(a) scale([rx, ry]) circle(r = 1, $fn = 40); }
function bez(p0, p1, p2, t) = (1-t)*(1-t)*p0 + 2*(1-t)*t*p1 + t*t*p2;
// Avsmalnende strek langs kvadratisk bezier
module tstroke(p0, p1, p2, w0, w1, n = 14) {
    for (i = [0:n-1]) hull() {
        translate(bez(p0, p1, p2, i/n))     circle(d = w0 + (w1 - w0)*i/n, $fn = 20);
        translate(bez(p0, p1, p2, (i+1)/n)) circle(d = w0 + (w1 - w0)*(i+1)/n, $fn = 20);
    }
}

module elephant() {
    // kropp, hode, ører
    blob([-20, -12], 14.5, 10.5);
    blob([-5, -6.5], 8, 7.5);
    blob([-9.5, -5], 5.2, 8, -8);          // øre
    // bein
    for (x = [-31, -23.6, -14.5, -7.1]) translate([x - 2.3, ground_z - 2]) square([4.6, -12 - ground_z + 2]);
    // snabel (hevet, med krøll)
    tstroke([-1.5, -8.5], [14, -12], [12, 5], 6.4, 2.8, 18);
    tstroke([12, 5], [11, 9.5], [7.8, 8.2], 2.8, 2.6, 8);
    // støttann
    pstroke([[0.5, -10.5], [4.5, -13.5]], 1.7);
    // hale
    tstroke([-34, -9], [-38, -12], [-36.5, -19], 2.4, 2.2, 6);
}

module giraffe() {
    blob([24.5, -10.5], 9.2, 5.6, -4);                         // kropp
    for (x = [17, 21.6, 27.6, 32]) translate([x - 1.4, ground_z - 2]) square([2.8, -13 - ground_z + 2]);
    tstroke([30, -9], [31.5, 6], [35.5, 21], 8, 4.4, 14);      // hals
    blob([38.8, 25.2], 6.6, 3.1, -18);                         // hode + snute
    pstroke([[35.8, 27], [35.2, 31.4]], 1.9);                  // ossikler
    pstroke([[38, 28.2], [39, 32]], 1.9);
    translate([35.2, 31.8]) circle(d = 2.9, $fn = 16);
    translate([39.1, 32.4]) circle(d = 2.9, $fn = 16);
    blob([33.2, 26.4], 2.6, 1.3, 35);                          // øre
    tstroke([16, -8], [13, -12], [14.2, -19], 2.3, 2.2, 6);    // hale
}

// Palme: stamme (bøyd) + bladkrone. dir = +1 (blader vendt utover mot høyre) / -1
module palm(base, crown, bend, dir = 1, k = 1, mask = [0, 1, 2, 3, 4, 5, 6]) {
    tstroke(base, [(base[0] + crown[0])/2 + bend, (base[1] + crown[1])/2 - 4], crown, 4.6, 3.0, 16);
    translate(crown) {
        blob([0, 0], 3.4, 3.4);
        // blader: [ctrl_dx, ctrl_dz, end_dx, end_dz]
        fr = [[-7, 9, -17, 1], [-3, 13, -10, 11], [3, 14, 5, 13.5], [8, 12, 15, 8.5], [10, 6, 20, -3], [-9, 4, -19, -8], [-1, 6, -4, -10]];
        for (i = mask) let(f = fr[i])
            tstroke([0, 0], k*[dir*f[0], f[1]], k*[dir*f[2], f[3]], 4.4*sqrt(k), 0.9, 12);
    }
}

module grass(p) { translate(p) for (a = [-28, 0, 28]) rotate(a) translate([0, 2.6]) scale([1, 1]) polygon([[-1.1, -2.7], [1.1, -2.7], [0.1, 3.4]]); }
module scene_raw() {
    palm([-43, ground_z - 2], [-36, 13], -2.5, 1);       // venstre palme
    palm([44, ground_z - 2], [41.5, 1], 1.5, -1, 0.68, [0, 1, 2, 5, 6]);          // høyre palme (speilvendt)
    elephant();
    giraffe();
    translate([-8, 41]) circle(r = 4.4, $fn = 32);      // sol
    for (x = [-1.5, 8.5, 38.5]) grass([x, ground_z + 0.5]);    // gresstotter
}
module ground2d() {
    polygon(concat([for (x = [-70:5:70]) [x, ground_z + 1.8*sin(x*4.5 + 40)]], [[70, -120], [-70, -120]]));
}
module scene() {
    intersection() {
        circle(r = scene_r, $fn = 120);
        translate([0, scene_dz]) scale([scene_sc, scene_sc]) difference() { scene_raw(); ground2d(); }
    }
}
module frame_ring() {
    difference() {
        difference() { circle(r = frame_r, $fn = 140); circle(r = frame_r - frame_slit, $fn = 140); }
        for (i = [0:frame_bridges - 1]) rotate(i*360/frame_bridges + 30)
            translate([frame_r - frame_slit - 1, -bridge_w/2]) square([frame_slit + 2, bridge_w]);
    }
}
// Alt som skjæres ut av frontflaten (2D i plate-koordinater)
module front_cut2d() {
    translate([0, frame_cz]) { scene(); frame_ring(); }
    logo_slot();
}

// ------------------------- 2D: frontklosser ---------------------------
// Klosser langs topp/bunn (x=±loc_x) og sidene (z=±loc_z); inn = vekst innover, ut = forlengelse utover
module loc_rects(inn = 0, ut = 0, len_add = 0) {
    for (sx = [-1, 1], sz = [-1, 1]) {
        translate([sx*loc_x, sz*(Hc/2 - tol - loc_t/2 + (ut - inn)/2)])
            square([loc_len + len_add, loc_t + inn + ut], center = true);
        translate([sx*(Wc/2 - tol - loc_t/2 + (ut - inn)/2), sz*loc_z])
            square([loc_t + inn + ut, loc_len + len_add], center = true);
    }
}
module loc_ribs() {
    rr = tol + rib_crush;       // ribbe stikker ut fra klossens yttervegg til veggen + overlapp
    for (sx = [-1, 1], sz = [-1, 1], k = [-1, 1]) {
        translate([sx*loc_x + k*(loc_len/2 - 4), sz*(Hc/2 - tol + rr/2 - 0.01)]) square([1.2, rr + 0.02], center = true);
        translate([sx*(Wc/2 - tol + rr/2 - 0.01), sz*loc_z + k*(loc_len/2 - 4)]) square([rr + 0.02, 1.2], center = true);
    }
}

// ------------------------------- DELER --------------------------------
module front_panel() {
    difference() {
        union() {
            difference() {
                xz_extrude(0, front_t) rrect(W, H, corner_r);
                xz_extrude(face_t, diff_t + 0.1) rrect(diff_w + 2*tol, diff_h + 2*tol, Rc + diff_overlap);  // diffuserlomme
            }
            xz_extrude(face_t - 0.01, diff_t + loc_depth + 0.01) { loc_rects(); loc_ribs(); }
        }
        xz_extrude(-0.1, face_t + 0.2) front_cut2d();
    }
}

module diffuser() {
    xz_extrude(face_t, diff_t) difference() {
        rrect(diff_w, diff_h, Rc + diff_overlap);
        loc_rects(inn = tol + 0.1, ut = 6, len_add = 2*tol + 0.4);
        // ribbene
        offset(delta = tol + 0.1) loc_ribs();
    }
}

module slice(y, inset) { xz_extrude(y, 0.01) rrect(Wc - 2*inset, Hc - 2*inset, max(Rc - inset, 1)); }
module led_ridge() {
    // Trekantlist (45° begge sider) rundt innsiden; LED-stripen limes på flanken som vender mot fronten.
    // Dens bakre flanke er 45° og dermed support-fri når kroppen printes med bakkanten ned.
    difference() {
        xz_extrude(led_y0, led_y1 - led_y0) rrect(Wc + 0.6, Hc + 0.6, Rc + 0.3);
        // fritt rom = «timeglass» (to avkortede kjegler) -> to separate hull()
        hull() { slice(led_y0, 0); slice(led_ridge_ym, ridge_p); }
        hull() { slice(led_ridge_ym, ridge_p); slice(led_y1 - 0.01, 0); }
    }
}

module body() {
    difference() {
        union() {
            difference() {
                xz_extrude(body_y0, body_L) rrect(W, H, corner_r);
                xz_extrude(body_y0 - 1, body_L + 2) rrect(Wc, Hc, Rc);
            }
            if (led_tilt_ridge) led_ridge();
            // klikk-ribber (topp/bunn og sider)
            intersection() {
                xz_extrude(body_y0, body_L) rrect(Wc + 0.2, Hc + 0.2, Rc);
                union() {
                    for (s = [1, -1]) {
                        translate([0, 0, s*Hc/2]) click_bar_x(s);
                        translate([s*Wc/2, 0, 0]) click_bar_z(s);
                    }
                }
            }
        }
        // to 45°-fasetter i bunnkanten bak (åpner et lite spor under bakplaten -> lett å lirke den av)
        for (sx = [-1, 1]) translate([sx*55 - 8, 0, 0]) rotate([90, 0, 90]) linear_extrude(16)
            polygon([[body_y1 + 0.01, -H/2 - 0.01], [body_y1 + 0.01, -H/2 + 1.4], [body_y1 - 1.4, -H/2 - 0.01]]);
    }
}
// Klikk-ribbe (V-profil, 45° flanker) langs X på topp/bunn-vegg: 2D = (Y,Z)
module click_bar_x(s) {
    translate([-click_len/2, click_y, 0]) rotate([90, 0, 90]) linear_extrude(click_len)
        polygon([[-1.1*click_h - 0.05, s*0.05], [1.1*click_h + 0.05, s*0.05], [0, -s*click_h]]);
}
// Klikk-ribbe langs Z på sidevegg: 2D = (X,Y)
module click_bar_z(s) {
    translate([0, click_y, -click_len/2]) linear_extrude(click_len)
        polygon([[s*0.05, -1.1*click_h - 0.05], [s*0.05, 1.1*click_h + 0.05], [-s*click_h, 0]]);
}
// Matchende V-spor i pluggringens yttervegg (litt dypere/bredere enn ribben)
gd = click_h + 0.1;
module groove_x(s) {
    translate([-(click_len + 4)/2, click_y, 0]) rotate([90, 0, 90]) linear_extrude(click_len + 4)
        polygon([[-1.1*gd - 0.05, s*(Hp/2 + 0.05)], [1.1*gd + 0.05, s*(Hp/2 + 0.05)], [0, s*(Hp/2 - gd)]]);
}
module groove_z(s) {
    translate([0, click_y, -(click_len + 4)/2]) linear_extrude(click_len + 4)
        polygon([[s*(Wp/2 + 0.05), -1.1*gd - 0.05], [s*(Wp/2 + 0.05), 1.1*gd + 0.05], [s*(Wp/2 - gd), 0]]);
}

module back_plate() {
    difference() {
        union() {
            xz_extrude(body_y1, back_t) rrect(W, H, corner_r);
            xz_extrude(body_y1 - plug_h, plug_h + 0.01) difference() {
                rrect(Wp, Hp, Rp);
                rrect(Wp - 2*plug_wall, Hp - 2*plug_wall, max(Rp - plug_wall, 1));
            }
        }
        // USB-hull
        translate([usb_x, 0, -H/2 + usb_z_from_bottom]) xz_extrude(body_y1 - plug_h - 1, plug_h + back_t + 2)
            rrect(usb_w, usb_h, 1.5);
        // klikk-spor
        for (s = [1, -1]) { groove_x(s); groove_z(s); }
    }
}

// ------------------------- Printretning (STL) -------------------------
module front_print()   { rotate([90, 0, 0]) front_panel(); }                         // forside ned
module body_print()    { translate([0, 0, D]) rotate([-90, 0, 0]) body(); }          // bakkant ned
module back_print()    { translate([0, 0, D]) rotate([-90, 0, 0]) back_plate(); }     // utside ned
module diffuser_print(){ translate([0, 0, -face_t]) rotate([90, 0, 0]) diffuser(); }

// --------------------------- Forhåndsvisning --------------------------
module assembled(explode = 0) {
    color([0.12, 0.12, 0.14]) translate([0, -explode*1.2, 0]) front_panel();
    color([1, 1, 1, 0.85]) translate([0, -explode*0.5, 0]) diffuser();
    color([0.93, 0.93, 0.9]) body();
    color([0.85, 0.9, 1]) translate([0, explode, 0]) back_plate();
}

if (part == "front_print") front_print();
else if (part == "body_print") body_print();
else if (part == "back_print") back_print();
else if (part == "diffuser_print") diffuser_print();
else if (part == "front") color([0.12, 0.12, 0.14]) front_panel();
else if (part == "body") color([0.93, 0.93, 0.9]) body();
else if (part == "back") color([0.85, 0.9, 1]) back_plate();
else if (part == "diffuser") color([1, 1, 1]) diffuser();
else if (part == "exploded") assembled(40);
else if (part == "section") difference() { assembled(0); translate([0, 0, -500]) translate([-500, -500, 0]) cube([500 + 0, 1000, 1000]); }
else if (part == "lit") {
    color([0.1, 0.1, 0.12]) front_panel();
    color([1, 0.85, 0.4]) translate([0, face_t + 0.01, 0]) xz_extrude(0, 0.5) rrect(W - 4, H - 4, corner_r);
}
else if (part == "clash_front_body") intersection() { front_panel(); body(); }
else if (part == "clash_diffuser_body") intersection() { diffuser(); body(); }
else if (part == "clash_diffuser_front") intersection() { diffuser(); front_panel(); }
else if (part == "clash_back_body") intersection() { back_plate(); body(); }
else if (part == "clash_back_front") intersection() { back_plate(); front_panel(); }
else assembled(0);
