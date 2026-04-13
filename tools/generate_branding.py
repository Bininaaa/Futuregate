"""
Generate Android launcher icons, adaptive icons, splash drawable,
web icons, and favicon from the new FutureGate branding assets.

Source assets (in assets/pictures/):
  ICON.png  — icon-only mark  → launcher icons, splash, web icons, favicon
  NAME.png  — full wordmark    → in-app Flutter branding (resolution copies)

Re-run with: python tools/generate_branding.py
"""

import os
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
ICON_SRC = os.path.join(ROOT, 'assets', 'pictures', 'ICON.png')
NAME_SRC = os.path.join(ROOT, 'assets', 'pictures', 'NAME.png')
ANDROID_RES = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')
FLUTTER_BRANDING = os.path.join(ROOT, 'assets', 'images', 'branding')
WEB_DIR = os.path.join(ROOT, 'web')

BG_COLOR = (255, 255, 255, 255)  # clean white background for the launcher / splash

# Legacy ic_launcher sizes (per density, for 48dp)
LEGACY_SIZES = {
    'mipmap-mdpi':    48,
    'mipmap-hdpi':    72,
    'mipmap-xhdpi':   96,
    'mipmap-xxhdpi':  144,
    'mipmap-xxxhdpi': 192,
}

# Adaptive icon foreground sizes (full 108dp canvas, per density)
ADAPTIVE_FG_SIZES = {
    'mipmap-mdpi':    108,
    'mipmap-hdpi':    162,
    'mipmap-xhdpi':   216,
    'mipmap-xxhdpi':  324,
    'mipmap-xxxhdpi': 432,
}

# Splash icon sizes for legacy launch_background
SPLASH_SIZES = {
    'drawable-mdpi':    192,
    'drawable-hdpi':    288,
    'drawable-xhdpi':   384,
    'drawable-xxhdpi':  576,
    'drawable-xxxhdpi': 768,
}

# Web icon sizes
WEB_ICON_SIZES = {
    'Icon-192': 192,
    'Icon-512': 512,
    'Icon-maskable-192': 192,
    'Icon-maskable-512': 512,
}

FAVICON_SIZE = 32


def load_trimmed(path):
    im = Image.open(path).convert('RGBA')
    alpha = im.split()[-1]
    bbox = alpha.getbbox()
    if bbox:
        im = im.crop(bbox)
    return im


def fit_contain(img, box_w, box_h):
    """Resize img to fit inside box_w x box_h preserving aspect ratio."""
    iw, ih = img.size
    scale = min(box_w / iw, box_h / ih)
    nw, nh = max(1, int(iw * scale)), max(1, int(ih * scale))
    return img.resize((nw, nh), Image.LANCZOS)


def paste_centered(canvas, img):
    cw, ch = canvas.size
    iw, ih = img.size
    canvas.paste(img, ((cw - iw) // 2, (ch - ih) // 2), img)
    return canvas


def ensure_dir(p):
    os.makedirs(p, exist_ok=True)


def make_legacy_launcher(logo):
    """Square icon with logo centered on solid white, ~10% padding for strong presence."""
    for folder, size in LEGACY_SIZES.items():
        canvas = Image.new('RGBA', (size, size), BG_COLOR)
        safe = int(size * 0.80)  # 10% padding each side — strong icon presence
        fitted = fit_contain(logo, safe, safe)
        paste_centered(canvas, fitted)
        out_dir = os.path.join(ANDROID_RES, folder)
        ensure_dir(out_dir)
        canvas.save(os.path.join(out_dir, 'ic_launcher.png'), 'PNG', optimize=True)
        print('wrote', os.path.join(folder, 'ic_launcher.png'))


def make_adaptive_foreground(logo):
    """Transparent foreground with logo inside the safe zone of the 108dp canvas."""
    for folder, size in ADAPTIVE_FG_SIZES.items():
        canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        # Safe zone is 66dp of 108dp. Use ~65% for strong presence.
        safe = int(size * 0.65)
        fitted = fit_contain(logo, safe, safe)
        paste_centered(canvas, fitted)
        out_dir = os.path.join(ANDROID_RES, folder)
        ensure_dir(out_dir)
        canvas.save(os.path.join(out_dir, 'ic_launcher_foreground.png'), 'PNG', optimize=True)
        print('wrote', os.path.join(folder, 'ic_launcher_foreground.png'))


def make_splash_icon(logo):
    """Splash drawable: icon centered, transparent bg."""
    for folder, size in SPLASH_SIZES.items():
        canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        fitted = fit_contain(logo, size, size)
        paste_centered(canvas, fitted)
        out_dir = os.path.join(ANDROID_RES, folder)
        ensure_dir(out_dir)
        canvas.save(os.path.join(out_dir, 'splash_logo.png'), 'PNG', optimize=True)
        print('wrote', os.path.join(folder, 'splash_logo.png'))


def make_flutter_branding(logo):
    """Optimized, reasonably sized copy for in-app use (keeps natural aspect)."""
    ensure_dir(FLUTTER_BRANDING)
    for scale, subdir in ((1.0, ''), (2.0, '2.0x'), (3.0, '3.0x')):
        target_w = int(900 * scale)
        iw, ih = logo.size
        target_h = int(ih * (target_w / iw))
        resized = logo.resize((target_w, target_h), Image.LANCZOS)
        out_dir = os.path.join(FLUTTER_BRANDING, subdir) if subdir else FLUTTER_BRANDING
        ensure_dir(out_dir)
        out = os.path.join(out_dir, 'futuregate_logo.png')
        resized.save(out, 'PNG', optimize=True)
        print('wrote', os.path.relpath(out, ROOT))


def make_web_icons(logo):
    """Generate web PWA icons and favicon from the icon source."""
    icons_dir = os.path.join(WEB_DIR, 'icons')
    ensure_dir(icons_dir)

    for name, size in WEB_ICON_SIZES.items():
        is_maskable = 'maskable' in name
        canvas = Image.new('RGBA', (size, size), BG_COLOR)
        # Maskable icons need more padding (safe area is inner 80%)
        safe = int(size * 0.70) if is_maskable else int(size * 0.85)
        fitted = fit_contain(logo, safe, safe)
        paste_centered(canvas, fitted)
        out = os.path.join(icons_dir, f'{name}.png')
        canvas.save(out, 'PNG', optimize=True)
        print('wrote', os.path.relpath(out, ROOT))

    # Favicon
    canvas = Image.new('RGBA', (FAVICON_SIZE, FAVICON_SIZE), BG_COLOR)
    safe = int(FAVICON_SIZE * 0.85)
    fitted = fit_contain(logo, safe, safe)
    paste_centered(canvas, fitted)
    out = os.path.join(WEB_DIR, 'favicon.png')
    canvas.save(out, 'PNG', optimize=True)
    print('wrote', os.path.relpath(out, ROOT))


def main():
    icon_logo = load_trimmed(ICON_SRC)
    name_logo = load_trimmed(NAME_SRC)
    print('icon source:', icon_logo.size)
    print('name source:', name_logo.size)

    make_legacy_launcher(icon_logo)
    make_adaptive_foreground(icon_logo)
    make_splash_icon(icon_logo)
    make_web_icons(icon_logo)
    make_flutter_branding(name_logo)
    print('done.')


if __name__ == '__main__':
    main()
