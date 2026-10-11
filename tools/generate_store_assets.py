#!/usr/bin/env python3
"""Battle Dojo store asset generator for BrainSpeed IQ.

Renders the polygon skin cards described by the store spec:

  * 512x512 PNG, transparent background, centered character bust
  * glowing rarity border, 8 px thick, exact rarity hex
  * neon grid / pattern inside the polygon on dark space #0A0E1A
  * top row: Lv.12 chip + coin balance chip (+ red heart when the skin has one)
  * skin name under the frame, coin price in #FFD700 with the word "coin"
  * BUY button strip clipped to the polygon; EQUIPPED variant in green

Outputs
  assets/skins/cards/<skin>.png            store card, BUY state
  assets/skins/cards/<skin>_equipped.png   store card, EQUIPPED state
  assets/skins/busts/<skin>.png            512x512 transparent bust (equip art)
  assets/skins/store_config.json           style guide + drop-in store JSON
  tools/preview_skin_cards.png             contact sheet for humans

Usage:  python3 tools/generate_store_assets.py
Set SKIN_RAW_DIR to point at the source art directory (default
assets/skins/raw, the model output) if you regenerate the busts elsewhere.
"""

from __future__ import annotations

import json
import math
import os
import random
from collections import deque
from dataclasses import dataclass

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW_DIR = os.environ.get("SKIN_RAW_DIR", os.path.join(ROOT, "assets", "skins", "raw"))
CARD_DIR = os.path.join(ROOT, "assets", "skins", "cards")
BUST_DIR = os.path.join(ROOT, "assets", "skins", "busts")
CONFIG_PATH = os.path.join(ROOT, "assets", "skins", "store_config.json")
PREVIEW_PATH = os.path.join(ROOT, "tools", "preview_skin_cards.png")

OUT = 512          # final asset size
PALETTE_COLORS = 256   # per-asset palette; keeps the 512px art under ~200 KB
S = 4              # supersample factor
W = OUT * S        # working canvas

FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

# ---------------------------------------------------------------- colour rules
COIN = "#FFD700"   # coin text / gold
HEART = "#FF0000"  # heart icon red
SPACE = "#0A0E1A"  # dark space background
INK = "#070A14"
WHITE = "#FFFFFF"
EQUIPPED_GREEN = "#1EC86A"


def rgba(hex_str: str, alpha: int = 255) -> tuple[int, int, int, int]:
    h = hex_str.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), alpha)


# --------------------------------------------------------------- shape catalog
@dataclass(frozen=True)
class Shape:
    """Regular polygon in unit space, normalised into the card box."""

    sides: int
    rotation: float           # degrees, first vertex angle (y grows downward)
    box: tuple[float, float]  # width, height as a fraction of the canvas
    center_y: float = 0.395   # vertical centre as a fraction of the canvas
    bust_frac: float = 0.96   # bust width, as a fraction of the frame bbox
    bust_anchor: str = "bottom"   # bottom | center
    chips: str = "inside"     # inside | corners | slope (pointed shapes)
    tall_ratio: float = 1.0   # optional vertical stretch after normalisation

    def vertices(self, cx: float, cy: float,
                 size: float = 512.0) -> list[tuple[float, float]]:
        """Polygon vertices around (cx, cy) on a `size` canvas."""
        pts = []
        for i in range(self.sides):
            a = math.radians(self.rotation + i * (360.0 / self.sides))
            pts.append((math.cos(a), math.sin(a)))
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        sx = self.box[0] * size / (max(xs) - min(xs))
        sy = self.box[1] * self.tall_ratio * size / (max(ys) - min(ys))
        mx = (max(xs) + min(xs)) / 2
        my = (max(ys) + min(ys)) / 2
        return [
            (cx + (x - mx) * sx, cy + (y - my) * sy)
            for x, y in pts
        ]


# rotation is the angle of the first vertex: 0 = right, -90 = up.
# 4 sides at rot 45 would draw a rectangle, so the diamond uses rot 0
# (vertices right/bottom/left/top) which is the true rhombus, and its bust
# is centred in the wide waist with a little overhang.
SHAPES = {
    "hexagon": Shape(6, 0.0, (0.90, 0.72), center_y=0.395),
    "octagon": Shape(8, 22.5, (0.86, 0.72), center_y=0.395),
    "diamond": Shape(4, 0.0, (0.80, 0.72), center_y=0.395, bust_frac=0.95,
                     bust_anchor="center", chips="corners"),
    "pentagon": Shape(5, -90.0, (0.88, 0.72), center_y=0.395),
    "triangle": Shape(3, -90.0, (0.94, 0.68), center_y=0.415, bust_frac=1.05,
                      bust_anchor="center", chips="slope"),
    "golden_hex": Shape(6, 0.0, (0.90, 0.72), center_y=0.395),
}


@dataclass(frozen=True)
class Skin:
    id: int
    skin_id: str
    name: str
    price: int
    frame: str
    rarity: str
    heart: bool
    accent: str
    accent2: str
    pattern: str
    double_border: bool = False
    gradient_border: bool = False
    button: str = ""
    raw: str = ""

    @property
    def button_color(self) -> str:
        return self.button or self.accent

    @property
    def border(self) -> str:
        return self.accent


