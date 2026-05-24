#!/usr/bin/env python3
"""Validate all ARB files are valid JSON and contain all 6 required keys."""
import sys, json, os
sys.stdout.reconfigure(encoding='utf-8')

KEYS = ['logCare','askFloraCTA','whatShouldICareForToday','addAPlantFirst','locationField','locationHint']
L10N_DIR = r'lib\l10n'

all_ok = True
for fname in sorted(os.listdir(L10N_DIR)):
    if not fname.endswith('.arb'):
        continue
    path = os.path.join(L10N_DIR, fname)
    try:
        data = json.loads(open(path, encoding='utf-8').read())
    except json.JSONDecodeError as e:
        print(f"FAIL {fname}: JSON error — {e}")
        all_ok = False
        continue
    missing = [k for k in KEYS if k not in data]
    if missing:
        print(f"FAIL {fname}: missing keys {missing}")
        all_ok = False
    else:
        print(f"OK   {fname}: all 6 keys present")

print()
print("All valid" if all_ok else "ERRORS FOUND")
