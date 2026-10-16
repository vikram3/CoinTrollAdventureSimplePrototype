"""Generates the reusable scenes (player, enemies, objects, UI) for the project."""
import os
from tscn import *

ROOT = os.path.join(os.path.dirname(__file__), "..")
def P(rel): return os.path.join(ROOT, rel)

L_WORLD, L_PLAYER, L_ENEMY, L_HAZARD, L_PICKUP, L_PATTACK, L_ALLY = 1, 2, 4, 8, 16, 32, 64
THEME = "res://scenes/ui/ui_theme.tres"

# ------------------------------------------------------------------ theme
def write_theme():
    def box(bg, border, radius=10, bw=3, margin=14):
        return [("bg_color", bg), ("border_width_left", bw), ("border_width_top", bw),
                ("border_width_right", bw), ("border_width_bottom", bw), ("border_color", border),
                ("corner_radius_top_left", radius), ("corner_radius_top_right", radius),
                ("corner_radius_bottom_right", radius), ("corner_radius_bottom_left", radius),
                ("content_margin_left", float(margin)), ("content_margin_top", float(margin * 0.6)),
                ("content_margin_right", float(margin)), ("content_margin_bottom", float(margin * 0.6))]
    styles = {
        "btn_normal": box(C(0.16, 0.12, 0.3), C(1, 0.8, 0.25)),
        "btn_hover": box(C(0.28, 0.2, 0.48), C(1, 0.9, 0.45)),
        "btn_pressed": box(C(0.4, 0.28, 0.1), C(1, 0.95, 0.6)),
        "btn_focus": box(C(0, 0, 0, 0), C(1, 1, 1), bw=3),
        "btn_disabled": box(C(0.12, 0.1, 0.16, 0.8), C(0.4, 0.38, 0.45)),
        "panel": box(C(0.08, 0.06, 0.16, 0.94), C(1, 0.78, 0.25), radius=16, bw=4, margin=20),
    }
    lines = [f"[gd_resource type=\"Theme\" load_steps={len(styles) + 1} format=3]", ""]
    for name, props in styles.items():
        lines.append(f'[sub_resource type="StyleBoxFlat" id="{name}"]')
        for k, v in props:
            lines.append(f"{k} = {val(v)}")
        lines.append("")
    lines += ["[resource]", "default_font_size = 22",
              'Button/colors/font_color = Color(1, 0.96, 0.85, 1)',
              'Button/colors/font_disabled_color = Color(0.5, 0.48, 0.55, 1)',
              'Button/styles/normal = SubResource("btn_normal")',
              'Button/styles/hover = SubResource("btn_hover")',
              'Button/styles/pressed = SubResource("btn_pressed")',
              'Button/styles/focus = SubResource("btn_focus")',
              'Button/styles/disabled = SubResource("btn_disabled")',
              'Label/colors/font_outline_color = Color(0.05, 0.03, 0.1, 1)',
              'Label/constants/outline_size = 6',
              'PanelContainer/styles/panel = SubResource("panel")', ""]
    with open(P("scenes/ui/ui_theme.tres"), "w") as f:
        f.write("\n".join(lines))

# ------------------------------------------------------------------ helpers
def rect_shape(s, w, h):
    return s.sub("RectangleShape2D", {"size": V(w, h)})

def capsule(s, r, h):
    return s.sub("CapsuleShape2D", {"radius": float(r), "height": float(h)})

def circle(s, r):
    return s.sub("CircleShape2D", {"radius": float(r)})

def full_rect(extra=None, mode=3):
    d = {"layout_mode": mode, "anchors_preset": 15, "anchor_right": 1.0, "anchor_bottom": 1.0,
         "grow_horizontal": 2, "grow_vertical": 2}
    d.update(extra or {})
    return d

def label_props(text, size=22, align=1, extra=None, mode=2):
    d = {"layout_mode": mode, "text": text, "horizontal_alignment": align,
         "theme_override_font_sizes/font_size": size}
    d.update(extra or {})
    return d

# ------------------------------------------------------------------ environment
def write_block():
    s = Scene("Block", "StaticBody2D", "res://scripts/environment/block.gd",
              {"collision_layer": L_WORLD, "collision_mask": 0})
    s.node("Sprite2D", "Sprite2D", props={"texture_repeat": 2, "texture": s.res("res://assets/environment/ground_arena.png"),
                                          "region_enabled": True, "region_rect": RECT(0, 0, 256, 64)})
    s.node("CollisionShape2D", "CollisionShape2D", props={"shape": rect_shape(s, 256, 64)})
    s.write(P("scenes/environment/block.tscn"))

def write_background():
    s = Scene("Background", "CanvasLayer", "res://scripts/environment/background.gd", {"layer": -10})
    s.node("Rect", "TextureRect", props={"offset_right": 3840.0, "offset_bottom": 720.0, "mouse_filter": 2,
                                         "texture": s.res("res://assets/backgrounds/bg_arena_night.png"),
                                         "stretch_mode": 1})
    s.write(P("scenes/environment/background.tscn"))

# ------------------------------------------------------------------ players
CT_ANIMS = ["idle", "run", "jump", "fall", "attack", "hurt"]

