#!/usr/bin/env python3
"""Draw the Pegasus star chart wallpaper as vector art.

An Ancient holographic star map: the Pegasus galaxy, tilted, inside the rings
of the projector, with gate addresses marked on its arms and the route to the
chosen one in amber. The address being dialed runs along the frieze. Same
rails, frieze and palette as earth_origin.

    ./make-pegasus-chart.py [width height] > pegasus_chart.svg
    rsvg-convert pegasus_chart.svg -o pegasus_chart.png
"""
import math
import random
import sys

W, H = (int(sys.argv[1]), int(sys.argv[2])) if len(sys.argv) == 3 else (3840, 2160)
S = H / 2160            # drawing is laid out for 2160 px of height
CX = W / 2

# Palette (quickshell/ancient/theme/Theme.qml)
VOID, STONE0, STONE1 = "#07090a", "#0b0f11", "#11171a"
LINE, LINE_BRIGHT = "#26343a", "#3a4d55"
CYAN, CYAN_BRIGHT, CYAN_MID, CYAN_DEEP = "#30c6de", "#8ceaf7", "#2093ae", "#133849"
AMBER, AMBER_BRIGHT = "#e8a33d", "#ffd08a"
TEXT = "#d5e3e7"

rng = random.Random(1983)
out = []
add = out.append


def f(v):
    return f"{v:.1f}"


def line(x1, y1, x2, y2, color=LINE, width=2, opacity=1.0, extra=""):
    add(f'<line x1="{f(x1)}" y1="{f(y1)}" x2="{f(x2)}" y2="{f(y2)}" stroke="{color}" '
        f'stroke-width="{f(width * S)}" stroke-opacity="{opacity}" stroke-linecap="square" {extra}/>')


# ── Layout ─────────────────────────────────────────────────
top = 112 * S                     # top rail
frieze = 1716 * S                 # frieze top
CY = (top + frieze) / 2 + 10 * S  # centre of the chart
RG = 740 * S                      # galaxy radius
TILT = 0.5                        # how flat the galaxy plane looks
ROT = math.radians(-13)           # the plane's turn on screen


def plane(x, y):
    """A point on the galaxy plane, on screen."""
    y *= TILT
    c, s = math.cos(ROT), math.sin(ROT)
    return CX + x * c - y * s, CY + x * s + y * c


def polar(r, a):
    return plane(r * math.cos(a), r * math.sin(a))


# Glyphs, drawn as strokes in a 48 px box around the origin
GLYPHS = [
    "M -20 20 L 0 -20 L 20 20",
    "M -20 -18 L 20 -18 L 0 20 Z",
    "M -20 0 L 20 0 M 0 -20 L 0 20 M -14 -14 L -6 -14",
    "M -20 20 L -20 -20 L 20 -20",
    "M -20 -20 L 20 20 M 20 -20 L 4 -4",
    "M -18 -18 L 18 -18 L 18 18 M -18 0 L 6 0",
    "M 0 -22 L 0 22 M 0 -22 L -16 -6 M 0 -22 L 16 -6",
    "M -20 10 L -8 -20 L 8 10 L 20 -20",
    "M -20 -20 L -20 20 L 20 20 M -8 -8 L 8 -8",
    "M -22 4 A 22 22 0 0 1 22 4 M 0 4 L 0 22",
    "M -18 22 L -18 -6 L 18 -22 L 18 6",
    "M -20 -12 L 20 -12 M -20 12 L 20 12 M 0 -12 L 0 12",
    "M -20 20 L 20 -20 M -20 -20 L -4 -4 M 8 8 L 20 20",
    "M -16 -22 L 16 -22 L -16 22 L 16 22",
]
# The point of origin of the earth_origin wallpaper
ORIGIN = "M 0 -9 A 7 7 0 1 1 0.01 -9 M 0 -2 L -18 22 L -9 22 M 0 -2 L 18 22 L 9 22"


def glyph(path, x, y, scale, color, opacity, width=2.2):
    add(f'<path d="{path}" transform="translate({f(x)},{f(y)}) scale({f(scale)})" fill="none" '
        f'stroke="{color}" stroke-opacity="{opacity}" stroke-width="{f(width * S / scale)}" '
        f'stroke-linejoin="miter" stroke-linecap="square"/>')


