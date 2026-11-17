#!/usr/bin/env python3
"""Draw the Earth point-of-origin wallpaper as clean vector art.

Same composition as the stone original (glyph between double pillars, crossed
panels, frieze at the bottom), redrawn flat with the Ancient Shell palette.

    ./make-earth-origin.py [width height] > earth_origin.svg
    rsvg-convert earth_origin.svg -o earth_origin.png
"""
import math
import sys

W, H = (int(sys.argv[1]), int(sys.argv[2])) if len(sys.argv) == 3 else (3840, 2160)
S = H / 2160            # drawing is laid out for 2160 px of height
CX = W / 2

# Palette (quickshell/ancient/theme/Theme.qml)
VOID, STONE0, STONE1 = "#07090a", "#0b0f11", "#11171a"
LINE, LINE_BRIGHT = "#26343a", "#3a4d55"
CYAN, CYAN_BRIGHT, CYAN_MID, CYAN_DEEP = "#30c6de", "#8ceaf7", "#2093ae", "#133849"
AMBER, AMBER_BRIGHT = "#e8a33d", "#ffd08a"

out = []
add = out.append


def f(v):
    return f"{v:.1f}"


def line(x1, y1, x2, y2, color=LINE, width=2, opacity=1.0):
    add(f'<line x1="{f(x1)}" y1="{f(y1)}" x2="{f(x2)}" y2="{f(y2)}" stroke="{color}" '
        f'stroke-width="{f(width * S)}" stroke-opacity="{opacity}" stroke-linecap="square"/>')


def poly(points, **attrs):
    a = " ".join(f'{k.replace("_", "-")}="{v}"' for k, v in attrs.items())
    add(f'<polygon points="{" ".join(f"{f(x)},{f(y)}" for x, y in points)}" {a}/>')


# ── Layout ─────────────────────────────────────────────────
top = 112 * S                     # top rail
frieze = 1716 * S                 # frieze top
half = 820 * S                    # half width of the centre panel
pl, pr = CX - half, CX + half     # centre panel edges
bar, gap = 30 * S, 22 * S         # pillar bars

# Point of origin, outlined in the coordinates of the stone original and scaled
k = 2.02 * S
gy = 392 * S


def g(x, y):
    return CX + (x - 785) * k, gy + (y - 250) * k


glyph = [g(*p) for p in [
    (785, 425), (565, 775), (705, 775), (685, 740), (640, 740), (785, 500),
    (930, 740), (885, 740), (865, 775), (1005, 775)]]
disc_c, disc_r = g(785, 318), 68 * k
glyph_cy = (disc_c[1] - disc_r + glyph[1][1]) / 2

