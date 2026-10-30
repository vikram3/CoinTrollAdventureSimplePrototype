# Coin Troll Adventure — Project Audit

Audit date: 30 October 2026. Scope: static review of the Godot project, story data, all 24 level scenes, objective wiring, player flow, and cinematic sequencing. A full runtime pass was not possible because Godot is not installed on this workstation.

## Executive verdict

The prototype has a clear, potentially fun foundation: a coin-obsessed underdog moves through short action-platforming challenges, learns mobility and combat moves, and meets a growing cast. The strongest material is Chapters 1–4, where mechanics, objectives, and story usually reinforce each other.

It is **not yet release-ready**. Four levels cannot complete through their designed objectives, progression abilities are not saved, Chapter 5–8 reuse too much earlier gameplay, and several cinematics are placed after the event they need to set up. The game has a good vertical-slice core, but not yet a coherent 24-level campaign.

## Core loop

```text
Read immediate objective → move / jump / dodge / fight → collect coins
        → reach goal or clear challenge → short reward / story beat → next challenge
```

The controls support this loop well: responsive running, jumping, double jump, dash, blocking, melee and coin feedback. Coins fit CT's motivation and create a natural risk/reward layer. The missing piece is meaningful long-term coin use: coins currently gate/select objectives and record a best score, but do not purchase upgrades, unlock routes, alter scenes, or affect the ending. As a result, collection loses importance once the target is met.

## Release blockers and technical risks

| Priority | Finding | Player impact | Recommended action |
| --- | --- | --- | --- |
| P0 | Levels 6, 10, 11 and 12 use `EVENT` objectives and have a `Tracker` node, but leave `tracker_path` empty. `Level` only loads a tracker when this path is set, so its event objective never becomes complete. | The campaign can hard-stop at Level 6; Levels 10–12 are also unwinnable by design. | Set `tracker_path = NodePath("Tracker")` on all four root Level nodes and run a full completion pass. |
| P0 | Progression abilities are only held in `GameState.abilities`; save/load only persists level unlock, best coins and difficulty. | Continuing a save at a later level can remove double jump, dash, block and advanced moves; level select can bypass their tutorials. | Persist abilities, or deterministically grant the chapter's required kit when loading a level. |
| P1 | `DEV_TOOLS` is true and release-facing menus expose level skipping/unlock-all controls. | Players can bypass the campaign and testing results become unreliable. | Disable/remove before any external build. |
| P1 | The supplied validator reports an unresolved `get_node("CollisionShape2D")` reference in `falling_hazard.gd`. | A falling-hazard scene may error or behave incorrectly at runtime. | Fix the node path, then rerun validation and headless scene checks. |
| P1 | Full runtime validation could not be performed in this environment because no Godot executable is on PATH. | Static analysis cannot prove collision, spawn, checkpoint, boss and cinematic behavior. | Run the project’s `check_all.gd`, `check_levels.gd`, one clean playthrough, and an Android touch pass in Godot 4.7. |

## Story and character flow

| Character | Current flow | Assessment / needed clarification |
| --- | --- | --- |
| CT | Coin collector → chest incident / suit → learns moves → travels with Flex’s group → contract in Sand Land → faces Ahrena’s gate. | Strong protagonist motivation at the start. The coin motive needs to remain materially relevant after Chapter 1; the contract must be shown before its gameplay consequence. |
| Big Boss | Introduced as the threat after the chest; pursues CT; beaten back by Pink Girl. | A good early antagonist, but his later relevance fades rather than resolving or evolving. |
| Pink Girl | Arrives to block Big Boss and wins the confrontation. | Good entrance, but the playable level does not make her support mechanically central; make the player defend/enable her or briefly play as her. |
| Flex / Felix | Flex introduces the travel/forest phase; scenes and triggers use both “Flex” and “Felix.” | Pick one name and use it consistently. The current identity/role is ambiguous. |
| Alex / Tex | Level 13 says Alex accepted a duel and uses Alex as the player. Level 20 is titled “Tex vs Sacavuelo,” but also uses Alex’s player scene. | This is a major character-continuity problem. Decide whether Alex and Tex are the same person, rename the level, or add a Tex player scene and handoff cinematic. |
| Queen / Reina de Viento | Queen enters Chapter 4; Reina is introduced in Chapter 5; Queen later holds up the ship. | Clarify whether “Queen” and “Reina” are the same person. If so, use one display name plus a deliberate reveal; if not, introduce them separately. |
| Lala / Mayor / Ahrena | Lala warns CT, Mayor offers a contract, Ahrena becomes the Chapter 8 threat. | This is the cleanest late-game objective chain in concept, but its cinematic order presently reveals the contract and worm threat too late. |

