#!/usr/bin/env python3
"""
Adds 6 new i18n keys from arb_translations_9.json into all ARB files.
- Fixes the malformed app_en.arb (stray comma) and ensures keys are appended correctly.
- Injects per-language values into each of the 14 non-English ARBs.
"""
import re, os, json

L10N_DIR = r"lib\l10n"
TRANS_FILE = r"tool\arb_translations_9.json"

with open(TRANS_FILE, "r", encoding="utf-8") as f:
    translations = json.load(f)

KEYS_ORDER = ["logCare", "askFloraCTA", "whatShouldICareForToday",
              "addAPlantFirst", "locationField", "locationHint"]

EN_VALUES = {
    "logCare": "Log Care",
    "askFloraCTA": "Ask Flora",
    "whatShouldICareForToday": "What should I care for today?",
    "addAPlantFirst": "Add a plant first",
    "locationField": "Location",
    "locationHint": "e.g. Living room, South-facing window",
}

def fix_and_append(path, key_value_pairs):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    # Remove any stray comma-only line that was left by the previous PS attempt
    content = re.sub(r'\n,\s*\n', '\n', content)

    # Ensure the last real entry has a trailing comma before closing brace
    # Find the closing brace
    stripped = content.rstrip()
    if stripped.endswith("}"):
        inner = stripped[:-1].rstrip()
        if not inner.endswith(","):
            inner = inner + ","
        new_entries = ""
        for key, val in key_value_pairs:
            # Escape any backslashes and quotes in value
            escaped = val.replace("\\", "\\\\").replace('"', '\\"')
            new_entries += f'\n  "{key}": "{escaped}",'
        # Remove trailing comma from last entry
        new_entries = new_entries.rstrip(",")
        content = inner + new_entries + "\n}\n"
    
    with open(path, "w", encoding="utf-8", newline="\r\n") as f:
        f.write(content)


# ── 1. app_en.arb ──────────────────────────────────────────────────────────
en_path = os.path.join(L10N_DIR, "app_en.arb")
en_pairs = [(k, EN_VALUES[k]) for k in KEYS_ORDER]

# Check which keys already exist so we don't double-add
with open(en_path, "r", encoding="utf-8") as f:
    existing_en = f.read()

en_pairs_to_add = [(k, v) for k, v in en_pairs if f'"{k}"' not in existing_en]
if en_pairs_to_add:
    fix_and_append(en_path, en_pairs_to_add)
    print(f"app_en.arb: added {[k for k,_ in en_pairs_to_add]}")
else:
    # Still fix the comma issue
    with open(en_path, "r", encoding="utf-8") as f:
        content = f.read()
    content = re.sub(r'\n,\s*\n', '\n', content)
    with open(en_path, "w", encoding="utf-8", newline="\r\n") as f:
        f.write(content)
    print("app_en.arb: keys already present, fixed formatting only")

# ── 2. Non-English ARBs ─────────────────────────────────────────────────────
LANG_MAP = {
    "app_es.arb": "es",
    "app_fr.arb": "fr",
    "app_de.arb": "de",
    "app_pt.arb": "pt",
    "app_ar.arb": "ar",
    "app_fa.arb": "fa",
    "app_ja.arb": "ja",
    "app_ko.arb": "ko",
    "app_it.arb": "it",
    "app_nl.arb": "nl",
    "app_tr.arb": "tr",
    "app_pl.arb": "pl",
    "app_sv.arb": "sv",
    "app_hi.arb": "hi",
}

for filename, lang_code in LANG_MAP.items():
    path = os.path.join(L10N_DIR, filename)
    with open(path, "r", encoding="utf-8") as f:
        existing = f.read()
    
    pairs_to_add = []
    for key in KEYS_ORDER:
        if f'"{key}"' not in existing:
            value = translations[key].get(lang_code, EN_VALUES[key])
            pairs_to_add.append((key, value))
    
    if pairs_to_add:
        fix_and_append(path, pairs_to_add)
        print(f"{filename}: added {[k for k,_ in pairs_to_add]}")
    else:
        print(f"{filename}: all keys already present")

print("\nAll ARB files updated successfully.")
