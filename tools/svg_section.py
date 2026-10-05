#!/usr/bin/env python3
"""Tegner et OpenSCAD-SVG-snitt (projection(cut=true)) til PNG med mål-rutenett. Bruk: svg_section.py in.svg out.png [px_per_mm] [tittel]"""
import sys, re
from PIL import Image, ImageDraw, ImageChops, ImageFont
src, out = sys.argv[1], sys.argv[2]
k = float(sys.argv[3]) if len(sys.argv) > 3 else 30
title = sys.argv[4] if len(sys.argv) > 4 else ''
txt = open(src).read()
vb = list(map(float, re.search(r'viewBox="([^"]+)"', txt).group(1).split()))
d = re.search(r'd="([^"]+)"', txt, re.S).group(1)
subs = [s for s in d.split('M')[1:]]
polys = []
for s in subs:
    pts = [tuple(map(float, p.split(','))) for p in re.findall(r'(-?[\d.]+,-?[\d.]+)', s)]
    polys.append(pts)
pad = 24
W = int(vb[2]*k) + 2*pad; H = int(vb[3]*k) + 2*pad + (28 if title else 0)
tx = lambda x: pad + (x - vb[0])*k
ty = lambda y: pad + (28 if title else 0) + (vb[1] + vb[3] - y)*k
acc = Image.new('L', (W, H), 0)
for p in polys:
    m = Image.new('L', (W, H), 0); ImageDraw.Draw(m).polygon([(tx(x), ty(y)) for x, y in p], fill=255)
    acc = ImageChops.logical_xor(acc.convert('1'), m.convert('1')).convert('L')
img = Image.new('RGB', (W, H), (249, 249, 249))
dr = ImageDraw.Draw(img)
# 5 mm-rutenett
x = int(vb[0]//5*5)
while x <= vb[0] + vb[2]:
    dr.line([(tx(x), ty(vb[1])), (tx(x), ty(vb[1] + vb[3]))], fill=(225, 225, 225)); x += 5
y = 0
while y <= vb[1] + vb[3]:
    dr.line([(tx(vb[0]), ty(y)), (tx(vb[0] + vb[2]), ty(y))], fill=(225, 225, 225)); y += 5
img.paste((196, 150, 40), mask=acc)
for p in polys: dr.line([(tx(x), ty(y)) for x, y in p] + [(tx(p[0][0]), ty(p[0][1]))], fill=(60, 40, 0), width=1)
if title: dr.text((pad, 6), title, fill=(0, 0, 0))
img.save(out)
