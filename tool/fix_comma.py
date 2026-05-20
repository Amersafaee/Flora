import sys, re, os
sys.stdout.reconfigure(encoding='utf-8')

locales = ['es','fr','de','pt','ar','fa','ja','ko','it','nl','tr','pl','sv','hi']
for loc in locales:
    path = f'lib/l10n/app_{loc}.arb'
    with open(path, 'r', encoding='utf-8-sig') as f:
        content = f.read()
    # Add comma after the treating value before myBadges
    pattern = r'("treating"\s*:\s*"[^"]+")([\r\n]+\s*"myBadges")'
    fixed = re.sub(pattern, r'\1,\2', content)
    if fixed == content:
        print(f'{loc}: no change needed (already has comma or pattern not found)')
    else:
        with open(path, 'w', encoding='utf-8', newline='\n') as f:
            f.write(fixed)
        print(f'{loc}: fixed')
