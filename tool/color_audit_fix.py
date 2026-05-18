#!/usr/bin/env python3
"""
Flora Color Audit Fix
Replaces hardcoded colors with AppColors tokens across all Dart files.
Run from: C:\\Projects\\Flora_v0.1\\Flora
"""

import os
import re
import sys

LIB_DIR = r"C:\Projects\Flora_v0.1\Flora\lib"

# Files to skip (they define the tokens themselves)
SKIP_FILES = {"app_theme.dart", "tokens.dart"}

# ─────────────────────────────────────────────────────────────────────────────
# Replacement rules — applied in order.
# (regex_pattern, replacement_string)
# Ordered from most-specific to least-specific.
# ─────────────────────────────────────────────────────────────────────────────
RULES = [
    # ── Primary forest greens ──────────────────────────────────────────────
    (r"const Color\(0xFF154212\)",        "AppColors.forest900"),
    (r"Color\(0xFF154212\)",              "AppColors.forest900"),
    (r"const Color\(0xFF2F5D3A\)",        "AppColors.forest700"),
    (r"Color\(0xFF2F5D3A\)",              "AppColors.forest700"),
    (r"const Color\(0xFF2D5A27\)",        "AppColors.forest700"),
    (r"Color\(0xFF2D5A27\)",              "AppColors.forest700"),
    (r"const Color\(0xFF2D5016\)",        "AppColors.forest900"),
    (r"Color\(0xFF2D5016\)",              "AppColors.forest900"),
    (r"Color\(0x332D5016\)",              "AppColors.forest900.withValues(alpha: 0.2)"),
    (r"const Color\(0xFF2E7D32\)",        "AppColors.forest600"),
    (r"Color\(0xFF2E7D32\)",              "AppColors.forest600"),

    # ── Terracotta accent ──────────────────────────────────────────────────
    (r"const Color\(0xFF8D3220\)",        "AppColors.terracotta900"),
    (r"Color\(0xFF8D3220\)",              "AppColors.terracotta900"),

    # ── Soft green surfaces ────────────────────────────────────────────────
    (r"const Color\(0xFFE8F5E9\)",        "AppColors.forest100"),
    (r"Color\(0xFFE8F5E9\)",              "AppColors.forest100"),
    (r"const Color\(0xFFE8F3EA\)",        "AppColors.forest100"),
    (r"Color\(0xFFE8F3EA\)",              "AppColors.forest100"),
    (r"const Color\(0xFFF0F7F0\)",        "AppColors.forest100"),
    (r"Color\(0xFFF0F7F0\)",              "AppColors.forest100"),
    (r"const Color\(0xFFF0F5F1\)",        "AppColors.forest100"),
    (r"Color\(0xFFF0F5F1\)",              "AppColors.forest100"),

    # ── Dark mode flora chat bubble / dark green card ─────────────────────
    (r"const Color\(0xFF1E3A1E\)",        "AppColors.darkForestSubtle"),
    (r"Color\(0xFF1E3A1E\)",              "AppColors.darkForestSubtle"),

    # ── Dark card/surface ──────────────────────────────────────────────────
    (r"const Color\(0xFF1E211E\)",        "AppColors.darkSurface"),
    (r"Color\(0xFF1E211E\)",              "AppColors.darkSurface"),

    # ── Page backgrounds ───────────────────────────────────────────────────
    (r"const Color\(0xFFF8FAF8\)",        "AppColors.bone25"),
    (r"Color\(0xFFF8FAF8\)",              "AppColors.bone25"),
    (r"const Color\(0xFF121212\)",        "AppColors.darkCanvas"),
    (r"Color\(0xFF121212\)",              "AppColors.darkCanvas"),
    (r"const Color\(0xFF111827\)",        "AppColors.darkCanvas"),
    (r"Color\(0xFF111827\)",              "AppColors.darkCanvas"),

    # ── On-surface / primary text ──────────────────────────────────────────
    (r"const Color\(0xFF191C1B\)",        "AppColors.bone900"),
    (r"Color\(0xFF191C1B\)",              "AppColors.bone900"),
    (r"const Color\(0xFF1F2937\)",        "AppColors.bone900"),
    (r"Color\(0xFF1F2937\)",              "AppColors.bone900"),

    # ── Secondary text shades ──────────────────────────────────────────────
    (r"const Color\(0xFF6B7280\)",        "AppColors.bone500"),
    (r"Color\(0xFF6B7280\)",              "AppColors.bone500"),

    # ── Onboarding muted green ─────────────────────────────────────────────
    (r"const Color\(0xFF6B8F5E\)",        "AppColors.forest500"),
    (r"Color\(0xFF6B8F5E\)",              "AppColors.forest500"),

    # ── Chip / badge border grey ───────────────────────────────────────────
    (r"const Color\(0xFFCCCCCC\)",        "AppColors.bone300"),
    (r"Color\(0xFFCCCCCC\)",              "AppColors.bone300"),

    # ── Colors.grey shades used as secondary/hint text ─────────────────────
    # Note: .shade200/300 in shimmer/progress bars is left intentional
    (r"Colors\.grey\.shade600",           "AppColors.bone500"),
    (r"Colors\.grey\.shade500",           "AppColors.bone500"),
    (r"Colors\.grey\.shade400",           "AppColors.bone300"),
]

