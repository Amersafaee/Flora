#!/usr/bin/env python3
"""
Fix const_eval_method_invocation errors in Flora codebase.

Pattern 1: const [ BoxShadow(color: AppColors.xxx.withValues(alpha: N), ...) ]
  → Remove withValues call and replace with pre-computed hex Color.

Pattern 2: boxShadow: const [BoxShadow(color: AppColors.xxx.withValues(...))]
  → Make the BoxShadow non-const if the color has .withValues()

Strategy: For each BoxShadow with .withValues(alpha: X) in a const list,
  we remove 'const' from the list and from the BoxShadow, so it's computed at runtime.

Actually the cleanest fix: just remove 'const' from the BoxShadow list brackets
wherever AppColors.xxx.withValues() appears inside.
"""

import os, re

LIB_DIR = r"C:\Projects\Flora_v0.1\Flora\lib"
SKIP_FILES = {"app_theme.dart", "tokens.dart"}


def fix_const_boxshadow(content):
    """
    Find `const [BoxShadow(color: AppColors.xxx.withValues(alpha: ...)` 
    and remove the `const` from the list.
    
    Also find `const BoxShadow(color: AppColors.xxx.withValues(...)` and remove const.
    """
    # Remove const from BoxShadow lists that contain .withValues()
    # Pattern: `const [` followed eventually by `.withValues(` on same block
    # Simple approach: remove `const` from any BoxShadow line that has .withValues
    lines = content.splitlines(keepends=True)
    new_lines = []
    
    for line in lines:
        new_line = line
        
        # If this line has BoxShadow( with a color that has .withValues(
        if 'BoxShadow(' in line and '.withValues(' in line:
            # Remove `const ` from this line
            new_line = re.sub(r'\bconst\s+BoxShadow\b', 'BoxShadow', new_line)
        
        # If this line starts a const list `const [` and the next few lines have .withValues,
        # we need to remove the const. But we can't do multi-line here easily.
        # Instead, look for `const [` followed by BoxShadow with .withValues on same line
        if re.search(r'const\s*\[', new_line) and '.withValues(' in new_line:
            new_line = re.sub(r'\bconst\s*\[', '[', new_line)
        
        new_lines.append(new_line)
    
    return "".join(new_lines)


def fix_const_boxshadow_multiline(content):
    """
    Handle multi-line const BoxShadow patterns.
    
    Pattern:
      boxShadow: const [
        BoxShadow(
          color: AppColors.forest900.withValues(alpha: 0.2),
          ...
        ),
      ],
    
    We need to remove 'const' from the list, and the BoxShadow itself becomes non-const.
    """
    # Match: (const\s*\[)\s*\n\s*BoxShadow\( ... .withValues\(
    # Replace: remove 'const' from the list bracket
    
    # Strategy: find 'const [' where the next non-empty token group contains .withValues
    # We'll use a multi-line scan approach
    
    result = re.sub(
        r'\bconst\s*(\[\s*\n(?:[ \t]*(?:BoxShadow|//).*\n)*?[ \t]*BoxShadow\([^)]*?\.withValues\()',
        r'\1',
        content,
        flags=re.DOTALL
    )
    
    # Also fix: const [ BoxShadow( color: Xxx.withValues( on separate lines
    # Find pattern: const [\n ... BoxShadow\n ... .withValues(
    # Use line-based scan
    
    # Find all occurrences of 'const [' followed by BoxShadow with .withValues in the block
    lines = result.split('\n')
    output_lines = []
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Look for 'const [' start
        if re.search(r'\bconst\s*\[', line):
            # Look ahead in the next ~15 lines for .withValues(
            window = '\n'.join(lines[i:min(i+20, len(lines))])
            if '.withValues(' in window:
                # Remove const from this line's [
                line = re.sub(r'\bconst\s*\[', '[', line)
        
        output_lines.append(line)
        i += 1
    
    return '\n'.join(output_lines)


def fix_file(file_path):
    with open(file_path, encoding="utf-8", errors="replace") as f:
        original = f.read()
    
    content = fix_const_boxshadow(original)
    content = fix_const_boxshadow_multiline(content)
    
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
    
    print(f"Fixed const/BoxShadow in {len(changed)} files:")
    for f in changed:
        print(f"  {f}")


if __name__ == "__main__":
    main()
