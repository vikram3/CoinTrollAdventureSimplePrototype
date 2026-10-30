# Coin Troll Adventure — campaign redesign specification

Status: proposed playable design, not implemented layouts. Supersedes “make the current levels longer” as a production direction. Existing r4 remains the comparison build. All durations below are initial tuning targets, not measured results.

## Game identity

An expressive action-platformer about a greedy little skeleton whose pursuit of coins pulls him into other people's problems. The player should feel clever for reading a threat, committing to a route, and escaping with the money. Comedy should come from the contrast between CT's motives and the consequences of his actions.

Three design pillars:

1. Read, commit, recover: every dangerous action has a readable cue, a decision, and a recovery opportunity.
2. Greed changes the route: the safe route finishes the mission; valuable coin routes ask for mastery.
3. Play the story: a rescue requires rescuing, a duel requires fighting, and stabilizing a ship requires stabilizing it.

The core loop is observe a space → choose safe or greedy route → execute movement/combat → collect feedback/reward → reach a new situation. Keep generic coin quotas out of escape and rescue missions.

## Campaign structure and pacing

Keep 24 levels for this iteration, grouped into eight three-act story movements where chapter lengths may differ. Target roughly 90–140 minutes for a first successful campaign excluding repeated deaths and optional exploration. Most levels should take 3–5 minutes on a first successful attempt; traversal introductions can be shorter and boss encounters depend on mastery. Do not enforce duration with an arbitrary wait timer.

Each level has three to five authored spaces. A space contains one main decision; not every screen needs an enemy. Use a safe opening, a demonstration of the level mechanic, a combination challenge, a safe checkpoint, and a final test. Boss and chase levels may deliberately use a different structure.

## All 24 level briefs

