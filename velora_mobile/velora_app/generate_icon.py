"""Generate a premium V app icon — geometric V with shield accent on dark bg."""
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import math
import os

SIZE = 1024
PAD = int(SIZE * 0.02)

# ── Base canvas with rich dark gradient ──────────────────────────
img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Rounded-rectangle background (simulated with filled rect + corner circles)
bg_color = (8, 12, 28)  # Near-black blue
corner_r = int(SIZE * 0.18)

def rounded_rect(d, xy, r, fill):
    x0, y0, x1, y1 = xy
    d.rectangle([x0 + r, y0, x1 - r, y1], fill=fill)
    d.rectangle([x0, y0 + r, x1, y1 - r], fill=fill)
    d.pieslice([x0, y0, x0 + 2*r, y0 + 2*r], 180, 270, fill=fill)
    d.pieslice([x1 - 2*r, y0, x1, y0 + 2*r], 270, 360, fill=fill)
    d.pieslice([x0, y1 - 2*r, x0 + 2*r, y1], 90, 180, fill=fill)
    d.pieslice([x1 - 2*r, y1 - 2*r, x1, y1], 0, 90, fill=fill)

rounded_rect(draw, (0, 0, SIZE - 1, SIZE - 1), corner_r, bg_color)

# ── Subtle radial gradient glow (blue-purple) ───────────────────
glow = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
cx, cy = SIZE // 2, SIZE // 2
for r in range(int(SIZE * 0.55), 0, -3):
    frac = r / (SIZE * 0.55)
    a = int(35 * frac * frac)
    gd.ellipse([cx - r, cy - r - 40, cx + r, cy + r - 40],
               fill=(80, 100, 255, a))
img = Image.alpha_composite(img, glow)
draw = ImageDraw.Draw(img)

# ── Accent: subtle diamond / shield outline behind the V ────────
diamond_layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
dd = ImageDraw.Draw(diamond_layer)
# Diamond points
d_top    = (cx, int(SIZE * 0.06))
d_left   = (int(SIZE * 0.10), cy - 20)
d_right  = (int(SIZE * 0.90), cy - 20)
d_bottom = (cx, int(SIZE * 0.94))
diamond_pts = [d_top, d_right, d_bottom, d_left]

# Outer glow of diamond
for offset in range(18, 0, -2):
    a = int(12 * (1 - offset / 18))
    expanded = []
    for px, py in diamond_pts:
        dx = px - cx
        dy = py - cy
        dist = math.sqrt(dx*dx + dy*dy) or 1
        expanded.append((px + dx / dist * offset, py + dy / dist * offset))
    dd.polygon(expanded, fill=(100, 140, 255, a))

# Diamond outline (thin elegant stroke)
dd.polygon(diamond_pts, outline=(120, 160, 255, 90))
# Second inner outline
shrink = 6
inner_diamond = []
for px, py in diamond_pts:
    dx = px - cx
    dy = py - cy
    dist = math.sqrt(dx*dx + dy*dy) or 1
    inner_diamond.append((px - dx / dist * shrink, py - dy / dist * shrink))
dd.polygon(inner_diamond, outline=(100, 140, 255, 50))

img = Image.alpha_composite(img, diamond_layer)
draw = ImageDraw.Draw(img)

# ── THE V — clean, bold, geometric ──────────────────────────────
v_top    = int(SIZE * 0.14)
v_bottom = int(SIZE * 0.84)
v_half_w = int(SIZE * 0.34)
stroke   = int(SIZE * 0.115)
gap      = int(SIZE * 0.012)   # center split gap for modern look

# Left arm
L1 = (cx - v_half_w, v_top)                                    # outer top-left
L2 = (cx - v_half_w + stroke, v_top)                           # inner top-left
L3 = (cx - gap, v_bottom - int(stroke * 0.45))                 # inner bottom
L4 = (cx - gap, v_bottom)                                      # outer bottom

left_arm = [L1, L2, L3, L4]

# Right arm
R1 = (cx + v_half_w, v_top)
R2 = (cx + v_half_w - stroke, v_top)
R3 = (cx + gap, v_bottom - int(stroke * 0.45))
R4 = (cx + gap, v_bottom)

right_arm = [R1, R2, R3, R4]

# --- Drop shadow for the V ---
shadow = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
sd = ImageDraw.Draw(shadow)
shadow_off = 8
shadow_arms_l = [(x + shadow_off, y + shadow_off) for x, y in left_arm]
shadow_arms_r = [(x + shadow_off, y + shadow_off) for x, y in right_arm]
sd.polygon(shadow_arms_l, fill=(0, 0, 0, 120))
sd.polygon(shadow_arms_r, fill=(0, 0, 0, 120))
shadow = shadow.filter(ImageFilter.GaussianBlur(radius=18))
img = Image.alpha_composite(img, shadow)
draw = ImageDraw.Draw(img)

# --- Main V fill: gradient from white-silver at top to ice-blue at bottom ---
# We'll draw the V in horizontal slices for a gradient effect
v_layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
vd = ImageDraw.Draw(v_layer)

