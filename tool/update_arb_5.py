import json, pathlib, sys
sys.stdout.reconfigure(encoding='utf-8')

# Step 1: Add 3 keys to app_en.arb
en_path = pathlib.Path('lib/l10n/app_en.arb')
arb = json.loads(en_path.read_text(encoding='utf-8'))
arb['accountSection'] = 'Account'
arb['backArrow'] = '\u2190 Back'
arb['errorPrefix'] = 'Error: '
en_path.write_text(json.dumps(arb, ensure_ascii=False, indent=2), encoding='utf-8')
print('app_en.arb updated with 3 keys')

# Step 2: Propagate to 14 non-English ARB files
translations = {
    'accountSection': {
        'es': 'Cuenta', 'fr': 'Compte', 'de': 'Konto', 'pt': 'Conta',
        'ar': '\u0627\u0644\u062d\u0633\u0627\u0628', 'fa': '\u062d\u0633\u0627\u0628',
        'ja': '\u30a2\u30ab\u30a6\u30f3\u30c8', 'ko': '\uacc4\uc815',
        'it': 'Account', 'nl': 'Account', 'tr': 'Hesap', 'pl': 'Konto',
        'sv': 'Konto', 'hi': '\u0916\u093e\u0924\u093e',
    },
    'backArrow': {
        'es': '\u2190 Atr\xe1s', 'fr': '\u2190 Retour', 'de': '\u2190 Zur\xfcck',
        'pt': '\u2190 Voltar', 'ar': '\u2190 \u0631\u062c\u0648\u0639',
        'fa': '\u2190 \u0628\u0627\u0632\u06af\u0634\u062a', 'ja': '\u2190 \u623b\u308b',
        'ko': '\u2190 \ub4a4\ub85c', 'it': '\u2190 Indietro', 'nl': '\u2190 Terug',
        'tr': '\u2190 Geri', 'pl': '\u2190 Wstecz', 'sv': '\u2190 Tillbaka',
        'hi': '\u2190 \u092a\u0940\u091b\u0947 \u091c\u093e\u090f\u0902',
    },
    'errorPrefix': {
        'es': 'Error: ', 'fr': 'Erreur\u00a0: ', 'de': 'Fehler: ', 'pt': 'Erro: ',
        'ar': '\u062e\u0637\u0623: ', 'fa': '\u062e\u0637\u0627: ',
        'ja': '\u30a8\u30e9\u30fc: ', 'ko': '\uc624\ub958: ',
        'it': 'Errore: ', 'nl': 'Fout: ', 'tr': 'Hata: ', 'pl': 'B\u0142\u0105d: ',
        'sv': 'Fel: ', 'hi': '\u0924\u094d\u0930\u0941\u091f\u093f: ',
    },
}

for p in pathlib.Path('lib/l10n').glob('app_*.arb'):
    if p.name == 'app_en.arb':
        continue
    lang = p.stem.replace('app_', '')
    data = json.loads(p.read_text(encoding='utf-8'))
    for key, lang_map in translations.items():
        if lang in lang_map:
            data[key] = lang_map[lang]
    p.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'{p.name}: updated')

print('Done.')
