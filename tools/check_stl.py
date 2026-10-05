#!/usr/bin/env python3
"""STL-sjekk: boundingboks, sammenhengende deler, åpne kanter og overheng (>45° fra vertikalen)."""
import sys, re, numpy as np
def load(fn):
    txt = open(fn).read()
    v = np.array(re.findall(r'vertex\s+(\S+)\s+(\S+)\s+(\S+)', txt), dtype=float).reshape(-1, 3, 3)
    return v
for fn in sys.argv[1:]:
    t = load(fn)
    mn, mx = t.reshape(-1, 3).min(0), t.reshape(-1, 3).max(0)
    n = np.cross(t[:, 1] - t[:, 0], t[:, 2] - t[:, 0]); a = np.linalg.norm(n, axis=1); ok = a > 1e-9
    nz = np.zeros(len(t)); nz[ok] = n[ok, 2] / a[ok]
    area = a / 2
    zmin = mn[2]
    on_bed = np.all(np.abs(t[:, :, 2] - zmin) < 1e-4, axis=1)
    over = (nz < -0.7072) & ~on_bed & ok          # nedovervendt flate brattere enn 45° fra vertikal
    bed_area = area[on_bed & (nz < -0.99)].sum()
    # kanter: hver kant skal deles av 2 trekanter
    key = lambda p: tuple(np.round(p, 4))
    from collections import Counter
    c = Counter()
    for tri in t:
        k = [key(p) for p in tri]
        for i in range(3):
            c[tuple(sorted((k[i], k[(i + 1) % 3])))] += 1
    open_edges = sum(1 for v in c.values() if v != 2)
    # volum (signert) for å sjekke at det er et lukket legeme
    vol = np.einsum('ij,ij->i', t[:, 0], np.cross(t[:, 1], t[:, 2])).sum() / 6
    print(f'{fn}: størrelse {mx[0]-mn[0]:.1f} x {mx[1]-mn[1]:.1f} x {mx[2]-mn[2]:.1f} mm, volum {vol/1000:.1f} cm3, '
          f'kanter ikke delt av to flater: {open_edges}, overheng-trekanter (>45°): {over.sum()} (areal {area[over].sum():.2f} mm2), '
          f'flate mot byggeplate {bed_area:.0f} mm2')
    if over.sum():
        z = t[over][:, :, 2].mean(1); print('   overheng i høyde z =', np.unique(np.round(z, 1))[:8])