| # / level | Story purpose and win condition | Authored progression | Signature decision / optional reward | Initial time target |
| --- | --- | --- | --- | --- |
| 1 — Castle Gardens | CT steals a purse and reaches the tower entrance. | Safe movement courtyard → visible skull patrol → hedge shelter demonstration → two-route garden → purse and exit. | Cross the open courtyard between patrols for a bonus chest, or take the longer hedge route. Keep the existing top-down view only as a clearly labelled prologue. | 3–4 min |
| 2 — Tower Lookout | Find the treasure's location from the lookout. | Safe jump lesson at the base → alternating ledges → first moving threat → midpoint balcony checkpoint → final stair/ledge climb. | Side balconies reward coins but never hide the main upward route. Falls land on earlier balconies except at clearly marked dangerous edges. | 3–4 min |
| 3 — Race to the Chest | Reach and interact with the treasure before the rival. | Rival shown on a separate visible route → forgiving opening jumps → two shortcuts → checkpoint at the final approach → chest interaction. | Coins on slower routes tempt the player to risk losing the race. Remove the mandatory 22-coin quota. Represent the rival's progress visibly; tune a generous first-run margin. | 3–4 min |
| 4 — The Suit Awakens | Learn the suit's core movement by escaping a practice courtyard. | Safe double-jump room → dash gap with recovery floor → shield demonstration using one visible cannon → combined traversal room → exit. | Optional medal route requires using both movement skills. Teach combo later rather than adding four instructions at once. Completion checks successful use, not merely walking through tutorial areas. | 3–4 min |
| 5 — Big Boss Pursuit | Escape Big Boss to the courtyard where Pink Girl intervenes. | Visible boss arrival → run through falling debris → boss attack breaks a gate → midpoint refuge → final escape into the arena. | A coin route above the main path is faster but demands a precise jump. Replace passive survival with forward progress; boss pressure follows the route and cannot spawn ahead of the player. | 3–4 min |
| 6 — Hold the Flanks | Help Pink Girl defeat Big Boss. | Demonstrate her shield's safe zone → stop one flanking group → clear debris from her retreat → two-direction pressure → her finishing attack. | Leave the shield to recover a supply cache, then return before the next telegraphed attack. Three visible support stages replace unrelated waves; finish only when the support task enables her victory. | 4–5 min |
| 7 — Horn's Ambush | Escape an ambush that ends in a scripted cliff collapse. | Horn introduced at a safe distance → charge into breakable cover → dodge through ruins → checkpoint → final charge breaks the ledge. | Bait Horn into an optional coin wall. Do not require the player to discover that getting hit is the win condition; the collapse triggers from reaching the story beat. | 3–4 min |
| 8 — Flex's Forest Trail | Follow Flex to the camp and learn the route. | Rescue/introduction before play → low-pressure forest path → log warning demonstration → fork with visible reunion point → camp. | Explore a side grove while Flex waits at a safe landmark. This is deliberate recovery after the chase, not another dense combat gauntlet. | 3–4 min |
| 9 — Forest Escape | Outrun Horn and reach the crew's boarding point. | Chase preview → branch obstacles → shelter-based breath point → chase resumes with a new hazard combination → boarding platform. | Short upper route versus reliable lower route. Chase distance is visible; checkpoints restart the local chase segment consistently. | 3–4 min |
| 10 — Know Your Enemy | Prove CT can handle three enemy roles. | Separate tank room → speed enemy room → ranged enemy room → checkpoint → mixed room → exit. | Each room demonstrates one weakness with space to experiment; optional mastery medals reward no-hit clears. UI names the enemy role and shows the room's objective. | 4–5 min |
| 11 — Bull Crossing | Cross Reina's guarded route without fighting the invulnerable armored bulls. | Single charge lane → refuge islands → charge breaks a barrier → minor-bull fight → alternating charge lanes → safe gate. | Use a dangerous central lane for bonus coins. Telegraph armored versus vulnerable bulls with distinct silhouettes/marks, not color alone. | 4–5 min |
| 12 — Duel Preparation | Prepare Alex for a projectile specialist. | Explicit character handoff → safe shield practice → reflect a slow shot → close distance on a practice opponent → checkpoint → short mixed rehearsal. | Reflection chain earns a medal. This teaches Alex's controls and the boss answer rather than repeating CT's wave fight. | 3–4 min |
| 13 — Big Bird Duel | Alex defeats the challenger. | Wide readable arena → aimed throw phase → recovery opening → arena changes at half health → combined pattern → victory. | Reflecting a shot creates a longer opening; dodging and approaching is always viable. No unrelated enemies count toward the boss objective. | 4–6 min |
| 14 — Cabin Trouble | Recover the crew's scattered cargo before departure. | Introduce three named cargo items → open hub with short cabin branches → one movement branch, one patrol branch, one crate branch → deliver cargo → departure. | Coins sit along optional detours. Replace “wait 75 seconds with 30 coins” with tangible items and visible delivery progress. | 4–5 min |
| 15 — Deck Battery | Silence the hostile deck weapon so the ship can move. | Cannon shown firing into cover → safe cover-to-cover demonstration → second lane with different timing → checkpoint → flank and disable battery. | An exposed upper route reaches the switch faster. Make cannon destruction/disable visible. Do not describe a Sacavuelo duel while asking only for coins. | 4–5 min |
| 16 — Battle Stations | Reach and activate three stations during a ship attack. | Station 1 on a stable deck → tilted cargo section → station 2 behind a timed volley → checkpoint → lower-deck route → station 3 and alarm payoff. | Safe lower lane versus risky deck-top coin route. Each activated station visibly reduces a threat; progress changes the level rather than just incrementing a counter. | 4–6 min |
| 17 — Wind Passage | Use Reina's wind corridor to reach the rendezvous. | Show calm/gust cycle with flags → safe tailwind jump → crosswind shelter route → checkpoint → alternating gust directions → landing platform. | Tailwind-assisted upper coins reward timing. Gust direction and start are visible before the player commits; mandatory jumps remain possible with the expected kit. | 4–5 min |
| 18 — The Mayor's Bargain | Recover a sealed payment bag after seeing the contract. | Contract setup → market plaza → two connected ruin routes → guarded bag → return shortcut → delivery confrontation. | Greedy side caches have no effect on mandatory completion. One unique bag, not a generic coin quota. The story states why this settlement is reachable before the later Sand Land arrival. | 4–5 min |
| 19 — Wormfish Escape | Escape the wormfish to a rock refuge. | Ground-ripple demonstration → safe rock islands → worm breaks a route behind CT → checkpoint → timing challenge on open sand → refuge. | Risk exposed sand for a faster route. Worm attacks are location-based, telegraphed and tied to movement; no surviving safely in a corner until a timer expires. | 3–4 min |
| 20 — Tex's Duel | Tex defeats Sacavuelo using his own combat identity. | Explicit handoff and safe control prompt → ranged pressure → counter/close-range opening → second phase with a moving arena hazard → victory. | Tex gets a distinct silhouette and gadget interaction. If bespoke Tex controls/art are out of scope, do not ship the level as Tex while silently using Alex. | 4–6 min |
| 21 — Burning Ship | Reach the rear evacuation point with the crew. | Fire starts visibly behind the player → first rescue interaction → blocked deck requires a lower route → checkpoint → final rescue → evacuation platform. | Optional coins near the advancing fire create risk. Rescue NPCs move to safety and appear in the completion scene. | 4–5 min |
| 22 — Queen's Lift | Activate three stabilizers while Reina supports the ship. | See ship list and first stabilizer → route to port stabilizer → first activation slows the tilt → checkpoint → starboard stabilizer under debris → final control at the bow. | Optional repair cache improves final score. Each stabilizer has a visible state and changes tilt/debris intensity. Replace the ballast-coin reskin with actual interactions. | 4–5 min |
| 23 — Dune Road | Reach Ahrena's gate and learn the finale's sand attacks. | Palace visible in the distance → warning stone falls → sand-wave practice → checkpoint → mixed sentinel encounter → gate approach. | A marked shrine route grants a final mastery medal. This prepares the boss, not another unrelated skull corridor. | 4–5 min |
| 24 — Ahrena's Challenge | Resolve CT's contract by defeating Ahrena. | Short gate defense → checkpoint and boss entrance → sand-wave phase → clear counterattack windows → second phase combining learned attacks → contract breaks and reward payoff. | No unseen attacks or generic survival-only finale. If this boss is not built, end the episode explicitly before this promise and remove “defeat Ahrena” from the current campaign goal. | 6–8 min |

