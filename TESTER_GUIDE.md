# Coin Troll Adventure — tester build r2

Run builds/CoinTroll-Tester-r2.exe. This Windows build includes all previous fixes plus tester navigation. Keep your older build for comparison.

## Navigation

- Main menu → Test any level: all 24 levels are available immediately.
- F3 or Pause → Next level: skip directly to the following level without a score or completion credit.
- F4 or Pause → Previous level: go back; level 1 stays at level 1.
- Skipping level 24 returns to the main menu.
- Esc/P pauses; R restarts. Cinematics have Skip and panel navigation.
- Difficulty is selected in the main menu. Starting a later level supplies the abilities taught earlier.

## Feedback

Report the build label shown in the HUD, level number, difficulty, controls used, expected behavior, actual behavior, and steps to reproduce. Screenshots/video help with collision or camera problems.

Local event records are stored in Godot's user-data folder as playtest_events.jsonl, typically %APPDATA%/Godot/app_userdata/Coin Troll Adventure/. Events include starts, skips, failures and completions. No telemetry is uploaded. Tester saves use coin_troll_test_levels.cfg, separate from normal campaign saves.

## Suggested test pass

Start with levels 1–6 in order, then test event objectives in 10–12, Alex/Tex controls in 13 and 20, wind timing in 17, ballast delivery in 22 and the gate finale in 24. Repeat critical objectives on Easy and Hard. Check pause/resume, restart, skip while paused, level selection, and Continue after closing the game.

This is a prototype test build. The Ahrena boss, bespoke Tex art, and broader campaign redesign remain unfinished. Automated load/smoke checks do not prove that every route is beatable or replace human playtesting.
