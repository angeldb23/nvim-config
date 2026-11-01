#!/usr/bin/env python3
"""Genera lua/sixel_font.lua con varios tamaños de letra (CaskaydiaCove Nerd Font) para el minimap sixel."""
import os, subprocess, sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    sys.exit("Falta Pillow: sudo pacman -S --needed python-pillow")

OUT = os.environ.get("SXM_OUT", os.path.expanduser("~/.config/nvim/lua/sixel_font.lua"))
PRESETS = {
    "chico":  dict(cw=1, lh=2,  fs=0.80, gain=2.6, cols=16),
    "vscode": dict(cw=2, lh=4,  fs=0.85, gain=2.2, cols=22),
    "medio":  dict(cw=3, lh=6,  fs=0.90, gain=1.7, cols=26),
    "grande": dict(cw=5, lh=12, fs=1.00, gain=1.3, cols=30),
}
SS = 8  # supermuestreo: dibuja 8x más grande y achica promediando

def sh(*a):
    try: return subprocess.run(a, capture_output=True, text=True).stdout.strip()
    except Exception: return ""

def find_font():
    forced = os.environ.get("SXM_FONT")
    if forced: return forced, "forzada"
    for q in ("CaskaydiaCove Nerd Font Mono:style=Regular", "CaskaydiaCove Nerd Font:style=Regular",
               "CaskaydiaCove NF:style=Regular", "Cascadia Code NF:style=Regular"):
        out = sh("fc-match", "-f", "%{file}|%{family}", q)
        if "|" in out:
            f, fam = out.split("|", 1)
            if ("askaydia" in fam.lower() or "ascadia" in fam.lower()) and os.path.exists(f):
                return f, fam
    cands = []
    for line in sh("fc-list", ":", "file", "family", "style").splitlines():
        low = line.lower()
        if ("caskaydia" in low or "cascadia" in low) and "italic" not in low and "bold" not in low:
            cands.append(line.split(":")[0].strip())
    cands = [c for c in cands if os.path.exists(c)]
    if cands:
        cands.sort(key=lambda p: ("regular" not in p.lower(), len(p)))
        return cands[0], "CaskaydiaCove"
    f = sh("fc-match", "-f", "%{file}", "monospace")
    print("OJO: no encontré CaskaydiaCove Nerd Font, uso", f)
    return f, "monospace"

path, fam = find_font()
ratio = ImageFont.truetype(path, 100).getlength("M") / 100.0

def build(p):
    cw, lh = p["cw"], p["lh"]
    size = cw * SS / ratio * p["fs"]
    try: font = ImageFont.truetype(path, size)
    except Exception: font = ImageFont.truetype(path, max(5, int(round(size))))
    asc, desc = font.getmetrics()
    base = max(0, (lh * SS - (asc + desc)) // 2) + asc
    glyphs = {}
    for code in range(33, 127):
        big = Image.new("L", (cw * SS, lh * SS), 0)
        ImageDraw.Draw(big).text((0, base), chr(code), font=font, fill=255, anchor="ls")
        small = big.resize((cw, lh), Image.BOX)
        flat = []
        for y in range(lh):
            for x in range(cw):
                cov = min(1.0, small.getpixel((x, y)) / 255.0 * p["gain"])
                lvl = 0 if cov < 0.10 else 1 if cov < 0.38 else 2 if cov < 0.68 else 3
                if lvl: flat += [x, y, lvl]
        glyphs[code] = flat
    return glyphs

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w") as fh:
    fh.write(f"-- generado por gen-sixel-font.py (fuente: {os.path.basename(path)})\nreturn {{ presets = {{\n")
    for name, p in PRESETS.items():
        fh.write(f"    {name} = {{ cw = {p['cw']}, lh = {p['lh']}, cols = {p['cols']}, g = {{\n")
        for code, flat in build(p).items():
            fh.write(f"        [{code}]={{{','.join(map(str, flat))}}},\n")
        fh.write("    } },\n")
    fh.write("} }\n")
print(f"fuente: {os.path.basename(path)} ({fam}) | tamaños: {', '.join(PRESETS)} -> {OUT}")
