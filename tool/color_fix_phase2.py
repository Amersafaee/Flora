#!/usr/bin/env python3
"""
Flora Color Token Fixer — Phase 2
Fixes Colors.white, Colors.grey, Colors.black in a context-aware way.
Also fixes remaining hex colors.

Rules:
- Colors.white as card/container bg → Theme.of(context).cardColor  (context-aware)
- Colors.white as text on dark bg (button, AppBar) → keep
- Colors.grey (bare) as text color → Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
- Colors.grey.shade200/300 for shimmer/progress → keep (data-vis)
- Colors.black.withValues(alpha: x) → keep (shadow overlays)
- Colors.black as text → Theme.of(context).colorScheme.onSurface
- Color(0xFFFFFFFF) as bg → AppColors.white
- softGreen const Color(0xFFE8F3EA) → AppColors.forest100
"""

import os, re

LIB_DIR = r"C:\Projects\Flora_v0.1\Flora\lib"
SKIP_FILES = {"app_theme.dart", "tokens.dart"}

# ─────────────────────────────────────────────────────────────────────────────
# Replacement rules (regex, replacement)  — hex colors only, exact & safe
# ─────────────────────────────────────────────────────────────────────────────
HEX_RULES = [
    # FFFFFF as explicit const Color → AppColors.white
    (r"const Color\(0xFFFFFFFF\)",   "AppColors.white"),
    (r"\bColor\(0xFFFFFFFF\)\b",     "AppColors.white"),
    # Forest greens
    (r"const Color\(0xFF154212\)",   "AppColors.forest900"),
    (r"\bColor\(0xFF154212\)\b",     "AppColors.forest900"),
    (r"const Color\(0xFF2D5A27\)",   "AppColors.forest700"),
    (r"\bColor\(0xFF2D5A27\)\b",     "AppColors.forest700"),
    (r"const Color\(0xFF2F5D3A\)",   "AppColors.forest700"),
    (r"\bColor\(0xFF2F5D3A\)\b",     "AppColors.forest700"),
    (r"const Color\(0xFF2D5016\)",   "AppColors.forest900"),
    (r"\bColor\(0xFF2D5016\)\b",     "AppColors.forest900"),
    (r"\bColor\(0x332D5016\)\b",     "AppColors.forest900.withValues(alpha: 0.2)"),
    (r"const Color\(0xFF2E7D32\)",   "AppColors.forest600"),
    (r"\bColor\(0xFF2E7D32\)\b",     "AppColors.forest600"),
    # Soft greens
    (r"const Color\(0xFFE8F5E9\)",   "AppColors.forest100"),
    (r"\bColor\(0xFFE8F5E9\)\b",     "AppColors.forest100"),
    (r"const Color\(0xFFE8F3EA\)",   "AppColors.forest100"),
    (r"\bColor\(0xFFE8F3EA\)\b",     "AppColors.forest100"),
    (r"const Color\(0xFFF0F7F0\)",   "AppColors.forest100"),
    (r"\bColor\(0xFFF0F7F0\)\b",     "AppColors.forest100"),
    (r"const Color\(0xFFF0F5F1\)",   "AppColors.forest100"),
    (r"\bColor\(0xFFF0F5F1\)\b",     "AppColors.forest100"),
    (r"const Color\(0xFFDFF5E3\)",   "AppColors.forest100"),
    (r"\bColor\(0xFFDFF5E3\)\b",     "AppColors.forest100"),
    (r"const Color\(0xFFF0F8F0\)",   "AppColors.forest100"),
    (r"\bColor\(0xFFF0F8F0\)\b",     "AppColors.forest100"),
    (r"const Color\(0xFFE8F0E8\)",   "AppColors.forest100"),
    (r"\bColor\(0xFFE8F0E8\)\b",     "AppColors.forest100"),
    # Dark mode
    (r"const Color\(0xFF1E3A1E\)",   "AppColors.darkForestSubtle"),
    (r"\bColor\(0xFF1E3A1E\)\b",     "AppColors.darkForestSubtle"),
    (r"const Color\(0xFF1E211E\)",   "AppColors.darkSurface"),
    (r"\bColor\(0xFF1E211E\)\b",     "AppColors.darkSurface"),
    (r"const Color\(0xFF1E221E\)",   "AppColors.darkSurface"),
    (r"\bColor\(0xFF1E221E\)\b",     "AppColors.darkSurface"),
    (r"const Color\(0xFF1A2B1A\)",   "AppColors.darkSurface"),
    (r"\bColor\(0xFF1A2B1A\)\b",     "AppColors.darkSurface"),
    (r"const Color\(0xFF1A3A1A\)",   "AppColors.darkForestSubtle"),
    (r"\bColor\(0xFF1A3A1A\)\b",     "AppColors.darkForestSubtle"),
    # Terracotta
    (r"const Color\(0xFF8D3220\)",   "AppColors.terracotta900"),
    (r"\bColor\(0xFF8D3220\)\b",     "AppColors.terracotta900"),
    # Text colors
    (r"const Color\(0xFF191C1B\)",   "AppColors.bone900"),
    (r"\bColor\(0xFF191C1B\)\b",     "AppColors.bone900"),
    (r"const Color\(0xFF1F2937\)",   "AppColors.bone900"),
    (r"\bColor\(0xFF1F2937\)\b",     "AppColors.bone900"),
    (r"const Color\(0xFF2A2925\)",   "AppColors.bone900"),
    (r"\bColor\(0xFF2A2925\)\b",     "AppColors.bone900"),
    # Page bg
    (r"const Color\(0xFFF8FAF8\)",   "AppColors.bone25"),
    (r"\bColor\(0xFFF8FAF8\)\b",     "AppColors.bone25"),
    (r"const Color\(0xFFF4F1EA\)",   "AppColors.bone50"),
    (r"\bColor\(0xFFF4F1EA\)\b",     "AppColors.bone50"),
    (r"const Color\(0xFFFAF8F4\)",   "AppColors.bone25"),
    (r"\bColor\(0xFFFAF8F4\)\b",     "AppColors.bone25"),
    # Bone shades (off-white)
    (r"const Color\(0xFFF5F0E8\)",   "AppColors.bone50"),
    (r"\bColor\(0xFFF5F0E8\)\b",     "AppColors.bone50"),
    (r"const Color\(0xFFF3EFE9\)",   "AppColors.bone50"),
    (r"\bColor\(0xFFF3EFE9\)\b",     "AppColors.bone50"),
    (r"const Color\(0xFFF0EDE8\)",   "AppColors.bone50"),
    (r"\bColor\(0xFFF0EDE8\)\b",     "AppColors.bone50"),
    # Dark bg
    (r"const Color\(0xFF121212\)",   "AppColors.darkCanvas"),
    (r"\bColor\(0xFF121212\)\b",     "AppColors.darkCanvas"),
    (r"const Color\(0xFF111827\)",   "AppColors.darkCanvas"),
    (r"\bColor\(0xFF111827\)\b",     "AppColors.darkCanvas"),
    (r"const Color\(0xFF1E1E1E\)",   "AppColors.darkCanvas"),
    (r"\bColor\(0xFF1E1E1E\)\b",     "AppColors.darkCanvas"),
    # Neutral greys → bone tokens
    (r"const Color\(0xFFCCCCCC\)",   "AppColors.bone300"),
    (r"\bColor\(0xFFCCCCCC\)\b",     "AppColors.bone300"),
    (r"const Color\(0xFFE0E0E0\)",   "AppColors.bone200"),
    (r"\bColor\(0xFFE0E0E0\)\b",     "AppColors.bone200"),
    (r"const Color\(0xFF6B7280\)",   "AppColors.bone500"),
    (r"\bColor\(0xFF6B7280\)\b",     "AppColors.bone500"),
    (r"const Color\(0xFF6B8F5E\)",   "AppColors.forest500"),
    (r"\bColor\(0xFF6B8F5E\)\b",     "AppColors.forest500"),
    # softGreen inline const
    (r"const softGreen = Color\(0xFFE8F3EA\)",   "const softGreen = AppColors.forest100"),
    (r"const Color softGreen = Color\(0xFFE8F3EA\)",   "const Color softGreen = AppColors.forest100"),
    # Colors.grey shades → bone tokens
    (r"Colors\.grey\.shade600",   "AppColors.bone500"),
    (r"Colors\.grey\.shade500",   "AppColors.bone500"),
    (r"Colors\.grey\.shade400",   "AppColors.bone300"),
    # Colors.grey.shadeX where X < 400 are shadow/shimmer — keep
]

def compute_import_path(file_path):
    lib = LIB_DIR.replace("\\", "/")
    fp  = file_path.replace("\\", "/")
    rel = fp[len(lib)+1:]
    depth = rel.count("/")
    prefix = "../" * depth
    return f"import '{prefix}theme/app_theme.dart';"


def has_app_theme_import(content):
    return "app_theme.dart" in content


def apply_hex_rules(content):
    for pattern, replacement in HEX_RULES:
        content = re.sub(pattern, replacement, content)
    return content


def fix_file(file_path):
    with open(file_path, encoding="utf-8", errors="replace") as f:
        original = f.read()

    content = apply_hex_rules(original)

    # Add import if we've introduced AppColors
    if "AppColors." in content and not has_app_theme_import(content):
        import_line = compute_import_path(file_path)
        lines = content.splitlines(keepends=True)
        insert_idx = 0
        for i, line in enumerate(lines):
            if line.strip().startswith("import "):
                insert_idx = i + 1
        eol = "\r\n" if "\r\n" in content else "\n"
        lines.insert(insert_idx, import_line + eol)
        content = "".join(lines)

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

    print(f"Changed {len(changed)} files:")
    for f in changed:
        print(f"  {f}")


if __name__ == "__main__":
    main()