def player_scene(path, script, frames_dir, prefix, extra_anims=(), alex=False, topdown=False, props=None):
    s = Scene("Player", "CharacterBody2D", script,
              dict({"collision_layer": L_PLAYER, "collision_mask": L_WORLD}, **(props or {})))
    anims = [(a, [f"res://assets/characters/{frames_dir}/{prefix}_{a}.png"], True) for a in list(CT_ANIMS) + list(extra_anims)]
    sf = sprite_frames(s, anims)
    s.node("Sprite", "AnimatedSprite2D", props={"position": V(0, -4), "sprite_frames": sf,
                                                "animation": R('&"idle"'), "autoplay": "idle"})
    if topdown:
        s.node("CollisionShape2D", "CollisionShape2D", props={"position": V(0, 14), "shape": circle(s, 16)})
    else:
        s.node("CollisionShape2D", "CollisionShape2D", props={"shape": capsule(s, 15, 56)})
    if not topdown:
        s.node("AttackArea", "Area2D", props={"position": V(40 if alex else 36, -4), "collision_layer": L_PATTACK,
                                              "collision_mask": L_ENEMY, "monitorable": False})
        s.node("CollisionShape2D", "CollisionShape2D", "AttackArea", {"shape": rect_shape(s, 60 if alex else 54, 50)})
        s.node("Swoosh", "Sprite2D", "AttackArea", {"texture": s.res("res://assets/objects/swoosh.png"), "modulate": C(1, 1, 1, 0.85)})
    if alex:
        s.node("Shield", "Sprite2D", props={"position": V(18, -6), "z_index": 1,
                                            "texture": s.res("res://assets/characters/Alex/shield.png")})
    s.node("Camera2D", "Camera2D", props={"script": s.res("res://scripts/core/camera_shake.gd"),
                                          "position_smoothing_enabled": True, "position_smoothing_speed": 7.0})
    s.write(P(path))

def write_players():
    player_scene("scenes/player/player_ct.tscn", "res://scripts/player/player_ct.gd", "CT", "ct")
    player_scene("scenes/player/player_ct_naked.tscn", "res://scripts/player/player_ct.gd", "CT_naked", "ct_naked")
    player_scene("scenes/player/player_ct_naked_topdown.tscn", "res://scripts/player/player_ct_topdown.gd", "CT_naked",
                 "ct_naked", topdown=True)
    player_scene("scenes/player/player_alex.tscn", "res://scripts/player/player_alex.gd", "Alex", "alex",
                 extra_anims=["shield"], alex=True, props={"max_health": 6, "arrow_scene": Res("res://scenes/objects/arrow.tscn")})

# ------------------------------------------------------------------ enemies
def enemy_scene(path, script, tex, body_size, props=None, hurt_pad=6, extra=None, sprite_offset=(0, 0), shape="rect"):
    s = Scene(os.path.splitext(os.path.basename(path))[0].title().replace("_", ""), "CharacterBody2D", script,
              dict({"collision_layer": L_ENEMY, "collision_mask": L_WORLD}, **(props or {})))
    s.node("Sprite", "Sprite2D", props={"position": V(*sprite_offset), "texture": s.res(tex)})
    w, h = body_size
    if shape == "circle":
        s.node("CollisionShape2D", "CollisionShape2D", props={"shape": circle(s, w / 2)})
        s.node("Hurtbox", "Area2D", props={"collision_layer": 0, "collision_mask": L_PLAYER, "monitorable": False})
        s.node("CollisionShape2D", "CollisionShape2D", "Hurtbox", {"shape": circle(s, w / 2 + hurt_pad)})
    else:
        s.node("CollisionShape2D", "CollisionShape2D", props={"shape": rect_shape(s, w, h)})
        s.node("Hurtbox", "Area2D", props={"collision_layer": 0, "collision_mask": L_PLAYER, "monitorable": False})
        s.node("CollisionShape2D", "CollisionShape2D", "Hurtbox", {"shape": rect_shape(s, w + hurt_pad, h + hurt_pad)})
    if extra:
        extra(s)
    s.write(P(path))

def warning_icon(y):
    def f(s):
        s.node("Warning", "Sprite2D", props={"position": V(0, y), "z_index": 5, "texture": s.res("res://assets/ui/warning.png")})
    return f

