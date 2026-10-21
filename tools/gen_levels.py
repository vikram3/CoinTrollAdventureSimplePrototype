# LEGACY: these generators predate the level rename and the hand-built levels.
# Do NOT run them: they would overwrite scenes/levels/ with old checkpoint output.
"""Builds the 18 level scenes from the level-design section of the GDD.
Every level is a normal editable Godot scene: move blocks, coins and enemies
in the editor afterwards."""
import os, random
from collections import deque
from tscn import *

ROOT = os.path.join(os.path.dirname(__file__), "..")
def P(rel): return os.path.join(ROOT, rel)

TRIGGERS = {
    1: "Time to grab those coins before anyone notices...",
    2: "Those coins are MINE. Gotta beat him there!",
    3: "New players flooding in... grab what I can before it gets crazy!",
    4: "Big Boss is coming. MOVE!",
    5: "She's holding her own, but Big Boss has one more trick!",
    6: "Better snap out of it... something doesn't feel right.",
    7: "Alright Flex, lead the way, but watch out for what's in these woods!",
    8: "Horn is somewhere in these woods... keep moving!",
    9: "A barreldugo! Flex says get close, let's try it!",
    10: "The Queen stepped in, but those bulls aren't done yet!",
    11: "Alex accepted the duel... somebody's gotta warm up for him!",
    12: "Big Bird went straight for projectiles, dodge and get close!",
    13: "I signed WHAT? Gotta do something, find those coins first!",
    14: "Alex won! Now the coins are flowing, grab what you can!",
    15: "The ship is going DOWN. Hold on and get to safety!",
    16: "Welcome to Sand Land... and it does NOT look friendly.",
    17: "I signed WHAT? Gotta do something, find those coins first!",
    18: "A sand wormfish?! Everyone scatter!",
}
COINS, EXIT, COINS_OR_EXIT, COINS_AND_EXIT, SURVIVE, DEFEAT, EVENT = range(7)

ENV = "res://assets/environment/"
BG = "res://assets/backgrounds/"
SC = "res://scenes/"
PLAYER_CT = SC + "player/player_ct.tscn"


class LB:
    def __init__(self, n, name, player_scene=PLAYER_CT, bg=None, width=4000, bounds=None, kill_y=900.0,
                 objective=COINS, coin_target=0, survive=0.0, defeat=0, override="", tracker=False, extra=None):
        self.n = n
        self.width = width
        self.player_scene = player_scene
        props = {"level_number": n, "level_name": name, "trigger_line": TRIGGERS[n],
                 "objective_type": objective, "coin_target": coin_target, "survive_seconds": float(survive),
                 "defeat_target": defeat, "objective_text_override": override,
                 "level_bounds": bounds or RECT(0, -600, width, 1320), "kill_y": float(kill_y)}
        if tracker:
            props["tracker_path"] = NP("Tracker")
        props.update(extra or {})
        self.s = Scene(f"Level{n:02d}", "Node2D", "res://scripts/levels/level.gd", props)
        self.count = {}
        self.right_wall = None
        if bg:
            self.s.node("Background", instance=SC + "environment/background.tscn",
                        props={"texture": Res(BG + bg), "parallax": 0.25})
        for g in ("Decor", "Environment", "Goals", "Coins", "Hazards", "NPCs", "Enemies"):
            self.s.node(g, "Node2D")

    def name(self, base):
        self.count[base] = self.count.get(base, 0) + 1
        return f"{base}{self.count[base]}"

    # --- geometry
    def block(self, x0, y0, w, h, tex, one_way=False, tint=None, base="Block", parent="Environment"):
        props = {"position": V(x0 + w / 2, y0 + h / 2), "size": V(w, h), "tile_texture": Res(ENV + tex)}
        if one_way:
            props["one_way"] = True
        if tint:
            props["tint"] = tint
        self.s.node(self.name(base), parent=parent, instance=SC + "environment/block.tscn", props=props)

    def ground(self, x0, x1, top, tex, depth=420, tint=None):
        self.block(x0, top, x1 - x0, depth, tex, tint=tint, base="Ground")

    def wall(self, x, top=-700, bottom=820, tex="wall_stone.png"):
        self.block(x - 32, top, 64, bottom - top, tex, base="Wall")

    def ledge(self, x0, y, w, tex, base="Ledge"):
        self.block(x0, y, w, 24, tex, one_way=True, base=base)

    # --- things
    def coin(self, x, y, falling=False, delay=0.0):
        props = {"position": V(x, y)}
        if falling:
            props["falling"] = True
            props["fall_delay"] = float(delay)
        self.s.node(self.name("Coin"), parent="Coins", instance=SC + "objects/coin.tscn", props=props)

    def coins_row(self, x0, x1, y, n):
        if n == 1:
            self.coin((x0 + x1) / 2, y); return
        for i in range(n):
            self.coin(x0 + (x1 - x0) * i / (n - 1), y)

    def enemy(self, scene, x, y, props=None, base=None):
        p = {"position": V(x, y)}; p.update(props or {})
        base = base or os.path.splitext(os.path.basename(scene))[0].title().replace("_", "")
        nm = self.name(base)
        self.s.node(nm, parent="Enemies", instance=SC + "enemies/" + scene, props=p)
        return nm

    def hazard(self, x, y, tex, props=None):
        p = {"position": V(x, y), "texture": Res("res://assets/objects/" + tex)}; p.update(props or {})
        self.s.node(self.name("Falling" + tex.split(".")[0].title().replace("_", "")), parent="Hazards",
                    instance=SC + "objects/falling_hazard.tscn", props=p)

    def goal(self, x, y, label="EXIT", tex="goal_flag.png", scale=1.0, show_sprite=True):
        self.s.node("Goal", parent="Goals", instance=SC + "objects/goal.tscn",
                    props={"position": V(x, y), "label_text": label, "texture": Res("res://assets/objects/" + tex),
                           "sprite_scale": float(scale), "show_sprite": show_sprite})

    def hide_spot(self, x, bottom, w, h, tex="hedge.png", hint="Hold DOWN to hide!"):
        """A bush or crate CT can hide in, drawn with its bottom on the floor at `bottom`."""
        tw, th = png_size("assets/environment/" + tex)
        cx, cy = x, bottom - h / 2
        self.s.node(self.name("HideSpot"), parent="Hazards", instance=SC + "objects/hide_spot.tscn",
                    props={"position": V(cx, cy), "size": V(w, h), "hint": hint})
        self.s.node(self.name("Bush"), "Sprite2D", parent="Decor",
                    props={"position": V(cx, cy), "texture": Res(ENV + tex), "scale": V(w / tw, h / th)})

    def restart_zone(self, x, y, w, h, msg="Waaah!", base="RestartZone"):
        self.s.node(self.name(base), parent="Hazards", instance=SC + "objects/restart_zone.tscn",
                    props={"position": V(x, y), "size": V(w, h), "message": msg})

    def decor(self, tex, x, y, props=None, base=None):
        p = {"position": V(x, y), "texture": Res(tex)}; p.update(props or {})
        nm = self.name(base or "Decor")
        self.s.node(nm, "Sprite2D", parent="Decor", props=p)
        return "Decor/" + nm

    def commenter(self, tex, x, y, lines, base, props=None, parent="Decor"):
        p = {"position": V(x, y), "texture": Res(tex), "lines": PSA(lines)}; p.update(props or {})
        self.s.node(self.name(base), parent=parent, instance=SC + "npc/commenter.tscn", props=p)

    def npc(self, scene, x, y, props=None, base=None):
        p = {"position": V(x, y)}; p.update(props or {})
        nm = base or os.path.splitext(os.path.basename(scene))[0].title().replace("_", "")
        self.s.node(nm, parent="NPCs", instance=SC + "npc/" + scene, props=p)

    def finish(self, px, py, tracker_script=None, tracker_props=None, nodes_after_player=None):
        if self.right_wall:
            self.wall(self.width, *self.right_wall)
        self.s.node("Player", parent=".", instance=self.player_scene, props={"position": V(px, py)})
        for fn in (nodes_after_player or []):
            fn(self.s)
        if tracker_script:
            p = dict(tracker_props or {})
            self.s.node("Tracker", "Node", props=p, script=tracker_script)
        mode = "platformer"
        if self.player_scene.endswith("player_alex.tscn"):
            mode = "alex"
        elif self.player_scene.endswith("topdown.tscn"):
            mode = "topdown"
        self.s.node("TouchControls", "CanvasLayer", props={"layer": 20})
        self.s.node("TouchPad", "Control", parent="TouchControls", script="res://scripts/ui/touch_controls.gd",
                    props={"mode": mode, "anchor_right": 1.0, "anchor_bottom": 1.0, "mouse_filter": 2})
        self.s.node("HUD", instance=SC + "ui/hud.tscn")
        self.s.node("PauseMenu", instance=SC + "ui/pause_menu.tscn")
        self.s.node("LevelComplete", instance=SC + "ui/level_complete.tscn")
        self.s.write(P(f"scenes/levels/level_{self.n:02d}.tscn"))


