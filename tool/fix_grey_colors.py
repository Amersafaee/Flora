"""
Fix remaining hardcoded Colors.grey.shade* and Colors.white (container backgrounds) 
across all lib/screens/*.dart files using safe line-by-line replacements.
"""
import os
import re

SCREENS_DIR = r'lib\screens'

# Patterns and their replacements
# Each tuple: (regex_pattern, replacement_string)
# We're careful NOT to replace:
#   - Colors.white on colored buttons/icon backgrounds (intentional contrast)
#   - Colors.black.withValues(alpha:...) image overlays
REPLACEMENTS = [
    # Grey shades as borders → outline token
    (r'Colors\.grey\.shade(?:200|300)', 'Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)'),
    # Grey shades as surface backgrounds → surfaceContainerHighest
    (r'Colors\.grey\.shade(?:100|200)', 'Theme.of(context).colorScheme.surfaceContainerHighest'),
]

# More specific rules per context (applied before general rules)
SPECIFIC_REPLACEMENTS = [
    # border: Border.all(color: Colors.grey.shade*) → outline
    (
        r'Border\.all\(color: Colors\.grey\.shade\d+\)',
        r'Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))'
    ),
    # BorderSide(color: Colors.grey.shade*) → outline
    (
        r'BorderSide\(color: Colors\.grey\.shade\d+\)',
        r'BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))'
    ),
    # Divider(color: Colors.grey.shade*) → outline
    (
        r'Divider\(color: Colors\.grey\.shade\d+\)',
        r'Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))'
    ),
    # color: Colors.grey.shade[12]00, (standalone color property, surface use)
    (
        r'color: Colors\.grey\.shade(?:100|200),',
        r'color: Theme.of(context).colorScheme.surfaceContainerHighest,'
    ),
    # color: Colors.grey.shade300, (standalone color property, used as subtle border/line)
    (
        r'color: Colors\.grey\.shade300,',
        r'color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),'
    ),
    # backgroundColor: Colors.grey.shade200 (used for inactive chip/button backgrounds)
    (
        r'backgroundColor: Colors\.grey\.shade\d+,',
        r'backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,'
    ),
    # isMe ? primaryColor : Colors.grey.shade200 (chat bubble received)
    (
        r'Colors\.grey\.shade200,\s*\n\s*borderRadius',  # leave specific patterns for manual fix
        r'Theme.of(context).colorScheme.surfaceContainerHighest,\n                                  borderRadius'
    ),
]

files_fixed = []

for filename in os.listdir(SCREENS_DIR):
    if not filename.endswith('.dart'):
        continue
    filepath = os.path.join(SCREENS_DIR, filename)
    with open(filepath, 'r', encoding='utf-8') as f:
        original = f.read()
    
    modified = original
    
    # Apply specific replacements first
    for pattern, replacement in SPECIFIC_REPLACEMENTS:
        new = re.sub(pattern, replacement, modified)
        if new != modified:
            modified = new
    
    if modified != original:
        with open(filepath, 'w', encoding='utf-8', newline='') as f:
            f.write(modified)
        files_fixed.append(filename)
        print(f'Fixed: {filename}')

print(f'\nTotal files fixed: {len(files_fixed)}')