# ─────────────────────────────────────────────────────────────────────────────
# Compute correct relative import path for app_theme.dart
# ─────────────────────────────────────────────────────────────────────────────
def compute_import_path(file_path):
    lib = LIB_DIR.replace("\\", "/")
    fp  = file_path.replace("\\", "/")
    rel = fp[len(lib)+1:]   # e.g. "screens/care_screen.dart"
    depth = rel.count("/")  # 1 for screens/x.dart, 2 for features/x/y.dart
    prefix = "../" * depth
    return f"import '{prefix}theme/app_theme.dart';"


def needs_app_colors(content):
    return "AppColors." in content


def has_app_theme_import(content):
    return "app_theme.dart" in content


def apply_rules(content):
    for pattern, replacement in RULES:
        content = re.sub(pattern, replacement, content)
    return content


def fix_file(file_path):
    """Read, transform, write a single file. Returns (changed, n_rules_matched)."""
    with open(file_path, encoding="utf-8", errors="replace") as f:
        original = f.read()

    content = apply_rules(original)

    # Add import if we've introduced AppColors references and it's not present
    if needs_app_colors(content) and not has_app_theme_import(content):
        import_line = compute_import_path(file_path)
        # Insert after the last existing import line
        lines = content.splitlines(keepends=True)
        insert_idx = 0
        for i, line in enumerate(lines):
            stripped = line.strip()
            if stripped.startswith("import "):
                insert_idx = i + 1
        eol = "\r\n" if "\r\n" in content else "\n"
        lines.insert(insert_idx, import_line + eol)
        content = "".join(lines)

    if content == original:
        return False, 0

    n_matched = sum(1 for p, _ in RULES if re.search(p, original))

    # Preserve original line endings
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

    return True, n_matched


def main():
    changed_files = []
    skipped_files = []
    errors = []

    for root, dirs, files in os.walk(LIB_DIR):
        for fname in sorted(files):
            if not fname.endswith(".dart"):
                continue
            if fname in SKIP_FILES:
                skipped_files.append(fname)
                continue
            fpath = os.path.join(root, fname)
            try:
                changed, n = fix_file(fpath)
                if changed:
                    rel = fpath[len(LIB_DIR)+1:]
                    changed_files.append((rel, n))
            except Exception as e:
                errors.append((fpath, str(e)))

    print(f"\nFixed {len(changed_files)} files:")
    for fname, n in sorted(changed_files):
        print(f"   {fname}  ({n} rule hits)")

    if skipped_files:
        print(f"\nSkipped (theme definitions): {', '.join(skipped_files)}")

    if errors:
        print(f"\nERRORS in {len(errors)} files:")
        for fpath, err in errors:
            print(f"   {fpath}: {err}")
        sys.exit(1)

    print("\nDone.")


if __name__ == "__main__":
    main()
