class_name StoryData
extends RefCounted
## Story script for the prototype: the 18 checkpoints in order, their trigger
## lines, and the cinematics that play between them.
## Cinematic panels are placeholders (still art + speech), per the design doc.

const CHECKPOINTS := [
	{"number": 1, "name": "Bush Maze Intro", "scene": "res://scenes/levels/checkpoint_01.tscn",
		"trigger": "Time to grab those coins before anyone notices...", "cinematic": "bush_maze_done"},
	{"number": 2, "name": "Treasure Chest Chase", "scene": "res://scenes/levels/checkpoint_02.tscn",
		"trigger": "Those coins are MINE. Gotta beat him there!", "cinematic": "chest_open+chapter1_outro+shadow_storm"},
	{"number": 3, "name": "Shadow Arena", "scene": "res://scenes/levels/checkpoint_03.tscn",
		"trigger": "New players flooding in... grab what I can before it gets crazy!", "cinematic": "big_boss_arrives"},
	{"number": 4, "name": "Big Boss Dodge", "scene": "res://scenes/levels/checkpoint_04.tscn",
		"trigger": "Big Boss is coming. MOVE!", "cinematic": "pink_girl_arrives"},
	{"number": 5, "name": "Pink Girl vs Big Boss", "scene": "res://scenes/levels/checkpoint_05.tscn",
		"trigger": "She's holding her own, but Big Boss has one more trick!", "cinematic": "pink_girl_wins"},
	{"number": 6, "name": "Cliff Ambush", "scene": "res://scenes/levels/checkpoint_06.tscn",
		"trigger": "Better snap out of it... something doesn't feel right.", "cinematic": "cliff_fall"},
	{"number": 7, "name": "Forest Walk", "scene": "res://scenes/levels/checkpoint_07.tscn",
		"trigger": "Alright Flex, lead the way, but watch out for what's in these woods!", "cinematic": "meet_felix"},
	{"number": 8, "name": "Forest Chase", "scene": "res://scenes/levels/checkpoint_08.tscn",
		"trigger": "Horn is somewhere in these woods... keep moving!", "cinematic": "forest_chase_done"},
	{"number": 9, "name": "Enemy Types", "scene": "res://scenes/levels/checkpoint_09.tscn",
		"trigger": "A barreldugo! Flex says get close, let's try it!", "cinematic": "enemy_types_done"},
	{"number": 10, "name": "Bull Gauntlet", "scene": "res://scenes/levels/checkpoint_10.tscn",
		"trigger": "The Queen stepped in, but those bulls aren't done yet!", "cinematic": "bull_gauntlet_done"},
	{"number": 11, "name": "Warm-up Before the Duel", "scene": "res://scenes/levels/checkpoint_11.tscn",
		"trigger": "Alex accepted the duel... somebody's gotta warm up for him!", "cinematic": "crew_gathers"},
	{"number": 12, "name": "Big Bird Duel", "scene": "res://scenes/levels/checkpoint_12.tscn",
		"trigger": "Big Bird went straight for projectiles, dodge and get close!", "cinematic": "big_bird_challenge"},
	{"number": 13, "name": "Coin Scramble", "scene": "res://scenes/levels/checkpoint_13.tscn",
		"trigger": "I signed WHAT? Gotta do something, find those coins first!", "cinematic": "coin_scramble_done"},
	{"number": 14, "name": "Coin Rain on the Deck", "scene": "res://scenes/levels/checkpoint_14.tscn",
		"trigger": "Alex won! Now the coins are flowing, grab what you can!", "cinematic": "deck_rain_done"},
	{"number": 15, "name": "Tilting Ship", "scene": "res://scenes/levels/checkpoint_15.tscn",
		"trigger": "The ship is going DOWN. Hold on and get to safety!", "cinematic": "ship_falls"},
	{"number": 16, "name": "Sand Land", "scene": "res://scenes/levels/checkpoint_16.tscn",
		"trigger": "Welcome to Sand Land... and it does NOT look friendly.", "cinematic": "sand_land"},
	{"number": 17, "name": "Mayor's Coin Bag", "scene": "res://scenes/levels/checkpoint_17.tscn",
		"trigger": "I signed WHAT? Gotta do something, find those coins first!", "cinematic": "mayor_contract"},
	{"number": 18, "name": "Wormfish Chase", "scene": "res://scenes/levels/checkpoint_18.tscn",
		"trigger": "A sand wormfish?! Everyone scatter!", "cinematic": "outro"},
]

