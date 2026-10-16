"""Generates placeholder PNG art for the Coin Troll Adventure prototype.
Every file is a static stand-in meant to be replaced by the final art
(same file names) per the art schedule."""
import os, math, random
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(__file__), "..", "assets")
random.seed(7)

OUT = "#1a1420"

def save(img, rel):
    p = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    img.save(p)

def canvas(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))

def ell(d, box, fill, outline=OUT, width=2):
    d.ellipse(box, fill=fill, outline=outline, width=width)

def rect(d, box, fill, outline=OUT, width=2, r=0):
    if r:
        d.rounded_rectangle(box, r, fill=fill, outline=outline, width=width)
    else:
        d.rectangle(box, fill=fill, outline=outline, width=width)

def poly(d, pts, fill, outline=OUT, width=2):
    d.polygon(pts, fill=fill, outline=outline)
    if width > 1:
        d.line(pts + [pts[0]], fill=outline, width=width)

# ---------------------------------------------------------------- characters
def troll(pose, suit, w=48, h=64):
    img = canvas(w, h); d = ImageDraw.Draw(img)
    skin = (92, 170, 70, 255); skin_dark = (60, 120, 50, 255)
    body = (40, 90, 200, 255) if suit else skin
    glow = (90, 230, 255, 255)
    oy = 0; leg_a = (14, 50, 22, 62); leg_b = (26, 50, 34, 62)
    if pose == "run":
        leg_a = (10, 48, 18, 60); leg_b = (28, 50, 36, 62)
    if pose in ("jump",):
        oy = -2; leg_a = (13, 46, 21, 56); leg_b = (27, 46, 35, 56)
    if pose == "fall":
        leg_a = (12, 50, 20, 63); leg_b = (28, 50, 36, 63)
    legc = (25, 50, 120, 255) if suit else skin_dark
    rect(d, leg_a, legc); rect(d, leg_b, legc)
    # body
    rect(d, (11, 26 + oy, 37, 52 + oy), body, r=6)
    if suit:
        d.line((24, 28 + oy, 24, 50 + oy), fill=glow, width=2)
        d.line((13, 38 + oy, 35, 38 + oy), fill=glow, width=2)
        ell(d, (20, 32 + oy, 28, 40 + oy), (255, 220, 60, 255), width=1)
    else:
        rect(d, (11, 42 + oy, 37, 52 + oy), (130, 85, 45, 255), r=3)  # shorts
    # arms
    if pose == "attack":
        rect(d, (32, 30 + oy, 46, 37 + oy), body if suit else skin, r=3)
        ell(d, (40, 28 + oy, 47, 39 + oy), skin)
    elif pose == "fall":
        rect(d, (4, 20 + oy, 11, 36 + oy), body if suit else skin, r=3)
        rect(d, (37, 20 + oy, 44, 36 + oy), body if suit else skin, r=3)
    else:
        rect(d, (6, 30 + oy, 12, 46 + oy), body if suit else skin, r=3)
        rect(d, (36, 30 + oy, 42, 46 + oy), body if suit else skin, r=3)
    # head + ears
    poly(d, [(8, 12 + oy), (0, 4 + oy), (12, 8 + oy)], skin)
    poly(d, [(40, 12 + oy), (48, 4 + oy), (36, 8 + oy)], skin)
    ell(d, (8, 2 + oy, 40, 30 + oy), skin)
    if pose == "hurt":
        d.line((27, 11, 33, 17), fill=OUT, width=2); d.line((33, 11, 27, 17), fill=OUT, width=2)
    else:
        ell(d, (25, 9 + oy, 35, 19 + oy), (255, 255, 255, 255), width=1)
        ell(d, (29, 12 + oy, 34, 17 + oy), OUT, width=1)
    d.arc((22, 16 + oy, 36, 26 + oy), 20, 160, fill=OUT, width=2)
    d.rectangle((26, 20 + oy, 28, 23 + oy), fill=(255, 255, 255, 255))  # tooth
    if pose == "hurt":
        img = Image.blend(img, Image.new("RGBA", img.size, (255, 60, 60, 0)), 0.0)
        r, g, b, a = img.split(); r = r.point(lambda v: min(255, v + 70)); img = Image.merge("RGBA", (r, g, b, a))
    return img

for pose in ["idle", "run", "jump", "fall", "attack", "hurt"]:
    save(troll(pose, True), f"characters/CT/ct_{pose}.png")
    save(troll(pose, False), f"characters/CT_naked/ct_naked_{pose}.png")

