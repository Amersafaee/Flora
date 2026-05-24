#!/usr/bin/env python3
"""Fix app_en.arb: ensure 'askFloraShort' line ends with a comma."""
import sys, re
sys.stdout.reconfigure(encoding='utf-8')

path = r'lib\l10n\app_en.arb'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Find 'askFloraShort' line that is missing a trailing comma
# Pattern: the line ends with "..." (closing quote) with no comma, followed by newline and then the new keys
fixed = re.sub(
    r'("askFloraShort":\s*"[^"]*")(\s*\n\s*"logCare")',
    r'\1,\2',
    content
)

if fixed == content:
    print("No change needed or pattern not found — checking manually...")
    # Show the area
    lines = content.splitlines()
    for i, l in enumerate(lines[1178:1188], start=1179):
        print(i, l)
else:
    with open(path, 'w', encoding='utf-8', newline='\r\n') as f:
        f.write(fixed)
    print("Fixed comma after askFloraShort")

# Validate JSON
import json
try:
    data = json.loads(open(path, encoding='utf-8').read())
    keys = ['logCare','askFloraCTA','whatShouldICareForToday','addAPlantFirst','locationField','locationHint']
    for k in keys:
        print(f"  {k} = {data[k]}")
    print("JSON valid ✓")
except json.JSONDecodeError as e:
    print(f"JSON ERROR: {e}")