def side_walls(lb, top=-700, bottom=820):
    lb.wall(0, top, bottom)
    lb.right_wall = (top, bottom)   # placed at lb.width by finish(), so sections can extend the level


# ===================================================================== EXTENSIONS
CASTLE = dict(ground="ground_castle.png", ledge="ledge_stone.png", pillar="wall_stone.png", crates=True,
              hazards=[("hedge_trap.png", {"trigger_size": V(170, 420), "damage": 1, "hazard_name": "hedge_trap",
                                           "debris_color": C(0.2, 0.5, 0.2)}, 60)],
              enemies=[("skull.tscn", 30, {}, False),
                       ("elite_skull.tscn", 32, {"detect_range": 300.0, "leash_distance": 260.0}, False)])
FOREST = dict(ground="ground_forest.png", ledge="ledge_moss.png", pillar="trunk.png", crates=True,
              hazards=[("log.png", {"trigger_size": V(220, 420), "damage": 1, "knockback": V(300, -250),
                                    "hazard_name": "log", "shake_time": 0.4, "debris_color": C(0.45, 0.3, 0.18)}, 70)],
              enemies=[("skull.tscn", 30, {}, False),
                       ("elite_skull.tscn", 32, {"enemy_type": "speed", "detect_range": 380.0, "leash_distance": 600.0}, False),
                       ("barreldugo.tscn", 26, {"fire_interval": 2.0}, False)])
ARENA = dict(ground="ground_arena.png", ledge="ledge_stone.png", pillar="wall_stone.png", crates=False,
             hazards=[], enemies=[])
DECK = dict(ground="ground_deck.png", ledge="ledge_wood.png", pillar="crate_big.png", crates=True,
            hazards=[("rock.png", {"trigger_size": V(180, 400), "respawn_time": 5.0, "damage": 1}, -20)],
            enemies=[("skull.tscn", 30, {}, False), ("minor_bull.tscn", 26, {}, True)])
SAND = dict(ground="ground_sand.png", ledge="ledge_rubble.png", pillar="ground_sand.png", crates=False,
            hazards=[("stone.png", {"trigger_size": V(180, 440), "damage": 1, "hazard_name": "stone",
                                    "debris_color": C(0.8, 0.65, 0.4)}, 0)],
            enemies=[("skull.tscn", 30, {}, False), ("elite_skull.tscn", 32, {}, False)])
CLIFF = dict(ground="ground_cliff.png", ledge="ledge_stone.png", pillar="ground_cliff.png", crates=False,
             hazards=[], enemies=[("skull.tscn", 30, {}, False)])


def png_size(rel):
    import struct
    with open(P(rel), "rb") as f:
        d = f.read(24)
    return struct.unpack(">II", d[16:24])


def add_section(lb, x0, x1, G, theme, seed=0, ground=True):
    """Appends a platforming stretch from x0 to x1 on floor height G: pillars to jump, reachable ledges
    with coins, hazard drops, enemies and sliding crates. No pits, so every section stays fair."""
    rng = random.Random(seed * 7919 + int(x0))
    if ground:
        lb.ground(x0, x1, G, theme["ground"])
    hazards = theme["hazards"]
    enemies = theme["enemies"]
    kinds = ["pillar", "ledge", "run", "hazard", "enemy", "crate"]
    weights = [3, 3, 2, 1.2 if hazards else 0, 3.2 if enemies else 0, 1.2 if theme["crates"] else 0]
    x = x0 + 200
    while x < x1 - 260:
        kind = rng.choices(kinds, weights)[0]
        if kind == "pillar":
            h = rng.choice([90, 110, 130])
            lb.block(x, G - h, 60, h, theme["pillar"], base="Pillar")
            lb.coins_row(x - 10, x + 70, G - h - 44, 3)
            x += rng.randint(220, 300)
        elif kind == "ledge":
            w = rng.randint(160, 220)
            lb.ledge(x, G - 150, w, theme["ledge"], base="SectionLedge")
            lb.coins_row(x + 30, x + w - 30, G - 190, 3)
            x += w + rng.randint(160, 220)
        elif kind == "run":
            lb.coins_row(x, x + 260, G - 36, 6)
            x += 240
        elif kind == "hazard":
            tex, props, hy = rng.choice(hazards)
            lb.hazard(x, hy, tex, dict(props))
            x += rng.randint(280, 360)
        elif kind == "enemy":
            scene, yoff, props, bounded = rng.choice(enemies)
            p = dict(props)
            if bounded:
                p["min_x"] = float(x0 + 80)
                p["max_x"] = float(x1 - 80)
            lb.enemy(scene, x, G - yoff, p)
            x += rng.randint(340, 440)
        else:
            lb.s.node(lb.name("SlidingCrate"), parent=".", instance=SC + "objects/sliding_crate.tscn",
                      props={"position": V(x, G - 30), "lifetime": 12.0,
                             "start_delay": round(rng.uniform(1.0, 3.0), 1)})
            x += rng.randint(300, 400)