## Layout and encounter rules

Use the existing movement values as a starting envelope, then measure jumps in the running game. A naked CT jump at -760 velocity and 1900 gravity has an ideal ballistic rise around 152 pixels before collision and variable-height input effects. Mandatory early jumps should sit comfortably inside that envelope; do not use the theoretical maximum as the default gap. Test Alex separately because his run speed and control scheme differ.

- Show the landing surface before a mandatory jump. Never put a first-time enemy on a blind landing.
- Opening screen: safe floor, visible forward direction, one landmark and one actionable goal.
- Introduce a hazard alone, repeat it with a variation, then combine it with another learned hazard.
- Keep enemies out of checkpoint respawn volumes. Provide enough safe space to regain orientation.
- Place checkpoints after meaningful mastery, usually every 45–75 seconds of successful play; chase segments need shorter recovery costs.
- Mark main route with consistent warm goal lights; use coin arcs for optional movement rather than placing them randomly across the screen.
- At a branch, both entrances should be visible. The risky route should visibly promise a reward and rejoin the main route.
- Shelters must have a consistent visual silhouette. Avoid labelling every decorative crate as safe.
- Projectile sources need visible barrels/muzzles and readable startup. First shots must not arrive before the player sees the source or warning.
- Track objective completion explicitly: a dead named boss, an activated station, an item delivered, or a reached escape point. Never substitute total kills for defeating a particular boss.

## Narrative and control continuity

Create one authoritative character roster before rewriting dialogue. Use Flex as the player-facing name consistently; internal Felix filenames can remain until an asset migration is justified. Reina is introduced as “Reina, Queen of Winds,” then addressed as Reina. Alex and Tex remain separate people. Both playable switches need a pre-level introduction and a control card that can be dismissed by the player, with gameplay paused while reading.

Every level has a short brief containing: who am I, where am I going, why, and what ends the mission. Display progress during play and retain the brief in Pause. Put setup before the level and consequence after it. Prefer 2–5 essential panels at a transition; keep extra comic material in an optional gallery. Readability options should include manual advance, adjustable text size, and reduced motion.

The current late-chapter travel/contract order needs an editorial pass. Do not present a location as reached for the first time after already playing there. Either establish Level 18 as a different settlement/advance contract or move that contract beat into the actual Sand Land arrival. Choose the final story order before laying out those chapter transitions.

## Reward design

Mandatory objectives unlock levels. Optional coins contribute to a best-run score and visible bronze/silver/gold collection medals, with thresholds set from actual authored coin budgets. Add one unique treasure per level for exploration. Do not make coin grinding necessary to obtain a mandatory movement ability. A later cosmetic shop is optional scope, not a prerequisite for fixing the campaign.

Completion screen should show objective achieved, time, deaths/retries, coins collected versus available, unique treasure, and personal best. Skipped tester levels show “Skipped” and award no medals or completion records. Reset/respawn policy must be consistent: no missing mandatory pickups after dying, no duplicated score farming, and no unreachable remaining objectives.

## Production sequence

1. Build and playtest three representative vertical slices: Level 3 for route choice, Level 15 for readable combat traversal, and Level 22 for story-driven interaction. Keep existing campaign scenes available for comparison.
2. Lock movement, camera, UI brief, interaction, checkpoint state, and threat readability based on those slices. A complete template means a good authored example, not duplicating its geometry 24 times.
3. Rebuild Chapters 1–3, validate the learning curve, then rebuild Chapters 4–6 around their different protagonists and enemy roles.
4. Rebuild Chapters 7–8 after the rescue/stabilizer systems and Ahrena encounter are defined. Integrate story transitions only when their before/after states are known.
5. Run full campaign testing, then export a versioned tester build. Do not label a load-only smoke test as campaign completion testing.

## Definition of ready for external testing

For every level, record a verified normal completion, checkpoint recovery, restart, skip, controller/touch behavior where supported, and correct next cinematic. Verify completion on all supported difficulty settings. Log time-to-first-action, time-to-complete, deaths by encounter, wrong turns, missed objective interactions and player explanations of what they were trying to do.

Initial usability targets: a new tester can identify the objective within ten seconds, explain the main hazard after its first safe demonstration, and recognize the destination without verbal coaching. Treat these as hypotheses to test, not proven properties of the redesign.

Required level handoff: a route sketch; starting/ending story state; player and available abilities; named encounter sequence; enemy/hazard positions; coin/treasure budget; checkpoint/reset rules; objective state transitions; screenshots; and completed test results. A level is not finished merely because its scene loads.