def write_enemies():
    enemy_scene("scenes/enemies/skull.tscn", "res://scripts/enemies/skull.gd", "res://assets/enemies/skull.png", (30, 42),
                {"max_health": 1, "enemy_type": "skull", "bubble_height": 50.0})
    enemy_scene("scenes/enemies/skull_topdown.tscn", "res://scripts/enemies/skull_topdown.gd", "res://assets/enemies/skull.png",
                (30, 30), {"max_health": 1, "enemy_type": "skull", "use_gravity": False, "bubble_height": 50.0,
                           "contact_knockback": V(240, 0)}, shape="circle")
    enemy_scene("scenes/enemies/elite_skull.tscn", "res://scripts/enemies/elite_skull.gd", "res://assets/enemies/elite_skull.png",
                (34, 50), {"max_health": 2, "enemy_type": "speed", "bubble_height": 56.0})
    def barrel_extra(s):
        s.node("Muzzle", "Marker2D", props={"position": V(30, -4)})
    enemy_scene("scenes/enemies/barreldugo.tscn", "res://scripts/enemies/barreldugo.gd", "res://assets/enemies/barreldugo.png",
                (44, 44), {"max_health": 3, "enemy_type": "projectile", "bubble_height": 52.0,
                           "projectile_scene": Res("res://scenes/objects/projectile.tscn")}, extra=barrel_extra)
    enemy_scene("scenes/enemies/horn.tscn", "res://scripts/enemies/charger.gd", "res://assets/enemies/horn.png", (96, 70),
                {"invulnerable": True, "enemy_type": "horn", "contact_knockback": V(620, -380), "charge_speed": 560.0,
                 "windup_time": 0.7, "rest_time": 1.4, "counts_for_objective": False, "bubble_height": 60.0,
                 "lines_charge": PSA(["HRRRNN!", "SNORT!", "*stomp stomp*"])},
                extra=warning_icon(-62))
    enemy_scene("scenes/enemies/bull.tscn", "res://scripts/enemies/charger.gd", "res://assets/enemies/bull.png", (86, 60),
                {"max_health": 6, "enemy_type": "tank", "contact_knockback": V(460, -320), "charge_speed": 420.0,
                 "windup_time": 0.8, "rest_time": 1.6, "bubble_height": 56.0, "lines_charge": PSA(["MOOO!", "Snort!"])},
                extra=warning_icon(-56))
    enemy_scene("scenes/enemies/bull_armored.tscn", "res://scripts/enemies/charger.gd", "res://assets/enemies/bull_armored.png", (86, 60),
                {"invulnerable": True, "enemy_type": "bull", "counts_for_objective": False, "contact_knockback": V(520, -340),
                 "charge_speed": 600.0, "windup_time": 0.7, "rest_time": 1.6, "bubble_height": 56.0,
                 "lines_charge": PSA(["MOOOOO!", "*metal clank*"])},
                extra=warning_icon(-56))
    enemy_scene("scenes/enemies/minor_bull.tscn", "res://scripts/enemies/charger.gd", "res://assets/enemies/minor_bull.png", (56, 40),
                {"max_health": 2, "enemy_type": "minor_bull", "contact_knockback": V(320, -260), "charge_speed": 380.0,
                 "windup_time": 0.6, "rest_time": 1.8, "bubble_height": 44.0, "lines_charge": PSA(["Moo!"])},
                extra=warning_icon(-44))

    def boss_extra(s):
        s.node("Warning", "Sprite2D", props={"position": V(0, -100), "z_index": 5, "scale": V(1.5, 1.5),
                                             "texture": s.res("res://assets/ui/warning.png")})
        s.node("SlamMarker", "Sprite2D", props={"z_index": -1, "texture": s.res("res://assets/enemies/slam_marker.png")})
    enemy_scene("scenes/enemies/big_boss.tscn", "res://scripts/enemies/big_boss.gd", "res://assets/enemies/big_boss.png", (80, 140),
                {"max_health": 40, "invulnerable": True, "enemy_type": "boss", "counts_for_objective": False,
                 "contact_knockback": V(380, -320), "bubble_height": 96.0, "feet_offset": 70.0,
                 "sword_wave_scene": Res("res://scenes/objects/sword_wave.tscn"), "shockwave_scene": Res("res://scenes/objects/shockwave.tscn"),
                 "lines_idle": PSA(["You think you can steal from ME?", "Hold still.", "I'll crush you like a coin."]),
                 "lines_combat": PSA(["YOU ARE DONE!", "I have been putting up with you for way too long!", "HRAAH!", "Take this!"]),
                 "lines_defeat": PSA(["This... isn't over!"])},
                extra=boss_extra, sprite_offset=(0, -4))
    enemy_scene("scenes/enemies/big_bird.tscn", "res://scripts/enemies/big_bird.gd", "res://assets/enemies/big_bird.png", (80, 96),
                {"max_health": 12, "enemy_type": "boss", "contact_damage": 1, "bubble_height": 74.0, "boomerang_scene": Res("res://scenes/objects/boomerang.tscn"),
                 "lines_combat": PSA(["Ow! Hey!", "Lucky hit!", "Squawk!"]),
                 "lines_defeat": PSA(["Impossible... I yield!"])})

    def shadow_extra(s):
        s.node("WarningFlash", "Sprite2D", props={"z_index": -1, "texture": s.res("res://assets/enemies/warning_flash.png")})
        s.node("Ring", "Sprite2D", props={"z_index": 2, "texture": s.res("res://assets/enemies/shock_ring.png")})
    enemy_scene("scenes/enemies/shadow_avatar.tscn", "res://scripts/enemies/shadow_avatar.gd", "res://assets/enemies/shadow_avatar.png",
                (34, 54), {"max_health": 1, "enemy_type": "shadow", "use_gravity": False, "bubble_height": 50.0,
                           "lines_defeat": PSA(["*lag spike*", "Disconnected..."])}, extra=shadow_extra)

def patch_scene_prop(path, prop, res_path, res_type="PackedScene"):
    """Assign a PackedScene export on the root node (scenes reference each other)."""
    import re
    fp = P(path); txt = open(fp).read()
    rid = prop + "_r"
    txt = txt.replace("\n\n[", f'\n[ext_resource type="{res_type}" path="{res_path}" id="{rid}"]\n\n[', 1) \
        if "[ext_resource" in txt else txt
    txt = txt.replace(f"{prop} = null", f'{prop} = ExtResource("{rid}")')
    txt = re.sub(r"load_steps=(\d+)", lambda m: f"load_steps={int(m.group(1)) + 1}", txt, count=1)
    open(fp, "w").write(txt)

# ------------------------------------------------------------------ objects
def area_scene(path, name, script, tex, shape_fn, props=None, extra=None, sprite_props=None):
    s = Scene(name, "Area2D", script, props or {})
    sp = {"texture": s.res(tex)}; sp.update(sprite_props or {})
    s.node("Sprite", "Sprite2D", props=sp)
    s.node("CollisionShape2D", "CollisionShape2D", props={"shape": shape_fn(s)})
    if extra: extra(s)
    s.write(P(path))

