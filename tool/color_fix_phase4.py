#!/usr/bin/env python3
"""
Flora Color Token Fixer — Phase 4
Handles Colors.white as container/card background colors.

Rules:
- "color: Colors.white," in BoxDecoration/Container → Theme.of(context).cardColor
  EXCEPT when inside: ElevatedButton.styleFrom, TextStyle, CircularProgressIndicator,
         foregroundColor:, backgroundColor: on buttons, icon: context
- "color: Colors.white" → keep if it's after 'foregroundColor:' or 'style: TextStyle'
  or 'child: Icon' or 'color: Colors.white70'
"""

import os, re, sys

LIB_DIR = r"C:\Projects\Flora_v0.1\Flora\lib"
SKIP_FILES = {"app_theme.dart", "tokens.dart"}


def compute_import_path(file_path):
    lib = LIB_DIR.replace("\\", "/")
    fp  = file_path.replace("\\", "/")
    rel = fp[len(lib)+1:]
    depth = rel.count("/")
    prefix = "../" * depth
    return f"import '{prefix}theme/app_theme.dart';"


def has_app_theme_import(content):
    return "app_theme.dart" in content


def fix_file(file_path):
    """
    Replace 'color: Colors.white' in decoration/container contexts.
    We use a line-by-line approach to be context-aware.
    """
    with open(file_path, encoding="utf-8", errors="replace") as f:
        original = f.read()

    lines = original.splitlines(keepends=True)
    changed_lines = []
    any_change = False

    for i, line in enumerate(lines):
        new_line = line

        # Only process lines that contain Colors.white (not Colors.white70/38/etc.)
        if re.search(r'\bColors\.white\b', line):
            stripped = line.strip()

            # KEEP: foregroundColor: Colors.white (button text, intentional)
            # KEEP: style: TextStyle(color: Colors.white ...) (button label text)
            # KEEP: CircularProgressIndicator(color: Colors.white ...)
            # KEEP: Colors.white on lines that also have backgroundColor: or foregroundColor:
            # KEEP: Icon(..., color: Colors.white) on colored backgrounds
            # KEEP: Colors.white70 (slightly transparent white, always intentional)
            # KEEP: Text('...', style: TextStyle(color: Colors.white ...))
            # KEEP: ElevatedButton.styleFrom(foregroundColor: Colors.white ...)
            # KEEP: SnackBar content text (white on colored bg)
            # KEEP: withValues(alpha: 0.2) type patterns

            skip_keywords = [
                'foregroundColor:',
                'TextStyle(',
                'CircularProgressIndicator(',
                'ProgressIndicator',
                'backgroundColor:',  # keep on buttons
                '.styleFrom(',
                'Icon(',
                'Colors.white70',
                'Colors.white.withValues',
                'withValues(alpha:',
                'SnackBar(',
                'ElevatedButton',
                'OutlinedButton',
                'FilledButton',
                # Patterns where white is explicitly on a dark/colored background
                'child: const Icon',
                'child: Icon(',
                'color: Colors.white)',  # lone line — might be icon
                'Colors.white, size:',
                'Colors.white, fontSize',
            ]

            should_skip = any(kw in line for kw in skip_keywords)

            # REPLACE: 'color: Colors.white' in decoration contexts (BoxDecoration, Container)
            # These typically look like:
            #   color: Colors.white,
            #   color: Colors.white,
            #   fillColor: Colors.white → already handled in phase 3
            if not should_skip:
                # Replace 'color: Colors.white,' → 'color: Theme.of(context).cardColor,'
                if re.search(r'\bcolor:\s*Colors\.white\b', line):
                    new_line = re.sub(
                        r'\bcolor:\s*Colors\.white\b',
                        'color: Theme.of(context).cardColor',
                        line
                    )

        if new_line != line:
            any_change = True
        changed_lines.append(new_line)

    if not any_change:
        return False

    content = "".join(changed_lines)

    if "AppColors." in content and not has_app_theme_import(content):
        import_line = compute_import_path(file_path)
        lines2 = content.splitlines(keepends=True)
        insert_idx = 0
        for i, line in enumerate(lines2):
            if line.strip().startswith("import "):
                insert_idx = i + 1
        eol = "\r\n" if "\r\n" in original else "\n"
        lines2.insert(insert_idx, import_line + eol)
        content = "".join(lines2)

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

    print(f"Changed {len(changed)} files:")
    for f in changed:
        print(f"  {f}")


if __name__ == "__main__":
    main()