SPEC: list[Skin] = [
    Skin(id=1, skin_id="neon_ninja", button="#00FFFF", name="Neon Ninja", price=500,
         frame="hexagon", rarity="common", heart=False,
         accent="#00FFFF", accent2="#7CFFFF", pattern="honeycomb"),
    Skin(id=2, skin_id="cyber_samurai", button="#8A2BE2", name="Cyber Samurai", price=700,
         frame="octagon", rarity="rare", heart=False,
         accent="#8A2BE2", accent2="#C77CFF", pattern="circuit",
         double_border=True),
    Skin(id=3, skin_id="shadow_assassin", button="#C026D3", name="Shadow Assassin", price=600,
         frame="diamond", rarity="epic", heart=False,
         accent="#FF00FF", accent2="#8A2BE2", pattern="smoke",
         gradient_border=True),
    Skin(id=4, skin_id="frost_warrior", button="#00BFFF", name="Frost Warrior", price=800,
         frame="pentagon", rarity="legendary", heart=True,
         accent="#00BFFF", accent2="#A8ECFF", pattern="ice"),
    Skin(id=5, skin_id="inferno_mask", button="#FF5A1F", name="Inferno Mask", price=900,
         frame="triangle", rarity="mythic", heart=True,
         accent="#FF4500", accent2="#FFB03A", pattern="flame"),
    Skin(id=6, skin_id="golden_emperor", button="#FFC400", name="Golden Emperor", price=1200,
         frame="golden_hex", rarity="ultimate", heart=True,
         accent="#FFD700", accent2="#FFF3A0", pattern="gold",
         gradient_border=True),
]

CARD_LEVEL = "Lv.12"
CARD_BALANCE = 1240
SCALE = W / OUT


def px(value: float) -> float:
    """Design pixels (512 grid) -> working canvas pixels."""
    return value * SCALE


def font(size: float) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_BOLD, int(round(size * SCALE)))


# ------------------------------------------------------------------ geometry
def offset_polygon(pts, distance):
    """Inset a convex polygon by `distance` (negative = outset)."""
    n = len(pts)
    cx = sum(p[0] for p in pts) / n
    cy = sum(p[1] for p in pts) / n
    lines = []
    for i in range(n):
        p = pts[i]
        q = pts[(i + 1) % n]
        ex, ey = q[0] - p[0], q[1] - p[1]
        length = math.hypot(ex, ey) or 1.0
        ex, ey = ex / length, ey / length
        nx, ny = -ey, ex
        if (cx - p[0]) * nx + (cy - p[1]) * ny < 0:
            nx, ny = -nx, -ny
        lines.append((p[0] + distance * nx, p[1] + distance * ny, ex, ey))
    out = []
    for i in range(n):
        x1, y1, dx1, dy1 = lines[i]
        x2, y2, dx2, dy2 = lines[(i + 1) % n]
        denom = dx1 * dy2 - dy1 * dx2
        t = ((x2 - x1) * dy2 - (y2 - y1) * dx2) / denom
        out.append((x1 + dx1 * t, y1 + dy1 * t))
    return out


def span_at(pts, y):
    """Horizontal (min_x, max_x) of a convex polygon at height y."""
    xs = []
    n = len(pts)
    for i in range(n):
        x1, y1 = pts[i]
        x2, y2 = pts[(i + 1) % n]
        if y1 == y2:
            continue
        lo, hi = (y1, y2) if y1 < y2 else (y2, y1)
        if lo <= y <= hi:
            t = (y - y1) / (y2 - y1)
            xs.append(x1 + (x2 - x1) * t)
    if len(xs) < 2:
        return None
    return min(xs), max(xs)


def scroll_height(pts, width, top, bottom, step=2.0):
    """Highest y where the polygon is at least `width` wide."""
    y = top
    while y <= bottom:
        span = span_at(pts, y)
        if span and span[1] - span[0] >= width:
            return y
        y += step
    return bottom


def polygon_mask(pts, size=W, blur=0.0):
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).polygon(pts, fill=255)
    if blur:
        mask = mask.filter(ImageFilter.GaussianBlur(blur))
    return mask


def gradient(size, top_color, bottom_color, diagonal=True):
    """Linear gradient image; diagonal runs top-left -> bottom-right."""
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    if diagonal:
        t = (xx + yy) / (2.0 * (size - 1))
    else:
        t = yy / (size - 1)
    top = np.array(top_color[:3], dtype=np.float32)
    bottom = np.array(bottom_color[:3], dtype=np.float32)
    rgb = top[None, None, :] * (1 - t[..., None]) + bottom[None, None, :] * t[..., None]
    alpha = np.full((size, size, 1), 255, dtype=np.float32)
    return Image.fromarray(
        np.concatenate([rgb, alpha], axis=2).astype(np.uint8), "RGBA"
    )