def write_objects():
    area_scene("scenes/objects/coin.tscn", "Coin", "res://scripts/objects/coin.gd", "res://assets/objects/coin.png",
               lambda s: circle(s, 13), {"collision_layer": L_PICKUP, "collision_mask": L_PLAYER})
    def goal_extra(s):
        s.node("Label", "Label", props={"offset_left": -60.0, "offset_top": -92.0, "offset_right": 60.0, "offset_bottom": -64.0,
                                        "text": "EXIT", "horizontal_alignment": 1,
                                        "theme_override_font_sizes/font_size": 18,
                                        "theme_override_constants/outline_size": 6,
                                        "theme_override_colors/font_outline_color": C(0, 0, 0)})
    area_scene("scenes/objects/goal.tscn", "Goal", "res://scripts/objects/goal.gd", "res://assets/objects/goal_flag.png",
               lambda s: rect_shape(s, 70, 110), {"collision_layer": 0, "collision_mask": L_PLAYER}, goal_extra,
               {"position": V(0, -10)})
    for name, tex, speed, life, dmg, src in [
        ("projectile", "res://assets/objects/cannonball.png", 300.0, 4.0, 1, "barreldugo"),
        ("deck_shot", "res://assets/objects/cannonball.png", 220.0, 14.0, 1, "deck_hazard"),
    ]:
        area_scene(f"scenes/objects/{name}.tscn", name.title().replace("_", ""), "res://scripts/objects/projectile.gd", tex,
                   lambda s: circle(s, 8), {"speed": speed, "lifetime": life, "damage": dmg, "source_name": src,
                                            "rotate_to_direction": False})
    area_scene("scenes/objects/arrow.tscn", "Arrow", "res://scripts/objects/projectile.gd", "res://assets/objects/arrow.png",
               lambda s: rect_shape(s, 30, 8), {"speed": 620.0, "lifetime": 1.6, "damage": 1, "hostile": False,
                                                "source_name": "arrow", "reflectable": False})
    area_scene("scenes/objects/boomerang.tscn", "Boomerang", "res://scripts/enemies/boomerang.gd", "res://assets/objects/boomerang.png",
               lambda s: circle(s, 16), {})
    area_scene("scenes/objects/sword_wave.tscn", "SwordWave", "res://scripts/enemies/boss_wave.gd", "res://assets/objects/sword_wave.png",
               lambda s: rect_shape(s, 36, 90), {"speed": 620.0, "lifetime": 1.8, "damage": 1, "knockback": V(320, -320)})
    area_scene("scenes/objects/shockwave.tscn", "Shockwave", "res://scripts/enemies/boss_wave.gd", "res://assets/objects/shockwave.png",
               lambda s: rect_shape(s, 56, 26), {"speed": 520.0, "lifetime": 0.95, "damage": 1, "knockback": V(260, -380)})

    # falling hazard
    s = Scene("FallingHazard", "Node2D", "res://scripts/objects/falling_hazard.gd")
    s.node("Warning", "Sprite2D", props={"position": V(0, -46), "z_index": 5, "texture": s.res("res://assets/ui/warning.png")})
    s.node("Body", "Area2D", props={"collision_layer": L_HAZARD, "collision_mask": L_WORLD | L_PLAYER, "monitorable": False})
    s.node("Sprite", "Sprite2D", "Body", {"texture": s.res("res://assets/objects/rock.png")})
    s.node("CollisionShape2D", "CollisionShape2D", "Body", {"shape": circle(s, 20)})
    s.node("Trigger", "Area2D", props={"collision_layer": 0, "collision_mask": L_PLAYER, "monitorable": False})
    s.node("CollisionShape2D", "CollisionShape2D", "Trigger")
    s.write(P("scenes/objects/falling_hazard.tscn"))

    # sliding crate
    s = Scene("SlidingCrate", "CharacterBody2D", "res://scripts/objects/sliding_crate.gd",
              {"collision_layer": L_HAZARD, "collision_mask": L_WORLD})
    s.node("Sprite", "Sprite2D", props={"texture": s.res("res://assets/objects/crate.png")})
    s.node("CollisionShape2D", "CollisionShape2D", props={"shape": rect_shape(s, 52, 52)})
    s.node("Hurtbox", "Area2D", props={"collision_layer": 0, "collision_mask": L_PLAYER, "monitorable": False})
    s.node("CollisionShape2D", "CollisionShape2D", "Hurtbox", {"shape": rect_shape(s, 50, 50)})
    s.write(P("scenes/objects/sliding_crate.tscn"))

    # chaser
    s = Scene("Chaser", "Area2D", "res://scripts/objects/chaser.gd", {"collision_layer": L_HAZARD, "collision_mask": L_PLAYER})
    s.node("Sprite", "Sprite2D", props={"position": V(-10, -80), "texture": s.res("res://assets/enemies/forest_chaser.png")})
    s.node("CollisionShape2D", "CollisionShape2D", props={"position": V(0, -200), "shape": rect_shape(s, 300, 2000)})
    s.write(P("scenes/objects/chaser.tscn"))

    # restart zone
    s = Scene("RestartZone", "Area2D", "res://scripts/objects/restart_zone.gd", {"collision_layer": 0, "collision_mask": L_PLAYER})
    s.node("CollisionShape2D", "CollisionShape2D", props={"shape": rect_shape(s, 400, 200)})
    s.write(P("scenes/objects/restart_zone.tscn"))

    # spawners / emitters
    Scene("WaveSpawner", "Node2D", "res://scripts/objects/wave_spawner.gd").write(P("scenes/objects/wave_spawner.tscn"))
    Scene("ShadowSpawner", "Node2D", "res://scripts/objects/shadow_spawner.gd").write(P("scenes/objects/shadow_spawner.tscn"))
    s = Scene("HazardEmitter", "Node2D", "res://scripts/objects/hazard_emitter.gd",
              {"projectile_scene": Res("res://scenes/objects/deck_shot.tscn")})
    s.write(P("scenes/objects/hazard_emitter.tscn"))