def humanoid(w, h, skin, hair, top, legs, extra=None, pose="idle"):
    img = canvas(w, h); d = ImageDraw.Draw(img)
    cx = w // 2
    la = (cx - 10, h - 20, cx - 2, h - 2); lb = (cx + 2, h - 20, cx + 10, h - 2)
    if pose == "run": la = (cx - 14, h - 20, cx - 6, h - 3); lb = (cx + 5, h - 20, cx + 13, h - 2)
    if pose in ("jump", "fall"): la = (cx - 11, h - 24, cx - 3, h - 8); lb = (cx + 3, h - 24, cx + 11, h - 8)
    rect(d, la, legs); rect(d, lb, legs)
    rect(d, (cx - 13, h - 46, cx + 13, h - 18), top, r=5)
    if pose == "attack":
        rect(d, (cx + 8, h - 42, cx + 22, h - 35), top, r=3)
        rect(d, (cx + 18, h - 50, cx + 23, h - 28), (120, 80, 40, 255))
    else:
        rect(d, (cx - 18, h - 44, cx - 12, h - 26), top, r=3)
        rect(d, (cx + 12, h - 44, cx + 18, h - 26), top, r=3)
    ell(d, (cx - 12, h - 68 if h >= 68 else 2, cx + 12, h - 44), skin)
    top_y = h - 68 if h >= 68 else 2
    d.chord((cx - 13, top_y - 2, cx + 13, top_y + 16), 180, 360, fill=hair, outline=OUT, width=2)
    ell(d, (cx + 3, top_y + 9, cx + 8, top_y + 14), OUT, width=1)
    if extra: extra(d, cx, top_y)
    if pose == "hurt":
        r, g, b, a = img.split(); r = r.point(lambda v: min(255, v + 70)); img = Image.merge("RGBA", (r, g, b, a))
    return img

for pose in ["idle", "run", "jump", "fall", "attack", "hurt", "shield"]:
    p = "idle" if pose == "shield" else pose
    save(humanoid(48, 70, (230, 190, 150, 255), (90, 55, 30, 255), (190, 40, 50, 255), (60, 50, 80, 255), pose=p), f"characters/Alex/alex_{pose}.png")

def glasses(d, cx, ty):
    d.rectangle((cx - 2, ty + 9, cx + 11, ty + 14), outline=OUT, width=2)
def crown(d, cx, ty):
    poly(d, [(cx - 10, ty), (cx - 6, ty - 8), (cx, ty - 2), (cx + 6, ty - 8), (cx + 10, ty)], (255, 210, 60, 255))
def tophat(d, cx, ty):
    rect(d, (cx - 9, ty - 14, cx + 9, ty + 2), (30, 30, 30, 255)); rect(d, (cx - 14, ty, cx + 14, ty + 3), (30, 30, 30, 255))

save(humanoid(44, 64, (240, 200, 160, 255), (235, 120, 30, 255), (240, 200, 50, 255), (40, 110, 60, 255)), "npc/felix.png")
save(humanoid(48, 70, (245, 205, 180, 255), (240, 110, 170, 255), (235, 120, 180, 255), (150, 60, 110, 255)), "npc/pink_girl.png")
save(humanoid(48, 70, (245, 205, 180, 255), (250, 130, 190, 255), (200, 90, 200, 255), (110, 50, 120, 255)), "npc/sigih.png")
save(humanoid(44, 64, (235, 195, 160, 255), (60, 40, 30, 255), (90, 130, 200, 255), (60, 60, 70, 255), glasses), "npc/lala.png")
save(humanoid(56, 84, (240, 210, 190, 255), (40, 160, 160, 255), (90, 40, 140, 255), (60, 30, 100, 255), crown), "npc/queen.png")
save(humanoid(52, 74, (225, 185, 150, 255), (120, 120, 120, 255), (120, 80, 50, 255), (70, 50, 40, 255), tophat), "npc/mayor.png")