def lerp_color(c1, c2, t):
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))

# Top color: pure bright silver-white
top_col = (245, 248, 255, 255)
# Bottom color: ice-blue silver
bot_col = (180, 210, 245, 255)

num_slices = v_bottom - v_top
for i in range(num_slices):
    y = v_top + i
    t = i / max(num_slices - 1, 1)
    col = lerp_color(top_col, bot_col, t)

    # For each y, compute x-bounds of left arm and right arm
    # Left arm outer edge: L1 -> L4
    lox = L1[0] + (L4[0] - L1[0]) * t
    # Left arm inner edge: L2 -> L3
    lix = L2[0] + (L3[0] - L2[0]) * t
    # Right arm outer edge: R1 -> R4
    rox = R1[0] + (R4[0] - R1[0]) * t
    # Right arm inner edge: R2 -> R3
    rix = R2[0] + (R3[0] - R2[0]) * t

    if lox < lix:
        vd.line([(int(lox), y), (int(lix), y)], fill=col, width=1)
    if rix < rox:
        vd.line([(int(rix), y), (int(rox), y)], fill=col, width=1)

img = Image.alpha_composite(img, v_layer)
draw = ImageDraw.Draw(img)

# --- Highlight: bright white edge on outer sides of V ---
hl_layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
hd = ImageDraw.Draw(hl_layer)
hl_w = max(stroke // 5, 6)

# Left outer highlight
hl_left = [
    L1,
    (L1[0] + hl_w, L1[1]),
    (L4[0] + hl_w * 0.15, L4[1] - hl_w),
    L4,
]
hd.polygon(hl_left, fill=(255, 255, 255, 160))

# Right outer highlight
hl_right = [
    R1,
    (R1[0] - hl_w, R1[1]),
    (R4[0] - hl_w * 0.15, R4[1] - hl_w),
    R4,
]
hd.polygon(hl_right, fill=(255, 255, 255, 130))

img = Image.alpha_composite(img, hl_layer)
draw = ImageDraw.Draw(img)

# --- Top cap: bright horizontal bar across tops of both arms ---
cap_h = 8
draw.rectangle([L1[0], v_top, L2[0], v_top + cap_h], fill=(255, 255, 255, 210))
draw.rectangle([R2[0], v_top, R1[0], v_top + cap_h], fill=(255, 255, 255, 210))

# --- Bottom tip glow ---
tip_glow = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
tgd = ImageDraw.Draw(tip_glow)
for r in range(30, 0, -1):
    a = int(90 * (1 - r / 30))
    tgd.ellipse([cx - r, v_bottom - r - 5, cx + r, v_bottom + r - 5],
                fill=(200, 220, 255, a))
img = Image.alpha_composite(img, tip_glow)
draw = ImageDraw.Draw(img)

# --- Small accent dots at top corners of V for tech feel ---
dot_r = 6
for (dx, dy) in [L1, L2, R1, R2]:
    draw.ellipse([dx - dot_r, dy - dot_r, dx + dot_r, dy + dot_r],
                 fill=(150, 190, 255, 120))

# ── Save ─────────────────────────────────────────────────────────
icon_dir = os.path.join(os.path.dirname(__file__), 'assets')
os.makedirs(icon_dir, exist_ok=True)

icon_path = os.path.join(icon_dir, 'app_icon.png')
img.save(icon_path, 'PNG')
print(f'Icon saved to {icon_path}')

# ── Foreground-only for adaptive icons ───────────────────────────
fg = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
# Re-draw just the V gradient + highlights on transparent bg
fg_v = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
fvd = ImageDraw.Draw(fg_v)
for i in range(num_slices):
    y = v_top + i
    t = i / max(num_slices - 1, 1)
    col = lerp_color(top_col, bot_col, t)
    lox = L1[0] + (L4[0] - L1[0]) * t
    lix = L2[0] + (L3[0] - L2[0]) * t
    rox = R1[0] + (R4[0] - R1[0]) * t
    rix = R2[0] + (R3[0] - R2[0]) * t
    if lox < lix:
        fvd.line([(int(lox), y), (int(lix), y)], fill=col, width=1)
    if rix < rox:
        fvd.line([(int(rix), y), (int(rox), y)], fill=col, width=1)
fg = Image.alpha_composite(fg, fg_v)
fhd = ImageDraw.Draw(fg)
fhd.polygon(hl_left, fill=(255, 255, 255, 160))
fhd.polygon(hl_right, fill=(255, 255, 255, 130))
fhd.rectangle([L1[0], v_top, L2[0], v_top + cap_h], fill=(255, 255, 255, 210))
fhd.rectangle([R2[0], v_top, R1[0], v_top + cap_h], fill=(255, 255, 255, 210))

fg_path = os.path.join(icon_dir, 'app_icon_foreground.png')
fg.save(fg_path, 'PNG')
print(f'Foreground saved to {fg_path}')
