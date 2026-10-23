# Coin Troll Adventure - Godot 4.7 prototype

Open `project.godot` in Godot 4.7.x and press F5. The first open imports all PNGs (takes a few seconds).

## Chapters and levels
The game is 8 chapters, 24 levels. Each level's scene lives in its chapter folder under `scenes/levels/`.
Level order, objectives, trigger lines and the cinematics that play around each level are in `scripts/data/story_data.gd`
(`LEVELS`, `CHAPTERS`, `CINEMATICS`). Cinematic keys joined with `+` play in order after that level.

| Chapter | Levels | Folder |
| --- | --- | --- |
| 1 | 1-3 Bush Maze, Tower Climb, Treasure Chest Chase | `chapter_01/` |
| 2 | 4-6 Shadow Arena, Big Boss Dodge, Pink Girl vs Big Boss | `chapter_02/` |
| 3 | 7-9 Cliff Ambush, Forest Walk, Forest Chase | `chapter_03/` |
| 4 | 10-13 Enemy Types, Bull Gauntlet, Warm-up, Big Bird Duel | `chapter_04/` |
| 5 | 14-17 Cabin Gathering, Sacavuelo on the Deck, Battle Station Run, Reina's Airship | `chapter_05/` |
| 6 | 18-20 Mayor's Coin Bag, Wormfish Chase, Tex vs Sacavuelo | `chapter_06/` |
| 7 | 21-22 Burning Ship, Queen's Lift | `chapter_07/` |
| 8 | 23-24 Dune Road, Ahrena's Gate | `chapter_08/` |

Comic panels for each chapter are in `assets/comic/chN/`. Placeholder art and sound are used where final art is missing.

## Controls
CT: A/D or arrows to move (WASD/arrows in the maze), Space/K/W/Up to jump, J/X/Enter to attack.
CT extras: press jump again in the air to double jump; Shift or C to dash; hold Q or Ctrl on the ground to block front hits (not from above). Mouse: left click attacks, hold right click to block.
Esc/P pause, R restart level. Hold DOWN in a bush or crate to hide.
On touch devices, on-screen buttons appear automatically. Set `always_show` on the TouchPad node to test on desktop.

## Project layout
```
assets/      art, sound and comic panels (assets/comic/ch1..ch8)
scenes/      environment, player, enemies, objects, npc, ui, cinematics, levels/chapter_01..chapter_08
scripts/     autoload (GameState, Sfx), data (StoryData: levels, chapters, cinematics),
             core, player, enemies, objects, npc, ui, environment, levels (+ objective trackers)
tools/       checks and build helpers (see below)
```

Collision layers: 1 world, 2 player, 3 enemies, 4 hazards, 5 pickups, 6 player attack, 7 allies.

## Checks
Run these headless from the project folder to catch broken scripts or scenes before playtesting:
- `tools/godot_checks/check_all.gd` loads every script.
- `tools/godot_checks/check_levels.gd` loads every level listed in `StoryData.LEVELS` and every cinematic key it uses.

## Notes
- Chapter 4 levels 10-13 keep their original layouts. Chapters 5-8 reuse some earlier layouts with new names and story text.
- Level 20 reuses the Chapter 4 Big Bird arena, with CT as the player. It doesn't have a Sacavuelo enemy yet.
- `tools/gen_*.py` and `tools/tscn.py` are old generators for the earlier flat level layout. Don't run them on the current chapter scenes, because they would overwrite the chapter levels.
