# Playtest update

## Latest Windows build

Run `builds/CoinTroll-Playtest.exe`. Godot 4.7.2 was downloaded from the official Godot GitHub release and used to build this update. Engine checks loaded all 62 scripts and all 24 level scenes with zero reported problems. The training-yard runtime harness ran 300 frames successfully. This does not constitute a complete human playthrough.

Reina's Airship now has warning / gust / calm phases with shelter protection. Queen's Lift now explains the ballast delivery objective and requires enough coins before accepting delivery at the exit. Existing source and earlier exports are retained.

The older environment/export limitations below describe the previous update and are superseded for Windows by this section. Android has not been rebuilt.

## Changes

- Event objectives now resolve the existing Tracker node by default, repairing levels 6, 10, 11 and 12.
- Starting a level reconstructs the abilities taught in preceding levels. This supports old saves, Continue and level select, and resets the kit for a new prologue.
- Easy survival objectives are shorter; Hard survival objectives are longer. Timed coin challenges use difficulty-adjusted targets and deadlines.
- Checkpoint respawn preserves collected coins because scene pickups remain consumed. A timed coin failure performs a full restart.
- Cinematic Next is on-screen. Boss briefing precedes the duel, the Chapter 5 introduction precedes its first level, and the Mayor's contract precedes its consequence.
- Added a wormfish warning and a gate-defense payoff. The end is explicitly Episode 1; an Ahrena boss is still future content.
- Objective labels respect difficulty targets; Alex and Tex fights show controls. Tex still uses placeholder Alex artwork/controller.
- Developer menu shortcuts are disabled; debug-build F3/F4 remain available for testing.

## Run the updated project

Open project.godot in Godot 4.7 and press F5. The existing EXE and APK predate these changes and have NOT been rebuilt. No Godot editor/export executable was found on PATH or in the searched Desktop, Downloads, AppData/Local and Program Files directories.

Static validation: python tools/validate.py reports NO ERRORS. This is not a runtime or collision verification.

In Godot run tools/godot_checks/check_all.gd and check_levels.gd headless, then test fresh-game progression, all four event levels, checkpoint deaths, Continue into levels 5–6, cinematic touch navigation, and each difficulty.

## Remaining design work

The campaign still needs distinctive late-chapter layouts and mechanics, Tex artwork, editorial review of comic dialogue, touch-device playtesting, and a decision on a full Ahrena boss. These changes are a correctness update, not a completed campaign redesign.

## Corrections to the original audit

The falling-hazard node exists; the original warning was a validator limitation with a relative child lookup. The lookup now uses an explicit root-relative path. No broken hazard node was found. Level 14 actually configures 75 seconds / 30 coins on Medium, overriding the tracker's defaults. No installed engine could be established from the search; absence from PATH alone does not prove Godot is uninstalled.
