#!/usr/bin/env python3
"""
Fix const_eval_method_invocation errors.
When a `const` BoxDecoration/Container/Widget has a non-const color 
(like Theme.of(context).cardColor), we must remove the `const` keyword.

Also fix the undefined_operator error in create_post_screen.dart.
"""
import os, re

LIB_DIR = r"C:\Projects\Flora_v0.1\Flora\lib"
SKIP_FILES = {"app_theme.dart", "tokens.dart"}

# Files and lines with errors from flutter analyze
# We need to remove `const` from lines/blocks that contain Theme.of(context)

def fix_const_issue(content):
    """
    Remove 'const' from lines where the construction uses non-const values.
    Pattern: `const BoxDecoration(color: Theme.of(context).cardColor ...)`
    We handle the common patterns:
    1. `const BoxDecoration(color: Theme.of(context)...`  → remove const
    2. `const Container(decoration: const BoxDecoration(color: Theme.of(...)` → remove inner const
    """
    # Remove 'const ' before BoxDecoration( where that BoxDecoration contains Theme.of
    # This is complex to do perfectly, but we can use a simpler heuristic:
    # Any line with `const BoxDecoration(` or `const Container(` that has Theme.of(context)
    # in the same logical expression → remove const.
    
    # Strategy: Find all `const SomeThing(` patterns and check if same line has Theme.of
    
    lines = content.splitlines(keepends=True)
    new_lines = []
    
    for line in lines:
        # If line has `const` AND `Theme.of(context)` in it — remove the `const`
        if 'const' in line and 'Theme.of(context)' in line:
            # Remove leading `const ` before a capitalized widget name or BoxDecoration
            new_line = re.sub(r'\bconst\s+(?=[A-Z])', '', line)
            new_lines.append(new_line)
        else:
            new_lines.append(line)
    
    return "".join(new_lines)


def fix_undefined_operator(content, file_path):
    """Fix Colors.grey['shade'] type operator errors."""
    # The error in create_post_screen.dart is likely:
    # Color(0x...)['something'] which is invalid
    # We skip this for now and handle it manually
    return content


def fix_file(file_path):
    with open(file_path, encoding="utf-8", errors="replace") as f:
        original = f.read()
    
    content = fix_const_issue(original)
    content = fix_undefined_operator(content, file_path)
    
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
    
    print(f"Fixed const issues in {len(changed)} files:")
    for f in changed:
        print(f"  {f}")


if __name__ == "__main__":
    main()
