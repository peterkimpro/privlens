#!/usr/bin/env python3
"""Generate Privlens app icon - 1024x1024 PNG for iOS."""

from PIL import Image, ImageDraw, ImageFont
import math

SIZE = 1024
img = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
draw = ImageDraw.Draw(img)

# --- Background: full-bleed gradient (iOS applies its own rounded mask) ---
def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(len(c1)))

# Draw gradient background - fill entire square
top_color = (40, 100, 220)     # bright blue
bottom_color = (90, 50, 180)   # indigo/purple

for y in range(SIZE):
    t = y / SIZE
    color = lerp_color(top_color, bottom_color, t)
    draw.line([(0, y), (SIZE, y)], fill=color)

# --- Shield shape (centered, white, semi-transparent) ---
cx, cy = SIZE // 2, SIZE // 2 + 20
shield_w, shield_h = 480, 560

def draw_shield(draw, cx, cy, w, h, fill, outline=None, outline_width=0):
    """Draw a shield shape."""
    top = cy - h // 2
    bottom = cy + h // 2
    left = cx - w // 2
    right = cx + w // 2
    mid_y = cy + h // 6

    points = []
    # Top-left rounded corner
    corner_r = 60
    steps = 20
    for i in range(steps + 1):
        angle = math.pi + (math.pi / 2) * (i / steps)
        px = left + corner_r + corner_r * math.cos(angle)
        py = top + corner_r + corner_r * math.sin(angle)
        points.append((px, py))

    # Top-right rounded corner
    for i in range(steps + 1):
        angle = -math.pi / 2 + (math.pi / 2) * (i / steps)
        px = right - corner_r + corner_r * math.cos(angle)
        py = top + corner_r + corner_r * math.sin(angle)
        points.append((px, py))

    # Right side down to mid
    points.append((right, mid_y))
    # Bottom point
    points.append((cx, bottom))
    # Left side from mid
    points.append((left, mid_y))

    if fill:
        draw.polygon(points, fill=fill)
    if outline:
        draw.polygon(points, outline=outline)
        # Draw thicker outline
        for i in range(len(points)):
            p1 = points[i]
            p2 = points[(i + 1) % len(points)]
            draw.line([p1, p2], fill=outline, width=outline_width)

# Convert base to RGBA for compositing overlays
img = img.convert("RGBA")

# Draw shield - white with some transparency
shield_overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
shield_draw = ImageDraw.Draw(shield_overlay)
draw_shield(shield_draw, cx, cy, shield_w, shield_h, fill=(255, 255, 255, 60))
draw_shield(shield_draw, cx, cy, shield_w, shield_h, fill=None, outline=(255, 255, 255, 180), outline_width=6)
img = Image.alpha_composite(img, shield_overlay)

# --- Document icon inside shield ---
doc_overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
doc_draw = ImageDraw.Draw(doc_overlay)

doc_w, doc_h = 200, 260
doc_left = cx - doc_w // 2
doc_top = cy - doc_h // 2 - 30
fold = 50

# Document body
doc_points = [
    (doc_left, doc_top),
    (doc_left + doc_w - fold, doc_top),
    (doc_left + doc_w, doc_top + fold),
    (doc_left + doc_w, doc_top + doc_h),
    (doc_left, doc_top + doc_h),
]
doc_draw.polygon(doc_points, fill=(255, 255, 255, 230))

# Fold triangle
fold_points = [
    (doc_left + doc_w - fold, doc_top),
    (doc_left + doc_w, doc_top + fold),
    (doc_left + doc_w - fold, doc_top + fold),
]
doc_draw.polygon(fold_points, fill=(200, 210, 240, 200))

# Text lines on document
line_y = doc_top + 70
for i, w_ratio in enumerate([0.7, 0.55, 0.65, 0.4]):
    lw = int(doc_w * w_ratio * 0.75)
    doc_draw.rounded_rectangle(
        [doc_left + 30, line_y, doc_left + 30 + lw, line_y + 12],
        radius=4,
        fill=(100, 130, 200, 180)
    )
    line_y += 28

img = Image.alpha_composite(img, doc_overlay)

# --- Magnifying glass / lens overlay (bottom-right of document) ---
lens_overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
lens_draw = ImageDraw.Draw(lens_overlay)

lens_cx = cx + 80
lens_cy = cy + 80
lens_r = 80

# Lens circle
lens_draw.ellipse(
    [lens_cx - lens_r, lens_cy - lens_r, lens_cx + lens_r, lens_cy + lens_r],
    fill=(180, 220, 255, 80),
    outline=(255, 255, 255, 240),
    width=8
)

# Lens handle
handle_angle = math.pi / 4  # 45 degrees
hx1 = lens_cx + int((lens_r - 4) * math.cos(handle_angle))
hy1 = lens_cy + int((lens_r - 4) * math.sin(handle_angle))
hx2 = lens_cx + int((lens_r + 65) * math.cos(handle_angle))
hy2 = lens_cy + int((lens_r + 65) * math.sin(handle_angle))
lens_draw.line([(hx1, hy1), (hx2, hy2)], fill=(255, 255, 255, 240), width=12)

# Small checkmark/spark inside lens to hint "AI insight"
spark_cx, spark_cy = lens_cx - 10, lens_cy - 5
check_points = [
    (spark_cx - 20, spark_cy),
    (spark_cx - 5, spark_cy + 18),
    (spark_cx + 25, spark_cy - 18),
]
lens_draw.line(check_points, fill=(180, 255, 200, 230), width=7, joint="curve")

img = Image.alpha_composite(img, lens_overlay)

# --- "PRIVLENS" text at bottom of shield ---
text_overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
text_draw = ImageDraw.Draw(text_overlay)

try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 52)
except:
    font = ImageFont.load_default()

text = "PRIVLENS"
bbox = text_draw.textbbox((0, 0), text, font=font)
tw = bbox[2] - bbox[0]
text_x = cx - tw // 2
text_y = cy + 190
text_draw.text((text_x, text_y), text, fill=(255, 255, 255, 200), font=font)

img = Image.alpha_composite(img, text_overlay)

# --- Save as opaque RGB PNG (no alpha — required by iOS) ---
output_path = "/home/petekim/command-center/repos/privlens/App/Privlens/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
final = img.convert("RGB")
final.save(output_path, "PNG")
print(f"Icon saved to {output_path}")

preview_path = "/home/petekim/command-center/repos/privlens/AppIcon.png"
final.save(preview_path, "PNG")
print(f"Preview copy saved to {preview_path}")