## Level-by-level objective and story fit

| Levels | Intended play | Fit | Audit note |
| --- | --- | --- | --- |
| 1 — Bush Maze | Collect 40 coins and exit. | Good | Strong coin-first tutorial and a clear CT motive. The top-down opening is an abrupt control/camera change before the rest of the side-scroller. Explain it as a prologue or start side-scrolling immediately. |
| 2 — Tower Climb | Reach the top. | Good | A direct, readable escalation; its post-level cinematic points to the chest well. |
| 3 — Treasure Chest Chase | Collect 22 coins and reach the chest under a 90-second limit. | Good, but overlong transition | The objective matches the story. Its chained post-level sequence contains 31 panels (chest, Chapter 1 outro, shadow storm, Chapter 2 intro), which is a large pace break. Split it with an intermission or reduce it to 8–12 essential panels. |
| 4 — Training Yard | Exit through a tutorial route. | Good | Correct place to teach double jump, dash, block and combo. Ensure each station is unavoidable or its skill is not mandatory later. |
| 5 — Big Boss Dodge | Survive 60 seconds while pursued. | Good mechanically; metadata mismatch | StoryData calls it “Big Boss Dodge,” but the scene completion label is “Rooftop Chase.” Use one name. It also teaches four more moves during a pressure encounter, which is too dense; teach one per safe beat. |
| 6 — Pink Girl vs Big Boss | Clear waves. | Broken | The scene title/trigger differ from StoryData, and the missing tracker path makes it unwinnable. Connect the wave goal to Pink Girl’s fight—e.g., protect her while she charges a finisher. |
| 7 — Cliff Ambush | Be knocked off by Horn to complete. | Good idea, unclear execution | The scripted fall is a memorable inversion, but the HUD says “Reach the exit” because it uses an EXIT objective. Override the text to “Escape Horn” / “Survive the ambush.” |
| 8 — Forest Walk | Reach exit with Felix. | Adequate | A good decompression level, though “Flex” in dialogue and “Felix” in assets/scenes are inconsistent. |
| 9 — Forest Chase | Reach exit while chased. | Good | Sound core-loop variation; give Horn a visible chase meter or escalating hazards so failure feels legible. |
| 10 — Enemy Types | Defeat tank, speed and projectile enemies. | Broken but well designed | Excellent learning objective, but event tracker is disconnected. This should be the model for objective-to-story alignment. |
| 11 — Bull Gauntlet | Survive charges and defeat minor bulls. | Broken | The custom objective is a good mastery test, but tracker is disconnected. Add stronger telegraphs and a clear charge/defeat HUD. |
| 12 — Warm-up Before Duel | Clear waves. | Broken / redundant | Tracker is disconnected. “Warm-up” immediately before a boss is structurally sensible, but waves repeat Level 6; teach a boss-specific answer instead. |
| 13 — Big Bird Duel | Defeat Big Bird as Alex. | Good fight; weak handoff | The close-range weakness and boomerang pressure create a real combat loop. The Alex playable handoff needs an explicit pre-level cinematic and UI cue. |
| 14 — Cabin Gathering | Survive 60 seconds and collect 20 coins. | Mechanically sound; late setup | This tracker is wired correctly. Its 17-panel Chapter 5 introduction plays after this level, so players complete “Cabin Gathering” before the group/story is introduced. Move the intro before Level 14. |
| 15 — Sacavuelo on the Deck | Collect 60 coins. | Poor fit | The story says to close distance on a ranged enemy, but the objective is only coin collection. Make this a boss damage/defeat objective, or explicitly frame coins as ammunition/ship repairs. |
| 16 — Battle Station Run | Reach exit. | Adequate | Works as movement respite, but it needs a new set-piece rather than another reused run. |
| 17 — Reina’s Airship | Collect 40 coins and reach exit. | Weak fit | “Dodge the winds” is not represented in the objective. Add wind-gust timing, airborne routing, or a survival/escort target. |
| 18 — Mayor’s Coin Bag | Collect 35 coins and exit. | Story order is wrong | The Mayor’s contract cinematic plays after the player has already acted on it. Move it before Level 18; then make the bag/contract visible in-level. |
| 19 — Wormfish Chase | Survive 56 seconds. | Story order is wrong | The Chapter 6 intro with the arena duel plays after the wormfish level. Put the worm reveal immediately before this chase and use its 56 seconds to build escalation. |
| 20 — Tex vs Sacavuelo | Defeat Big Bird using Alex player scene. | Good boss loop; continuity error | It reuses Level 13’s boss/arena design and appears to feature Alex, not Tex. Differentiate its moves, arena and character identity. |
| 21 — Burning Ship | Reach exit. | Good | Clear emergency objective and appropriate pace increase. Add visible fire spread or collapse so the fiction drives the route. |
| 22 — Queen’s Lift | Collect 40 coins and reach exit. | Weak fit | The text says “help her keep it steady,” but coins + exit do not embody assistance. Replace with stabilizer interactions, survival, or escort progress. |
| 23 — Dune Road | Reach exit. | Adequate | Falling stones match the story text. It is an appropriate final approach, but needs a setup cinematic before it rather than the Chapter 8 intro after Level 22 if the transition is intended to be immediate. |
| 24 — Ahrena’s Gate | Survive 40 seconds. | Incomplete finale | This is a decent climax setup but not a final confrontation: Ahrena never becomes a playable boss objective and the ending says “To Be Continued.” Add a distinct Ahrena phase, a resolution beat, or label the prototype explicitly as Episode 1. |