add(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">')
add(f'''<defs>
  <linearGradient id="base" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#0b1013"/>
    <stop offset="0.62" stop-color="#090d0f"/>
    <stop offset="1" stop-color="{VOID}"/>
  </linearGradient>
  <radialGradient id="haze" cx="{f(CX)}" cy="{f(CY)}" r="{f(1250 * S)}" gradientUnits="userSpaceOnUse">
    <stop offset="0" stop-color="{CYAN_MID}" stop-opacity="0.22"/>
    <stop offset="0.4" stop-color="{CYAN_DEEP}" stop-opacity="0.28"/>
    <stop offset="1" stop-color="{CYAN_DEEP}" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="core" cx="0.5" cy="0.5" r="0.5">
    <stop offset="0" stop-color="{AMBER_BRIGHT}" stop-opacity="0.75"/>
    <stop offset="0.18" stop-color="{CYAN_BRIGHT}" stop-opacity="0.45"/>
    <stop offset="0.55" stop-color="{CYAN}" stop-opacity="0.12"/>
    <stop offset="1" stop-color="{CYAN}" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="vignette" cx="{f(CX)}" cy="{f(H * 0.45)}" r="{f(W * 0.62)}" gradientUnits="userSpaceOnUse">
    <stop offset="0.55" stop-color="#000" stop-opacity="0"/>
    <stop offset="1" stop-color="#000" stop-opacity="0.55"/>
  </radialGradient>
  <linearGradient id="rail" x1="0" y1="0" x2="{W}" y2="0" gradientUnits="userSpaceOnUse">
    <stop offset="0" stop-color="{CYAN}" stop-opacity="0"/>
    <stop offset="0.5" stop-color="{CYAN}" stop-opacity="0.75"/>
    <stop offset="1" stop-color="{CYAN}" stop-opacity="0"/>
  </linearGradient>
  <linearGradient id="beam" x1="0" y1="{f(top)}" x2="0" y2="{f(frieze)}" gradientUnits="userSpaceOnUse">
    <stop offset="0" stop-color="{CYAN}" stop-opacity="0"/>
    <stop offset="0.5" stop-color="{CYAN}" stop-opacity="0.5"/>
    <stop offset="1" stop-color="{CYAN}" stop-opacity="0"/>
  </linearGradient>
  <filter id="glowWide" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="{f(40 * S)}"/></filter>
  <filter id="glow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="{f(10 * S)}"/></filter>
  <filter id="glowSoft" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="{f(4 * S)}"/></filter>
</defs>''')

# ── Backdrop ───────────────────────────────────────────────
add(f'<rect width="{W}" height="{H}" fill="url(#base)"/>')
add(f'<rect width="{W}" height="{H}" fill="url(#haze)"/>')

# Faint background stars, outside the galaxy
for _ in range(int(420 * W / 3840)):
    x, y = rng.uniform(0, W), rng.uniform(top, frieze)
    add(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(rng.uniform(0.8, 2.0) * S)}" fill="{TEXT}" '
        f'fill-opacity="{rng.uniform(0.06, 0.22):.2f}"/>')

# ── Projector frame: chamfered panel and side readouts ─────
inset_x, inset_y, cut = 300 * S, 40 * S, 70 * S
a, b, c, d = inset_x, top + inset_y, W - inset_x, frieze - inset_y
add(f'<polygon points="{f(a + cut)},{f(b)} {f(c - cut)},{f(b)} {f(c)},{f(b + cut)} {f(c)},{f(d - cut)} '
    f'{f(c - cut)},{f(d)} {f(a + cut)},{f(d)} {f(a)},{f(d - cut)} {f(a)},{f(b + cut)}" fill="none" '
    f'stroke="{LINE_BRIGHT}" stroke-width="{f(2 * S)}" stroke-opacity="0.5"/>')
for (x, y, dx, dy) in [(a, b, 1, 1), (c, b, -1, 1), (a, d, 1, -1), (c, d, -1, -1)]:
    add(f'<polyline points="{f(x)},{f(y + dy * (cut + 90 * S))} {f(x)},{f(y + dy * cut)} '
        f'{f(x + dx * cut)},{f(y)} {f(x + dx * (cut + 90 * S))},{f(y)}" fill="none" stroke="{CYAN}" '
        f'stroke-width="{f(3 * S)}" stroke-opacity="0.55"/>')

# Light along the frame's sides
for x in (a, c):
    add(f'<line x1="{f(x)}" y1="{f(b + cut)}" x2="{f(x)}" y2="{f(d - cut)}" stroke="url(#beam)" '
        f'stroke-width="{f(10 * S)}" filter="url(#glow)"/>')

