import re

files_to_fix = {
    r'lib\screens\vitals_dashboard_screen.dart': [
        (
            'colorScheme.surfaceContainerHighest,\\r\\n                                  borderRadius',
            'colorScheme.surfaceContainerHighest,\r\n                                  borderRadius'
        ),
    ],
    r'lib\screens\weekly_report_screen.dart': [
        (
            'cardColor,\\r\\n                  borderRadius',
            'cardColor,\r\n                  borderRadius'
        ),
    ],
}

for filepath, replacements in files_to_fix.items():
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    for old, new in replacements:
        content = content.replace(old, new)
    with open(filepath, 'w', encoding='utf-8', newline='') as f:
        f.write(content)
    print(f'Fixed: {filepath}')

print('Done.')
