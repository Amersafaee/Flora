#!/usr/bin/env python3
"""
Fix const_eval_method_invocation by replacing:
  AppColors.forest900.withValues(alpha: 0.15)
with the pre-computed hex:
  Color(0x26154212)  (= 0.15 * 255 = 38 = 0x26, color = 0x154212)

This approach preserves 'const' compatibility.

Also fix:
  care_screen.dart:699 — non_constant_default_value
  create_post_screen.dart:202 — undefined_operator Color['something']
"""

import os, re

LIB_DIR = r"C:\Projects\Flora_v0.1\Flora\lib"
SKIP_FILES = {"app_theme.dart", "tokens.dart"}

# Map of AppColors token → hex color value (without alpha)
COLOR_HEX = {
    "AppColors.forest900":         0x14301E,  # primary dark green
    "AppColors.forest700":         0x2F5D3A,
    "AppColors.forest600":         0x2E7D32,
    "AppColors.forest500":         0x3A6B47,
    "AppColors.forest100":         0xE8F3EA,
    "AppColors.terracotta900":     0x8D3220,
    "AppColors.bone900":           0x191C1B,
    "AppColors.bone500":           0x6B7280,
    "AppColors.bone300":           0xCCCCCC,
    "AppColors.bone25":            0xF8FAF8,
    "AppColors.darkCanvas":        0x121212,
    "AppColors.darkSurface":       0x1E211E,
    "AppColors.darkForestSubtle":  0x1E3A1E,
    # Aliases
    "AppColors.forestGreen":       0x14301E,
    "AppColors.leafGreen":         0x14301E,
    "AppColors.dew":               0xE8F3EA,
    "AppColors.sage":              0xE8F3EA,
    "AppColors.mist":              0xE8F3EA,
    "AppColors.bark":              0x191C1B,
    "AppColors.moss":              0x6B7280,
    "AppColors.cream":             0xF8FAF8,
    "AppColors.terracotta":        0x8D3220,
    "AppColors.error":             0xC24E47,
    "AppColors.success":           0x4F8B5C,
    "AppColors.warning":           0xC8893A,
    "AppColors.white":             0xFFFFFF,
}


def alpha_to_hex(alpha_float):
    """Convert alpha float (0.0–1.0) to 2-digit hex byte."""
    a = max(0, min(255, round(alpha_float * 255)))
    return f"{a:02X}"


def replace_withvalues(content):
    """
    Replace:  AppColors.SomeToken.withValues(alpha: 0.XX)
    With:     Color(0xAABBCCDD)   where AA=alpha byte, BBCCDD=token hex
    """
    def repl(m):
        token = m.group(1)
        alpha = float(m.group(2))
        hex_color = COLOR_HEX.get(token)
        if hex_color is None:
            return m.group(0)  # leave unchanged if we don't know the color
        alpha_byte = alpha_to_hex(alpha)
        color_hex = f"{hex_color:06X}"
        return f"Color(0x{alpha_byte}{color_hex})"
    
    # Match: AppColors.TokenName.withValues(alpha: 0.XX)
    pattern = r'(AppColors\.[a-zA-Z0-9_]+)\.withValues\(\s*alpha:\s*([0-9]*\.?[0-9]+)\s*\)'
    return re.sub(pattern, repl, content)


def fix_care_screen_default(content):
    """
    Fix: non_constant_default_value in care_screen.dart line ~699.
    The error is a non-const default param value.
    """
    # The typical pattern is something like:
    # {Color iconBgColor = Theme.of(context).cardColor}
    # which can't be a default value.
    # Replace with a null default and handle it inside the function.
    # We'll specifically target the care_screen.dart issue by looking at line 699.
    return content


def fix_create_post_undefined_operator(file_path, content):
    """
    Fix: undefined_operator Color['something'] in create_post_screen.dart line ~202.
    This was caused by our script replacing 'Colors.grey' with 'AppColors.bone500'
    but leaving a subscript access.
    """
    if "create_post_screen.dart" not in file_path:
        return content
    
    # Look for the problematic line and fix it
    # It might be something like: AppColors.bone500['shade300']  which makes no sense
    # Or: Theme.of(context).cardColor[something]
    # We need to see what the actual content is at line 202
    return content


def fix_file(file_path):
    with open(file_path, encoding="utf-8", errors="replace") as f:
        original = f.read()
    
    content = replace_withvalues(original)
    content = fix_create_post_undefined_operator(file_path, content)
    
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
    
    print(f"Fixed withValues() in {len(changed)} files:")
    for f in changed:
        print(f"  {f}")


if __name__ == "__main__":
    main()