# Readouts in the margins: columns of glyphs and scale bars
for side in (-1, 1):
    x0 = (a / 2) if side < 0 else (W - a / 2)
    for i in range(9):
        y = b + 120 * S + i * 150 * S
        if y > d - 80 * S:
            break
        glyph(GLYPHS[(i * 5 + (side > 0) * 3) % len(GLYPHS)], x0, y, 0.85 * S, CYAN, 0.28)
        for j in range(3):
            ln = rng.uniform(30, 110) * S
            yy = y + (34 + j * 12) * S
            line(x0 - 55 * S, yy, x0 - 55 * S + ln, yy, CYAN if j == 0 else LINE_BRIGHT, 2,
                 0.35 if j == 0 else 0.5)

# ── The galaxy ─────────────────────────────────────────────
# Projector rings on the galaxy plane, with a degree scale on the outer one
ring_tf = f'translate({f(CX)},{f(CY)}) rotate({math.degrees(ROT):.2f}) scale(1,{TILT})'
add(f'<g transform="{ring_tf}" fill="none">')
for r, op, w in [(RG * 1.08, 0.45, 1.6), (RG * 1.2, 0.7, 2.2), (RG * 1.26, 0.35, 1.4), (RG * 0.55, 0.18, 1.2)]:
    add(f'<circle r="{f(r)}" stroke="{CYAN}" stroke-opacity="{op}" stroke-width="{f(w * S)}" '
        f'vector-effect="non-scaling-stroke"/>')
for i in range(120):
    ang = i / 120 * math.tau
    long = i % 10 == 0
    r0, r1 = RG * 1.2, RG * (1.26 if long else 1.225)
    add(f'<line x1="{f(r0 * math.cos(ang))}" y1="{f(r0 * math.sin(ang))}" x2="{f(r1 * math.cos(ang))}" '
        f'y2="{f(r1 * math.sin(ang))}" stroke="{CYAN_BRIGHT if long else CYAN}" '
        f'stroke-opacity="{0.7 if long else 0.35}" stroke-width="{f((2 if long else 1.2) * S)}" '
        f'vector-effect="non-scaling-stroke"/>')
# The plane's axes, dashed
for ang in (0, math.pi / 2):
    add(f'<line x1="{f(-RG * 1.3 * math.cos(ang))}" y1="{f(-RG * 1.3 * math.sin(ang))}" '
        f'x2="{f(RG * 1.3 * math.cos(ang))}" y2="{f(RG * 1.3 * math.sin(ang))}" stroke="{CYAN}" '
        f'stroke-opacity="0.16" stroke-width="{f(1.4 * S)}" stroke-dasharray="{f(14 * S)} {f(18 * S)}" '
        f'vector-effect="non-scaling-stroke"/>')
add('</g>')

# The projector's beam, from the console below up to the chart
bx, by = CX, frieze - 6 * S
add(f'<polygon points="{f(bx - 40 * S)},{f(by)} {f(bx + 40 * S)},{f(by)} {f(CX + RG * 0.9)},{f(CY + 30 * S)} '
    f'{f(CX - RG * 0.9)},{f(CY + 30 * S)}" fill="{CYAN}" fill-opacity="0.025"/>')

# Stars: two arms, a disc and a bulge
stars = []
ARMS, WIND = 2, 4.6
for _ in range(3400):
    arm = rng.randrange(ARMS)
    t = rng.random() ** 0.8 * 0.92 + 0.08
    spread = 0.018 + 0.045 * t
    ang = arm * math.tau / ARMS + WIND * t + rng.gauss(0, spread * 2.2)
    r = RG * t + rng.gauss(0, RG * spread * 0.6)
    stars.append((r, ang, "arm"))
for _ in range(650):
    r = RG * min(1.05, rng.expovariate(3.5))
    stars.append((r, rng.uniform(0, math.tau), "disc"))
for _ in range(700):
    r = abs(rng.gauss(0, RG * 0.09))
    stars.append((r, rng.uniform(0, math.tau), "core"))

# Galaxy glow first: the bright core and the arms blurred
add(f'<ellipse cx="0" cy="0" rx="{f(RG * 0.42)}" ry="{f(RG * 0.42 * TILT)}" fill="url(#core)" '
    f'transform="translate({f(CX)},{f(CY)}) rotate({math.degrees(ROT):.2f})"/>')
add('<g filter="url(#glow)" opacity="0.8">')
for r, ang, kind in stars[:1400]:
    x, y = polar(r, ang)
    add(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(5 * S)}" fill="{CYAN}" fill-opacity="0.16"/>')