add(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">')
add(f'''<defs>
  <linearGradient id="base" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#0b1013"/>
    <stop offset="0.62" stop-color="#090d0f"/>
    <stop offset="1" stop-color="{VOID}"/>
  </linearGradient>
  <radialGradient id="haze" cx="{f(CX)}" cy="{f(glyph_cy)}" r="{f(1050 * S)}" gradientUnits="userSpaceOnUse">
    <stop offset="0" stop-color="{CYAN_MID}" stop-opacity="0.30"/>
    <stop offset="0.45" stop-color="{CYAN_DEEP}" stop-opacity="0.32"/>
    <stop offset="1" stop-color="{CYAN_DEEP}" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="vignette" cx="{f(CX)}" cy="{f(H * 0.45)}" r="{f(W * 0.62)}" gradientUnits="userSpaceOnUse">
    <stop offset="0.55" stop-color="#000" stop-opacity="0"/>
    <stop offset="1" stop-color="#000" stop-opacity="0.55"/>
  </radialGradient>
  <linearGradient id="glyphFill" x1="0" y1="{f(disc_c[1] - disc_r)}" x2="0" y2="{f(glyph[1][1])}" gradientUnits="userSpaceOnUse">
    <stop offset="0" stop-color="#123642"/>
    <stop offset="1" stop-color="#0c1f27"/>
  </linearGradient>
  <linearGradient id="pillar" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="{STONE1}"/>
    <stop offset="1" stop-color="{STONE0}"/>
  </linearGradient>
  <linearGradient id="beam" x1="0" y1="{f(top)}" x2="0" y2="{f(frieze)}" gradientUnits="userSpaceOnUse">
    <stop offset="0" stop-color="{CYAN}" stop-opacity="0"/>
    <stop offset="0.5" stop-color="{CYAN}" stop-opacity="0.9"/>
    <stop offset="1" stop-color="{CYAN}" stop-opacity="0"/>
  </linearGradient>
  <linearGradient id="rail" x1="0" y1="0" x2="{W}" y2="0" gradientUnits="userSpaceOnUse">
    <stop offset="0" stop-color="{CYAN}" stop-opacity="0"/>
    <stop offset="0.5" stop-color="{CYAN}" stop-opacity="0.75"/>
    <stop offset="1" stop-color="{CYAN}" stop-opacity="0"/>
  </linearGradient>
  <filter id="glowWide" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="{f(46 * S)}"/></filter>
  <filter id="glow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="{f(12 * S)}"/></filter>
  <filter id="glowSoft" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="{f(5 * S)}"/></filter>
</defs>''')

# ── Backdrop ───────────────────────────────────────────────
add(f'<rect width="{W}" height="{H}" fill="url(#base)"/>')
add(f'<rect width="{W}" height="{H}" fill="url(#haze)"/>')

# Crossed panels
line(pl, top, pr, frieze, opacity=0.9)
line(pr, top, pl, frieze, opacity=0.9)
for x0, x1 in [(0, pl - 2 * bar - 3 * gap), (pr + 2 * bar + 3 * gap, W)]:
    xm, ym = (x0 + x1) / 2, (top + frieze) / 2
    line(x0, top, x1, frieze, opacity=0.5)
    line(x1, top, x0, frieze, opacity=0.5)
    poly([(xm, top), (x1, ym), (xm, frieze), (x0, ym)], fill="none", stroke=LINE,
         stroke_width=f(2 * S), stroke_opacity="0.35")

# Chamfered inner frame of the centre panel
inset, cut = 34 * S, 54 * S
a, b, c, d = pl + inset, top + inset, pr - inset, frieze - inset
poly([(a + cut, b), (c - cut, b), (c, b + cut), (c, d - cut), (c - cut, d), (a + cut, d), (a, d - cut), (a, b + cut)],
     fill="none", stroke=LINE_BRIGHT, stroke_width=f(2 * S), stroke_opacity="0.55")
# Corner accents on the frame
for (x, y, dx, dy) in [(a, b, 1, 1), (c, b, -1, 1), (a, d, 1, -1), (c, d, -1, -1)]:
    add(f'<polyline points="{f(x)},{f(y + dy * (cut + 70 * S))} {f(x)},{f(y + dy * cut)} '
        f'{f(x + dx * cut)},{f(y)} {f(x + dx * (cut + 70 * S))},{f(y)}" fill="none" stroke="{CYAN}" '
        f'stroke-width="{f(3 * S)}" stroke-opacity="0.55"/>')

# Faint glyphs on the side panels
side_glyphs = [
    "M -22 22 L 0 -22 L 22 22 Z",                                 # triangle
    "M -20 -24 L 20 -24 L -20 24 L 20 24 Z",                       # hourglass
    "M 18 -24 L -18 -24 L 6 0 L -18 24 L 18 24",                   # sigma
    "M -22 -22 L -22 22 L 22 22",                                  # corner
    "M 0 -24 L 0 24 M -18 -6 L 18 -6",                             # cross
    "M -22 20 L 0 -20 L 22 20 M -10 4 L 10 4",                     # A
]
for i, (fx, fy) in enumerate([(0.07, 0.22), (0.135, 0.47), (0.065, 0.66),
                              (0.93, 0.27), (0.86, 0.5), (0.935, 0.71)]):
    add(f'<path d="{side_glyphs[i]}" transform="translate({f(W * fx)},{f(H * fy)}) scale({f(1.3 * S)})" '
        f'fill="none" stroke="{CYAN}" stroke-opacity="0.22" stroke-width="2"/>')

# ── Pillars: two bars each side, a light beam on the inner one ─
for side in (-1, 1):
    edge = pl if side < 0 else pr
    xs = [edge - gap - bar, edge - 2 * gap - 2 * bar] if side < 0 else [edge + gap, edge + 2 * gap + bar]
    for x in xs:
        add(f'<rect x="{f(x)}" y="{f(top)}" width="{f(bar)}" height="{f(frieze - top)}" fill="url(#pillar)" '
            f'stroke="{LINE}" stroke-width="{f(2 * S)}"/>')
    inner = xs[0] + (bar - 4 * S if side < 0 else 4 * S)
    add(f'<line x1="{f(inner)}" y1="{f(top)}" x2="{f(inner)}" y2="{f(frieze)}" stroke="url(#beam)" '
        f'stroke-width="{f(14 * S)}" filter="url(#glow)"/>')
    add(f'<line x1="{f(inner)}" y1="{f(top)}" x2="{f(inner)}" y2="{f(frieze)}" stroke="url(#beam)" '
        f'stroke-width="{f(2.5 * S)}"/>')
    # Amber caps where the pillars meet the rails
    for y in (top, frieze):
        x0 = min(xs) - 6 * S
        add(f'<rect x="{f(x0)}" y="{f(y - 3 * S)}" width="{f(2 * bar + gap + 12 * S)}" height="{f(6 * S)}" '
            f'fill="{AMBER}" opacity="0.85"/>')

# ── Rails ──────────────────────────────────────────────────
add(f'<rect y="0" width="{W}" height="{f(top)}" fill="{STONE0}"/>')
line(0, top, W, top, LINE_BRIGHT, 2)
line(0, top - 12 * S, W, top - 12 * S, LINE, 2)
add(f'<line x1="0" y1="{f(top)}" x2="{W}" y2="{f(top)}" stroke="url(#rail)" stroke-width="{f(2 * S)}"/>')
# Amber accent centred on the top rail (the ChamferPanel accent edge)
add(f'<rect x="{f(CX - 150 * S)}" y="{f(top - 3 * S)}" width="{f(300 * S)}" height="{f(6 * S)}" fill="{AMBER}"/>')
add(f'<rect x="{f(CX - 150 * S)}" y="{f(top - 3 * S)}" width="{f(300 * S)}" height="{f(6 * S)}" fill="{AMBER}" '
    f'filter="url(#glowSoft)" opacity="0.8"/>')

# ── Frieze ─────────────────────────────────────────────────
add(f'<rect y="{f(frieze)}" width="{W}" height="{f(H - frieze)}" fill="{STONE0}"/>')
line(0, frieze, W, frieze, LINE_BRIGHT, 2)
line(0, frieze + 12 * S, W, frieze + 12 * S, LINE, 2)
add(f'<line x1="0" y1="{f(frieze)}" x2="{W}" y2="{f(frieze)}" stroke="url(#rail)" stroke-width="{f(2 * S)}"/>')

cell = 240 * S
n = math.ceil(W / cell) + 1
x_start = CX - cell / 2 - math.ceil((CX - cell / 2) / cell) * cell
bowl_top, bowl_r = frieze + 48 * S, 96 * S
for i in range(n):
    x0 = x_start + i * cell + 22 * S
    x1 = x0 + cell - 44 * S
    centre = abs((x0 + x1) / 2 - CX) < 1
    r = (x1 - x0) / 2
    path = f"M {f(x0)} {f(bowl_top)} L {f(x1)} {f(bowl_top)} A {f(r)} {f(bowl_r)} 0 0 1 {f(x0)} {f(bowl_top)} Z"
    if centre:
        add(f'<path d="{path}" fill="{CYAN}" fill-opacity="0.06" stroke="{CYAN}" stroke-width="{f(8 * S)}" '
            f'filter="url(#glow)" opacity="0.7"/>')
        add(f'<path d="{path}" fill="none" stroke="{CYAN_BRIGHT}" stroke-width="{f(2.5 * S)}"/>')
    else:
        add(f'<path d="{path}" fill="{STONE1}" fill-opacity="0.6" stroke="{LINE_BRIGHT}" '
            f'stroke-width="{f(2 * S)}" stroke-opacity="0.8"/>')
    add(f'<circle cx="{f((x0 + x1) / 2)}" cy="{f(bowl_top + bowl_r * 0.45)}" r="{f(4 * S)}" '
        f'fill="{AMBER if centre else CYAN}" fill-opacity="{0.9 if centre else 0.25}"/>')

slots_top = frieze + 196 * S
line(0, slots_top - 26 * S, W, slots_top - 26 * S, LINE, 2)
slot_w, slot_gap = 64 * S, 40 * S
pitch = slot_w + slot_gap
m = math.ceil(W / pitch) + 1
sx0 = CX - slot_w / 2 - math.ceil((CX - slot_w / 2) / pitch) * pitch
for i in range(m):
    x = sx0 + i * pitch
    rr = slot_w / 2
    add(f'<path d="M {f(x)} {f(H + 10)} L {f(x)} {f(slots_top + rr)} A {f(rr)} {f(rr)} 0 0 1 {f(x + slot_w)} '
        f'{f(slots_top + rr)} L {f(x + slot_w)} {f(H + 10)}" fill="{STONE1}" fill-opacity="0.35" '
        f'stroke="{LINE}" stroke-opacity="0.6" stroke-width="{f(2 * S)}"/>')

# ── Point of origin ────────────────────────────────────────
glyph_pts = " ".join(f"{f(x)},{f(y)}" for x, y in glyph)


def glyph_shapes(attrs):
    add(f'<circle cx="{f(disc_c[0])}" cy="{f(disc_c[1])}" r="{f(disc_r)}" {attrs}/>')
    add(f'<polygon points="{glyph_pts}" stroke-linejoin="miter" {attrs}/>')


# Wide halo, then the glowing edge, the fill and a crisp double edge
add('<g filter="url(#glowWide)" opacity="0.75">')
glyph_shapes(f'fill="{CYAN}" fill-opacity="0.35" stroke="{CYAN}" stroke-width="{f(26 * S)}"')
add('</g>')
add('<g filter="url(#glow)" opacity="0.9">')
glyph_shapes(f'fill="none" stroke="{CYAN}" stroke-width="{f(12 * S)}"')
add('</g>')
glyph_shapes(f'fill="url(#glyphFill)" stroke="{CYAN}" stroke-width="{f(5 * S)}"')
glyph_shapes(f'fill="none" stroke="{CYAN_BRIGHT}" stroke-width="{f(1.8 * S)}"')

# Thin inner outline, inset from the edge, for a machined look
add(f'<g transform="translate({f(disc_c[0])},{f(disc_c[1])}) scale(0.82) translate({f(-disc_c[0])},{f(-disc_c[1])})">'
    f'<circle cx="{f(disc_c[0])}" cy="{f(disc_c[1])}" r="{f(disc_r)}" fill="none" stroke="{CYAN}" '
    f'stroke-opacity="0.35" stroke-width="{f(2 * S / 0.82)}"/></g>')

add(f'<rect width="{W}" height="{H}" fill="url(#vignette)"/>')
add('</svg>')
print("\n".join(out))
