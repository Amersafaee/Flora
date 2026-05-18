#!/usr/bin/env python3
"""
Remove tokens.dart import from any file that already imports app_theme.dart.
This resolves the ambiguous_import errors from both files defining AppColors etc.
"""
import os, re

LIB_DIR = r"C:\Projects\Flora_v0.1\Flora\lib"

# Pattern to match any import of tokens.dart
tokens_import_pat = re.compile(r"^import '.*?tokens\.dart';\s*\n?", re.MULTILINE)

changed = []
for root, dirs, files in os.walk(LIB_DIR):
    for fname in sorted(files):
        if not fname.endswith(".dart"):
            continue
        path = os.path.join(root, fname)
        content = open(path, encoding="utf-8", errors="replace").read()
        
        # Only touch files that import BOTH
        if "tokens.dart" not in content or "app_theme.dart" not in content:
            continue
        
        # Remove the tokens.dart import line
        new_content = tokens_import_pat.sub("", content)
        
        if new_content == content:
            continue
        
        with open(path, "w", encoding="utf-8") as f:
            f.write(new_content)
        changed.append(path[len(LIB_DIR)+1:])

print(f"Removed tokens.dart import from {len(changed)} files:")
for f in changed:
    print(f"  {f}")
