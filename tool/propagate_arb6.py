import json, pathlib, sys
sys.stdout.reconfigure(encoding='utf-8')

l10n = pathlib.Path('lib/l10n')
trans = json.loads(pathlib.Path('tool/arb_translations_6.json').read_text(encoding='utf-8'))

locales = ['ar','de','es','fa','fr','hi','it','ja','ko','nl','pl','pt','sv','tr']

for locale in locales:
    path = l10n / f'app_{locale}.arb'
    arb = json.loads(path.read_text(encoding='utf-8'))

    for key, translations in trans.items():
        if locale in translations:
            arb[key] = translations[locale]
        # Copy metadata from app_en.arb (no metadata needed for non-English)

    # Write back preserving order
    path.write_text(json.dumps(arb, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'✅ {locale}: added {list(trans.keys())}')

print('Done.')
