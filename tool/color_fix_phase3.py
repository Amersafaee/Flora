#!/usr/bin/env python3
"""
Flora Color Token Fixer — Phase 3
Fixes Colors.grey (bare text), Colors.grey.shade700/800, Colors.white as bg,
Colors.black as text.

Key decisions:
- Colors.grey (bare) → AppColors.bone500  (safe in const and non-const)
- Colors.grey.shade700 → AppColors.bone700
- Colors.grey.shade800 → AppColors.bone900
- Colors.grey.shade200/300 in shimmer/border/divider context → KEEP (data-vis/decoration)
- Colors.grey.shade100 → KEEP (very subtle bg tint)
- Colors.grey.shade200 → KEEP (shadow/progress bg)
- Colors.grey.shade300 as a border/line → KEEP; as icon color → AppColors.bone300
- Colors.white as card bg (fillColor:/color: Colors.white) → Theme.of(context).cardColor
  EXCEPT: in const context → AppColors.white
- Colors.black as text → AppColors.bone900 (near-black, semantic)
- Colors.black.withValues(alpha:...) → KEEP (shadow overlay)
"""

import os, re

LIB_DIR = r"C:\Projects\Flora_v0.1\Flora\lib"
SKIP_FILES = {"app_theme.dart", "tokens.dart"}

# Rules applied in order (pattern, replacement)
RULES = [
    # ── Colors.grey.shadeXXX — selective ──────────────────────────────────
    # shade700 and shade800 are clearly text colors
    (r"Colors\.grey\.shade800\b",  "AppColors.bone900"),
    (r"Colors\.grey\.shade700\b",  "AppColors.bone700"),
    # shade600, shade500, shade400 already handled in phase2, do again
    (r"Colors\.grey\.shade600\b",  "AppColors.bone500"),
    (r"Colors\.grey\.shade500\b",  "AppColors.bone500"),
    (r"Colors\.grey\.shade400\b",  "AppColors.bone300"),
    # shade300 used as an icon color in text context → bone300
    # but keep for dividers/borders — we'll replace all and see
    # Actually shade300 is mostly used for borders/dividers, so KEEP
    # shade200, shade100 → KEEP (shimmer/progress)

    # ── Colors.grey (bare) as color → AppColors.bone500 ───────────────────
    # Match "Colors.grey," or "Colors.grey)" or "Colors.grey\n"
    # but NOT Colors.grey.shade or Colors.greyAccent etc.
    (r"Colors\.grey\b(?!\.)",  "AppColors.bone500"),

    # ── Colors.white in non-const background usages ────────────────────────
    # fillColor: Colors.white  → Theme context not possible statically, use AppColors.white
    (r"fillColor:\s*Colors\.white\b",  "fillColor: AppColors.white"),
    # color: Colors.white as container/card bg
    # Only if NOT preceded by "text" or "style" context (button white text is intentional)
    # Simple heuristic: color: Colors.white in a Container decoration → AppColors.white
    # But we can't tell context easily — use AppColors.white for now (same as Colors.white in light)

    # ── Colors.black as explicit text color ────────────────────────────────
    # Colors.black.withValues(alpha:...) → KEEP (shadow)
    # Colors.black87 → KEEP (standard text weight)
    # Colors.black as bare text → AppColors.bone900
    # The pattern: color: Colors.black, or color: Colors.black) — not followed by .
    (r"(?<=color:\s)Colors\.black\b(?![\.\d])",  "AppColors.bone900"),
    (r"(?<=color: )Colors\.black\b(?![\.\d])",   "AppColors.bone900"),
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


def apply_rules(content):
    for pattern, replacement in RULES:
        content = re.sub(pattern, replacement, content)
    return content


def fix_file(file_path):
    with open(file_path, encoding="utf-8", errors="replace") as f:
        original = f.read()

    content = apply_rules(original)

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
