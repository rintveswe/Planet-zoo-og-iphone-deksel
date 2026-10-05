#!/usr/bin/env python3
"""Gjør en logo-PNG (lys logo på gjennomsiktig/mørk bunn) om til en OpenSCAD-polygon for utskjæring i lysboksen.
 - lyse piksler = utskåret (lyset skinner gjennom)
 - lukkede mørke «øyer» (som innsiden av P, A, O) får en tynn solid bro til ytterområdet; bittesmå øyer fylles (skjæres bort)
Bruk: vectorize_logo.py logo.png out.scad [bredde_mm=84] [bro_mm=1.6] [min_øy_mm=1.6]"""
import sys, numpy as np, cv2
from scipy import ndimage as ndi
src, out = sys.argv[1], sys.argv[2]
width_mm = float(sys.argv[3]) if len(sys.argv) > 3 else 84
bridge_mm = float(sys.argv[4]) if len(sys.argv) > 4 else 1.6
min_island_mm = float(sys.argv[5]) if len(sys.argv) > 5 else 1.6
im = cv2.imread(src, cv2.IMREAD_UNCHANGED)
if im.shape[2] == 4: lit = im[..., 3].astype(np.float32)
else: lit = cv2.cvtColor(im, cv2.COLOR_BGR2GRAY).astype(np.float32)
UP = 2
lit = cv2.resize(lit, None, fx=UP, fy=UP, interpolation=cv2.INTER_CUBIC)
lit = cv2.GaussianBlur(lit, (0, 0), 1.0)
m = (lit > 128)
m = np.pad(m, 20)                                    # ramme så ytterområdet er sammenhengende
h, w = m.shape
mm_px = width_mm / (m.shape[1] - 40)
dark = ~m
lab, n = ndi.label(dark)
outer = lab[0, 0]
bridge_px = max(2, int(round(bridge_mm / mm_px)))
min_px2 = (min_island_mm / mm_px) ** 2
islands = [i for i in range(1, n + 1) if i != outer]
filled = bridged = 0
outer_mask = lab == outer
dist, idx = ndi.distance_transform_edt(~outer_mask, return_indices=True)
bridges = np.zeros(m.shape, np.uint8)
for i in islands:
    comp = lab == i
    area = comp.sum()
    if area < min_px2:
        m[comp] = True; filled += 1; continue
    ys, xs = np.nonzero(comp)
    k = np.argmin(dist[ys, xs])
    y0, x0 = ys[k], xs[k]
    y1, x1 = idx[0][y0, x0], idx[1][y0, x0]
    cv2.line(bridges, (int(x0), int(y0)), (int(x1), int(y1)), 1, bridge_px)
    bridged += 1
m[bridges > 0] = False
print(f'mørke områder: {n}, ytre: 1, øyer med bro: {bridged}, små øyer fylt: {filled}, bro {bridge_mm} mm = {bridge_px}px, {mm_px:.4f} mm/px')
mask = (m.astype(np.uint8) * 255)
# verifiser: ett sammenhengende mørkt område
lab2, n2 = ndi.label(~m)
print('mørke områder etter broer:', n2)
cnts, hier = cv2.findContours(mask, cv2.RETR_CCOMP, cv2.CHAIN_APPROX_NONE)
pts, paths = [], []
for c in cnts:
    c = cv2.approxPolyDP(c, 0.7, True)[:, 0, :]
    if len(c) < 3: continue
    start = len(pts)
    for x, y in c: pts.append((round((x - 20) * mm_px, 3), round((h - 20 - y) * mm_px, 3)))   # y opp, mm
    paths.append(list(range(start, start + len(c))))
xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
pts = [(round(x - cx, 3), round(y - cy, 3)) for x, y in pts]
with open(out, 'w') as f:
    f.write(f'// Generert av tools/vectorize_logo.py fra {src.split("/")[-1]} – ikke rediger for hånd\n')
    f.write(f'// Størrelse ca. {max(xs)-min(xs):.1f} x {max(ys)-min(ys):.1f} mm, midtstilt. Lyse deler = utskåret.\n')
    f.write('logo_pts = [' + ','.join(f'[{x},{y}]' for x, y in pts) + '];\n')
    f.write('logo_paths = [' + ','.join('[' + ','.join(map(str, p)) + ']' for p in paths) + '];\n')
    f.write('module logo2d() { polygon(points = logo_pts, paths = logo_paths); }\n')
print('punkter:', len(pts), 'baner:', len(paths), f'størrelse {max(xs)-min(xs):.1f} x {max(ys)-min(ys):.1f} mm')