add('</g>')

for r, ang, kind in stars:
    x, y = polar(r, ang)
    near = 1 - min(1.0, r / RG)
    size = (rng.random() ** 3 * 2.6 + 0.7) * S
    op = min(1.0, rng.uniform(0.3, 0.9) + 0.3 * near)
    roll = rng.random()
    if kind == "core" and roll < 0.35:
        col = AMBER_BRIGHT
    elif roll < 0.5:
        col = CYAN_BRIGHT
    elif roll < 0.9:
        col = CYAN
    else:
        col = TEXT
    add(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(size)}" fill="{col}" fill-opacity="{op:.2f}"/>')

# ── Gate addresses on the arms ─────────────────────────────
# (radius, angle) on the plane, label side, and whether it is the destination
systems = [
    (0.78, 0.6, 1, False), (0.46, 2.3, -1, False), (0.9, 3.6, -1, False),
    (0.62, 4.9, 1, False), (0.34, 5.8, 1, False), (0.86, 1.75, 1, True),
]
home = polar(RG * 0.7, 4.15)
# Each system's address: six symbols and the point of origin
addresses = [rng.sample(range(len(GLYPHS)), 6) for _ in systems]

# Route from home to the destination, a dashed arc through the plane
dest = next(s for s in systems if s[3])
steps = 48
pts = []
for i in range(steps + 1):
    u = i / steps
    r = RG * (0.7 + (dest[0] - 0.7) * u) * (1 - 0.35 * math.sin(u * math.pi))
    ang = 4.15 + ((dest[1] + math.tau) - 4.15) * u
    pts.append(polar(r, ang))
route = " ".join(f"{f(x)},{f(y)}" for x, y in pts)
add(f'<polyline points="{route}" fill="none" stroke="{AMBER}" stroke-opacity="0.35" stroke-width="{f(8 * S)}" '
    f'filter="url(#glowSoft)"/>')
add(f'<polyline points="{route}" fill="none" stroke="{AMBER}" stroke-opacity="0.85" stroke-width="{f(2.2 * S)}" '
    f'stroke-dasharray="{f(16 * S)} {f(12 * S)}"/>')

# Home: the origin glyph in a ring
hx, hy = home
add(f'<circle cx="{f(hx)}" cy="{f(hy)}" r="{f(22 * S)}" fill="{CYAN}" fill-opacity="0.3" filter="url(#glow)"/>')
add(f'<circle cx="{f(hx)}" cy="{f(hy)}" r="{f(22 * S)}" fill="{STONE0}" fill-opacity="0.7" stroke="{CYAN_BRIGHT}" '
    f'stroke-width="{f(2 * S)}"/>')
glyph(ORIGIN, hx, hy + 1 * S, 0.62 * S, CYAN_BRIGHT, 0.95, 1.8)

for i, (rr, ang, side, chosen) in enumerate(systems):
    x, y = polar(RG * rr, ang)
    col = AMBER if chosen else CYAN
    # Marker: a dot in a ring, the destination with a second ring
    add(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(5 * S)}" fill="{AMBER_BRIGHT if chosen else CYAN_BRIGHT}"/>')
    add(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(14 * S)}" fill="none" stroke="{col}" stroke-width="{f(2 * S)}" '
        f'stroke-opacity="0.9"/>')
    if chosen:
        add(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(30 * S)}" fill="{AMBER}" fill-opacity="0.18" filter="url(#glow)"/>')
        add(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(26 * S)}" fill="none" stroke="{AMBER}" stroke-width="{f(1.5 * S)}" '
            f'stroke-opacity="0.6" stroke-dasharray="{f(6 * S)} {f(6 * S)}"/>')
    # Leader to a plate of seven glyphs
    lx, ly = x + side * 70 * S, y - 60 * S
    px = lx + (12 * S if side > 0 else -12 * S - 7 * 34 * S)
    add(f'<polyline points="{f(x + side * 10 * S)},{f(y - 10 * S)} {f(lx)},{f(ly)} '
        f'{f(lx + side * 12 * S)},{f(ly)}" fill="none" stroke="{col}" stroke-opacity="0.6" stroke-width="{f(1.6 * S)}"/>')
    add(f'<rect x="{f(px - 6 * S)}" y="{f(ly - 20 * S)}" width="{f(7 * 34 * S + 12 * S)}" height="{f(40 * S)}" '
        f'fill="{STONE0}" fill-opacity="0.72" stroke="{col}" stroke-opacity="0.45" stroke-width="{f(1.5 * S)}"/>')
    for k in range(7):
        g = ORIGIN if k == 6 else GLYPHS[addresses[i][k]]
        glyph(g, px + 17 * S + k * 34 * S, ly, 0.5 * S, AMBER_BRIGHT if chosen else CYAN_BRIGHT,
              0.95 if chosen else 0.7, 1.6)