def scatter_enemies(lb, x0, x1, G, theme, count, seed=0):
    """Drops `count` enemies evenly along an existing stretch (used for the original parts of levels)."""
    rng = random.Random(seed * 104729 + int(x0))
    span = x1 - x0
    for i in range(count):
        scene, yoff, props, bounded = rng.choice(theme["enemies"])
        p = dict(props)
        if bounded:
            p["min_x"] = float(x0 + 60)
            p["max_x"] = float(x1 - 60)
        x = x0 + span * (i + 0.5) / count + rng.randint(-40, 40)
        lb.enemy(scene, x, G - yoff, p)


# ===================================================================== CP01
def cp01():
    random.seed(1)
    CW, CH, CELL = 13, 9, 96
    GW, GH = CW * 2 + 1, CH * 2 + 1
    grid = [["#"] * GW for _ in range(GH)]
    def carve(cx, cy):
        stack = [(cx, cy)]; grid[cy * 2 + 1][cx * 2 + 1] = "."
        seen = {(cx, cy)}
        while stack:
            x, y = stack[-1]
            nb = [(x + dx, y + dy, dx, dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
                  if 0 <= x + dx < CW and 0 <= y + dy < CH and (x + dx, y + dy) not in seen]
            if not nb:
                stack.pop(); continue
            nx, ny, dx, dy = random.choice(nb)
            grid[y * 2 + 1 + dy][x * 2 + 1 + dx] = "."
            grid[ny * 2 + 1][nx * 2 + 1] = "."
            seen.add((nx, ny)); stack.append((nx, ny))
    carve(0, 0)
    # open a few loops so the maze has more than one safe route
    opened = 0
    while opened < 20:
        x = random.randint(1, GW - 2); y = random.randint(1, GH - 2)
        if grid[y][x] != "#": continue
        if (grid[y][x - 1] == "." and grid[y][x + 1] == "." and grid[y - 1][x] == "#" and grid[y + 1][x] == "#") or \
           (grid[y - 1][x] == "." and grid[y + 1][x] == "." and grid[y][x - 1] == "#" and grid[y][x + 1] == "#"):
            grid[y][x] = "."; opened += 1
    exit_cell = (GW - 1, GH - 2)
    grid[exit_cell[1]][exit_cell[0]] = "."
    # BFS distances
    dist = {(1, 1): 0}; dq = deque([(1, 1)])
    while dq:
        x, y = dq.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < GW and 0 <= ny < GH and grid[ny][nx] == "." and (nx, ny) not in dist:
                dist[(nx, ny)] = dist[(x, y)] + 1; dq.append((nx, ny))
    assert exit_cell in dist
    W, H = GW * CELL, GH * CELL
    lb = LB(1, "Bush Maze Intro", player_scene=SC + "player/player_ct_naked_topdown.tscn", width=W,
            bounds=RECT(0, 0, W, H), kill_y=100000.0, objective=COINS_OR_EXIT, coin_target=20)
    lb.s.node("Floor", "Sprite2D", parent="Decor", props={"texture_repeat": 2, "texture": Res(ENV + "grass_topdown.png"),
                                                           "centered": False, "region_enabled": True,
                                                           "region_rect": RECT(0, 0, W, H)})
    for y in range(GH):
        x = 0
        while x < GW:
            if grid[y][x] == "#":
                x0 = x
                while x < GW and grid[y][x] == "#": x += 1
                lb.block(x0 * CELL, y * CELL, (x - x0) * CELL, CELL, "hedge.png", base="Hedge")
            else:
                x += 1
    paths = [c for c in dist if c != exit_cell and dist[c] >= 2]
    # skulls on long straight corridors, away from the start
    def open_cell(x, y):
        return 1 <= x < GW - 1 and 1 <= y < GH - 1 and grid[y][x] == "."
    def run(c, d):
        a = b = c
        dx, dy = d
        while open_cell(a[0] - dx, a[1] - dy): a = (a[0] - dx, a[1] - dy)
        while open_cell(b[0] + dx, b[1] + dy): b = (b[0] + dx, b[1] + dy)
        return a, b
    cands = []
    for c in paths:
        if dist[c] < 7: continue
        for d in ((1, 0), (0, 1)):
            a, b = run(c, d)
            ln = abs(a[0] - b[0]) + abs(a[1] - b[1])
            if ln >= 4: cands.append((ln, c, a, b))
    random.shuffle(cands)
    cands.sort(key=lambda t: -t[0])
    skulls = []
    for ln, c, a, b in cands:
        if any(abs(a[0] - s[0][0]) + abs(a[1] - s[0][1]) < 6 for s in skulls): continue
        skulls.append((a, b))
        if len(skulls) == 6: break
    for a, b in skulls:
        ax, ay = a[0] * CELL + CELL / 2, a[1] * CELL + CELL / 2
        bx, by = b[0] * CELL + CELL / 2, b[1] * CELL + CELL / 2
        lb.enemy("skull_topdown.tscn", ax, ay, {"patrol_points": PV2([(0, 0), (bx - ax, by - ay)])}, base="Skull")
    skull_cells = set()
    for a, b in skulls:
        for x in range(min(a[0], b[0]), max(a[0], b[0]) + 1):
            for y in range(min(a[1], b[1]), max(a[1], b[1]) + 1):
                skull_cells.add((x, y))
    safe = [c for c in paths if c not in skull_cells]
    random.shuffle(safe)
    coin_cells = sorted(safe[:40], key=lambda c: dist[c])
    for (x, y) in coin_cells:
        lb.coin(x * CELL + CELL / 2, y * CELL + CELL / 2)
    lb.goal(exit_cell[0] * CELL + CELL / 2, exit_cell[1] * CELL + CELL / 2 + 10, "EXIT")
    lb.finish(1 * CELL + CELL / 2, 1 * CELL + CELL / 2)
    print("cp01 maze", GW, "x", GH, "coins", len(coin_cells), "skulls", len(skulls))

# ===================================================================== CP02
def castle_gauntlet(lb, x0, x1, G):
    """Mario-style trap run for level 03: a thwomp-like stone drop, a pit with a bait ledge,
    a bullet emitter, an invisible floor trap, falling stones, a crate and skull stair, and a narrow last pit."""
    STONE = {"trigger_size": V(180, 440), "damage": 1, "hazard_name": "stone", "debris_color": C(0.8, 0.65, 0.4)}
    # 1. thwomp run: stones drop as you pass under them
    lb.ground(x0, 7400, G, "ground_castle.png")
    lb.hazard(6950, 0, "stone.png", dict(STONE, shake_time=0.45))
    lb.coins_row(7060, 7180, G - 36, 4)
    lb.hazard(7250, 0, "stone.png", dict(STONE, shake_time=0.45))
    # 2. pit with a bait ledge floating over it (coins tempt a jump that drops you in)
    lb.ledge(7330, G - 170, 200, "ledge_stone.png", base="BaitLedge")
    lb.coins_row(7350, 7510, G - 212, 4)
    lb.restart_zone(7480, G + 200, 160, 400, "Waaah!", base="PitRestart")
    lb.ground(7560, 7900, G, "ground_castle.png")
    lb.hide_spot(6880, G, 120, 110)
    lb.hide_spot(9060, G, 120, 110)
    lb.hide_spot(7760, G, 120, 110)
    # 3. bullet emitter firing along the floor toward you
    lb.s.node("BulletEmitter1", parent=".", instance=SC + "objects/hazard_emitter.tscn",
              props={"position": V(8000, G - 40), "direction": V(-1, 0), "interval": 2.2, "first_delay": 1.0})
    lb.commenter("res://assets/npc/lala.png", 7700, G - 32, ["Hmm... that ground looks... normal."], "Lala",
                 {"first_delay": 2.0, "interval_min": 8.0, "interval_max": 12.0})
    # 4. invisible floor trap: solid-looking ground with a hidden zone at the surface, lured by coins
    lb.ground(7900, 8150, G, "ground_castle.png")
    lb.restart_zone(8030, G - 20, 120, 40, "Gotcha!", base="InvisibleTrap")
    lb.coins_row(7990, 8070, G - 70, 3)
    # 5. stair of stone pillars with a skull patrolling the top, then a sliding crate
    lb.ground(8150, 8900, G, "ground_castle.png")
    lb.block(8260, G - 90, 60, 90, "wall_stone.png", base="StairStep")
    lb.block(8340, G - 130, 60, 130, "wall_stone.png", base="StairStep")
    lb.block(8420, G - 90, 60, 90, "wall_stone.png", base="StairStep")
    lb.coins_row(8250, 8490, G - 170, 4)
    lb.enemy("elite_skull.tscn", 8560, G - 32, {"detect_range": 300.0, "leash_distance": 260.0})
    lb.s.node(lb.name("SlidingCrate"), parent=".", instance=SC + "objects/sliding_crate.tscn",
              props={"position": V(8720, G - 30), "lifetime": 12.0, "start_delay": 1.0})
    # 6. chandelier of falling stones
    for x in (8650, 8800):
        lb.hazard(x, 0, "stone.png", dict(STONE))
    # 7. last stretch: two skulls, a narrow pit, then the chest
    lb.enemy("skull.tscn", 9020, G - 30)
    lb.ground(8900, 9150, G, "ground_castle.png")
    lb.ground(9220, x1, G, "ground_castle.png")
    lb.restart_zone(9185, G + 200, 70, 400, "Waaah!", base="NarrowPitRestart")
    lb.coins_row(9160, 9210, G - 120, 2)


def cp02():
    G = 400; T = "ground_castle.png"
    lb = LB(2, "Treasure Chest Chase", player_scene=SC + "player/player_ct_naked.tscn", bg="bg_castle_night.png",
            width=9400, objective=EXIT, override="Reach the TREASURE chest")
    side_walls(lb)
    lb.ground(0, 1100, G, T); lb.ground(1280, 3300, G, T); lb.ground(3450, 4400, G, T)
    lb.block(2200, -700, 600, 990, "wall_stone.png", base="CorridorCeiling")
    for x0, y, w in ((550, 300, 160), (800, 230, 160), (1500, 290, 160), (1740, 220, 160), (3560, 320, 140), (3700, 250, 140)):
        lb.ledge(x0, y, w, "ledge_stone.png")
    for x in (500, 1400, 1950, 3050, 3650):
        lb.hazard(x, 60, "hedge_trap.png", {"trigger_size": V(170, 420), "damage": 1, "hazard_name": "hedge_trap",
                                            "debris_color": C(0.2, 0.5, 0.2)})
    fast = {"patrol_speed": 143.0, "chase_speed": 253.5, "patrol_distance": 140.0}
    for x in (800, 1650, 3100):
        lb.enemy("skull.tscn", x, G - 30, fast)
    lb.enemy("elite_skull.tscn", 2500, G - 32, {"detect_range": 300.0, "leash_distance": 260.0})
    lb.coins_row(570, 690, 260, 3); lb.coins_row(820, 940, 190, 3); lb.coins_row(1520, 1640, 250, 3)
    lb.coins_row(1760, 1880, 180, 3); lb.coins_row(2950, 3250, 360, 4)
    lb.decor("res://assets/enemies/big_boss.png", 200, 240,
             {"modulate": C(0, 0, 0, 0.5), "scale": V(0.8, 0.8), "script": Res("res://scripts/environment/decor_mover.gd"),
              "move_velocity": V(70, 0), "travel": 3700.0}, base="RivalSilhouette")
    add_section(lb, 4400, 6800, G, CASTLE, seed=2)
    castle_gauntlet(lb, 6800, 9400, G)
    # treasure: a glowing chest on a pile of coins, with a coin bag and a hint from Lala
    # chest.png is 70x58; at scale 2 it stands on the floor at x 9260-9400, its centre 58 px above floor
    lb.coins_row(9270, 9390, G - 170, 5)
    lb.coins_row(9300, 9360, G - 220, 3)
    lb.commenter("res://assets/npc/lala.png", 9100, G - 32, ["Is that... TREASURE?!", "Grab it before the Mayor does!"],
                 "Lala", {"first_delay": 1.5, "interval_min": 6.0, "interval_max": 9.0})
    lb.decor("res://assets/objects/chest.png", 9330, G - 58, {"scale": V(2.0, 2.0), "modulate": C(1.0, 0.95, 0.7)},
             base="TreasureBox")
    lb.goal(9330, G - 48, "TREASURE", "chest.png", 2.0, False)
    lb.finish(150, G - 40)

# ===================================================================== CP03
def cp03():
    G = 400; lb = LB(3, "Shadow Arena", bg="bg_arena_night.png", width=4200, objective=EVENT, tracker=True,
                     bounds=RECT(0, -400, 4200, 1120))
    side_walls(lb)
    lb.ground(0, 2600, G, "ground_arena.png")
    ledges = ((300, 280, 240), (800, 200, 280), (1500, 200, 280), (2060, 280, 240), (1150, 90, 300))
    for x0, y, w in ledges:
        lb.ledge(x0, y, w, "ledge_stone.png")
        lb.coins_row(x0 + 30, x0 + w - 30, y - 34, 4)
    add_section(lb, 2600, 4200, G, ARENA, seed=3)
    lb.coins_row(150, 4050, G - 36, 20)
    def spawner(s):
        s.node("ShadowSpawner", parent=".", instance=SC + "objects/shadow_spawner.tscn",
               props={"avatar_scene": Res(SC + "enemies/shadow_avatar.tscn"), "interval": 3.4, "first_delay": 2.5})
        for i, (x, y) in enumerate(((400, 330), (950, 330), (1300, 330), (1700, 330), (2200, 330), (1300, 40), (950, 140), (2900, 330), (3500, 330), (3900, 40), (2700, 40))):
            s.node(f"Spawn{i + 1}", "Marker2D", parent="ShadowSpawner", props={"position": V(x, y)})
    lb.finish(150, G - 40, "res://scripts/levels/trackers/shadow_arena_tracker.gd",
              {"need_coins": 30, "need_bursts": 5, "spawner_path": NP("../ShadowSpawner")}, [spawner])

# ===================================================================== CP04
def cp04():
    G = 400; lb = LB(4, "Big Boss Dodge", bg="bg_arena_night.png", width=3200, objective=SURVIVE, survive=100,
                     bounds=RECT(0, -400, 3200, 1120))
    side_walls(lb)
    lb.ground(0, 1800, G, "ground_arena.png")
    lb.ledge(180, 270, 220, "ledge_stone.png"); lb.ledge(1400, 270, 220, "ledge_stone.png")
    lb.ledge(780, 200, 240, "ledge_stone.png")
    add_section(lb, 1800, 3200, G, ARENA, seed=4)
    lb.enemy("big_boss.tscn", 1200, G - 80, {"arena_min_x": 140.0, "arena_max_x": 3060.0, "telegraph_time": 0.8})
    lb.hide_spot(2250, G, 110, 100, tex="crate_big.png")
    lb.finish(300, G - 40)

# ===================================================================== CP05
def cp05():
    G = 300; lb = LB(5, "Pink Girl vs Big Boss", bg="bg_arena_night.png", width=4400, objective=EVENT, tracker=True,
                     bounds=RECT(0, -700, 4400, 1320), kill_y=1000.0)
    side_walls(lb, bottom=720)
    lb.ground(0, 4400, G, "ground_arena.png")
    for i in range(4):
        lb.decor("res://assets/objects/fence.png", 3340, G - 32 - i * 64, base="ArenaFence")
    lb.ledge(900, 180, 240, "ledge_stone.png"); lb.ledge(1900, 180, 240, "ledge_stone.png")
    lb.coins_row(920, 1120, 145, 4); lb.coins_row(1920, 2120, 145, 4); lb.coins_row(400, 800, G - 36, 4)
    boss = lb.enemy("big_boss.tscn", 3950, 191, {"target_group": "pink_girl", "ignore_player": True, "contact_damage": 0,
                                                 "invulnerable": False, "max_health": 24, "arena_min_x": 3420.0,
                                                 "arena_max_x": 4320.0, "preferred_distance": 170.0, "slam_chance": 0.35},
                    base="BigBoss")
    lb.npc("pink_girl.tscn", 3550, 235, {"boss_path": NP("../../Enemies/" + boss), "min_x": 3420.0, "max_x": 4300.0},
           base="PinkGirl")
    def waves(s):
        s.node("WaveSpawner", parent=".", instance=SC + "objects/wave_spawner.tscn",
               props={"enemy_scene": Res(SC + "enemies/skull.tscn"), "wave_counts": PIA([2, 3, 4]),
                      "one_marker_per_wave": True, "spread": 60.0, "start_delay": 2.5, "delay_between_waves": 3.0,
                      "speed_bonus_per_wave": 6.0, "march": True, "march_target_x": 3340.0, "fail_on_reach": True,
                      "fail_message": "The skulls reached the arena!", "detect_range_override": 320.0})
        for i, x in enumerate((1500, 2300, 2868)):
            s.node(f"Wave{i + 1}Spawn", "Marker2D", parent="WaveSpawner", props={"position": V(x, 250)})
    lb.finish(300, G - 40, "res://scripts/levels/trackers/wave_tracker.gd",
              {"spawner_path": NP("../WaveSpawner"), "label": "Clear the skull waves"}, [waves])

# ===================================================================== CP06
def cp06():
    G = 389; lb = LB(6, "Cliff Ambush", bg="bg_cliff_dusk.png", width=4800, objective=SURVIVE, survive=75,
                     kill_y=1100.0, extra={"knockback_fall_completes": True, "knockback_fall_source": "horn"})
    lb.wall(0, bottom=G + 420)
    lb.ground(0, 1500, G, "ground_cliff.png"); lb.ground(1900, 3000, G, "ground_cliff.png")
    lb.ledge(550, 250, 300, "ledge_stone.png", base="LedgeA"); lb.ledge(2150, 250, 300, "ledge_stone.png", base="LedgeB")
    lb.restart_zone(1700, 800, 500, 300, "Waaah!", base="FallZone")
    lb.enemy("horn.tscn", 150, G - 50, {"min_x": 60.0, "max_x": 1500.0}, base="Horn")
    lb.enemy("skull.tscn", 1250, G - 30); lb.enemy("skull.tscn", 2600, G - 30)
    lb.coins_row(580, 820, 215, 4); lb.coins_row(2180, 2420, 215, 4); lb.coins_row(300, 1300, G - 36, 6)
    add_section(lb, 3000, 4800, G, CLIFF, seed=6)
    lb.wall(4800, bottom=G + 420)
    lb.hide_spot(3800, G, 120, 110)
    lb.hide_spot(2100, G, 120, 110)
    lb.finish(800, G - 40)

# ===================================================================== CP07
def cp07():
    lb = LB(7, "Forest Walk", bg="bg_forest.png", width=7600, objective=COINS, coin_target=50)
    side_walls(lb)
    sections = ((0, 1200, 420), (1200, 2000, 380), (2000, 3200, 420), (3200, 4000, 360), (4000, 5200, 420))
    for x0, x1, top in sections:
        lb.ground(x0, x1, top, "ground_forest.png")
    for i, x in enumerate(range(150, 5100, 420)):
        top = next(t for a, b, t in sections if a <= x < b)
        lb.decor(ENV + "tree.png", x + 60, top - 105, {"modulate": C(0.75, 0.85, 0.75)}, base="Tree")
    for x0, y, w in ((650, 270, 220), (1650, 230, 220), (2650, 280, 220), (3550, 200, 220), (4450, 270, 220)):
        lb.ledge(x0, y, w, "ledge_moss.png", base="MossLedge")
        lb.coins_row(x0 + 60, x0 + w - 60, y - 34, 2)
    for x0, x1, top in sections:
        n = 8
        lb.coins_row(x0 + 90, x1 - 90, top - 36, n)
    lb.enemy("elite_skull.tscn", 2500, 380); lb.enemy("elite_skull.tscn", 4300, 380)
    lb.enemy("skull.tscn", 1500, 340)
    lb.npc("felix.tscn", 90, 370, {"opening_lines": PSA(["So... you just fell out of the sky.", "Stick with me. The forest gets weird.",
                                                          "Coins on the moss ledges, if you're into that."])}, base="Felix")
    scatter_enemies(lb, 900, 5000, 420, FOREST, 3, seed=7)
    add_section(lb, 5200, 7600, 420, FOREST, seed=7)
    lb.hide_spot(1800, 380, 120, 110)
    lb.hide_spot(5600, 420, 120, 110)
    lb.hide_spot(6600, 420, 120, 110)
    lb.hide_spot(3000, 420, 120, 110)
    lb.hide_spot(4700, 420, 120, 110)
    lb.finish(220, 380)

# ===================================================================== CP08
def cp08():
    G = 420; lb = LB(8, "Forest Chase", bg="bg_forest.png", width=6400, objective=EXIT)
    side_walls(lb)
    lb.ground(0, 2600, G, "ground_forest.png"); lb.ground(2720, 4200, G, "ground_forest.png")
    for x in (800, 1250, 1600, 2050, 2450, 2950, 3200):
        lb.block(x - 30, G - 110, 60, 110, "trunk.png", base="Trunk")
    for x in (1100, 2300):
        lb.hazard(x, 70, "log.png", {"trigger_size": V(220, 420), "damage": 1, "knockback": V(300, -250),
                                     "hazard_name": "log", "shake_time": 0.4, "debris_color": C(0.45, 0.3, 0.18)})
    scatter_enemies(lb, 600, 3800, G, FOREST, 2, seed=8)
    lb.enemy("barreldugo.tscn", 1900, G - 26, {"fire_interval": 1.8}, base="Barreldugo")
    for x in (400, 1000, 1400, 1800, 2250, 2800, 3100, 3500):
        lb.coin(x, G - 150 if x in (1000, 1400, 2800) else G - 36)
    lb.npc("felix.tscn", 120, 380, {"opening_lines": PSA(["Horn is somewhere in these woods... keep moving!",
                                                           "Do not look back. Seriously, do not look back.",
                                                           "Duck the logs, dodge the trees, and keep running!"]),
                                    "opening_interval": 3.5, "idle_lines": PSA(["Faster, CT!", "Almost there!", "RUN!"]),
                                    "idle_interval_min": 5.0, "idle_interval_max": 8.0}, base="Felix")
    add_section(lb, 4200, 6400, G, FOREST, seed=8)
    lb.goal(6250, G - 50, "SAFE")
    def chaser(s):
        s.node("Chaser", parent=".", instance=SC + "objects/chaser.tscn",
               props={"position": V(-150, G), "speed": 468.0, "start_delay": 1.2,
                      "texture": Res("res://assets/enemies/forest_chaser.png"), "kill_message": "Horn caught me!"})
    lb.hide_spot(2250, G, 120, 110)
    lb.hide_spot(3600, G, 120, 110)
    lb.finish(260, G - 40, nodes_after_player=[chaser])

# ===================================================================== CP09
def cp09():
    G = 400; lb = LB(9, "Enemy Types", bg="bg_forest.png", width=3400, objective=EVENT, tracker=True,
                     bounds=RECT(0, -500, 3400, 1220))
    side_walls(lb)
    lb.ground(0, 2200, G, "ground_forest.png")
    for x0, y, w in ((450, 280, 200), (1000, 240, 220), (1650, 280, 200)):
        lb.ledge(x0, y, w, "ledge_moss.png", base="MossLedge")
    lb.enemy("bull.tscn", 1600, G - 36, {"charge_speed": 468.0, "min_x": 80.0, "max_x": 2120.0, "enemy_type": "tank"},
             base="TankBull")
    lb.enemy("elite_skull.tscn", 1100, G - 30, {"enemy_type": "speed", "detect_range": 420.0, "leash_distance": 900.0},
             base="SpeedSkull")
    lb.enemy("barreldugo.tscn", 1980, G - 26, {"enemy_type": "projectile"}, base="Barreldugo")
    add_section(lb, 2200, 3400, G, FOREST, seed=9)
    lb.npc("felix.tscn", 90, 360, {"opening_lines": PSA(["Three kinds of enemies, CT. Listen up!",
                                                          "Tanks like that bull: slow but tough. Keep hitting up close.",
                                                          "Speed types rush you. They're fragile - one or two good hits.",
                                                          "Projectile guys like the Barreldugo? Get close and they panic!"]),
                                    "opening_interval": 4.2}, base="Felix")
    lb.hide_spot(2700, G, 120, 110)
    lb.hide_spot(1500, G, 120, 110)
    lb.finish(200, G - 40, "res://scripts/levels/trackers/enemy_type_tracker.gd",
              {"required_types": PSA(["tank", "speed", "projectile"])})

# ===================================================================== CP10
def cp10():
    G = 400; lb = LB(10, "Bull Gauntlet", bg="bg_ship_sky.png", width=4200, objective=EVENT, tracker=True,
                     bounds=RECT(0, -500, 4200, 1220))
    side_walls(lb)
    lb.ground(0, 2800, G, "ground_deck.png")
    for x0, y, w in ((450, 260, 220), (1300, 240, 260), (2150, 260, 220)):
        lb.ledge(x0, y, w, "ledge_wood.png")
    lb.commenter("res://assets/npc/queen.png", 2600, G - 42, ["Stand back, troll!", "These beasts answer to ME.",
                                                               "Hold them... hold them..."], "Queen",
                 {"modulate": C(0.85, 0.85, 1, 0.9), "bubble_height": 80.0})
    lb.commenter("res://assets/characters/Alex/alex_idle.png", 2480, G - 35, ["Whoa, the Queen!", "Keep dodging, CT!"],
                 "Alex", {"modulate": C(0.85, 0.85, 1, 0.9), "flip": True, "first_delay": 5.0})
    for x in (900, 2100):
        lb.enemy("bull_armored.tscn", x, G - 36, {"min_x": 80.0, "max_x": 2720.0}, base="ArmoredBull")
    for x in (1300, 1700):
        lb.enemy("minor_bull.tscn", x, G - 26, {"min_x": 80.0, "max_x": 2720.0}, base="MinorBull")
    add_section(lb, 2800, 4200, G, DECK, seed=10)
    lb.coins_row(480, 640, 225, 3); lb.coins_row(2180, 2340, 225, 3)
    lb.hide_spot(1000, G, 120, 110)
    lb.hide_spot(3600, G, 110, 100, tex="crate_big.png")
    lb.finish(200, G - 40, "res://scripts/levels/trackers/bull_tracker.gd",
              {"need_charges": 4, "need_minor_defeats": 2})

# ===================================================================== CP11
def cp11():
    G = 400; lb = LB(11, "Warm-up Before the Duel", bg="bg_ship_sky.png", width=5200, objective=EVENT, tracker=True)
    side_walls(lb)
    lb.ground(0, 3600, G, "ground_deck.png")
    add_section(lb, 3600, 5200, G, DECK, seed=11)
    for x in (950, 1850, 2950):
        lb.block(x - 28, G - 56, 56, 56, "crate_big.png", base="CargoCrate")
    lb.decor(ENV + "crowd.png", 900, G - 45, {"modulate": C(0.7, 0.7, 0.85, 0.9)}, base="Crowd")
    lb.decor(ENV + "crowd.png", 2600, G - 45, {"modulate": C(0.7, 0.7, 0.85, 0.9)}, base="Crowd")
    lb.commenter("res://assets/characters/Alex/alex_idle.png", 520, G - 35, ["I've got this duel.", "Warm 'em up for me, CT!"],
                 "Alex", {"modulate": C(0.8, 0.8, 0.95)})
    lb.commenter("res://assets/npc/felix.png", 640, G - 32, ["Grab the coins the crowd throws!", "Watch the deck shots!"],
                 "Felix", {"modulate": C(0.8, 0.8, 0.95), "first_delay": 4.0})
    lb.commenter("res://assets/npc/lala.png", 3200, G - 32, ["Fascinating creature, that troll.", "Big Bird is weak up close..."],
                 "Lala", {"modulate": C(0.8, 0.8, 0.95), "flip": True, "first_delay": 7.0})
    xs = [200 + i * 110 for i in range(30)]
    for x in xs:
        if any(abs(x - c) < 40 for c in (950, 1850, 2950)):
            lb.coin(x, G - 100)
        else:
            lb.coin(x, G - 36)
    def extras(s):
        s.node("WaveSpawner", parent=".", instance=SC + "objects/wave_spawner.tscn",
               props={"enemy_scene": Res(SC + "enemies/skull.tscn"), "wave_counts": PIA([2, 2]), "start_delay": 2.5,
                      "delay_between_waves": 3.0, "detect_range_override": 900.0, "spread": 80.0})
        s.node("SpawnA", "Marker2D", parent="WaveSpawner", props={"position": V(1250, 340)})
        s.node("SpawnB", "Marker2D", parent="WaveSpawner", props={"position": V(2650, 340)})
        s.node("DeckShotRight", parent=".", instance=SC + "objects/hazard_emitter.tscn",
               props={"position": V(5140, G - 22), "direction": V(-1, 0), "interval": 4.5, "first_delay": 3.0})
        s.node("DeckShotLeft", parent=".", instance=SC + "objects/hazard_emitter.tscn",
               props={"position": V(60, G - 22), "direction": V(1, 0), "interval": 5.5, "first_delay": 6.0})
    lb.hide_spot(1400, G, 120, 110)
    lb.hide_spot(2400, G, 110, 100, tex="crate_big.png")
    lb.finish(200, G - 40, "res://scripts/levels/trackers/wave_tracker.gd",
              {"spawner_path": NP("../WaveSpawner"), "need_coins": 25, "label": "Clear 2 enemy waves"}, [extras])

# ===================================================================== CP12 / CP13 shared arena
def duel_arena(lb, G, right=3500):
    lb.wall(1200, -700, 720); lb.wall(right, -700, 720)
    lb.ground(1200, 2120, G, "ground_deck.png"); lb.ground(2280, right, G, "ground_deck.png")
    lb.restart_zone(2200, 1000, 700, 400, "Whoa!", base="FallRestartZone")
    lb.decor(ENV + "throne.png", 1300, G - 65, {"modulate": C(0.85, 0.85, 0.95)}, base="Throne")
    lb.decor(ENV + "crowd.png", 1750, G - 45, {"modulate": C(0.65, 0.65, 0.8, 0.9)}, base="Crowd")
    lb.decor(ENV + "crowd.png", 3000, G - 45, {"modulate": C(0.65, 0.65, 0.8, 0.9)}, base="Crowd")

def cp12():
    G = 300; lb = LB(12, "Big Bird Duel", player_scene=SC + "player/player_alex.tscn", bg="bg_ship_sky.png", width=3500,
                     bounds=RECT(1200, -600, 2300, 1220), kill_y=1400.0, objective=DEFEAT, defeat=1,
                     override="Defeat Big Bird")
    duel_arena(lb, G)
    lb.commenter("res://assets/npc/queen.png", 1300, G - 95, ["Show me your shield, Alex.", "Close the distance!"], "Queen",
                 {"bubble_height": 70.0, "first_delay": 6.0})
    lb.commenter("res://assets/characters/CT/ct_idle.png", 1620, G - 32, ["Get close, Alex!", "Shield! SHIELD!",
                                                                         "I can't watch... okay I'm watching."], "CT",
                 {"first_delay": 3.0, "interval_min": 5.0, "interval_max": 8.0})
    lb.commenter("res://assets/npc/lala.png", 1700, G - 32, ["Up close he's helpless!", "Block the boomerang, then strike."],
                 "Lala", {"first_delay": 8.0, "interval_min": 7.0, "interval_max": 11.0})
    lb.enemy("big_bird.tscn", 2600, 200, {"arena_min_x": 2330.0, "arena_max_x": 3440.0}, base="BigBird")
    lb.finish(1500, G - 40)

def cp13():
    G = 300; lb = LB(13, "Coin Scramble", bg="bg_ship_sky.png", width=5000, bounds=RECT(1200, -600, 3800, 1220),
                     kill_y=1400.0, objective=EVENT, tracker=True)
    duel_arena(lb, G, right=5000)
    add_section(lb, 3500, 5000, G, DECK, seed=13, ground=False)
    lb.decor("res://assets/characters/Alex/alex_hurt.png", 2900, G - 30, {"rotation": 0.25}, base="AlexKneeling")
    lb.coins_row(1270, 2080, G - 36, 14); lb.coins_row(2330, 3440, G - 36, 26)
    for x in (1500, 1850, 2500, 2900, 3250):
        lb.hazard(x, -20, "rock.png", {"trigger_size": V(180, 400), "respawn_time": 5.0, "damage": 1})
    lb.finish(1500, G - 40, "res://scripts/levels/trackers/timed_coins_tracker.gd", {"seconds": 75.0, "need_coins": 30})

# ===================================================================== CP14
def cp14():
    lb = LB(14, "Coin Rain on the Deck", bg="bg_ship_sky.png", width=6400, objective=COINS, coin_target=60)
    side_walls(lb)
    for x0, x1, top in ((0, 1100, 400), (1100, 2200, 360), (2200, 3300, 400), (3300, 4400, 340)):
        lb.ground(x0, x1, top, "ground_deck.png")
    scatter_enemies(lb, 600, 4300, 400, DECK, 4, seed=14)
    add_section(lb, 4400, 6400, 340, DECK, seed=14)
    for x in (600, 1700, 2800, 3900):
        lb.decor(ENV + "crowd.png", x, 300, {"modulate": C(0.7, 0.7, 0.9, 0.8)}, base="Crowd")
    random.seed(14)
    for i in range(50):
        x = 120 + i * 85
        lb.coin(x, -100 - (i % 5) * 60, falling=True, delay=round((i % 10) * 1.4 + (i // 10) * 0.6 + random.random() * 0.4, 2))
    lb.hide_spot(1500, 360, 120, 110)
    lb.hide_spot(5300, 340, 110, 100, tex="crate_big.png")
    lb.finish(200, 360)

# ===================================================================== CP15
def cp15():
    G = 400; lb = LB(15, "Tilting Ship", bg="bg_ship_sky.png", width=6000, objective=EXIT)
    side_walls(lb)
    for i, (x0, x1) in enumerate(((0, 1000), (1000, 2000), (2000, 3000), (3000, 3600))):
        lb.ground(x0, x1, G, "ground_deck.png", tint=C(1, 1, 1) if i % 2 == 0 else C(0.9, 0.85, 0.8))
    lb.block(3600, 250, 800, 570, "ground_deck.png", base="TopDeck")
    for x0 in (1150, 2150, 3250):
        lb.ledge(x0, 310, 160, "ledge_wood.png", base="LowLedge")
    for x in (900, 1900, 2800):
        lb.hazard(x, -40, "rock.png", {"trigger_size": V(180, 460), "respawn_time": 6.0, "damage": 1})
    lb.coins_row(1170, 1290, 275, 2); lb.coins_row(2170, 2290, 275, 2); lb.coins_row(3270, 3390, 275, 2)
    scatter_enemies(lb, 400, 3400, G, DECK, 3, seed=15)
    add_section(lb, 4400, 6000, G, DECK, seed=15)
    lb.goal(5850, G - 60, "SAFE", "safe_zone.png")
    def extras(s):
        s.node("CrateA", parent=".", instance=SC + "objects/sliding_crate.tscn",
               props={"position": V(3500, G - 30), "lifetime": 14.0, "start_delay": 1.5})
        s.node("CrateB", parent=".", instance=SC + "objects/sliding_crate.tscn",
               props={"position": V(2400, G - 30), "lifetime": 10.0, "start_delay": 4.0})
        s.node("ShipTilt", "Node", parent=".", script="res://scripts/environment/ship_tilt.gd",
               props={"amplitude_degrees": 4.0, "period": 5.0, "push_strength": 90.0})
    lb.hide_spot(1800, G, 120, 110)
    lb.hide_spot(4900, G, 110, 100, tex="crate_big.png")
    lb.finish(200, G - 40, nodes_after_player=[extras])

# ===================================================================== CP16
def cp16():
    lb = LB(16, "Sand Land", bg="bg_desert.png", width=6400, objective=COINS_AND_EXIT, coin_target=40)
    side_walls(lb)
    sections = ((0, 1100, 420), (1100, 2200, 390), (2200, 3300, 420), (3300, 4400, 400))
    for x0, x1, top in sections:
        lb.ground(x0, x1, top, "ground_sand.png")
    for x in (800, 2000, 3500):
        top = next(t for a, b, t in sections if a <= x < b)
        lb.decor(ENV + "ruins.png", x, top - 64, base="Ruins")
    for (x0, y, w), n in zip(((500, 300, 220), (1450, 270, 220), (2850, 290, 220), (3650, 270, 220)), (4, 4, 4, 3)):
        lb.ledge(x0, y, w, "ledge_rubble.png", base="RubbleLedge")
        lb.coins_row(x0 + 30, x0 + w - 30, y - 34, n)
    for i in range(15):
        x = 200 + i * 285
        top = next(t for a, b, t in sections if a <= x < b)
        lb.coin(x, top - 36)
    for x in (1300, 3000):
        lb.hazard(x, 0, "stone.png", {"trigger_size": V(180, 440), "damage": 1, "hazard_name": "stone",
                                      "debris_color": C(0.8, 0.65, 0.4)})
    scatter_enemies(lb, 300, 4300, 400, SAND, 4, seed=16)
    add_section(lb, 4400, 6400, 400, SAND, seed=16)
    lb.goal(6250, 370, "EXIT")
    lb.hide_spot(1600, 390, 140, 120, tex="ruins.png")
    lb.hide_spot(4800, 400, 140, 120, tex="ruins.png")
    lb.finish(150, 380)

# ===================================================================== CP17
def cp17():
    G = 420; lb = LB(17, "Mayor's Coin Bag", bg="bg_desert.png", width=6300, objective=COINS_AND_EXIT, coin_target=35)
    side_walls(lb)
    for x0, x1, top in ((0, 800, G), (1000, 2200, G), (2400, 3300, G), (3300, 4300, 410)):
        lb.ground(x0, x1, top, "ground_sand.png")
    for cx in (900, 2300):
        lb.s.node(lb.name("QuicksandVisual"), "Sprite2D", parent="Decor",
                  props={"position": V(cx, G + 140), "texture_repeat": 2, "texture": Res(ENV + "quicksand.png"),
                         "region_enabled": True, "region_rect": RECT(0, 0, 200, 260)})
        lb.restart_zone(cx, G + 100, 200, 200, "Quicksand!", base="QuicksandPit")
    lb.commenter("res://assets/npc/lala.png", 260, G - 32, ["CT, read the fine print!", "Careful near the sand pits!"], "Lala",
                 {"first_delay": 5.0})
    lb.coins_row(200, 740, G - 36, 6); lb.coins_row(1060, 2140, G - 36, 8); lb.coins_row(2460, 3240, G - 36, 6)
    lb.coins_row(3380, 3880, 374, 4)
    lb.coins_row(850, 950, G - 140, 2); lb.coins_row(2250, 2350, G - 140, 2)
    for x in (1600, 2900, 3700):
        lb.hazard(x, 0, "stone.png", {"trigger_size": V(180, 440), "damage": 1, "hazard_name": "stone",
                                      "debris_color": C(0.8, 0.65, 0.4)})
    scatter_enemies(lb, 300, 4200, 420, SAND, 4, seed=17)
    lb.hide_spot(2800, 420, 140, 120, tex="ruins.png")
    lb.hide_spot(5000, 410, 140, 120, tex="ruins.png")
    add_section(lb, 4300, 6300, 410, SAND, seed=17)
    lb.goal(6150, 360, "COIN BAG", "coin_bag.png")
    lb.finish(150, G - 40)

# ===================================================================== CP18
def cp18():
    G = 420; W = 15000
    lb = LB(18, "Wormfish Chase", bg="bg_desert.png", width=W, objective=SURVIVE, survive=56)
    side_walls(lb)
    for i in range(10):
        x0 = i * 1500; x1 = W if i == 9 else x0 + 1400
        lb.ground(x0, x1, G, "ground_sand.png")
    for x in range(900, 14500, 600):
        lb.hazard(x, 0, "stone.png", {"trigger_size": V(200, 440), "damage": 1, "hazard_name": "stone",
                                      "shake_time": 0.45, "debris_color": C(0.8, 0.65, 0.4)})
    for x in range(700, 14500, 450):
        if x % 1500 < 1380:
            lb.coin(x, G - 36)
    scatter_enemies(lb, 800, 14000, G, SAND, 8, seed=18)
    lb.decor(ENV + "ruins.png", 14600, G - 64, base="EndRuins")
    def worm(s):
        s.node("Wormfish", parent=".", instance=SC + "objects/chaser.tscn",
               props={"position": V(-150, G), "speed": 364.0, "start_delay": 1.0,
                      "texture": Res("res://assets/enemies/wormfish.png"), "kill_message": "Eaten by the wormfish!"})
    lb.finish(300, G - 40, nodes_after_player=[worm])


if __name__ == "__main__":
    for f in (cp01, cp02, cp03, cp04, cp05, cp06, cp07, cp08, cp09, cp10, cp11, cp12, cp13, cp14, cp15, cp16, cp17, cp18):
        f()
    print("levels done")
