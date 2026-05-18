#!/usr/bin/env python3
"""
Fix incorrect const + Theme.of(context).cardColor placements.

Cases to fix:
1. const TextStyle(... color: Theme.of(context).cardColor ...) 
   → These should be Colors.white (white text on green buttons)
   → Remove 'const' from TextStyle

2. const BoxDecoration(... color: Theme.of(context).cardColor ...)
   → Remove 'const' from BoxDecoration

3. const Icon(... color: Theme.of(context).cardColor ...)
   → Remove 'const' from Icon

4. const Text('...' style: TextStyle(color: Theme.of(context).cardColor ...))
   → Remove 'const' from Text

5. CircularProgressIndicator(color: Theme.of(context).cardColor ...)
   → Change back to Colors.white (spinner on green button)

6. care_screen.dart:699 — non_constant_default_value
   → Find and fix the default parameter issue

7. create_post_screen.dart:202 — undefined_operator Color[...]
   → Find and fix the bracket operator

Strategy: Line-by-line scan.
- If line has 'const' AND 'Theme.of(context)' → remove 'const'
- If line has 'CircularProgressIndicator' or 'strokeWidth' and 'Theme.of(context).cardColor' 
  → change to Colors.white (spinner in buttons is always white)
"""

import os, re

LIB_DIR = r"C:\Projects\Flora_v0.1\Flora\lib"
SKIP_FILES = {"app_theme.dart", "tokens.dart"}


def fix_file(file_path):
    with open(file_path, encoding="utf-8", errors="replace") as f:
        lines = f.readlines()
    
    original = "".join(lines)
    new_lines = []
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Case 1: Line has 'const' and 'Theme.of(context)' → remove 'const'
        if "const" in line and "Theme.of(context)" in line:
            line = re.sub(r"\bconst\s+", "", line)
        
        # Case 2: CircularProgressIndicator color: Theme.of(context).cardColor
        # → change to Colors.white (spinner on button is always white)
        if re.search(r"color:\s*Theme\.of\(context\)\.cardColor", line):
            # Check surrounding context — if we're in a CircularProgressIndicator or
            # this appears to be white-on-colored-button context
            # Look at previous few lines for context
            context_window = "".join(lines[max(0, i-5):i+1])
            if ("CircularProgressIndicator" in context_window or
                "strokeWidth" in context_window):
                line = re.sub(
                    r"color:\s*Theme\.of\(context\)\.cardColor",
                    "color: Colors.white",
                    line
                )
        
        new_lines.append(line)
        i += 1
    
    content = "".join(new_lines)
    
    # Special fix for create_post_screen.dart undefined_operator
    if "create_post_screen.dart" in file_path:
        # Find and fix Color['something'] pattern
        content = re.sub(
            r"(AppColors\.\w+|Theme\.of\(context\)\.\w+)\['[^']*'\]",
            r"\1",  # Remove the bracket subscript
            content
        )
    
    if content == original:
        return False
    
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    return True


def main():
    changed = []
    for root, dirs, files in os.walk(LIB_DIR):
        for fname in sorted(files):
            if not fname.endswith(".dart") or fname in SKIP_FILES:
                continue
            fpath = os.path.join(root, fname)
            if fix_file(fpath):
                changed.append(fpath[len(LIB_DIR)+1:])
    
    print(f"Fixed const+Theme.of issues in {len(changed)} files:")
    for f in changed:
        print(f"  {f}")


if __name__ == "__main__":
    main()