## Cinematic sequencing assessment

The cinematic system itself is sound: players can advance, navigate, and skip. The issue is editorial sequencing and pacing.

- Keep: Level 2 → tower reveal → Level 3; Level 7 → fall → Level 8; Level 9 → Chapter 4 intro → Level 10; Level 20 → Chapter 7 transition → Level 21; Level 22 → Chapter 8 intro → Level 23.
- Move earlier: `chapter5_intro` before Level 14; `mayor_contract` before Level 18; the worm reveal before Level 19; a short Alex/Tex handoff before Levels 13 and 20.
- Shorten: the post-Level-3 chain (31 panels) and Chapter 5’s 17-panel introduction. The first playthrough should rarely require more than 30–45 seconds of unskippable reading between active levels.
- Add: a cinematic after Level 24 that pays off the Ahrena threat. “To Be Continued” is viable only if it follows a completed chapter goal, not the promise of a fight that never occurs.

## Recommended production order

1. Fix the four event tracker paths and the falling-hazard node reference; verify every level can be completed from a clean save.
2. Persist or deterministic-grant abilities and remove release-facing developer controls.
3. Normalize canonical names: Flex/Felix, Alex/Tex, Queen/Reina; make StoryData and scene titles match.
4. Recut cinematics so each setup happens before its gameplay and reduce long consecutive panel sequences.
5. Rebuild Chapters 5–8 around distinct mechanics: wind routing, ship stabilization, worm chase, contract consequence, then an Ahrena boss.
6. Give coins a lasting purpose—upgrade choices, optional routes, rescue/repair thresholds, or ending variation—without making the critical path grindy.

## Minimum acceptance test for the next build

- New game through Levels 1–24 on a fresh save, without developer skip.
- Quit after Levels 4 and 5, then Continue; verify acquired moves remain available.
- Complete Levels 6, 10, 11 and 12 using their on-screen event objectives.
- Verify each cinematic occurs before the action it introduces and that the Level 3 transition is paced acceptably.
- Confirm every playable-character switch is named and explained in both cinematic and HUD.
- Test keyboard, mouse, touch controls, checkpoints, easy/medium/hard timers, and Android export.
