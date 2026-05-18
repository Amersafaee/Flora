#!/usr/bin/env python3
import re, os

LIB_DIR = r"C:\Projects\Flora_v0.1\Flora\lib"

hex_pat = re.compile(r"Color\(0x[0-9A-Fa-f]{8}\)")
grey_pat = re.compile(r"Colors\.grey")
white_pat = re.compile(r"Colors\.white")
black_pat = re.compile(r"Colors\.black")

summary = {}
for root, dirs, files in os.walk(LIB_DIR):
    for fname in files:
        if not fname.endswith(".dart") or fname in {"app_theme.dart", "tokens.dart"}:
            continue
        path = os.path.join(root, fname)
        content = open(path, encoding="utf-8", errors="replace").read()
        hexes = sorted(set(hex_pat.findall(content)))
        greys = grey_pat.findall(content)
        whites = white_pat.findall(content)
        blacks = black_pat.findall(content)
        if hexes or greys or whites or blacks:
            rel = path[len(LIB_DIR)+1:]
            summary[rel] = {
                "hex": hexes,
                "grey": len(greys),
                "white": len(whites),
                "black": len(blacks),
            }

print(f"Files with hardcoded colors: {len(summary)}")
print()
for f, data in sorted(summary.items()):
    print(f"  {f}")
    if data["hex"]:
        for h in data["hex"]:
            print(f"      {h}")
    if data["grey"]:  print(f"    Colors.grey x{data['grey']}")
    if data["white"]: print(f"    Colors.white x{data['white']}")
    if data["black"]: print(f"    Colors.black x{data['black']}")
