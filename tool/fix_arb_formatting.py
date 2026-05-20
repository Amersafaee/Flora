#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys
sys.stdout.reconfigure(encoding='utf-8', errors='replace')
"""
Fixes all JSON formatting issues in 14 non-English ARB files:
1. Moves standalone comma lines — attaches the comma to the END of the
   preceding key-value pair instead of deleting it.
2. Parses and re-serialises the result to verify validity.
3. Optionally applies translations from tool/arb_translations.json.
"""
import json
import os
import re

LOCALES = ['es', 'fr', 'de', 'pt', 'ar', 'fa', 'ja', 'ko', 'it', 'nl', 'tr', 'pl', 'sv', 'hi']
L10N_DIR = os.path.join(os.path.dirname(__file__), '..', 'lib', 'l10n')
TRANSLATIONS_FILE = os.path.join(os.path.dirname(__file__), 'arb_translations.json')


def fix_arb_text(content):
    """
    Repair common ARB sync artifacts:
    - A standalone ',' line means the PREVIOUS line is missing its comma.
      Solution: remove the standalone comma line and append a comma to the
      preceding non-empty line.
    """
    lines = content.split('\n')
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
        # Check if the NEXT line is a standalone comma
        if i + 1 < len(lines) and lines[i + 1].strip() == ',':
            # Attach comma to current line (only if it doesn't already end with ,)
            stripped = line.rstrip()
            if stripped and not stripped.endswith(','):
                result.append(stripped + ',')
            else:
                result.append(line)
            i += 2  # skip the standalone comma line
        elif line.strip() == ',':
            # Orphaned comma with no preceding line in result to fix — skip it
            i += 1
        else:
            result.append(line)
            i += 1

    return '\n'.join(result)


def fix_and_parse_arb(filepath):
    with open(filepath, 'r', encoding='utf-8-sig') as f:
        content = f.read()

    content = fix_arb_text(content)

    try:
        return json.loads(content), content
    except json.JSONDecodeError as e:
        print(f'  ERROR parsing JSON: {e}')
        lineno = e.lineno
        problem_lines = content.split('\n')[max(0, lineno - 3):lineno + 3]
        for idx, l in enumerate(problem_lines):
            print(f'    {lineno - 3 + idx}: {l}')
        return None, content


def write_arb(filepath, data):
    with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')


def main():
    translations = {}
    if os.path.exists(TRANSLATIONS_FILE):
        with open(TRANSLATIONS_FILE, 'r', encoding='utf-8') as f:
            translations = json.load(f)
        print(f'Loaded {len(translations)} translation keys from arb_translations.json')
    else:
        print('No arb_translations.json found — only fixing formatting.')

    for locale in LOCALES:
        filepath = os.path.join(L10N_DIR, f'app_{locale}.arb')
        if not os.path.exists(filepath):
            print(f'  SKIP: {filepath} not found')
            continue

        print(f'Processing {locale}...', end=' ', flush=True)
        arb, _ = fix_and_parse_arb(filepath)
        if arb is None:
            print('FAILED')
            continue

        updated = 0
        for key, lang_map in translations.items():
            if locale in lang_map and key in arb:
                arb[key] = lang_map[locale]
                updated += 1

        write_arb(filepath, arb)
        print(f'OK ({updated} translations applied)')

    print('\nDone.')


if __name__ == '__main__':
    main()