def write_npcs():
    s = Scene("Felix", "CharacterBody2D", "res://scripts/npc/felix.gd", {"collision_layer": L_ALLY, "collision_mask": L_WORLD})
    s.node("Sprite", "Sprite2D", props={"position": V(0, -2), "texture": s.res("res://assets/npc/felix.png")})
    s.node("CollisionShape2D", "CollisionShape2D", props={"shape": capsule(s, 14, 56)})
    s.write(P("scenes/npc/felix.tscn"))
    s = Scene("PinkGirl", "CharacterBody2D", "res://scripts/npc/pink_girl.gd", {"collision_layer": L_ALLY, "collision_mask": L_WORLD})
    s.node("Sprite", "Sprite2D", props={"position": V(0, -2), "texture": s.res("res://assets/npc/pink_girl.png")})
    s.node("Shield", "Sprite2D", props={"position": V(22, -4), "z_index": 1, "texture": s.res("res://assets/npc/pink_shield.png")})
    s.node("CollisionShape2D", "CollisionShape2D", props={"shape": capsule(s, 15, 62)})
    s.write(P("scenes/npc/pink_girl.tscn"))
    s = Scene("Commenter", "Node2D", "res://scripts/npc/commenter.gd")
    s.node("Sprite", "Sprite2D", props={"texture": s.res("res://assets/npc/lala.png")})
    s.write(P("scenes/npc/commenter.tscn"))

# ------------------------------------------------------------------ UI
def write_speech_bubble():
    s = Scene("SpeechBubble", "Node2D", "res://scripts/ui/speech_bubble.gd", {"z_index": 50})
    style = s.sub("StyleBoxFlat", [("bg_color", C(1, 1, 1, 0.96)), ("border_width_left", 2), ("border_width_top", 2),
                                   ("border_width_right", 2), ("border_width_bottom", 2), ("border_color", C(0.1, 0.08, 0.15)),
                                   ("corner_radius_top_left", 12), ("corner_radius_top_right", 12),
                                   ("corner_radius_bottom_right", 12), ("corner_radius_bottom_left", 12),
                                   ("content_margin_left", 10.0), ("content_margin_top", 6.0),
                                   ("content_margin_right", 10.0), ("content_margin_bottom", 6.0)])
    s.node("Tail", "Polygon2D", props={"color": C(1, 1, 1, 0.96), "polygon": PV2([(-8, -12), (8, -12), (0, 0)])})
    s.node("Panel", "PanelContainer", props={"offset_left": -40.0, "offset_top": -40.0, "offset_right": 40.0, "offset_bottom": -10.0,
                                             "mouse_filter": 2, "theme_override_styles/panel": style})
    s.node("Label", "Label", "Panel", {"layout_mode": 2, "mouse_filter": 2, "text": "...", "horizontal_alignment": 1,
                                       "theme_override_colors/font_color": C(0.1, 0.08, 0.15),
                                       "theme_override_constants/outline_size": 0,
                                       "theme_override_font_sizes/font_size": 15})
    s.write(P("scenes/ui/speech_bubble.tscn"))

def write_hud():
    s = Scene("HUD", "CanvasLayer", "res://scripts/ui/hud.gd", {"layer": 10, "heart_full": Res("res://assets/ui/heart_full.png"), "heart_empty": Res("res://assets/ui/heart_empty.png")})

    s.node("Root", "Control", props=full_rect({"mouse_filter": 2, "theme": s.res(THEME)}))
    s.node("TopLeft", "HBoxContainer", "Root", {"unique_name_in_owner": True, "layout_mode": 1, "offset_left": 16.0,
                                                "offset_top": 12.0, "offset_right": 260.0, "offset_bottom": 52.0,
                                                "mouse_filter": 2, "theme_override_constants/separation": 8})
    s.node("CoinIcon", "TextureRect", "Root/TopLeft", {"layout_mode": 2, "custom_minimum_size": V(32, 32),
                                                       "texture": s.res("res://assets/ui/coin_icon.png"),
                                                       "expand_mode": 1, "stretch_mode": 5})
    s.node("CoinLabel", "Label", "Root/TopLeft", label_props("0", 28, 0, {"unique_name_in_owner": True,
                                                                          "theme_override_colors/font_color": C(1, 0.88, 0.3)}))
    s.node("TopCenter", "VBoxContainer", "Root", {"unique_name_in_owner": True, "layout_mode": 1, "anchors_preset": 5,
                                                  "anchor_left": 0.5, "anchor_right": 0.5, "offset_left": -340.0,
                                                  "offset_top": 10.0, "offset_right": 340.0, "offset_bottom": 96.0,
                                                  "grow_horizontal": 2, "mouse_filter": 2,
                                                  "theme_override_constants/separation": 0})
    s.node("ObjectiveLabel", "Label", "Root/TopCenter", label_props("Objective", 20, 1, {"unique_name_in_owner": True,
                                                                                         "autowrap_mode": 3}))
    s.node("TimerLabel", "Label", "Root/TopCenter", label_props("60 s", 30, 1, {"unique_name_in_owner": True}))
    s.node("TopRight", "HBoxContainer", "Root", {"unique_name_in_owner": True, "layout_mode": 1, "anchors_preset": 1,
                                                 "anchor_left": 1.0, "anchor_right": 1.0, "offset_left": -400.0,
                                                 "offset_top": 12.0, "offset_right": -12.0, "offset_bottom": 52.0,
                                                 "grow_horizontal": 0, "alignment": 2, "mouse_filter": 2,
                                                 "theme_override_constants/separation": 14})
    s.node("HealthBox", "HBoxContainer", "Root/TopRight", {"unique_name_in_owner": True, "layout_mode": 2, "mouse_filter": 2,
                                                          "theme_override_constants/separation": 4})
    for i in range(8):
        s.node(f"Pip{i + 1}", "TextureRect", "Root/TopRight/HealthBox",
               {"layout_mode": 2, "custom_minimum_size": V(28, 26), "mouse_filter": 2,
                "texture": s.res("res://assets/ui/heart_full.png"), "expand_mode": 1, "stretch_mode": 5})
    s.node("PauseButton", "Button", "Root/TopRight", {"unique_name_in_owner": True, "layout_mode": 2,
                                                     "custom_minimum_size": V(40, 40), "focus_mode": 0,
                                                     "tooltip_text": "Pause (Esc)",
                                                     "icon": s.res("res://assets/ui/pause_icon.png"), "flat": True,
                                                     "icon_alignment": 1})
    s.node("AnnounceLabel", "Label", "Root", {"unique_name_in_owner": True, "layout_mode": 1, "anchors_preset": 14,
                                              "anchor_top": 0.5, "anchor_right": 1.0, "anchor_bottom": 0.5,
                                              "offset_top": -170.0, "offset_bottom": -120.0, "grow_horizontal": 2,
                                              "grow_vertical": 2, "text": "", "horizontal_alignment": 1,
                                              "theme_override_colors/font_color": C(1, 0.92, 0.5),
                                              "theme_override_constants/outline_size": 10,
                                              "theme_override_font_sizes/font_size": 36})
    s.write(P("scenes/ui/hud.tscn"))

