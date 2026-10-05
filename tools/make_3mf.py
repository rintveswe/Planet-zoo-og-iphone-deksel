#!/usr/bin/env python3
"""Pakker STL-filene til én .3mf (Bambu Studio / OrcaSlicer): fire objekter, lagt ut på én 256 x 256 mm plate,
med filament-nummer (extruder) satt per objekt: 1 = svart (frontpanel), 2 = hvit (resten)."""
import re, zipfile, numpy as np, sys
from xml.sax.saxutils import escape
parts = [  # fil, navn, extruder, senter (x, y) på plata
    ("stl/lysboks_frontpanel.stl", "Frontpanel (svart)", 1, (73, 183)),
    ("stl/lysboks_hovedkropp.stl", "Hovedkropp (hvit)", 2, (183, 183)),
    ("stl/lysboks_bakplate.stl",   "Bakplate (hvit)",   2, (73, 73)),
    ("stl/lysboks_diffuser.stl",   "Diffuser (hvit, 0,8 mm)", 2, (183, 73)),
]
def load(fn):
    t = np.array(re.findall(r'vertex\s+(\S+)\s+(\S+)\s+(\S+)', open(fn).read()), float).reshape(-1, 3)
    uniq, inv = np.unique(np.round(t, 5), axis=0, return_inverse=True)
    return uniq, inv.reshape(-1, 3)
objs, build, cfg = [], [], []
for i, (fn, name, ext, (cx, cy)) in enumerate(parts, 1):
    v, f = load(fn)
    assert abs(v[:, 2].min()) < 1e-3, fn      # ligger på plata
    c = (v[:, :2].min(0) + v[:, :2].max(0)) / 2
    v = v - [c[0], c[1], 0]                    # midtstill i XY; plasseres via build-transform
    vs = ''.join(f'<vertex x="{x:.5f}" y="{y:.5f}" z="{z:.5f}"/>' for x, y, z in v)
    ts = ''.join(f'<triangle v1="{a}" v2="{b}" v3="{c_}"/>' for a, b, c_ in f)
    objs.append(f'<object id="{i}" name="{escape(name)}" type="model"><mesh><vertices>{vs}</vertices><triangles>{ts}</triangles></mesh></object>')
    build.append(f'<item objectid="{i}" transform="1 0 0 0 1 0 0 0 1 {cx} {cy} 0" printable="1"/>')
    cfg.append(f'<object id="{i}"><metadata key="name" value="{escape(name)}"/><metadata key="extruder" value="{ext}"/></object>')
model = ('<?xml version="1.0" encoding="UTF-8"?>\n<model unit="millimeter" xml:lang="en-US" '
         'xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">'
         '<metadata name="Title">Lysboks Planet Zoo 2</metadata><metadata name="Application">BambuStudio</metadata>'
         f'<resources>{"".join(objs)}</resources><build>{"".join(build)}</build></model>')
plate = ('<plate><metadata key="plater_id" value="1"/><metadata key="plater_name" value=""/>' +
         ''.join(f'<model_instance><metadata key="object_id" value="{i}"/><metadata key="instance_id" value="0"/></model_instance>' for i in range(1, len(parts) + 1)) + '</plate>')
settings = f'<?xml version="1.0" encoding="UTF-8"?>\n<config>{"".join(cfg)}{plate}</config>'
ct = ('<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>'
      '<Default Extension="config" ContentType="text/xml"/></Types>')
rels = ('<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Target="/3D/3dmodel.model" Id="rel0" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/></Relationships>')
out = sys.argv[1] if len(sys.argv) > 1 else 'lysboks_planetzoo2.3mf'
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
    z.writestr('[Content_Types].xml', ct); z.writestr('_rels/.rels', rels)
    z.writestr('3D/3dmodel.model', model); z.writestr('Metadata/model_settings.config', settings)
print('skrev', out)