def shield_img(w, h, col, trim):
    img = canvas(w, h); d = ImageDraw.Draw(img)
    poly(d, [(2, 2), (w - 3, 2), (w - 3, h * 0.6), (w // 2, h - 2), (2, h * 0.6)], col)
    ell(d, (w // 2 - 5, h // 2 - 9, w // 2 + 5, h // 2 + 1), trim, width=1)
    return img
save(shield_img(24, 44, (150, 170, 200, 255), (240, 200, 60, 255)), "characters/Alex/shield.png")
save(shield_img(28, 46, (240, 130, 190, 255), (255, 230, 120, 255)), "npc/pink_shield.png")

# ---------------------------------------------------------------- enemies
def skull_img(w, h, elite=False):
    img = canvas(w, h); d = ImageDraw.Draw(img)
    robe = (120, 30, 40, 255) if elite else (50, 40, 70, 255)
    poly(d, [(w // 2 - 12, h * 0.45), (w // 2 + 12, h * 0.45), (w // 2 + 16, h - 2), (w // 2 - 16, h - 2)], robe)
    ell(d, (w // 2 - 15, 4, w // 2 + 15, int(h * 0.55)), (240, 235, 220, 255))
    eye = (255, 40, 40, 255) if elite else OUT
    ell(d, (w // 2 - 2, 12, w // 2 + 8, 22), eye, width=1)
    ell(d, (w // 2 - 12, 12, w // 2 - 4, 22), eye, width=1)
    for i in range(4):
        d.line((w // 2 - 6 + i * 4, int(h * 0.42), w // 2 - 6 + i * 4, int(h * 0.5)), fill=OUT, width=1)
    if elite:
        d.chord((w // 2 - 16, 0, w // 2 + 16, 22), 180, 360, fill=(120, 120, 140, 255), outline=OUT, width=2)
        poly(d, [(w // 2 - 2, 0), (w // 2 + 2, 0), (w // 2, -8 + 8)], (200, 40, 40, 255))
        rect(d, (w // 2 + 12, int(h * 0.5), w // 2 + 18, h - 6), (170, 170, 190, 255))
    return img
save(skull_img(40, 46), "enemies/skull.png")
save(skull_img(46, 54, True), "enemies/elite_skull.png")

img = canvas(46, 62); d = ImageDraw.Draw(img)
poly(d, [(23, 2), (40, 20), (42, 60), (4, 60), (6, 20)], (70, 30, 110, 230), outline=(160, 90, 255, 255))
ell(d, (24, 16, 32, 24), (255, 80, 255, 255), outline=(255, 200, 255, 255), width=1)
ell(d, (12, 16, 20, 24), (255, 80, 255, 255), outline=(255, 200, 255, 255), width=1)
save(img, "enemies/shadow_avatar.png")

def circle_tex(size, fill, outline, width, name):
    img = canvas(size, size); d = ImageDraw.Draw(img)
    d.ellipse((2, 2, size - 3, size - 3), fill=fill, outline=outline, width=width)
    save(img, name)
circle_tex(128, (255, 60, 60, 70), (255, 80, 80, 255), 6, "enemies/warning_flash.png")
circle_tex(128, (0, 0, 0, 0), (220, 160, 255, 255), 10, "enemies/shock_ring.png")

img = canvas(58, 54); d = ImageDraw.Draw(img)
rect(d, (6, 10, 44, 52), (140, 90, 50, 255), r=8)
for y in (18, 42): d.line((7, y, 43, y), fill=(80, 60, 40, 255), width=3)
rect(d, (40, 20, 56, 30), (60, 60, 70, 255))
ell(d, (16, 20, 24, 28), (255, 255, 255, 255), width=1); ell(d, (28, 20, 36, 28), (255, 255, 255, 255), width=1)
d.point((21, 24), fill=OUT); d.point((33, 24), fill=OUT)
save(img, "enemies/barreldugo.png")

def beast(w, h, col, horn_col, big_horn):
    img = canvas(w, h); d = ImageDraw.Draw(img)
    for x in (0.18, 0.32, 0.62, 0.78):
        rect(d, (int(w * x), int(h * 0.68), int(w * x) + 9, h - 2), tuple(int(c * 0.7) for c in col[:3]) + (255,))
    ell(d, (2, int(h * 0.22), int(w * 0.8), int(h * 0.8)), col)
    ell(d, (int(w * 0.58), int(h * 0.15), w - 2, int(h * 0.62)), col)
    if big_horn:
        poly(d, [(int(w * 0.85), int(h * 0.2)), (w - 2, 0), (int(w * 0.95), int(h * 0.3))], horn_col)
    else:
        poly(d, [(int(w * 0.7), int(h * 0.2)), (int(w * 0.64), 0), (int(w * 0.78), int(h * 0.18))], horn_col)
        poly(d, [(int(w * 0.9), int(h * 0.2)), (w - 2, 0), (int(w * 0.95), int(h * 0.24))], horn_col)
    ell(d, (int(w * 0.8), int(h * 0.28), int(w * 0.88), int(h * 0.38)), (255, 60, 40, 255), width=1)
    return img
save(beast(112, 84, (120, 125, 135, 255), (240, 230, 200, 255), True), "enemies/horn.png")
save(beast(100, 72, (130, 80, 50, 255), (240, 230, 200, 255), False), "enemies/bull.png")
save(beast(66, 50, (175, 120, 75, 255), (240, 230, 200, 255), False), "enemies/minor_bull.png")
save(beast(100, 72, (90, 60, 40, 255), (255, 220, 120, 255), False), "enemies/bull_armored.png")

img = canvas(130, 156); d = ImageDraw.Draw(img)
rect(d, (34, 112, 58, 154), (60, 30, 30, 255)); rect(d, (72, 112, 96, 154), (60, 30, 30, 255))
rect(d, (22, 52, 108, 118), (150, 30, 30, 255), r=14)
rect(d, (30, 60, 100, 72), (90, 90, 100, 255))
ell(d, (40, 8, 92, 60), (200, 150, 120, 255))
d.chord((36, 2, 96, 44), 180, 360, fill=(60, 60, 70, 255), outline=OUT, width=2)
poly(d, [(38, 20), (24, 0), (46, 14)], (230, 220, 200, 255)); poly(d, [(92, 20), (106, 0), (84, 14)], (230, 220, 200, 255))
d.line((62, 34, 74, 38), fill=OUT, width=3); d.line((80, 38, 90, 34), fill=OUT, width=3)
d.arc((60, 42, 86, 54), 200, 340, fill=OUT, width=3)
rect(d, (104, 20, 114, 110), (210, 210, 225, 255)); rect(d, (98, 100, 120, 108), (120, 80, 40, 255))
save(img, "enemies/big_boss.png")

img = canvas(116, 112); d = ImageDraw.Draw(img)
ell(d, (12, 30, 92, 104), (60, 110, 200, 255))
poly(d, [(16, 56), (0, 30), (40, 50)], (40, 80, 170, 255))
ell(d, (56, 4, 104, 50), (70, 130, 220, 255))
poly(d, [(98, 24), (116, 32), (98, 38)], (250, 190, 40, 255))
ell(d, (80, 16, 92, 28), (255, 255, 255, 255), width=1); ell(d, (84, 19, 90, 25), OUT, width=1)
for x in (40, 62): d.line((x, 102, x, 111), fill=(250, 190, 40, 255), width=4)
save(img, "enemies/big_bird.png")

img = canvas(360, 520); d = ImageDraw.Draw(img)
ell(d, (10, 40, 350, 520), (200, 160, 90, 255), width=4)
ell(d, (220, 120, 270, 170), (255, 240, 120, 255), width=3); ell(d, (238, 135, 258, 160), OUT, width=1)
poly(d, [(250, 260), (350, 220), (350, 380)], (90, 30, 30, 255), width=3)
for i in range(6):
    y = 236 + i * 22
    poly(d, [(300 + i * 4, y), (318 + i * 4, y + 8), (300 + i * 4, y + 14)], (250, 250, 240, 255), width=1)
for i in range(8):
    d.arc((20, 60 + i * 50, 200, 160 + i * 50), 200, 340, fill=(160, 120, 60, 255), width=3)
save(img, "enemies/wormfish.png")

img = canvas(320, 720); d = ImageDraw.Draw(img)
for i in range(70):
    x = random.randint(0, 300); y = random.randint(0, 700)
    d.line((x, y, x + random.randint(10, 60), y + random.randint(-30, 30)), fill=(30, 50, 25, 255), width=random.randint(3, 8))
d.rectangle((0, 0, 200, 720), fill=(20, 35, 18, 230))
for i in range(30):
    y = random.randint(0, 700); d.polygon([(200, y), (240, y + 6), (200, y + 12)], fill=(60, 80, 40, 255))
hb = beast(112, 84, (40, 40, 50, 255), (90, 90, 100, 255), True)
img.alpha_composite(hb.resize((180, 135)), (120, 420))
save(img, "enemies/forest_chaser.png")

# warning "!" icon
img = canvas(28, 34); d = ImageDraw.Draw(img)
poly(d, [(14, 1), (27, 32), (1, 32)], (255, 210, 40, 255))
rect(d, (12, 10, 16, 22), OUT, width=0); rect(d, (12, 25, 16, 29), OUT, width=0)
save(img, "ui/warning.png")

img = canvas(140, 18); d = ImageDraw.Draw(img)
d.ellipse((1, 1, 138, 16), fill=(255, 50, 50, 90), outline=(255, 70, 70, 255), width=3)
save(img, "enemies/slam_marker.png")

# ---------------------------------------------------------------- objects
img = canvas(24, 24); d = ImageDraw.Draw(img)
d.ellipse((1, 1, 22, 22), fill=(255, 200, 40, 255), outline=(150, 90, 10, 255), width=2)
d.ellipse((6, 6, 17, 17), outline=(255, 240, 150, 255), width=2)
d.line((9, 5, 6, 9), fill=(255, 255, 255, 255), width=2)
save(img, "objects/coin.png"); save(img.resize((32, 32), Image.NEAREST), "ui/coin_icon.png")

img = canvas(70, 58); d = ImageDraw.Draw(img)
rect(d, (4, 22, 66, 56), (150, 90, 40, 255), r=4)
d.chord((4, 2, 66, 42), 180, 360, fill=(170, 105, 45, 255), outline=OUT, width=2)
rect(d, (30, 18, 40, 34), (255, 210, 60, 255))
for x in (14, 56): d.line((x, 8, x, 56), fill=(255, 210, 60, 255), width=3)
save(img.filter(ImageFilter.SMOOTH), "objects/chest.png")

img = canvas(52, 100); d = ImageDraw.Draw(img)
rect(d, (6, 4, 11, 98), (220, 220, 230, 255))
poly(d, [(11, 6), (50, 18), (11, 32)], (60, 220, 120, 255))
save(img, "objects/goal_flag.png")

img = canvas(60, 60); d = ImageDraw.Draw(img)
ell(d, (4, 18, 56, 58), (190, 150, 80, 255))
poly(d, [(20, 20), (14, 4), (46, 4), (40, 20)], (190, 150, 80, 255))
d.line((18, 20, 42, 20), fill=(120, 60, 30, 255), width=4)
d.text((24, 32), "$", fill=(255, 220, 60, 255))
save(img, "objects/coin_bag.png")

img = canvas(110, 70); d = ImageDraw.Draw(img)
d.rectangle((0, 50, 110, 70), fill=(80, 200, 255, 90))
for i in range(5): d.line((10 + i * 22, 5, 10 + i * 22, 50), fill=(120, 220, 255, 180), width=4)
save(img, "objects/safe_zone.png")

def rock(w, h, col):
    img = canvas(w, h); d = ImageDraw.Draw(img)
    poly(d, [(w * 0.2, 2), (w * 0.8, 4), (w - 2, h * 0.5), (w * 0.75, h - 2), (w * 0.2, h - 3), (2, h * 0.55)], col)
    d.line((w * 0.3, h * 0.3, w * 0.5, h * 0.5), fill=tuple(int(c * 0.6) for c in col[:3]) + (255,), width=2)
    return img
save(rock(48, 46, (130, 125, 120, 255)), "objects/rock.png")
save(rock(52, 44, (200, 170, 110, 255)), "objects/stone.png")
img = canvas(130, 36); d = ImageDraw.Draw(img)
rect(d, (2, 4, 128, 32), (120, 80, 45, 255), r=12); ell(d, (110, 4, 128, 32), (190, 150, 100, 255))
save(img, "objects/log.png")
img = canvas(84, 52); d = ImageDraw.Draw(img)
for i in range(9): ell(d, (random.randint(0, 50), random.randint(0, 22), random.randint(30, 34) + 50, 50), (40, 110, 50, 255), width=1)
d.rectangle((6, 40, 78, 50), fill=(90, 60, 30, 255))
save(img, "objects/hedge_trap.png")

def crate(sz):
    img = canvas(sz, sz); d = ImageDraw.Draw(img)
    rect(d, (2, 2, sz - 3, sz - 3), (170, 120, 60, 255), width=3)
    d.line((4, 4, sz - 5, sz - 5), fill=(110, 70, 30, 255), width=4); d.line((sz - 5, 4, 4, sz - 5), fill=(110, 70, 30, 255), width=4)
    return img
save(crate(56), "objects/crate.png"); save(crate(160), "environment/crate_big.png")

img = canvas(18, 18); d = ImageDraw.Draw(img); ell(d, (1, 1, 16, 16), (60, 50, 50, 255)); d.ellipse((4, 4, 8, 8), fill=(200, 200, 200, 255))
save(img, "objects/cannonball.png")
img = canvas(34, 8); d = ImageDraw.Draw(img)
d.line((2, 4, 28, 4), fill=(120, 80, 40, 255), width=3); poly(d, [(26, 0), (33, 4), (26, 7)], (200, 200, 210, 255), width=1)
d.line((2, 1, 6, 4), fill=(240, 240, 240, 255), width=2); d.line((2, 7, 6, 4), fill=(240, 240, 240, 255), width=2)
save(img, "objects/arrow.png")
img = canvas(42, 42); d = ImageDraw.Draw(img)
poly(d, [(4, 6), (21, 20), (38, 6), (38, 14), (21, 36), (4, 14)], (230, 180, 60, 255))
save(img, "objects/boomerang.png")
img = canvas(46, 96); d = ImageDraw.Draw(img)
d.chord((-40, 2, 44, 94), 270, 90, fill=(255, 90, 60, 200), outline=(255, 220, 160, 255), width=3)
save(img, "objects/sword_wave.png")
img = canvas(64, 30); d = ImageDraw.Draw(img)
d.ellipse((2, 4, 62, 30), fill=(255, 160, 50, 210), outline=(255, 230, 150, 255), width=3)
save(img, "objects/shockwave.png")
img = canvas(48, 56); d = ImageDraw.Draw(img)
d.arc((0, 2, 44, 54), 300, 60, fill=(255, 255, 220, 230), width=6)
save(img, "objects/swoosh.png")
img = canvas(64, 64); d = ImageDraw.Draw(img)
for x in (8, 32, 56): rect(d, (x - 4, 6, x + 4, 62), (140, 100, 60, 255))
rect(d, (0, 18, 63, 26), (160, 115, 70, 255)); rect(d, (0, 40, 63, 48), (160, 115, 70, 255))
save(img, "objects/fence.png")

# ---------------------------------------------------------------- environment tiles
def ground(top, mid, deep, name, top_h=16, speck=None):
    img = Image.new("RGBA", (64, 512), mid); d = ImageDraw.Draw(img)
    for y in range(512):
        t = min(1.0, y / 300)
        c = tuple(int(mid[i] * (1 - t) + deep[i] * t) for i in range(3)) + (255,)
        d.line((0, y, 63, y), fill=c)
    for _ in range(90):
        x = random.randint(0, 60); y = random.randint(top_h + 2, 505)
        c = speck or tuple(max(0, v - 25) for v in mid[:3]) + (255,)
        d.rectangle((x, y, x + random.randint(2, 5), y + random.randint(1, 3)), fill=c)
    d.rectangle((0, 0, 63, top_h), fill=top)
    for x in range(0, 64, 8):
        d.polygon([(x, top_h), (x + 4, top_h + 5), (x + 8, top_h)], fill=top)
    d.line((0, 0, 63, 0), fill=tuple(min(255, v + 40) for v in top[:3]) + (255,), width=2)
    save(img, "environment/" + name)
ground((80, 160, 60, 255), (95, 75, 55, 255), (45, 35, 30, 255), "ground_castle.png")
ground((120, 120, 135, 255), (85, 85, 100, 255), (40, 40, 50, 255), "ground_arena.png")
ground((100, 150, 70, 255), (110, 95, 80, 255), (55, 45, 40, 255), "ground_cliff.png")
ground((60, 140, 60, 255), (80, 60, 40, 255), (35, 28, 20, 255), "ground_forest.png")
ground((180, 130, 80, 255), (150, 100, 60, 255), (90, 60, 35, 255), "ground_deck.png", top_h=10, speck=(110, 70, 40, 255))
ground((235, 205, 140, 255), (215, 180, 115, 255), (170, 130, 80, 255), "ground_sand.png", top_h=10)
# deck planks overlay
img = Image.open(os.path.join(ROOT, "environment/ground_deck.png")); d = ImageDraw.Draw(img)
for y in range(12, 512, 22): d.line((0, y, 63, y), fill=(110, 70, 40, 255), width=2)
d.line((63, 0, 63, 511), fill=(110, 70, 40, 255), width=2)
img.save(os.path.join(ROOT, "environment/ground_deck.png"))

def ledge(top, body, name):
    img = Image.new("RGBA", (64, 32), body); d = ImageDraw.Draw(img)
    d.rectangle((0, 0, 63, 8), fill=top); d.line((0, 31, 63, 31), fill=OUT, width=2)
    for _ in range(10):
        x = random.randint(0, 60); y = random.randint(10, 28)
        d.rectangle((x, y, x + 3, y + 2), fill=tuple(max(0, v - 30) for v in body[:3]) + (255,))
    save(img, "environment/" + name)
ledge((90, 170, 70, 255), (100, 80, 60, 255), "ledge_moss.png")
ledge((190, 140, 90, 255), (140, 95, 55, 255), "ledge_wood.png")
ledge((150, 150, 165, 255), (100, 100, 115, 255), "ledge_stone.png")
ledge((200, 175, 130, 255), (150, 120, 85, 255), "ledge_rubble.png")

img = Image.new("RGBA", (64, 64), (95, 95, 110, 255)); d = ImageDraw.Draw(img)
for y in (0, 32):
    d.line((0, y, 63, y), fill=(60, 60, 72, 255), width=2)
for x, y in ((0, 0), (32, 0), (16, 32), (48, 32)):
    d.line((x, y, x, y + 32), fill=(60, 60, 72, 255), width=2)
save(img, "environment/wall_stone.png")

img = Image.new("RGBA", (64, 64), (100, 70, 45, 255)); d = ImageDraw.Draw(img)
for x in range(4, 64, 12): d.line((x, 0, x + random.randint(-3, 3), 63), fill=(70, 48, 30, 255), width=3)
save(img, "environment/trunk.png")

img = Image.new("RGBA", (64, 64), (190, 160, 100, 255)); d = ImageDraw.Draw(img)
for i in range(6): d.arc((random.randint(-10, 40), random.randint(-10, 40), random.randint(40, 80), random.randint(40, 80)), 0, 360, fill=(150, 120, 70, 255), width=2)
save(img, "environment/quicksand.png")

img = Image.new("RGBA", (96, 96), (40, 105, 45, 255)); d = ImageDraw.Draw(img)
for _ in range(60):
    x = random.randint(0, 90); y = random.randint(0, 90)
    d.ellipse((x, y, x + random.randint(6, 14), y + random.randint(6, 14)), fill=(random.randint(30, 70), random.randint(110, 150), random.randint(40, 60), 255))
d.rectangle((0, 0, 95, 95), outline=(25, 70, 30, 255), width=2)
save(img, "environment/hedge.png")
img = Image.new("RGBA", (64, 64), (70, 120, 60, 255)); d = ImageDraw.Draw(img)
for _ in range(40):
    x = random.randint(0, 62); y = random.randint(0, 62)
    d.line((x, y, x + 1, y - 3), fill=(90, 150, 70, 255), width=1)
save(img, "environment/grass_topdown.png")

def ruins():
    img = canvas(180, 130); d = ImageDraw.Draw(img)
    rect(d, (10, 40, 60, 128), (190, 160, 110, 255)); rect(d, (80, 70, 170, 128), (180, 150, 100, 255))
    poly(d, [(10, 40), (30, 20), (60, 40)], (170, 140, 95, 255))
    rect(d, (100, 90, 120, 128), (60, 40, 30, 255), width=1)
    return img
save(ruins(), "environment/ruins.png")
img = canvas(110, 130); d = ImageDraw.Draw(img)
rect(d, (10, 10, 100, 128), (130, 60, 160, 255), r=10); rect(d, (22, 60, 88, 100), (220, 180, 60, 255))
save(img, "environment/throne.png")
img = canvas(512, 90); d = ImageDraw.Draw(img)
for i in range(22):
    x = i * 24 + random.randint(-4, 4); hgt = random.randint(50, 80)
    col = (random.randint(40, 80), random.randint(40, 70), random.randint(70, 110), 255)
    d.ellipse((x, 90 - hgt, x + 22, 90 - hgt + 22), fill=col)
    d.rectangle((x + 2, 90 - hgt + 16, x + 20, 90), fill=col)
save(img, "environment/crowd.png")
img = canvas(140, 220); d = ImageDraw.Draw(img)
rect(d, (55, 90, 85, 220), (80, 55, 35, 255))
ell(d, (5, 0, 135, 130), (40, 110, 50, 255))
save(img, "environment/tree.png")

# ---------------------------------------------------------------- backgrounds
def gradient(top, bottom, w=1280, h=720):
    img = Image.new("RGBA", (w, h)); d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / (h - 1)
        d.line((0, y, w, y), fill=tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3)) + (255,))
    return img, d

img, d = gradient((15, 18, 45), (45, 40, 80))
for _ in range(120):
    x = random.randint(0, 1279); y = random.randint(0, 420); d.point((x, y), fill=(255, 255, 230, 255))
d.ellipse((1020, 60, 1100, 140), fill=(250, 245, 210, 255))
for x0 in (100, 520, 900):
    d.rectangle((x0, 300, x0 + 220, 720), fill=(25, 22, 45, 255))
    for i in range(5): d.rectangle((x0 + i * 46, 280, x0 + i * 46 + 26, 300), fill=(25, 22, 45, 255))
d.rectangle((640, 160, 700, 720), fill=(30, 26, 52, 255))
save(img, "backgrounds/bg_castle_night.png")

img, d = gradient((30, 20, 50), (70, 40, 70))
for _ in range(80):
    d.point((random.randint(0, 1279), random.randint(0, 400)), fill=(255, 255, 255, 255))
d.ellipse((-200, 480, 1480, 1100), fill=(40, 30, 50, 255))
for x in range(0, 1280, 160): d.rectangle((x + 40, 380, x + 70, 520), fill=(55, 40, 65, 255))
save(img, "backgrounds/bg_arena_night.png")

img, d = gradient((250, 150, 90), (120, 60, 90))
d.ellipse((540, 380, 740, 580), fill=(255, 220, 120, 255))
d.polygon([(0, 720), (0, 450), (300, 380), (600, 470), (900, 360), (1280, 440), (1280, 720)], fill=(70, 40, 60, 255))
save(img, "backgrounds/bg_cliff_dusk.png")

img, d = gradient((140, 200, 160), (40, 90, 60))
for i in range(14):
    x = i * 95 + random.randint(-20, 20); w = random.randint(40, 70)
    d.rectangle((x, 0, x + w, 720), fill=(50 + random.randint(0, 20), 80, 50, 255))
for i in range(30):
    x = random.randint(0, 1280); d.ellipse((x - 90, -60, x + 90, 160), fill=(40, 100 + random.randint(0, 30), 50, 255))
save(img, "backgrounds/bg_forest.png")

img, d = gradient((90, 160, 240), (190, 225, 255))
for _ in range(9):
    x = random.randint(0, 1200); y = random.randint(40, 420)
    for k in range(4): d.ellipse((x + k * 40, y - random.randint(0, 20), x + k * 40 + 90, y + 50), fill=(255, 255, 255, 230))
d.rectangle((0, 520, 1280, 720), fill=(150, 200, 240, 255))
save(img, "backgrounds/bg_ship_sky.png")

img, d = gradient((250, 200, 120), (240, 170, 90))
d.ellipse((980, 70, 1100, 190), fill=(255, 245, 200, 255))
d.polygon([(0, 720), (0, 500), (250, 430), (520, 520), (800, 440), (1100, 510), (1280, 470), (1280, 720)], fill=(220, 160, 90, 255))
for x0 in (150, 700, 1000): d.rectangle((x0, 420, x0 + 90, 520), fill=(190, 140, 90, 255))
save(img, "backgrounds/bg_desert.png")

# ---------------------------------------------------------------- UI
def heart(fill):
    img = canvas(28, 26); d = ImageDraw.Draw(img)
    d.ellipse((1, 1, 14, 14), fill=fill, outline=OUT, width=2); d.ellipse((13, 1, 26, 14), fill=fill, outline=OUT, width=2)
    d.polygon([(2, 9), (26, 9), (14, 24)], fill=fill)
    d.line((2, 10, 14, 24), fill=OUT, width=2); d.line((26, 10, 14, 24), fill=OUT, width=2)
    return img
save(heart((230, 50, 60, 255)), "ui/heart_full.png")
save(heart((70, 60, 70, 255)), "ui/heart_empty.png")
img = canvas(32, 32); d = ImageDraw.Draw(img)
d.rounded_rectangle((1, 1, 30, 30), 6, fill=(30, 25, 50, 220), outline=(255, 255, 255, 255), width=2)
d.rectangle((10, 8, 13, 23), fill=(255, 255, 255, 255)); d.rectangle((18, 8, 21, 23), fill=(255, 255, 255, 255))
save(img, "ui/pause_icon.png")
print("assets done")