def menu_panel(s, parent, name, title, min_w=420):
    s.node(name, "CenterContainer", parent, full_rect({"mouse_filter": 1}, mode=1))
    s.node("Panel", "PanelContainer", f"{parent}/{name}" if parent != "." else name,
           {"layout_mode": 2, "custom_minimum_size": V(min_w, 0)})
    base = (f"{parent}/{name}" if parent != "." else name) + "/Panel"
    s.node("VBox", "VBoxContainer", base, {"layout_mode": 2, "theme_override_constants/separation": 14})
    s.node("Title", "Label", base + "/VBox", label_props(title, 40, 1, {"theme_override_colors/font_color": C(1, 0.85, 0.3)}))
    return base + "/VBox"

def write_pause_menu():
    s = Scene("PauseMenu", "CanvasLayer", "res://scripts/ui/pause_menu.gd", {"process_mode": 3, "layer": 20})
    s.node("Root", "Control", props=full_rect({"theme": s.res(THEME)}))
    s.node("Dim", "ColorRect", "Root", full_rect({"color": C(0, 0, 0, 0.6)}, mode=1))
    vb = menu_panel(s, "Root", "Center", "Paused")
    for n, t in (("ResumeButton", "Resume"), ("RestartButton", "Restart checkpoint"), ("QuitButton", "Quit to menu")):
        s.node(n, "Button", vb, {"unique_name_in_owner": True, "layout_mode": 2, "text": t})
    s.node("Hint", "Label", vb, label_props("Esc: resume", 16, 1, {"modulate": C(1, 1, 1, 0.7)}))
    s.write(P("scenes/ui/pause_menu.tscn"))

def write_complete_banner():
    s = Scene("CheckpointComplete", "CanvasLayer", "res://scripts/ui/checkpoint_complete.gd", {"process_mode": 3, "layer": 25})
    s.node("Root", "Control", props=full_rect({"theme": s.res(THEME)}))
    s.node("Dim", "ColorRect", "Root", full_rect({"color": C(0, 0, 0, 0.45)}, mode=1))
    s.node("Center", "CenterContainer", "Root", full_rect({}, mode=1))
    s.node("Banner", "PanelContainer", "Root/Center", {"unique_name_in_owner": True, "layout_mode": 2,
                                                      "custom_minimum_size": V(560, 0)})
    vb = "Root/Center/Banner/VBox"
    s.node("VBox", "VBoxContainer", "Root/Center/Banner", {"layout_mode": 2, "theme_override_constants/separation": 14})
    s.node("Header", "Label", vb, label_props("CHECKPOINT COMPLETE", 40, 1, {"theme_override_colors/font_color": C(1, 0.85, 0.3)}))
    s.node("NameLabel", "Label", vb, label_props("Checkpoint 01 - Name", 24, 1, {"unique_name_in_owner": True}))
    s.node("CoinsRow", "HBoxContainer", vb, {"layout_mode": 2, "alignment": 1, "theme_override_constants/separation": 10})
    s.node("CoinIcon", "TextureRect", vb + "/CoinsRow", {"layout_mode": 2, "custom_minimum_size": V(32, 32),
                                                         "texture": s.res("res://assets/ui/coin_icon.png"),
                                                         "expand_mode": 1, "stretch_mode": 5})
    s.node("CoinsLabel", "Label", vb + "/CoinsRow", label_props("0 coins", 28, 1, {"unique_name_in_owner": True,
                                                                                   "theme_override_colors/font_color": C(1, 0.88, 0.3)}))
    s.node("ContinueButton", "Button", vb, {"unique_name_in_owner": True, "layout_mode": 2, "text": "Continue"})
    s.write(P("scenes/ui/checkpoint_complete.tscn"))

