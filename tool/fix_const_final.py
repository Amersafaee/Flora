#!/usr/bin/env python3
"""
Final comprehensive fix for const_eval_method_invocation.
Scans ALL dart files for `const SomeThing(` that spans multiple lines 
and contains `Theme.of(context)` — removes the `const` keyword.

Also specifically handles:
- `const TextStyle(color: Theme.of(context)...` → `TextStyle(color: Colors.white...`
  (white text on colored buttons/badges — the original intent)
- `const BoxDecoration(color: Theme.of(context)...` → `BoxDecoration(color: Theme.of(context)...`
- `const Icon(... color: Theme.of(context)...` → `Icon(... color: Colors.white...`
"""

import os, re

LIB_DIR = r"C:\Projects\Flora_v0.1\Flora\lib"
SKIP_FILES = {"app_theme.dart", "tokens.dart"}


def is_spinner_context(lines, idx):
    """Check if the line is inside a CircularProgressIndicator."""
    context = "\n".join(lines[max(0, idx-5):idx+1])
    return ("CircularProgressIndicator" in context or 
            "strokeWidth" in context)


def fix_const_theme_multiline(content):
    """
    Multi-pass fix for const + Theme.of(context) on different lines.
    
    Scan line by line tracking `const` keywords.
    When we see `const Something(` we track until the matching `)`.
    If the block contains `Theme.of(context)`, remove the `const`.
    """
    lines = content.splitlines(keepends=True)
    result_lines = list(lines)
    
    i = 0
    while i < len(result_lines):
        line = result_lines[i]
        
        # Single-line fix: const Foo(... Theme.of(context)...) on same line
        if "const" in line and "Theme.of(context)" in line:
            # Determine if this is white-text-on-button context (should be Colors.white)
            if re.search(r"const\s+TextStyle\(.*color:\s*Theme\.of\(context\)\.cardColor", line):
                # White text label on button → Colors.white
                result_lines[i] = re.sub(
                    r"\bconst\s+TextStyle\(",
                    "TextStyle(",
                    line
                )
                result_lines[i] = re.sub(
                    r"color:\s*Theme\.of\(context\)\.cardColor",
                    "color: Colors.white",
                    result_lines[i]
                )
            elif re.search(r"const\s+Icon\(.*color:\s*Theme\.of\(context\)\.cardColor", line):
                # Icon on button → Colors.white
                result_lines[i] = re.sub(
                    r"\bconst\s+Icon\(",
                    "Icon(",
                    line
                )
                result_lines[i] = re.sub(
                    r"color:\s*Theme\.of\(context\)\.cardColor",
                    "color: Colors.white",
                    result_lines[i]
                )
            else:
                # Generic: just remove const
                result_lines[i] = re.sub(r"\bconst\s+(?=[A-Z])", "", line)
        
        # Multi-line: `const TextStyle(` on line i, `Theme.of(context)` on line i+j
        # Look for `const SomeThing(` patterns
        if re.search(r"\bconst\s+(TextStyle|BoxDecoration|Icon|Text|Padding|SizedBox|Row|Column|Container)\s*\(", line):
            # Look ahead for Theme.of(context) in next 10 lines
            window_end = min(len(result_lines), i + 15)
            window = "".join(result_lines[i:window_end])
            
            if "Theme.of(context)" in window:
                # Remove const from this line
                widget_match = re.search(r"\bconst\s+(TextStyle|BoxDecoration|Icon|Text)\s*\(", result_lines[i])
                if widget_match:
                    widget = widget_match.group(1)
                    old_line = result_lines[i]
                    new_line = re.sub(r"\bconst\s+" + widget + r"\s*\(", widget + "(", old_line)
                    
                    if widget in ("TextStyle", "Icon"):
                        # These were originally Colors.white — fix the color too
                        # Find the color: Theme.of(context).cardColor line in window
                        for j in range(i, window_end):
                            if "Theme.of(context).cardColor" in result_lines[j]:
                                ctx = "".join(result_lines[max(0,i-3):i+1])
                                is_spinner = is_spinner_context(result_lines, j)
                                if not is_spinner:
                                    result_lines[j] = re.sub(
                                        r"Theme\.of\(context\)\.cardColor",
                                        "Colors.white",
                                        result_lines[j]
                                    )
                    else:
                        # BoxDecoration, Container, etc. — just remove const
                        pass
                    
                    result_lines[i] = new_line
        
        i += 1
    
    return "".join(result_lines)


def fix_file(file_path):
    with open(file_path, encoding="utf-8", errors="replace") as f:
        original = f.read()
    
    content = fix_const_theme_multiline(original)
    
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
    
    print(f"Fixed {len(changed)} files:")
    for f in changed:
        print(f"  {f}")


if __name__ == "__main__":
    main()