def radial_glow(pts, color, radius, strength=170, tight=0.35):
    """Outer soft glow that follows the polygon silhouette."""
    glow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(glow).polygon(pts, fill=rgba(color, strength))
    glow = glow.filter(ImageFilter.GaussianBlur(radius))
    core = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(core).polygon(pts, outline=rgba(color, 235), width=int(px(7)))
    core = core.filter(ImageFilter.GaussianBlur(radius * tight))
    return Image.alpha_composite(glow, core)


# -------------------------------------------------------------------- icons
def draw_coin(draw, cx, cy, r):
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=rgba("#FFC400"),
                 outline=rgba("#8A6100"), width=max(1, int(r * 0.16)))
    draw.ellipse([cx - r * 0.74, cy - r * 0.74, cx + r * 0.74, cy + r * 0.74],
                 outline=rgba("#B98900"), width=max(1, int(r * 0.14)))
    draw.ellipse([cx - r * 0.34, cy - r * 0.44, cx - r * 0.02, cy - r * 0.16],
                 fill=rgba("#FFF6C2", 220))
    glyph = font(r * 1.05)
    draw.text((cx, cy + r * 0.04), "B", font=glyph, anchor="mm",
              fill=rgba("#6A4A00"))


def draw_heart(draw, cx, cy, size, fill=HEART, outline=WHITE, stroke=None):
    """Parametric heart, y grows downward."""
    stroke = stroke if stroke is not None else size * 0.09
    pts = []
    for i in range(90):
        t = 2 * math.pi * i / 90
        x = 16 * math.sin(t) ** 3
        y = -(13 * math.cos(t) - 5 * math.cos(2 * t)
              - 2 * math.cos(3 * t) - math.cos(4 * t))
        pts.append((cx + x * size / 34.0, cy + y * size / 34.0))
    draw.polygon(pts, fill=rgba(fill), outline=rgba(outline),
                 width=max(1, int(stroke)))
    draw.ellipse(
        [cx - size * 0.30, cy - size * 0.30, cx - size * 0.10, cy - size * 0.14],
        fill=rgba(WHITE, 230),
    )


def draw_text(draw, xy, text, fnt, fill, stroke=INK, stroke_width=3.0,
              anchor="mm"):
    draw.text(xy, text, font=fnt, anchor=anchor, fill=rgba(fill),
              stroke_width=max(0, int(px(stroke_width))),
              stroke_fill=rgba(stroke))


def pill(draw, box, radius, fill=INK, outline=None, width=3.0, alpha=232):
    draw.rounded_rectangle(
        box, radius=radius, fill=rgba(fill, alpha),
        outline=rgba(outline) if outline else None,
        width=max(1, int(px(width))) if outline else 0,
    )


