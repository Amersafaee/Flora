import re

path = r'c:\Projects\Flora\lib\screens\swap_market_screen.dart'
with open(path, 'rb') as f:
    raw = f.read()

try:
    content = raw.decode('utf-8')
except Exception:
    content = raw.decode('utf-16')

if "import 'listing_detail_screen.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'listing_detail_screen.dart';")

pattern = re.compile(r'onTap:\s*\(\)\s*\{[\s\S]*?ScaffoldMessenger\.of\(context\)\.showSnackBar\([\s\S]*?Coming soon[\s\S]*?\);?\s*\},')
replacement = '''onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ListingDetailScreen(doc: doc),
            ),
          );
        },'''

new_content = re.sub(pattern, replacement, content)

if new_content == content:
    print('Regex failed to match or already replaced.')
else:
    with open(path, 'wb') as f:
        f.write(new_content.encode('utf-8'))
    print('File updated successfully.')