def write_transition():
    s = Scene("Transition", "CanvasLayer", "res://scripts/ui/transition.gd", {"process_mode": 3, "layer": 100})
    s.node("Fade", "ColorRect", props=full_rect({"mouse_filter": 2, "color": C(0.02, 0.01, 0.05, 1)}))
    s.node("Title", "Label", props=full_rect({"text": "", "horizontal_alignment": 1, "vertical_alignment": 1,
                                              "theme_override_colors/font_color": C(1, 0.88, 0.35),
                                              "theme_override_constants/outline_size": 8,
                                              "theme_override_colors/font_outline_color": C(0, 0, 0),
                                              "theme_override_font_sizes/font_size": 40}))
    s.write(P("scenes/ui/transition.tscn"))

def write_main_menu():
    import sys
    sys.path.insert(0, os.path.dirname(__file__))
    s = Scene("MainMenu", "Control", "res://scripts/ui/main_menu.gd", full_rect({"theme": Res(THEME)}))
    s.node("Background", "TextureRect", props=full_rect({"texture": s.res("res://assets/backgrounds/bg_castle_night.png"),
                                                         "expand_mode": 1, "stretch_mode": 6}, mode=1))
    s.node("Shade", "ColorRect", props=full_rect({"color": C(0.03, 0.02, 0.08, 0.35), "mouse_filter": 2}, mode=1))
    s.node("Title", "Label", props={"layout_mode": 1, "anchors_preset": 10, "anchor_right": 1.0, "offset_top": 50.0,
                                    "offset_bottom": 140.0, "grow_horizontal": 2, "text": "COIN TROLL ADVENTURE",
                                    "horizontal_alignment": 1, "theme_override_colors/font_color": C(1, 0.82, 0.2),
                                    "theme_override_constants/outline_size": 14,
                                    "theme_override_font_sizes/font_size": 64})
    s.node("Subtitle", "Label", props={"layout_mode": 1, "anchors_preset": 10, "anchor_right": 1.0, "offset_top": 138.0,
                                       "offset_bottom": 172.0, "grow_horizontal": 2, "text": "Prototype - 18 checkpoints",
                                       "horizontal_alignment": 1, "theme_override_font_sizes/font_size": 22})
    s.node("CTArt", "TextureRect", props={"layout_mode": 1, "anchors_preset": 2, "anchor_top": 1.0, "anchor_bottom": 1.0,
                                          "offset_left": 60.0, "offset_top": -330.0, "offset_right": 300.0, "offset_bottom": -10.0,
                                          "grow_vertical": 0, "texture": s.res("res://assets/characters/CT/ct_idle.png"),
                                          "expand_mode": 1, "stretch_mode": 5})
    s.node("CoinArt", "TextureRect", props={"layout_mode": 1, "anchors_preset": 3, "anchor_left": 1.0, "anchor_top": 1.0,
                                            "anchor_right": 1.0, "anchor_bottom": 1.0, "offset_left": -220.0, "offset_top": -200.0,
                                            "offset_right": -60.0, "offset_bottom": -40.0, "grow_horizontal": 0, "grow_vertical": 0,
                                            "texture": s.res("res://assets/objects/coin_bag.png"), "expand_mode": 1, "stretch_mode": 5})
    s.node("EndCard", "Label", props={"unique_name_in_owner": True, "layout_mode": 1, "anchors_preset": 10, "anchor_right": 1.0,
                                      "offset_top": 180.0, "offset_bottom": 220.0, "grow_horizontal": 2,
                                      "text": "TO BE CONTINUED... thanks for playing the prototype!", "horizontal_alignment": 1,
                                      "theme_override_colors/font_color": C(0.6, 1, 0.7),
                                      "theme_override_font_sizes/font_size": 24})
    s.node("MainButtons", "VBoxContainer", props={"unique_name_in_owner": True, "layout_mode": 1, "anchors_preset": 8,
                                                  "anchor_left": 0.5, "anchor_top": 0.5, "anchor_right": 0.5, "anchor_bottom": 0.5,
                                                  "offset_left": -200.0, "offset_top": -60.0, "offset_right": 200.0,
                                                  "offset_bottom": 250.0, "grow_horizontal": 2, "grow_vertical": 2,
                                                  "theme_override_constants/separation": 12})
    for n, t in (("ContinueButton", "Continue"), ("NewGameButton", "New game"), ("SelectButton", "Checkpoint select"),
                 ("ControlsButton", "Controls"), ("QuitButton", "Quit")):
        s.node(n, "Button", "MainButtons", {"unique_name_in_owner": True, "layout_mode": 2, "text": t})
    # checkpoint select
    s.node("SelectPanel", "CenterContainer", props=full_rect({"unique_name_in_owner": True, "visible": False}, mode=1))
    s.node("Panel", "PanelContainer", "SelectPanel", {"layout_mode": 2, "custom_minimum_size": V(760, 0)})
    vb = "SelectPanel/Panel/VBox"
    s.node("VBox", "VBoxContainer", "SelectPanel/Panel", {"layout_mode": 2, "theme_override_constants/separation": 14})
    s.node("Header", "Label", vb, label_props("Checkpoint Select", 36, 1, {"theme_override_colors/font_color": C(1, 0.85, 0.3)}))
    s.node("CheckpointGrid", "GridContainer", vb, {"unique_name_in_owner": True, "layout_mode": 2, "columns": 6,
                                                   "theme_override_constants/h_separation": 10,
                                                   "theme_override_constants/v_separation": 10})
    for i in range(1, 19):
        s.node(f"CP{i:02d}", "Button", vb + "/CheckpointGrid", {"layout_mode": 2, "custom_minimum_size": V(110, 56),
                                                                "text": f"{i:02d}"})
    s.node("SelectInfo", "Label", vb, label_props("", 20, 1, {"unique_name_in_owner": True, "custom_minimum_size": V(0, 90),
                                                               "autowrap_mode": 3}))
    s.node("SelectBackButton", "Button", vb, {"unique_name_in_owner": True, "layout_mode": 2, "text": "Back"})
    # controls
    s.node("ControlsPanel", "CenterContainer", props=full_rect({"unique_name_in_owner": True, "visible": False}, mode=1))
    s.node("Panel", "PanelContainer", "ControlsPanel", {"layout_mode": 2, "custom_minimum_size": V(640, 0)})
    vb = "ControlsPanel/Panel/VBox"
    s.node("VBox", "VBoxContainer", "ControlsPanel/Panel", {"layout_mode": 2, "theme_override_constants/separation": 12})
    s.node("Header", "Label", vb, label_props("Controls", 36, 1, {"theme_override_colors/font_color": C(1, 0.85, 0.3)}))
    s.node("Body", "Label", vb, label_props(
        "CT\n  Move: A/D or Left/Right   (maze: WASD / arrows)\n  Jump: Space, K, W or Up\n  Attack: J, X or Enter\n\n"
        "Alex (checkpoint 12)\n  Move: Left/Right   Jump: Space\n  Shield: Down   Bow: Up   Attack combo: Enter / J\n\n"
        "Pause: Esc or P      Restart checkpoint: R\nCinematics: Space to advance, Esc to skip", 19, 0))
    s.node("ControlsBackButton", "Button", vb, {"unique_name_in_owner": True, "layout_mode": 2, "text": "Back"})
    s.write(P("scenes/ui/main_menu.tscn"))