# ── Rails ──────────────────────────────────────────────────
add(f'<rect y="0" width="{W}" height="{f(top)}" fill="{STONE0}"/>')
line(0, top, W, top, LINE_BRIGHT, 2)
line(0, top - 12 * S, W, top - 12 * S, LINE, 2)
add(f'<line x1="0" y1="{f(top)}" x2="{W}" y2="{f(top)}" stroke="url(#rail)" stroke-width="{f(2 * S)}"/>')
add(f'<rect x="{f(CX - 150 * S)}" y="{f(top - 3 * S)}" width="{f(300 * S)}" height="{f(6 * S)}" fill="{AMBER}"/>')
add(f'<rect x="{f(CX - 150 * S)}" y="{f(top - 3 * S)}" width="{f(300 * S)}" height="{f(6 * S)}" fill="{AMBER}" '
    f'filter="url(#glowSoft)" opacity="0.8"/>')

# ── Frieze: the address being dialed ───────────────────────
add(f'<rect y="{f(frieze)}" width="{W}" height="{f(H - frieze)}" fill="{STONE0}"/>')
line(0, frieze, W, frieze, LINE_BRIGHT, 2)
line(0, frieze + 12 * S, W, frieze + 12 * S, LINE, 2)
add(f'<line x1="0" y1="{f(frieze)}" x2="{W}" y2="{f(frieze)}" stroke="url(#rail)" stroke-width="{f(2 * S)}"/>')

tile, tgap = 150 * S, 26 * S
ty = frieze + 42 * S
n_side = math.ceil((W / 2) / (tile + tgap)) + 1
dest_i = systems.index(dest)
for i in range(-n_side, n_side + 1):
    x0 = CX - tile / 2 + i * (tile + tgap)
    k = i + 3                     # the seven centre tiles hold the address
    active = 0 <= k < 7
    tc = 22 * S
    pts_ = [(x0 + tc, ty), (x0 + tile - tc, ty), (x0 + tile, ty + tc), (x0 + tile, ty + tile - tc),
            (x0 + tile - tc, ty + tile), (x0 + tc, ty + tile), (x0, ty + tile - tc), (x0, ty + tc)]
    poly_pts = " ".join(f"{f(px_)},{f(py_)}" for px_, py_ in pts_)
    gx, gy = x0 + tile / 2, ty + tile / 2
    if active:
        last = k == 6
        col = AMBER if last else CYAN
        add(f'<polygon points="{poly_pts}" fill="{col}" fill-opacity="0.08" stroke="{col}" '
            f'stroke-width="{f(8 * S)}" filter="url(#glow)" opacity="0.7"/>')
        add(f'<polygon points="{poly_pts}" fill="{STONE1}" fill-opacity="0.8" stroke="{AMBER_BRIGHT if last else CYAN_BRIGHT}" '
            f'stroke-width="{f(2.2 * S)}"/>')
        g = ORIGIN if last else GLYPHS[addresses[dest_i][k]]
        glyph(g, gx, gy, 1.7 * S, AMBER_BRIGHT if last else CYAN_BRIGHT, 0.95, 3)
        # Chevron mark above each locked symbol
        add(f'<polygon points="{f(gx - 14 * S)},{f(ty - 22 * S)} {f(gx + 14 * S)},{f(ty - 22 * S)} '
            f'{f(gx)},{f(ty - 8 * S)}" fill="{AMBER}" fill-opacity="0.9"/>')
    else:
        add(f'<polygon points="{poly_pts}" fill="{STONE1}" fill-opacity="0.5" stroke="{LINE_BRIGHT}" '
            f'stroke-width="{f(2 * S)}" stroke-opacity="0.7"/>')
        glyph(GLYPHS[(i * 5 + 40) % len(GLYPHS)], gx, gy, 1.4 * S, CYAN, 0.16, 2.4)

slots_top = ty + tile + 46 * S
line(0, slots_top - 20 * S, W, slots_top - 20 * S, LINE, 2)
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

add(f'<rect width="{W}" height="{H}" fill="url(#vignette)"/>')
add('</svg>')
print("\n".join(out))
