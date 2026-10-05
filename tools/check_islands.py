#!/usr/bin/env python3
"""Sjekker at frontplatens massive område er ETT sammenhengende stykke (ingen «øyer» som faller ut)
og måler tynneste bro. Bruker out/lit.png (ortografisk bilde rett forfra, mørk = plast, gul = utskåret)."""
import sys, numpy as np
from PIL import Image
from scipy import ndimage as ndi
img = np.array(Image.open(sys.argv[1] if len(sys.argv) > 1 else 'out/lit.png').convert('RGB')).astype(int)
dark = (img.max(axis=2) < 70)
lab, n = ndi.label(dark)
sizes = ndi.sum(dark, lab, range(1, n + 1))
print('Sammenhengende plastområder:', n, 'størrelser(px):', sorted(map(int, sizes), reverse=True)[:6])
big = max(sizes)
small = [int(s) for s in sizes if s != big and s > 20]
print('Frittflytende øyer (>20 px):', len(small))
# tynneste solide bro: euklidsk avstandstransform
mm_px = 200.0 / (np.ptp(np.where(dark.any(axis=0))[0]) + 1)
dt = ndi.distance_transform_edt(dark)
# skeleton-ish: lokale maksima av dt langs broer er vanskelig; rapporter minste «hals» via åpning
for w in (1.2, 1.6, 2.0):
    r = int(round(w / mm_px / 2))
    opened = ndi.binary_opening(dark, structure=np.ones((2 * r + 1, 2 * r + 1)))
    lab2, n2 = ndi.label(opened)
    print(f'Etter fjerning av steg < {w} mm: {n2} område(r)')
# tynneste utskårne spalte
cut = ~dark & (img[:, :, 0] > 150)
print('mm pr px:', round(mm_px, 3))