def write_cinematic():
    s = Scene("Cinematic", "Control", "res://scripts/ui/cinematic.gd", full_rect({"theme": Res(THEME)}))
    s.node("Background", "ColorRect", props=full_rect({"unique_name_in_owner": True, "color": C(0.06, 0.06, 0.12)}, mode=1))
    s.node("TitleLabel", "Label", props={"unique_name_in_owner": True, "layout_mode": 1, "anchors_preset": 10, "anchor_right": 1.0,
                                         "offset_top": 18.0, "offset_bottom": 64.0, "grow_horizontal": 2, "text": "Title",
                                         "horizontal_alignment": 1, "theme_override_colors/font_color": C(1, 0.85, 0.3),
                                         "theme_override_font_sizes/font_size": 34})
    s.node("Frame", "PanelContainer", props={"unique_name_in_owner": True, "layout_mode": 1, "anchors_preset": 5,
                                             "anchor_left": 0.5, "anchor_right": 0.5, "offset_left": -420.0, "offset_top": 76.0,
                                             "offset_right": 420.0, "offset_bottom": 470.0, "grow_horizontal": 2})
    s.node("VBox", "VBoxContainer", "Frame", {"layout_mode": 2, "theme_override_constants/separation": 8})
    s.node("ArtHolder", "Control", "Frame/VBox", {"layout_mode": 2, "size_flags_vertical": 3, "clip_contents": True})
    s.node("Art", "TextureRect", "Frame/VBox/ArtHolder", full_rect({"unique_name_in_owner": True, "expand_mode": 1,
                                                                    "stretch_mode": 5}, mode=1))
    s.node("Caption", "Label", "Frame/VBox", label_props("Caption", 20, 1, {"unique_name_in_owner": True, "autowrap_mode": 3,
                                                                            "theme_override_colors/font_color": C(0.85, 0.85, 1)}))
    s.node("Bubble", "PanelContainer", props={"unique_name_in_owner": True, "layout_mode": 1, "anchors_preset": 7,
                                              "anchor_left": 0.5, "anchor_top": 1.0, "anchor_right": 0.5, "anchor_bottom": 1.0,
                                              "offset_left": -420.0, "offset_top": -230.0, "offset_right": 420.0,
                                              "offset_bottom": -60.0, "grow_horizontal": 2, "grow_vertical": 0})
    s.node("VBox", "VBoxContainer", "Bubble", {"layout_mode": 2})
    s.node("SpeakerLabel", "Label", "Bubble/VBox", label_props("Speaker", 24, 0, {"unique_name_in_owner": True,
                                                                                  "theme_override_colors/font_color": C(1, 0.85, 0.3)}))
    s.node("LineLabel", "Label", "Bubble/VBox", label_props("Line", 26, 0, {"unique_name_in_owner": True, "autowrap_mode": 3}))
    s.node("Hint", "Label", props={"layout_mode": 1, "anchors_preset": 3, "anchor_left": 1.0, "anchor_top": 1.0,
                                   "anchor_right": 1.0, "anchor_bottom": 1.0, "offset_left": -420.0, "offset_top": -44.0,
                                   "offset_right": -20.0, "offset_bottom": -14.0, "grow_horizontal": 0, "grow_vertical": 0,
                                   "text": "Space: next    Esc: skip", "horizontal_alignment": 2,
                                   "modulate": C(1, 1, 1, 0.7), "theme_override_font_sizes/font_size": 16})
    s.write(P("scenes/cinematics/cinematic.tscn"))


def main():
    write_theme(); write_block(); write_background(); write_objects()
    write_players(); write_enemies(); write_npcs()
    write_speech_bubble(); write_hud(); write_pause_menu(); write_complete_banner(); write_transition()
    write_main_menu(); write_cinematic()
    print("common scenes done")

if __name__ == "__main__":
    main()