# ------------------------------------------------------------------ patterns
def pattern_layer(skin: Skin, rng: random.Random, box) -> Image.Image:
    """Backdrop texture drawn inside the frame, clipped later."""
    layer = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    x0, y0, x1, y1 = box
    if skin.pattern == "honeycomb":
        r = px(26)
        h = r * math.sqrt(3) / 2
        for row in range(int((y1 - y0) / h) + 3):
            for col in range(int((x1 - x0) / (r * 1.5)) + 3):
                cx = x0 - r + col * r * 1.5
                cy = y0 - h + row * h * 2 + (h if col % 2 else 0)
                pts = [(cx + r * math.cos(math.radians(a)),
                        cy + r * math.sin(math.radians(a)))
                       for a in range(0, 360, 60)]
                d.polygon(pts, outline=rgba(skin.accent, 60),
                          width=int(px(1.4)))
    elif skin.pattern == "circuit":
        for _ in range(26):
            x = rng.uniform(x0, x1)
            y = rng.uniform(y0, y1)
            segs = rng.randint(2, 3)
            for _ in range(segs):
                length = rng.uniform(px(40), px(130))
                horizontal = rng.random() < 0.5
                nx, ny = (x + length, y) if horizontal else (x, y + length)
                if rng.random() < 0.5:
                    nx, ny = (x - length, y) if horizontal else (x, y - length)
                d.line([x, y, nx, ny], fill=rgba(skin.accent, 78),
                       width=int(px(1.6)))
                x, y = nx, ny
                d.ellipse([x - px(4), y - px(4), x + px(4), y + px(4)],
                          fill=rgba(skin.accent2, 120))
        for _ in range(60):
            x = rng.uniform(x0, x1)
            y = rng.uniform(y0, y1)
            d.ellipse([x - px(2.2), y - px(2.2), x + px(2.2), y + px(2.2)],
                      fill=rgba(skin.accent, 70))
    elif skin.pattern == "smoke":
        smoke = Image.new("RGBA", (W, W), (0, 0, 0, 0))
        sd = ImageDraw.Draw(smoke)
        for _ in range(22):
            x = rng.uniform(x0, x1)
            y = rng.uniform(y0, y1)
            r = rng.uniform(px(35), px(105))
            sd.ellipse([x - r, y - r, x + r, y + r],
                       fill=rgba(skin.accent if rng.random() < 0.5 else "#8A2BE2", 70))
        layer = Image.alpha_composite(
            layer, smoke.filter(ImageFilter.GaussianBlur(px(22)))
        )
        d = ImageDraw.Draw(layer)
        for _ in range(3):
            y = rng.uniform(y0 + px(40), y1 - px(40))
            pts = [(x0 - px(10), y)]
            for k in range(1, 9):
                pts.append((x0 + (x1 - x0) * k / 8,
                            y + math.sin(k * 0.9) * px(14) * rng.choice([-1, 1])))
            d.line(pts, fill=rgba(skin.accent2, 60), width=int(px(5)), joint="curve")
    elif skin.pattern == "ice":
        for _ in range(30):
            x = rng.uniform(x0, x1)
            y = rng.uniform(y0, y1)
            size = rng.uniform(px(25), px(70))
            pts = [(x, y - size), (x + size * 0.45, y), (x, y + size),
                   (x - size * 0.45, y)]
            d.polygon(pts, fill=rgba(skin.accent, 34),
                      outline=rgba(skin.accent2, 110), width=int(px(1.6)))
        for _ in range(26):
            x = rng.uniform(x0, x1)
            y = rng.uniform(y0, y1)
            r = rng.uniform(px(7), px(16))
            d.line([x - r, y, x + r, y], fill=rgba(WHITE, 150), width=int(px(1.6)))
            d.line([x, y - r, x, y + r], fill=rgba(WHITE, 150), width=int(px(1.6)))
    elif skin.pattern == "flame":
        for _ in range(150):
            x = rng.uniform(x0, x1)
            t = rng.random()
            y = y1 - t * (y1 - y0)
            r = px(2.0 + 4.5 * (1 - t)) * rng.uniform(0.6, 1.2)
            d.ellipse([x - r, y - r, x + r, y + r],
                      fill=rgba(skin.accent2 if rng.random() < 0.4 else skin.accent,
                                int(90 + 140 * (1 - t))))
        for _ in range(9):
            x = rng.uniform(x0 + px(30), x1 - px(30))
            w = rng.uniform(px(16), px(40))
            hgt = rng.uniform(px(50), px(130))
            base = y1 - px(10)
            d.polygon([(x - w, base), (x + w, base),
                       (x + w * 0.3, base - hgt * 0.55), (x, base - hgt),
                       (x - w * 0.35, base - hgt * 0.5)],
                      fill=rgba(skin.accent, 60))
    elif skin.pattern == "gold":
        top_x, top_y = (x0 + x1) / 2, y0
        for i in range(16):
            a = math.pi * (i / 15.0)
            reach = (y1 - y0) * 1.5
            ex = top_x - math.cos(a) * reach
            ey = top_y + math.sin(a) * reach
            d.polygon([(top_x, top_y), (ex - px(9), ey), (ex + px(9), ey)],
                      fill=rgba(skin.accent, 34))
        for _ in range(40):
            x = rng.uniform(x0, x1)
            y = rng.uniform(y0, y1)
            s = rng.uniform(px(6), px(16))
            d.line([x - s, y, x + s, y], fill=rgba(WHITE, 180), width=int(px(2)))
            d.line([x, y - s, x, y + s], fill=rgba(WHITE, 180), width=int(px(2)))
        gloss = Image.new("RGBA", (W, W), (0, 0, 0, 0))
        ImageDraw.Draw(gloss).polygon(
            [(x0, y1), (x0 + (x1 - x0) * 0.45, y0), (x0 + (x1 - x0) * 0.72, y0),
             (x0 + (x1 - x0) * 0.27, y1)], fill=rgba(WHITE, 40))
        layer = Image.alpha_composite(layer, gloss.filter(
            ImageFilter.GaussianBlur(px(6))))
    return layer


def grid_layer(inside, color=rgba("#00FFFF", 26), purple=rgba("#8A2BE2", 26)):
    """Low-poly neon wireframe grid used behind every card."""
    layer = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    step = px(34)
    for x in range(0, W + int(step), int(step)):
        d.line([x, 0, x, W], fill=color, width=int(px(1.2)))
    for y in range(0, W + int(step), int(step)):
        d.line([0, y, W, y], fill=purple, width=int(px(1.2)))
    return layer


