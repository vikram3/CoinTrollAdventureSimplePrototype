# Coin Troll Adventure - Godot 4.7 prototype

Built from *Coin Troll Adventure - Game Design Document*. Open `project.godot` in Godot 4.7.x and press F5.
The first open imports all PNGs (takes a few seconds).

## What's in it
- 18 playable levels (`scenes/levels/level_01..18.tscn`), each with one objective (types 0-6 from the GDD).
- Playable: CT (top-down naked CT in 01, platformer naked CT in 02, suit CT in 03-18) and Alex (12).
- Enemies: Skull, Elite Skull, Shadow avatar, Barreldugo, Horn, Bull, Minor bull, armoured (invulnerable) bull,
  Big Boss (idle/jump/fall/windup/slam/slash/stagger/story, 0.8 s telegraphs), Big Bird with tracking boomerangs,
  chasers (forest chaser, wormfish), falling rocks/logs/stones/hedge traps, sliding crates.
- Companions: Felix (follows, tips, warnings), Pink Girl (duels Big Boss, blocks = counter-stagger).
- Speech bubbles with no-repeat line pools; trigger line at every level start.
- HUD (coins / objective / timer pulse under 5 s / health / pause button, fades when CT is under it),
  pause menu, level-complete banner, restart fade, main menu with level select and save,
  cinematics between levels (still panels + speech, Space to advance, Esc to skip).
- Placeholder sound effects are synthesized at runtime (`scripts/autoload/sfx.gd`).

## Controls
CT: A/D or arrows to move (WASD/arrows in the maze), Space/K/W/Up to jump, J/X/Enter to attack.
CT extras: press jump again in the air to double jump; Shift or C to dash; hold Q or Ctrl on the ground to block front hits (not from above). Mouse: left click attacks, hold right click to block.
Alex: arrows to move, Space jump, Down shield, Up bow, Enter/J combo attack.
Esc/P pause, R restart level.

## Project layout
```
assets/      placeholder art - replace files with same names (characters/CT is the CT animation set)
scenes/      environment, player, enemies, objects, npc, ui, cinematics, levels
scripts/     autoload (GameState, Sfx), data (StoryData: levels + cinematic scripts),
             core, player, enemies, objects, npc, ui, environment, levels (+ objective trackers)
tools/       Python generators used to build the art and scenes (optional, not needed in Godot)
```
Environment pieces are plain sprites (`scenes/environment/block.tscn`, a tool script - set Size and
Tile Texture in the inspector), no tilesets. Animations: every player uses an AnimatedSprite2D whose
animations (idle/run/jump/fall/attack/hurt) currently hold one static frame each - add frames later.

Collision layers: 1 world, 2 player, 3 enemies, 4 hazards, 5 pickups, 6 player attack, 7 allies.

## Notes / deviations from the GDD
- Level 01 is a top-down maze (per the project notes) - win: 20 coins or the exit.
- Level 07: a Horn knockback off the edge completes the level (scripted fall); a plain fall restarts.
- Level 14 uses the same trigger line as 18 because the GDD lists it that way - likely a copy error.
- Level 19's track is 10 decks (15000 px) with a 56 s survive at 280 px/s.
- Level 09 / 19 chasers have a 1.2 s / 1.0 s start delay for fairness (positions and speeds as in the GDD).
- Level 06 (Pink Girl duel) and 13 (Big Bird duel) keep their fixed arenas; the other levels were extended.
- Big Bird uses health (12) instead of five close-range hits; arrows only hurt him from close-ish range.
- Not built (as in the GDD): hold-to-grab poles, sand slowdown, Alex bubble shield/thunder items,
  CT damage bonus rules, cinematic panel art (placeholders are used).

## Longer levels, obstacles and cinematics (latest pass)
- Every side-scrolling level is longer, with new sections of pillars, reachable ledges, hazard drops, enemies and crates
  (`add_section` in `tools/gen_levels.py`; re-run `python tools/gen_levels.py` to rebuild the scenes).
- Level 01's maze is bigger (13 x 9 cells).
- A cinematic now plays after every level from 01 to 17.
- Big Boss: airborne watchdog (2.2 s), respawn if he leaves the arena, and capped jump speed, so attacks can't freeze.

- Mobile/tablet: on-screen buttons appear automatically on touch devices (D-pad + HIT in the maze, LEFT/RIGHT/HIT/JUMP in platformer levels, plus SHIELD/BOW for Alex). Set `always_show` on the TouchPad node to test on desktop.
- Hiding: bushes and crates (HideSpot) let CT hide. Stand in one and hold DOWN (HIDE on touch). Hidden CT is ignored by enemies and can't be hurt. Hiding spots are in levels 03, 08, 10 and 12.
- More hiding spots added across levels 03, 05, 07, 08, 09, 11, 15, 16, 17 and 18.
- More bushes added to levels 03, 07 to 12, 15 to 18. Hold DOWN inside a bush to hide.
