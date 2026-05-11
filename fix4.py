import re

path = r'c:\Projects\Flora\lib\screens\swap_market_screen.dart'
with open(path, 'rb') as f:
    raw = f.read()

# find out the encoding
try:
    content = raw.decode('utf-8')
except UnicodeDecodeError:
    content = raw.decode('windows-1252')

# 1. Add import
if "import 'listing_detail_screen.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'listing_detail_screen.dart';")

# 2. Replace onTap
pattern = re.compile(r'onTap:\s*\(\)\s*\{\s*ScaffoldMessenger\.of\(context\)\.showSnackBar\(.*?Coming soon.*?\);?\s*\},', re.DOTALL)
replacement = '''onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ListingDetailScreen(doc: doc),
            ),
          );
        },'''

new_content = re.sub(pattern, replacement, content)

if new_content != content:
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print('Replaced successfully.')
else:
    print('Failed to replace.')