# ------------------------------------------------------------------ bust prep
def drop_stray_islands(alpha: Image.Image, keep_share: float = 0.25) -> Image.Image:
    """Keep the subject and drop background blobs the flood fill could not reach.

    Renders with mist, glow or particles leave islands of backdrop behind the
    character; a studio backdrop cannot. Component labelling runs on a quarter
    scale grid and the surviving mask is grown back before it is applied, so the
    subject edge is never clipped.
    """
    small = alpha.resize(
        (max(1, alpha.width // 4), max(1, alpha.height // 4)), Image.NEAREST
    )
    solid = np.array(small) > 96
    h, w = solid.shape
    seen = np.zeros_like(solid)
    components: list[list[tuple[int, int]]] = []
    for y0 in range(h):
        for x0 in range(w):
            if not solid[y0, x0] or seen[y0, x0]:
                continue
            queue = deque([(y0, x0)])
            seen[y0, x0] = True
            cells: list[tuple[int, int]] = []
            while queue:
                y, x = queue.popleft()
                cells.append((y, x))
                for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
                    if 0 <= ny < h and 0 <= nx < w and solid[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        queue.append((ny, nx))
            components.append(cells)
    if len(components) <= 1:
        return alpha
    components.sort(key=len, reverse=True)
    largest = len(components[0])
    keep = np.zeros_like(solid)
    dropped = 0
    for cells in components:
        if len(cells) >= keep_share * largest:
            for y, x in cells:
                keep[y, x] = True
        else:
            dropped += 1
    if dropped:
        print(f"  dropped {dropped} stray background island(s)")
    keep_img = Image.fromarray((keep * 255).astype(np.uint8), "L")
    keep_img = (
        keep_img.resize(alpha.size, Image.NEAREST)
        .filter(ImageFilter.MaxFilter(5))
        .filter(ImageFilter.GaussianBlur(1.2))
    )
    return ImageChops.multiply(alpha, keep_img)


def cut_bust(path: str) -> Image.Image:
    """Drop the flat studio background, keep the rendered subject."""
    im = Image.open(path).convert("RGBA")
    rgb = im.convert("RGB")
    key = (255, 0, 255)
    flood = rgb.copy()
    w, h = flood.size
    seeds = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1),
             (w // 2, 0), (w // 2, h - 1), (0, h // 2), (w - 1, h // 2),
             (w // 4, 0), (3 * w // 4, 0), (w // 4, h - 1), (3 * w // 4, h - 1)]
    for seed in seeds:
        if flood.getpixel(seed) != key:
            ImageDraw.floodfill(flood, seed, key, thresh=30)
    arr = np.array(flood)
    is_key = (arr[:, :, 0] > 248) & (arr[:, :, 1] < 8) & (arr[:, :, 2] > 248)
    alpha = np.where(is_key, 0, 255).astype(np.uint8)
    alpha_img = Image.fromarray(alpha, "L").filter(ImageFilter.GaussianBlur(0.9))
    alpha_img = drop_stray_islands(alpha_img)
    out = im.copy()
    out.putalpha(alpha_img)
    bbox = out.getbbox()
    return out.crop(bbox) if bbox else out


def save_asset(image: Image.Image, path: str, colors: int = PALETTE_COLORS) -> None:
    """Save a PNG with an adaptive palette so each 512px asset stays small."""
    image.convert("RGBA").quantize(
        colors=colors, method=Image.FASTOCTREE, dither=Image.FLOYDSTEINBERG
    ).save(path, optimize=True)


def bust_512(bust: Image.Image) -> Image.Image:
    art = bust.copy()
    art.thumbnail((OUT - 20, OUT - 20), Image.LANCZOS)
    canvas = Image.new("RGBA", (OUT, OUT), (0, 0, 0, 0))
    canvas.paste(art, ((OUT - art.width) // 2, (OUT - art.height) // 2), art)
    return canvas


# --------------------------------------------------------------------- card
def render_card(skin: Skin, bust: Image.Image, equipped: bool,
                rng_seed: int) -> Image.Image:
    """One 512x512 transparent store card, BUY or EQUIPPED state."""
    rng = random.Random(rng_seed)
    shape = SHAPES[skin.frame]
    cx = W / 2
    cy = shape.center_y * W
    outer = shape.vertices(cx, cy, W)
    border = px(8)                        # the 8 px glowing rarity border
    panel = offset_polygon(outer, border + px(6))
    deep = offset_polygon(outer, border * 0.42 + px(2))

    accent = EQUIPPED_GREEN if equipped else skin.border
    accent2 = EQUIPPED_GREEN if equipped else skin.accent2
    button_col = EQUIPPED_GREEN if equipped else skin.button_color

    card = Image.new("RGBA", (W, W), (0, 0, 0, 0))

    # 1. outer soft glow that follows the silhouette
    card = Image.alpha_composite(card, radial_glow(outer, accent, px(15), 150))

    # 2. rarity border ring (solid or gradient) + dark keyline
    ring_mask = ImageChops.subtract(polygon_mask(outer), polygon_mask(deep))
    ring_mask = ring_mask.filter(ImageFilter.GaussianBlur(0.7))
    if skin.gradient_border:
        ring = gradient(W, rgba(skin.accent), rgba(skin.accent2))
    else:
        ring = Image.new("RGBA", (W, W), rgba(accent))
    card.paste(ring, (0, 0), ring_mask)
    key = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(key).polygon(offset_polygon(outer, -px(2.5)),
                                outline=rgba(INK), width=int(px(3)))
    card = Image.alpha_composite(card, key)

    # 3. dark space panel + neon grid + rarity pattern, clipped to the frame
    panel_mask = polygon_mask(panel)
    card.paste(Image.new("RGBA", (W, W), rgba(SPACE)), (0, 0), panel_mask)
    box = (min(p[0] for p in panel), min(p[1] for p in panel),
           max(p[0] for p in panel), max(p[1] for p in panel))
    texture = Image.alpha_composite(
        grid_layer(panel), pattern_layer(skin, rng, box))
    texture.putalpha(ImageChops.multiply(texture.getchannel("A"), panel_mask))
    card = Image.alpha_composite(card, texture)

    if skin.double_border:
        dbl = Image.new("RGBA", (W, W), (0, 0, 0, 0))
        ImageDraw.Draw(dbl).polygon(offset_polygon(outer, border + px(9)),
                                    outline=rgba(accent2, 160), width=int(px(2)))
        card = Image.alpha_composite(card, dbl)

    # 4. HUD chips: Lv.12 + coin balance (+ red heart when the skin has one).
    #    Pointed frames either hug their own slopes or float over the corners.
    lv_font, bal_font = font(21), font(21)
    text_stroke = 2.4
    chip_h, chip_pad = px(38), px(13)
    heart_w, coin_r, gap = px(26), px(11.5), px(7)
    lv_text, bal_text = CARD_LEVEL, f"{CARD_BALANCE:,}"

    def text_w(text, fnt, sw=text_stroke):
        probe = ImageDraw.Draw(Image.new("L", (8, 8)))
        return probe.textbbox((0, 0), text, font=fnt,
                              stroke_width=int(px(sw)))[2]

    lv_w = text_w(lv_text, lv_font)
    bal_w = text_w(bal_text, bal_font)
    lv_chip_w = lv_w + chip_pad * 2 + px(6)
    bal_chip_w = (bal_w + coin_r * 2 + gap * 3 + chip_pad * 2
                  + (heart_w + gap if skin.heart else 0))
    chip_row_y = 0.0

    if shape.chips == "corners":
        chip_row_y = px(14)
        left, right = px(12), W - px(12)
        glass = True
    elif shape.chips == "slope":
        # sit against the upper slopes of the apex, not the canvas corners
        chip_row_y = px(108)
        top_span = span_at(panel, chip_row_y) or (box[0], box[2])
        bot_span = span_at(panel, chip_row_y + chip_h) or (box[0], box[2])
        left = max(px(10), max(top_span[0], bot_span[0]) - px(12) - lv_chip_w)
        right = min(W - px(10),
                    min(top_span[1], bot_span[1]) + px(12) + bal_chip_w)
        glass = True
    else:
        need = lv_chip_w + bal_chip_w + px(16)
        chip_row_y = scroll_height(panel, need + px(6), box[1] - px(40),
                                   box[3] * 0.55) + px(7)
        span = span_at(panel, chip_row_y) or (box[0], box[2])
        left, right = span[0] + px(14), span[1] - px(14)
        glass = False

    if glass:
        shade = Image.new("RGBA", (W, W), (0, 0, 0, 0))
        sd = ImageDraw.Draw(shade)
        sd.rounded_rectangle([left, chip_row_y, left + lv_chip_w,
                              chip_row_y + chip_h], radius=px(9),
                             fill=rgba("#000000", 165))
        sd.rounded_rectangle([right - bal_chip_w, chip_row_y, right,
                              chip_row_y + chip_h], radius=px(9),
                             fill=rgba("#000000", 165))
        card = Image.alpha_composite(card, shade.filter(
            ImageFilter.GaussianBlur(px(7))))

    # 5. button bar geometry, needed before the bust is placed
    bar_h = px(46)
    bar_y = box[3] - bar_h - px(18)
    if shape.chips == "corners":
        # the diamond narrows fast: lift its bar so it still fits the waist
        bar_y = box[3] - bar_h - px(46)
    bust_bottom = bar_y - px(6)

    # 6. character bust: contain-fit inside the usable panel area
    art = bust.copy()
    box_w, box_h = box[2] - box[0], box[3] - box[1]
    usable_h = max(px(60), bust_bottom - box[1])
    head_floor = box[1] + px(8)
    if not glass:
        head_floor = max(head_floor, chip_row_y + chip_h + px(8))
    scale = min(box_w * shape.bust_frac / art.width, usable_h / art.height)
    art = art.resize((max(1, int(art.width * scale)),
                      max(1, int(art.height * scale))), Image.LANCZOS)
    if shape.bust_anchor == "center":
        ay = int((box[1] + bust_bottom) / 2 - art.height * 0.62)
        ay = max(ay, int(head_floor))
        ay = min(ay, int(bust_bottom - art.height))
    else:
        ay = int(bust_bottom - art.height)
        ay = max(ay, int(head_floor))
    ax = int(cx - art.width / 2)

    shadow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    shadow.paste(Image.new("RGBA", art.size, rgba("#000000", 200)), (ax, ay), art)
    shadow = shadow.filter(ImageFilter.GaussianBlur(px(9)))
    shadow.putalpha(ImageChops.multiply(shadow.getchannel("A"),
                                        polygon_mask(panel, blur=px(3))))
    card = Image.alpha_composite(card, shadow)

    bust_layer = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    bust_layer.paste(art, (ax, ay), art)
    bust_layer.putalpha(ImageChops.multiply(bust_layer.getchannel("A"),
                                            polygon_mask(panel, blur=px(2))))
    card = Image.alpha_composite(card, bust_layer)

    # glass sheen across the top of the panel
    sheen = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(sheen).polygon(panel, fill=rgba(accent, 30))
    sheen = sheen.filter(ImageFilter.GaussianBlur(px(20)))
    top_mask = Image.new("L", (W, W), 0)
    ImageDraw.Draw(top_mask).rectangle(
        [0, 0, W, int(box[1] + box_h * 0.40)], fill=255)
    top_mask = top_mask.filter(ImageFilter.GaussianBlur(px(26)))
    sheen.putalpha(ImageChops.multiply(
        ImageChops.multiply(sheen.getchannel("A"), top_mask),
        polygon_mask(panel, blur=px(2))))
    card = Image.alpha_composite(card, sheen)

    d = ImageDraw.Draw(card)
    mid_y = chip_row_y + chip_h / 2
    lv_box = [left, chip_row_y, left + lv_chip_w, chip_row_y + chip_h]
    pill(d, lv_box, radius=px(9), fill=INK, outline=accent, width=2.6, alpha=246)
    draw_text(d, (lv_box[0] + chip_pad + px(3), mid_y), lv_text, lv_font,
              accent, stroke=INK, stroke_width=text_stroke, anchor="lm")

    bal_box = [right - bal_chip_w, chip_row_y, right, chip_row_y + chip_h]
    pill(d, bal_box, radius=px(9), fill=INK, outline=COIN, width=2.6, alpha=246)
    cursor = bal_box[0] + chip_pad
    if skin.heart:
        draw_heart(d, cursor + heart_w / 2, mid_y, heart_w)
        cursor += heart_w + gap
    draw_coin(d, cursor + coin_r, mid_y, coin_r)
    draw_text(d, (cursor + coin_r * 2 + gap, mid_y), bal_text, bal_font, COIN,
              stroke=INK, stroke_width=text_stroke, anchor="lm")

    # 6. price pill + name pill + rarity tag, stacked under the frame
    rarity_font, name_font, price_font, word_font = (font(15), font(27),
                                                     font(25), font(13))
    price_text = f"{skin.price:,}"
    price_w = text_w(price_text, price_font, 2.6)
    word_w = text_w("coin", word_font, 2.0)
    owned_w = text_w("OWNED", price_font, 2.6)
    coin_d = px(13)
    price_h = px(42)
    price_y = px(486) - price_h / 2
    gap_a, gap_b = px(9), px(10)
    if equipped:
        content_w = coin_d * 2 + gap_a + owned_w
    else:
        content_w = (coin_d * 2 + gap_a + price_w + gap_b + word_w
                     + (px(8) + heart_w if skin.heart else 0))
    price_pill_w = content_w + px(20) * 2
    price_box = [cx - price_pill_w / 2, price_y,
                 cx + price_pill_w / 2, price_y + price_h]
    pill(d, price_box, radius=px(11), fill=INK,
         outline=EQUIPPED_GREEN if equipped else COIN, width=3, alpha=248)
    mid = price_y + price_h / 2
    cursor = price_box[0] + px(20)
    draw_coin(d, cursor + coin_d, mid, coin_d)
    cursor += coin_d * 2 + gap_a
    if equipped:
        draw_text(d, (cursor, mid), "OWNED", price_font, EQUIPPED_GREEN,
                  stroke=INK, stroke_width=2.6, anchor="lm")
    else:
        draw_text(d, (cursor, mid), price_text, price_font, COIN,
                  stroke=INK, stroke_width=2.6, anchor="lm")
        cursor += price_w + gap_b
        draw_text(d, (cursor, mid + px(4)), "coin", word_font, COIN,
                  stroke=INK, stroke_width=2.0, anchor="lm")
        cursor += word_w + px(8)
        if skin.heart:
            draw_heart(d, cursor + heart_w / 2, mid, heart_w)

    name_text = skin.name.upper()
    name_w = text_w(name_text, name_font, 2.6)
    name_pill_w = name_w + px(34)
    name_h = px(44)
    name_y = px(433) - name_h / 2
    name_box = [cx - name_pill_w / 2, name_y, cx + name_pill_w / 2,
                name_y + name_h]
    pill(d, name_box, radius=px(9), fill=INK, outline=accent, width=3, alpha=244)
    draw_text(d, (cx, name_y + name_h / 2), name_text, name_font, WHITE,
              stroke=INK, stroke_width=2.6)

    rarity_text = "EQUIPPED" if equipped else skin.rarity.upper()
    r_w = text_w(rarity_text, rarity_font, 1.6)
    r_h = px(24)
    r_y = name_y - r_h - px(2)
    r_box = [cx - r_w / 2 - px(13), r_y, cx + r_w / 2 + px(13), r_y + r_h]
    pill(d, r_box, radius=px(7), fill=accent, outline=INK, width=2.2, alpha=246)
    draw_text(d, (cx, r_y + r_h / 2), rarity_text, rarity_font, INK,
              stroke=INK, stroke_width=1.4)

    # 7. BUY / EQUIPPED bar, clipped to the frame with a dark backing plate
    bar_span = span_at(panel, bar_y + bar_h / 2) or (box[0], box[2])
    label = "EQUIPPED" if equipped else "BUY"
    label_w = text_w(label, font(24), 0.8)
    max_w = (bar_span[1] - bar_span[0]) * (
        0.78 if shape.chips == "corners" else 0.9)
    bar_w = min(max_w, max(label_w + px(56), px(190)))
    bar_cx = (bar_span[0] + bar_span[1]) / 2
    bar_box = [bar_cx - bar_w / 2, bar_y, bar_cx + bar_w / 2, bar_y + bar_h]

    plate = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    ImageDraw.Draw(plate).rounded_rectangle(
        [bar_box[0] - px(10), bar_box[1] - px(8), bar_box[2] + px(10),
         bar_box[3] + px(8)], radius=px(14), fill=rgba("#000000", 165))
    plate.putalpha(ImageChops.multiply(plate.getchannel("A"),
                                       polygon_mask(panel, blur=px(6))))
    card = Image.alpha_composite(card, plate.filter(ImageFilter.GaussianBlur(px(5))))

    button = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    bd = ImageDraw.Draw(button)
    bd.rounded_rectangle(bar_box, radius=px(11), fill=rgba(button_col),
                         outline=rgba(INK), width=int(px(3)))
    bd.rectangle([bar_box[0] + px(3), bar_box[1] + px(3), bar_box[2] - px(3),
                  bar_box[1] + px(15)], fill=rgba(WHITE, 70))
    button.putalpha(ImageChops.multiply(button.getchannel("A"),
                                        polygon_mask(panel, blur=px(1.4))))
    card = Image.alpha_composite(card, button)
    d = ImageDraw.Draw(card)
    draw_text(d, (bar_cx, bar_y + bar_h / 2 + px(2)), label, font(24), INK,
              stroke=INK, stroke_width=0.8)

    return card.resize((OUT, OUT), Image.LANCZOS)


def build_config() -> dict:
    frames = {}
    for skin in SPEC:
        entry = {
            "rarity": skin.rarity,
            "border": skin.border,
            "shape": {"hexagon": "hex", "octagon": "oct"}.get(
                skin.frame, skin.frame),
        }
        if skin.heart:
            entry["heart"] = True
        frames[skin.frame] = entry
    return {
        "store_config": {
            "coin_color": COIN,
            "heart_color": HEART,
            "coin_text_suffix": "coin",
            "space_color": SPACE,
            "level_label": CARD_LEVEL,
            "coin_balance_sample": CARD_BALANCE,
            "asset_format": "512x512 PNG transparent",
            "border_width_px": 8,
            "frames": frames,
            "skins": [
                {
                    "id": skin.id,
                    "name": skin.name,
                    "price": skin.price,
                    "frame": skin.frame,
                    "heart": skin.heart,
                    "asset": f"assets/skins/cards/{skin.skin_id}.png",
                    "equipped_asset": f"assets/skins/cards/{skin.skin_id}_equipped.png",
                    "bust": f"assets/skins/busts/{skin.skin_id}.png",
                }
                for skin in SPEC
            ],
        }
    }


def main() -> None:
    os.makedirs(CARD_DIR, exist_ok=True)
    os.makedirs(BUST_DIR, exist_ok=True)

    cards = []
    for skin in SPEC:
        raw = os.path.join(RAW_DIR, f"{skin.skin_id}.png")
        if not os.path.exists(raw):
            raise SystemExit(f"missing source art: {raw}")
        bust = cut_bust(raw)
        save_asset(bust_512(bust), os.path.join(BUST_DIR, f"{skin.skin_id}.png"))
        for equipped in (False, True):
            card = render_card(skin, bust, equipped, rng_seed=skin.id * 977)
            suffix = "_equipped" if equipped else ""
            path = os.path.join(CARD_DIR, f"{skin.skin_id}{suffix}.png")
            save_asset(card, path)
            if not equipped:
                cards.append((skin, card))
        print(f"rendered {skin.name:16s} -> {skin.frame:10s} {skin.rarity}")

    with open(CONFIG_PATH, "w", encoding="utf-8") as fh:
        json.dump(build_config(), fh, indent=2)
        fh.write("\n")

    # contact sheet for humans
    cols, rows = 3, 2
    cell = OUT
    label_h = 34
    sheet = Image.new("RGB", (cols * cell, rows * (cell + label_h)), "#1B1F2A")
    sd = ImageDraw.Draw(sheet)
    for i, (skin, card) in enumerate(cards):
        px_x = (i % cols) * cell
        px_y = (i // cols) * (cell + label_h)
        sheet.paste(card, (px_x, px_y), card)
        sd.text((px_x + 10, px_y + cell + 8),
                f"{skin.name} - {skin.rarity} - {skin.price} coin",
                font=ImageFont.truetype(FONT_BOLD, 17), fill="#F5F7FF")
    sheet.save(PREVIEW_PATH, optimize=True)
    print(f"wrote {CONFIG_PATH}")
    print(f"wrote {PREVIEW_PATH}")


if __name__ == "__main__":
    main()
