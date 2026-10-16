class_name StoryData
extends RefCounted
## Story script for the prototype: the 18 checkpoints in order, their trigger
## lines, and the cinematics that play between them.
## Cinematic panels are placeholders (still art + speech), per the design doc.

const CHECKPOINTS := [
	{"number": 1, "name": "Bush Maze Intro", "scene": "res://scenes/levels/checkpoint_01.tscn",
		"trigger": "Time to grab those coins before anyone notices...", "cinematic": "bush_maze_done"},
	{"number": 2, "name": "Treasure Chest Chase", "scene": "res://scenes/levels/checkpoint_02.tscn",
		"trigger": "Those coins are MINE. Gotta beat him there!", "cinematic": "chest_open"},
	{"number": 3, "name": "Shadow Arena", "scene": "res://scenes/levels/checkpoint_03.tscn",
		"trigger": "New players flooding in... grab what I can before it gets crazy!", "cinematic": "shadow_arena_done"},
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
		"trigger": "A sand wormfish?! Everyone scatter!", "cinematic": "wormfish"},
]

## Each cinematic is a list of still panels. Every panel has a background
## colour, optional art, a caption and speech lines shown one at a time.
const CINEMATICS := {
	"chest_open": {
		"title": "The Chest Opens",
		"panels": [
			{"bg": "#1b1f3a", "art": "res://assets/objects/chest.png",
				"caption": "At the end of the castle run, CT bursts the treasure chest open.",
				"lines": [["CT", "Coins coins coins coins..."], ["CT", "...a SUIT? Where are my COINS?!"]]},
			{"bg": "#14304a", "art": "res://assets/characters/CT/ct_idle.png",
				"caption": "The glowing suit wraps around CT and seals shut.",
				"lines": [["CT", "Hey! It's stuck! It's... actually kind of comfy."], ["CT", "Wait. Why is the sky full of players?"]]},
			{"bg": "#3a1414", "art": "res://assets/enemies/big_boss.png",
				"caption": "Far below, Big Boss watches the empty chest.",
				"lines": [["Big Boss", "That chest was MINE."], ["Big Boss", "Find the little green thief."]]},
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
	"wormfish": {
		"title": "To Be Continued...",
		"panels": [
			{"bg": "#3a2408", "art": "res://assets/enemies/wormfish.png",
				"caption": "The sand bursts open. Something enormous rises.",
				"lines": [["CT", "That's not Ahrena... is it?"], ["Lala", "That's her PET."], ["CT", "...I want my coins back."]]},
			{"bg": "#000000", "art": "",
				"caption": "Coin Troll Adventure - prototype complete.",
				"lines": [["", "TO BE CONTINUED..."]]},
		],
	},

	"bush_maze_done": {
		"title": "Out of the Hedges",
		"panels": [
			{"bg": "#1f3a1f", "art": "res://assets/characters/CT/ct_idle.png",
				"caption": "CT tumbles out of the hedge maze, coins jingling in every pocket.",
				"lines": [["CT", "Who designs these mazes? A troll would have just walked through the hedges."], ["CT", "Next stop: the castle. Hopefully with fewer hedges."]]},
			{"bg": "#101c10", "art": "res://assets/enemies/skull.png",
				"caption": "Something rattles behind the hedges. Probably just skulls.",
				"lines": [["CT", "Probably just skulls. Keep walking."]]},
		],
	},
	"shadow_arena_done": {
		"title": "The Shadows Fade",
		"panels": [
			{"bg": "#101030", "art": "res://assets/characters/CT/ct_idle.png",
				"caption": "The shadows dissolve. Coins glitter on every ledge.",
				"lines": [["CT", "Shadows don't carry wallets. Their loss."], ["CT", "Okay, now the hall ahead looks even bigger."]]},
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


static func get_cinematic(key: String) -> Dictionary:
	if CINEMATICS.has(key):
		return CINEMATICS[key]
	return {}
