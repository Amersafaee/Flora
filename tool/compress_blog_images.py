"""
compress_blog_images.py
Compresses every JPEG in assets/blog_images/ in-place:
  - Max width: 1200 px (keeps aspect ratio)
  - JPEG quality: 75
  - Skips files already under 300 KB
Run from the project root:
  python tool/compress_blog_images.py
"""

import os
from pathlib import Path
from PIL import Image

ASSET_DIR = Path("assets/blog_images")
MAX_WIDTH = 1200
JPEG_QUALITY = 75
SKIP_THRESHOLD_BYTES = 300 * 1024  # 300 KB

def human(n: int) -> str:
    if n >= 1_048_576:
        return f"{n / 1_048_576:.1f} MB"
    return f"{n / 1024:.1f} KB"

def compress_image(path: Path) -> None:
    original_size = path.stat().st_size

    if original_size < SKIP_THRESHOLD_BYTES:
        print(f"  ⏩ SKIP  {path.name}  ({human(original_size)} — already under 300 KB)")
        return

    with Image.open(path) as img:
        # Convert palette/RGBA images so JPEG save works
        if img.mode in ("P", "RGBA", "LA"):
            img = img.convert("RGB")

        original_mode = img.mode
        original_w, original_h = img.size

        # Resize only if wider than MAX_WIDTH
        if original_w > MAX_WIDTH:
            ratio = MAX_WIDTH / original_w
            new_size = (MAX_WIDTH, int(original_h * ratio))
            img = img.resize(new_size, Image.LANCZOS)
        
        img.save(path, "JPEG", quality=JPEG_QUALITY, optimize=True)

    new_size = path.stat().st_size
    reduction = (original_size - new_size) / original_size * 100
    print(
        f"  ✅ COMPRESSED  {path.name}\n"
        f"     Before: {human(original_size)}  →  After: {human(new_size)}"
        f"  (−{reduction:.0f}%)"
    )

def main():
    print(f"\n🗜️  Compressing images in {ASSET_DIR}/\n")
    print(f"   Max width : {MAX_WIDTH}px")
    print(f"   Quality   : {JPEG_QUALITY}")
    print(f"   Skip if   : < {SKIP_THRESHOLD_BYTES // 1024} KB\n")

    files = sorted(ASSET_DIR.glob("*.jpg")) + sorted(ASSET_DIR.glob("*.jpeg"))

    if not files:
        print("  ⚠️  No .jpg files found.")
        return

    for f in files:
        try:
            compress_image(f)
        except Exception as e:
            print(f"  ❌ ERROR  {f.name}: {e}")

    print("\nDone.\n")

if __name__ == "__main__":
    main()