## Each cinematic is a list of still panels. Every panel has a background
## colour, optional art, a caption and speech lines shown one at a time.
const CINEMATICS := {
	## Plays before checkpoint 01 when a New Game starts.
	"intro": {
		"title": "Chapter 1",
		"panels": [
			{"bg": "#0c1430", "art": "res://assets/comic/ch1/intro_01_moon.jpg",
				"caption": "A low-level castle sits under a crescent moon.",
				"lines": [["", "A castle at night."]]},
			{"bg": "#101c3a", "art": "res://assets/comic/ch1/intro_02_castle.jpg",
				"caption": "The castle walls rise over the yard.",
				"lines": [["", "Quiet... too quiet."]]},
			{"bg": "#000000", "art": "res://assets/comic/ch1/intro_03_rumble.jpg",
				"caption": "RUMBLE! The ground shakes.",
				"lines": [["", "RUMBLE!"]]},
			{"bg": "#1f2a1f", "art": "res://assets/comic/ch1/intro_04_hand.jpg",
				"caption": "A bony hand bursts out of the dirt.",
				"lines": [["Skull", "Not the overgrown chupacabra! That smaller skeleton!"]]},
			{"bg": "#1f2a1f", "art": "res://assets/comic/ch1/intro_05_skull_down.jpg",
				"caption": "A skeleton lies sprawled in the mud, one arm stuck on its head.",
				"lines": [["", "..."]]},
			{"bg": "#1f2a1f", "art": "res://assets/comic/ch1/intro_06_skull_up.jpg",
				"caption": "CT shakes off the dirt and looks around.",
				"lines": [["", "..."]]},
			{"bg": "#101c10", "art": "res://assets/comic/ch1/intro_07_yeah.jpg",
				"caption": "The small skeleton is sure who he is.",
				"lines": [["CT", "Yeah, that's me."]]},
			{"bg": "#101c10", "art": "res://assets/comic/ch1/intro_08_low_level.jpg",
				"caption": "CT stands among the low-level skulls.",
				"lines": [["CT", "I'm a low-level enemy. Outside a castle level."]]},
			{"bg": "#1f3a1f", "art": "res://assets/comic/ch1/intro_09_different.jpg",
				"caption": "CT is a bit different from the other low-level enemies.",
				"lines": [["CT", "I'm a bit different than the other low-level enemies."]]},
			{"bg": "#1f3a1f", "art": "res://assets/comic/ch1/intro_10_existence.jpg",
				"caption": "CT grabs a coin, proud as can be.",
				"lines": [["CT", "Ever since my existence..."], ["CT", "...I have been into coins."]]},
			{"bg": "#1f3a1f", "art": "res://assets/comic/ch1/intro_11_coin_creep.jpg",
				"caption": "CT holds the coin close.",
				"lines": [["", "CT gets a little creepy about his coins."]]},
			{"bg": "#101c10", "art": "res://assets/comic/ch1/intro_12_skulls_safe.jpg",
				"caption": "A skull watches CT holding the coin.",
				"lines": [["Skull", "You're not going to take that, are you?"], ["CT", "Naw, man. I'm putting it in a safe area."]]},
			{"bg": "#1f3a1f", "art": "res://assets/comic/ch1/intro_13_ok.jpg",
				"caption": "CT gets ready to go.",
				"lines": [["CT", "Okay!"]]},
			{"bg": "#1f3a1f", "art": "res://assets/comic/ch1/intro_14_bag.jpg",
				"caption": "CT collects every coin into his bag.",
				"lines": [["CT", "Big or small coins, anywhere in between. I collect them all in my inventory."]]},
			{"bg": "#1f3a1f", "art": "res://assets/comic/ch1/intro_15_last_one.jpg",
				"caption": "CT looks at the empty pile.",
				"lines": [["CT", "I think that was the last one. Now the only thing left is that treasure chest."]]},
		],
	},
	## Tower climb ending (comic page 3). Wire after the tower climb level.
	"tower_done": {
		"title": "The Guard on the Tower",
		"panels": [
			{"bg": "#1a2030", "art": "res://assets/comic/ch1/tower_18_guard_huh.jpg",
				"caption": "A guard looks down from the top of the tower.",
				"lines": [["Guard", "Huh?"]]},
			{"bg": "#1a2030", "art": "res://assets/comic/ch1/tower_19_what_doing.jpg",
				"caption": "The guard spots CT on the ledge.",
				"lines": [["Guard", "What are you doing, CT?"]]},
			{"bg": "#1a2030", "art": "res://assets/comic/ch1/tower_20_look_at_something.jpg",
				"caption": "CT tries to look innocent.",
				"lines": [["CT", "I just need to look at something."]]},
			{"bg": "#1a2030", "art": "res://assets/comic/ch1/tower_21_relax.jpg",
				"caption": "The guard waves him off.",
				"lines": [["Guard", "Ey, relax, ma man. I'm just making sure everything is in order."], ["Guard", "That's not your job, bone head."]]},
			{"bg": "#1a2030", "art": "res://assets/comic/ch1/tower_22_where_hide.jpg",
				"caption": "CT ponders where a shiny coin would hide.",
				"lines": [["CT", "Now let me see... if I were a precious shiny coin, where would I hide?"]]},
			{"bg": "#1a2030", "art": "res://assets/comic/ch1/tower_23_chest_far.jpg",
				"caption": "Far below, a treasure chest glows in the yard.",
				"lines": [["CT", "There it is. The treasure!"]]},
		],
	},
	"chest_open": {
		"title": "Showtime",
		"panels": [
			{"bg": "#1b1f3a", "art": "res://assets/comic/ch1/chest_24_found_ya.jpg",
				"caption": "CT spots the chest and gets close.",
				"lines": [["CT", "Hehe, found ya!"]]},
			{"bg": "#3a1414", "art": "res://assets/comic/ch1/chest_25_protagonist.jpg",
				"caption": "Lights flash by the tower. The protagonist is coming.",
				"lines": [["Skull", "Flashing lights, that's got to be the protagonist."], ["Skull", "Hmm, darn it. Of all the times the protagonist had to show up..."]]},
			{"bg": "#1b1f3a", "art": "res://assets/comic/ch1/chest_26_swing.jpg",
				"caption": "The protagonist swings toward the skulls.",
				"lines": [["", "..."]]},
			{"bg": "#1b1f3a", "art": "res://assets/comic/ch1/chest_27_better_get.jpg",
				"caption": "CT races for the chest.",
				"lines": [["CT", "I better get to the treasure chest before he does!"]]},
			{"bg": "#1b1f3a", "art": "res://assets/comic/ch1/chest_28_allyup.jpg",
				"caption": "CT leaps into the air.",
				"lines": [["CT", "Allyup!"]]},
			{"bg": "#1b1f3a", "art": "res://assets/comic/ch1/chest_29_zoom.jpg",
				"caption": "CT zooms toward the chest.",
				"lines": [["CT", "Those coins are mine!"]]},
			{"bg": "#3a2a0a", "art": "res://assets/comic/ch1/chest_30_glow.jpg",
				"caption": "The chest glows bright.",
				"lines": [["", "..."]]},
			{"bg": "#1b1f3a", "art": "res://assets/comic/ch1/chest_32_chest_closed.jpg",
				"caption": "The chest stays shut.",
				"lines": [["CT", "Open, you son of a..."]]},
			{"bg": "#1b1f3a", "art": "res://assets/comic/ch1/chest_33_open_damn.jpg",
				"caption": "CT pulls at the lid.",
				"lines": [["CT", "Open damn it!"]]},
			{"bg": "#000000", "art": "res://assets/comic/ch1/chest_34_boom.jpg",
				"caption": "BOOM! The chest bursts open.",
				"lines": [["", "BOOM!"]]},
			{"bg": "#1b1f3a", "art": "res://assets/comic/ch1/chest_35_ouch.jpg",
				"caption": "CT falls to the ground.",
				"lines": [["CT", "Ouch! That hurt."]]},
		],
	},
	## Chapter 1 ending (storyboard pages 33-37). Plays after chest_open, before the next checkpoint.
	## Chapter 1 ending (comic pages 6 to 7). Plays after the chest scene.
	"chapter1_outro": {
		"title": "Chapter 1 Ends",
		"panels": [
			{"bg": "#14304a", "art": "res://assets/comic/ch1/outro_36_suit_appears.jpg",
				"caption": "A hooded suit floats out of the chest.",
				"lines": [["CT", "Woooahh!!"]]},
			{"bg": "#14304a", "art": "res://assets/comic/ch1/outro_37_woooah.jpg",
				"caption": "CT stares at the suit.",
				"lines": [["CT", "What the poop?"]]},
			{"bg": "#14304a", "art": "res://assets/comic/ch1/outro_38_no_coin.jpg",
				"caption": "CT is not impressed.",
				"lines": [["CT", "That's no coin."]]},
			{"bg": "#3a1414", "art": "res://assets/comic/ch1/outro_39_protagonist_way.jpg",
				"caption": "A shadowy figure laughs in the tower.",
				"lines": [["Big Boss", "Ha ha ha! The protagonist is on his way. It's showtime."]]},
			{"bg": "#3a1414", "art": "res://assets/comic/ch1/outro_41_show_time.jpg",
				"caption": "Big Boss stands in the tower window.",
				"lines": [["Big Boss", "Show time."]]},
			{"bg": "#3a1414", "art": "res://assets/comic/ch1/outro_42_strongest.jpg",
				"caption": "Big Boss hits the skulls. SMACK! CLINK!",
				"lines": [["Big Boss", "He's the strongest and the worst character in the whole game. But we refer to him as Big Boss."]]},
			{"bg": "#3a1414", "art": "res://assets/comic/ch1/outro_43_bozo.jpg",
				"caption": "Big Boss notices the flashing light.",
				"lines": [["Big Boss", "Huh? That light isn't where the protagonist spawned."], ["Big Boss", "Wait a minute, don't tell me, that bozo is at it again!"]]},
			{"bg": "#3a1414", "art": "res://assets/comic/ch1/outro_44_not_junk.jpg",
				"caption": "CT is blasted into a cloud of coins.",
				"lines": [["CT", "I wanted coins, not this junk!"]]},
			{"bg": "#3a1414", "art": "res://assets/comic/ch1/outro_45_lunatic.jpg",
				"caption": "Big Boss is furious.",
				"lines": [["Big Boss", "That lunatic is always messing things up."]]},
			{"bg": "#3a1414", "art": "res://assets/comic/ch1/outro_46_won_fix.jpg",
				"caption": "Big Boss grips his sword.",
				"lines": [["Big Boss", "Fine! If the game won't fix it, then I will."]]},
			{"bg": "#3a1414", "art": "res://assets/comic/ch1/outro_48_fall_to_me.jpg",
				"caption": "Big Boss leaps from the tower.",
				"lines": [["Big Boss", "Then I guess it falls to me to deal with that bug!"]]},
		],
	},
	"pink_girl_arrives": {
		"title": "A Shield in the Way",
		"panels": [
			{"bg": "#3a1414", "art": "res://assets/enemies/big_boss.png",
				"caption": "Big Boss raises his sword over the exhausted troll.",
				"lines": [["Big Boss", "YOU ARE DONE!"], ["CT", "Can we talk about this? I have... zero coins to offer."]]},
			{"bg": "#4a1a3a", "art": "res://assets/npc/pink_girl.png",
				"caption": "CLANG. A pink shield stops the blade cold.",
				"lines": [["Pink Girl", "Back off, big guy."], ["CT", "...whoa."]]},
		],
	},
	"pink_girl_wins": {
		"title": "The Duel Ends",
		"panels": [
			{"bg": "#4a1a3a", "art": "res://assets/npc/pink_girl.png",
				"caption": "Pink Girl drives Big Boss back across the arena.",
				"lines": [["Big Boss", "I have been putting up with you for way too long!"], ["Pink Girl", "Then stop getting up."]]},
			{"bg": "#2a1a4a", "art": "res://assets/npc/sigih.png",
				"caption": "Sigih, the pink fighter, opens a portal.",
				"lines": [["Sigih", "Keep training, Coin Troll. You'll need it."], ["CT", "Wait! What's your... name..."], ["CT", "...she's gone."]]},
		],
	},
	"cliff_fall": {
		"title": "Over the Edge",
		"panels": [
			{"bg": "#3a2a1a", "art": "res://assets/enemies/horn.png",
				"caption": "Horn's charge connects. CT sails off the cliff.",
				"lines": [["CT", "Not the cliiiiiiff!"], ["Horn", "HRRRNN!"]]},
		],
	},
	"meet_felix": {
		"title": "A New Friend",
		"panels": [
			{"bg": "#1a3a22", "art": "res://assets/npc/felix.png",
				"caption": "On the forest floor, CT and Felix finally talk properly.",
				"lines": [["Felix", "You landed on me, you know. Face first."], ["CT", "You broke my fall. Thanks, I guess?"], ["Felix", "Call me Flex. Here's a map. Don't lose it."], ["CT", "Does it show where the coins are?"], ["Felix", "...it shows where we are NOT going to die."]]},
		],
	},
	"crew_gathers": {
		"title": "The Crew on Deck",
		"panels": [
			{"bg": "#1a2a4a", "art": "res://assets/npc/lala.png",
				"caption": "The crew gathers on the deck of the flying ship.",
				"lines": [["Lala", "The Queen of Winds holds this whole ship in the air."], ["Lala", "And that suit of yours? It runs on the same wind magic."], ["CT", "Can it make coins?"], ["Lala", "No."]]},
			{"bg": "#1a2a4a", "art": "res://assets/characters/Alex/alex_idle.png",
				"caption": "Alex checks his shield and bow.",
				"lines": [["Lala", "Big Bird throws boomerangs. He's weak up close."], ["Alex", "Then I'll get close."]]},
		],
	},
	"big_bird_challenge": {
		"title": "The Challenge",
		"panels": [
			{"bg": "#203a5a", "art": "res://assets/enemies/big_bird.png",
				"caption": "Big Bird lands on the rail and spreads his wings.",
				"lines": [["Big Bird", "Sacavuelo never loses a duel, little shield boy."], ["Alex", "Then today's a first."], ["CT", "I bet ten coins on Alex! ...I don't have ten coins."]]},
		],
	},
	"ship_falls": {
		"title": "Going Down",
		"panels": [
			{"bg": "#2a2030", "art": "res://assets/npc/queen.png",
				"caption": "The Queen strains to keep the tilting ship in the air.",
				"lines": [["Queen", "Everyone hold on!"], ["CT", "Holding! Holding everything! Mostly coins!"]]},
			{"bg": "#3a2a10", "art": "res://assets/environment/crate_big.png",
				"caption": "The wind gives out. The ship drops toward the desert.",
				"lines": [["Lala", "That's... not good."]]},
		],
	},
	"sand_land": {
		"title": "Sand Land",
		"panels": [
			{"bg": "#5a4320", "art": "res://assets/npc/lala.png",
				"caption": "The ship crash-lands beside a ruined desert town.",
				"lines": [["CT", "Lala! Grab my hand!"], ["Lala", "Pthh! Sand. Sand everywhere."], ["CT", "...and coins in the rubble. Today's improving."]]},
		],
	},
	"mayor_contract": {
		"title": "The Mayor's Offer",
		"panels": [
			{"bg": "#4a3018", "art": "res://assets/npc/mayor.png",
				"caption": "The town mayor holds out a heavy bag of coins.",
				"lines": [["Mayor", "Defeat the desert boss Ahrena and this bag is yours."], ["Mayor", "Just sign this little magic contract."], ["CT", "Sure, sure, where do I sign?"], ["Lala", "CT, you didn't even read it!"]]},
		],
	},
	"outro": {
		"title": "To Be Continued...",
		"panels": [
			{"bg": "#3a2408", "art": "res://assets/enemies/wormfish.png",
				"caption": "The sand bursts open behind the ruined town. Something enormous rises.",
				"lines": [["CT", "That's not Ahrena... is it?"], ["Lala", "That's her PET."], ["CT", "...I want my coins back."]]},
			{"bg": "#2a1a0a", "art": "res://assets/npc/mayor.png",
				"caption": "Back in the ruins, the Mayor is already counting coins he never planned to give away.",
				"lines": [["Mayor", "Don't worry, the contract is airtight."], ["Lala", "CT, nothing in that contract is airtight. Not the mud, not the ring, not the worm."]]},
			{"bg": "#000000", "art": "",
				"caption": "Ahrena's ring is still on CT's finger. Sand Land is not done with him.",
				"lines": [["", "TO BE CONTINUED..."]]},
		],
	},

	"bush_maze_done": {
		"title": "Up the Tower",
		"panels": [
			{"bg": "#1f3a1f", "art": "res://assets/comic/ch1/maze_16_climb_decision.jpg",
				"caption": "CT looks up at the tower.",
				"lines": [["CT", "Well, I'm going to climb that tower to get a better view."]]},
			{"bg": "#1f3a1f", "art": "res://assets/comic/ch1/maze_17_arrow.jpg",
				"caption": "The tower stands above the castle yard.",
				"lines": [["", "..."]]},
		],
	},
	## Plays before checkpoint 03 (after chest_open, joined with "+" in CHECKPOINTS).
	"shadow_storm": {
		"title": "New Players Arrive",
		"panels": [
			{"bg": "#1a2a4a", "art": "res://assets/characters/Alex/alex_idle.png",
				"caption": "A crowd of new players pours into the arena through the castle gate.",
				"lines": [["New Player", "Everybody in! Grab the coins before the boss gets them!"]]},
			{"bg": "#101c10", "art": "res://assets/enemies/shadow_avatar.png",
				"caption": "A dark shadow flickers in the middle of the arena. Its warning light pulses on the ground.",
				"lines": [["New Player", "What is THAT?"]]},
			{"bg": "#2a1a0a", "art": "res://assets/enemies/shadow_avatar.png",
				"caption": "The shadow bursts open right beside CT. A shockwave rings out across the arena.",
				"lines": [["CT", "Whoa! Not cool!"]]},
			{"bg": "#1a2a4a", "art": "res://assets/characters/Alex/alex_idle.png",
				"caption": "The new player charges straight into the shadow, sword first.",
				"lines": [["New Player", "Storm it! Together!"], ["New Player", "Nobody touches the coins!"]]},
			{"bg": "#101c10", "art": "res://assets/enemies/shadow_avatar.png",
				"caption": "The shadow breaks apart into dust. More players rush past the spot where it stood.",
				"lines": [["New Player", "Got it! Next one!"]]},
		],
	},
	"big_boss_arrives": {
		"title": "Big Boss Is Coming",
		"panels": [
			{"bg": "#3a1414", "art": "res://assets/enemies/big_boss.png",
				"caption": "Big Boss crashes down from the castle tower, sword raised.",
				"lines": [["Big Boss", "Little green thief. Did you think I forgot about you?"]]},
			{"bg": "#14304a", "art": "res://assets/characters/CT/ct_idle.png",
				"caption": "CT scrambles backward as the blade swings toward him. It misses by a hair.",
				"lines": [["CT", "Whoa! Whoa! Let's talk about this!"], ["Big Boss", "No talking."]]},
			{"bg": "#3a1414", "art": "res://assets/enemies/big_boss.png",
				"caption": "Big Boss raises his sword again.",
				"lines": [["Big Boss", "Stand still and let me finish."], ["CT", "Nope! I'm not standing still for that!"]]},
		],
	},
	"forest_chase_done": {
		"title": "Safe at Last",
		"panels": [
			{"bg": "#1a3a22", "art": "res://assets/npc/felix.png",
				"caption": "Horn's roar fades behind the treeline.",
				"lines": [["Felix", "We made it! Horn's still huffing back there."], ["CT", "I'm never running again. ...Okay, maybe once more."]]},
		],
	},
	"enemy_types_done": {
		"title": "Know Your Enemies",
		"panels": [
			{"bg": "#2a2a3a", "art": "res://assets/enemies/bull.png",
				"caption": "A tank, a speedster and a shooter. All three are down.",
				"lines": [["Felix", "Textbook. You're a natural, troll."], ["CT", "Textbook? I just hit things until they stop."]]},
		],
	},
	"bull_gauntlet_done": {
		"title": "The Queen's Warning",
		"panels": [
			{"bg": "#1a2a4a", "art": "res://assets/npc/queen.png",
				"caption": "The Queen lowers her wind-staff. The bulls are calm again.",
				"lines": [["Queen", "Impressive. Now you'll meet Alex's real challenge."], ["CT", "Hey, I'm not the one who's dueling!"]]},
		],
	},
	"coin_scramble_done": {
		"title": "A Bet Is A Bet",
		"panels": [
			{"bg": "#203a5a", "art": "res://assets/characters/Alex/alex_idle.png",
				"caption": "Alex lowers his bow, still breathing hard.",
				"lines": [["Alex", "I'm not even mad. That was a great fight."], ["CT", "I'm mad. Where are my coins, Alex?"]]},
		],
	},
	"deck_rain_done": {
		"title": "Every Last Coin",
		"panels": [
			{"bg": "#1a2a4a", "art": "res://assets/npc/lala.png",
				"caption": "The last coin clatters across the deck.",
				"lines": [["Lala", "You caught every one. Impressive, and a little gross."], ["CT", "They're MINE. Every drop."]]},
		],
	},
}


static func count() -> int:
	return CHECKPOINTS.size()


static func get_checkpoint(number: int) -> Dictionary:
	var index := clampi(number, 1, CHECKPOINTS.size()) - 1
	return CHECKPOINTS[index]


static func cinematic_after(number: int) -> String:
	var info := get_checkpoint(number)
	return str(info.get("cinematic", ""))


## A key like "chest_open+shadow_storm" plays those cinematics one after another.
static func get_cinematic(key: String) -> Dictionary:
	if key.contains("+"):
		var merged := {"title": "", "panels": []}
		for part in key.split("+"):
			var one := get_cinematic(part.strip_edges())
			if one.is_empty():
				continue
			if str(merged["title"]) == "":
				merged["title"] = one.get("title", "")
			merged["panels"].append_array(one.get("panels", []))
		return merged
	if CINEMATICS.has(key):
		return CINEMATICS[key]
	return {}
